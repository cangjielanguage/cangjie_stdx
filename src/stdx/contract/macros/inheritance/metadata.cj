/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.inheritance

import stdx.contract.macros.syntax.{TypeClause}
import stdx.contract.macros.tokens.{tokenValuesCompactString, tokensStableKey}
import std.ast.{ASTException, Body, DiagReportLevel, FuncDecl, PropDecl, QualifiedType, RefType, Token, TokenKind, Tokens, TypeNode, VarDecl, diagReport}
import std.collection.{ArrayList, HashMap, HashSet, contains, isEmpty}
import std.sync.{ReentrantMutex}

/**
 * @brief Source identity of a clause, used to avoid duplicating diamond inheritance.
 *
 * `declaringType` is stored in the same canonical qualified form as
 * `ContractMetaData.fullName`, so simple names of different packages cannot collide in
 * checker suffixes or diamond keys.
 */
public class ClauseOrigin {
    /**
     * @brief Canonical qualified name of the type whose `@Contract` attribute declared the
     * clause.
     */
    public let declaringType: String
    /** @brief Zero-based position of the clause inside the declaring type's attribute. */
    public let clauseIndex: Int64
    /**
     * @brief Type arguments of the declaring clause, kept in the declaring type's formal
     * spelling; they participate in `key` so diamond copies stay identical.
     */
    public let typeArguments: ArrayList<TypeNode>

    /**
     * @brief Build an origin; `declaringType` is canonicalized via
     * `canonicalDeclaringTypeName`.
     */
    public init(declaringType: String, clauseIndex: Int64, typeArguments: ArrayList<TypeNode>) {
        this.declaringType = canonicalDeclaringTypeName(declaringType)
        this.clauseIndex = clauseIndex
        this.typeArguments = typeArguments
    }

    /**
     * @brief Diamond de-duplication key: the declaring type, its compact clause type
     * arguments, and the clause index.
     *
     * @return A string that is equal for the same clause reached through different
     * inheritance paths, and distinct for different clauses.
     */
    public func key(): String {
        let arguments = ArrayList<String>()
        for (argument in typeArguments) {
            arguments.add(typeReferenceKey(argument))
        }
        declaringType + "<" + String.join(arguments.toArray(), delimiter: ",") + ">#" + clauseIndex.toString()
    }
}

/**
 * @brief One clause of a resolved type contract: the parsed `TypeClause` plus the origin it
 * came from.
 *
 * Clauses inherited from a parent keep the parent's `ClauseOrigin`, which diamond
 * de-duplication and `[conforming]` validation rely on; clauses declared by this type carry
 * this type as their origin.
 */
public class ResolvedTypeClause {
    /** @brief Declaring type and clause position this clause came from. */
    public let origin: ClauseOrigin
    /** @brief The parsed clause: a variable, invariant, invariant-inherit, or inherits. */
    public let clause: TypeClause
    /**
     * @brief Interface variables need the implementor to provide storage; class parents
     * already own it.
     */
    public var emitStorage: Bool
    /**
     * @brief Interface variables also need the implementor to expose the reserved accessor
     * used by the interface's default members.
     */
    public var fromInterface: Bool

    /**
     * @brief Build a clause; the flags default to plain class inheritance (`emitStorage` on,
     * `fromInterface` off).
     */
    public init(origin: ClauseOrigin, clause: TypeClause, emitStorage!: Bool = true,
        fromInterface!: Bool = false) {
        this.origin = origin
        this.clause = clause
        this.emitStorage = emitStorage
        this.fromInterface = fromInterface
    }
}

/**
 * @brief A type contract after inheritance resolution: the type's own clauses plus every
 * clause inherited from parent types, each carrying its provenance.
 *
 * Produced by `resolveTypeContract` for `@Contract` types and persisted as part of
 * `ContractMetaData`. Member and property contract attributes inherited from parents are
 * merged here so child expansions can replay them; the provenance maps record which
 * ancestor declared each name, so diamond paths stay silent while unrelated parents
 * declaring the same name conflict loudly.
 */
