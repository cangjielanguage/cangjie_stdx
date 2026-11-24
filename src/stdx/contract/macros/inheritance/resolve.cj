/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.inheritance

import stdx.contract.macros.parse.{parseFunctionContract, parsePropertyContract}
import stdx.contract.macros.syntax.{Diagnostic, FunctionClause, IdentifierSyntax, InheritClauseKind, InvariantClause, TypeClause, TypeContract, TypeInheritTarget, TypeInheritsClause, TypeSyntax, VariableClause}
import stdx.contract.macros.tokens.{precededByDot, tokenValuesCompactString, tokensStableKey}
import std.ast.{ASTException, ClassDecl, Decl, ExtendDecl, FuncDecl, InterfaceDecl, QualifiedType, RefType, StructDecl, Token, TokenKind, Tokens, TypeNode, compareTokens}
import std.collection.{ArrayList, HashMap, HashSet, contains}

/**
 * @brief Expand `inherits from` and `inherits invariant` clauses using metadata registered by
 * already-expanded parent contracts.
 *
 * The result keeps this type's own clauses in source order and merges in everything the
 * annotated parents publish: class-level auxiliary variables are inherited from every
 * annotated direct parent even without an explicit `inherits from` clause, while member and
 * property contract attributes, transitive member signatures, parameter-name and checker-base
 * records, and per-name provenance are merged for later member expansion and conflict
 * checks.
 *
 * @param contract The `@Contract` attribute clauses of the type being expanded.
 * @param owner The class, struct or interface declaration carrying the attribute.
 * @param diagnostics Expansion diagnostics.
 * @return The resolved type contract, ready to be registered as `ContractMetaData`.
 */
public func resolveTypeContract(contract: TypeContract, owner: Decl,
    diagnostics: ArrayList<Diagnostic>): ResolvedTypeContract {
    let resolved = ResolvedTypeContract(contract.tokens)
    // Canonical qualified form: keeps `ClauseOrigin.declaringType` comparisons and the
    // generated checker suffixes stable when `CANGJIE_STDX_CONTRACT_PKG_NAME` is set.
    let ownerName = canonicalDeclaringTypeName(declaredTypeName(owner))
    let parameters = declaredTypeParameters(owner)
    let arguments = formalTypeArguments(parameters)
    // This type's own member parameters: inherited clause conditions are renamed positionally
    // from the parent's recorded names to these (#8) and call checkers with these (#9).
    let childParams = collectChildMemberParams(owner)

    // Class-level auxiliary variables are always inherited from every annotated direct parent,
    // whether or not the child writes `inherits from`.
    for (superType in declaredSuperTypes(owner)) {
        inheritClassVariables(resolved, superType, diagnostics)
        recordParentMemberAttrs(resolved, superType)
    }

    // Explicit `inherits from` clauses are expanded next, in source order.
    for (clause in contract.clauses) {
        if (let TypeClause.Inherits(inherits) <- clause) {
            resolveInherits(inherits, owner, diagnostics, resolved, childParams)
        }
    }

    // Newly declared and selectively inherited clauses follow the full-inheritance clauses.
    for (index in 0..contract.clauses.size) {
        let clause = contract.clauses[index]
        match (clause) {
            case TypeClause.Inherits(_) =>
                // Already handled above.
                ()
            case TypeClause.InvariantInherit(target) =>
                for (inherited in resolveInvariantInherit(target, owner, diagnostics, arguments, index)) {
                    resolved.add(inherited)
                }
            case _ =>
                resolved.add(ResolvedTypeClause(ClauseOrigin(ownerName, index, arguments), clause))
        }
    }
    validateResolvedDuplicates(resolved, diagnostics)
    validateConformingInvariants(resolved, ownerName, diagnostics)
    validateCrossOriginNames(resolved, diagnostics)
    resolved
}

/// Class-level auxiliary variables are always inherited, even without an `inherits from` clause;
/// only the `variable` clauses of each annotated parent are taken here.
func inheritClassVariables(resolved: ResolvedTypeContract, superType: TypeNode,
    diagnostics: ArrayList<Diagnostic>): Unit {
    let name = match (qualifiedTypeName(superType)) {
        case Some(value) => value
        case None => return
    }
    let meta = match (searchMetaData(name)) {
        case Some(value) => value
        case None => return
    }
    let actual = typeArguments(superType)
    if (actual.size != meta.typeArgs.size) {
        diagnostics.add(
            Diagnostic("wrong number of type arguments for `${name}`", "contract inheritance", superType.toTokens()))
        return
    }
    let expanded = match (substituteContract(meta.contracts, TypeSubstitution(meta.typeArgs, actual, meta.valueNames),
        diagnostics, emitStorage: meta.isInterface, fromInterface: meta.isInterface)) {
        case Some(value) => value
        case None => return
    }
    for (inherited in expanded.clauses) {
        if (let TypeClause.Variable(_) <- inherited.clause) {
            resolved.add(inherited)
        }
    }
}

