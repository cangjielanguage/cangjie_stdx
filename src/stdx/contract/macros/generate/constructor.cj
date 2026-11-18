/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.generate

import stdx.contract.macros.syntax.{FunctionContract}
import std.ast.{ASTException, Block, CallExpr, DoWhileExpr, Expr, ForInExpr, FuncDecl, IfExpr, MatchExpr, Node, PrimaryCtorDecl, RefExpr, ReturnExpr, ToTokens, Token, Tokens, TryExpr, WhileExpr, parseDecl, parseExpr}
import std.collection.{ArrayList, HashSet, contains, isEmpty}

/**
 * @brief Injects constructor contract checks directly into the primary constructor body.
 *
 * Field initialization cannot be moved into a helper function, so the checks are
 * inlined: `$pre` arguments are snapshotted into plain `let` bindings at entry, and
 * every exit — bare `return` and exceptional exits included — runs the exit checks
 * inside a generated wrapper.
 *
 * @param contract The parsed constructor contract clauses.
 * @param owner The primary constructor declaration the contract was attached to.
 * @return The rewritten constructor tokens.
 */
public func genConstructorContract(contract: FunctionContract, owner: PrimaryCtorDecl): Tokens {
    genConstructorBody(contract, owner.block)
    owner.toTokens()
}

/**
 * @brief Injects constructor contract checks into a constructor surfaced as an ordinary
 * `FuncDecl` named `init`.
 *
 * Some toolchains surface a primary constructor as an ordinary `FuncDecl` named
 * `init`; this entry point applies the same inlining as `genConstructorContract`
 * to that shape.
 *
 * @param contract The parsed constructor contract clauses.
 * @param owner The `init` function declaration the contract was attached to.
 * @return The rewritten constructor tokens.
 */
public func genConstructorFuncContract(contract: FunctionContract, owner: FuncDecl): Tokens {
    genConstructorBody(contract, owner.block)
    owner.toTokens()
}

/// Pieces generated once per constructor expansion and shared by the entry and catch emitters.
class ConstructorExpansion {
    /// Auxiliary-variable holders; declared in both check modes.
    let holderNodes = ArrayList<Node>()
    /// Entry checks (`requires`, `throws` declarations, `$pre` bindings). When `$pre`
    /// snapshots are present these are emitted inside the checked branch so the snapshots
    /// are not evaluated with checks disabled.
    let checkNodes = ArrayList<Node>()
    var throwsDeclared = false
    var throwsActive = Tokens()
    var throwsViolations = Tokens()
    var exitCheckTokens: ?Tokens = None
    var hasPreSnapshots = false
}

func genConstructorBody(contract: FunctionContract, block: Block): Unit {
    if (contract.clauses.isEmpty()) {
        return
    }

    let names = auxiliaryNames(contract)
    block.nodes = rewriteAuxiliaryMacros(block, names).nodes
    // Render the unchecked body now: `insertExitCheck` rewrites nested blocks in place, so
    // rendering afterwards would leak the generated exit checks (which read the `$pre`
    // snapshot bindings) into the check-disabled branch where those bindings do not exist.
    let plainTokens = constructorPlainBodyTokens(ArrayList<Node>(block.nodes))

    let enabled = Token(IDENTIFIER, "_contract_ctor_enabled")
    let expansion = buildConstructorExpansion(contract, names, enabled)
    let bodyNodes = insertExitCheck(ArrayList<Node>(block.nodes), expansion.exitCheckTokens)
    let (prefix, rest) = splitConstructorSuperCall(bodyNodes)

    // The body always runs inside a wrapper so the type-level invariant injection can
    // also guard the exceptional exit; exits include exceptional ones.
    let catchNodes = genConstructorCatch(contract, enabled, expansion)
    block.nodes = prefix
    block.nodes.add(parseDecl(quote(let $(enabled) = _contract_gateEnabled())))
    block.nodes.add(all: expansion.holderNodes)
    if (expansion.hasPreSnapshots) {
        // `$pre` arguments must not run while checks are disabled, but a constructor
        // cannot early-return before field initialization. Bind the snapshots inside the
        // checked branch together with the exit checks that read them, and let the
        // disabled branch run the untouched body.
        let checkedBody = Tokens()
        checkedBody.append(quote(try {
            $(rest)
        } catch (_contract_exception: Exception) {
            $(catchNodes)
        }))
        block.nodes.add(parseExpr(quote(
            if ($(enabled)) {
                $(expansion.checkNodes)
                $(checkedBody)
            } else {
                $(plainTokens)
            }
        )))
    } else {
        block.nodes.add(all: expansion.checkNodes)
        block.nodes.add(parseExpr(quote(try {
            $(rest)
        } catch (_contract_exception: Exception) {
            $(catchNodes)
        })))
    }
}