public class ResolvedTypeContract {
    /** @brief Source tokens of the `@Contract` attribute this contract was resolved from. */
    public let tokens: Tokens
    /**
     * @brief Resolved clauses in expansion order, own and inherited, each carrying its
     * origin.
     */
    public let clauses: ArrayList<ResolvedTypeClause> = ArrayList<ResolvedTypeClause>()
    /**
     * @brief Inherited member contract attributes keyed by signature (see
     * `methodSignatureKey`).
     */
    public let memberAttrs: HashMap<String, Tokens> = HashMap<String, Tokens>()
    /** @brief Inherited property contract attributes keyed by property name. */
    public let propertyAttrs: HashMap<String, Tokens> = HashMap<String, Tokens>()
    /**
     * @brief Member contract attributes declared by the annotated direct parents, keyed like
     * `memberAttrs`.
     *
     * They are not inherited; they only tell whether an override redeclares a same-kind
     * parent contract name.
     */
    public let parentMemberAttrs: HashMap<String, Tokens> = HashMap<String, Tokens>()
    /** @brief Property contracts of the annotated direct parents, only for the same check. */
    public let parentPropertyAttrs: HashMap<String, Tokens> = HashMap<String, Tokens>()
    /**
     * @brief Signatures of every member reachable through inherited parents (their own
     * signatures plus their ancestors', transitively).
     *
     * Used to tell overrides from brand-new members when checking `[conforming]`: only
     * overrides may be barred from adding `requires`.
     */
    public let inheritedMemberSignatures: HashSet<String> = HashSet<String>()
    /**
     * @brief Signatures reachable through a parent inherited with `[conforming]`: only those
     * members are barred from adding `requires`, and the restriction applies per parent.
     */
    public let conformingMemberSignatures: HashSet<String> = HashSet<String>()
    /**
     * @brief Provenance of merged member contract names: signature -> declaring type ->
     * `kind|name` set.
     *
     * Two unrelated parents declaring the same kind and name on the same member conflict;
     * the same ancestor reached through two paths does not.
     */
    public let memberAttrOrigins: HashMap<String, HashMap<String, HashSet<String>>> =
        HashMap<String, HashMap<String, HashSet<String>>>()
    /**
     * @brief Property counterpart of `memberAttrOrigins`, keyed by property name.
     */
    public let propertyAttrOrigins: HashMap<String, HashMap<String, HashSet<String>>> =
        HashMap<String, HashMap<String, HashSet<String>>>()
    /**
     * @brief True when an `inherits from T [conforming]` clause requires LSP conformance.
     */
    public var conforming: Bool = false
    /**
     * @brief Member signature keys whose stored attribute was declared by this type itself
     * (`absorbDeferredMemberContracts`); drives parent-side checker generation.
     *
     * Kept in memory only: cross-package consumers rely on `memberCheckerBases` instead.
     */
    public let ownMemberAttrKeys: HashSet<String> = HashSet<String>()
    /**
     * @brief Ordered formal parameter names per member signature key, as recorded by the
     * type that declared (or last renamed) the stored clause text.
     *
     * Inheriting types rename clause parameters positionally from this list (see
     * `adaptInheritedMemberAttrTokens`).
     */
    public let memberParamNames: HashMap<String, ArrayList<String>> = HashMap<String, ArrayList<String>>()
    /**
     * @brief Per-member checker-name base (`_contract_member_cond_<DeclType>_<key>_`) of the
     * expansion whose checkers materialize the stored conditions; empty when none apply.
     *
     * Propagated so grandchildren keep addressing the original declaring type's checkers.
     */
    public let memberCheckerBases: HashMap<String, String> = HashMap<String, String>()
    private let origins = HashSet<String>()

    /**
     * @brief Start a contract that carries only the source tokens; clauses are appended via
     * `add`.
     */
    public init(tokens: Tokens) {
        this.tokens = tokens
    }

    /**
     * @brief Append `clause` unless an identical origin `key` was already added.
     *
     * @param clause Resolved clause to append.
     */
    public func add(clause: ResolvedTypeClause): Unit {
        if (origins.add(clause.origin.key())) {
            clauses.add(clause)
        }
    }

