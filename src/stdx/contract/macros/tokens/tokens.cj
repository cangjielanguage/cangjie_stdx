/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.tokens

import std.ast.{Token, TokenKind, Tokens, cangjieLex}
import std.collection.{ArrayList}
import std.core.{Exception, Iterable, StringBuilder}

/**
 * @brief Compares the token text with a name without restricting the token kind.
 *
 * Internal helper for macro expansion; not part of the public documentation API.
 *
 * @param token The token whose text is examined.
 * @param name The text to compare against.
 * @return `true` when the token text equals `name`, regardless of the token kind.
 */
public func isValue(token: Token, name: String): Bool {
    token.value == name
}

/**
 * @brief Checks whether the token text belongs to the supplied names.
 *
 * Internal helper for macro expansion; not part of the public documentation API.
 *
 * @param token The token whose text is examined.
 * @param names The candidate texts to match against.
 * @return `true` when the token text equals any entry of `names`.
 */
public func isElem(token: Token, names: Iterable<String>): Bool {
    for (name in names) {
        if (isValue(token, name)) {
            return true
        }
    }
    false
}

/**
 * @brief Concatenates the token text without separators; used for type identity keys.
 *
 * Internal helper for macro expansion; not part of the public documentation API.
 *
 * @param tokens The tokens whose text is concatenated.
 * @return The compact text of all tokens.
 */
public func tokenValuesCompactString(tokens: Tokens): String {
    let builder = StringBuilder()
    for (token in tokens) {
        builder.append(token.value)
    }
    builder.toString()
}

/**
 * @brief Builds a stable key for matching a declaration across nested macro expansions.
 *
 * Every token contributes its text length and text, so the key survives re-lexing even
 * when token boundaries differ between expansions.
 *
 * Internal helper for macro expansion; not part of the public documentation API.
 *
 * @param tokens The tokens to encode.
 * @return The stable key of the token stream.
 */
public func tokensStableKey(tokens: Tokens): String {
    let builder = StringBuilder()
    for (token in tokens) {
        builder.append(token.value.size.toString())
        builder.append(":")
        builder.append(token.value)
        builder.append("|")
    }
    builder.toString()
}

/**
 * @brief Skips the separators between clauses or statements.
 *
 * Separators are line breaks and semicolons (see `isSeparator`).
 *
 * Internal helper for macro expansion; not part of the public documentation API.
 *
 * @param tokens The token stream to scan.
 * @param start The index to scan from.
 * @return The first index at or after `start` whose token is not a separator, or the
 * stream size when only separators remain.
 */
public func skipSeparators(tokens: Tokens, start: Int64): Int64 {
    var pos = start
    while (pos < tokens.size && isSeparator(tokens[pos])) {
        pos += 1
    }
    pos
}

/**
 * @brief Checks whether the token is a separator: a line break or a semicolon.
 *
 * Internal helper for macro expansion; not part of the public documentation API.
 *
 * @param token The token to test.
 * @return `true` when the token kind is `NL` or `SEMI`.
 */
public func isSeparator(token: Token): Bool {
    token.kind == NL || token.kind == SEMI
}

/**
 * @brief Tells whether the identifier at `index` is accessed through a qualifier (`a.x`).
 *
 * Scanning back over separators, the previous significant token must be a dot.
 *
 * Internal helper for macro expansion; not part of the public documentation API.
 *
 * @param tokens The token stream to scan.
 * @param index The index of the identifier.
 * @return `true` when the identifier is accessed through a qualifier.
 */
public func precededByDot(tokens: Tokens, index: Int64): Bool {
    var cursor = index - 1
    while (cursor >= 0) {
        let token = tokens[cursor]
        if (isSeparator(token)) {
            cursor -= 1
            continue
        }
        return token.kind == DOT
    }
    false
}

/**
 * @brief Tells whether the identifier at `index` sits in a type-annotation position
 * (`let c: Count`).
 *
 * Scanning back over separators, the previous significant token is a colon. Cangjie has
 * no ternary operator, so outside of named-argument labels (already excluded separately)
 * an identifier after a colon names a type and must never be rewritten. A named-argument
 * value (`f(label: arg)`) is a value despite the colon: exempt it with
 * `followsNamedArgumentLabel`.
 *
 * Internal helper for macro expansion; not part of the public documentation API.
 *
 * @param tokens The token stream to scan.
 * @param index The index of the identifier.
 * @return `true` when the identifier sits in a type-annotation position.
 */