/// Remember the member contracts of an annotated direct parent without inheriting them: an
/// override may not redeclare a same-kind name on the same member.
func recordParentMemberAttrs(resolved: ResolvedTypeContract, superType: TypeNode): Unit {
    let name = match (qualifiedTypeName(superType)) {
        case Some(value) => value
        case None => return
    }
    match (searchMetaData(name)) {
        case Some(meta) =>
            // The override's contracts are keyed by its own instantiated signatures, so the
            // guard must compare against instantiated parent keys.
            // `inheritClassVariables` already diagnosed a wrong argument count.
            let actual = typeArguments(superType)
            if (actual.size != meta.typeArgs.size) {
                return
            }
            resolved.mergeParentMemberAttrs(instantiateMemberAttrs(meta.memberAttrs, meta.typeArgs, actual,
                meta.valueNames))
            resolved.mergeParentPropertyAttrs(instantiatePropertyAttrs(meta.propertyAttrs, meta.typeArgs, actual,
                meta.valueNames))
        case None => ()
    }
}

/// Resolve `<type>` into its registered metadata, checking it names a direct parent type.
func parentMeta(ty: TypeSyntax, owner: Decl, diagnostics: ArrayList<Diagnostic>,
    clauseTokens: Tokens): ?(String, ContractMetaData, ArrayList<TypeNode>) {
    let node = match (ty.parsed) {
        case Some(value) where value is RefType || value is QualifiedType => value
        case _ =>
            diagnostics.add(
                Diagnostic("inheritance reference must name a parent class or interface", "contract inheritance",
                    clauseTokens))
            return None
    }
    if (!declaredSuper(node, owner)) {
        diagnostics.add(
            Diagnostic("inheritance reference does not match a declared parent type: `${node.toTokens()}`",
                "contract inheritance", clauseTokens))
        return None
    }
    let name = match (qualifiedTypeName(node)) {
        case Some(value) => value
        case None =>
            diagnostics.add(
                Diagnostic("inheritance reference must name a parent class or interface", "contract inheritance",
                    clauseTokens))
            return None
    }
    let meta = match (searchMetaData(name)) {
        case Some(value) => value
        case None =>
            diagnostics.add(
                Diagnostic(
                    "parent contract metadata is unavailable for `${name}`: the parent `@Contract` type must be " +
                    "expanded before this type in the same package; cross-package inheritance needs a `.cmeta` record " +
                    "produced by building the parent with CANGJIE_STDX_CONTRACT_PKG_NAME and CANGJIE_STDX_CONTRACT_META_DIR set",
                    "contract inheritance", clauseTokens))
            return None
    }
    let actual = typeArguments(node)
    if (actual.size != meta.typeArgs.size) {
        diagnostics.add(
            Diagnostic("wrong number of type arguments for `${name}`", "contract inheritance", clauseTokens))
        return None
    }
    Some((name, meta, actual))
}

/// This type's member parameter facts per signature key: ordered parameter names (positional
/// rename targets for inherited clause conditions) and whether the member is `static` (a
/// static replay calls its checker without a receiver).
private func collectChildMemberParams(owner: Decl): HashMap<String, (ArrayList<String>, Bool)> {
    let result = HashMap<String, (ArrayList<String>, Bool)>()
    let body = match (owner) {
        case value: ClassDecl => value.body
        case value: StructDecl => value.body
        case value: InterfaceDecl => value.body
        case _ => return result
    }
    for (member in body.decls) {
        if (let method: FuncDecl <- member) {
            if (method.identifier.value == "init") {
                continue
            }
            result.add(methodSignatureKey(method), childMemberParamEntry(method))
        }
    }
    result
}

/// The ordered parameter names of one member and whether it is `static`.
private func childMemberParamEntry(method: FuncDecl): (ArrayList<String>, Bool) {
    let names = ArrayList<String>()
    for (parameter in method.funcParams) {
        try {
            names.add(parameter.identifier.value)
        } catch (_: ASTException) {
            ()
        }
    }
    var isStatic = false
    for (modifier in method.modifiers) {
        if (modifier.keyword.value == "static") {
            isStatic = true
        }
    }
    (names, isStatic)
}

func resolveInherits(clause: TypeInheritsClause, owner: Decl, diagnostics: ArrayList<Diagnostic>,
    resolved: ResolvedTypeContract, childParams: HashMap<String, (ArrayList<String>, Bool)>): Unit {
    let (_, meta, actual) = match (parentMeta(clause.target.getType(), owner, diagnostics, clause.tokens)) {
        case Some(value) => value
        case None => return
    }
    if (clause.isConforming) {
        resolved.conforming = true
        // `[conforming]` only restricts the members of the conforming parent; overrides of
        // other parents may still strengthen their preconditions. Signatures carrying the
        // parent's type parameters are instantiated with the clause's type arguments.
        for (signature in meta.allMemberSignatures) {
            resolved.conformingMemberSignatures.add(instantiateSignatureKey(signature, meta.typeArgs, actual))
        }
    }
    inheritParent(resolved, meta, ParentInstantiation(actual, childParams), diagnostics, clause.tokens)
}

/// The parent's concrete type arguments and the child's per-signature parameter facts.
class ParentInstantiation {
    let actual: ArrayList<TypeNode>
    let childParams: HashMap<String, (ArrayList<String>, Bool)>

    init(actual: ArrayList<TypeNode>, childParams: HashMap<String, (ArrayList<String>, Bool)>) {
        this.actual = actual
        this.childParams = childParams
    }
}

