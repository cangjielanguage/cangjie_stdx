/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.generate

import stdx.contract.macros.inheritance.{ContractMetaData, ResolvedTypeContract, attrOriginHasOwner, collectAllMemberSignatures, collectValueMemberNames, combineAttrs, declaredTypeParameters, expandMemberInherits, methodSignatureKey, recordDeclaredAttrOrigin, registerMetaData, reportInheritedNameConflicts, resolveTypeContract, unionInto}
import stdx.contract.macros.parse.{parseFunctionContract, parsePropertyContract}
import stdx.contract.macros.syntax.{Diagnostic, PropClause, PropContract, PropKind, TypeClause, TypeContract}
import stdx.contract.macros.tokens.{tokensStableKey}
import stdx.contract.runtime.ContractVisibility
import std.ast.{ASTException, Body, Decl, ExtendDecl, FuncDecl, InterfaceDecl, PropDecl, Token, Tokens, parseDecl}
import std.collection.{ArrayList, HashSet, contains, isEmpty}

/**
 * @brief Expands an interface type contract into the rewritten declaration tokens.
 *
 * Interfaces publish type-level clauses and member contracts for implementors:
 * abstract variables become abstract properties, concrete default members are wrapped
 * so the implementor's invariant checkpoints dispatch through the published per-origin
 * hooks, and the resolved metadata is registered for implementors. On diagnostics,
 * reports them and returns the owner unchanged.
 *
 * @param contract The parsed type contract clauses of the interface.
 * @param owner The interface declaration the contract was attached to.
 * @return The rewritten interface tokens with the published contract clauses.
 */
public func genInterfaceContract(contract: TypeContract, owner: InterfaceDecl): Tokens {
    let diagnostics = ArrayList<Diagnostic>()
    let resolved = resolveTypeContract(contract, owner, diagnostics)
    if (!diagnostics.isEmpty()) {
        for (diagnostic in diagnostics) {
            diagnostic.show()
        }
        return owner.toTokens()
    }
    let generated = InterfaceDecl(owner.toTokens())
    let members = ArrayList<Decl>()
    members.add(all: genInterfaceVariableDeclarations(resolved))
    let expansion = InterfaceExpansion(resolved, owner, diagnostics,
        collectMemberNames(generated.body, resolved))

    for (member in generated.body.decls) {
        processInterfaceMember(member, expansion, members)
    }
    // Publish per-origin `_contract_invariant_*` defaults for default-member checkpoint
    // dispatch, only when a default member actually carries a checkpoint. Plain
    // implementors inherit the empty defaults; others derive their own checkers.
    let hookSource = if (expansion.wrapsDefaultMembers) {
        collectInvariants(resolved)
    } else {
        ArrayList<ResolvedInvariant>()
    }
    for (hook in genInterfaceDefaultHooks(hookSource)) {
        members.add(hook)
    }
    generated.body = Body(members)

    if (!diagnostics.isEmpty()) {
        for (diagnostic in diagnostics) {
            diagnostic.show()
        }
        return owner.toTokens()
    }
    registerMetaData(
        ContractMetaData(owner.identifier.value, declaredTypeParameters(owner), resolved, isInterface: true,
            isOpen: true, memberAttrs: resolved.memberAttrs, propertyAttrs: resolved.propertyAttrs,
            memberAttrOrigins: resolved.memberAttrOrigins, propertyAttrOrigins: resolved.propertyAttrOrigins,
            allMemberSignatures: unionInto(collectAllMemberSignatures(generated.body),
                resolved.inheritedMemberSignatures),
            valueNames: collectValueMemberNames(generated.body),
            memberParamNames: resolved.memberParamNames))
    generated.toTokens()
}

/// State shared while expanding the members of one interface contract.
class InterfaceExpansion {
    let resolved: ResolvedTypeContract
    let owner: InterfaceDecl
    let diagnostics: ArrayList<Diagnostic>
    let memberNames: HashSet<String>
    var wrapsDefaultMembers = false

    init(resolved: ResolvedTypeContract, owner: InterfaceDecl, diagnostics: ArrayList<Diagnostic>,
        memberNames: HashSet<String>) {
        this.resolved = resolved
        this.owner = owner
        this.diagnostics = diagnostics
        this.memberNames = memberNames
    }
}