public func precededByColon(tokens: Tokens, index: Int64): Bool {
    var cursor = index - 1
    while (cursor >= 0) {
        let token = tokens[cursor]
        if (isSeparator(token)) {
            cursor -= 1
            continue
        }
        return token.kind == COLON
    }
    false
}

/**
 * @brief Tells whether the token at `index` is a named-argument label.
 *
 * A named argument label sits in argument position: its text is preceded by `(` or `,`
 * and followed by `:`. A ternary's true branch (`cond ? value : other`) is not preceded
 * by either, so it keeps being rewritten.
 *
 * Internal helper for macro expansion; not part of the public documentation API.
 *
 * @param tokens The token stream to scan.
 * @param index The index of the candidate label.
 * @return `true` when the token at `index` is a named-argument label.
 */
public func isNamedArgumentLabel(tokens: Tokens, index: Int64): Bool {
    var previous = index - 1
    while (previous >= 0 && isSeparator(tokens[previous])) {
        previous -= 1
    }
    if (previous < 0) {
        return false
    }
    let before = tokens[previous].kind
    if (before != LPAREN && before != COMMA) {
        return false
    }
    var cursor = index + 1
    while (cursor < tokens.size && isSeparator(tokens[cursor])) {
        cursor += 1
    }
    cursor < tokens.size && tokens[cursor].kind == COLON
}

/**
 * @brief Tells whether the colon right before `index` is a named-argument label's colon.
 *
 * In `f(label: arg)` the identifier before that colon is itself an argument label
 * (preceded by `(` or `,`), so what follows the colon is a value, not a type. Such an
 * identifier must not be treated as a type position by `precededByColon`.
 *
 * Internal helper for macro expansion; not part of the public documentation API.
 *
 * @param tokens The token stream to scan.
 * @param index The index of the token that follows the colon.
 * @return `true` when the token at `index` follows a named-argument label's colon.
 */
public func followsNamedArgumentLabel(tokens: Tokens, index: Int64): Bool {
    var cursor = index - 1
    while (cursor >= 0 && isSeparator(tokens[cursor])) {
        cursor -= 1
    }
    if (cursor < 0 || tokens[cursor].kind != COLON) {
        return false
    }
    var label = cursor - 1
    while (label >= 0 && isSeparator(tokens[label])) {
        label -= 1
    }
    if (label < 0 || tokens[label].kind != IDENTIFIER) {
        return false
    }
    var before = label - 1
    while (before >= 0 && isSeparator(tokens[before])) {
        before -= 1
    }
    before >= 0 && (tokens[before].kind == LPAREN || tokens[before].kind == COMMA)
}

/**
 * @brief Removes the leading and trailing separators from the token stream.
 *
 * Internal helper for macro expansion; not part of the public documentation API.
 *
 * @param tokens The token stream to trim.
 * @return The sub-slice between the first and the last non-separator tokens.
 */
public func trimSeparators(tokens: Tokens): Tokens {
    let start = skipSeparators(tokens, 0)
    var end = tokens.size
    while (end > start && isSeparator(tokens[end - 1])) {
        end -= 1
    }
    tokens[start..end]
}

/**
 * @brief Skips line breaks within a clause, preserving semicolons for syntax checks.
 *
 * Internal helper for macro expansion; not part of the public documentation API.
 *
 * @param tokens The token stream to scan.
 * @param start The index to scan from.
 * @return The first index at or after `start` whose token is not a line break, or the
 * stream size when only line breaks remain.
 */
public func skipNewLine(tokens: Tokens, start: Int64): Int64 {
    var pos = start
    while (pos < tokens.size && tokens[pos].kind == NL) {
        pos += 1
    }
    pos
}

/**
 * @brief Removes the leading and trailing line breaks from the token stream.
 *
 * Internal helper for macro expansion; not part of the public documentation API.
 *
 * @param tokens The token stream to trim.
 * @return The sub-slice between the first and the last non-line-break tokens.
 */
public func trimNewLine(tokens: Tokens): Tokens {
    let start = skipNewLine(tokens, 0)
    var end = tokens.size
    while (end > start && tokens[end - 1].kind == NL) {
        end -= 1
    }
    tokens[start..end]
}