/// Expand a parent's whole contract into the current type.
func inheritParent(resolved: ResolvedTypeContract, meta: ContractMetaData,
    instantiation: ParentInstantiation, diagnostics: ArrayList<Diagnostic>, clauseTokens: Tokens): Unit {
    let actual = instantiation.actual
    let expanded = match (substituteContract(meta.contracts, TypeSubstitution(meta.typeArgs, actual, meta.valueNames),
        diagnostics, emitStorage: meta.isInterface, fromInterface: meta.isInterface)) {
        case Some(value) => value
        case None => return
    }
    // The parent's attribute keys and clause bodies use its formal type parameters;
    // instantiate everything with the clause's actual arguments before the conflict checks
    // and merges, so lookups by the child's signatures succeed. Member clauses are adapted
    // for the child scope at the same time: parameters are renamed positionally (#8) and
    // materializable conditions become calls to the ancestor's public checkers (#9).
    let memberAttrs = instantiateAdaptedMemberAttrs(meta, actual, instantiation.childParams, diagnostics)
    let propertyAttrs = instantiatePropertyAttrs(meta.propertyAttrs, meta.typeArgs, actual, meta.valueNames)
    let memberAttrOrigins = instantiateMemberAttrOrigins(meta.memberAttrOrigins, meta.typeArgs, actual)
    // Propagate the parent's per-member records so grandchildren keep renaming parameters and
    // addressing the original declaring type's checkers; this type's own records (absorbed
    // later from its declarations) take precedence.
    resolved.mergeMemberParamNames(instantiateMemberParamNames(meta, actual))
    resolved.mergeMemberCheckerBases(instantiateMemberCheckerBases(meta, actual))
    checkMemberAttrConflicts(resolved.memberAttrs, memberAttrs, diagnostics, clauseTokens)
    checkPropertyAttrConflicts(resolved.propertyAttrs, propertyAttrs, diagnostics, clauseTokens)
    // Identical-text contracts from unrelated parents still conflict on their name; the same
    // ancestor reached through two paths must not (diamond).
    checkAttrOriginConflicts(resolved.memberAttrOrigins, memberAttrOrigins,
        {key => "inherited contracts for `${key}`"}, diagnostics, clauseTokens)
    // Property keys and their provenance owners are plain names with no method type
    // parameters, so `meta.propertyAttrOrigins` is deliberately merged uninstantiated;
    // "symmetrically" instantiating it here would corrupt names instead.
    checkAttrOriginConflicts(resolved.propertyAttrOrigins, meta.propertyAttrOrigins,
        {key => "inherited contracts for property `${key}`"}, diagnostics, clauseTokens)
    resolved.mergeMemberAttrs(memberAttrs)
    resolved.mergePropertyAttrs(propertyAttrs)
    resolved.mergeMemberAttrOrigins(memberAttrOrigins)
    resolved.mergePropertyAttrOrigins(meta.propertyAttrOrigins)
    // Remember every member reachable through this parent so `[conforming]` can distinguish
    // overriding members from brand-new ones.
    resolved.mergeInheritedSignatures(instantiateMemberSignatures(meta.allMemberSignatures, meta.typeArgs, actual))
    if (!meta.isInterface && !meta.isOpen) {
        for (inherited in expanded.clauses) {
            if (let TypeClause.Invariant(_) <- inherited.clause) {
                diagnostics.add(
                    Diagnostic("parent class contract `${meta.typeName}` must be declared `open` to inherit invariants",
                        "contract inheritance", clauseTokens))
                return
            }
        }
    }
    for (inherited in expanded.clauses) {
        resolved.add(inherited)
    }
}

/// Resolve `inherits invariant <type>.<name>` / `inherits invariant <new> = <type>.<name>`.
func resolveInvariantInherit(target: TypeInheritTarget, owner: Decl,
    diagnostics: ArrayList<Diagnostic>, arguments: ArrayList<TypeNode>, clauseIndex: Int64):
    ArrayList<ResolvedTypeClause> {
    let result = ArrayList<ResolvedTypeClause>()
    let ownerName = declaredTypeName(owner)
    let ty = target.getType()
    var parentMemberName = ""
    var renamed: ?IdentifierSyntax = None
    match (target) {
        case TypeInheritTarget.ByMember(_, name) => parentMemberName = name.name
        case TypeInheritTarget.ByRename(_, newName, memberName) =>
            parentMemberName = memberName.name
            renamed = newName
        case TypeInheritTarget.ByType(_) => return result
    }
    let (_, meta, actual) = match (parentMeta(ty, owner, diagnostics, ty.tokens)) {
        case Some(value) => value
        case None => return result
    }
    let expanded = match (substituteContract(meta.contracts, TypeSubstitution(meta.typeArgs, actual, meta.valueNames),
        diagnostics, emitStorage: meta.isInterface, fromInterface: meta.isInterface)) {
        case Some(value) => value
        case None => return result
    }
    var matched = false
    for (resolved in expanded.clauses) {
        if (!matchesInvariant(resolved.clause, parentMemberName)) {
            continue
        }
        if (matched) {
            diagnostics.add(
                Diagnostic("ambiguous inherited invariant: multiple invariants have the requested name",
                    "contract inheritance", ty.tokens))
            return ArrayList<ResolvedTypeClause>()
        }
        matched = true
        result.add(renamedInvariantEntry(resolved, renamed, ClauseOrigin(ownerName, clauseIndex, arguments)))
    }
    if (!matched) {
        diagnostics.add(
            Diagnostic("no inherited invariant matches the requested name", "contract inheritance", ty.tokens))
    }
    result
}

