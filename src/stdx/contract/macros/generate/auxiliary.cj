/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.generate

import stdx.contract.macros.syntax.{FunctionContract}
import stdx.contract.macros.tokens.followsNamedArgumentLabel
import stdx.contract.macros.tokens.inDestructuringGroup
import stdx.contract.macros.tokens.precededByColon
import stdx.contract.macros.tokens.precededByDot
import stdx.contract.macros.tokens.rewriteStringInterpolation
import std.ast.{Block, Decl, DiagReportLevel, FuncDecl, ParseASTException, ToTokens, Token, TokenKind, Tokens, diagReport, parseDecl}
import std.collection.{HashSet, contains, isEmpty}

/// Names of the function-level auxiliary variables declared by a callable contract.
///
/// A function-typed variable (`variable f: () -> Unit`) is additionally registered under
/// a non-identifier marker key so `f(...)` is rewritten into a slot read followed by the
/// call instead of being mistaken for a type constructor call.
func auxiliaryNames(contract: FunctionContract): HashSet<String> {
    let names = HashSet<String>()
    for (clause in contract.clauses) {
        if (let Variable(variable) <- clause) {
            names.add(variable.name.name)
            if (isFunctionType(variable.ty.tokens)) {
                names.add(callableAuxKey(variable.name.name))
            }
        }
    }
    names
}

/// Marker key for function-typed auxiliary variables; `(` cannot occur in an identifier,
/// so it never collides with a real variable name.
func callableAuxKey(name: String): String {
    "()" + name
}

func isFunctionType(tokens: Tokens): Bool {
    for (token in tokens) {
        if (token.kind == ARROW) {
            return true
        }
    }
    false
}

/// Storage identifier backing a function-level auxiliary variable.
func auxiliaryStorage(name: String): String {
    "_contract_aux_" + name
}

/// Rewrite reads and updates of auxiliary variables in `@ghost` statements.
/// The same rewrite is safe on plain expression token streams, where no update occurs.
func rewriteAux(tokens: Tokens, names: HashSet<String>): Tokens {
    if (names.isEmpty()) {
        return tokens
    }
    let output = Tokens()
    var index = 0
    while (index < tokens.size) {
        index = rewriteAuxAt(tokens, index, names, output)
    }
    output
}

/// Rewrite the token at `index` into `output` and return the next index to scan.
func rewriteAuxAt(tokens: Tokens, index: Int64, names: HashSet<String>, output: Tokens): Int64 {
    let token = tokens[index]
    // String interpolation is invisible at token level: rewrite the identifiers
    // inside every `${...}` segment with the same rules as the surrounding stream.
    if (token.kind == STRING_LITERAL) {
        output.append(rewriteStringInterpolation(token, {inner => rewriteAux(inner, names)}))
        return index + 1
    }
    // A destructuring pattern (`let (a, b) = ...`) or a multiple-assignment target
    // (`(a, b) = ...`) binds locals by name: those identifiers are declaration
    // positions and keep their spelled form instead of becoming slot reads.
    if (token.kind == IDENTIFIER && inDestructuringGroup(tokens, index)) {
        output.append(token)
        return index + 1
    }
    // Prefix increment/decrement: `++x` / `--x`.
    if ((token.kind == INCR || token.kind == DECR) && isPrefixAuxUpdate(tokens, index, names)) {
        if (!isStatementPosition(tokens, index)) {
            reportUpdateInValuePosition(token, tokens[index + 1].value, true)
        }
        emitAuxUpdate(output, tokens[index + 1].value, token.kind == INCR)
        return index + 2
    }
    if (isAuxIdentifier(token, names) && isAuxReadPosition(tokens, index, names)) {
        return rewriteAuxReference(tokens, index, names, output)
    }
    output.append(token)
    index + 1
}

/// Whether `++`/`--` at `index` prefixes an auxiliary variable reference.
func isPrefixAuxUpdate(tokens: Tokens, index: Int64, names: HashSet<String>): Bool {
    index + 1 < tokens.size && isAuxIdentifier(tokens[index + 1], names) &&
        !precededByDot(tokens, index + 1) &&
        !isCallOrLabelPosition(tokens, index + 1, callable: names.contains(callableAuxKey(tokens[index + 1].value)))
}

/// Whether the auxiliary identifier at `index` is a value read rather than a declaration,
/// member access or call/label position.
func isAuxReadPosition(tokens: Tokens, index: Int64, names: HashSet<String>): Bool {
    !precededByDot(tokens, index) &&
        (!precededByColon(tokens, index) || followsNamedArgumentLabel(tokens, index)) &&
        !precededByDeclKeyword(tokens, index) &&
        !isCallOrLabelPosition(tokens, index, callable: names.contains(callableAuxKey(tokens[index].value)))
}

