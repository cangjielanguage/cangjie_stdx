/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.parse

import stdx.contract.macros.syntax.{Diagnostic, EnsuresClause, ExprSyntax, FunctionClause, FunctionContract, FunctionInheritClause, IdentifierSyntax, InheritClauseKind, RequiresClause, ThrowsClause, TypeInheritTarget, VariableClause}
import std.ast.{Tokens}
import std.collection.{ArrayList}

/**
 * @brief Parses the clauses of a callable contract into a `FunctionContract`.
 *
 * Accepts the `requires`, `ensures`, `throws`, `variable`, and `inherits` clauses.
 * Clauses are split at clause keywords on line starts and at `;`; a parsed clause must
 * consume its whole slice, so leftover tokens after a clause are reported as a
 * diagnostic instead of being dropped, and a slice that does not start with a clause
 * keyword is reported as well. Malformed clause bodies are returned as diagnostics in
 * the `ParseResult` rather than thrown.
 *
 * @param tokens The contract clauses carried in `@Contract[...]`.
 * @return The parsed contract with the diagnostics collected while parsing the clauses.
 */
public func parseFunctionContract(tokens: Tokens): ParseResult<FunctionContract> {
    parseCallableContract(tokens)
}

internal func parseConstructorContract(tokens: Tokens): ParseResult<FunctionContract> {
    parseCallableContract(tokens)
}

func parseCallableContract(tokens: Tokens): ParseResult<FunctionContract> {
    let diagnostics = ArrayList<Diagnostic>()
    let contract = FunctionContract(tokens)
    let slices = splitContractClauses(tokens)
    for (slice in slices) {
        let state = ParseState(slice, diagnostics: diagnostics)
        if (let Some(clause) <- parseFunctionClause(state)) {
            contract.clauses.add(clause)
            // A clause may consume only part of its slice (`variable v: Int64 requires ...`
            // written on one line); report the leftover instead of dropping it silently.
            state.cursor.skipClauseSeparators()
            if (!state.cursor.atEnd()) {
                state.reportError("unexpected token after contract clause")
            }
        }
    }
    ParseResult(contract, diagnostics)
}

/// Parse a function clause
func parseFunctionClause(state: ParseState): ?FunctionClause {
    let token = state.cursor.current()
    if (!isClauseKeyword(token)) {
        state.reportError("expected a function contract clause, got ${token.value}")
        return None
    }
    match (token.value) {
        case "requires" => parseRequires(state)
        case "ensures" => parseEnsures(state)
        case "throws" => parseThrows(state)
        case "variable" => parseFunctionVariable(state)
        case "inherits" => parseInheritClause(state)
        case _ => None
    }
}

/// `inherits <kind> <type>.<name>` or `inherits <kind> <new-name> = <type>.<name>`.
/// The `inherits` prefix separates inheritance syntax from ordinary member expressions.
func parseInheritClause(state: ParseState): ?FunctionClause {
    let start = state.cursor.pos
    state.cursor.forward() // "inherits"
    if (state.cursor.atEnd()) {
        state.reportError("`inherits` needs a contract kind after it")
        return None
    }
    let keyword = state.cursor.current()
    let kind = match (keyword.value) {
        case "requires" => InheritClauseKind.Requires
        case "ensures" => InheritClauseKind.Ensures
        case "throws" => InheritClauseKind.Throws
        case "variable" => InheritClauseKind.Variable
        case value =>
            state.reportError("`inherits` needs `requires`, `ensures`, `throws`, or `variable`, got ${value}")
            return None
    }
    state.cursor.forward() // the clause kind
    let inherit = match (parseFunctionInherit(state, kind, start)) {
        case Some(value) => value
        case None =>
            state.reportError("`inherits ${keyword.value}` needs `<type>.<name>` or `<new-name> = <type>.<name>`")
            return None
    }
    match (kind) {
        case InheritClauseKind.Variable =>
            match (inherit.target) {
                case TypeInheritTarget.ByRename(_, _, _) =>
                    state.reportError("`inherits variable` cannot rename the inherited auxiliary variable")
                    return None
                case _ => ()
            }
        case _ => ()
    }
    Some(FunctionClause.Inherit(inherit))
}

func parseRequires(state: ParseState): ?FunctionClause {
    let start = state.cursor.pos
    state.cursor.forward() // "requires"
    let name = parseOptionalLabel(state, "function contract")
    if (state.cursor.atEnd()) {
        state.reportError("contract clause needs an expression")
        return None
    }
    // `$pre` snapshots do not exist for `requires`; say so instead of failing the
    // SDK expression parse.
    if (reportMisplacedPreAhead(state, "ContractClause", false)) {
        return None
    }
    let condition = readExpr(state)
    Some(FunctionClause.Requires(
        RequiresClause(condition, state.cursor.tokens[start..state.cursor.pos], name: name)))
}

