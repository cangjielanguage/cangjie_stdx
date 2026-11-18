/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.generate

import stdx.contract.macros.inheritance.{ContractMetaData, ResolvedTypeContract, attrOriginHasOwner, canonicalDeclaringTypeName, collectAllMemberSignatures, collectValueMemberNames, declaredTypeName, declaredTypeParameters, expandMemberInherits, memberConditionIsMaterializable, methodSignatureKey, recordDeclaredAttrOrigin, registerMetaData, reportInheritedNameConflicts, resolveTypeContract, sanitizeCheckerPart, unionInto}
import stdx.contract.macros.parse.{parseFunctionContract, parsePropertyContract}
import stdx.contract.macros.syntax.{Diagnostic, FunctionClause, FunctionContract, IdentifierSyntax, PropContract, PropKind, TypeContract}
import stdx.contract.macros.tokens.{isValue}
import stdx.contract.macros.validation.astGetOrDefault
import stdx.contract.macros.validation.validateVariableMemberNames
import stdx.contract.runtime.ContractVisibility
import std.ast.{ASTException, Body, ClassDecl, Decl, DiagReportLevel, FuncDecl, Modifier, PrimaryCtorDecl, PropDecl, StructDecl, Token, Tokens, TypeNode, VarDecl, diagReport}
import std.collection.{ArrayList, HashSet, contains, forEach, isEmpty}

/**
 * @brief Expands a class type contract into the rewritten declaration tokens.
 *
 * Resolves the contract clauses against the class, absorbs the deferred member
 * contracts, registers the type metadata, and regenerates the type body with ghost
 * variable (auxiliary variable) storage, invariant checkpoints, and member contract
 * wrappers. On diagnostics, reports them and returns the owner unchanged.
 *
 * @param contract The parsed type contract clauses of the class.
 * @param owner The class declaration the contract was attached to.
 * @return The rewritten class tokens with the generated contract checks.
 */
public func genClassContract(contract: TypeContract, owner: ClassDecl): Tokens {
    let diagnostics = ArrayList<Diagnostic>()
    let resolved = resolveTypeContract(contract, owner, diagnostics)
    let generated = ClassDecl(owner.toTokens())
    absorbDeferredMemberContracts(resolved, generated.body, owner, diagnostics)
    if (!diagnostics.isEmpty()) {
        diagnostics.forEach {diagnostic => diagnostic.show()}
        return owner.toTokens()
    }
    registerMetaData(
        ContractMetaData(owner.identifier.value, declaredTypeParameters(owner), resolved, isInterface: false,
            isOpen: hasOpenOrAbstract(owner.modifiers), memberAttrs: resolved.memberAttrs,
            propertyAttrs: resolved.propertyAttrs, memberAttrOrigins: resolved.memberAttrOrigins,
            propertyAttrOrigins: resolved.propertyAttrOrigins,
            allMemberSignatures: unionInto(collectAllMemberSignatures(owner.body),
                resolved.inheritedMemberSignatures),
            valueNames: collectValueMemberNames(owner.body), memberParamNames: resolved.memberParamNames,
            memberCheckerBases: resolved.memberCheckerBases))
    generated.body = genTypeBody(resolved, generated.body, owner.identifier.value, true,
        hasOpenOrAbstract(owner.modifiers))
    generated.toTokens()
}

/**
 * @brief Expands a struct type contract into the rewritten declaration tokens.
 *
 * Mirrors `genClassContract` for struct hosts: struct members are never open, so no
 * inheritance-driven checkpoint dispatch is emitted, and the struct-shaped wrappers
 * keep `mut` members working on the mutable receiver.
 *
 * @param contract The parsed type contract clauses of the struct.
 * @param owner The struct declaration the contract was attached to.
 * @return The rewritten struct tokens with the generated contract checks.
 */
