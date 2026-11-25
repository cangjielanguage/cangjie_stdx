/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.generate

import stdx.contract.macros.tokens.isValue
import stdx.contract.macros.syntax.{ExprWithPreSyntax, FunctionContract, IdentifierSyntax, VariableClause}
import stdx.contract.macros.validation.astGetOrDefault
import std.ast.{DiagReportLevel, FuncDecl, FuncParam, ToTokens, Token, Tokens, diagReport, parseType}
import std.collection.{ArrayList, HashSet, map}

/// Share contract phases and state for one callable or accessor generation.
internal abstract class GenCallable {
    let contract: FunctionContract
    let owner: FuncDecl
    let invariants: ?Tokens
    let ctx = GenContext()
    private let bodyHelperName: String

    protected init(contract: FunctionContract, owner: FuncDecl, invariants!: ?Tokens = None,
        bodyHelper!: String = "_contract_body") {
        this.contract = contract
        this.owner = owner
        this.invariants = invariants
        this.bodyHelperName = bodyHelper
    }

    /**
     * @brief Generates the rewritten callable declaration with its contract checks.
     *
     * Rejects non-ordinary targets (`const` functions and async/reasync functions)
     * with a diagnostic; when generation collects errors, the owner is returned
     * unchanged instead of being rebuilt from partial tokens.
     *
     * @return The rewritten declaration tokens with any sibling declarations, or the
     *     owner unchanged when generation is rejected.
     */
    public func gen(): Tokens {
        if (!isValue(owner.keyword, "func") || owner.isConst()) {
            ctx.error("function contract requires an ordinary, non-const function.", "function contract",
                contract.tokens)
            ctx.report()
            return owner.toTokens()
        }
        let isAsync = modifiersHave(owner.modifiers, "async")
        let isReasync = modifiersHave(owner.modifiers, "reasync")
        if (isAsync || isReasync) {
            // The hoisted `_contract_body` helper would silently lose the async modifier and
            // fail to compile inside the macro; reject up front with a readable diagnostic
            // (contract expressions must not suspend either way).
            ctx.error("contract is not supported on async/reasync functions; annotate a synchronous helper instead.",
                "function contract", contract.tokens)
            ctx.report()
            return owner.toTokens()
        }

        let (body, members) = genWrappedBody()
        if (ctx.hasErrors()) {
            // `genWrappedBody` already reported; never rebuild the declaration from
            // partial tokens, which would raise an ASTException on top of the real error.
            return owner.toTokens()
        }
        let generated = FuncDecl(owner.toTokens())
        generated.block = FuncDecl(quote(func generatedBody() { $(body) })).block
        quote($(generated) $(members))
    }

    /**
     * @brief Returns the generated body tokens and any sibling declarations.
     *
     * The default shape hoists the original body into the `_contract_body` helper,
     * evaluates the eligibility gate once at entry, and emits the entry checks
     * (`requires`, `throws` conditions, `$pre` snapshots, invariant checkpoints) plus
     * the exit checks (`ensures`, `throws` violations) around the guarded invoke.
     *
     * @return A pair of the wrapped body tokens and the sibling declarations.
     */
    public open func genWrappedBody(): (Tokens, Tokens) {
        let names = auxiliaryNames(contract)
        if (auxiliaryBoxed()) {
            names.add(boxedAuxKey())
        }
        owner.block = rewriteAuxiliaryMacros(owner.block, names)
        let gate = genGate()
        let (bodyHelper, bodyCall, members) = genBodyBinding()
        let requiresChecks = genRequires(names)
        let (throwsConditions, normalThrowsChecks, exceptionalThrowsChecks) = genThrows(names)
        let (ensuresChecks, preSnapshots) = genEnsures(names)
        let variableDeclarations = genVariables(names)
        let entry = genEntry(requiresChecks, throwsConditions, preSnapshots)
        let (normalExit, exceptionalExit, contractExceptionExit) =
            genExit(ensuresChecks, normalThrowsChecks, exceptionalThrowsChecks)

        if (ctx.hasErrors()) {
            ctx.report()
            return (Tokens(), Tokens())
        }

        let invoke = if (exceptionalExit.size == 0) {
            bodyCall
        } else {
            // Catch only the business call, never entry or normal exit checks.
            quote(try {
                $(bodyCall)
            } catch (_contract_exception: Exception) {
                if (isContractException(_contract_exception)) {
                    // Contract failures bypass the `throws` checks, but invariants must
                    // still hold on this abnormal exit.
                    $(contractExceptionExit)
                    throw _contract_exception
                }
                $(exceptionalExit)
                throw _contract_exception
            })
        }

        let body = quote(
            let _contract_enabled = $(gate)
            $(variableDeclarations)
            $(bodyHelper)
            if (!_contract_enabled) {
                return $(bodyCall)
            }
            $(entry)
            let _contract_result = $(invoke)
            $(normalExit)
            return _contract_result
        )
        (body, members)
    }