func parseEnsures(state: ParseState): ?FunctionClause {
    let start = state.cursor.pos
    state.cursor.forward() // "ensures"
    let name = parseOptionalLabel(state, "function contract")
    let ret = parseOptionalReturnName(state)
    if (state.cursor.atEnd()) {
        state.reportError("contract clause needs an expression")
        return None
    }
    // Only the `$pre(expr)` snapshot-call form is valid here; a bare `$pre` gets the
    // dedicated diagnostic instead of the SDK's generic parse failure.
    if (reportMisplacedPreAhead(state, "ContractClause", true)) {
        return None
    }
    let condition = readPreExpr(state)
    Some(FunctionClause.Ensures(
        EnsuresClause(ret, condition, state.cursor.tokens[start..state.cursor.pos], name: name)))
}

func parseThrows(state: ParseState): ?FunctionClause {
    let start = state.cursor.pos
    state.cursor.forward() // "throws"
    let name = parseOptionalLabel(state, "function contract")
    let exception = match (parseClauseType(state)) {
        case Some(ty) => ty
        case None => return None
    }
    if (state.cursor.consumeKind(IF).isNone()) {
        state.reportError("throws clause needs `if` after the exception type")
        return None
    }
    if (state.cursor.atEnd()) {
        state.reportError("contract clause needs an expression")
        return None
    }
    if (reportMisplacedPreAhead(state, "ContractClause", false)) {
        return None
    }
    let condition = readExpr(state)
    Some(FunctionClause.Throws(
        ThrowsClause(exception, condition, state.cursor.tokens[start..state.cursor.pos], name: name)))
}

/// `variable name: Type (= init)?`
func parseFunctionVariable(state: ParseState): ?FunctionClause {
    let start = state.cursor.pos
    state.cursor.forward() // "variable"
    let name = parseIdentifier(state)
    if (name.isNone()) {
        state.reportError("variable clause needs a name and `:` before its type")
        return None
    }
    if (state.cursor.consumeKind(COLON).isNone()) {
        state.reportError("variable clause needs a name and `:` before its type")
        return None
    }
    let ty = match (parseClauseType(state)) {
        case Some(value) => value
        case None => return None
    }
    var initExpr: ?ExprSyntax = None
    if (state.cursor.consumeKind(ASSIGN).isSome()) {
        if (!reportMisplacedPreAhead(state, "ContractClause", false)) {
            initExpr = Some(readExpr(state))
        }
    }
    Some(FunctionClause.Variable(
        VariableClause(false, name.getOrThrow(), ty, initExpr, state.cursor.tokens[start..state.cursor.pos])))
}

/// Parse `<type>.<name>` or `<new-name> = <type>.<name>` after `inherits <kind>`.
func parseFunctionInherit(state: ParseState, kind: InheritClauseKind,
    start: Int64): ?FunctionInheritClause {
    let tokens = state.cursor.tokens
    let targetStart = state.cursor.pos
    // The `+ 2` bound is stricter than parseInvariantInherit's precise `+ 1`: when the
    // `new = ` prefix is the last thing before the token end, this skips the rename
    // branch and falls through to the ByMember attempt, which fails identically
    // (parseMemberReference returns None on the empty/suffix input and restores the
    // cursor). Both bounds therefore yield the same outcome for every input.
    if (targetStart + 2 < tokens.size && tokens[targetStart].kind == IDENTIFIER &&
        tokens[targetStart + 1].kind == ASSIGN) {
        let newName = IdentifierSyntax(tokens[targetStart].value, Tokens(tokens[targetStart]))
        state.cursor.pos = targetStart + 2
        if (let Some(target) <- parseMemberReference(state)) {
            return FunctionInheritClause(kind, TypeInheritTarget.ByRename(target[0], newName, target[1]),
                tokens[start..state.cursor.pos])
        }
        state.cursor.pos = targetStart
        return None
    }
    if (let Some(target) <- parseMemberReference(state)) {
        return FunctionInheritClause(kind, TypeInheritTarget.ByMember(target[0], target[1]),
            tokens[start..state.cursor.pos])
    }
    None
}

func parseOptionalReturnName(state: ParseState): ?IdentifierSyntax {
    let cursor = state.cursor
    let start = cursor.pos
    if (let Some(ident) <- cursor.consumeKind(IDENTIFIER)) {
        if (cursor.consumeKind(COLON).isSome()) {
            return IdentifierSyntax(ident.value, Tokens(ident))
        }
    }
    cursor.pos = start
    None
}