/// Rebuild a selected invariant entry, keeping the parent's origin when the name is unchanged.
/// A rename publishes a new contract identity, so it gets the fresh origin passed in; keeping
/// the parent's origin would let diamond de-duplication drop the renamed copy and hide it from
/// later generations.
func renamedInvariantEntry(entry: ResolvedTypeClause, renamed: ?IdentifierSyntax,
    freshOrigin: ClauseOrigin): ResolvedTypeClause {
    let clause = match (renamed) {
        case Some(newName) => renameClause(entry.clause, newName)
        case None => entry.clause
    }
    let origin = match (renamed) {
        case Some(_) => freshOrigin
        case None => entry.origin
    }
    ResolvedTypeClause(origin, clause)
}

func matchesInvariant(clause: TypeClause, name: String): Bool {
    match (clause) {
        case TypeClause.Invariant(invariant) =>
            match (invariant.name) {
                case Some(label) => label.name == name
                case None => false
            }
        case _ => false
    }
}

/// Rename a selected invariant while keeping its origin for diamond de-duplication. The
/// persisted source tokens are rebuilt with the new label: `metaClauseTokens` serializes
/// exactly these tokens, so keeping the old stream would resurrect the old name when the
/// record is read back (the member-level path rebuilds tokens in `rebuildInheritedClause`).
func renameClause(clause: TypeClause, newName: IdentifierSyntax): TypeClause {
    match (clause) {
        case TypeClause.Invariant(invariant) =>
            TypeClause.Invariant(InvariantClause(invariant.isStatic, invariant.visibility, invariant.condition,
                renameClauseTokens(invariant.tokens, invariant.name, newName), name: Some(newName)))
        case _ => clause
    }
}

/// Replace the old clause label inside the invariant's source tokens with `newName`.
///
/// Two label spellings occur: an invariant declares its label as `invariant [label]`,
/// while a function or property clause binds it as `ensures label: ...`. Both must be
/// handled; leaving the bracket form in place resurrects the old name when the renamed
/// invariant is serialized into a child record. When no label is found the original
/// stream is kept unchanged rather than silently dropping it.
func renameClauseTokens(tokens: Tokens, oldName: ?IdentifierSyntax, newName: IdentifierSyntax): Tokens {
    let old = match (oldName) {
        case Some(value) => value.name
        case None => return tokens
    }
    if (let Some(index) <- invariantLabelIndex(tokens, old)) {
        return replaceIdentifier(tokens, index, newName)
    }
    for (index in 0..tokens.size) {
        let token = tokens[index]
        if (token.kind != IDENTIFIER || token.value != old) {
            continue
        }
        let cursor = nextNonNewline(tokens, index + 1)
        if (cursor < tokens.size && tokens[cursor].kind == COLON) {
            return replaceIdentifier(tokens, index, newName)
        }
        // The condition may legitimately mention the same name (e.g. a named argument);
        // only the first colon-followed occurrence is the label, so stop scanning here.
        break
    }
    tokens
}

/// The index of the `[ label ]` identifier following the invariant keyword when its value
/// is `expected`, or None for the colon-bound clause spelling.
func invariantLabelIndex(tokens: Tokens, expected: String): ?Int64 {
    var index = 0
    while (index < tokens.size && !(tokens[index].kind == IDENTIFIER && tokens[index].value == "invariant")) {
        index += 1
    }
    if (index >= tokens.size) {
        return None
    }
    let open = nextNonNewline(tokens, index + 1)
    if (open >= tokens.size || tokens[open].kind != TokenKind.LSQUARE) {
        return None
    }
    let label = nextNonNewline(tokens, open + 1)
    if (label >= tokens.size || tokens[label].kind != IDENTIFIER || tokens[label].value != expected) {
        return None
    }
    let close = nextNonNewline(tokens, label + 1)
    if (close >= tokens.size || tokens[close].kind != TokenKind.RSQUARE) {
        return None
    }
    Some(label)
}

func nextNonNewline(tokens: Tokens, start: Int64): Int64 {
    var cursor = start
    while (cursor < tokens.size && tokens[cursor].kind == NL) {
        cursor += 1
    }
    cursor
}

func replaceIdentifier(tokens: Tokens, index: Int64, replacement: IdentifierSyntax): Tokens {
    let result = Tokens()
    for (position in 0..tokens.size) {
        if (position == index) {
            result.append(Token(IDENTIFIER, replacement.name))
        } else {
            result.append(tokens[position])
        }
    }
    result
}

func declaredSuper(ty: TypeNode, owner: Decl): Bool {
    for (superType in declaredSuperTypes(owner)) {
        if (compareTokens(ty.toTokens(), superType.toTokens())) {
            return true
        }
        // A package-qualified clause reference (`inherits from pkg.Parent`) names the same
        // type as the bare declared supertype (`class Child <: Parent`): the clause uses the
        // qualification to address the right cross-package `.cmeta` record, while the class
        // header only sees the imported simple name. Comparing the trailing simple names
        // keeps the guard meaningful without rejecting that spelling.
        let tyName = superSimpleName(ty) // cjlint-ignore !G.VAR.02 both simple names are derived once per supertype and compared right below
        let superName = superSimpleName(superType) // cjlint-ignore !G.VAR.02 both simple names are derived once per supertype and compared right below
        if (tyName != "" && tyName == superName) {
            return true
        }
    }
    false
}

