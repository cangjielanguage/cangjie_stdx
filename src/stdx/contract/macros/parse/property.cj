/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.parse

import stdx.contract.macros.tokens.{followsNamedArgumentLabel, inDestructuringGroup, isNamedArgumentLabel, precededByColon, precededByDot, rewriteStringInterpolation, trimSeparators}
import stdx.contract.macros.syntax.{Diagnostic, FunctionClause, PropClause, PropContract, PropKind}
import std.ast.{Token, Tokens}
import std.collection.{ArrayList, step}

/**
 * @brief Parses the `get`/`set` accessor clauses of a property contract into a
 * `PropContract`.
 *
 * Both the brace form (`get { requires ... }`) and the brace-less form (`get requires
 * ...`) are accepted, and each accessor may hold several callable clauses; an accessor
 * with no clauses is rejected. In setter clauses, bare `value` identifiers are
 * rewritten to `setterAlias` so the clauses reference the actual setter parameter name.
 *
 * @param tokens The contract clauses carried in `@Contract[...]`.
 * @param setterAlias The name of the setter parameter that `value` in setter clauses
 * refers to; defaults to `"value"`.
 * @return The parsed contract with the diagnostics collected while parsing the clauses.
 */
public func parsePropertyContract(tokens: Tokens, setterAlias!: String = "value"): ParseResult<PropContract> {
    let diagnostics = ArrayList<Diagnostic>()
    let contract = PropContract(tokens)
    let slices = splitContractClauses(tokens, grammar: ClauseGrammar.Property)
    for (slice in slices) {
        let state = ParseState(slice, diagnostics: diagnostics)
        state.cursor.skipClauseSeparators()
        if (let Some(clause) <- parsePropClause(state, setterAlias)) {
            contract.clauses.add(clause)
        }
    }
    ParseResult(contract, diagnostics)
}

func parsePropClause(state: ParseState, setterAlias: String): ?PropClause {
    let start = state.cursor.pos
    let kind = parsePropKind(state)
    if (kind.isNone()) {
        state.reportError("expected `get` or `set` accessor contract")
        return None
    }
    let propKind = kind.getOrThrow()
    state.cursor.skipClauseSeparators()
    let bodyTokens = match (readAccessorBody(state)) {
        case Some(value) => value
        case None => return None
    }
    // An accessor with no clauses (`@Contract[get]`) is rejected, like an empty function contract.
    if (trimSeparators(bodyTokens).size == 0) {
        let label = match (propKind) {
            case PropKind.Getter => "get"
            case PropKind.Setter => "set"
        }
        state.reportError("expected at least one contract clause after `${label}`")
        return None
    }
    let rewritten = match (propKind) {
        case PropKind.Setter => rewriteValueAlias(bodyTokens, setterAlias)
        case _ => bodyTokens
    }
    let clauses = ArrayList<FunctionClause>()
    for (slice in splitContractClauses(rewritten)) {
        let bodyState = ParseState(slice, diagnostics: state.diagnostics)
        bodyState.cursor.skipClauseSeparators()
        if (let Some(clause) <- parseFunctionClause(bodyState)) {
            clauses.add(clause)
            bodyState.cursor.skipClauseSeparators()
            if (!bodyState.cursor.atEnd()) {
                bodyState.reportError("unexpected tokens after property contract clause")
            }
        }
    }
    PropClause(propKind, clauses, state.cursor.tokens[start..state.cursor.pos])
}

/// Read the accessor body: an optional `{ ... }` block, or the remaining tokens.
func readAccessorBody(state: ParseState): ?Tokens {
    if (!state.cursor.matches(LCURL)) {
        return Some(state.cursor.takeRest())
    }
    state.cursor.step() // `{`
    let beginning = state.cursor.pos
    var depth: Int64 = 1
    while (!state.cursor.atEnd() && depth > 0) {
        let currentKind = state.cursor.current().kind
        if (currentKind == LCURL) {
            depth += 1
        } else if (currentKind == RCURL) {
            depth -= 1
            if (depth == 0) {
                break
            }
        }
        state.cursor.step()
    }
    if (depth > 0) {
        state.reportError("property accessor contract is missing a closing `}`")
        return None
    }
    let body = trimSeparators(state.cursor.tokens[beginning..state.cursor.pos])
    state.cursor.step() // `}`
    state.cursor.skipClauseSeparators()
    if (!state.cursor.atEnd()) {
        state.reportError("unexpected tokens after property accessor contract")
        return None
    }
    Some(body)
}

func parsePropKind(state: ParseState): ?PropKind {
    if (state.cursor.consumeValue("get")) {
        return PropKind.Getter
    }
    if (state.cursor.consumeValue("set")) {
        return PropKind.Setter
    }
    None
}

/// Rewrite bare `value` identifiers, leaving member accesses such as `obj.value`, named
/// argument labels such as `f(value: 1)`, and type positions (`let c: Value`) untouched.
/// A named-argument *value* (`f(x: value)`) is a real read despite the colon and keeps
/// being rewritten. String-literal interpolations are rewritten with the same rules so
/// `"v=${value}"` resolves against the real setter parameter.
func rewriteValueAlias(tokens: Tokens, alias: String): Tokens {
    if (alias == "value") {
        return tokens
    }
    let output = Tokens()
    for (index in 0..tokens.size) {
        let token = tokens[index]
        if (token.kind == STRING_LITERAL) {
            output.append(rewriteStringInterpolation(token, {inner => rewriteAliasIdTokens(inner, alias)}))
        } else if (token.kind == IDENTIFIER && token.value == "value" && !precededByDot(tokens, index) &&
            !precededByColon(tokens, index) && isNamedArgumentLabel(tokens, index)) {
            output.append(token)
        } else if (token.kind == IDENTIFIER && token.value == "value" && !precededByDot(tokens, index) &&
            (!precededByColon(tokens, index) || followsNamedArgumentLabel(tokens, index)) &&
            !inDestructuringGroup(tokens, index)) {
            // A destructuring binding (`let (value, y) = ...`) names a fresh local and
            // must keep its spelled form instead of becoming the setter parameter.
            output.append(Token(IDENTIFIER, alias))
        } else {
            output.append(token)
        }
    }
    output
}

/// The per-token alias rewrite applied to a re-lexed interpolation segment. Segment-local
/// scans cannot see outside the `${...}` span, which only ever holds a complete expression.
func rewriteAliasIdTokens(tokens: Tokens, alias: String): Tokens {
    let output = Tokens()
    for (index in 0..tokens.size) {
        let token = tokens[index]
        let previousIsDot = index > 0 && tokens[index - 1].kind == DOT
        if (token.kind == IDENTIFIER && token.value == "value" && !previousIsDot &&
            (!precededByColon(tokens, index) || followsNamedArgumentLabel(tokens, index))) {
            if (isNamedArgumentLabel(tokens, index)) {
                output.append(token)
            } else {
                output.append(Token(IDENTIFIER, alias))
            }
        } else {
            output.append(token)
        }
    }
    output
}