    /// Return the eligibility expression evaluated once at entry. Every generated shape uses
    /// the same global gate wrapper, so subclasses only override this when that ever changes.
    protected open func genGate(): Tokens {
        quote(_contract_gateEnabled())
    }

    /// Whether the function-level `variable` holders are boxed into one-element arrays so a
    /// hoisted body helper can share them with the wrapper body. Only the `mut` method shape
    /// hoists its body into a sibling member; every other shape keeps a local helper and the
    /// holders stay plain locals.
    protected open func auxiliaryBoxed(): Bool {
        false
    }

    /// Return local declarations, the body call, and sibling declarations.
    protected open func genBodyBinding(): (Tokens, Tokens, Tokens) {
        let returnType = astGetOrDefault(Tokens()) {=> quote(: $(owner.declType))}
        let body = owner.block.toTokens()
        let helper = Token(IDENTIFIER, bodyHelperName)
        (quote(func $(helper)() $(returnType) $(body)), quote($(helper)()), Tokens())
    }

    protected func genRequires(names: HashSet<String>): Tokens {
        genRequiresChecks(contract, owner.identifier.value, names)
    }

    protected func genThrows(names: HashSet<String>): (Tokens, Tokens, Tokens) {
        let (statements, active, violations, clauses, index) = throwsClauseTable(contract, None, names)
        let conditions = Tokens()
        for (statement in statements) {
            appendStatement(conditions, statement)
        }
        let normal = Tokens()
        let exceptional = Tokens()
        if (index > 0) {
            appendStatement(normal,
                quote(
                if ($(active) false) { throw ContractCheckThrowsException(message: $(throwsNormalMessage(owner.identifier.value, clauses))) }
            ))
            appendStatement(exceptional,
                quote(
                if ($(violations) false) {
                    throw ContractCheckThrowsException(
                        message: $(throwsExceptionalMessage(owner.identifier.value, clauses)) + _contract_exception.message,
                        cause: Some(_contract_exception))
                }
            ))
        }
        (conditions, normal, exceptional)
    }

    protected func genEnsures(names: HashSet<String>): (Tokens, Tokens) {
        let checks = Tokens()
        let preSnapshots = Tokens()
        for (clause in contract.clauses) {
            if (let Ensures(c) <- clause) {
                // Snapshots here are `let` declarations wrapping `genEvaluation` — not the
                // constructor path's `contractCaptureSnapshot(enabled, { => ... })` closure:
                // `$pre` arguments may read mutable locals, which lambdas cannot capture.
                let (expression, _) = splicePreSnapshots(c.condition, names, 0, {value, _ =>
                    let name = ctx.nextPreName()
                    appendStatement(preSnapshots, quote(let $(name) = $(value)))
                    (quote($(name)), 0)
                })
                appendEnsuresCheck(checks, expression,
                    EnsuresTarget(c.ret, quote(_contract_result), owner.identifier.value, c.tokens))
            }
        }
        (checks, preSnapshots)
    }

    /// Declare one holder per function-level `variable` clause.
    protected func genVariables(names: HashSet<String>): Tokens {
        let declarations = Tokens()
        for (clause in contract.clauses) {
            if (let Variable(variable) <- clause) {
                appendStatement(declarations, auxiliaryHolderDecl(variable, names))
            }
        }
        declarations
    }

    protected func genEntry(requiresChecks: Tokens, throwsConditions: Tokens, preSnapshots: Tokens): Tokens {
        let checks = invariants ?? Tokens()
        quote(
            $(requiresChecks)
            $(throwsConditions)
            $(preSnapshots)
            $(checks)
        )
    }