public func genStructContract(contract: TypeContract, owner: StructDecl): Tokens {
    let diagnostics = ArrayList<Diagnostic>()
    let resolved = resolveTypeContract(contract, owner, diagnostics)
    let generated = StructDecl(owner.toTokens())
    absorbDeferredMemberContracts(resolved, generated.body, owner, diagnostics)
    if (!diagnostics.isEmpty()) {
        diagnostics.forEach {diagnostic => diagnostic.show()}
        return owner.toTokens()
    }
    registerMetaData(
        ContractMetaData(owner.identifier.value, declaredTypeParameters(owner), resolved, isInterface: false,
            isOpen: false, memberAttrs: resolved.memberAttrs, propertyAttrs: resolved.propertyAttrs,
            memberAttrOrigins: resolved.memberAttrOrigins, propertyAttrOrigins: resolved.propertyAttrOrigins,
            allMemberSignatures: unionInto(collectAllMemberSignatures(owner.body),
                resolved.inheritedMemberSignatures),
            valueNames: collectValueMemberNames(owner.body), memberParamNames: resolved.memberParamNames,
            memberCheckerBases: resolved.memberCheckerBases))
    generated.body = genTypeBody(resolved, generated.body, owner.identifier.value, false, false)
    generated.toTokens()
}

/// Collect member contracts declared inside this type contract before publishing the metadata.
func absorbDeferredMemberContracts(contract: ResolvedTypeContract, body: Body, owner: Decl,
    diagnostics: ArrayList<Diagnostic>): Unit {
    for (member in body.decls) {
        if (let method: FuncDecl <- member) {
            absorbDeferredMethodContract(contract, method, owner, diagnostics)
        } else if (let property: PropDecl <- member) {
            absorbDeferredPropertyContract(contract, property, owner, diagnostics)
        }
    }
}

func absorbDeferredMethodContract(contract: ResolvedTypeContract, method: FuncDecl, owner: Decl,
    diagnostics: ArrayList<Diagnostic>): Unit {
    // A member without its own contract still hosts local functions whose
    // deferred contracts were published to this type context.
    absorbLocalFunctionContracts(method)
    if (method.identifier.value == "init") {
        return
    }
    let key = methodSignatureKey(method)
    // This type's own parameter names: the positional rename targets the stored (and
    // inherited) clause text of this member is kept consistent with.
    let methodParams = methodParameterNames(method)
    let raw = findDeferredMethodAttr(method)
    let own = expandMemberInherits(raw, key, false, owner, diagnostics,
        childParams: (methodParams, methodHasModifier(method, "static")))
    if (own.size > 0) {
        reportDeferredMethodConflicts(contract, key, raw, own, diagnostics)
    }
    contract.appendMemberAttr(key, own)
    if (own.size > 0) {
        // Own-key provenance for checker generation; independent of the origin map,
        // which stays empty for unlabeled clauses (see genMemberConditionCheckers).
        contract.ownMemberAttrKeys.add(key)
    }
    // A contract this type declares carries this type as its provenance, even when the
    // member also carries an inherited ancestor contract: sibling parents redeclaring
    // the same name must still conflict (diamond). Only the same declaring type is
    // skipped, so re-recording stays idempotent.
    if (own.size > 0 && !attrOriginHasOwner(contract.memberAttrOrigins, key, declaredTypeName(owner))) {
        recordDeclaredAttrOrigin(contract, key, own, declaredTypeName(owner))
    }
    // The member's own parameter names override any propagated record: the stored clause
    // text of this key is renamed to (or declared with) exactly these names. Own clause
    // conditions materialize as this type's own checkers, so its checker base wins too.
    contract.recordMemberParamNames(key, methodParams)
    if (own.size > 0) {
        contract.recordMemberCheckerBase(key, memberCheckerBase(owner, key))
    }
}

func reportDeferredMethodConflicts(contract: ResolvedTypeContract, key: String, raw: Tokens,
    own: Tokens, diagnostics: ArrayList<Diagnostic>): Unit {
    // Parent contracts are inherited only through `inherits from`; without it they
    // merely guard the override from reusing a same-kind name.
    let parent = match (contract.memberAttrs.get(key)) {
        case Some(inherited) => Some(inherited)
        case None => contract.parentMemberAttrs.get(key)
    }
    match (parent) {
        case Some(inherited) =>
            reportInheritedNameConflicts(inherited, raw, "override of `${key}`", diagnostics, own)
        case None => ()
    }
    if (contract.conformingMemberSignatures.contains(key)) {
        // Only a locally written `requires` strengthens the precondition; a
        // `<kind> <type>.<name>` clause merely replays the parent contract.
        // `[conforming]` restricts only the members of the conforming parent.
        reportConformingRequires(raw, key, diagnostics)
    }
}