/// Build the entry declarations and the per-exit check tokens of the constructor contract.
func buildConstructorExpansion(contract: FunctionContract, names: HashSet<String>,
    enabled: Token): ConstructorExpansion {
    let expansion = ConstructorExpansion()
    expansion.holderNodes.add(all: genConstructorVariables(contract, names))

    let requiresChecks = genRequiresChecks(contract, "init", names)
    if (requiresChecks.size > 0) {
        expansion.checkNodes.add(parseExpr(quote(if ($(enabled)) { $(requiresChecks) })))
    }

    let (throwsDecls, throwsActive, throwsViolations) = genThrows(contract, names)
    expansion.checkNodes.add(all: throwsDecls)
    expansion.throwsDeclared = throwsDecls.size > 0
    expansion.throwsActive = throwsActive
    expansion.throwsViolations = throwsViolations

    let preBindings = ArrayList<Node>()
    let ensuresChecks = genEnsures(contract, preBindings, names)
    expansion.checkNodes.add(all: preBindings)
    expansion.hasPreSnapshots = preBindings.size > 0

    let exitTokens = Tokens()
    if (expansion.throwsDeclared) {
        exitTokens.append(constructorNormalThrows(enabled, throwsActive, contract))
    }
    exitTokens.append(ensuresChecks)
    // One guard per exit; nested bare `return` statements get their own copy so no
    // exit can skip the checks.
    expansion.exitCheckTokens = if (exitTokens.size == 0) {
        None
    } else {
        Some(quote(if ($(enabled)) { $(exitTokens) }))
    }
    expansion
}

/// The normal-exit `throws` check of a constructor.
func constructorNormalThrows(enabled: Token, throwsActive: Tokens, contract: FunctionContract): Tokens {
    let normalThrows = Tokens()
    let message = throwsNormalMessage("init", throwsClauseText(contract))
    appendStatement(normalThrows,
        quote(
        if ($(enabled) && ($(throwsActive) false)) { throw ContractCheckThrowsException(message: $(message)) }
    ))
    normalThrows
}

/// Split a super call (which must stay first) from the remaining constructor nodes.
func splitConstructorSuperCall(bodyNodes: ArrayList<Node>): (ArrayList<Node>, ArrayList<Node>) {
    let hasSuper = bodyNodes.size > 0 && isSuperCall(bodyNodes[0])
    let prefix = ArrayList<Node>()
    if (hasSuper) {
        prefix.add(bodyNodes[0])
    }
    let rest = ArrayList<Node>()
    let start = if (hasSuper) { 1 } else { 0 }
    for (index in start..bodyNodes.size) {
        rest.add(bodyNodes[index])
    }
    (prefix, rest)
}

