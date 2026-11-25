/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.validation

import stdx.contract.macros.syntax.{Diagnostic, FunctionClause, FunctionContract, IdentifierSyntax, InheritClauseKind, TypeInheritTarget}
import stdx.contract.macros.tokens.{destructuringGroupSpans, isValue, lambdaAndCaseBindingTokens}
import std.ast.{DiagReportLevel, FuncDecl, Token, Tokens, VarDecl, VarPattern, diagReport}
import std.collection.{ArrayList, HashSet, contains, isEmpty}

/**
 * @brief Validate a function-level contract against its `func` declaration.
 *
 * Checks that parameters, the callable name, and top-level local declarations avoid the
 * reserved `_contract_` and `_abs_` prefixes, that `ensures` return names do not collide
 * with the callable name, a parameter, or a contract `variable`, that clause names are
 * unique within their clause kind, and that contract `variable` names are not shadowed
 * by parameters or by local declarations in the body.
 *
 * @param contract The parsed function contract to validate.
 * @param owner The function declaration carrying the contract.
 * @return true when the contract is valid, false otherwise (diagnostics are reported).
 */
public func validateFunctionContract(contract: FunctionContract, owner: FuncDecl): Bool {
    let diagnostics = ArrayList<Diagnostic>()
    let parameters = ArrayList<String>()
    let variableNames = HashSet<String>()

    for (parameter in owner.funcParams) {
        parameters.add(parameter.identifier.value)
        validateReservedName(parameter.identifier.value, Tokens(parameter.identifier))
    }
    validateReservedName(owner.identifier.value, Tokens(owner.identifier))

    // Generated helper bindings (`_contract_r`, `_contract_pre_N`, `_contract_throws_N`, loop
    // indices, ...) are declared at the top level of the rewritten body, so user locals in that
    // same scope must not use the reserved prefix. Nested blocks live in narrower scopes and
    // cannot collide with the injected bindings.
    for (node in owner.block.nodes) {
        if (let variable: VarDecl <- node) {
            validateLocalDeclaration(variable)
        }
    }

    for (clause in contract.clauses) {
        if (let Variable(variable) <- clause) {
            variableNames.add(variable.name.name)
        }
    }
    for (clause in contract.clauses) {
        if (let Ensures(c) <- clause && let Some(ret) <- c.ret) {
            if (ret.name == owner.identifier.value) {
                diagnostics.add(
                    Diagnostic("`ensures` return name `" + ret.name + "` collides with callable name",
                        "Contract", ret.tokens))
            } else if (parameters.contains(ret.name)) {
                diagnostics.add(
                    Diagnostic("`ensures` return name `" + ret.name + "` collides with parameter name",
                        "Contract", ret.tokens))
            } else if (variableNames.contains(ret.name)) {
                // `variable x` + `ensures x: ...` would rewrite the condition to the auxiliary
                // storage and bind the result to a dead `let x`, silently checking the wrong
                // value.
                diagnostics.add(
                    Diagnostic("`ensures` return name `" + ret.name + "` collides with contract variable name",
                        "Contract", ret.tokens))
            }
        }
    }
    collectContractNames(contract.clauses, diagnostics)
    validateVariableNames(contract.clauses, parameters, blockTokensOrEmpty({=> owner.block}), diagnostics)
    for (diagnostic in diagnostics) {
        diagnostic.show()
    }
    diagnostics.isEmpty()
}

/// Reject reserved prefixes on a top-level local declaration of the body.
func validateLocalDeclaration(variable: VarDecl): Unit {
    if (variable.identifier.value.size > 0) {
        validateReservedName(variable.identifier.value, Tokens(variable.identifier))
        return
    }
    if (let pattern: VarPattern <- variable.pattern) {
        validateReservedName(pattern.identifier.value, Tokens(pattern.identifier))
    }
}

/// A function-level `variable` is rewritten by name at token level, so a parameter or local
/// declaration with the same name would silently capture the auxiliary storage instead.
/// Report the ambiguity instead of miscompiling.
internal func validateVariableNames(clauses: ArrayList<FunctionClause>, parameters: ArrayList<String>,
    bodyTokens: Tokens, diagnostics: ArrayList<Diagnostic>): Unit {
    let names = HashSet<String>()
    for (clause in clauses) {
        if (let Variable(variable) <- clause) {
            names.add(variable.name.name)
        }
    }
    if (names.isEmpty()) {
        return
    }
    for (clause in clauses) {
        if (let Variable(variable) <- clause && parameters.contains(variable.name.name)) {
            diagnostics.add(
                Diagnostic("contract variable `${variable.name.name}` collides with the parameter of the same name",
                    "Contract", variable.name.tokens))
        }
    }
    for (token in shadowingLocalDeclarations(bodyTokens, names)) {
        diagnostics.add(
            Diagnostic("contract variable `${token.value}` is shadowed by a local declaration; rename one of them",
                "Contract", Tokens(token)))
    }
}

