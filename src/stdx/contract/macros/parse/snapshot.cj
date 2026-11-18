/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.parse

import stdx.contract.macros.tokens.{TokenCursor, skipNewLine, trimSeparators}
import stdx.contract.macros.syntax.{ExprSyntax}
import std.ast.{ParseASTException, Token, Tokens, parseExprFragment}
import std.collection.{ArrayList, step}

class SnapshotParser {
    let parseTokens = Tokens()
    let pre = ArrayList<(Int64, ExprSyntax)>()

    private let cursor: TokenCursor
    private let state: ParseState

    init(tokens: Tokens, state: ParseState) {
        this.cursor = TokenCursor(tokens)
        this.state = state
    }

    func parse(): ?Tokens {
        while (!cursor.atEnd()) {
            if (let Some(open) <- findOpen()) {
                if (let Some(argument) <- parseSnapshot(open)) {
                    let index = parseTokens.size
                    pre.add((index, argument))
                    parseTokens.append(Token(IDENTIFIER, "_pre_" + index.toString()))
                } else {
                    return None
                }
            } else {
                parseTokens.append(cursor.current())
                cursor.step()
            }
        }
        Some(parseTokens)
    }

    /// Parse one `$pre(...)` snapshot at the cursor.
    ///
    /// @throws ParseASTException When the closing `)` is missing; the caller reports it
    /// as a parse error.
    private func parseSnapshot(open: Int64): ?ExprSyntax {
        let start = cursor.pos
        try {
            let argStart = skipNewLine(cursor.tokens, open + 1)
            // `$pre` expressions cannot be nested. Report it here instead of letting
            // `parseExprFragment` fail with a generic parse error.
            for (index in argStart..matchingClose(open)) {
                let token = cursor.tokens[index]
                if (token.kind == DOLLAR_IDENTIFIER && token.value == "$pre") {
                    state.reportError("`$pre` cannot be nested", "ContractClause", Tokens(token))
                    return None
                }
            }
            let (expr, next) = parseExprFragment(cursor.tokens, startFrom: argStart)
            let inner = trimSeparators(cursor.tokens[argStart..next])
            // Locate the expression end before the separators consumed by the SDK.
            cursor.pos = skipNewLine(cursor.tokens, argStart + inner.size)
            if (!cursor.matches(RPAREN)) {
                throw ParseASTException("expected `)` after `$pre` argument")
            }
            cursor.step()
            return ExprSyntax(inner, Some(expr))
        } catch (e: ParseASTException) {
            state.reportError("contract expression failed to parse: ${e.message}", "ContractClause",
                cursor.tokens[start..cursor.tokens.size])
        }
        None
    }

    private func findOpen(): ?Int64 {
        if (cursor.matches(DOLLAR_IDENTIFIER, value: "$pre") && cursor.matches(LPAREN, offset: 1)) {
            return Some(cursor.pos + 1)
        }
        None
    }

    /// Index of the token closing the group opened at `open`; the token count when unbalanced.
    private func matchingClose(open: Int64): Int64 {
        var depth = 0
        for (index in open..cursor.tokens.size) {
            let kind = cursor.tokens[index].kind
            if (kind == LPAREN || kind == LSQUARE || kind == LCURL) {
                depth += 1
            } else if (kind == RPAREN || kind == RSQUARE || kind == RCURL) {
                depth -= 1
                if (depth == 0) {
                    return index
                }
            }
        }
        cursor.tokens.size
    }
}