func processInterfaceMember(member: Decl, expansion: InterfaceExpansion, members: ArrayList<Decl>): Unit {
    if (let method: FuncDecl <- member) {
        processInterfaceMethod(method, expansion, members)
    } else if (let property: PropDecl <- member) {
        processInterfaceProperty(property, expansion, members)
    } else {
        members.add(member)
    }
}

func processInterfaceMethod(method: FuncDecl, expansion: InterfaceExpansion,
    members: ArrayList<Decl>): Unit {
    // Lower contracts deferred by local functions inside concrete members.
    absorbLocalFunctionContracts(method)
    let key = methodSignatureKey(method)
    // The interface's own parameter names: ancestor clause text is renamed to them
    // and implementors rename their positional counterparts from the metadata.
    let methodParams = methodParameterNames(method)
    let raw = findDeferredMethodAttr(method)
    let attr = expandMemberInherits(raw, key, false, expansion.owner, expansion.diagnostics,
        childParams: (methodParams, methodHasModifier(method, "static")))
    // The member's own parameter names override any propagated record: the stored
    // clause text is renamed to (or declared with) exactly these names. Interfaces
    // publish no condition checkers, so no checker base is recorded.
    expansion.resolved.recordMemberParamNames(key, methodParams)
    if (attr.size > 0) {
        mergeInterfaceMethodContract(expansion, key, raw, attr)
    }
    // Concrete default members are wrapped even without their own
    // contract, so the implementor's invariant checkpoint is dispatched on the
    // default-member path.
    if (!isConcreteMethod(method)) {
        members.add(method)
        return
    }
    let checks = genInterfaceDefaultChecks(collectInvariants(expansion.resolved),
        visibilityOf(method.modifiers, defaultVisibility: ContractVisibility.Public),
        methodHasModifier(method, "static"))
    if (checks.size > 0) {
        // Hooks are published only when a default member actually
        // carries a checkpoint — see `genInterfaceDefaultHooks`.
        expansion.wrapsDefaultMembers = true
    }
    if (attr.size == 0 && checks.size == 0) {
        members.add(method)
        return
    }
    let parsed = parseFunctionContract(attr)
    for (diagnostic in parsed.diagnostics) {
        diagnostic.show()
    }
    if (parsed.hasError()) {
        members.add(method)
        return
    }
    validateEnsuresReturnNames(parsed.value, expansion.memberNames, method.identifier.value)
    let generated = if (checks.size > 0) {
        if (methodHasModifier(method, "mut")) {
            // A local helper cannot touch the receiver of a `mut` default member, so its
            // body is hoisted into a sibling `mut` member. Interface members cannot be
            // `private`, so the helper is emitted without a visibility modifier.
            GenStructMember(parsed.value, method, invariants: Some(checks), privateHelper: false).gen()
        } else {
            GenClassMember(parsed.value, method, invariants: Some(checks)).gen()
        }
    } else {
        genFunction(parsed.value, method)
    }
    appendGenerated(members, generated)
}

func methodParameterNames(method: FuncDecl): ArrayList<String> {
    let names = ArrayList<String>()
    for (parameter in method.funcParams) {
        try {
            names.add(parameter.identifier.value)
        } catch (_: ASTException) {
            ()
        }
    }
    names
}

/// Merge a method contract with the inherited one, reporting name conflicts and
/// recording the interface as the clause provenance.
func mergeInterfaceMethodContract(expansion: InterfaceExpansion, key: String, raw: Tokens,
    attr: Tokens): Unit {
    let resolved = expansion.resolved
    // Parent contracts are inherited only through `inherits from`; without it they
    // merely guard the redeclaration from reusing a same-kind name.
    let parent = match (resolved.memberAttrs.get(key)) {
        case Some(inherited) => Some(inherited)
        case None => resolved.parentMemberAttrs.get(key)
    }
    match (parent) {
        case Some(inherited) =>
            reportInheritedNameConflicts(inherited, raw, "override of `${key}`",
                expansion.diagnostics, attr)
        case None => ()
    }
    if (resolved.conformingMemberSignatures.contains(key)) {
        // Only a locally written `requires` strengthens the
        // precondition, and only on members inherited from the conforming parent.
        reportConformingRequires(raw, key, expansion.diagnostics)
    }
    // Merge with inherited contracts instead of overwriting them, so a
    // redeclared interface member keeps the ancestor clauses.
    resolved.appendMemberAttr(key, attr)
    // A contract this interface declares carries this interface as provenance,
    // even when the member also carries an inherited ancestor contract: sibling
    // parents redeclaring the same name must still conflict (diamond). Only the
    // same declaring type is skipped, so re-recording stays idempotent.
    if (!attrOriginHasOwner(resolved.memberAttrOrigins, key, expansion.owner.identifier.value)) {
        recordDeclaredAttrOrigin(resolved, key, raw, expansion.owner.identifier.value)
    }
    // A default method body must carry its contract checks so that
    // implementors inheriting the body keep the parent's checks.
}

