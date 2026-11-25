/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.generate

import stdx.contract.macros.syntax.{FunctionContract}
import stdx.contract.macros.validation.astGetOrDefault
import std.ast.{Annotation, DiagReportLevel, FuncDecl, Token, Tokens, diagReport}
import std.collection.{ArrayList, enumerate}

/**
 * @brief Generates the contract for functions or methods.
 *
 * Dispatches on the owner shape: `foreign` functions are rejected with a diagnostic,
 * a `mut` method (a struct-host member) routes to the struct-shaped generator that
 * hoists the body into a private `mut` member, and everything else goes through the
 * ordinary function generator with its global eligibility gate.
 *
 * @param contract The parsed function contract clauses.
 * @param owner The function or method declaration the contract was attached to.
 * @return The rewritten declaration tokens with the generated contract checks.
 */
public func genFunction(contract: FunctionContract, owner: FuncDecl): Tokens {
    if (methodHasModifier(owner, "foreign")) {
        // Contracts are not supported on foreign functions. Reconstructing a
        // foreign `FuncDecl` inside the macro would crash with an unrelated
        // ASTException, so report a targeted diagnostic instead.
        diagReport(DiagReportLevel.ERROR, owner.toTokens(),
            "contracts are not supported on foreign functions", "Contract")
        return owner.toTokens()
    }
    // A `mut` method belongs to a struct or an interface (class members, top-level and
    // local functions cannot declare `mut`), and its body is hoisted into a sibling `mut`
    // member: a local helper cannot touch the receiver of a `mut` method. The host is not
    // visible from a standalone member macro, and `private` is illegal on interface
    // members, so the hoisted helper omits that modifier to stay legal in both hosts.
    // Type-level expansion knows its host and uses `GenStructMember` directly instead.
    if (methodHasModifier(owner, "mut")) {
        return GenStructMember(contract, owner, privateHelper: false).gen()
    }
    GenFunction(contract, owner).gen()
}

/// Generate an ordinary function with its global gate.
private class GenFunction <: GenCallable {
    public init(contract: FunctionContract, owner: FuncDecl) {
        super(contract, owner)
    }
}

/// Generate a class method with the global gate and invariant checks.
internal class GenClassMember <: GenCallable {
    public init(contract: FunctionContract, owner: FuncDecl, invariants!: ?Tokens = None) {
        super(contract, owner, invariants: invariants, bodyHelper: "_contract_invariant_body")
    }
}

/// Generate a struct method, preserving mut receiver updates.
internal class GenStructMember <: GenCallable {
    /// Whether the hoisted `mut` helper may be `private`. A known struct host allows it;
    /// an interface host does not, so the helper is emitted without a visibility modifier.
    private let privateHelper: Bool

    public init(contract: FunctionContract, owner: FuncDecl, invariants!: ?Tokens = None,
        privateHelper!: Bool = true) {
        super(contract, owner, invariants: invariants, bodyHelper: "_contract_invariant_body")
        this.privateHelper = privateHelper
    }

    /// Keep mut bodies in a separate member to avoid capturing this.
    protected override func genBodyBinding(): (Tokens, Tokens, Tokens) {
        if (!methodHasModifier(owner, "mut")) {
            return super.genBodyBinding()
        }

        let helper = FuncDecl(owner.toTokens())
        helper.identifier = Token(IDENTIFIER, "_contract_invariant_body_" + owner.identifier.value)
        let prototype = if (privateHelper) {
            quote(private mut func body() {})
        } else {
            quote(mut func body() {})
        }
        helper.modifiers = FuncDecl(prototype).modifiers
        helper.annotations = ArrayList<Annotation>()

        let arguments = Tokens()
        for ((index, parameter) in enumerate(owner.funcParams)) {
            if (index > 0) {
                arguments.append(quote(,))
            }
            let name = parameter.identifier
            if (astGetOrDefault(false) {=> parameter.not.kind == NOT}) {
                arguments.append(quote($(name):))
            }
            arguments.append(name)
        }
        // Boxed auxiliary holders are shared with the hoisted body through named
        // parameters, so the forwarding stays legal after any named parameter of the
        // original method.
        appendBoxedAuxParams(helper, arguments, contract)
        let typeArguments = if (owner.isGenericDecl) {
            owner.genericParam.toTokens()
        } else {
            Tokens()
        }
        let call = quote(this.$(helper.identifier)$(typeArguments)($(arguments)))
        (Tokens(), call, helper.toTokens())
    }

    /// A `mut` method's body is hoisted into a sibling member, so its function-level
    /// `variable` holders must be boxed to stay reachable from both functions.
    protected override func auxiliaryBoxed(): Bool {
        methodHasModifier(owner, "mut") && hasVariableClause(contract)
    }
}