func absorbDeferredPropertyContract(contract: ResolvedTypeContract, property: PropDecl, owner: Decl,
    diagnostics: ArrayList<Diagnostic>): Unit {
    let name = property.identifier.value
    let raw = findDeferredPropertyAttr(property)
    let own = expandMemberInherits(raw, name, true, owner, diagnostics)
    if (own.size > 0) {
        let parent = match (contract.propertyAttrs.get(name)) {
            case Some(inherited) => Some(inherited)
            case None => contract.parentPropertyAttrs.get(name)
        }
        match (parent) {
            case Some(inherited) =>
                reportInheritedNameConflicts(inherited, raw, "override of property `${name}`",
                    diagnostics, own, property: true)
            case None => ()
        }
        if (contract.conformingMemberSignatures.contains(name)) {
            // Brand-new properties are not overrides and may declare `requires`.
            reportConformingPropertyRequires(raw, name, diagnostics)
        }
    }
    contract.appendPropertyAttr(name, own)
    if (own.size > 0 && !attrOriginHasOwner(contract.propertyAttrOrigins, name, declaredTypeName(owner))) {
        recordDeclaredAttrOrigin(contract, name, own, declaredTypeName(owner), property: true)
    }
}

/// `[conforming]` overrides must not strengthen preconditions.
func reportConformingRequires(attr: Tokens, subject: String, diagnostics: ArrayList<Diagnostic>): Unit {
    let parsed = parseFunctionContract(attr)
    if (parsed.hasError()) {
        return
    }
    for (clause in parsed.value.clauses) {
        if (let FunctionClause.Requires(c) <- clause) {
            diagnostics.add(
                Diagnostic("`[conforming]` override of `${subject}` cannot add a `requires` contract",
                    "contract inheritance", c.tokens))
        }
    }
}

func reportConformingPropertyRequires(attr: Tokens, subject: String, diagnostics: ArrayList<Diagnostic>): Unit {
    let parsed = parsePropertyContract(attr, setterAlias: "value")
    if (parsed.hasError()) {
        return
    }
    for (clause in parsed.value.clauses) {
        for (body in clause.clauses) {
            match (body) {
                case FunctionClause.Requires(c) =>
                    diagnostics.add(
                        Diagnostic("`[conforming]` override of property `${subject}` cannot add a `requires` contract",
                            "contract inheritance", c.tokens))
                case _ => ()
            }
        }
    }
}

func genTypeBody(contract: ResolvedTypeContract, body: Body, typeName: String, isClass: Bool, isOpen: Bool): Body {
    let ctx = TypeBodyContext(contract, collectInvariants(contract), declaredInvariantMethods(body),
        collectMemberNames(body, contract), collectDeclaredMemberNames(body), isClass, isOpen)
    let members = ArrayList<Decl>()
    let interfaceNames = HashSet<String>()
    for (variable in collectInterfaceVariables(contract)) {
        interfaceNames.add(variable.name.name)
    }
    members.add(all: genVariableDeclarations(collectVariables(contract), isOpen, interfaceNames))
    for (member in body.decls) {
        processTypeMember(member, ctx, members)
    }
    members.add(all: genInvariantMethods(ctx.invariants, typeName, isClass, isOpen, ctx.declared))
    // Member-condition checkers (#9): per-clause predicates the declaring type owns, emitted
    // with the member's own visibility, so an inheriting type can replay a condition in the
    // declaring scope (private members stay visible) instead of pasting its text into a scope
    // where it cannot compile.
    if (isClass) {
        members.add(all: genMemberConditionCheckers(contract, body, typeName))
    }
    Body(members)
}

