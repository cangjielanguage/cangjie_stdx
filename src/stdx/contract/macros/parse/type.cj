/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.parse

import stdx.contract.macros.tokens.{skipNewLine, trimNewLine, trimSeparators}
import stdx.contract.macros.syntax.{Diagnostic, ExprSyntax, ExprWithPreSyntax, IdentifierSyntax, InvariantClause, InvariantVisibility, TypeClause, TypeContract, TypeInheritTarget, TypeInheritsClause, TypeSyntax, VariableClause}
import std.ast.{ParseASTException, TokenKind, Tokens, parseType, parseTypeFragment}
import std.collection.{ArrayList, map}

func parseClauseType(state: ParseState): ?TypeSyntax {
    let start = state.cursor.pos
    if (state.cursor.atEnd()) {
        state.reportError("contract clause needs a type")
        return None
    }
    try {
        let (ty, next) = parseTypeFragment(state.cursor.tokens, startFrom: start)
        state.cursor.pos = next
        let tokens = trimNewLine(state.cursor.tokens[start..next])
        state.cursor.skipNewLine()
        return TypeSyntax(tokens, Some(ty))
    } catch (e: ParseASTException) {
        state.reportError("contract type failed to parse: ${e.message}")
        None
    }
}

/**
 * @brief Parses the clauses of a class contract into a `TypeContract`.
 *
 * Accepts the type-level grammar: `invariant` clauses (with an optional `static`
 * modifier and `on_public`/`on_protected`/`on_private` visibility selectors),
 * `variable` clauses, and `inherits` clauses (`inherits from <type>` or
 * `inherits invariant <type>.<name>`). Diagnostics use the `class contract` category so
 * messages point at the annotated declaration kind.
 *
 * @param tokens The contract clauses carried in `@Contract[...]`.
 * @return The parsed contract with the diagnostics collected while parsing the clauses.
 */
public func parseClassContract(tokens: Tokens): ParseResult<TypeContract> {
    parseTypeContract(tokens, "class contract")
}

internal func parseStructContract(tokens: Tokens): ParseResult<TypeContract> {
    parseTypeContract(tokens, "struct contract")
}

internal func parseInterfaceContract(tokens: Tokens): ParseResult<TypeContract> {
    parseTypeContract(tokens, "interface contract")
}

internal func parseExtendContract(tokens: Tokens): ParseResult<TypeContract> {
    parseTypeContract(tokens, "extend contract")
}

func parseTypeContract(tokens: Tokens, category: String): ParseResult<TypeContract> {
    let diagnostics = ArrayList<Diagnostic>()
    let contract = TypeContract(tokens)
    let slices = splitContractClauses(tokens, grammar: ClauseGrammar.TypeLevel)
    for (slice in slices) {
        let state = ParseState(slice, diagnostics: diagnostics)
        state.cursor.skipClauseSeparators()
        if (let Some(clause) <- parseTypeClause(state, category)) {
            contract.clauses.add(clause)
        }
        finishClause(state)
    }
    ParseResult(contract, diagnostics)
}

func parseTypeClause(state: ParseState, category: String): ?TypeClause {
    let start = state.cursor.pos
    state.cursor.skipClauseSeparators()
    if (state.cursor.atEnd()) {
        return None
    }
    let visibility = parseOptionalVisibility(state)
    let isStatic = state.cursor.consumeValue("static")
    if (state.cursor.atEnd()) {
        state.reportError("expected `invariant` in type contract", category, state.cursor.tokens[start..state.cursor.pos])
        return None
    }
    match (state.cursor.current().value) {
        case "invariant" =>
            state.cursor.forward()
            let name = parseOptionalLabel(state, category)
            let condition = readInvariantExpr(state, category)
            TypeClause.Invariant(
                InvariantClause(isStatic, visibility, condition,
                    state.cursor.tokens[start..state.cursor.pos], name: name))
        case "variable" =>
            if (visibility.isSome()) {
                state.reportError("`variable` cannot have an invariant visibility selector", category,
                    state.cursor.tokens[start..state.cursor.pos + 1])
                return None
            }
            parseVariableClause(state, isStatic, start, category).map {clause => TypeClause.Variable(clause)}
        case "inherits" =>
            // Visibility selectors and `static` belong to `invariant`/`variable` clauses
            // only; consuming and dropping them here would silently hide the malformed
            // clause from the user.
            if (visibility.isSome() || isStatic) {
                state.reportError("`inherits` cannot have an invariant visibility selector or `static`", category,
                    state.cursor.tokens[start..state.cursor.pos + 1])
                return None
            }
            parseInheritsClause(state, start, category)
        case value =>
            state.reportError("expected a type contract clause, got ${value}", category,
                state.cursor.tokens[start..state.cursor.pos])
            None
    }
}

