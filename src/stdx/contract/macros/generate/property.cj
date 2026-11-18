/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.generate

import stdx.contract.macros.syntax.{FunctionContract, PropContract, PropKind}
import stdx.contract.macros.validation.astGetOrDefault
import std.ast.{Annotation, FuncDecl, Node, PropDecl, Token, Tokens}
import std.collection.{ArrayList, HashSet, enumerate, isEmpty}

/**
 * @brief Generates getter/setter contracts and appends the enclosing type's invariant calls.
 *
 * Each accessor body is rewritten into its gate/wrapper shape; when the hoisted
 * helper shape applies, the sibling helper declarations are returned together with
 * the property tokens.
 *
 * @param contract The parsed property contract clauses, split by accessor kind.
 * @param owner The property declaration the contract was attached to.
 * @param invariants The type invariant clauses of the enclosing type.
 * @param isOpen Whether the enclosing type is open, driving checkpoint dispatch.
 * @param declared User-declared invariant checker names already present in the body.
 * @param isStruct Selects the setter body-binding shape (a struct `mut` accessor
 *     cannot host a local helper).
 * @param hostKnown When `false`, falls back to the inline shape
 *     (`GenInlinePropertyAccessor`) for hosts of unknown kind.
 * @param invariantChecks Overrides the derived invariant calls wholesale: an interface
 *     replay injects the per-origin hook calls (`_contract_invariant_*`) that dispatch
 *     to the implementor's derived checkers instead of the host's
 *     `_contract_invariant` aggregator.
 * @return The rewritten property tokens, plus the sibling helpers when hoisting applies.
 */
public func genPropertyContract(contract: PropContract, owner: PropDecl, // cjlint-ignore !G.FUN.01 public API signature is fixed
    invariants: ArrayList<ResolvedInvariant>, isOpen: Bool, declared: HashSet<String>,
    isStruct!: Bool = false, hostKnown!: Bool = true, invariantChecks!: ?Tokens = None): Tokens {
    let (getterContract, setterContract) = splitPropertyContracts(contract)
    let isStatic = modifiersHave(owner.modifiers, "static")
    let visibility = visibilityOf(owner.modifiers)
    let checks = match (invariantChecks) {
        case Some(injected) => injected
        case None => genInvariantCalls(invariants, isStatic, visibility, isOpen, declared)
    }

    // An accessor is also wrapped when only the type-level invariants
    // apply — the property itself may declare no contract clauses at all.
    if (!getterContract.clauses.isEmpty() || checks.size > 0) {
        wrapPropertyGetter(owner, getterContract, checks)
    }
    if (!setterContract.clauses.isEmpty() || checks.size > 0) {
        if (!modifiersHave(owner.modifiers, "mut")) {
            // Validation already reported this; keep the declaration unchanged.
            return owner.toTokens()
        }
        if (let Some(tokens) <- wrapPropertySetter(owner, setterContract, checks, isStruct, hostKnown)) {
            return tokens
        }
    }
    owner.toTokens()
}

/// Split the property contract clauses by accessor kind into two function contracts.
func splitPropertyContracts(contract: PropContract): (FunctionContract, FunctionContract) {
    let getterContract = FunctionContract(contract.tokens)
    let setterContract = FunctionContract(contract.tokens)
    for (clause in contract.clauses) {
        match (clause.kind) {
            case PropKind.Getter => getterContract.clauses.add(all: clause.clauses)
            case PropKind.Setter => setterContract.clauses.add(all: clause.clauses)
        }
    }
    (getterContract, setterContract)
}

func wrapPropertyGetter(owner: PropDecl, contract: FunctionContract, checks: Tokens): Unit {
    let effective = if (contract.clauses.isEmpty()) {
        FunctionContract(Tokens())
    } else {
        contract
    }
    let accessor = owner.getter
    let block = accessor.block.toTokens()
    let shell = FuncDecl(quote(func $(owner.identifier)(): $(owner.declType.toTokens()) $(block)))
    let generated = GenPropertyAccessor(effective, shell, invariants: Some(checks))
    setAccessorBody(accessor, generated.genWrappedBody()[0])
}