/// Names and flags shared while rewriting the members of one type body.
class TypeBodyContext {
    let contract: ResolvedTypeContract
    let invariants: ArrayList<ResolvedInvariant>
    let declared: HashSet<String>
    let memberNames: HashSet<String>
    let declaredMemberNames: HashSet<String>
    let isClass: Bool
    let isOpen: Bool

    init(contract: ResolvedTypeContract, invariants: ArrayList<ResolvedInvariant>,
        declared: HashSet<String>, memberNames: HashSet<String>, declaredMemberNames: HashSet<String>,
        isClass: Bool, isOpen: Bool) {
        this.contract = contract
        this.invariants = invariants
        this.declared = declared
        this.memberNames = memberNames
        this.declaredMemberNames = declaredMemberNames
        this.isClass = isClass
        this.isOpen = isOpen
    }
}

func processTypeMember(member: Decl, ctx: TypeBodyContext, members: ArrayList<Decl>): Unit {
    if (let method: FuncDecl <- member) {
        processTypeMethod(method, ctx, members)
    } else if (let ctor: PrimaryCtorDecl <- member) {
        processTypeConstructor(ctor, ctx, members)
    } else if (let property: PropDecl <- member) {
        processTypeProperty(property, ctx, members)
    } else {
        members.add(member)
    }
}

func processTypeMethod(method: FuncDecl, ctx: TypeBodyContext, members: ArrayList<Decl>): Unit {
    if (method.identifier.value == "init") {
        // Only instance constructors (and primary constructors) of non-open
        // classes are invariant checkpoints; `static init` is not in the spec's
        // checkpoint list, so no invariant check is injected there.
        if (!(ctx.isClass && ctx.isOpen) && !methodHasModifier(method, "static")) {
            // Constructors are not filtered by their own visibility: every invariant
            // applies at the constructor exit (spec §3.2.4), and the body can read
            // private/protected members regardless of the constructor's modifier.
            let checks = genInvariantCalls(ctx.invariants, false, ContractVisibility.Public, false,
                ctx.declared)
            injectConstructorFuncInvariants(method, checks)
        }
        members.add(method)
        return
    }
    if (skipMethod(method, ctx.declared) || !isConcreteMethod(method)) {
        // Contracts are rejected on `const` functions (they execute at compile
        // time); report instead of silently dropping them.
        reportConstContract(method, ctx)
        members.add(method)
        return
    }
    processConcreteTypeMethod(method, ctx, members)
}

func reportConstContract(method: FuncDecl, ctx: TypeBodyContext): Unit {
    if (!method.isConst() || skipMethod(method, ctx.declared)) {
        return
    }
    match (ctx.contract.memberAttrs.get(methodSignatureKey(method))) {
        case Some(attr) =>
            if (attr.size > 0) {
                Diagnostic("function contract requires an ordinary, non-const function.",
                    "function contract", method.toTokens()).show()
            }
        case None => ()
    }
}

func processConcreteTypeMethod(method: FuncDecl, ctx: TypeBodyContext, members: ArrayList<Decl>): Unit {
    // Inherited and own clauses were merged parent-first into the metadata index.
    let attr = match (ctx.contract.memberAttrs.get(methodSignatureKey(method))) {
        case Some(attr) => attr
        case None => Tokens()
    }
    var functionContract = FunctionContract(Tokens())
    if (attr.size > 0) {
        let parsed = parseFunctionContract(attr)
        parsed.diagnostics.forEach {diagnostic => diagnostic.show()}
        if (parsed.hasError()) {
            members.add(method)
            return
        }
        validateVariableMemberNames(parsed.value.clauses, ctx.declaredMemberNames, method.identifier.value)
        validateEnsuresReturnNames(parsed.value, ctx.memberNames, method.identifier.value)
        functionContract = parsed.value
    }
    let checks = genInvariantCalls(ctx.invariants, methodHasModifier(method, "static"),
        visibilityOf(method.modifiers), ctx.isOpen, ctx.declared)
    if (attr.size == 0 && checks.size == 0) {
        members.add(method)
        return
    }
    let generated = if (ctx.isClass) {
        GenClassMember(functionContract, method, invariants: Some(checks)).gen()
    } else {
        GenStructMember(functionContract, method, invariants: Some(checks)).gen()
    }
    appendGenerated(members, generated)
}