/// Trailing simple name of a (possibly package-qualified, possibly generic) type reference:
/// the last identifier before the first generic bracket. `inhmetaa.PersistBase` and
/// `PersistBase<T>` both map to `PersistBase`; empty when the node has no identifier.
func superSimpleName(ty: TypeNode): String {
    var last: String = ""
    for (token in ty.toTokens()) {
        if (token.kind == TokenKind.IDENTIFIER) {
            last = token.value
        } else if (token.kind == TokenKind.LT || token.kind == TokenKind.LPAREN) {
            break
        }
    }
    last
}

func declaredSuperTypes(owner: Decl): ArrayList<TypeNode> {
    match (owner) {
        case value: ClassDecl => value.superTypes
        case value: StructDecl => value.superTypes
        case value: InterfaceDecl => value.superTypes
        case value: ExtendDecl => value.superTypes
        case _ => ArrayList<TypeNode>()
    }
}

/**
 * @brief Declared identifier of `owner`: the type name for classes, structs and interfaces.
 *
 * @param owner Declaration to inspect.
 * @return The declared type name, or an empty string for declarations without one (such as
 * `extend` declarations).
 */
public func declaredTypeName(owner: Decl): String {
    match (owner) {
        case value: ClassDecl => value.identifier.value
        case value: StructDecl => value.identifier.value
        case value: InterfaceDecl => value.identifier.value
        case _: ExtendDecl => ""
        case _ => ""
    }
}

/**
 * @brief Formal type parameter names of `owner`'s generic declaration, in source order.
 *
 * @param owner Class, struct or interface declaration to inspect.
 * @return The declared type parameter names; empty for non-generic declarations.
 */
public func declaredTypeParameters(owner: Decl): ArrayList<String> {
    let names = ArrayList<String>()
    let parameters = match (genericParameterTokens(owner)) {
        case Some(value) => value
        case None => return names
    }
    for (token in parameters) {
        if (token.kind == IDENTIFIER) {
            names.add(token.value)
        }
    }
    names
}

/// The generic parameter tokens of a generic class, struct or interface declaration.
private func genericParameterTokens(owner: Decl): ?Tokens {
    match (owner) {
        case value: ClassDecl =>
            if (value.isGenericDecl) {
                return Some(value.genericParam.parameters)
            }
        case value: StructDecl =>
            if (value.isGenericDecl) {
                return Some(value.genericParam.parameters)
            }
        case value: InterfaceDecl =>
            if (value.isGenericDecl) {
                return Some(value.genericParam.parameters)
            }
        case _ => ()
    }
    None
}

func formalTypeArguments(parameters: ArrayList<String>): ArrayList<TypeNode> {
    let arguments = ArrayList<TypeNode>()
    for (name in parameters) {
        arguments.add(RefType(Tokens(Token(IDENTIFIER, name))))
    }
    arguments
}

/**
 * @brief Whether `owner` already contributes to the provenance recorded for `key`.
 *
 * Recording the same owner twice is redundant (names union), but a *different* owner must
 * still be appended: a type may inherit an ancestor's contract on a member and also declare
 * its own, and skipping that record would hide diamond conflicts from
 * `checkAttrOriginConflicts`.
 *
 * @param origins Provenance map: member key -> declaring type -> `kind|name` set.
 * @param key Member signature key or property name.
 * @param owner Canonical declaring type name.
 * @return `true` when `owner` is already recorded for `key`.
 */
public func attrOriginHasOwner(origins: HashMap<String, HashMap<String, HashSet<String>>>, key: String,
    owner: String): Bool {
    match (origins.get(key)) {
        case Some(owners) => owners.contains(owner)
        case None => false
    }
}

/// Inputs shared by the per-owner provenance conflict check.
class AttrConflictScan {
    let current: HashMap<String, HashSet<String>>
    let key: String
    let subjectOf: (String) -> String
    let reported: HashSet<String>
    let diagnostics: ArrayList<Diagnostic>
    let tokens: Tokens

    init(current: HashMap<String, HashSet<String>>, key: String, subjectOf: (String) -> String,
        reported: HashSet<String>, diagnostics: ArrayList<Diagnostic>, tokens: Tokens) {
        this.current = current
        this.key = key
        this.subjectOf = subjectOf
        this.reported = reported
        this.diagnostics = diagnostics
        this.tokens = tokens
    }
}

/// Reports a kind+name contract that two unrelated parents declare on the same member; the
/// diamond case (the same ancestor reached through two paths) shares its origin and stays
/// silent. Same-name variables must agree on type, `static`, and initializer.
func checkAttrOriginConflicts(existing: HashMap<String, HashMap<String, HashSet<String>>>,
    incoming: HashMap<String, HashMap<String, HashSet<String>>>, subjectOf: (String) -> String,
    diagnostics: ArrayList<Diagnostic>, tokens: Tokens): Unit {
    for ((key, owners) in incoming) {
        let current = match (existing.get(key)) {
            case Some(value) => value
            case None => continue
        }
        let scan = AttrConflictScan(current, key, subjectOf, HashSet<String>(), diagnostics, tokens)
        for ((owner, names) in owners) {
            reportOwnerConflicts(owner, names, scan)
        }
    }
}

/// Report the incoming owner's names that another owner also declares, at most once each.
func reportOwnerConflicts(owner: String, names: HashSet<String>, scan: AttrConflictScan): Unit {
    for ((otherOwner, otherNames) in scan.current) {
        if (owner == otherOwner) {
            continue
        }
        for (name in names) {
            if (otherNames.contains(name) && !scan.reported.contains(name)) {
                scan.reported.add(name)
                scan.diagnostics.add(
                    Diagnostic(
                        "${scan.subjectOf(scan.key)} both declare contract `${provenanceLabel(name)}`; rename " +
                        "one with `=`",
                        "contract inheritance", scan.tokens))
            }
        }
    }
}