    /// Merge inherited member contracts; diamond paths contribute identical tokens and are ignored.
    internal func mergeMemberAttrs(source: HashMap<String, Tokens>): Unit {
        for ((name, attr) in source) {
            absorb(memberAttrs, name, attr)
        }
    }

    internal func mergePropertyAttrs(source: HashMap<String, Tokens>): Unit {
        for ((name, attr) in source) {
            absorb(propertyAttrs, name, attr)
        }
    }

    /// Remember a parent's member contracts without inheriting them.
    internal func mergeParentMemberAttrs(source: HashMap<String, Tokens>): Unit {
        for ((name, attr) in source) {
            absorb(parentMemberAttrs, name, attr)
        }
    }

    /// Remember a parent's property contracts without inheriting them.
    internal func mergeParentPropertyAttrs(source: HashMap<String, Tokens>): Unit {
        for ((name, attr) in source) {
            absorb(parentPropertyAttrs, name, attr)
        }
    }

    /// Merge a parent's full member-signature set (already transitively closed over its own ancestors).
    internal func mergeInheritedSignatures(source: HashSet<String>): Unit {
        unionInto(inheritedMemberSignatures, source)
    }

    /// Union a parent's member-contract provenance into this contract (no conflict checks here;
    /// `checkAttrOriginConflicts` runs first in `inheritParent`).
    internal func mergeMemberAttrOrigins(source: HashMap<String, HashMap<String, HashSet<String>>>): Unit {
        mergeAttrOrigins(memberAttrOrigins, source)
    }

    /// Property counterpart of `mergeMemberAttrOrigins`.
    internal func mergePropertyAttrOrigins(source: HashMap<String, HashMap<String, HashSet<String>>>): Unit {
        mergeAttrOrigins(propertyAttrOrigins, source)
    }

    /// Record `owner` as a declaring type of the named contracts on `key`.
    internal func recordMemberAttrOrigin(key: String, names: AttrNames, owner: String): Unit {
        recordAttrOrigin(memberAttrOrigins, key, names, owner)
    }

    /// Property counterpart of `recordMemberAttrOrigin`.
    internal func recordPropertyAttrOrigin(key: String, names: AttrNames, owner: String): Unit {
        recordAttrOrigin(propertyAttrOrigins, key, names, owner)
    }

    /**
     * @brief Append contracts declared on this type itself; they run after the inherited
     * ones.
     *
     * @param name Signature key of the member the contracts are declared on.
     * @param attr Contract attribute tokens; empty tokens are ignored.
     */
    public func appendMemberAttr(name: String, attr: Tokens): Unit {
        if (attr.size == 0) {
            return
        }
        match (memberAttrs.get(name)) {
            case Some(existing) => memberAttrs.add(name, combineAttrs(existing, attr))
            case None => memberAttrs.add(name, attr)
        }
    }

    /**
     * @brief Property counterpart of `appendMemberAttr`: append contracts declared on this
     * type itself, keyed by property name; empty tokens are ignored.
     */
    public func appendPropertyAttr(name: String, attr: Tokens): Unit {
        if (attr.size == 0) {
            return
        }
        match (propertyAttrs.get(name)) {
            case Some(existing) => propertyAttrs.add(name, combineAttrs(existing, attr))
            case None => propertyAttrs.add(name, attr)
        }
    }

    /**
     * @brief Record this type's ordered parameter names for a member it declares; replaces
     * any propagated record, because the stored clause text is (or will be) renamed to
     * these.
     */
    public func recordMemberParamNames(key: String, names: ArrayList<String>): Unit {
        memberParamNames.add(key, names)
    }

    /**
     * @brief Record the checker base of this type's own materialized conditions for `key`,
     * so children replay them as calls to this type's public checkers.
     */
    public func recordMemberCheckerBase(key: String, base: String): Unit {
        memberCheckerBases.add(key, base)
    }

    /// Merge a parent's per-member parameter names under instantiated keys; records this type
    /// already made (or makes later, in `absorbDeferredMemberContracts`) take precedence.
    internal func mergeMemberParamNames(source: HashMap<String, ArrayList<String>>): Unit {
        for ((key, names) in source) {
            if (memberParamNames.get(key).isNone()) {
                memberParamNames.add(key, names)
            }
        }
    }