/// Rewrite one auxiliary variable reference (assignment, compound update, increment or
/// plain read) and return the next index to scan.
func rewriteAuxReference(tokens: Tokens, index: Int64, names: HashSet<String>, output: Tokens): Int64 {
    let token = tokens[index]
    let next = if (index + 1 < tokens.size) { tokens[index + 1].kind } else { ILLEGAL }
    if (next == ASSIGN) {
        let (rhs, after) = statementExpression(tokens, index + 2)
        output.append(quote($(auxStorageToken(token.value)) = Some($(rewriteAux(rhs, names)))))
        return after
    }
    if (isCompoundAssign(next)) {
        let (rhs, after) = statementExpression(tokens, index + 2)
        let read = auxRead(token.value)
        let op = Token(compoundOperator(next))
        output.append(
            quote($(auxStorageToken(token.value)) = Some($(read) $(op) ($(rewriteAux(rhs, names))))))
        return after
    }
    if (next == INCR || next == DECR) {
        if (!isStatementPosition(tokens, index)) {
            reportUpdateInValuePosition(tokens[index + 1], token.value, false)
        }
        emitAuxUpdate(output, token.value, next == INCR)
        return index + 2
    }
    // A plain read.
    output.append(auxRead(token.value))
    index + 1
}

/// Rewrite reads and updates of auxiliary variables in a callable body. Body macros
/// (`@ghost`, `@contractAssert`, `@loopInvariant`) are expanded before the enclosing
/// `@Contract`; the rewritten body only runs while contract checking is enabled.
func rewriteAuxiliaryMacros(block: Block, names: HashSet<String>): Block {
    if (names.isEmpty()) {
        return block
    }
    let tokens = block.toTokens()
    let rewritten = rewriteAux(tokens, names)
    if (rewritten.toString() == tokens.toString()) {
        return block
    }
    // A rewrite in a type-argument position (e.g. a clause variable sharing a name with
    // a generic type argument) makes the re-parse throw instead of returning a non-func
    // decl; degrade to the original body the same way.
    var reparsed: ?Decl = None
    try {
        reparsed = Some(parseDecl(quote(func __contract_body() $(rewritten))))
    } catch (e: ParseASTException) {
        reparsed = None
    }
    match (reparsed) {
        case Some(owner: FuncDecl) => owner.block
        case _ =>
            // The rewritten body failed to re-parse; keep the original body (the auxiliary
            // macros stay unrewritten) but say so instead of silently dropping the rewrite.
            diagReport(DiagReportLevel.WARNING, Tokens(),
                "auxiliary macro rewrite failed to re-parse and was discarded; auxiliary " +
                "variable references in this body will not be replaced",
                "simplify the body or report this case")
            block
    }
}

func isAuxIdentifier(token: Token, names: HashSet<String>): Bool {
    token.kind == IDENTIFIER && names.contains(token.value)
}

func auxStorageToken(name: String): Token {
    Token(IDENTIFIER, auxiliaryStorage(name))
}

func auxRead(name: String): Tokens {
    quote(contractGhostGet($(auxStorageToken(name)), $(name)))
}

func emitAuxUpdate(output: Tokens, name: String, increment: Bool): Unit {
    let read = auxRead(name)
    let op = if (increment) { Token(ADD) } else { Token(SUB) }
    output.append(quote($(auxStorageToken(name)) = Some($(read) $(op) 1)))
}

/// True when `x++` / `++x` at `index` stands alone as a statement (after a separator,
/// `{`/`}` or at the stream start). Statements arrive with their separators kept:
/// `block.toTokens()` renders statements one per line and drops `;`, so `foo(); count++`
/// reaches this check as `foo()` NL `count++`. After a separator the update is its own
/// statement unless the nearest significant token before it continues an expression
/// written across the separator (`1 +\ncount++`). Otherwise the update expands to an
/// assignment of type `Unit`, which cannot work as a value.
func isStatementPosition(tokens: Tokens, index: Int64): Bool {
    if (index == 0) {
        return true
    }
    var cursor = index - 1
    var afterSeparator = false
    while (cursor >= 0 && (tokens[cursor].kind == NL || tokens[cursor].kind == SEMI)) {
        afterSeparator = true
        cursor -= 1
    }
    if (cursor < 0 || afterSeparator) {
        return cursor < 0 || !continuesExpression(tokens[cursor].kind)
    }
    let kind = tokens[cursor].kind
    return kind == LCURL || kind == RCURL
}

