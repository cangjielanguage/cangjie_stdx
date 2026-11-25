/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.validation

import stdx.contract.macros.syntax.{FunctionClause}
import stdx.contract.macros.tokens.precededByDot
import std.ast.{ASTException, Block, CallExpr, DiagReportLevel, DoWhileExpr, Expr, ForInExpr, FuncDecl, FuncParam, IfExpr, MatchExpr, Node, RefExpr, SpawnExpr, SynchronizedExpr, Token, Tokens, TryExpr, VarDecl, WhileExpr, diagReport}
import std.collection.{ArrayList, HashSet, contains, isEmpty}

/**
 * @brief Warn when clause conditions read names declared inside `@ghost` blocks.
 *
 * `let`/`var` declarations inside a `@ghost` block are auxiliary state for later `@ghost`,
 * `@contractAssert` and `@loopInvariant` uses only, not visible to the enclosing clauses.
 * The expanded `if (_contract_gateEnabled())` gates are recognized and collected. Ghost
 * names covered by a parameter or a contract `variable` of the same name are allowed, and
 * an `ensures` clause may read its own return name.
 *
 * @param clauses The contract clauses of one callable.
 * @param block Body of the callable; validation is skipped when it is None.
 * @param params Parameters of the callable, whose names stay visible to the clauses.
 */
public func validateGhostUsage(clauses: ArrayList<FunctionClause>, block: ?Block,
    params: ArrayList<FuncParam>): Unit {
    let body = match (block) {
        case Some(value) => value
        case None => return
    }
    let ghostNames = collectGhostDeclarations(body)
    if (ghostNames.isEmpty()) {
        return
    }
    let visible = HashSet<String>()
    for (parameter in params) {
        visible.add(parameter.identifier.value)
    }
    for (clause in clauses) {
        if (let Variable(variable) <- clause) {
            visible.add(variable.name.name)
        }
    }
    for (clause in clauses) {
        match (clause) {
            case Requires(c) => reportGhostReferences(c.condition.tokens, ghostNames, visible)
            case Ensures(c) =>
                // The return name of one clause must not become visible to the next one.
                let clauseVisible = HashSet<String>(visible)
                if (let Some(ret) <- c.ret) {
                    clauseVisible.add(ret.name)
                }
                reportGhostReferences(c.condition.tokens, ghostNames, clauseVisible)
            case Throws(c) => reportGhostReferences(c.condition.tokens, ghostNames, visible)
            case _ => ()
        }
    }
}

/// Collect the names declared by `@ghost` blocks anywhere in `block`. Nested callables own
/// their own scope and are skipped.
private func collectGhostDeclarations(block: Block): HashSet<String> {
    let names = HashSet<String>()
    collectGhostDeclarationsInBlock(block, names)
    names
}

/// Return the tokens in `tokens` that read a `@ghost`-declared name and are not covered by an
/// explicit parameter or a contract `variable` of the same name.
private func ghostContractReferences(tokens: Tokens, ghostNames: HashSet<String>,
    visible: HashSet<String>): ArrayList<Token> {
    let references = ArrayList<Token>()
    var index = 0
    while (index < tokens.size) {
        let token = tokens[index]
        if (token.kind == IDENTIFIER && ghostNames.contains(token.value) &&
            !visible.contains(token.value) && !precededByDot(tokens, index) &&
            !followedByCallOrLabel(tokens, index)) {
            references.add(token)
        }
        index += 1
    }
    references
}

func reportGhostReferences(tokens: Tokens, ghostNames: HashSet<String>,
    visible: HashSet<String>): Unit {
    for (token in ghostContractReferences(tokens, ghostNames, visible)) {
        diagReport(DiagReportLevel.WARNING, Tokens(token),
            "`" + token.value +
            "` is declared in a `@ghost` block and cannot be used by `requires`, `ensures`, or `throws`; declare it as a contract `variable` instead",
            "ghost")
    }
}

func collectGhostDeclarationsInBlock(block: Block, names: HashSet<String>): Unit {
    for (node in block.nodes) {
        collectGhostDeclarationsInNode(node, names)
    }
}

func collectGhostNodes(nodes: ArrayList<Node>, names: HashSet<String>): Unit {
    for (node in nodes) {
        collectGhostDeclarationsInNode(node, names)
    }
}