/// `inherits from <type>` or `inherits invariant <type>.<name>`.
func parseInheritsClause(state: ParseState, start: Int64, category: String): ?TypeClause {
    state.cursor.forward() // "inherits"
    state.cursor.skipClauseSeparators()
    if (state.cursor.atEnd()) {
        state.reportError("`inherits` clause needs `from` or `invariant`", category,
            state.cursor.tokens[start..state.cursor.pos])
        return None
    }
    match (state.cursor.current().value) {
        case "from" => parseTypeInherits(state, start, category).map {clause => TypeClause.Inherits(clause)}
        case "invariant" =>
            state.cursor.forward()
            match (parseInvariantInherit(state)) {
                case Some(target) => TypeClause.InvariantInherit(target)
                case None =>
                    state.reportError(
                        "`inherits invariant` needs `<type>.<name>` or `<new-name> = <type>.<name>`", category,
                        state.cursor.tokens[start..state.cursor.tokens.size])
                    None
            }
        case value =>
            state.reportError("`inherits` clause needs `from` or `invariant`, got ${value}", category,
                state.cursor.tokens[start..state.cursor.pos])
            None
    }
}

/// Parses the `from <type> ([conforming])?` part of `inherits from <type>`; the cursor is
/// already positioned at `from`.
func parseTypeInherits(state: ParseState, start: Int64, category: String): ?TypeInheritsClause {
    if (!state.cursor.consumeValue("from")) {
        state.reportError("`inherits` clause needs `from` before the parent type", category,
            state.cursor.tokens[start..state.cursor.pos])
        return None
    }
    let ty = match (parseClauseType(state)) {
        case Some(value) => value
        case None => return None
    }
    var conforming = false
    if (state.cursor.consumeKind(LSQUARE).isSome()) {
        if (!state.cursor.consumeValue("conforming") || state.cursor.consumeKind(RSQUARE).isNone()) {
            state.reportError("`inherits from` supports only the `[conforming]` modifier", category,
                state.cursor.tokens[start..state.cursor.pos])
            return None
        }
        conforming = true
    }
    TypeInheritsClause(TypeInheritTarget.ByType(ty), state.cursor.tokens[start..state.cursor.pos],
        isConforming: conforming)
}

/// `invariant` conditions have no snapshot semantics: `$pre` is only defined for
/// `ensures`. Reject it with a dedicated diagnostic instead of a raw parse failure.
func readInvariantExpr(state: ParseState, category: String): ExprWithPreSyntax {
    let tokens = state.cursor.takeRest()
    for (index in 0..tokens.size) {
        let token = tokens[index]
        if (token.kind == DOLLAR_IDENTIFIER && token.value == "$pre") {
            state.reportError(
                "`$pre` is not supported in `invariant` conditions; it is only available in `ensures`",
                category, Tokens(token))
            return ExprWithPreSyntax(tokens, None, tokens, ArrayList<(Int64, ExprSyntax)>())
        }
    }
    let parsed = parseCompleteExpr(tokens, tokens, state)
    ExprWithPreSyntax(tokens, parsed, tokens, ArrayList<(Int64, ExprSyntax)>())
}

/// `inherits invariant T.name` or `inherits invariant newName = T.name`.
func parseInvariantInherit(state: ParseState): ?TypeInheritTarget {
    state.cursor.skipClauseSeparators()
    let tokens = state.cursor.tokens
    let start = state.cursor.pos
    if (start + 1 < tokens.size && tokens[start].kind == IDENTIFIER && tokens[start + 1].kind == ASSIGN) {
        let cursor = state.cursor
        cursor.pos = start + 2
        if (let Some(target) <- parseMemberReference(state)) {
            let newName = IdentifierSyntax(tokens[start].value, Tokens(tokens[start]))
            return TypeInheritTarget.ByRename(target[0], newName, target[1])
        }
        cursor.pos = start
        return None
    }
    parseMemberReference(state).map {target => TypeInheritTarget.ByMember(target[0], target[1])}
}

/// Consume exactly `<type>.<name>` from the cursor; otherwise leave it unchanged.
/// The type part is shaped like a type (its outermost segment is a depth-0 identifier
/// made of type-legal characters, checked by `isTypeLikeTokens` plus `parseType`), so
/// plain member expressions keep their meaning. Lowercase type names are accepted.
func parseMemberReference(state: ParseState): ?(TypeSyntax, IdentifierSyntax) {
    let tokens = trimSeparators(state.cursor.tokens[state.cursor.pos..state.cursor.tokens.size])
    var depth: Int64 = 0
    var dot: Int64 = -1
    for (index in 0..tokens.size) {
        match (tokens[index].kind) {
            case LPAREN | LSQUARE | LCURL => depth += 1
            case RPAREN | RSQUARE | RCURL => depth -= 1
            case DOT => if (depth == 0) {dot = index}
            case _ => ()
        }
    }
    if (dot <= 0 || dot + 2 != tokens.size || tokens[dot + 1].kind != IDENTIFIER) {
        return None
    }
    let typeTokens = trimNewLine(tokens[0..dot])
    if (!isTypeLikeTokens(typeTokens)) {
        return None
    }
    let ty = try {
        TypeSyntax(typeTokens, Some(parseType(typeTokens)))
    } catch (e: ParseASTException) {
        return None
    }
    let nameToken = tokens[dot + 1]
    state.cursor.pos = state.cursor.tokens.size
    Some((ty, IdentifierSyntax(nameToken.value, Tokens(nameToken))))
}