/// A named `invariant` and a `variable` clause from different origins must not share a
/// name (审计 47): both generate same-named members — the variable's storage/property and
/// the invariant's named checker — and the overlap otherwise only surfaces as a generic
/// compiler `redefinition`. Same-origin clauses may share a name across kinds: a local
/// `invariant b` and a local `variable b` generate disjoint members.
func validateCrossOriginNames(resolved: ResolvedTypeContract,
    diagnostics: ArrayList<Diagnostic>): Unit {
    let invariantOrigins = HashMap<String, String>()
    for (entry in resolved.clauses) {
        if (let TypeClause.Invariant(invariant) <- entry.clause) {
            if (let Some(label) <- invariant.name) {
                invariantOrigins.add(label.name, entry.origin.key())
            }
        }
    }
    if (invariantOrigins.isEmpty()) {
        return
    }
    let reported = HashSet<String>()
    for (entry in resolved.clauses) {
        if (let TypeClause.Variable(variable) <- entry.clause) {
            reportCrossOriginNameConflict(entry, variable, invariantOrigins, reported, diagnostics)
        }
    }
}

/// Report a name shared by an invariant and a `variable` clause of different origins.
private func reportCrossOriginNameConflict(entry: ResolvedTypeClause, variable: VariableClause,
    invariantOrigins: HashMap<String, String>, reported: HashSet<String>,
    diagnostics: ArrayList<Diagnostic>): Unit {
    match (invariantOrigins.get(variable.name.name)) {
        case Some(origin) =>
            if (origin != entry.origin.key() && reported.add(variable.name.name)) {
                diagnostics.add(
                    Diagnostic("an invariant and a `variable` clause from different origins both use the name `${variable.name.name}`; rename one",
                        "contract inheritance", variable.tokens))
            }
        case None => ()
    }
}

/// State shared while scanning resolved clauses for duplicate declarations.
class ResolvedDuplicateScan {
    let resolved: ResolvedTypeContract
    let diagnostics: ArrayList<Diagnostic>
    let variableKeys = HashMap<String, String>()
    let variableIndexes = HashMap<String, Int64>()
    let invariantOrigins = HashMap<String, String>()
    let duplicates = ArrayList<Int64>()

    init(resolved: ResolvedTypeContract, diagnostics: ArrayList<Diagnostic>) {
        this.resolved = resolved
        this.diagnostics = diagnostics
    }
}

func validateResolvedDuplicates(resolved: ResolvedTypeContract,
    diagnostics: ArrayList<Diagnostic>): Unit {
    let scan = ResolvedDuplicateScan(resolved, diagnostics)
    for (index in 0..resolved.clauses.size) {
        scanResolvedClause(index, resolved.clauses[index], scan)
    }
    // Keep the first occurrence of a merged variable so storage is emitted once.
    var cursor = scan.duplicates.size - 1
    while (cursor >= 0) {
        resolved.clauses.remove(at: scan.duplicates[cursor])
        cursor -= 1
    }
}

func scanResolvedClause(index: Int64, entry: ResolvedTypeClause, scan: ResolvedDuplicateScan): Unit {
    match (entry.clause) {
        case TypeClause.Variable(variable) => handleDuplicateVariable(index, entry, variable, scan)
        case TypeClause.Invariant(invariant) => handleDuplicateInvariant(entry, invariant, scan)
        case _ => ()
    }
}

func handleDuplicateVariable(index: Int64, entry: ResolvedTypeClause, variable: VariableClause,
    scan: ResolvedDuplicateScan): Unit {
    let key = variableDeclarationKey(variable)
    let existing = match (scan.variableKeys.get(variable.name.name)) {
        case Some(value) => value
        case None =>
            scan.variableKeys.add(variable.name.name, key)
            scan.variableIndexes.add(variable.name.name, index)
            return
    }
    if (existing != key) {
        scan.diagnostics.add(
            Diagnostic("inherited abstract variable `${variable.name.name}` has conflicting declarations; same-name variables must share type, `static`, and initializer",
                "contract inheritance", variable.tokens))
        return
    }
    // Merge the flags instead of dropping the duplicate: the first occurrence may come from
    // a class parent while a later one comes from an interface, and the implementor needs both.
    let first = scan.variableIndexes[variable.name.name]
    scan.resolved.clauses[first].emitStorage = scan.resolved.clauses[first].emitStorage || entry.emitStorage
    scan.resolved.clauses[first].fromInterface = scan.resolved.clauses[first].fromInterface ||
        entry.fromInterface
    scan.duplicates.add(index)
}

func handleDuplicateInvariant(entry: ResolvedTypeClause, invariant: InvariantClause,
    scan: ResolvedDuplicateScan): Unit {
    let label = match (invariant.name) {
        case Some(value) => value
        case None => return
    }
    let existing = match (scan.invariantOrigins.get(label.name)) {
        case Some(value) => value
        case None =>
            scan.invariantOrigins.add(label.name, entry.origin.key())
            return
    }
    if (existing != entry.origin.key()) {
        scan.diagnostics.add(
            Diagnostic("inherited invariant `${label.name}` is declared by multiple ancestors; rename one with `inherits invariant <new> = <type>.${label.name}`",
                "contract inheritance", label.tokens))
    }
}