/// Render the constructor body without its leading super call, one statement per line.
/// Must run before `insertExitCheck`, which rewrites nested blocks in place and would
/// otherwise contaminate the rendered tokens with generated exit checks.
func constructorPlainBodyTokens(nodes: ArrayList<Node>): Tokens {
    let (_, plainRest) = splitConstructorSuperCall(nodes)
    let tokens = Tokens()
    for (node in plainRest) {
        // A statement's tokens carry no trailing separator; without an explicit NL the
        // concatenated statements re-parse as one malformed expression.
        tokens.append(node.toTokens()).append(Token(NL))
    }
    tokens
}

/// The catch body of the constructor wrapper: contract exceptions pass through, other
/// exceptions first run the contract-exception dispatch and the `throws` violation check.
func genConstructorCatch(contract: FunctionContract, enabled: Token,
    expansion: ConstructorExpansion): Tokens {
    let catchNodes = Tokens()
    if (expansion.throwsDeclared) {
        catchNodes.append(
            quote(
            if (isContractException(_contract_exception)) { throw _contract_exception }
        ))
        let message = throwsExceptionalMessage("init", throwsClauseText(contract))
        appendStatement(catchNodes,
            quote(
            if ($(enabled) && ($(expansion.throwsViolations) false)) {
                throw ContractCheckThrowsException(
                    message: $(message) + _contract_exception.message,
                    cause: Some(_contract_exception))
            }
        ))
    }
    catchNodes.append(quote(throw _contract_exception))
    catchNodes
}

/// Declare one holder per function-level `variable` clause.
func genConstructorVariables(contract: FunctionContract, names: HashSet<String>): ArrayList<Node> {
    let declarations = ArrayList<Node>()
    for (clause in contract.clauses) {
        if (let Variable(variable) <- clause) {
            declarations.add(parseDecl(auxiliaryHolderDecl(variable, names)))
        }
    }
    declarations
}

func isSuperCall(node: Node): Bool {
    if (node is Expr) {
        let expression = (node as Expr).getOrThrow()
        if (expression is CallExpr) {
            let call = (expression as CallExpr).getOrThrow()
            if (call.callFunc is RefExpr) {
                return (call.callFunc as RefExpr).getOrThrow().identifier.value == "super"
            }
        }
    }
    false
}

func genThrows(contract: FunctionContract, names: HashSet<String>): (ArrayList<Node>, Tokens, Tokens) {
    let (statements, active, violations, _, _) =
        throwsClauseTable(contract, Some(Token(IDENTIFIER, "_contract_ctor_enabled")), names)
    let declarations = ArrayList<Node>()
    for (statement in statements) {
        declarations.add(parseDecl(statement))
    }
    (declarations, active, violations)
}

func genEnsures(contract: FunctionContract, preBindings: ArrayList<Node>,
    names: HashSet<String>): Tokens {
    let checks = Tokens()
    var snapshotId: Int64 = 0
    for (clause in contract.clauses) {
        if (let Ensures(c) <- clause) {
            let (expression, nextSnapshotId) = splicePreSnapshots(c.condition, names, snapshotId,
                {value: Tokens, id: Int64 =>
                    let name = Token(IDENTIFIER, "_contract_pre_" + (id + 1).toString())
                    // The binding itself is emitted inside the checked branch (see
                    // `genConstructorBody`), so with checks disabled `$pre` never runs.
                    // A plain `let` also allows `$pre` arguments to read mutable locals,
                    // which a capturing lambda could not.
                    preBindings.add(parseDecl(quote(let $(name) = $(value))))
                    (quote($(name)), id + 1)
                })
            snapshotId = nextSnapshotId
            appendEnsuresCheck(checks, expression, EnsuresTarget(c.ret, quote(()), "init", c.tokens))
        }
    }
    checks
}

func throwsClauseText(contract: FunctionContract): String {
    var text = ""
    for (clause in contract.clauses) {
        if (let Throws(c) <- clause) {
            text += escapeInterpolationText(c.tokens.toString()) + "\n"
        }
    }
    text
}