    protected func genExit(ensuresChecks: Tokens, normalThrowsChecks: Tokens, exceptionalThrowsChecks: Tokens):
        (Tokens, Tokens, Tokens) {
        let normal = Tokens()
        let exceptional = Tokens()
        // Contract failures skip `throws` checks (no cascading contract errors) but
        // still have to leave the receiver in a valid invariant state.
        let contractExceptional = Tokens()
        if (let Some(invs) <- invariants) {
            if (invs.size > 0) {
                appendStatement(normal, invs)
                appendStatement(exceptional, invs)
                appendStatement(contractExceptional, invs)
            }
        }
        normal.append(normalThrowsChecks)
        exceptional.append(exceptionalThrowsChecks)
        normal.append(ensuresChecks)
        (normal, exceptional, contractExceptional)
    }
}

func appendStatement(output: Tokens, statement: Tokens): Unit {
    output.append(statement).append(Token(NL))
}

/// Unwrap an `Option` that the parse pipeline guarantees to hold a value: on a missing
/// node, report a warning and return `fallback` instead of crashing the macro process.
internal func unwrapOrReport<T>(value: ?T, tokens: Tokens, what: String, fallback: T): T {
    match (value) {
        case Some(v) => v
        case None =>
            diagReport(DiagReportLevel.WARNING, tokens,
                "expected compiler-provided node was missing: ${what}; falling back", "Contract")
            fallback
    }
}

/// Emit the `requires` checks shared by the function and constructor paths. `context` is
/// the display name of the failing callable (`init` for constructors).
func genRequiresChecks(contract: FunctionContract, context: String, names: HashSet<String>): Tokens {
    let checks = Tokens()
    for (clause in contract.clauses) {
        if (let Requires(c) <- clause) {
            let condition = genEvaluation(rewriteAux(c.condition.tokens, names))
            let message = "requires failed in " + context + ": " + escapeInterpolationText(c.tokens.toString())
            appendStatement(checks,
                quote(
                if (!($(condition))) { throw ContractCheckRequiresException(message: $(message)) }
            ))
        }
    }
    checks
}

/// Per-`throws`-clause table shared by the function and constructor paths: one flag
/// statement per clause plus the combined `active`/`violations` expressions and the
/// clause text for the diagnostics. `gate` is the constructor's `_contract_ctor_enabled`
/// token — there each flag is only evaluated when checks are on; the function path passes
/// None and evaluates flags unconditionally at entry. Every satisfied condition must hold
/// at the same time, so the thrown exception has to be a subtype of each true clause's
/// type; no common subtype means the check always fails.
func throwsClauseTable(contract: FunctionContract, gate: ?Token, names: HashSet<String>)
    : (ArrayList<Tokens>, Tokens, Tokens, String, Int64) {
    let statements = ArrayList<Tokens>()
    let active = Tokens()
    let violations = Tokens()
    var index: Int64 = 0
    var clauses = ""
    for (clause in contract.clauses) {
        if (let Throws(c) <- clause) {
            // Fallback `Nothing` matches no thrown value, so an unparsable exception type makes
            // the violation check fire instead of silently passing. Falling back to `Exception`
            // would match everything and degenerate the check into a no-op.
            let ty = unwrapOrReport(c.exception.parsed, c.tokens, "throws clause exception type",
                parseType(quote(Nothing)))
            let condition = genEvaluation(rewriteAux(c.condition.tokens, names))
            let flag = Token(IDENTIFIER, "_contract_throws_" + index.toString())
            let initializer = match (gate) {
                case Some(enabled) => quote(if ($(enabled)) { $(condition) } else { false })
                case None => condition
            }
            statements.add(quote(let $(flag) = $(initializer)))
            active.append(quote($(flag) ||))
            violations.append(quote(($(flag) && !(_contract_exception is $(ty))) ||))
            clauses += escapeInterpolationText(c.tokens.toString()) + "\n"
            index += 1
        }
    }
    (statements, active, violations, clauses, index)
}

/// `throws` diagnostics shared by both paths; `context` is `init` or the member name.
func throwsNormalMessage(context: String, clauses: String): String {
    "throws failed in " + context + ": required exception was not thrown; clauses:\n" + clauses
}

func throwsExceptionalMessage(context: String, clauses: String): String {
    "throws failed in " + context + ": unexpected exception; clauses:\n" + clauses + "cause: "
}