    /// Property-free counterpart for inherited checker bases.
    internal func mergeMemberCheckerBases(source: HashMap<String, String>): Unit {
        for ((key, base) in source) {
            if (memberCheckerBases.get(key).isNone()) {
                memberCheckerBases.add(key, base)
            }
        }
    }
}

func absorb(target: HashMap<String, Tokens>, name: String, attr: Tokens): Unit {
    match (target.get(name)) {
        case Some(existing) =>
            if (tokensStableKey(existing) != tokensStableKey(attr)) {
                target.add(name, combineAttrs(existing, attr))
            }
        case None => target.add(name, attr)
    }
}

/// Union provenance maps: key -> declaring type -> `kind|name` set.
func mergeAttrOrigins(target: HashMap<String, HashMap<String, HashSet<String>>>,
    source: HashMap<String, HashMap<String, HashSet<String>>>): Unit {
    for ((key, owners) in source) {
        let inner = match (target.get(key)) {
            case Some(value) => value
            case None =>
                let fresh = HashMap<String, HashSet<String>>()
                target.add(key, fresh)
                fresh
        }
        for ((owner, names) in owners) {
            match (inner.get(owner)) {
                case Some(existing) =>
                    for (name in names) {
                        existing.add(name)
                    }
                case None => inner.add(owner, names)
            }
        }
    }
}

func recordAttrOrigin(target: HashMap<String, HashMap<String, HashSet<String>>>, key: String,
    names: AttrNames, owner: String): Unit {
    let entries = names.entries()
    if (entries.isEmpty()) {
        return
    }
    let inner = match (target.get(key)) {
        case Some(value) => value
        case None =>
            let fresh = HashMap<String, HashSet<String>>()
            target.add(key, fresh)
            fresh
    }
    let declared = match (inner.get(owner)) {
        case Some(value) => value
        case None =>
            let fresh = HashSet<String>()
            inner.add(owner, fresh)
            fresh
    }
    for (entry in entries) {
        declared.add(entry[0] + "|" + entry[1])
    }
}

/// Label part of a stored `kind|name` provenance key.
internal func provenanceLabel(stored: String): String {
    let parts = stored.split("|")
    parts[parts.size - 1]
}

/**
 * @brief Concatenate two contract attributes with a newline separator, keeping the declared
 * order so own contracts run after the inherited ones.
 *
 * @param first Existing attribute tokens.
 * @param second Newly declared attribute tokens.
 * @return `second` when `first` is empty, `first` when `second` is empty, otherwise the
 * combined token stream.
 */
public func combineAttrs(first: Tokens, second: Tokens): Tokens {
    if (first.size == 0) {
        return second
    }
    if (second.size == 0) {
        return first
    }
    let combined = Tokens()
    combined.append(first)
    combined.append(Token(NL))
    combined.append(second)
    combined
}

/// Prefix of the positional placeholders that stand for a method's own type parameters in
/// signature keys (`id(_contract_ty_0)`); it must lex as a plain identifier, because stored
/// keys are re-lexed with `cangjieLex` on the instantiation side.
const TYPE_PARAM_PLACEHOLDER_PREFIX = "_contract_ty_"

/**
 * @brief Signature key used to index member contracts, e.g. `foo(Int64,String)`.
 *
 * Method-level type parameters are normalized to positional placeholders
 * (`id(_contract_ty_0)`), so an override that only renames its type parameters keeps
 * matching the parent's key.
 *
 * @param method Function declaration to key; constructors included.
 * @return The compact signature key of the method.
 */
public func methodSignatureKey(method: FuncDecl): String {
    let typeParameters = methodTypeParameterNames(method)
    let parameters = ArrayList<String>()
    for (parameter in method.funcParams) {
        parameters.add(normalizedTypeParameterKey(parameter.paramType, typeParameters))
    }
    method.identifier.value + "(" + String.join(parameters.toArray(), delimiter: ",") + ")"
}