func collectGhostDeclarationsInNode(node: Node, names: HashSet<String>): Unit {
    match (node) {
        // A local callable has its own contract scope.
        case _: FuncDecl => ()
        case expression: IfExpr =>
            if (isGhostGate(expression.condition)) {
                collectGhostBodyDeclarations(expression.ifBlock, names)
                // An inner `@ghost` nested inside this gate declares state
                // that stays visible to the enclosing callable, so those
                // names join the same set instead of surfacing as generic errors.
                collectGhostDeclarationsInBlock(expression.ifBlock, names)
            } else {
                collectGhostDeclarationsInBlock(expression.ifBlock, names)
                astGetOrDefault((), {=> collectGhostDeclarationsInNode(expression.elseExpr, names)})
            }
        case expression: MatchExpr =>
            for (matchCase in expression.matchCases) {
                collectGhostDeclarationsInBlock(matchCase.block, names)
            }
        case expression: TryExpr =>
            collectGhostDeclarationsInBlock(expression.tryBlock, names)
            for (catchBlock in expression.catchBlocks) {
                collectGhostDeclarationsInBlock(catchBlock, names)
            }
            astGetOrDefault((), {=> collectGhostDeclarationsInBlock(expression.finallyBlock, names)})
        case expression: WhileExpr => collectGhostDeclarationsInBlock(expression.block, names)
        case expression: DoWhileExpr => collectGhostDeclarationsInBlock(expression.block, names)
        case expression: ForInExpr => collectGhostDeclarationsInBlock(expression.block, names)
        case expression: SynchronizedExpr => collectGhostDeclarationsInBlock(expression.block, names)
        // `unsafe` and `spawn` bodies are ordinary code of the enclosing callable,
        // so gates nested inside them must stay visible to the collectors.
        case expression: SpawnExpr => collectGhostNodes(expression.lambdaExpr.nodes, names)
        case expression: Block => collectGhostDeclarationsInBlock(expression, names)
        // Lambdas and local types keep their declarations private as well.
        case _ => ()
    }
}

/// Only the declarations at the top level of a `@ghost` body stay visible afterwards.
func collectGhostBodyDeclarations(block: Block, names: HashSet<String>): Unit {
    for (node in block.nodes) {
        if (let variable: VarDecl <- node) {
            addGhostBodyDeclaration(variable, names)
        }
    }
}

private func addGhostBodyDeclaration(variable: VarDecl, names: HashSet<String>): Unit {
    if (let Some(identifier) <- declaredVariableIdentifier(variable)) {
        names.add(identifier.value)
    }
}

/// Recognize the eligibility gate emitted by `@ghost` around its body:
/// `_contract_gateEnabled()`. The generated code never calls
/// `contractCheckEnabled`/`contractInEvaluation` directly, so matching this unique
/// `_contract_`-reserved-prefix name alone keeps the check independent of whitespace,
/// comments and token positions, and user-defined functions cannot collide with it.
func isGhostGate(condition: Expr): Bool {
    isCallOf(condition, "_contract_gateEnabled")
}

/// Recognize an unqualified no-argument call `<name>()`.
func isCallOf(expression: Expr, name: String): Bool {
    if (let call: CallExpr <- expression) {
        if (call.arguments.isEmpty()) {
            if (let reference: RefExpr <- call.callFunc) {
                return reference.identifier.value == name
            }
        }
    }
    false
}

/// A call or a named argument labels a callable/parameter, not a ghost variable.
func followedByCallOrLabel(tokens: Tokens, index: Int64): Bool {
    followedByLabelColon(tokens, index) || followedByLParen(tokens, index)
}

/// A named-argument label or a type annotation (`f(name: ...)` / `let x: T`), not a read
/// or a call. Callers that must also report call positions use this instead of
/// `followedByCallOrLabel`.
func followedByLabelColon(tokens: Tokens, index: Int64): Bool {
    var cursor = index + 1
    while (cursor < tokens.size && (tokens[cursor].kind == NL || tokens[cursor].kind == SEMI)) {
        cursor += 1
    }
    cursor < tokens.size && tokens[cursor].kind == COLON
}

/**
 * @brief Read a declaration body that may be absent (interface or abstract members).
 *
 * Accessing `FuncDecl.block` or `PropDecl.getter.block` without a body throws
 * `ASTException`.
 *
 * @param getter Closure that reads the body block.
 * @return The body block, or None when reading it raises `ASTException`.
 */
public func callableBlock(getter: () -> Block): ?Block {
    try {
        Some(getter())
    } catch (_: ASTException) {
        None
    }
}

/// Tokens of a declaration body, or an empty token stream when the body is absent.
internal func blockTokensOrEmpty(getter: () -> Block): Tokens {
    astGetOrDefault(Tokens()) {=> getter().toTokens()}
}

/**
 * @brief Evaluate `action`, falling back to `default` when it raises `ASTException`.
 *
 * For reads that may touch a body-less declaration.
 *
 * @param default Value returned when `action` raises `ASTException`.
 * @return The result of `action`, or `default` when `ASTException` is raised.
 */
public func astGetOrDefault<T>(default: T, action: () -> T): T {
    try {
        action()
    } catch (_: ASTException) {
        default
    }
}