func processTypeConstructor(ctor: PrimaryCtorDecl, ctx: TypeBodyContext, members: ArrayList<Decl>): Unit {
    if (ctx.isClass && ctx.isOpen) {
        members.add(ctor)
        return
    }
    let checks = genInvariantCalls(ctx.invariants, false, ContractVisibility.Public, false, ctx.declared)
    if (checks.size == 0) {
        members.add(ctor)
        return
    }
    injectConstructorInvariants(ctor, checks)
    members.add(ctor)
}

func processTypeProperty(property: PropDecl, ctx: TypeBodyContext, members: ArrayList<Decl>): Unit {
    let attr = match (ctx.contract.propertyAttrs.get(property.identifier.value)) {
        case Some(attr) => attr
        case None => Tokens()
    }
    // Wrap the accessors also when only the type-level invariants
    // apply and the property itself declares no contract clauses.
    let checks = genInvariantCalls(ctx.invariants, modifiersHave(property.modifiers, "static"),
        visibilityOf(property.modifiers), ctx.isOpen, ctx.declared)
    if (attr.size == 0 && checks.size == 0) {
        members.add(property)
        return
    }
    if (attr.size == 0) {
        processInvariantOnlyProperty(property, ctx, members)
    } else {
        processContractProperty(property, attr, checks, ctx, members)
    }
}

func processInvariantOnlyProperty(property: PropDecl, ctx: TypeBodyContext, members: ArrayList<Decl>): Unit {
    // Invariant-only wrapping on an abstract property: no accessor body to
    // host the invariant checks; keep the declaration unchanged.
    if (!propertyAccessorsHaveBodies(property, true, false)) {
        members.add(property)
        return
    }
    let generated = genPropertyContract(PropContract(Tokens()), property, ctx.invariants, ctx.isOpen,
        ctx.declared, isStruct: !ctx.isClass)
    appendGenerated(members, generated)
}

func processContractProperty(property: PropDecl, attr: Tokens, checks: Tokens, ctx: TypeBodyContext,
    members: ArrayList<Decl>): Unit {
    let parsed = parsePropertyContract(attr, setterAlias: setterParameterName(property))
    parsed.diagnostics.forEach {diagnostic => diagnostic.show()}
    if (parsed.hasError()) {
        members.add(property)
        return
    }
    // A body-less accessor (an abstract property) has no check point to
    // host the generated wrapper; report instead of crashing.
    var needGetter = checks.size > 0
    var needSetter = false
    for (clause in parsed.value.clauses) {
        match (clause.kind) {
            case PropKind.Getter => needGetter = true
            case PropKind.Setter => needSetter = true
        }
    }
    // The setter wrapper is skipped for non-`mut` properties, so only a
    // `mut` accessor needs its body checked.
    if (!propertyAccessorsHaveBodies(property, needGetter, needSetter && modifiersHave(property.modifiers, "mut"))) {
        diagReport(DiagReportLevel.ERROR, attr,
            "`@Contract` requires accessor bodies; an abstract property has no accessor to host its contract checks",
            "Contract")
        members.add(property)
        return
    }
    for (section in parsed.value.clauses) {
        validateVariableMemberNames(section.clauses, ctx.declaredMemberNames, property.identifier.value)
    }
    validateEnsuresReturnNamesProperty(parsed.value, ctx.memberNames, property.identifier.value)
    let generated = genPropertyContract(parsed.value, property, ctx.invariants, ctx.isOpen, ctx.declared,
        isStruct: !ctx.isClass)
    appendGenerated(members, generated)
}