/// Method-level type parameter names (`func f<T, U>()`); empty for non-generic methods.
func methodTypeParameterNames(method: FuncDecl): ArrayList<String> {
    let names = ArrayList<String>()
    try {
        for (token in method.genericParam.parameters) {
            names.add(token.value)
        }
    } catch (_: ASTException) {
        // Not a generic method: keep the names collected so far.
        return names
    }
    names
}

/// Compact type text with the method's own type parameter names replaced by positional
/// placeholders. Member accesses (`x.T`) are never substituted, mirroring
/// `substituteTypeArguments` on the instantiation side.
func normalizedTypeParameterKey(ty: TypeNode, typeParameters: ArrayList<String>): String {
    if (typeParameters.isEmpty()) {
        return typeReferenceKey(ty)
    }
    let result = Tokens()
    var previous = TokenKind.ILLEGAL
    for (token in ty.toTokens()) {
        var replaced = false
        if (token.kind == IDENTIFIER && previous != DOT) {
            for (index in 0..typeParameters.size) {
                if (token.value == typeParameters[index]) {
                    result.append(Token(IDENTIFIER, TYPE_PARAM_PLACEHOLDER_PREFIX + index.toString()))
                    replaced = true
                    break
                }
            }
        }
        if (!replaced) {
            result.append(token)
        }
        if (token.kind != NL) {
            previous = token.kind
        }
    }
    tokenValuesCompactString(result)
}

/**
 * @brief Persisted metadata of one `@Contract` type: identity, resolved clauses, and the
 * member contracts implementors must replay.
 *
 * Produced when a type's `@Contract` macro finishes expanding, registered in the in-process
 * registry, and written to `<meta-dir>/<fullName>.cmeta` so later cjc runs and other
 * packages can resolve contract inheritance against it (see `persist.cj`).
 */
public class ContractMetaData {
    /** @brief Simple name of the declaring type, without any package qualifier. */
    public let typeName: String
    /**
     * @brief Package declared by `CANGJIE_STDX_CONTRACT_PKG_NAME` when this metadata was
     * produced.
     *
     * Empty when the build did not provide it, which keeps the legacy simple-name identity.
     */
    public let packageName: String
    /**
     * @brief `packageName.typeName`, or just `typeName` when the package is unknown.
     *
     * It is the registry key and the persisted file stem, so same-named types from different
     * packages stay distinct.
     */
    public let fullName: String
    /** @brief Formal type parameter names of the declaring type. */
    public let typeArgs: ArrayList<String>
    /** @brief Type contract with all `inherits` clauses already expanded, in source order. */
    public let contracts: ResolvedTypeContract
    /**
     * @brief Whether the declaring type is an interface; interface parents make implementors
     * provide variable storage and reserved accessors.
     */
    public let isInterface: Bool
    /**
     * @brief Whether the declaring type is `open`; only open class contracts may pass
     * invariants on to children.
     */
    public let isOpen: Bool
    /** @brief Member `@Contract` attributes that implementors must replay. */
    public let memberAttrs: HashMap<String, Tokens>
    /**
     * @brief Property `@Contract` attributes that implementors must replay, keyed by
     * property name.
     */
    public let propertyAttrs: HashMap<String, Tokens>
    /**
     * @brief Provenance of the named contracts inside `memberAttrs`: member key -> declaring
     * type -> `kind|name` set.
     */
    public let memberAttrOrigins: HashMap<String, HashMap<String, HashSet<String>>>
    /** @brief Property counterpart of `memberAttrOrigins`, keyed by property name. */
    public let propertyAttrOrigins: HashMap<String, HashMap<String, HashSet<String>>>
    /**
     * @brief Signatures of every member declared by this type plus everything inherited from
     * its ancestors (transitively).
     *
     * Implementors consult it to tell overrides from brand-new members when enforcing
     * `[conforming]`.
     */
    public let allMemberSignatures: HashSet<String>
    /**
     * @brief Names that denote values in this type's member contracts: declared fields,
     * properties, and method parameter names.
     *
     * When a child instantiates inherited clause conditions, an identifier equal to one of
     * these names is a value reference and must not be rewritten as a type argument (see
     * `substituteValueTokens`). Empty means "unknown": consumers degrade to the plain
     * type-context substitution.
     */
    public let valueNames: HashSet<String>
    /**
     * @brief Ordered formal parameter names per member signature key (positional rename
     * source for inherited clause conditions).
     *
     * Empty per key means "unknown": children keep the text.
     */
    public let memberParamNames: HashMap<String, ArrayList<String>>
    /**
     * @brief Per-member checker-name base of the expansion that materializes the stored
     * conditions (see `genMemberConditionCheckers`); empty per key means the conditions stay
     * as text.
     */
    public let memberCheckerBases: HashMap<String, String>