/// Insert the exit check before every bare `return` in the statement list (including
/// returns nested in `if`/loops/`try`/`match` blocks) and at the end of the list when
/// it has no top-level return. Lambda and local-function bodies are left alone.
func insertExitCheck(nodes: ArrayList<Node>, exitCheckTokens: ?Tokens, appendAtEnd!: Bool = true): ArrayList<Node> {
    let check = match (exitCheckTokens) {
        case Some(value) => value
        case None => return nodes
    }
    let output = ArrayList<Node>()
    var sawReturn = false
    for (node in nodes) {
        if (isReturnNode(node)) {
            output.add(parseExpr(check))
            output.add(node)
            sawReturn = true
            continue
        }
        insertExitCheckInChildren(node, check)
        output.add(node)
    }
    if (!sawReturn && appendAtEnd) {
        output.add(parseExpr(check))
    }
    output
}

/// The else branch accessor throws when absent; surface it as an option instead.
func ctorElseBranch(ifExpr: IfExpr): ?Expr {
    try {
        Some(ifExpr.elseExpr)
    } catch (e: ASTException) {
        None
    }
}

/// Rewrite the nested blocks of one statement so that `return` inside them still runs the
/// exit check. Nested blocks never get a check appended at the end: falling out of an
/// `if`/loop/`try`/`match` body flows back into an enclosing scope that already checks.
func insertExitCheckInChildren(node: Node, check: Tokens): Unit {
    if (!(node is Expr)) {
        return
    }
    let expression = (node as Expr).getOrThrow()
    if (expression is IfExpr) {
        insertExitCheckInIf((expression as IfExpr).getOrThrow(), check)
    } else if (expression is WhileExpr) {
        insertExitCheckInBlock((expression as WhileExpr).getOrThrow().block, check)
    } else if (expression is DoWhileExpr) {
        insertExitCheckInBlock((expression as DoWhileExpr).getOrThrow().block, check)
    } else if (expression is ForInExpr) {
        insertExitCheckInBlock((expression as ForInExpr).getOrThrow().block, check)
    } else if (expression is MatchExpr) {
        insertExitCheckInMatch((expression as MatchExpr).getOrThrow(), check)
    } else if (expression is TryExpr) {
        insertExitCheckInTry((expression as TryExpr).getOrThrow(), check)
    } else if (expression is Block) {
        // `unsafe { ... }` surfaces as a Block expression; a `return` inside it is a normal
        // constructor exit and must run the checks.
        insertExitCheckInBlock((expression as Block).getOrThrow(), check)
    }
    // Lambdas and local functions keep their own `return` semantics; skip them.
}

/// Rewrite the nodes of one nested block so a `return` inside it runs the exit check.
func insertExitCheckInBlock(block: Block, check: Tokens): Unit {
    block.nodes = insertExitCheck(ArrayList<Node>(block.nodes), Some(check), appendAtEnd: false)
}

func insertExitCheckInIf(ifExpr: IfExpr, check: Tokens): Unit {
    insertExitCheckInBlock(ifExpr.ifBlock, check)
    // `else` surfaces as a block; `else if` surfaces as a nested IfExpr. Both are
    // covered: the block is rewritten here, the nested if by the recursive walk.
    match (ctorElseBranch(ifExpr)) {
        case Some(elseBranch) =>
            if (elseBranch is Block) {
                insertExitCheckInBlock((elseBranch as Block).getOrThrow(), check)
            } else {
                insertExitCheckInChildren(elseBranch, check)
            }
        case None => ()
    }
}

func insertExitCheckInMatch(matchExpr: MatchExpr, check: Tokens): Unit {
    // A `return` inside a match case is a normal exit and must run the checks too.
    // Every case body is exposed as a block, even the brace-less form.
    for (matchCase in matchExpr.matchCases) {
        let caseBlock: ?Block = try {
            Some(matchCase.block)
        } catch (_: ASTException) {
            None
        }
        if (let Some(block) <- caseBlock) {
            insertExitCheckInBlock(block, check)
        }
    }
}

