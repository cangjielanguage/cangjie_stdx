/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.generate

import stdx.contract.macros.inheritance.{ClauseOrigin, ResolvedTypeContract, canonicalDeclaringTypeName, searchMetaData}
import stdx.contract.macros.syntax.{InvariantClause, InvariantVisibility, TypeClause}
import stdx.contract.runtime.ContractVisibility
import std.ast.{Body, Decl, FuncDecl, ToTokens, Token, Tokens}
import std.collection.{ArrayList, HashSet, contains, isEmpty}

/**
 * @brief A type invariant clause together with the type that declared it.
 *
 * The recorded origin keeps inherited invariants running in the scope of the
 * declaring type (private members stay visible) and drives the per-origin
 * checker naming.
 */
public class ResolvedInvariant {
    /**
     * @brief The origin of the invariant: its declaring type and clause index.
     */
    public let origin: ClauseOrigin
    /**
     * @brief The invariant clause itself, including its condition and visibility.
     */
    public let clause: InvariantClause

    /**
     * @brief Creates a resolved invariant from its origin and clause.
     *
     * @param origin The declaring type and clause index of the invariant.
     * @param clause The invariant clause to carry.
     */
    public init(origin: ClauseOrigin, clause: InvariantClause) {
        this.origin = origin
        this.clause = clause
    }

    /// Checker suffix. Type arguments are excluded so a generic declaring type and its
    /// concrete subclass agree on the checker name. Qualified types keep their package
    /// part but replace separators, so the suffix stays valid and packages cannot collide.
    internal func methodSuffix(): String {
        origin.declaringType.replace(".", "_") + "_" + origin.clauseIndex.toString()
    }
}

func collectInvariants(contract: ResolvedTypeContract): ArrayList<ResolvedInvariant> {
    let invariants = ArrayList<ResolvedInvariant>()
    for (resolved in contract.clauses) {
        if (let TypeClause.Invariant(invariant) <- resolved.clause) {
            invariants.add(ResolvedInvariant(resolved.origin, invariant))
        }
    }
    invariants
}

/// Explicit checker methods are owned by the user and must not be generated again.
func declaredInvariantMethods(body: Body): HashSet<String> {
    let names = HashSet<String>()
    for (member in body.decls) {
        if (let method: FuncDecl <- member) {
            let name = method.identifier.value
            if (name == "_contract_invariant" || name == "_contract_static_invariant") {
                names.add(name)
            }
        }
    }
    names
}

/// A class ancestor already publishes a checker method for its own clause; only the
/// declaring type itself or an interface (which has no method bodies) needs a local one.
func ownsInvariantBody(origin: ClauseOrigin, typeName: String): Bool {
    // Origins are stored canonically qualified; the generated type's name is canonicalized
    // the same way so the own-type check survives `CANGJIE_STDX_CONTRACT_PKG_NAME` being set.
    if (origin.declaringType == canonicalDeclaringTypeName(typeName)) {
        return true
    }
    match (searchMetaData(origin.declaringType)) {
        case Some(meta) => meta.isInterface
        // Unknown origin: generate locally so the generated call always resolves.
        case None => true
    }
}

/// Type scope keeps method parameters from shadowing invariant member names.
func genInvariantMethods(invariants: ArrayList<ResolvedInvariant>, typeName: String, isClass: Bool,
    isOpen: Bool, declared: HashSet<String>): ArrayList<Decl> {
    let methods = ArrayList<Decl>()
    if (invariants.isEmpty() && !isOpen) {
        return methods
    }

    let instanceCalls = Tokens()
    let staticCalls = Tokens()
    for (invariant in invariants) {
        if (ownsInvariantBody(invariant.origin, typeName)) {
            methods.add(genInvariantMethod(invariant, typeName, isClass, isOpen))
        }
        let call = genInvariantCall(invariant)
        if (invariant.clause.isStatic) {
            appendStatement(staticCalls, call)
        } else {
            appendStatement(instanceCalls, call)
        }
    }

    let access = if (isClass) {
        quote(protected)
    } else {
        quote(private)
    }
    let openModifier = if (isClass && isOpen) {
        quote(open)
    } else {
        Tokens()
    }
    if (!declared.contains("_contract_invariant")) {
        methods.add(
            FuncDecl(
                quote(
            $(access) $(openModifier) func _contract_invariant(_contract_member_visibility: ContractVisibility): Unit {
                $(instanceCalls)
            }
        )))
    }
    // Static methods allow redefinition but cannot be marked open.
    if (!declared.contains("_contract_static_invariant")) {
        methods.add(
            FuncDecl(
                quote(
            $(access) static func _contract_static_invariant(_contract_member_visibility: ContractVisibility): Unit {
                $(staticCalls)
            }
        )))
    }
    methods
}