/// Wrap the setter accessor; returns the property tokens with the hoisted helper when
/// the accessor shape emits sibling declarations, or None when the property is unchanged.
func wrapPropertySetter(owner: PropDecl, contract: FunctionContract, checks: Tokens,
    isStruct: Bool, hostKnown: Bool): ?Tokens {
    let effective = if (contract.clauses.isEmpty()) {
        FunctionContract(Tokens())
    } else {
        contract
    }
    let accessor = owner.setter
    let parameter = accessorParameterName(accessor)
    let parameterToken = Token(IDENTIFIER, parameter)
    let block = accessor.block.toTokens()
    let shell = FuncDecl(
        quote(func $(owner.identifier)($(parameterToken): $(owner.declType.toTokens())) $(block)))
    let generated: GenCallable = if (isStruct) {
        // Known struct host: hoist the body into a private `mut` member so the
        // mutable receiver is never captured by a local helper.
        GenStructPropertyAccessor(effective, shell, invariants: Some(checks))
    } else if (!hostKnown) {
        // Direct annotation with unknown host kind: neither the
        // hoisted `mut` member (illegal in a class body) nor the local helper
        // (illegal inside a struct `mut` accessor) is safe, so inline the body.
        GenInlinePropertyAccessor(effective, shell, invariants: Some(checks))
    } else {
        // Known class host: a local helper may capture `this` freely.
        GenPropertyAccessor(effective, shell, invariants: Some(checks))
    }
    let (body, members) = generated.genWrappedBody()
    setAccessorBody(accessor, body)
    if (members.size == 0) {
        return None
    }
    // The hoisted helper is a sibling declaration of the property.
    Some(quote($(owner.toTokens()) $(members)))
}

class GenPropertyAccessor <: GenCallable {
    init(contract: FunctionContract, owner: FuncDecl, invariants!: ?Tokens = None) {
        super(contract, owner, invariants: invariants, bodyHelper: "_contract_property_body")
    }
}

/// Setter wrapper for struct hosts: the original body becomes a private `mut` member
/// instead of a local helper function, so the mutable receiver is never captured
/// (the same shape `GenStructMember` uses for `mut` methods).
private class GenStructPropertyAccessor <: GenCallable {
    public init(contract: FunctionContract, owner: FuncDecl, invariants!: ?Tokens = None) {
        super(contract, owner, invariants: invariants, bodyHelper: "_contract_property_body")
    }

    protected override func genBodyBinding(): (Tokens, Tokens, Tokens) {
        let helper = FuncDecl(owner.toTokens())
        helper.identifier = Token(IDENTIFIER, "_contract_property_body_" + owner.identifier.value)
        helper.modifiers = FuncDecl(quote(private mut func body() {})).modifiers
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
        let call = quote(this.$(helper.identifier)($(arguments)))
        (Tokens(), call, helper.toTokens())
    }
}

func setAccessorBody(accessor: FuncDecl, body: Tokens): Unit {
    accessor.block = FuncDecl(quote(func generatedAccessor() { $(body) })).block
}

/// Host-agnostic setter wrapper for the direct-annotation path. The host (struct or
/// class) is invisible to the macro, so the original body is inlined instead of hoisted.
/// A bare `return` in the body would bypass the wrapper's trailing `normalExit`, so
/// every normal exit in the inlined body gets its own copy of the checks (see
/// `insertExitCheck`: lambdas and local functions keep their own `return` semantics).
private class GenInlinePropertyAccessor <: GenCallable {
    public init(contract: FunctionContract, owner: FuncDecl, invariants!: ?Tokens = None) {
        super(contract, owner, invariants: invariants, bodyHelper: "_contract_property_body")
    }

