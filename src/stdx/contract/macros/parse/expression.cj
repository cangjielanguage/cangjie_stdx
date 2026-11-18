/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.parse

import stdx.contract.macros.tokens.{isSeparator, skipSeparators, trimSeparators}
import stdx.contract.macros.syntax.{ExprSyntax, ExprWithPreSyntax}
import std.ast.{Expr, ParseASTException, Tokens, parseExprFragment}
import std.collection.{ArrayList, flatMap}

internal func readExpr(state: ParseState): ExprSyntax {
    let tokens = state.cursor.takeRest()
    let parsed = parseCompleteExpr(tokens, tokens, state)
    ExprSyntax(tokens, parsed)
}

/// Parse the whitespace/`;`-separated expression list of a block clause. `category`
/// names the reporting clause (`loopInvariant`, `contractAssert`) so diagnostics point
/// at the construct the user actually wrote.
///
/// @throws ParseASTException When a fragment is followed by a token that is neither a
/// separator nor a new expression; the caller reports it as a parse error.
internal func readExprs(state: ParseState, category!: String = "loopInvariant"): ArrayList<ExprSyntax> {
    let tokens = state.cursor.takeRest()
    let expressions = ArrayList<ExprSyntax>()
    var pos = skipSeparators(tokens, 0)
    try {
        while (pos < tokens.size) {
            let (expr, next) = parseExprFragment(tokens, startFrom: pos)
            let source = trimSeparators(tokens[pos..next])
            let end = pos + source.size
            // `(f)(x)` is a single call: the fragment parser consumes an adjacent
            // paren group as the argument list, so it must not be split into two
            // expressions here.
            if (end < tokens.size && !isSeparator(tokens[end])) {
                throw ParseASTException("expected a newline or `;` between contract expressions")
            }
            expressions.add(ExprSyntax(source, Some(expr)))
            pos = skipSeparators(tokens, end)
        }
    } catch (e: ParseASTException) {
        let rest = tokens[pos..tokens.size]
        if (isGroupedExpressionList(rest)) {
            state.reportError(
                "the outer parentheses are not supported; write each expression on its own line",
                category, rest)
        } else {
            state.reportError("contract expression failed to parse: ${e.message}", "Contract", rest)
        }
    }
    expressions
}

/// Detect an outer group wrapping several expressions, e.g. `(a; b)` or `(a\n b)`.
func isGroupedExpressionList(tokens: Tokens): Bool {
    let start = skipSeparators(tokens, 0)
    if (start >= tokens.size || tokens[start].kind != LPAREN) {
        return false
    }
    var depth = 0
    for (i in start..tokens.size) {
        let kind = tokens[i].kind
        if (kind == LPAREN || kind == LSQUARE || kind == LCURL) {
            depth += 1
        } else if (kind == RPAREN || kind == RSQUARE || kind == RCURL) {
            depth -= 1
            if (depth == 0) {
                return false
            }
        } else if (depth == 1 && isSeparator(tokens[i])) {
            return true
        }
    }
    false
}

/// Consume tokens as an expression with entry snapshots.
internal func readPreExpr(state: ParseState): ExprWithPreSyntax {
    let tokens = state.cursor.takeRest()
    let snapshots = SnapshotParser(tokens, state)
    let parsed = snapshots.parse().flatMap {input => parseCompleteExpr(input, tokens, state)}
    ExprWithPreSyntax(tokens, parsed, snapshots.parseTokens, snapshots.pre)
}

/// Record parsing errors against the original source and return None on failure.
func parseCompleteExpr(input: Tokens, source: Tokens, state: ParseState): ?Expr {
    try {
        return Some(parseExprTokens(input))
    } catch (e: ParseASTException) {
        state.reportError("contract expression failed to parse: ${e.message}", "ContractClause", source)
    }
    None
}

/// Parse a standalone expression, allowing surrounding statement separators only.
///
/// @throws ParseASTException When tokens remain after the parsed expression.
private func parseExprTokens(input: Tokens): Expr {
    let tokens = trimSeparators(input)
    let (expr, next) = parseExprFragment(tokens, startFrom: 0)
    if (skipSeparators(tokens, next) < tokens.size) {
        throw ParseASTException("unexpected tokens after contract expression")
    }
    expr
}
