/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.generate

import stdx.contract.macros.syntax.{AssertBlock, GhostBlock, LoopInvariant}
import stdx.contract.macros.tokens.trimNewLine
import std.ast.{Block, DiagReportLevel, DoWhileExpr, ForInExpr, ToTokens, Token, TokenKind, Tokens, WhileExpr, diagReport, parseExpr}

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
 * iteration, and do-while loops after each body execution and before the
 * condition, for `continue` exits only once the `finally` blocks they leave have
 * run. A non-loop `in` expression is reported as an error.
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
            // Check after each body execution and before the condition is evaluated,
            // including when the body leaves through `continue`. A `continue` runs the
            // `finally` blocks it leaves first, and those may update the state the
            // invariant observes, so the check must follow them: a check appended to the
            // body or inserted at the `continue` site would run too early and read stale
            // state. Rewrite the loop as `while (true)` whose top runs the checks and
            // then the original condition before the body; `break`/`return`/`throw` still
            // leave without a check. The one-iteration outer `do-while` keeps the helper
            // flag scoped to this expansion. The body statements are spliced directly into
            // the loop block with explicit separators: a bare `{ ... }` here would parse as
            // a lambda literal, and a nested loop would capture the body's `break`/`continue`.
            let condition = trimNewLine(expression.condition.toTokens())
            let body = loopBodyTokens(expression.block)
            let bodyStatements = Tokens()
            bodyStatements.append(Token(TokenKind.NL)).append(body).append(Token(TokenKind.NL))
            // The flag is a plain local binding: a user identifier with the same name in an
            // enclosing block or declared as a member would be shadowed inside the loop,
            // silently rebinding the condition, body, or invariant expressions. The name is
            // reserved, so reject it instead of accepting a different meaning.
            reportReservedIdentifier(loop.toTokens(), "_contract_do_while_first_iteration")
            for (definition in invariant.definitions) {
                reportReservedIdentifier(definition.tokens, "_contract_do_while_first_iteration")
            }
            quote(do {
                var _contract_do_while_first_iteration = true
                while (true) {
                    if (_contract_do_while_first_iteration) {
                        _contract_do_while_first_iteration = false
                    } else {
                        $(loopChecks)
                        if (!($(condition))) { break }
                    }
                    $(bodyStatements)
                }
            } while (false))
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

/// Reject a reserved generated identifier in user-written tokens. The expansion introduces a
/// local binding with that name, so any reference here would change meaning silently.
func reportReservedIdentifier(tokens: Tokens, name: String): Unit {
    for (token in tokens) {
        if (token.kind == TokenKind.IDENTIFIER && token.value == name) {
            diagReport(DiagReportLevel.ERROR, Tokens(token),
                "`" + name + "` is reserved for generated code", "loopInvariant")
        }
    }
}
