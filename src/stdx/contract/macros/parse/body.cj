/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.parse

import stdx.contract.macros.syntax.{AssertBlock, ExprSyntax, GhostBlock, LoopInvariant}
import stdx.contract.macros.tokens.{skipSeparators}
import std.ast.{DoWhileExpr, ForInExpr, Tokens, WhileExpr}
import std.collection.{ArrayList}

/**
 * @brief Wraps the tokens of a `@ghost` block into a `GhostBlock` without parsing them.
 *
 * The ghost body is preserved as written: no clause splitting or expression parsing
 * happens here and no diagnostics are produced; lowering of the block is performed by
 * the macro expansion step.
 *
 * @param tokens The ghost code carried in `@ghost(...)`.
 * @return The ghost block holding the tokens unchanged.
 */
public func parseContractGhost(tokens: Tokens): GhostBlock {
    GhostBlock(tokens)
}

/**
 * @brief Parses the assertion expressions of a `@contractAssert` block into an
 * `AssertBlock`.
 *
 * The tokens are read as a whitespace/`;`-separated expression list, and at least one
 * assertion expression is required. `$pre` snapshots are defined for contract clauses
 * only, so any `$pre` here is rejected with a dedicated diagnostic instead of the SDK's
 * generic parse failure.
 *
 * @param tokens The assertion expressions carried in `@contractAssert(...)`.
 * @return The parsed assertions with the diagnostics collected while parsing; the block
 * is empty when a `$pre` misuse is reported.
 */
public func parseContractAssert(tokens: Tokens): ParseResult<AssertBlock> {
    let state = ParseState(tokens)
    // `$pre` snapshots exist for contract clauses only; fail with the dedicated
    // diagnostic instead of the SDK's generic parse error.
    if (reportPrePhaseOutsideClauses(tokens, state, "contractAssert")) {
        return ParseResult(AssertBlock(ArrayList<ExprSyntax>(), tokens), state.diagnostics)
    }
    let conditions = readExprs(state, category: "contractAssert")
    if (conditions.isEmpty() && state.diagnostics.isEmpty()) {
        state.reportError("contractAssert needs at least one assertion expression", "contractAssert", tokens)
    }
    ParseResult(AssertBlock(conditions, tokens), state.diagnostics)
}

/**
 * @brief Parses the invariant expressions of a `@loopInvariant` macro together with the
 * annotated loop into a `LoopInvariant`.
 *
 * `invariants` is read as a whitespace/`;`-separated expression list and at least one
 * invariant expression is required; `input` must be a `for-in`, `while`, or `do-while`
 * expression, with a dedicated diagnostic when extra parentheses wrap the loop. `$pre`
 * snapshots are defined for contract clauses only, so any `$pre` here is rejected with
 * a dedicated diagnostic.
 *
 * @param invariants The invariant expressions carried in `[]`.
 * @param input The loop expression passed as the second argument in `()`.
 * @return The parsed invariants with the loop expression and the diagnostics collected
 * while parsing; the invariants are empty when a `$pre` misuse is reported.
 */
public func parseLoopInvariant(invariants: Tokens, input: Tokens): ParseResult<LoopInvariant> {
    let state = ParseState(invariants)
    // Same dedicated `$pre` diagnostic as `@contractAssert`.
    if (reportPrePhaseOutsideClauses(invariants, state, "loopInvariant")) {
        return ParseResult(LoopInvariant(ArrayList<ExprSyntax>(), ExprSyntax(input, None), invariants, input),
            state.diagnostics)
    }
    let invs = readExprs(state)
    if (invs.isEmpty() && state.diagnostics.isEmpty()) {
        state.reportError("loopInvariant needs at least one invariant expression", "loopInvariant", invariants)
    }

    let loopState = ParseState(input)
    let loop = readExpr(loopState)

    if (let Some(expr) <- loop.parsed) {
        if (!(expr is WhileExpr || expr is ForInExpr || expr is DoWhileExpr)) {
            let message = if (hasExtraLoopParens(input)) {
                "loopInvariant input must be a for, while, or do-while expression; remove the extra parentheses around the loop"
            } else {
                "loopInvariant input must be a for, while, or do-while expression"
            }
            loopState.reportError(message, "loopInvariant", input)
        }
    }
    state.diagnostics.add(all: loopState.diagnostics)
    ParseResult(LoopInvariant(invs, loop, invariants, input), state.diagnostics)
}

/// `((while ...))`: the caller's parentheses already delimit the loop argument, so a
/// remaining leading `(` means an extra pair wraps the whole loop expression.
func hasExtraLoopParens(tokens: Tokens): Bool {
    let pos = skipSeparators(tokens, 0)
    pos < tokens.size && tokens[pos].kind == LPAREN
}

/// `$pre` snapshots are defined only for the clauses of a callable contract; anywhere
/// else they must be rejected with this dedicated diagnostic rather than the SDK's
/// generic parse failure. Returns true when the diagnostic was reported.
func reportPrePhaseOutsideClauses(tokens: Tokens, state: ParseState, label: String): Bool {
    for (token in tokens) {
        if (token.kind == DOLLAR_IDENTIFIER && token.value == "$pre") {
            state.reportError("`$pre` is only available in contract clauses; it cannot be used in `${label}`",
                label, Tokens(token))
            return true
        }
    }
    false
}

/// `$pre` snapshots exist only for `ensures` clauses, written as the call `$pre(expr)`.
/// A `$pre` in any other clause (or in a variable initializer) is rejected outright; a
/// bare `$pre` without its argument list inside `ensures` is rejected as well. Both get
/// this dedicated diagnostic instead of the SDK's generic parse failure. `callFormOnly`
/// selects the `ensures` mode where only the missing-call shape is wrong. Returns true
/// when a diagnostic was reported.
private func reportMisplacedPre(tokens: Tokens, state: ParseState, category: String, callFormOnly: Bool): Bool {
    var index = 0
    while (index < tokens.size) {
        let token = tokens[index]
        if (token.kind == DOLLAR_IDENTIFIER && token.value == "$pre") {
            if (callFormOnly && index + 1 < tokens.size && tokens[index + 1].kind == LPAREN) {
                // A well-formed `$pre(expr)` call: keep scanning the rest.
                index += 1
                continue
            }
            let message = if (callFormOnly) {
                "`$pre` must be used as the snapshot call `$pre(expr)`"
            } else {
                "`$pre` is only available in `ensures` clauses; it cannot be used here"
            }
            state.reportError(message, category, Tokens(token))
            return true
        }
        index += 1
    }
    false
}

/// `reportMisplacedPre` over the clause text that the cursor has not consumed yet.
func reportMisplacedPreAhead(state: ParseState, category: String, callFormOnly: Bool): Bool {
    reportMisplacedPre(state.cursor.tokens[state.cursor.pos..state.cursor.tokens.size], state, category,
        callFormOnly)
}