/// Whether the tokens are shaped like a type: a depth-0 identifier names the outermost
/// segment. The case of the name does not matter — lowercase type names are legal — and
/// anything that is not actually a type fails the `parseType` call of the caller.
func isTypeLikeTokens(tokens: Tokens): Bool {
    var depth: Int64 = 0
    var last = false
    for (token in tokens) {
        match (token.kind) {
            case LPAREN | LSQUARE => depth += 1
            case RPAREN | RSQUARE => depth -= 1
            case IDENTIFIER => if (depth == 0) {last = true}
            case _ => ()
        }
    }
    last
}

func parseVariableClause(state: ParseState, isStatic: Bool, start: Int64, category: String): ?VariableClause {
    state.cursor.forward() // "variable"
    let name = parseIdentifier(state)
    if (name.isNone() || state.cursor.consumeKind(COLON).isNone()) {
        state.reportError("variable clause needs a name and `:` before its type", category,
            state.cursor.tokens[start..state.cursor.pos])
        return None
    }
    let ty = match (parseClauseType(state)) {
        case Some(value) => value
        case None => return None
    }
    let initExpr: ?ExprSyntax
    if (state.cursor.consumeKind(ASSIGN).isSome()) {
        initExpr = if (reportMisplacedPreAhead(state, category, false)) {
            None
        } else {
            Some(readExpr(state))
        }
    } else {
        initExpr = None
    }
    VariableClause(isStatic, name.getOrThrow(), ty, initExpr, state.cursor.tokens[start..state.cursor.pos])
}

func parseIdentifier(state: ParseState): ?IdentifierSyntax {
    state.cursor.skipClauseSeparators()
    if (let Some(token) <- state.cursor.consumeKind(IDENTIFIER)) {
        return IdentifierSyntax(token.value, Tokens(token))
    }
    None
}

func parseOptionalVisibility(state: ParseState): ?InvariantVisibility {
    state.cursor.skipClauseSeparators()
    if (state.cursor.atEnd()) {
        return None
    }
    match (state.cursor.current().value) {
        case "on_public" =>
            state.cursor.forward()
            InvariantVisibility.OnPublic
        case "on_protected" =>
            state.cursor.forward()
            InvariantVisibility.OnProtected
        case "on_private" =>
            state.cursor.forward()
            InvariantVisibility.OnPrivate
        case _ => None
    }
}

func parseOptionalLabel(state: ParseState, category: String): ?IdentifierSyntax {
    let cursor = state.cursor
    let start = cursor.pos
    cursor.skipClauseSeparators()
    if (let Some(tokens) <- cursor.consumeKinds([LSQUARE, IDENTIFIER, RSQUARE])) {
        let labelTokens = cursor.tokens[start..cursor.pos]
        cursor.skipClauseSeparators()
        if (cursor.atEnd()) {
            // Nothing follows the label; rolling back would surface only as a generalized
            // type error in the expansion, so report the missing condition here instead.
            state.reportError("contract clause label must be followed by a condition expression", category,
                labelTokens)
            cursor.pos = start
            return None
        }
        let next = cursor.current().kind
        // `[flag][0]` and `[flag].x` are expressions, not clause names; `[flag] (...)` is a
        // labeled clause with a parenthesized condition; a token that cannot begin an
        // expression (e.g. `[flag] == expected`) marks the bracket group as the condition head.
        if (next != LSQUARE && next != DOT && !cannotBeginCondition(next)) {
            let ident = tokens[1]
            return IdentifierSyntax(ident.value, Tokens(ident))
        }
    }
    cursor.pos = start
    None
}

/// Kinds that can never start a clause condition expression. When the token after
/// `[IDENT]` is one of these, the bracket group belongs to the condition (an array
/// literal compared with something, e.g. `[flag] == expected`), not a clause label.
func cannotBeginCondition(kind: TokenKind): Bool {
    match (kind) {
        case EQUAL | NOTEQ | LT | GT | LE | GE | AND | OR => true
        case ASSIGN | ADD_ASSIGN | SUB_ASSIGN | MUL_ASSIGN | DIV_ASSIGN | MOD_ASSIGN => true
        case RANGEOP | CLOSEDRANGEOP | COALESCING | PIPELINE | COMPOSITION => true
        case BITAND | BITOR | BITXOR | LSHIFT | RSHIFT | EXP | MUL | DIV | MOD => true
        case COMMA | COLON | SEMI | RPAREN | RSQUARE | RCURL | DOUBLE_ARROW | ARROW | QUEST => true
        case IS | AS | IN | NOT_IN | UPPERBOUND | WILDCARD => true
        case _ => false
    }
}

func finishClause(state: ParseState): Unit {
    state.cursor.skipClauseSeparators()
    if (!state.cursor.atEnd()) {
        state.reportError("unexpected token after contract clause", "type contract",
            state.cursor.tokens[state.cursor.pos..state.cursor.pos + 1])
    }
}