/// One checker per origin so inherited invariants keep running in the scope of the type
/// that declared them (private members stay visible) and shared ancestors run once.
func genInvariantMethod(invariant: ResolvedInvariant, typeName: String, isClass: Bool, isOpen: Bool): Decl {
    let check = genInvariantCheck(invariant.clause, typeName)
    if (invariant.clause.isStatic) {
        let access = if (isClass) {
            quote(protected)
        } else {
            quote(private)
        }
        let name = Token(IDENTIFIER, "_contract_static_invariant_" + invariant.methodSuffix())
        FuncDecl(
            quote(
            $(access) static func $(name)(_contract_member_visibility: ContractVisibility): Unit {
                $(check)
            }
        ))
    } else {
        // An interface-origin checker derives the interface's published `public`
        // empty default (a deriving member must be at least as visible as its base).
        // Unknown origins stay public so the derivation cannot fail either.
        let fromInterface = match (searchMetaData(invariant.origin.declaringType)) {
            case Some(meta) => meta.isInterface
            case None => true
        }
        let access = if (fromInterface) {
            quote(public)
        } else if (isClass) {
            quote(protected)
        } else {
            quote(private)
        }
        let openModifier = if (isClass && isOpen) {
            quote(open)
        } else {
            Tokens()
        }
        let name = Token(IDENTIFIER, "_contract_invariant_" + invariant.methodSuffix())
        FuncDecl(
            quote(
            $(access) $(openModifier) func $(name)(_contract_member_visibility: ContractVisibility): Unit {
                $(check)
            }
        ))
    }
}

func genInvariantCheck(invariant: InvariantClause, typeName: String): Tokens {
    let minimum = visibilityTokens(invariantThreshold(invariant))
    let condition = genEvaluation(invariant.condition.tokens)
    let message = "invariant failed in " + typeName + ": " + escapeInterpolationText(invariant.tokens.toString())
    quote(
        if (_contract_member_visibility.isAtLeast($(minimum))) {
            if (!($(condition))) { throw ContractCheckInvariantException(message: $(message)) }
        }
    )
}

func genInvariantCall(invariant: ResolvedInvariant): Tokens {
    let argument = Token(IDENTIFIER, "_contract_member_visibility")
    if (invariant.clause.isStatic) {
        let name = Token(IDENTIFIER, "_contract_static_invariant_" + invariant.methodSuffix())
        quote($(name)($(argument)))
    } else {
        let name = Token(IDENTIFIER, "_contract_invariant_" + invariant.methodSuffix())
        quote(this.$(name)($(argument)))
    }
}

/// Checkpoints for an interface default member. Each instance invariant is checked
/// through its per-origin hook, which the interface publishes as an empty `public`
/// default and a contract implementor derives.
func genInterfaceDefaultChecks(invariants: ArrayList<ResolvedInvariant>, visibility: ContractVisibility,
    isStatic: Bool): Tokens {
    if (isStatic) {
        return Tokens()
    }
    let checks = Tokens()
    for (invariant in invariants) {
        if (!invariant.clause.isStatic && visibility.isAtLeast(invariantThreshold(invariant.clause))) {
            let name = Token(IDENTIFIER, "_contract_invariant_" + invariant.methodSuffix())
            appendStatement(checks, quote(this.$(name)($(visibilityTokens(visibility)))))
        }
    }
    checks
}

/// The empty per-origin hooks an interface publishes for default-member checkpoints.
/// Published only when the interface actually wraps default members, so purely
/// abstract interfaces stay free of generated symbols for non-opted-in implementors.
func genInterfaceDefaultHooks(invariants: ArrayList<ResolvedInvariant>): ArrayList<Decl> {
    let hooks = ArrayList<Decl>()
    for (invariant in invariants) {
        if (!invariant.clause.isStatic) {
            let name = Token(IDENTIFIER, "_contract_invariant_" + invariant.methodSuffix())
            hooks.add(
                FuncDecl(
                    quote(
                public func $(name)(_contract_member_visibility: ContractVisibility): Unit {}
            )))
        }
    }
    hooks
}

func genInvariantCalls(invariants: ArrayList<ResolvedInvariant>, isStatic: Bool, visibility: ContractVisibility,
    isOpen: Bool, declared: HashSet<String>): Tokens {
    // The `_contract_invariant` aggregators are virtual by design: a subclass that opts into
    // `@Contract` redefines the (always `open`, since only `open` classes can be inherited)
    // parent aggregator with its own per-origin calls, so checkpoints dispatch to the most
    // derived contract set. `isOpen` therefore forces the calls even with no local invariants
    // (a subclass may add them), and `declared` covers a user-supplied checker replacing the
    // generated one. Without inheritance the parent aggregator is shadowed, matching the
    // documented "parent contracts are not inherited by default" rule.
    var checkStatic = isOpen || declared.contains("_contract_static_invariant")
    var checkInstance = !isStatic && (isOpen || declared.contains("_contract_invariant"))
    for (invariant in invariants) {
        if (isStatic && !invariant.clause.isStatic) {
            continue
        }
        if (!visibility.isAtLeast(invariantThreshold(invariant.clause))) {
            continue
        }
        if (invariant.clause.isStatic) {
            checkStatic = true
        } else {
            checkInstance = true
        }
    }
    let checks = Tokens()
    let argument = visibilityTokens(visibility)
    if (checkStatic) {
        appendStatement(checks, quote(_contract_static_invariant($(argument))))
    }
    if (checkInstance) {
        appendStatement(checks, quote(this._contract_invariant($(argument))))
    }
    checks
}

func invariantThreshold(invariant: InvariantClause): ContractVisibility {
    match (invariant.visibility) {
        case Some(InvariantVisibility.OnPublic) => ContractVisibility.Public
        // `on_protected` covers public and protected members but not package-level ones.
        case Some(InvariantVisibility.OnProtected) => ContractVisibility.Protected
        case Some(InvariantVisibility.OnPrivate) => ContractVisibility.Private
        // Without a selector, checks also apply to package-level (internal) members.
        case None => ContractVisibility.Internal
    }
}