func insertExitCheckInTry(tryExpr: TryExpr, check: Tokens): Unit {
    insertExitCheckInBlock(tryExpr.tryBlock, check)
    for (catchBlock in tryExpr.catchBlocks) {
        insertExitCheckInBlock(catchBlock, check)
    }
    // A `return` in `finally` exits the constructor as well.
    let finallyBlock: ?Block = try {
        Some(tryExpr.finallyBlock)
    } catch (_: ASTException) {
        None
    }
    if (let Some(block) <- finallyBlock) {
        insertExitCheckInBlock(block, check)
    }
}

func isReturnNode(node: Node): Bool {
    if (node is Expr) {
        (node as Expr).getOrThrow() is ReturnExpr
    } else {
        false
    }
}

/// Add the enclosing type's invariant checks to a primary constructor exit.
internal func injectConstructorInvariants(owner: PrimaryCtorDecl, checks: Tokens): Unit {
    injectConstructorBlockInvariants(owner.block, checks)
}

internal func injectConstructorFuncInvariants(owner: FuncDecl, checks: Tokens): Unit {
    injectConstructorBlockInvariants(owner.block, checks)
}

func injectConstructorBlockInvariants(block: Block, checks: Tokens): Unit {
    if (checks.size == 0) {
        return
    }
    let gate = Token(IDENTIFIER, "_contract_ctor_type_enabled")
    let entry = parseDecl(quote(let $(gate) = _contract_gateEnabled()))
    let invariantTokens = quote(if ($(gate)) { $(checks) })
    let original = ArrayList<Node>(block.nodes)
    let hasSuper = original.size > 0 && isSuperCall(original[0])
    let output = ArrayList<Node>()
    if (hasSuper) {
        output.add(original[0])
    }
    output.add(entry)
    let body = ArrayList<Node>()
    let start = if (hasSuper) { 1 } else { 0 }
    for (index in start..original.size) {
        body.add(original[index])
    }
    let wrapper = lastTryExpr(body)
    match (wrapper) {
        case Some(tryExpr) =>
            // Declaration-level contract present: the generated wrapper is the trailing
            // try expression. Invariants go before every exit check inside the try and
            // first inside every catch, which also covers contract exceptions.
            tryExpr.tryBlock.nodes = insertInvariantsWrapper(tryExpr.tryBlock, invariantTokens)
            injectCatchInvariants(tryExpr, invariantTokens)
            for (node in body) {
                output.add(node)
            }
        case None =>
            // No declaration-level contract: wrap the body so invariants also guard the
            // exceptional exit. The normal-exit check stays outside the wrapper so a
            // failing invariant runs exactly once per exit; bare `return`s get their own copy.
            let guarded = insertExitCheck(body, Some(invariantTokens), appendAtEnd: false)
            output.add(parseExpr(quote(try {
                $(guarded)
            } catch (_contract_exception: Exception) {
                $(parseExpr(invariantTokens))
                throw _contract_exception
            })))
            output.add(parseExpr(invariantTokens))
    }
    block.nodes = output
}

/// The declaration-level wrapper is the trailing try of the constructor body. A
/// user-written `try` must not be mistaken for it: the generated wrapper
/// has exactly one catch, whose block ends by rethrowing `_contract_exception`.
func lastTryExpr(nodes: ArrayList<Node>): ?TryExpr {
    var found: ?TryExpr = None
    for (node in nodes) {
        if (node is Expr) {
            let expression = (node as Expr).getOrThrow()
            if (expression is TryExpr) {
                let tryExpr = (expression as TryExpr).getOrThrow()
                if (isGeneratedCtorWrapper(tryExpr)) {
                    found = Some(tryExpr)
                }
            }
        }
    }
    found
}