    public override func genWrappedBody(): (Tokens, Tokens) {
        let names = auxiliaryNames(contract)
        owner.block = rewriteAuxiliaryMacros(owner.block, names)
        let bodyNodes = ArrayList<Node>(owner.block.nodes)
        // The block braces belong to the wrapper, not to the inlined fragment.
        // The raw fragment backs the check-disabled early exit; the guarded fragment
        // (checks re-injected before every bare `return`) backs the checked invoke.
        let inlineBody = appendNodeTokens(bodyNodes)
        let gate = genGate()
        let requiresChecks = genRequires(names)
        let (throwsConditions, normalThrowsChecks, exceptionalThrowsChecks) = genThrows(names)
        let (ensuresChecks, preSnapshots) = genEnsures(names)
        let variableDeclarations = genVariables(names)
        let entry = genEntry(requiresChecks, throwsConditions, preSnapshots)
        let (_, exceptional, _) = genExit(ensuresChecks, normalThrowsChecks, exceptionalThrowsChecks)
        let resultBinding = inlineResultBinding(contract)
        let normalExit = Tokens()
        normalExit.append(normalThrowsChecks)
        normalExit.append(ensuresChecks)
        let guardedBody = inlineGuardedBody(bodyNodes, inlineBody, normalExit)

        if (ctx.hasErrors()) {
            ctx.report()
            return (Tokens(), Tokens())
        }

        let invoke = inlineInvoke(guardedBody, exceptionalThrowsChecks, exceptional)
        let body = quote(
            let _contract_enabled = $(gate)
            $(variableDeclarations)
            if (!_contract_enabled) {
                $(inlineBody)
                return
            }
            $(entry)
            $(resultBinding)
            $(invoke)
            $(normalExit)
        )
        (body, Tokens())
    }
}

/// Render statement nodes one per line, as the wrapper's inlined fragment expects.
func appendNodeTokens(nodes: ArrayList<Node>): Tokens {
    let output = Tokens()
    for (node in nodes) {
        output.append(node.toTokens())
        output.append(Token(NL))
    }
    output
}

/// `genEnsures` binds an `ensures ret` clause to `_contract_result`; unlike the
/// base `genWrappedBody` this inline shape has no `let _contract_result = $(invoke)`
/// (the inlined body is a statement block, not an expression). The wrapped setter
/// returns Unit, so the binding mirrors the constructor path's result expression
/// `()`. The caller emits it before the guarded body: that body carries an exit-check
/// copy before every bare `return`, and those copies read `_contract_result`.
func inlineResultBinding(contract: FunctionContract): Tokens {
    for (clause in contract.clauses) {
        if (let Ensures(c) <- clause && let Some(_) <- c.ret) {
            return quote(let _contract_result: Unit = ())
        }
    }
    Tokens()
}

/// Re-inject the exit checks before every bare `return` of the inlined body, or return
/// the raw fragment when the exit checks are empty.
func inlineGuardedBody(bodyNodes: ArrayList<Node>, inlineBody: Tokens, normalExit: Tokens): Tokens {
    if (normalExit.size == 0) {
        return inlineBody
    }
    // Same shape as the constructor exit guard: one expression, gated on the
    // wrapper's switch local (always true on the checked path).
    let exitCheck: Tokens = quote(if (_contract_enabled) { $(normalExit) })
    appendNodeTokens(insertExitCheck(bodyNodes, Some(exitCheck), appendAtEnd: false))
}

/// The checked invocation of the inlined body; wraps it in a catch only when exceptional
/// `throws` checks were generated.
func inlineInvoke(guardedBody: Tokens, exceptionalThrowsChecks: Tokens, exceptional: Tokens): Tokens {
    if (exceptionalThrowsChecks.size == 0) {
        return guardedBody
    }
    // Catch only the business body, never the entry or exit checks.
    quote(try {
        $(guardedBody)
    } catch (_contract_exception: Exception) {
        if (isContractException(_contract_exception)) {
            // Contract failures bypass the `throws` checks.
            throw _contract_exception
        }
        $(exceptional)
        throw _contract_exception
    })
}

/// The real parameter name of an accessor, or the canonical `value` alias when the
/// accessor has no explicit parameter.
func accessorParameterName(accessor: FuncDecl): String {
    if (accessor.funcParams.size > 0) {
        accessor.funcParams[0].identifier.value
    } else {
        "value"
    }
}