/// The kind of the next token after `index` with separators skipped, or `END`.
func nextSignificantKind(tokens: Tokens, index: Int64, end: Int64): TokenKind {
    var cursor = index + 1
    while (cursor < end && isSeparator(tokens[cursor])) {
        cursor += 1
    }
    if (cursor < end) {
        tokens[cursor].kind
    } else {
        TokenKind.END
    }
}

/// The kind of the token before `index` with separators skipped, or `END`.
func previousSignificantKind(tokens: Tokens, index: Int64, start: Int64): TokenKind {
    var cursor = index - 1
    while (cursor >= start && isSeparator(tokens[cursor])) {
        cursor -= 1
    }
    if (cursor >= start) {
        tokens[cursor].kind
    } else {
        TokenKind.END
    }
}

/// True when `tokens[index]` stands where a statement can begin: at the stream start,
/// after a separator that does not continue an expression, or right after a brace.
func isStatementStart(tokens: Tokens, index: Int64): Bool {
    if (index == 0) {
        return true
    }
    var cursor = index - 1
    while (cursor >= 0 && isSeparator(tokens[cursor])) {
        cursor -= 1
    }
    if (cursor < 0) {
        return true
    }
    let kind = tokens[cursor].kind
    return kind == LCURL || kind == RCURL || !continuesExpressionKind(kind)
}

/// Operators and punctuators after which an expression continues across a separator.
func continuesExpressionKind(kind: TokenKind): Bool {
    match (kind) {
        case ADD | SUB | MUL | DIV | MOD | EXP | LT | GT | LE | GE | EQUAL | NOTEQ | AND | OR |
            BITAND | BITOR | BITXOR | LSHIFT | RSHIFT | COMMA | DOT | QUEST | COLON |
            LPAREN | LSQUARE | ASSIGN => true
        case _ => false
    }
}

/// The index of the `)` closing the `(` at `open`, or -1 when the group stays open.
func matchingParenIndex(tokens: Tokens, open: Int64, end: Int64): Int64 {
    var depth: Int64 = 0
    var cursor = open
    while (cursor < end) {
        let kind = tokens[cursor].kind
        if (kind == LPAREN) {
            depth += 1
        } else if (kind == RPAREN) {
            depth -= 1
            if (depth == 0) {
                return cursor
            }
        }
        cursor += 1
    }
    -1
}

/// The span of the destructuring group after the declaration keyword at `keyword`, or
/// `(-1, -1)` when the declaration does not start with a parenthesized pattern.
func declarationDestructuringSpan(tokens: Tokens, keyword: Int64, end: Int64): (Int64, Int64) {
    let open = skipSeparators(tokens, keyword + 1)
    if (open < end && tokens[open].kind == LPAREN) {
        let close = matchingParenIndex(tokens, open, end)
        if (close >= 0) {
            return (open, close)
        }
    }
    (-1, -1)
}

/// The span of the `(a, b) = ...` target opened by the `(` at `open`, or `(-1, -1)` when
/// the group is not followed by an assignment.
func assignmentDestructuringSpan(tokens: Tokens, open: Int64, end: Int64): (Int64, Int64) {
    if (!isStatementStart(tokens, open)) {
        return (-1, -1)
    }
    let close = matchingParenIndex(tokens, open, end)
    if (close < 0) {
        return (-1, -1)
    }
    let after = skipSeparators(tokens, close + 1)
    if (after < end && tokens[after].kind == ASSIGN) {
        return (open, close)
    }
    (-1, -1)
}

/// The span of the destructuring group starting at `index`, or `(-1, -1)` when no group
/// starts there.
func destructuringSpanAt(tokens: Tokens, index: Int64, end: Int64): (Int64, Int64) {
    match (tokens[index].kind) {
        case LET | VAR | CONST => declarationDestructuringSpan(tokens, index, end)
        case LPAREN => assignmentDestructuringSpan(tokens, index, end)
        case _ => (-1, -1)
    }
}

/**
 * @brief Collects the inclusive token-index spans of the parenthesized destructuring
 * groups in `tokens[start..end]`.
 *
 * A destructuring group is the pattern of a `let`/`var`/`const` declaration
 * (`let (a, (b, _)) = ...`) or the target of a multiple assignment (`(a, b) = ...`,
 * recognized only when its `(` opens a statement and the matching `)` is directly
 * followed by `=`). Identifiers inside such a group bind fresh locals, so they are
 * declaration positions, never uses of an outer name. A tuple in ordinary expression
 * position (`f((a, b))`, `(a, b) == c`) gets no span and keeps being rewritten.
 * Wildcards (`_`, a dedicated token kind) and type-annotation tokens never bind.
 *
 * Internal helper for macro expansion; not part of the public documentation API.
 *
 * @param tokens The token stream to scan.
 * @param start The inclusive start of the scanned range.
 * @param end The exclusive end of the scanned range.
 * @return The inclusive index spans of the recognized destructuring groups.
 */