    /**
     * @brief Build a record; `fullName` is derived from `packageName` and `typeName`, and
     * the defaulted arguments keep the legacy simple-name identity for older producers.
     */
    public init(typeName: String, typeArgs: ArrayList<String>, contracts: ResolvedTypeContract,
        isInterface!: Bool, isOpen!: Bool, memberAttrs!: HashMap<String, Tokens>,
        propertyAttrs!: HashMap<String, Tokens>,
        memberAttrOrigins!: HashMap<String, HashMap<String, HashSet<String>>> = HashMap<String,
            HashMap<String, HashSet<String>>>(),
        propertyAttrOrigins!: HashMap<String, HashMap<String, HashSet<String>>> = HashMap<String,
            HashMap<String, HashSet<String>>>(),
        allMemberSignatures!: HashSet<String> = HashSet<String>(),
        valueNames!: HashSet<String> = HashSet<String>(),
        memberParamNames!: HashMap<String, ArrayList<String>> = HashMap<String, ArrayList<String>>(),
        memberCheckerBases!: HashMap<String, String> = HashMap<String, String>(),
        packageName!: String = contractPackageName()) {
        this.typeName = unqualifiedTypeName(typeName)
        this.packageName = packageName
        this.fullName = if (packageName == "") {
            this.typeName
        } else {
            packageName + "." + this.typeName
        }
        this.typeArgs = typeArgs
        this.contracts = contracts
        this.isInterface = isInterface
        this.isOpen = isOpen
        this.memberAttrs = memberAttrs
        this.propertyAttrs = propertyAttrs
        this.memberAttrOrigins = memberAttrOrigins
        this.propertyAttrOrigins = propertyAttrOrigins
        this.allMemberSignatures = allMemberSignatures
        this.valueNames = valueNames
        this.memberParamNames = memberParamNames
        this.memberCheckerBases = memberCheckerBases
    }
}

/**
 * @brief Collect the signatures of every member declared directly by this type: functions by
 * `methodSignatureKey` (constructors included), properties by name.
 *
 * @param body Body of the declaring class, struct or interface.
 * @return The member signature set published with the metadata.
 */
public func collectAllMemberSignatures(body: Body): HashSet<String> {
    let signatures = HashSet<String>()
    for (member in body.decls) {
        if (let method: FuncDecl <- member) {
            signatures.add(methodSignatureKey(method))
        } else if (let property: PropDecl <- member) {
            signatures.add(property.identifier.value)
        }
    }
    signatures
}

/**
 * @brief Collect the names that denote values inside this type's contracts: declared
 * fields, properties, and every method parameter name.
 *
 * The set is published with the metadata so inheriting types can keep those identifiers
 * intact when they instantiate clause conditions with concrete type arguments (see
 * `substituteValueTokens`).
 *
 * @param body Body of the declaring class, struct or interface.
 * @return The value-name set published with the metadata.
 */