/// One `?T` holder per function-level `variable` clause, initialized unconditionally: a
/// checks-off build never throws on reads of an auxiliary variable that shadows a
/// same-named member or global; it behaves as a local holding its initial value. When the
/// holder is boxed, its `mut` method body runs in a hoisted member helper and reaches the
/// slot through a parameter, so the holder is a one-element array both sides share.
func auxiliaryHolderDecl(variable: VariableClause, names: HashSet<String>): Tokens {
    let storage = Token(IDENTIFIER, auxiliaryStorage(variable.name.name))
    let ty = variable.ty.tokens
    let initializer = match (variable.initExpr) {
        case Some(initExpr) => quote(Some($(rewriteAux(initExpr.tokens, names))))
        case None => quote(None)
    }
    if (names.contains(boxedAuxKey())) {
        return quote(let $(storage): Array<?$(ty)> = [$(initializer)])
    }
    quote(var $(storage): ?$(ty) = $(initializer))
}

/// Forward every boxed auxiliary holder to a hoisted body helper: one named parameter per
/// `variable` clause on `helper`, and the matching named argument on the helper call. Named
/// form keeps the forwarding legal after any named parameter of the original callable.
func appendBoxedAuxParams(helper: FuncDecl, arguments: Tokens, contract: FunctionContract): Unit {
    for (clause in contract.clauses) {
        if (let Variable(variable) <- clause) {
            let storage = auxStorageToken(variable.name.name)
            helper.funcParams.add(FuncParam(quote($(storage)!: Array<?$(variable.ty.tokens)>)))
            if (arguments.size > 0) {
                arguments.append(quote(,))
            }
            arguments.append(quote($(storage): $(storage)))
        }
    }
}

/// Splice the `$pre(argument)` occurrences of an `ensures` condition: the tokens between
/// arguments pass through unchanged and `capture` binds each argument value, returning its
/// placeholder expression. `state` threads the caller's counter across `$pre` arguments
/// (the constructor numbers its snapshot holders); the function path ignores it. The two
/// binding strategies differ on purpose — the function path binds a plain local `let`
/// because `$pre` arguments may read mutable locals that lambdas cannot capture, while the
/// constructor path takes a runtime `contractCaptureSnapshot` closure.
func splicePreSnapshots(expression: ExprWithPreSyntax, names: HashSet<String>, state: Int64,
    capture: (Tokens, Int64) -> (Tokens, Int64)): (Tokens, Int64) {
    let output = Tokens()
    var index: Int64 = 0
    var nextState = state
    for ((tokenIndex, argument) in expression.pre) {
        output.append(rewriteAux(expression.parseTokens[index..tokenIndex], names))
        let (placeholder, captured) = capture(genEvaluation(rewriteAux(argument.tokens, names)), nextState)
        output.append(placeholder)
        nextState = captured
        index = tokenIndex + 1
    }
    output.append(rewriteAux(expression.parseTokens[index..expression.parseTokens.size], names))
    (output, nextState)
}

/// The per-clause inputs of one `ensures` check: the optional named result binding, the
/// expression it reads, the message scope, and the clause tokens quoted in the message.
class EnsuresTarget {
    let ret: ?IdentifierSyntax
    let resultExpr: Tokens
    let context: String
    let clauseTokens: Tokens

    init(ret: ?IdentifierSyntax, resultExpr: Tokens, context: String, clauseTokens: Tokens) {
        this.ret = ret
        this.resultExpr = resultExpr
        this.context = context
        this.clauseTokens = clauseTokens
    }
}

/// One `ensures` check emission shared by the function and constructor paths: the named
/// result binding reads `resultExpr` (`_contract_result` for functions, `()` for
/// constructors, which have no result value) and the message is scoped by `context`.
func appendEnsuresCheck(checks: Tokens, spliced: Tokens, target: EnsuresTarget): Unit {
    let evaluate = target.ret.map({ret => quote(let $(ret.tokens) = $(target.resultExpr))}) ?? Tokens()
    let condition = genEvaluation(quote($(evaluate); $(spliced)))
    let message = "ensures failed in " + target.context + ": " +
        escapeInterpolationText(target.clauseTokens.toString())
    appendStatement(checks,
        quote(
        if (!($(condition))) { throw ContractCheckEnsuresException(message: $(message)) }
    ))
}