/// Shape test for the try expression generated by `genConstructorBody`: a single
/// `catch (_contract_exception: Exception)` whose block rethrows. A user-written `try`
/// only collides when it binds the same reserved name.
func isGeneratedCtorWrapper(tryExpr: TryExpr): Bool {
    if (tryExpr.catchBlocks.size != 1) {
        return false
    }
    let catchBlock = tryExpr.catchBlocks[0]
    if (catchBlock.nodes.isEmpty()) {
        return false
    }
    let last = catchBlock.nodes[catchBlock.nodes.size - 1]
    if (!(last is Expr)) {
        return false
    }
    // Contains-based like `isCtorExitCheck`: token rendering inserts separators.
    let text = (last as Expr).getOrThrow().toTokens().toString()
    text.contains("throw") && text.contains("_contract_exception")
}

/// Main try block of the constructor: invariants before every exit check, or at the
/// block tail (itself an exit) when no exit check exists.
func insertInvariantsWrapper(block: Block, invariantTokens: Tokens): ArrayList<Node> {
    let _ = injectCtorExitIfBlock(block, invariantTokens, appendWhenMissing: true)
    block.nodes
}

/// Place the invariant check before each constructor exit check (`if (_contract_ctor_enabled)`)
/// emitted by the declaration-level expansion, including nested copies. `appendWhenMissing`
/// marks the constructor's main try block, whose tail is itself an exit.
func injectCtorExitIfBlock(block: Block, invariantTokens: Tokens, appendWhenMissing!: Bool = false): Bool {
    let output = ArrayList<Node>()
    var inserted = false
    var previousWasCheck = false
    for (node in ArrayList<Node>(block.nodes)) {
        var emittedCheck = false
        if (isCtorExitCheck(node)) {
            output.add(parseExpr(invariantTokens))
            inserted = true
            emittedCheck = true
        } else if (isReturnNode(node) && !previousWasCheck) {
            // A bare `return` is a normal exit even when the member contract declares no
            // ensures/throws exit check to attach the invariant to.
            output.add(parseExpr(invariantTokens))
            inserted = true
            emittedCheck = true
        }
        previousWasCheck = emittedCheck
        let childInserted = injectCtorInvariantsInChildren(node, invariantTokens)
        inserted = inserted || childInserted
        output.add(node)
    }
    // The block tail is itself an exit unless it is one of the exits already guarded above.
    if (appendWhenMissing && !endsWithCtorExit(output)) {
        output.add(parseExpr(invariantTokens))
        inserted = true
    }
    block.nodes = output
    inserted
}

func endsWithCtorExit(nodes: ArrayList<Node>): Bool {
    if (nodes.isEmpty()) {
        return false
    }
    let last = nodes[nodes.size - 1]
    isReturnNode(last) || isCtorExitCheck(last)
}

func injectCtorInvariantsInChildren(node: Node, invariantTokens: Tokens): Bool {
    if (!(node is Expr)) {
        return false
    }
    let expression = (node as Expr).getOrThrow()
    if (expression is IfExpr) {
        return injectCtorInvariantsInIf((expression as IfExpr).getOrThrow(), invariantTokens)
    }
    if (expression is WhileExpr) {
        return injectCtorExitIfBlock((expression as WhileExpr).getOrThrow().block, invariantTokens)
    }
    if (expression is DoWhileExpr) {
        return injectCtorExitIfBlock((expression as DoWhileExpr).getOrThrow().block, invariantTokens)
    }
    if (expression is ForInExpr) {
        return injectCtorExitIfBlock((expression as ForInExpr).getOrThrow().block, invariantTokens)
    }
    if (expression is MatchExpr) {
        return injectCtorInvariantsInMatch((expression as MatchExpr).getOrThrow(), invariantTokens)
    }
    if (expression is TryExpr) {
        return injectCtorInvariantsInTry((expression as TryExpr).getOrThrow(), invariantTokens)
    }
    if (expression is Block) {
        // `unsafe { ... }` surfaces as a Block expression, not a dedicated node; a `return`
        // inside it leaves the constructor and must run the checks like any other exit.
        return injectCtorExitIfBlock((expression as Block).getOrThrow(), invariantTokens)
    }
    false
}