/// Operators and punctuators after which an expression continues across a separator.
func continuesExpression(kind: TokenKind): Bool {
    match (kind) {
        case ADD | SUB | MUL | DIV | MOD | EXP | LT | GT | LE | GE | EQUAL | NOTEQ | AND | OR |
            BITAND | BITOR | BITXOR | LSHIFT | RSHIFT | COMMA | DOT | QUEST | COLON |
            LPAREN | LSQUARE | ASSIGN => true
        case _ => false
    }
}

func reportUpdateInValuePosition(operatorToken: Token, name: String, prefix: Bool): Unit {
    let form = if (prefix) {
        operatorToken.value + name
    } else {
        name + operatorToken.value
    }
    diagReport(DiagReportLevel.ERROR, Tokens(operatorToken),
        "auxiliary variable update `" + form + "` writes a slot and only works as a standalone statement",
        "read the slot through `" + name + "` and update it in a separate `@ghost` statement")
}

/// True when the identifier at `index` is being declared (`let`/`var`/`const` before it,
/// separators skipped): a same-name declaration introduces a fresh binding and must keep
/// its declared name instead of being rewritten into the auxiliary slot.
func precededByDeclKeyword(tokens: Tokens, index: Int64): Bool {
    var cursor = index - 1
    while (cursor >= 0) {
        let kind = tokens[cursor].kind
        if (kind == NL || kind == SEMI) {
            cursor -= 1
            continue
        }
        return kind == LET || kind == VAR || kind == CONST
    }
    false
}

/// Collect the right-hand side of `name = ...` up to the end of the statement.
func statementExpression(tokens: Tokens, start: Int64): (Tokens, Int64) {
    var depth = 0
    var index = start
    while (index < tokens.size) {
        let kind = tokens[index].kind
        if (depth == 0 && (kind == NL || kind == SEMI)) {
            break
        }
        if (kind == LPAREN || kind == LSQUARE || kind == LCURL) {
            depth += 1
        } else if (kind == RPAREN || kind == RSQUARE || kind == RCURL) {
            if (depth == 0) {
                break
            }
            depth -= 1
        }
        index += 1
    }
    (tokens[start..index], index)
}

/// Positions where an identifier never denotes the auxiliary variable: a call `x(...)`,
/// and a named-argument / struct-literal label `f(x: 1)` / `Point(x: 1)`. A label is `x`
/// preceded by `(` or `,` and followed by `:`; a ternary's true branch keeps being rewritten.
/// A function-typed auxiliary variable (`callable`) is callable itself, so a following
/// `(` starts its invocation rather than denoting a type constructor call.
func isCallOrLabelPosition(tokens: Tokens, index: Int64, callable!: Bool = false): Bool {
    // Direct call: `x(...)`. Newlines are not skipped: a `(` on the next line starts a
    // new statement, not a call of `x`.
    if (!callable && index + 1 < tokens.size && tokens[index + 1].kind == LPAREN) {
        return true
    }
    var previous = index - 1
    while (previous >= 0 && tokens[previous].kind == NL) {
        previous -= 1
    }
    if (previous < 0 || (tokens[previous].kind != LPAREN && tokens[previous].kind != COMMA)) {
        return false
    }
    var cursor = index + 1
    while (cursor < tokens.size && tokens[cursor].kind == NL) {
        cursor += 1
    }
    return cursor < tokens.size && tokens[cursor].kind == COLON
}

func isCompoundAssign(kind: TokenKind): Bool {
    match (kind) {
        case ADD_ASSIGN | SUB_ASSIGN | MUL_ASSIGN | DIV_ASSIGN | MOD_ASSIGN | EXP_ASSIGN | LSHIFT_ASSIGN |
             RSHIFT_ASSIGN | BITAND_ASSIGN | BITOR_ASSIGN | BITXOR_ASSIGN | AND_ASSIGN | OR_ASSIGN => true
        case _ => false
    }
}

func compoundOperator(kind: TokenKind): TokenKind {
    match (kind) {
        case ADD_ASSIGN => ADD
        case SUB_ASSIGN => SUB
        case MUL_ASSIGN => MUL
        case DIV_ASSIGN => DIV
        case MOD_ASSIGN => MOD
        case EXP_ASSIGN => EXP
        case LSHIFT_ASSIGN => LSHIFT
        case RSHIFT_ASSIGN => RSHIFT
        case BITAND_ASSIGN => BITAND
        case BITOR_ASSIGN => BITOR
        case BITXOR_ASSIGN => BITXOR
        case AND_ASSIGN => AND
        case OR_ASSIGN => OR
        case _ => ADD
    }
}

