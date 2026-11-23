/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.generate

import stdx.contract.macros.syntax.{AssertBlock, GhostBlock, LoopInvariant}
import stdx.contract.macros.tokens.{isValue, trimNewLine}
import std.ast.{Block, DiagReportLevel, DoWhileExpr, ForInExpr, ToTokens, TokenKind, Tokens, WhileExpr, diagReport, parseExpr}
import std.collection.{ArrayList}

private func emitContractBlock(body: Tokens): Tokens {
    quote(if (_contract_gateEnabled()) { $(body) })
}

/**
 * @brief Expands a `@ghost` block into the gated execution of its statements.
 *
 * The block tokens run inside the global eligibility gate, so reads and updates of
 * auxiliary (ghost) variables only execute while contract checking is enabled.
 *
 * @param ghost The ghost block carrying the statement tokens to gate.
 * @return The gated statement tokens.
 */
public func genGhost(ghost: GhostBlock): Tokens {
    emitContractBlock(ghost.tokens)
}

/**
 * @brief Expands a `@contractAssert` block into gated, ordered assertion checks.
 *
 * One check per condition: the doc requires evaluating `<expr>+` in order, and a
 * per-condition message pinpoints which assertion failed. A condition that fails to
 * parse degrades to `true`, so the assertion never fires instead of crashing the
 * macro expansion.
 *
 * @param assertion The assert block with its parsed condition definitions.
 * @return The gated check tokens throwing `ContractCheckAssertException` on failure.
 */
public func genAssert(assertion: AssertBlock): Tokens {
    // One check per condition: the doc requires evaluating `<expr>+` in order,
    // and a per-condition message pinpoints which assertion failed.
    let checks = Tokens()
    for (definition in assertion.conditions) {
        // Fallback `true` degrades the assertion to a check that never fires.
        let condition = unwrapOrReport(definition.parsed, definition.tokens,
            "assert condition expression", parseExpr(quote(true)))
        let message = "assertion failed: " + escapeInterpolationText(definition.tokens.toString())
        checks.append(quote(
            if (!($(condition))) { throw ContractCheckAssertException(message: $(message)) }))
    }
    emitContractBlock(
        genEvaluation(checks))
}

/// Run one contract expression with re-entrancy suppression. The guarded expression stays
/// in expression position (conditions are embedded inside `if`/`let`); a lambda-based
/// wrapper is impossible because lambdas cannot capture mutable variables.
func genEvaluation(expression: Tokens): Tokens {
    quote(try {
        contractEvalEnter()
        $(expression)
    } finally {
        contractEvalExit()
    })
}

/**
 * @brief Expands a `@loopInvariant` block into the loop with its invariant checks.
 *
 * One check per condition, evaluated in order with a per-condition message. The
 * check placement follows the loop shape: while loops check at the start of every
 * iteration and once when the loop exits, for-in loops at the start of every
 * iteration, and do-while loops after each body execution, with every `continue`
 * of the enclosing loop rewritten to run the checks first. A non-loop `in`
 * expression is reported as an error.
 *
 * @param invariant The loop invariant block with its conditions and loop expression.
 * @return The rewritten loop tokens with the injected invariant checks.
 */
public func genLoopInvariant(invariant: LoopInvariant): Tokens {
    // One check per condition: the doc requires checking `<expr>+` in order
    // and a per-condition message pinpoints the failing condition.
    let checks = Tokens()
    for (definition in invariant.definitions) {
        // Fallback `true` degrades the invariant to a check that never fires.
        let condition = unwrapOrReport(definition.parsed, definition.tokens,
            "loop invariant expression", parseExpr(quote(true)))
        let message = "loop invariant failed: " + escapeInterpolationText(definition.tokens.toString())
        checks.append(quote(
            if (!($(condition))) { throw ContractCheckLoopInvariantException(message: $(message)) }))
    }
    let loopChecks = emitContractBlock(
        genEvaluation(checks))

    // Clone the loop so generating it does not add checks to the parsed input.
    // The placeholder fallback reaches the `case _` branch below, which reports
    // the dedicated diagnostic instead of crashing the macro.
    let loop = parseExpr(unwrapOrReport(invariant.loop.parsed, invariant.tokens,
        "loop expression after `in`", parseExpr(quote(true))).toTokens())
    match (loop) {
        case expression: WhileExpr =>
            // Check at the start of every iteration and once when the loop exits,
            // so the check also runs when the loop body never executes.
            expression.block.nodes.add(parseExpr(loopChecks), at: 0)
            quote($(loop); $(loopChecks))
        case expression: ForInExpr =>
            // Check at the start of every iteration only. The loop variable is out of
            // scope after the loop, so no trailing check is emitted.
            expression.block.nodes.add(parseExpr(loopChecks), at: 0)
            loop.toTokens()
        case expression: DoWhileExpr =>
            // Check after each body execution and before the condition is evaluated: the
            // checks are appended to the end of the body block and every `continue` is
            // rewritten to run them first; the do-while shape preserves the original scoping.
            let condition = trimNewLine(expression.condition.toTokens())
            let rewritten = rewriteLoopContinues(
                loopBodyTokens(expression.block), loopChecks)
            quote(do {
                $(rewritten)
                $(loopChecks)
            } while ($(condition)))
        case _ =>
            // A non-loop shape here means the `in` clause of `loopInvariant` parsed into
            // something unexpected; report it instead of raising an unreadable macro crash.
            diagReport(DiagReportLevel.ERROR, invariant.tokens,
                "loopInvariant requires a loop expression after `in`",
                "write a while/for/do-while loop in the `in` clause")
            loop.toTokens()
    }
}