func processInterfaceProperty(property: PropDecl, expansion: InterfaceExpansion,
    members: ArrayList<Decl>): Unit {
    let raw = findDeferredPropertyAttr(property)
    let name = property.identifier.value
    let attr = expandMemberInherits(raw, name, true, expansion.owner, expansion.diagnostics)
    // Lower contracts deferred by local functions inside accessor bodies before
    // the accessors are rebuilt, so the wrapped bodies carry the lowered forms.
    absorbPropertyLocalContracts(property)
    if (attr.size > 0) {
        mergeInterfacePropertyContract(expansion, name, raw, attr)
    }
    // A concrete default property is rebuilt like a concrete default method: each
    // accessor hosts the property's own contract checks plus the implementor's
    // invariant checkpoints through the published per-origin hooks. An abstract
    // property (no accessor bodies) keeps the declaration unchanged — its recorded
    // contract alone is forwarded to implementors.
    let checks = genInterfaceDefaultChecks(collectInvariants(expansion.resolved),
        visibilityOf(property.modifiers, defaultVisibility: ContractVisibility.Public),
        modifiersHave(property.modifiers, "static"))
    let (needGetter, needSetter, parseFailed, parsedContract) =
        parseInterfacePropertyContract(attr, property, checks.size)
    // The setter wrapper is skipped for non-`mut` properties, so only a `mut`
    // accessor needs its body checked.
    let isMutProperty = modifiersHave(property.modifiers, "mut")
    let setterNeedsBodyCheck = needSetter && isMutProperty
    let accessorsHaveBodies = propertyAccessorsHaveBodies(property, needGetter, setterNeedsBodyCheck)
    if (attr.size == 0 && checks.size == 0 || parseFailed || !accessorsHaveBodies) {
        members.add(property)
        return
    }
    // Hooks are published only when a default member actually carries a
    // checkpoint — see `genInterfaceDefaultHooks`.
    if (checks.size > 0) {
        expansion.wrapsDefaultMembers = true
    }
    let contract = match (parsedContract) {
        case Some(parsed) => parsed
        case None => PropContract(Tokens())
    }
    validateEnsuresReturnNamesProperty(contract, expansion.memberNames, name)
    appendGenerated(members, genPropertyContract(contract, property,
        ArrayList<ResolvedInvariant>(), false, HashSet<String>(), invariantChecks: Some(checks)))
}

/// Parse the property contract and report whether each accessor needs its body checked.
func parseInterfacePropertyContract(attr: Tokens, property: PropDecl, checksSize: Int64):
    (Bool, Bool, Bool, ?PropContract) {
    var needGetter = checksSize > 0
    var needSetter = checksSize > 0
    var parseFailed = false
    var parsedContract: ?PropContract = None
    if (attr.size > 0) {
        let parsed = parsePropertyContract(attr, setterAlias: setterParameterName(property))
        for (diagnostic in parsed.diagnostics) {
            diagnostic.show()
        }
        if (parsed.hasError()) {
            parseFailed = true
        } else {
            parsedContract = Some(parsed.value)
            let (hasGetter, hasSetter) = declaredPropertyKinds(parsed.value.clauses)
            needGetter = needGetter || hasGetter
            needSetter = needSetter || hasSetter
        }
    }
    (needGetter, needSetter, parseFailed, parsedContract)
}