func variableDeclarationKey(variable: VariableClause): String {
    var key = tokenValuesCompactString(variable.ty.tokens)
    key = key + (if (variable.isStatic) {
        "|static"
    } else {
        "|instance"
    })
    match (variable.initExpr) {
        case Some(initializer) => key + "|=" + tokenValuesCompactString(initializer.tokens)
        case None => key + "|<none>"
    }
}

/// A `[conforming]` invariant may only reference newly added variables and member variables.
func validateConformingInvariants(resolved: ResolvedTypeContract, ownerName: String,
    diagnostics: ArrayList<Diagnostic>): Unit {
    if (!resolved.conforming) {
        return
    }
    let inheritedVariables = HashSet<String>()
    let ownVariables = HashSet<String>() // cjlint-ignore !G.VAR.02 the set is filled in the first clause loop and consumed by the second
    for (entry in resolved.clauses) {
        if (let TypeClause.Variable(variable) <- entry.clause) {
            if (entry.origin.declaringType == ownerName) {
                ownVariables.add(variable.name.name)
            } else {
                inheritedVariables.add(variable.name.name)
            }
        }
    }
    if (inheritedVariables.isEmpty()) {
        return
    }
    for (entry in resolved.clauses) {
        if (let TypeClause.Invariant(invariant) <- entry.clause) {
            if (entry.origin.declaringType != ownerName) {
                continue
            }
            reportConformingViolations(invariant.condition.tokens, inheritedVariables, ownVariables,
                diagnostics)
        }
    }
}

/// Report every inherited-only variable a `[conforming]` invariant condition references.
private func reportConformingViolations(conditionTokens: Tokens, inheritedVariables: HashSet<String>,
    ownVariables: HashSet<String>, diagnostics: ArrayList<Diagnostic>): Unit {
    let reported = HashSet<String>() // cjlint-ignore !G.VAR.02 the set deduplicates diagnostics across the whole token loop
    for (index in 0..conditionTokens.size) {
        let token = conditionTokens[index] // cjlint-ignore !G.VAR.02 the token is read by the condition and reused in the diagnostic text
        if (token.kind == IDENTIFIER && inheritedVariables.contains(token.value) &&
            !ownVariables.contains(token.value) && !reported.contains(token.value) &&
            !precededByDot(conditionTokens, index)) {
            diagnostics.add(
                Diagnostic("a `[conforming]` invariant may only reference newly added abstract variables and member variables: `${token.value}`",
                    "contract inheritance", Tokens(token)))
            reported.add(token.value)
        }
    }
}

/// Contract names declared by one attribute, grouped by clause kind: names only conflict
/// within the same kind, so the kind is part of the lookup key.
internal class AttrNames {
    private let byKind = HashMap<String, HashSet<String>>()

    public init() {}

    public func add(kind: String, name: String): Unit {
        match (byKind.get(kind)) {
            case Some(names) => names.add(name)
            case None =>
                let names = HashSet<String>()
                names.add(name)
                byKind.add(kind, names)
        }
    }

    public func isEmpty(): Bool {
        byKind.isEmpty()
    }

    /// All `(kind, name)` pairs declared by this attribute.
    public func entries(): ArrayList<(String, String)> {
        let result = ArrayList<(String, String)>()
        for (entry in byKind) {
            for (name in entry[1]) {
                result.add((entry[0], name))
            }
        }
        result
    }

    /// Names declared in the same clause kind by both attributes.
    internal func conflictsWith(other: AttrNames): ArrayList<String> {
        let result = ArrayList<String>()
        for (entry in byKind) {
            if (let Some(theirs) <- other.byKind.get(entry[0])) {
                appendConflictingNames(entry[1], theirs, result)
            }
        }
        result
    }

    /// Append the names present in both sets.
    private func appendConflictingNames(mine: HashSet<String>, theirs: HashSet<String>,
        result: ArrayList<String>): Unit {
        for (name in mine) {
            if (theirs.contains(name)) {
                result.add(name)
            }
        }
    }
}

/// Function-level contract names declared by an attribute. `declaredOnly` skips `inherits`
/// clauses: replaying a parent contract is the allowed exception to the override clash rule.
internal func functionAttrNames(attr: Tokens, declaredOnly!: Bool = false): AttrNames {
    let names = AttrNames()
    let parsed = parseFunctionContract(attr)
    if (parsed.hasError()) {
        return names
    }
    for (clause in parsed.value.clauses) {
        if (!declaredOnly || !isInheritClause(clause)) {
            recordAttrName(clause, names)
        }
    }
    names
}

/// Property contract names declared by an attribute; see `functionAttrNames` for `declaredOnly`.
internal func propertyAttrNames(attr: Tokens, declaredOnly!: Bool = false): AttrNames {
    let names = AttrNames()
    let parsed = parsePropertyContract(attr, setterAlias: "value")
    if (parsed.hasError()) {
        return names
    }
    for (clause in parsed.value.clauses) {
        for (body in clause.clauses) {
            if (!declaredOnly || !isInheritClause(body)) {
                recordAttrName(body, names)
            }
        }
    }
    names
}

/// Contract names a function declares itself, excluding `inherits` clauses: replaying a parent
/// contract is the allowed exception to the override clash rule.
internal func declaredFunctionAttrNames(attr: Tokens): AttrNames {
    functionAttrNames(attr, declaredOnly: true)
}