/// The inner tokens of a loop body block: outer braces stripped when present,
/// surrounding separators trimmed.
func loopBodyTokens(block: Block): Tokens {
    let raw = trimNewLine(block.toTokens())
    if (raw.size >= 2 && raw[0].kind == LCURL && raw[raw.size - 1].kind == RCURL) {
        return trimNewLine(raw[1..raw.size - 1])
    }
    raw
}

/// Loop-tracking state shared while rewriting `continue` targets.
class LoopContinueScan {
    // Per open brace: true marks a loop body, and among those, the second value
    // records whether it belongs to a `do`, whose `}` is followed by a `while`
    // trailer that must not open a new loop.
    let braces = ArrayList<(Bool, Bool)>()
    var loopDepth: Int64 = 0
    var parenDepth: Int64 = 0
    var pendingKeyword = false
    var pendingWhere = false
    var pendingIsDo = false
    var expectTrailerWhile = false
}

/// Rewrite every `continue` targeting the enclosing loop (no nested loop open) to run
/// the invariant checks first; a `continue` inside a nested loop is untouched. Loop
/// bodies are tracked brace-wise, including the `while` trailer of nested do-whiles.
func rewriteLoopContinues(body: Tokens, checks: Tokens): Tokens {
    let output = Tokens()
    let state = LoopContinueScan()
    var index = 0
    while (index < body.size) {
        if (consumeLoopTrailer(body, index, state, output)) {
            index += 1
            continue
        }
        if (consumeLoopKeyword(body, index, state, output)) {
            index += 1
            continue
        }
        if (state.pendingKeyword) {
            consumeLoopHeader(body, index, state, output)
            index += 1
            continue
        }
        trackLoopBrace(body[index].kind, state)
        if (body[index].kind == TokenKind.CONTINUE && state.loopDepth == 0) {
            output.append(quote(
                $(checks)
                continue))
            index += 1
            continue
        }
        output.append(body[index])
        index += 1
    }
    output
}

/// Append the `while` trailer that follows a nested `do` body without opening a new loop.
func consumeLoopTrailer(body: Tokens, index: Int64, state: LoopContinueScan, output: Tokens): Bool {
    if (!state.expectTrailerWhile) {
        return false
    }
    let kind = body[index].kind
    if (kind == NL) {
        output.append(body[index])
        return true
    }
    state.expectTrailerWhile = false
    if (kind == TokenKind.WHILE) {
        output.append(body[index])
        return true
    }
    false
}

/// Append a loop keyword and start waiting for its body brace.
func consumeLoopKeyword(body: Tokens, index: Int64, state: LoopContinueScan, output: Tokens): Bool {
    let kind = body[index].kind
    if (kind == TokenKind.WHILE || kind == TokenKind.FOR || kind == TokenKind.DO) {
        state.pendingKeyword = true
        state.pendingIsDo = kind == TokenKind.DO
        output.append(body[index])
        return true
    }
    false
}

/// Consume one token of a loop header until its body brace opens the loop body.
func consumeLoopHeader(body: Tokens, index: Int64, state: LoopContinueScan, output: Tokens): Unit {
    let token = body[index]
    let kind = token.kind
    if (kind == LPAREN) {
        state.parenDepth += 1
    } else if (kind == RPAREN) {
        state.parenDepth -= 1
    } else if (kind == LCURL && state.parenDepth == 0) {
        state.pendingKeyword = false
        state.pendingWhere = false
        state.braces.add((true, state.pendingIsDo))
        state.loopDepth += 1
    } else if ((kind == NL || kind == SEMI) && state.parenDepth == 0) {
        // Layout between the header and the body brace (`for (x in xs)` with the
        // `{` on the next line): keep waiting instead of dropping the keyword, or
        // a nested loop's `continue`s would later be misattributed to it.
    } else if (state.parenDepth == 0 && (isValue(token, "where") || state.pendingWhere)) {
        // `for (x in xs) where cond { ... }`: the header continues past the
        // parentheses, so keep waiting for the body brace. Clearing the keyword
        // here would leave the body untracked and misattribute a nested loop's
        // `continue`s (running the enclosing invariant checks at the wrong point).
        state.pendingWhere = true
    } else if (state.parenDepth == 0) {
        // Any other token before a brace: the keyword opened no loop body.
        state.pendingKeyword = false
        state.pendingWhere = false
    }
    output.append(token)
}

/// Track one non-header brace and close loop bodies (and their do-while trailer) when it
/// is a closing brace.
func trackLoopBrace(kind: TokenKind, state: LoopContinueScan): Unit {
    if (kind == LCURL) {
        state.braces.add((false, false))
    } else if (kind == RCURL) {
        if (state.braces.size > 0) {
            let entry = state.braces[state.braces.size - 1]
            state.braces.remove(state.braces.size - 1..state.braces.size)
            if (entry[0]) {
                state.loopDepth -= 1
                if (entry[1]) {
                    state.expectTrailerWhile = true
                }
            }
        }
    }
}