public func destructuringGroupSpans(tokens: Tokens, start: Int64, end: Int64): ArrayList<(Int64, Int64)> {
    let spans = ArrayList<(Int64, Int64)>()
    var index = start
    while (index < end) {
        let span = destructuringSpanAt(tokens, index, end)
        if (span[0] >= 0) {
            spans.add(span)
        }
        index += 1
    }
    spans
}

/**
 * @brief Tells whether `tokens[index]` lies inside a destructuring group (see
 * `destructuringGroupSpans`).
 *
 * Inside such a group the token keeps its spelled form.
 *
 * Internal helper for macro expansion; not part of the public documentation API.
 *
 * @param tokens The token stream to scan.
 * @param index The index to test.
 * @return `true` when the token at `index` lies inside a destructuring group.
 */
public func inDestructuringGroup(tokens: Tokens, index: Int64): Bool {
    for (span in destructuringGroupSpans(tokens, 0, tokens.size)) {
        if (index >= span[0] && index <= span[1]) {
            return true
        }
    }
    false
}

/**
 * @brief Collects the identifiers bound by lambda parameter lists, `match` case patterns
 * or `catch` bindings in `tokens[start..end]`, together with their token positions.
 *
 * Covered forms are lambda parameter lists (`{ x => ... }`), `match` case patterns
 * (`case Some(x) => ...`) and `catch` bindings (`catch (ex: Exception)`). Only
 * identifiers outside type position bind, and constructor names in payload position
 * (`Some(x)` binds `x`) are excluded.
 *
 * Internal helper for macro expansion; not part of the public documentation API.
 *
 * @param tokens The token stream to scan.
 * @param start The inclusive start of the scanned range.
 * @param end The exclusive end of the scanned range.
 * @return The index and the token of every collected binding identifier.
 */
public func lambdaAndCaseBindingSpans(tokens: Tokens, start: Int64, end: Int64): ArrayList<(Int64, Token)> {
    let found = ArrayList<(Int64, Token)>()
    var index = start
    while (index < end) {
        let token = tokens[index]
        if (token.kind == LCURL) {
            collectLambdaParameters(tokens, index, end, found)
        } else if (token.kind == CASE) {
            collectCaseBindings(tokens, index, end, found)
        } else if (token.kind == CATCH) {
            collectCatchBindings(tokens, index, end, found)
        }
        index += 1
    }
    found
}

/**
 * @brief Position-free view of `lambdaAndCaseBindingSpans`.
 *
 * Internal helper for macro expansion; not part of the public documentation API.
 *
 * @param tokens The token stream to scan.
 * @param start The inclusive start of the scanned range.
 * @param end The exclusive end of the scanned range.
 * @return The tokens of the binding identifiers, without their positions.
 */
public func lambdaAndCaseBindingTokens(tokens: Tokens, start: Int64, end: Int64): ArrayList<Token> {
    let found = ArrayList<Token>()
    for (span in lambdaAndCaseBindingSpans(tokens, start, end)) {
        found.add(span[1])
    }
    found
}

/// Collect the binding of one `catch (name: SomeType)` clause: the identifier directly
/// inside the parentheses that is followed by a colon. A catch body follows and keeps
/// being covered by the caller's ordinary scan of the token stream.
func collectCatchBindings(tokens: Tokens, catchPos: Int64, end: Int64, found: ArrayList<(Int64, Token)>): Unit {
    var cursor = catchPos + 1
    while (cursor < end && (tokens[cursor].kind == NL || tokens[cursor].kind == SEMI)) {
        cursor += 1
    }
    if (cursor >= end || tokens[cursor].kind != LPAREN) {
        return
    }
    cursor += 1
    while (cursor < end && (tokens[cursor].kind == NL || tokens[cursor].kind == SEMI)) {
        cursor += 1
    }
    if (cursor < end && tokens[cursor].kind == IDENTIFIER) {
        if (nextSignificantKind(tokens, cursor, end) == COLON) {
            found.add((cursor, tokens[cursor]))
        }
    }
}