func injectCtorInvariantsInIf(ifExpr: IfExpr, invariantTokens: Tokens): Bool {
    var inserted = injectCtorExitIfBlock(ifExpr.ifBlock, invariantTokens)
    match (ctorElseBranch(ifExpr)) {
        case Some(elseBranch) =>
            if (elseBranch is Block) {
                let elseBlock = (elseBranch as Block).getOrThrow()
                let elseInserted = injectCtorExitIfBlock(elseBlock, invariantTokens)
                inserted = inserted || elseInserted
            } else {
                let nested = injectCtorInvariantsInChildren(elseBranch, invariantTokens)
                inserted = inserted || nested
            }
        case None => ()
    }
    inserted
}

func injectCtorInvariantsInMatch(matchExpr: MatchExpr, invariantTokens: Tokens): Bool {
    // Match case bodies are exits too; keep the node set in sync with
    // `insertExitCheckInChildren`.
    var inserted = false
    for (matchCase in matchExpr.matchCases) {
        let caseBlock: ?Block = try {
            Some(matchCase.block)
        } catch (_: ASTException) {
            None
        }
        if (let Some(block) <- caseBlock) {
            let caseInserted = injectCtorExitIfBlock(block, invariantTokens)
            inserted = inserted || caseInserted
        }
    }
    inserted
}

func injectCtorInvariantsInTry(tryExpr: TryExpr, invariantTokens: Tokens): Bool {
    // Nested user try: only exits reached from here matter; the constructor's own
    // wrapper is handled by the caller, and its catches by `injectCatchInvariants`.
    var inserted = injectCtorExitIfBlock(tryExpr.tryBlock, invariantTokens)
    for (catchBlock in tryExpr.catchBlocks) {
        let catchInserted = injectCtorExitIfBlock(catchBlock, invariantTokens)
        inserted = inserted || catchInserted
    }
    let finallyBlock: ?Block = try {
        Some(tryExpr.finallyBlock)
    } catch (_: ASTException) {
        None
    }
    if (let Some(block) <- finallyBlock) {
        let finallyInserted = injectCtorExitIfBlock(block, invariantTokens)
        inserted = inserted || finallyInserted
    }
    inserted
}

func isCtorExitCheck(node: Node): Bool {
    if (node is Expr) {
        let expression = (node as Expr).getOrThrow()
        if (expression is IfExpr) {
            let ifExpr = (expression as IfExpr).getOrThrow()
            // Exact gate only: `_contract_ctor_type_enabled` contains
            // `_contract_ctor_enabled` as a substring and must not match, and neither may
            // the `throws`-violation gate `if (enabled && (violations false))`.
            return isSingleIdentifier(ifExpr.condition.toTokens(), "_contract_ctor_enabled")
        }
    }
    false
}

func isSingleIdentifier(tokens: Tokens, expected: String): Bool {
    var found = false
    for (token in tokens) {
        if (token.kind == NL) {
            continue
        }
        if (found || token.kind != IDENTIFIER || token.value != expected) {
            return false
        }
        found = true
    }
    found
}

/// Prepend the invariant check to every catch of the constructor's wrapper try: the
/// exceptional exit checks invariants first, before the contract-exception dispatch
/// and the `throws` violation checks.
func injectCatchInvariants(tryExpr: TryExpr, invariantTokens: Tokens): Unit {
    for (catchBlock in tryExpr.catchBlocks) {
        let prepended = ArrayList<Node>()
        prepended.add(parseExpr(invariantTokens))
        for (existing in catchBlock.nodes) {
            prepended.add(existing)
        }
        catchBlock.nodes = prepended
    }
}