/// Checker-name base for one member of `owner`: `_contract_member_cond_<DeclType>_<key>_`.
/// The canonical (package-qualified) declaring type keeps the name aligned with the
/// `fullName` recorded in the type's metadata, so children recompute the same names.
private func memberCheckerBase(owner: Decl, key: String): String {
    "_contract_member_cond_" + sanitizeCheckerPart(canonicalDeclaringTypeName(declaredTypeName(owner))) +
        "_" + sanitizeCheckerPart(key) + "_"
}

/**
 * @brief Generates the condition checkers for every member contract this type
 * declares itself (keys carrying this type's provenance).
 *
 * One checker per materializable `requires`/`ensures` clause, named `<base><ordinal>`
 * with ordinals counting those clauses across the member's stored attribute — the
 * same enumeration the inheriting side uses to materialize calls. Conditions carrying
 * `$pre` snapshots, referencing function-level contract variables, or already
 * materialized by an ancestor stay textual and get no checker.
 *
 * @param contract The resolved type contract holding the member attributes.
 * @param body The declared body of the type, providing the member declarations.
 * @param typeName The declared name of the type, canonicalized into the checker names.
 * @return The generated checker declarations, in clause order.
 */
public func genMemberConditionCheckers(contract: ResolvedTypeContract, body: Body,
    typeName: String): ArrayList<Decl> {
    let checkers = ArrayList<Decl>()
    for ((key, attr) in contract.memberAttrs) {
        // Own-key provenance, not `memberAttrOrigins`: unlabeled clauses record no attr names
        // (the origin map exists for name-conflict reporting and stays empty for them).
        if (!contract.ownMemberAttrKeys.contains(key)) {
            continue
        }
        let method = match (findMemberBySignature(body, key)) {
            case Some(value) => value
            case None => continue
        }
        let parsed = parseFunctionContract(attr)
        if (parsed.hasError()) {
            continue
        }
        appendMemberConditionCheckers(checkers, memberCheckerNameBase(typeName, key), method, parsed.value,
            conditionVariableNames(parsed.value))
    }
    checkers
}

func findMemberBySignature(body: Body, key: String): ?FuncDecl {
    for (member in body.decls) {
        if (let candidate: FuncDecl <- member) {
            if (methodSignatureKey(candidate) == key) {
                return Some(candidate)
            }
        }
    }
    None
}

func conditionVariableNames(contract: FunctionContract): HashSet<String> {
    let variableNames = HashSet<String>()
    for (clause in contract.clauses) {
        if (let FunctionClause.Variable(c) <- clause) {
            variableNames.add(c.name.name)
        }
    }
    variableNames
}

func appendMemberConditionCheckers(checkers: ArrayList<Decl>, base: String, method: FuncDecl,
    contract: FunctionContract, variableNames: HashSet<String>): Unit {
    var ordinal: Int64 = 0
    for (clause in contract.clauses) {
        match (clause) {
            case FunctionClause.Requires(c) =>
                if (memberConditionIsMaterializable(c.condition.tokens, variableNames)) {
                    checkers.add(genMemberConditionChecker(base + ordinal.toString(), method,
                        c.condition.tokens, None))
                }
                ordinal += 1
            case FunctionClause.Ensures(c) =>
                if (memberConditionIsMaterializable(c.condition.tokens, variableNames) &&
                    (c.ret.isNone() || funcDeclReturnType(method).isSome())) {
                    checkers.add(genMemberConditionChecker(base + ordinal.toString(), method,
                        c.condition.tokens, c.ret))
                }
                ordinal += 1
            case _ => ()
        }
    }
}

/// Checker-name base recomputed from the registered type name; the `typeName` argument of
/// `genTypeBody` is the declared (simple) name, canonicalized exactly like the metadata's
/// `fullName` so both spellings sanitize to the same checker prefix.
func memberCheckerNameBase(typeName: String, key: String): String {
    "_contract_member_cond_" + sanitizeCheckerPart(canonicalDeclaringTypeName(typeName)) +
        "_" + sanitizeCheckerPart(key) + "_"
}

/// The declared return type of `method`, or None when the compiler-provided node is missing.
func funcDeclReturnType(method: FuncDecl): ?TypeNode {
    try {
        Some(method.declType)
    } catch (_: Exception) {
        None
    }
}