/// Mutable state of the lambda parameter-list scan.
class LambdaParameterScan {
    var depth: Int64 = 0
    // Generic arguments in a parameter type (`HashMap<K, V>`) nest without parentheses,
    // so their comma must not be taken as a parameter separator. `>>` closes two levels
    // because the lexer folds nested closers into one shift token.
    var angleDepth: Int64 = 0
    var inType = false
    var afterComma = false
}

/// Scan the parameter list that starts right after the `{` at `open`. The scan stops at
/// the `=>` on success (emitting the bound identifiers) and at the first token that
/// cannot appear in a parameter list, so ordinary blocks and `match` bodies yield nothing.
func collectLambdaParameters(tokens: Tokens, open: Int64, end: Int64, found: ArrayList<(Int64, Token)>): Unit {
    var cursor = open + 1
    // The parameter list may start on the line after the brace.
    while (cursor < end && tokens[cursor].kind == NL) {
        cursor += 1
    }
    let candidates = ArrayList<(Int64, Token)>()
    let state = LambdaParameterScan()
    while (cursor < end) {
        let outcome = scanLambdaParameterToken(tokens, cursor, state, candidates)
        if (outcome < 0) {
            return
        }
        if (outcome > 0) {
            for (candidate in candidates) { found.add(candidate) }
            return
        }
        cursor += 1
    }
}

/// Classify one token of a lambda parameter list. Returns 1 when the `=>` was reached,
/// 0 to keep scanning and -1 when the token cannot appear in a parameter list.
func scanLambdaParameterToken(tokens: Tokens, cursor: Int64, state: LambdaParameterScan,
    candidates: ArrayList<(Int64, Token)>): Int64 {
    let current = tokens[cursor]
    match (current.kind) {
        case DOUBLE_ARROW => scanLambdaArrowToken(state)
        case LPAREN | LSQUARE | RPAREN | RSQUARE | LT | GT | RSHIFT =>
            scanLambdaBracketToken(current.kind, state)
        case _ => scanLambdaParameterValue(current, cursor, state, candidates)
    }
}

/// The `=>` terminates a parameter list only when no bracket or generic argument is
/// open; a nested arrow is ordinary type text.
func scanLambdaArrowToken(state: LambdaParameterScan): Int64 {
    if (state.depth == 0 && state.angleDepth == 0) {
        return 1
    }
    0
}

/// Track one bracket or generic argument token of a parameter list.
func scanLambdaBracketToken(kind: TokenKind, state: LambdaParameterScan): Int64 {
    match (kind) {
        case LPAREN | LSQUARE =>
            state.depth += 1
        case RPAREN | RSQUARE =>
            if (state.depth == 0) {
                return -1
            }
            state.depth -= 1
        case LT =>
            state.angleDepth += 1
        case GT =>
            if (state.angleDepth > 0) {
                state.angleDepth -= 1
            }
        case _ =>
            // `>>` is a single token closing two generic levels.
            if (state.angleDepth >= 2) {
                state.angleDepth -= 2
            } else {
                state.angleDepth = 0
            }
    }
    0
}

/// Track a token that is neither a bracket nor the `=>` of a parameter list.
func scanLambdaParameterValue(current: Token, cursor: Int64, state: LambdaParameterScan,
    candidates: ArrayList<(Int64, Token)>): Int64 {
    // Type text between brackets; the arrow can only terminate at depth 0.
    if (state.depth > 0 || state.angleDepth > 0) {
        return 0
    }
    match (current.kind) {
        case COMMA => scanLambdaCommaToken(state)
        case NL => scanLambdaNewlineToken(state)
        case COLON => scanLambdaColonToken(state)
        case IDENTIFIER => scanLambdaIdentifierToken(current, cursor, state, candidates)
        case MUT => scanLambdaMutToken(state)
        case _ => scanLambdaOtherToken(current.kind)
    }
}

/// Reset the type state at the `,` between parameters and remember the wrap position.
func scanLambdaCommaToken(state: LambdaParameterScan): Int64 {
    state.inType = false
    state.afterComma = true
    0
}

/// A wrapped parameter list continues only directly after a `,`.
func scanLambdaNewlineToken(state: LambdaParameterScan): Int64 {
    if (!state.afterComma) {
        return -1
    }
    state.afterComma = false
    0
}