/**
 * @brief Report contract `variable` clauses colliding with members of the enclosing type.
 *
 * A function-level `variable` is rewritten by bare name inside the member body at token
 * level, and a bare name there may also denote a field, property or sibling method of the
 * enclosing type — a distinction the token rewrite cannot make. Report the ambiguity
 * instead of silently reading the auxiliary storage. This runs at the type-level
 * expansion, which is the only place the enclosing declaration is available.
 *
 * @param clauses The contract clauses of one callable.
 * @param memberNames Names of the members declared directly on the enclosing type.
 * @param subject Name of the declaration owning the clauses, used in diagnostics.
 */
public func validateVariableMemberNames(clauses: ArrayList<FunctionClause>, memberNames: HashSet<String>,
    subject: String): Unit {
    for (clause in clauses) {
        if (let Variable(variable) <- clause && memberNames.contains(variable.name.name)) {
            diagReport(DiagReportLevel.ERROR, variable.name.tokens,
                "contract variable `${variable.name.name}` on `${subject}` collides with a member of the enclosing type; " +
                "the body rewrite cannot tell them apart, rename one of them",
                "Contract")
        }
    }
}

/// Tokens already reported together with their indexes, so a name recorded by one scan
/// is not recorded again by a later one.
class ShadowingScanResult {
    let found = ArrayList<Token>()
    let recorded = HashSet<Int64>()
}

/// Tokens declaring a name that matches a contract variable in `let`, `var`, `const`,
/// `for` position, in a nested `func` name / parameter list; lambda parameter lists,
/// `match` case patterns and `catch` bindings are covered by the shared binding collector.
/// Those bindings shadow the auxiliary variable and a token rewrite would corrupt them.
func shadowingLocalDeclarations(tokens: Tokens, names: HashSet<String>): ArrayList<Token> {
    let result = ShadowingScanResult()
    var index: Int64 = 0
    while (index < tokens.size) {
        index = scanShadowingAt(tokens, index, names, result)
    }
    for (binding in lambdaAndCaseBindingTokens(tokens, 0, tokens.size)) {
        if (names.contains(binding.value)) {
            result.found.add(binding)
        }
    }
    // Destructuring groups: identifiers inside a `let`/`var`/`const` pattern
    // (`let (a, (b, _)) = ...`) or a multiple-assignment target (`(a, b) = ...`)
    // bind locals the same way and shadow the auxiliary variable. The `let` scan
    // above already covers same-statement patterns (it stops at a depth-0 newline),
    // so the `recorded` guard prevents duplicate diagnostics.
    for (span in destructuringGroupSpans(tokens, 0, tokens.size)) {
        scanDestructuringSpan(tokens, span, names, result)
    }
    result.found
}

/// Handle the token at `index` and return the next index to scan.
func scanShadowingAt(tokens: Tokens, index: Int64, names: HashSet<String>, result: ShadowingScanResult): Int64 {
    let token = tokens[index]
    if (isValue(token, "let") || isValue(token, "var") || isValue(token, "for") ||
        isValue(token, "const")) {
        // `const func` declares a nested function, not a binding; the `func` branch
        // below covers its name and parameter list.
        if (isConstFuncAt(tokens, index)) {
            return index + 1
        }
        scanBindingList(tokens, index, token, names, result)
    } else if (isValue(token, "func")) {
        scanFunctionDeclaration(tokens, index, names, result)
    }
    index + 1
}

/// True when the `const` at `index` is followed by `func`, i.e. declares a nested function.
func isConstFuncAt(tokens: Tokens, index: Int64): Bool {
    if (!isValue(tokens[index], "const")) {
        return false
    }
    var cursor = index + 1
    while (cursor < tokens.size && (tokens[cursor].kind == NL || tokens[cursor].kind == SEMI)) {
        cursor += 1
    }
    cursor < tokens.size && isValue(tokens[cursor], "func")
}

/// Record identifiers of the binding list opened by `keyword` (at `index`).
func scanBindingList(tokens: Tokens, index: Int64, keyword: Token, names: HashSet<String>,
    result: ShadowingScanResult): Unit {
    var cursor = index + 1
    var depth: Int64 = 0
    while (cursor < tokens.size) {
        let current = tokens[cursor]
        if (isBindingListEnd(keyword, current, depth)) {
            break
        }
        match (current.kind) {
            case LPAREN | LSQUARE => depth += 1
            case RPAREN | RSQUARE =>
                if (depth > 0) {
                    depth -= 1
                }
            case IDENTIFIER => recordShadowingName(current, cursor, names, result)
            case _ => ()
        }
        cursor += 1
    }
}

