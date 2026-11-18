/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.parse

import stdx.contract.macros.tokens.{isElem, isValue, trimSeparators}
import std.ast.{Token, Tokens}
import std.collection.{ArrayList, max}

internal enum ClauseGrammar {
    | Callable
    | Property
    | TypeLevel
}

internal func splitContractClauses(tokens: Tokens, grammar!: ClauseGrammar = ClauseGrammar.Callable): ArrayList<Tokens> {
    let clauses = ArrayList<Tokens>()
    var start: Int64 = 0
    var depth: Int64 = 0
    var lineStart = true

    for (i in 0..tokens.size) {
        let kind = tokens[i].kind
        if (depth == 0 && (kind == SEMI || (lineStart && startsClause(grammar, tokens[i])))) {
            let clause = trimSeparators(tokens[start..i])
            if (clause.size > 0) {
                clauses.add(clause)
            }
            start = if (kind == SEMI) { i + 1 } else { i }
        }
        match (kind) {
            case LPAREN | LSQUARE | LCURL => depth += 1
            case RPAREN | RSQUARE | RCURL => depth = max(0, depth - 1)
            case _ => ()
        }
        lineStart = kind == NL
    }
    let tail = trimSeparators(tokens[start..tokens.size])
    if (tail.size > 0) {
        clauses.add(tail)
    }
    clauses
}

func startsClause(grammar: ClauseGrammar, token: Token): Bool {
    match (grammar) {
        case ClauseGrammar.Callable => token.kind == IDENTIFIER && isClauseKeyword(token)
        case ClauseGrammar.Property => token.kind == IDENTIFIER && (isValue(token, "get") || isValue(token, "set"))
        case ClauseGrammar.TypeLevel =>
            isElem(token, ["invariant", "variable", "inherits", "static", "on_public", "on_protected", "on_private"])
    }
}

func isClauseKeyword(token: Token): Bool {
    token.kind == IDENTIFIER && (token.value == "requires" || token.value == "ensures" || token.value == "throws" ||
        token.value == "variable" || token.value == "inherits")
}