public func collectValueMemberNames(body: Body): HashSet<String> {
    let names = HashSet<String>()
    for (member in body.decls) {
        if (let method: FuncDecl <- member) {
            for (parameter in method.funcParams) {
                try {
                    names.add(parameter.identifier.value)
                } catch (_: ASTException) {
                    ()
                }
            }
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

/**
 * @brief Union `extra` into `base` in place and return `base`.
 *
 * The name stresses the mutating semantics: the first argument is consumed as the
 * accumulator, not treated as immutable.
 *
 * @param base Set consumed as the accumulator and returned.
 * @param extra Signatures to add.
 * @return `base` with every element of `extra` added.
 */
public func unionInto(base: HashSet<String>, extra: HashSet<String>): HashSet<String> {
    for (signature in extra) {
        base.add(signature)
    }
    base
}

/// In-memory metadata of every `@Contract` type expanded so far in this cjc process. Macro
/// expansion may execute in parallel inside one cjc process, so every access to this
/// package-level mutable global — and to the disk-probe set in `persist.cj` — must hold
/// `_CONTRACT_META_REGISTRY_MUTEX`.
let _CONTRACT_META_REGISTRY: HashMap<String, ContractMetaData> = HashMap<String, ContractMetaData>()

private let _CONTRACT_META_REGISTRY_MUTEX = ReentrantMutex()

/**
 * @brief Register a record in the in-process registry under its `fullName` and persist it to
 * disk.
 *
 * Registration replaces an existing entry for the same qualified name; when the stored
 * contract text differs, a WARNING diagnostic reports the conflict before the replacement,
 * because a silent override could make inheritance resolve to the wrong declaration.
 *
 * @param data Metadata produced by the expanding `@Contract` type macro.
 */
public func registerMetaData(data: ContractMetaData): Unit {
    synchronized(_CONTRACT_META_REGISTRY_MUTEX) {
        registerMetaDataLocked(data)
    }
}

func registerMetaDataLocked(data: ContractMetaData): Unit {
    // Key by the fully qualified name: two packages may each declare `Node`, and a short key
    // would let the second registration silently replace the first. When the key is taken by a
    // different declaration, the override must stay loud, not silent.
    if (let Some(existing) <- _CONTRACT_META_REGISTRY.get(data.fullName)) {
        if (tokensStableKey(existing.contracts.tokens) != tokensStableKey(data.contracts.tokens)) {
            diagReport(DiagReportLevel.WARNING, data.contracts.tokens,
                "conflicting contract metadata for `" + data.fullName + "`: already registered from " +
                describeMetaDataOwner(existing) + ", now replaced by " + describeMetaDataOwner(data) +
                "; inheritance may resolve to the wrong declaration",
                "build each library with CANGJIE_STDX_CONTRACT_PKG_NAME set so records stay package-qualified")
        }
    }
    _CONTRACT_META_REGISTRY.add(data.fullName, data)
    persistMetaData(data)
}

/// Human-readable origin of a metadata record for conflict diagnostics.
func describeMetaDataOwner(data: ContractMetaData): String {
    if (data.packageName == "") {
        return "a package built without CANGJIE_STDX_CONTRACT_PKG_NAME"
    }
    return "package `" + data.packageName + "`"
}

/**
 * @brief Look up metadata by the name written in source.
 *
 * A qualified `pkgA.Parent` must match that exact record; a bare `Parent` is resolved
 * against the current package first and then by a simple-name scan, reporting ambiguity
 * instead of returning another package's record. Names not found in memory are probed on
 * disk once per cjc process and registered on success.
 *
 * @param key Qualified or simple parent type name as written in source.
 * @return The matching record, or `None` when it is unavailable or ambiguous.
 */
public func searchMetaData(key: String): ?ContractMetaData {
    synchronized(_CONTRACT_META_REGISTRY_MUTEX) {
        searchMetaDataLocked(key)
    }
}

func searchMetaDataLocked(key: String): ?ContractMetaData {
    if (let Some(value) <- _CONTRACT_META_REGISTRY.get(key)) {
        return value
    }
    let name = unqualifiedTypeName(key)
    if (name == key) {
        let currentPackage = contractPackageName()
        if (currentPackage != "") {
            if (let Some(value) <- _CONTRACT_META_REGISTRY.get(currentPackage + "." + name)) {
                return value
            }
        }
        let matches = ArrayList<ContractMetaData>()
        for ((_, data) in _CONTRACT_META_REGISTRY) {
            if (data.typeName == name) {
                matches.add(data)
            }
        }
        if (matches.size > 1) {
            reportAmbiguousMetaData(name, matches)
            return None
        }
        if (matches.size == 1 && simpleNameRecordUsable(matches[0])) {
            return matches[0]
        }
    }
    if (_META_DISK_PROBED.contains(key)) {
        return None
    }
    _META_DISK_PROBED.add(key)
    match (loadMetaDataFromDisk(key)) {
        case Some(data) =>
            if (name == key && !simpleNameRecordUsable(data)) {
                return None
            }
            _CONTRACT_META_REGISTRY.add(data.fullName, data)
            return data
        case None =>
            return None
    }
}

/// Whether a bare-name reference may use this record. A consumer without a package
/// identity (no `CANGJIE_STDX_CONTRACT_PKG_NAME` set) cannot rule any record out — the
/// documented cross-package interop (CT-INH-048) relies on the bare-name suffix match
/// against `<pkg>.<Name>.cmeta`. A consumer that HAS an identity only rejects records
/// provably owned by a different package: otherwise a same-named `Base.cmeta` left behind
/// by an unrelated build would silently hand the child the wrong contract while its own
/// parent has not registered yet. Referencing another package's type from an
/// identity-carrying consumer is still supported through the qualified form `pkg.Type`.
func simpleNameRecordUsable(data: ContractMetaData): Bool {
    let currentPackage = contractPackageName()
    currentPackage == "" || data.packageName == "" || data.packageName == currentPackage
}

/// The source reference carries no qualifier while several packages declare the same simple
/// name: returning either record would silently inherit the wrong contract, so skip both.
func reportAmbiguousMetaData(name: String, matches: ArrayList<ContractMetaData>): Unit {
    let packages = ArrayList<String>()
    for (data in matches) {
        packages.add(if (data.packageName == "") {
            "<unknown package>"
        } else {
            data.packageName
        })
    }
    // The matches may come from disk (`loadMetaDataFromDisk`), whose tokens are re-lexed
    // outside the current macro call range: `diagReport` rejects such positions with an
    // ASTException and would crash the expansion, so the diagnostic carries an empty range.
    diagReport(DiagReportLevel.WARNING, Tokens(),
        "ambiguous contract metadata for `" + name + "`: declared by " +
        String.join(packages.toArray(), delimiter: ", ") +
        "; qualify the parent type with its package name", "Contract")
}

private func unqualifiedTypeName(name: String): String {
    let parts = name.split(".")
    parts[parts.size - 1]
}

/**
 * @brief Canonical storage form of a declaring type name, matching
 * `ContractMetaData.fullName`.
 *
 * A qualified name keeps its qualifier, a simple name is prefixed with the current package
 * when `CANGJIE_STDX_CONTRACT_PKG_NAME` is set. Idempotent; an empty name passes through
 * unchanged.
 *
 * @param name Declaring type name as written in source.
 * @return The canonical qualified form of the name.
 */
public func canonicalDeclaringTypeName(name: String): String {
    if (name == "" || unqualifiedTypeName(name) != name) {
        return name
    }
    let pkg = contractPackageName()
    if (pkg == "") {
        return name
    }
    return pkg + "." + name
}

/// Fully qualified name of a type reference as written in source: `pkgA.Parent` keeps its
/// qualifier, a bare `Parent` stays a simple name. Nested types (`Outer.Inner`) are shaped
/// like packages here, which is fine because both are source-level qualifiers.
internal func qualifiedTypeName(ty: TypeNode): ?String {
    match (ty) {
        case ref: RefType => Some(ref.identifier.value)
        case qualified: QualifiedType =>
            match (qualifiedTypeName(qualified.baseType)) {
                case Some(prefix) => Some(prefix + "." + qualified.identifier.value)
                case None => Some(qualified.identifier.value)
            }
        case _ => None
    }
}

private func typeReferenceKey(ty: TypeNode): String {
    tokenValuesCompactString(ty.toTokens())
}

/**
 * @brief Type arguments written on a type reference.
 *
 * @param ty Type node to inspect.
 * @return The written type arguments; empty for other node kinds or references without
 * arguments.
 */
public func typeArguments(ty: TypeNode): ArrayList<TypeNode> {
    match (ty) {
        case ref: RefType => ref.typeArguments
        case qualified: QualifiedType => qualified.typeArguments
        case _ => ArrayList<TypeNode>()
    }
}