/// Enter type position at the `:` of a parameter annotation.
func scanLambdaColonToken(state: LambdaParameterScan): Int64 {
    state.inType = true
    0
}

/// Collect a parameter name; identifiers in type position do not bind.
func scanLambdaIdentifierToken(current: Token, cursor: Int64, state: LambdaParameterScan,
    candidates: ArrayList<(Int64, Token)>): Int64 {
    if (!state.inType) {
        candidates.add((cursor, current))
    }
    0
}

/// Leave type position at `mut`, whose following name is the parameter binding.
func scanLambdaMutToken(state: LambdaParameterScan): Int64 {
    state.inType = false
    0
}

/// Type-level tokens; position inside the list is unchanged. Anything else ends the scan.
func scanLambdaOtherToken(kind: TokenKind): Int64 {
    match (kind) {
        case DOT | QUEST | LSHIFT | ARROW | BITAND => 0
        case _ =>
            if (isBuiltinTypeKind(kind)) {
                0
            } else {
                -1
            }
    }
}

/// Scan one `match` case pattern from the `case` at `casePos` up to its `=>`, emitting
/// the identifiers the pattern binds. Every depth-0 identifier in an or-pattern binds
/// (`case a | b =>`), while constructor names stay excluded: a bare identifier followed
/// by `(` is a constructor with a payload, a segment after `.` or before `.` belongs to
/// a qualified constructor path. An unqualified bare constructor (`case Red =>`) is
/// indistinguishable from a binding at token level and stays collected (over-reporting
/// is the safe direction; see the documented macro limitations).
func collectCaseBindings(tokens: Tokens, casePos: Int64, end: Int64, found: ArrayList<(Int64, Token)>): Unit {
    let candidates = ArrayList<(Int64, Token)>()
    var cursor = casePos + 1
    var depth: Int64 = 0
    while (cursor < end) {
        let current = tokens[cursor]
        let kind = current.kind
        if (depth == 0 && kind == DOUBLE_ARROW) {
            for (candidate in candidates) { found.add(candidate) }
            return
        }
        if (depth == 0 && kind == NL) {
            return
        }
        if (kind == LPAREN || kind == LSQUARE) {
            depth += 1
        } else if (kind == RPAREN || kind == RSQUARE) {
            if (depth == 0) {
                return
            }
            depth -= 1
        } else if (kind == LCURL || kind == RCURL || kind == SEMI) {
            return
        } else if (kind == IDENTIFIER) {
            let previous = previousSignificantKind(tokens, cursor, casePos + 1)
            let next = nextSignificantKind(tokens, cursor, end)
            if (depth > 0) {
                // A payload, tuple, or or-pattern binding follows `(`, `,` or `|`; a
                // constructor name inside the pattern is itself followed by `(`.
                if ((previous == LPAREN || previous == COMMA || previous == BITOR) && next != LPAREN) {
                    candidates.add((cursor, current))
                }
            } else if (previous != DOT && next != LPAREN && next != DOT) {
                // A leading or or-pattern identifier binds; a qualified path segment
                // (`Color.Red`) is excluded on either side of the dot.
                candidates.add((cursor, current))
            }
        }
        cursor += 1
    }
}

/// Built-in type keywords carry dedicated token kinds, so a lambda parameter type such
/// as `Int64` is not an `IDENTIFIER`.
func isBuiltinTypeKind(kind: TokenKind): Bool {
    match (kind) {
        case INT8 | INT16 | INT32 | INT64 | INTNATIVE | UINT8 | UINT16 | UINT32 | UINT64 |
             UINTNATIVE | FLOAT16 | FLOAT32 | FLOAT64 | RUNE | BOOLEAN | NOTHING | UNIT |
             VARRAY | THISTYPE => true
        case _ => false
    }
}

/**
 * @brief Rewrites the interpolated expressions inside one string-literal token.
 *
 * A string literal reaches rewriters as a single token, so identifiers inside `${...}`
 * are otherwise invisible to them: the rewrite would silently miss them (or, worse, a
 * same-named outer-scope name would be read instead of the intended one). Every
 * `${...}` segment (brace depth tracked) is re-lexed and passed through `rewriteInner`;
 * the surrounding text is kept byte for byte. Raw strings (`#"..."#`) and literals
 * without interpolation are returned unchanged.
 *
 * Internal helper for macro expansion; not part of the public documentation API.
 *
 * @param token The string-literal token to rewrite.
 * @param rewriteInner The transformation applied to every re-lexed `${...}` segment.
 * @return The rewritten token, or the original token when nothing changed.
 */