/// Which accessors the property contract declares a clause for.
func declaredPropertyKinds(clauses: ArrayList<PropClause>): (Bool, Bool) {
    var hasGetter = false
    var hasSetter = false
    for (clause in clauses) {
        match (clause.kind) {
            case PropKind.Getter => hasGetter = true
            case PropKind.Setter => hasSetter = true
        }
    }
    (hasGetter, hasSetter)
}

func mergeInterfacePropertyContract(expansion: InterfaceExpansion, name: String, raw: Tokens,
    attr: Tokens): Unit {
    let resolved = expansion.resolved
    let parent = match (resolved.propertyAttrs.get(name)) {
        case Some(inherited) => Some(inherited)
        case None => resolved.parentPropertyAttrs.get(name)
    }
    match (parent) {
        case Some(inherited) =>
            reportInheritedNameConflicts(inherited, raw, "override of property `${name}`",
                expansion.diagnostics, attr, property: true)
        case None => ()
    }
    if (resolved.conformingMemberSignatures.contains(name)) {
        reportConformingPropertyRequires(raw, name, expansion.diagnostics)
    }
    resolved.appendPropertyAttr(name, attr)
    if (!attrOriginHasOwner(resolved.propertyAttrOrigins, name, expansion.owner.identifier.value)) {
        recordDeclaredAttrOrigin(resolved, name, raw, expansion.owner.identifier.value, property: true)
    }
}

/// Interfaces declare their abstract variables as abstract properties; implementors supply the
/// storage and a same-name public property.
func genInterfaceVariableDeclarations(contract: ResolvedTypeContract): ArrayList<Decl> {
    let declarations = ArrayList<Decl>()
    for (resolved in contract.clauses) {
        if (let TypeClause.Variable(variable) <- resolved.clause) {
            let name = Token(IDENTIFIER, variable.name.name)
            let typeTokens = variable.ty.tokens
            let modifiers = if (variable.isStatic) {
                quote(static mut)
            } else {
                quote(mut)
            }
            declarations.add(parseDecl(quote($(modifiers) prop $(name): $(typeTokens))))
        }
    }
    declarations
}

/**
 * @brief Expands a contract attached to an `extend` declaration.
 *
 * `extend` may inherit member contracts, but must not add variables or invariants:
 * such type-level clauses are reported as diagnostics. Member contracts combine the
 * inherited and own clauses and wrap the extended members accordingly.
 *
 * @param contract The parsed type contract clauses of the extend declaration.
 * @param owner The extend declaration the contract was attached to.
 * @return The rewritten extend tokens with the generated member checks.
 */
public func genExtendContract(contract: TypeContract, owner: ExtendDecl): Tokens {
    let diagnostics = ArrayList<Diagnostic>()
    let resolved = resolveTypeContract(contract, owner, diagnostics)
    reportExtendTypeLevelClauses(resolved, diagnostics)
    let generated = ExtendDecl(owner.toTokens())
    let members = ArrayList<Decl>()
    let expansion = ExtendExpansion(resolved, owner, diagnostics,
        collectMemberNames(generated.body, resolved), ArrayList<ResolvedInvariant>(), HashSet<String>())
    for (member in generated.body.decls) {
        processExtendMember(member, expansion, members)
    }
    if (!diagnostics.isEmpty()) {
        for (diagnostic in diagnostics) {
            diagnostic.show()
        }
        return owner.toTokens()
    }
    generated.body = Body(members)
    generated.toTokens()
}

/// State shared while expanding the members of one extend contract.
class ExtendExpansion {
    let resolved: ResolvedTypeContract
    let owner: ExtendDecl
    let diagnostics: ArrayList<Diagnostic>
    let memberNames: HashSet<String>
    let invariants: ArrayList<ResolvedInvariant>
    let declared: HashSet<String>

    init(resolved: ResolvedTypeContract, owner: ExtendDecl, diagnostics: ArrayList<Diagnostic>,
        memberNames: HashSet<String>, invariants: ArrayList<ResolvedInvariant>, declared: HashSet<String>) {
        this.resolved = resolved
        this.owner = owner
        this.diagnostics = diagnostics
        this.memberNames = memberNames
        this.invariants = invariants
        this.declared = declared
    }
}