/// Whether the binding list of `keyword` ends at `current` given the current `depth`.
func isBindingListEnd(keyword: Token, current: Token, depth: Int64): Bool {
    (isValue(keyword, "for") && isValue(current, "in")) ||
        (depth == 0 && (current.kind == NL || current.kind == ASSIGN || current.kind == COLON ||
        isValue(current, "<-")))
}

/// Record the name and parameter list declared by the `func` at `index`.
func scanFunctionDeclaration(tokens: Tokens, index: Int64, names: HashSet<String>,
    result: ShadowingScanResult): Unit {
    var cursor = index + 1
    // The first identifier after `func` is the declared function name.
    if (cursor < tokens.size && tokens[cursor].kind == IDENTIFIER) {
        recordShadowingName(tokens[cursor], cursor, names, result)
        cursor += 1
    }
    // Identifiers inside the `LPAREN..RPAREN` parameter list are declared
    // parameter names; the function body itself keeps being covered by the
    // ordinary linear scan of this token stream.
    var depth: Int64 = 0
    var entered = false
    while (cursor < tokens.size) {
        let current = tokens[cursor]
        if (current.kind == LPAREN) {
            depth += 1
            entered = true
        } else if (current.kind == RPAREN) {
            if (depth > 0) {
                depth -= 1
            }
        } else if (depth > 0 && current.kind == IDENTIFIER && names.contains(current.value)) {
            recordShadowingName(current, cursor, names, result)
        } else if (!entered && (current.kind == NL || current.kind == LCURL)) {
            break
        }
        cursor += 1
        if (entered && depth == 0) {
            break
        }
    }
}

/// Record the identifiers of one destructuring group that were not already recorded.
func scanDestructuringSpan(tokens: Tokens, span: (Int64, Int64), names: HashSet<String>,
    result: ShadowingScanResult): Unit {
    var cursor = span[0]
    while (cursor <= span[1]) {
        let current = tokens[cursor]
        if (!result.recorded.contains(cursor) && current.kind == IDENTIFIER &&
            names.contains(current.value)) {
            recordShadowingName(current, cursor, names, result)
        }
        cursor += 1
    }
}

func recordShadowingName(token: Token, index: Int64, names: HashSet<String>, result: ShadowingScanResult): Unit {
    if (names.contains(token.value)) {
        result.found.add(token)
        result.recorded.add(index)
    }
}

/// Names used by the clauses of one callable. Names must be unique within one clause
/// kind, while different kinds may share a name.
internal class ContractNames {
    private let requires = HashSet<String>()
    private let ensures = HashSet<String>()
    private let throws = HashSet<String>()
    private let variables = HashSet<String>()

    public func record(clause: FunctionClause, diagnostics: ArrayList<Diagnostic>): Unit {
        match (clause) {
            case FunctionClause.Requires(c) => recordContractName(c.name, requires, diagnostics)
            case FunctionClause.Ensures(c) => recordContractName(c.name, ensures, diagnostics)
            case FunctionClause.Throws(c) => recordContractName(c.name, throws, diagnostics)
            case FunctionClause.Inherit(c) =>
                let target = match (c.kind) {
                    case InheritClauseKind.Requires => requires
                    case InheritClauseKind.Ensures => ensures
                    case InheritClauseKind.Throws => throws
                    case InheritClauseKind.Variable => variables
                }
                match (c.target) {
                    case TypeInheritTarget.ByRename(_, newName, _) =>
                        recordContractName(Some(newName), target, diagnostics)
                    case _ => ()
                }
            case FunctionClause.Variable(c) => recordContractName(Some(c.name), variables, diagnostics)
        }
    }
}

/// Require every contract name on one callable to be distinct within its clause kind.
internal func collectContractNames(clauses: ArrayList<FunctionClause>, diagnostics: ArrayList<Diagnostic>): Unit {
    let names = ContractNames()
    for (clause in clauses) {
        names.record(clause, diagnostics)
    }
}

func recordContractName(name: ?IdentifierSyntax, names: HashSet<String>, diagnostics: ArrayList<Diagnostic>): Unit {
    match (name) {
        case Some(label) =>
            if (names.contains(label.name)) {
                diagnostics.add(
                    Diagnostic("duplicate contract name `${label.name}` on the same callable", "Contract",
                        label.tokens))
            } else {
                names.add(label.name)
            }
        case None => ()
    }
}

internal func validateReservedName(name: String, tokens: Tokens): Unit {
    if (name.startsWith("_contract_")) {
        diagReport(DiagReportLevel.ERROR, tokens,
            "the `_contract_` prefix is reserved for generated contract bindings; choose another name", "Contract")
    }
    if (name.startsWith("_abs_")) {
        diagReport(DiagReportLevel.ERROR, tokens,
            "the `_abs_` prefix is reserved for generated contract storage; choose another name", "Contract")
    }
}