/// Property counterpart of `declaredFunctionAttrNames`.
internal func declaredPropertyAttrNames(attr: Tokens): AttrNames {
    propertyAttrNames(attr, declaredOnly: true)
}

func isInheritClause(clause: FunctionClause): Bool {
    if (let FunctionClause.Inherit(_) <- clause) {
        return true
    }
    false
}

func recordAttrName(clause: FunctionClause, names: AttrNames): Unit {
    match (clause) {
        case FunctionClause.Requires(c) => addAttrName(c.name, "requires", names)
        case FunctionClause.Ensures(c) => addAttrName(c.name, "ensures", names)
        case FunctionClause.Throws(c) => addAttrName(c.name, "throws", names)
        case FunctionClause.Variable(c) => names.add("variable", c.name.name)
        case FunctionClause.Inherit(c) =>
            let kind = match (c.kind) {
                case InheritClauseKind.Requires => "requires"
                case InheritClauseKind.Ensures => "ensures"
                case InheritClauseKind.Throws => "throws"
                case InheritClauseKind.Variable => "variable"
            }
            match (c.target) {
                case TypeInheritTarget.ByRename(_, newName, _) => names.add(kind, newName.name)
                case _ => ()
            }
    }
}

func addAttrName(name: ?IdentifierSyntax, kind: String, names: AttrNames): Unit {
    match (name) {
        case Some(label) => names.add(kind, label.name)
        case None => ()
    }
}

func checkMemberAttrConflicts(existing: HashMap<String, Tokens>, incoming: HashMap<String, Tokens>,
    diagnostics: ArrayList<Diagnostic>, tokens: Tokens): Unit {
    for ((signature, attr) in incoming) {
        match (existing.get(signature)) {
            case Some(previous) =>
                if (tokensStableKey(previous) != tokensStableKey(attr)) {
                    reportContractNameConflicts(functionAttrNames(previous), functionAttrNames(attr),
                        "inherited contracts for `${signature}`", diagnostics, tokens)
                }
            case None => ()
        }
    }
}

func checkPropertyAttrConflicts(existing: HashMap<String, Tokens>, incoming: HashMap<String, Tokens>,
    diagnostics: ArrayList<Diagnostic>, tokens: Tokens): Unit {
    for ((name, attr) in incoming) {
        match (existing.get(name)) {
            case Some(previous) =>
                if (tokensStableKey(previous) != tokensStableKey(attr)) {
                    reportContractNameConflicts(propertyAttrNames(previous), propertyAttrNames(attr),
                        "inherited contracts for property `${name}`", diagnostics, tokens)
                }
            case None => ()
        }
    }
}

/// Compare names declared by an inherited attribute with names declared by a locally written one.
/// Only same-kind names conflict; different kinds may share a name.
internal func reportContractNameConflicts(previous: AttrNames, incoming: AttrNames, subject: String,
    diagnostics: ArrayList<Diagnostic>, tokens: Tokens): Unit {
    for (name in incoming.conflictsWith(previous)) {
        diagnostics.add(
            Diagnostic(subject + " both declare contract `${name}`; rename one with `=`",
                "contract inheritance", tokens))
    }
}

/**
 * @brief Cross-package entry for the generate package: report same-kind contract name
 * conflicts between an inherited member attribute and a locally redeclared one.
 *
 * Only same-kind names conflict; different kinds may share a name. The inherited side is
 * compared with all its clauses, the local side with `inherits` clauses skipped, so
 * replaying a parent contract stays the allowed exception to the override clash rule.
 * `property` selects the property-clause grammar; keeps the `AttrNames` plumbing
 * package-internal.
 *
 * @param inherited Inherited member contract attribute tokens.
 * @param local Locally redeclared member contract attribute tokens.
 * @param subject Diagnostic subject line, e.g. ``inherited contracts for `f(Int64)```.
 * @param diagnostics Diagnostics to append to.
 * @param tokens Source range reported with each diagnostic.
 * @param property Selects the property-clause grammar instead of the function one.
 */
public func reportInheritedNameConflicts(inherited: Tokens, local: Tokens, subject: String, // cjlint-ignore !G.FUN.01 public API signature is fixed
    diagnostics: ArrayList<Diagnostic>, tokens: Tokens, property!: Bool = false): Unit {
    if (property) {
        reportContractNameConflicts(propertyAttrNames(inherited), declaredPropertyAttrNames(local),
            subject, diagnostics, tokens)
    } else {
        reportContractNameConflicts(functionAttrNames(inherited), declaredFunctionAttrNames(local),
            subject, diagnostics, tokens)
    }
}

/**
 * @brief Cross-package entry for the generate package: record the contract names a member
 * attribute declares itself (no `inherits` clauses) with `owner` as provenance.
 *
 * @param contract Resolved type contract to record into.
 * @param key Member signature key or property name.
 * @param attr Member contract attribute tokens.
 * @param owner Canonical declaring type name of the attribute.
 * @param property Selects the property-clause grammar instead of the function one.
 */
public func recordDeclaredAttrOrigin(contract: ResolvedTypeContract, key: String, attr: Tokens,
    owner: String, property!: Bool = false): Unit {
    if (property) {
        contract.recordPropertyAttrOrigin(key, declaredPropertyAttrNames(attr), owner)
    } else {
        contract.recordMemberAttrOrigin(key, declaredFunctionAttrNames(attr), owner)
    }
}