/// The visibility keyword the checker mirrors from the checked member. A checker is never
/// more visible than the member itself, so an `internal`/`private` member whose parameter or
/// return types are not public stays compilable.
func checkerVisibility(owner: FuncDecl): Token {
    match (visibilityOf(owner.modifiers)) {
        case ContractVisibility.Private => Token(IDENTIFIER, "private")
        case ContractVisibility.Internal => Token(IDENTIFIER, "internal")
        case ContractVisibility.Protected => Token(IDENTIFIER, "protected")
        case ContractVisibility.Public => Token(IDENTIFIER, "public")
    }
}

/// One checker with the member's visibility: the method's parameters (plus the named result
/// binding for `ensures`) as formals, the condition as the body, so the predicate evaluates
/// in the declaring scope.
func genMemberConditionChecker(checkerName: String, owner: FuncDecl, condition: Tokens,
    ret: ?IdentifierSyntax): Decl {
    let name = Token(IDENTIFIER, checkerName)
    let visibility = checkerVisibility(owner)
    let staticModifier = if (methodHasModifier(owner, "static")) {
        quote(static)
    } else {
        Tokens()
    }
    let params = Tokens()
    var first = true
    for (parameter in owner.funcParams) {
        if (!first) {
            params.append(Token(COMMA))
        }
        first = false
        params.append(Token(IDENTIFIER, parameter.identifier.value)).append(Token(COLON))
            .append(parameter.paramType.toTokens())
    }
    if (let Some(binding) <- ret) {
        if (!first) {
            params.append(Token(COMMA))
        }
        match (funcDeclReturnType(owner)) {
            case Some(retType) =>
                params.append(binding.tokens).append(Token(COLON)).append(retType.toTokens())
            case None => ()
        }
    }
    // Method-level type parameters and their `where` bounds must be re-declared on the
    // checker: the copied parameter/return types and the condition itself can reference
    // them, and they are not in scope in the class body where the checker is placed.
    let generics = if (owner.isGenericDecl) {
        owner.genericParam.toTokens()
    } else {
        Tokens()
    }
    let whereClause = Tokens()
    var firstConstraint = true
    for (constraint in owner.genericConstraint) {
        if (!firstConstraint) {
            whereClause.append(Token(COMMA))
        }
        firstConstraint = false
        whereClause.append(constraint.toTokens())
    }
    FuncDecl(
        quote(
        $(visibility) $(staticModifier) func $(name)$(generics)($(params)): Bool $(whereClause) {
            return $(condition)
        }
    ))
}

func skipMethod(method: FuncDecl, declared: HashSet<String>): Bool {
    let name = method.identifier.value
    declared.contains(name) || name == "_contract_body" || name.startsWith("_contract_invariant_body") ||
        name == "_contract_property_body" || name.startsWith("_contract_property_body_")
}

func isConcreteMethod(method: FuncDecl): Bool {
    method.identifier.value != "init" && isValue(method.keyword, "func") && !method.isConst() &&
        !astGetOrDefault(true) {=> method.block.toTokens().size == 0}
}

func appendGenerated(members: ArrayList<Decl>, generated: Tokens): Unit {
    // A struct mut member may generate a wrapper plus a private helper method.
    let holder = quote(struct ContractGenerated { $(generated) })
    try {
        let wrapper = StructDecl(holder)
        members.add(all: wrapper.body.decls)
    } catch (e: ASTException) {
        diagReport(DiagReportLevel.WARNING, holder,
            "could not parse the generated contract holder struct; property/type contract checks may be skipped for this declaration",
            "Contract")
    }
}

/**
 * @brief Returns the real parameter name of the property's setter, or the canonical
 * `value` alias when the setter has no explicit parameter.
 *
 * Public so the direct-annotation path can re-parse clauses against the same alias
 * the type-level replay uses.
 *
 * @param property The property whose setter parameter is queried.
 * @return The setter parameter name, or `value` as the fallback alias.
 */
public func setterParameterName(property: PropDecl): String {
    try {
        accessorParameterName(property.setter)
    } catch (_: ASTException) {
        "value"
    }
}