/// `extend` may inherit member contracts, but must not add variables or invariants.
func reportExtendTypeLevelClauses(resolved: ResolvedTypeContract,
    diagnostics: ArrayList<Diagnostic>): Unit {
    for (entry in resolved.clauses) {
        match (entry.clause) {
            case TypeClause.Variable(variable) =>
                diagnostics.add(
                    Diagnostic("extend type-level contracts cannot declare or inherit abstract variables",
                        "extend contract", variable.tokens))
            case TypeClause.Invariant(invariant) =>
                diagnostics.add(
                    Diagnostic("extend type-level contracts cannot declare or inherit invariants", "extend contract",
                        invariant.tokens))
            case _ => ()
        }
    }
}

func processExtendMember(member: Decl, expansion: ExtendExpansion, members: ArrayList<Decl>): Unit {
    if (let method: FuncDecl <- member) {
        processExtendMethod(method, expansion, members)
    } else if (let property: PropDecl <- member) {
        processExtendProperty(property, expansion, members)
    } else {
        members.add(member)
    }
}

func processExtendMethod(method: FuncDecl, expansion: ExtendExpansion, members: ArrayList<Decl>): Unit {
    // Lower contracts deferred by local functions inside concrete members.
    absorbLocalFunctionContracts(method)
    let key = methodSignatureKey(method)
    let inherited = inheritedExtendMemberAttr(expansion, key, false)
    let raw = findDeferredMethodAttr(method)
    let own = expandMemberInherits(raw, key, false, expansion.owner, expansion.diagnostics)
    let attr = combineAttrs(inherited, own)
    if (attr.size > 0) {
        if (own.size > 0 && expansion.resolved.conformingMemberSignatures.contains(key) &&
            tokensStableKey(inherited) != tokensStableKey(own)) {
            // Only a locally written `requires` strengthens the precondition. The
            // signature check (not the presence of an inherited contract) tells an
            // override from a brand-new extension member, scoped to the conforming parent.
            reportConformingRequires(raw, key, expansion.diagnostics)
        }
        let parsed = parseFunctionContract(attr)
        for (diagnostic in parsed.diagnostics) {
            diagnostic.show()
        }
        if (!parsed.hasError()) {
            validateEnsuresReturnNames(parsed.value, expansion.memberNames, method.identifier.value)
            appendGenerated(members, genFunction(parsed.value, method))
            return
        }
    }
    members.add(method)
}

func processExtendProperty(property: PropDecl, expansion: ExtendExpansion,
    members: ArrayList<Decl>): Unit {
    let name = property.identifier.value
    let inherited = inheritedExtendMemberAttr(expansion, name, true)
    let raw = findDeferredPropertyAttr(property)
    let own = expandMemberInherits(raw, name, true, expansion.owner, expansion.diagnostics)
    let attr = combineAttrs(inherited, own)
    if (attr.size > 0) {
        if (own.size > 0 && expansion.resolved.conformingMemberSignatures.contains(name) &&
            tokensStableKey(inherited) != tokensStableKey(own)) {
            // The signature check distinguishes overrides from new members,
            // scoped to the conforming parent.
            reportConformingPropertyRequires(raw, name, expansion.diagnostics)
        }
        let parsed = parsePropertyContract(attr, setterAlias: setterParameterName(property))
        for (diagnostic in parsed.diagnostics) {
            diagnostic.show()
        }
        if (!parsed.hasError()) {
            validateEnsuresReturnNamesProperty(parsed.value, expansion.memberNames, property.identifier.value)
            // The extended type's kind (class or struct) is invisible here, so the
            // setter wrapper must take the host-agnostic inline shape: the class-style
            // local helper would be illegal inside a struct `mut` accessor, where it
            // captures the mutable receiver.
            appendGenerated(members,
                genPropertyContract(parsed.value, property, expansion.invariants, false, expansion.declared,
                    hostKnown: false))
            return
        }
    }
    members.add(property)
}

/// The inherited contract of an extend member, or empty tokens when none is recorded.
func inheritedExtendMemberAttr(expansion: ExtendExpansion, key: String, property: Bool): Tokens {
    let found = if (property) {
        expansion.resolved.propertyAttrs.get(key)
    } else {
        expansion.resolved.memberAttrs.get(key)
    }
    match (found) {
        case Some(attr) => attr
        case None => Tokens()
    }
}