public func rewriteStringInterpolation(token: Token, rewriteInner: (Tokens) -> Tokens): Token {
    if (token.kind != STRING_LITERAL || token.value.size < 4 || token.value.startsWith("#")) {
        return token
    }
    let text = token.value
    let builder = StringBuilder()
    var index = 0
    var changed = false
    while (index < text.size) {
        let byte = text[index]
        // `\${` escapes the interpolation marker; copy the escape verbatim. The escaped
        // character may be multi-byte, so it is copied whole instead of two bytes.
        if (byte == 92 && index + 1 < text.size) {
            index = appendEscapedChar(builder, text, index)
            continue
        }
        if (byte == 36 && index + 1 < text.size && text[index + 1] == 123) {
            let (innerStart, close) = interpolationSpan(text, index + 2)
            if (close < 0) {
                builder.append("$")
                index += 1
                continue
            }
            let segment = text[innerStart..close]
            let rewritten = rewriteInterpolatedSegment(segment, rewriteInner)
            // `"$"` and `"{"` are appended separately: a literal `"${"` in this source
            // file would itself start an interpolation that swallows following code.
            builder.append("$")
            builder.append("{")
            builder.append(rewritten)
            builder.append("}")
            changed = changed || rewritten != segment
            index = close + 1
            continue
        }
        index = appendLiteralRun(builder, text, index)
    }
    if (!changed) {
        return token
    }
    Token(STRING_LITERAL, builder.toString())
}

/**
 * @brief Copies the literal run starting at `index` up to the next structural ASCII byte
 * (`\` or `$`) and returns the first index not copied.
 *
 * Both structural bytes are ASCII, so the `String` slice always ends on a UTF-8 character
 * boundary; copying a single byte of a multi-byte character would make the range index
 * throw `IllegalArgumentException`.
 *
 * Internal helper for macro expansion; not part of the public documentation API.
 *
 * @param builder The builder receiving the copied text.
 * @param text The string-literal source text.
 * @param index The byte index where copying starts; must be a character boundary.
 * @return The byte index of the next structural byte, or `text.size`.
 */
public func appendLiteralRun(builder: StringBuilder, text: String, index: Int64): Int64 {
    var end = index + 1
    while (end < text.size && text[end] != 92 && text[end] != 36) {
        end += 1
    }
    builder.append(text[index..end])
    end
}

/// Copy the escape sequence at `index` (a leading backslash plus the escaped character,
/// which may be multi-byte) and return the first index not copied.
func appendEscapedChar(builder: StringBuilder, text: String, index: Int64): Int64 {
    var end = index + 1
    if (end < text.size) {
        end += utf8CharLength(text[end])
    }
    if (end > text.size) {
        end = text.size
    }
    builder.append(text[index..end])
    end
}

/// Byte length of the UTF-8 character whose leading byte is `lead`.
func utf8CharLength(lead: UInt8): Int64 {
    if (lead >= 0xF0u8) {
        4
    } else if (lead >= 0xE0u8) {
        3
    } else if (lead >= 0xC0u8) {
        2
    } else {
        1
    }
}

/// Scan from `start` for the `}` closing a `${` segment: `{` opens and `}` closes a level,
/// so nested braced expressions stay inside the segment. Returns the segment start and the
/// closing index (-1 when unterminated).
func interpolationSpan(text: String, start: Int64): (Int64, Int64) {
    var cursor = start
    var depth: Int64 = 1
    while (cursor < text.size) {
        let byte = text[cursor]
        if (byte == 123) {
            depth += 1
        } else if (byte == 125) {
            depth -= 1
            if (depth == 0) {
                return (start, cursor)
            }
        }
        cursor += 1
    }
    (start, -1)
}

/// Lex one `${...}` segment and apply `rewriteInner` to it. A segment that fails to lex
/// (it may hold syntax the lexer rejects out of context) keeps its original text.
func rewriteInterpolatedSegment(segment: String, rewriteInner: (Tokens) -> Tokens): String {
    let inner = try {
        cangjieLex(segment, true)
    } catch (_: Exception) {
        return segment
    }
    if (inner.size == 0) {
        return segment
    }
    let rewritten = rewriteInner(inner)
    let text = rewritten.toString()
    if (trimSeparators(rewritten).size == 0) {
        return segment
    }
    text
}