/// Whether every accessor the type-level wrapping needs carries a body. Reading the
/// `.block` of a body-less accessor — or `.getter`/`.setter` itself on a property
/// lacking that accessor (an abstract member) — throws `ASTException`.
func propertyAccessorsHaveBodies(property: PropDecl, needGetter: Bool, needSetter: Bool): Bool {
    if (needGetter) {
        let getterOk = try {
            property.getter.block.toTokens().size != 0
        } catch (_: ASTException) {
            false
        }
        if (!getterOk) {
            return false
        }
    }
    if (needSetter) {
        let setterOk = try {
            property.setter.block.toTokens().size != 0
        } catch (_: ASTException) {
            false
        }
        if (!setterOk) {
            return false
        }
    }
    true
}

func hasOpenOrAbstract(modifiers: ArrayList<Modifier>): Bool {
    modifiersHave(modifiers, "open") || modifiersHave(modifiers, "abstract")
}

/// Names occupying the member namespace of a type: declared functions, properties
/// and fields, plus the properties generated for abstract (contract) variables.
func collectMemberNames(body: Body, contract: ResolvedTypeContract): HashSet<String> {
    let names = HashSet<String>()
    for (member in body.decls) {
        if (let method: FuncDecl <- member) {
            names.add(method.identifier.value)
        } else if (let property: PropDecl <- member) {
            names.add(property.identifier.value)
        } else if (let field: VarDecl <- member) {
            try {
                names.add(field.identifier.value)
            } catch (_: ASTException) {
                ()
            }
        }
    }
    for (variable in collectVariables(contract)) {
        names.add(variable.name.name)
    }
    names
}

/// Declared members only (functions, properties, fields): the namespace a member-level
/// `variable` clause must not collide with. Unlike `collectMemberNames` this excludes
/// type-level contract variables, whose generated properties a member-level `variable`
/// may deliberately shadow (the member body then reads the member-level slot).
func collectDeclaredMemberNames(body: Body): HashSet<String> {
    let names = HashSet<String>()
    for (member in body.decls) {
        if (let method: FuncDecl <- member) {
            names.add(method.identifier.value)
        } else if (let property: PropDecl <- member) {
            names.add(property.identifier.value)
        } else if (let field: VarDecl <- member) {
            try {
                names.add(field.identifier.value)
            } catch (_: ASTException) {
                ()
            }
        }
    }
    names
}

/// An `ensures <ret>: ...` clause binds `let <ret> = _contract_result` inside the
/// generated member body, so a same-named member would be shadowed and the
/// expression would silently observe the binding instead of the member.
internal func validateEnsuresReturnNames(contract: FunctionContract, memberNames: HashSet<String>,
    subject: String): Unit {
    for (clause in contract.clauses) {
        if (let Ensures(c) <- clause) {
            if (let Some(ret) <- c.ret) {
                if (memberNames.contains(ret.name)) {
                    diagReport(DiagReportLevel.ERROR, ret.tokens,
                        "`ensures` return name `" + ret.name + "` on `" + subject +
                        "` collides with a member of the enclosing type", "Contract")
                }
            }
        }
    }
}

/// Report an `ensures` return-name collision for one clause, if any.
internal func reportEnsuresReturnNameCollision(clause: FunctionClause, memberNames: HashSet<String>,
    subject: String): Unit {
    if (let Ensures(c) <- clause) {
        if (let Some(ret) <- c.ret) {
            if (memberNames.contains(ret.name)) {
                diagReport(DiagReportLevel.ERROR, ret.tokens,
                    "`ensures` return name `" + ret.name + "` on `" + subject +
                    "` collides with a member of the enclosing type", "Contract")
            }
        }
    }
}

/// Same check for the getter/setter sections of a property contract.
internal func validateEnsuresReturnNamesProperty(contract: PropContract, memberNames: HashSet<String>,
    subject: String): Unit {
    for (section in contract.clauses) {
        for (clause in section.clauses) {
            reportEnsuresReturnNameCollision(clause, memberNames, subject)
        }
    }
}
