/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.generate

import stdx.contract.macros.inheritance.{ResolvedTypeContract}
import stdx.contract.macros.syntax.{TypeClause, VariableClause}
import stdx.contract.macros.tokens.{precededByDot, rewriteStringInterpolation}
import std.ast.{Decl, ToTokens, Token, Tokens, parseDecl}
import std.collection.{ArrayList, HashSet, contains, isEmpty}

func collectVariables(contract: ResolvedTypeContract): ArrayList<VariableClause> {
    let variables = ArrayList<VariableClause>()
    for (resolved in contract.clauses) {
        if (let TypeClause.Variable(variable) <- resolved.clause) {
            // Class parents already own the storage; interface variables need the implementor to add it.
            if (resolved.emitStorage) {
                variables.add(variable)
            }
        }
    }
    variables
}

/// Abstract variables the type inherits from an interface. Their same-name property must stay
/// public so it can implement the interface's abstract property.
func collectInterfaceVariables(contract: ResolvedTypeContract): ArrayList<VariableClause> {
    let variables = ArrayList<VariableClause>()
    let seen = HashSet<String>()
    for (resolved in contract.clauses) {
        if (let TypeClause.Variable(variable) <- resolved.clause) {
            // Two interfaces may contribute the same variable name; treat it as one variable.
            if (resolved.fromInterface && !seen.contains(variable.name.name)) {
                seen.add(variable.name.name)
                variables.add(variable)
            }
        }
    }
    variables
}

/// Emit ghost storage and a same-name property used by contracts.
/// User API visibility: variables inherited from an interface stay public (they must implement the
/// interface's abstract property); open types expose others to subclasses; every other type is private.
func genVariableDeclarations(variables: ArrayList<VariableClause>, isOpen: Bool,
    interfaceNames: HashSet<String>): ArrayList<Decl> {
    let declarations = ArrayList<Decl>()
    // Instance initializers may read earlier instance slots directly, but static slots are
    // only initialized lazily on first property access: rewriting a static name to a direct
    // storage read would observe `None` and throw `GhostStateException`.
    let initializedInstanceNames = HashSet<String>()
    // Function-typed variables are invoked (`f(1)`) rather than read; the call-position
    // guard must not mistake the callee for a type constructor.
    let callableInstanceNames = HashSet<String>()
    for (variable in variables) {
        if (variable.isStatic) {
            declarations.add(all: genStaticVariableDeclaration(variable, isOpen, interfaceNames))
            // Static names are deliberately not added to `initializedInstanceNames`: an
            // instance initializer must read them through the property so lazy init runs.
            continue
        }
        declarations.add(all:
            genInstanceVariableDeclaration(variable, isOpen, interfaceNames, initializedInstanceNames,
                callableInstanceNames))
        if (variable.initExpr.isSome()) {
            initializedInstanceNames.add(variable.name.name)
        }
        if (isFunctionType(variable.ty.tokens)) {
            callableInstanceNames.add(variable.name.name)
        }
    }
    declarations
}

/// Ghost storage and property of one static abstract variable.
func genStaticVariableDeclaration(variable: VariableClause, isOpen: Bool,
    interfaceNames: HashSet<String>): ArrayList<Decl> {
    let name = variable.name.name
    let storage = Token(IDENTIFIER, "_abs_" + name)
    let typeTokens = variable.ty.tokens
    let nameToken = Token(IDENTIFIER, name)
    // Static initializers run while the module loads. The declared initial value is
    // applied on the first read in both check modes: `contract_check=off` still
    // evaluates it (the storage is plain memory then), matching instance variables.
    let declaration = parseDecl(quote(private static var $(storage): ?$(typeTokens) = None))
    let lazyInit = match (variable.initExpr) {
        case Some(expression) =>
            quote(
            if ($(storage).isNone()) {
                $(storage) = Some($(expression.tokens))
            })
        case None => Tokens()
    }
    let propertyModifiers = if (interfaceNames.contains(name)) {
        quote(public static mut)
    } else if (isOpen) {
        quote(protected static mut)
    } else {
        quote(private static mut)
    }
    let property = parseDecl(
        quote(
        $(propertyModifiers) prop $(nameToken): $(typeTokens) {
            get() {
                $(lazyInit)
                match ($(storage)) {
                    case Some(value) => value
                    case None => throw ContractCheckGhostStateException()
                }
            }
            set(value) { $(storage) = Some(value) }
        }
    ))
    // Both declarations are emitted in order by the caller.
    let declarations = ArrayList<Decl>()
    declarations.add(declaration)
    declarations.add(property)
    declarations
}

/// Ghost storage and property of one instance abstract variable.
func genInstanceVariableDeclaration(variable: VariableClause, isOpen: Bool,
    interfaceNames: HashSet<String>, initializedInstanceNames: HashSet<String>,
    callableInstanceNames: HashSet<String>): ArrayList<Decl> {
    let name = variable.name.name
    let storage = Token(IDENTIFIER, "_abs_" + name)
    let typeTokens = variable.ty.tokens
    let nameToken = Token(IDENTIFIER, name)
    // The initializer is applied unconditionally in both check modes: with
    // `contract_check=off` the storage is plain memory and the declared initial value
    // must still hold so body reads via the prop behave like a normal variable.
    let initial = match (variable.initExpr) {
        case Some(expression) =>
            let rewritten = rewriteVariableInitializer(expression.tokens, initializedInstanceNames,
                callableInstanceNames)
            quote(Some($(rewritten)))
        case None => quote(None)
    }
    let declaration = parseDecl(quote(private var $(storage): ?$(typeTokens) = $(initial)))
    let propertyModifiers = if (interfaceNames.contains(name)) {
        quote(public mut)
    } else if (isOpen) {
        // `open` lets a implementing subclass widen the property to public when the type
        // must also implement an interface that declares the same auxiliary variable.
        quote(protected open mut)
    } else {
        quote(private mut)
    }
    let property = parseDecl(
        quote(
        $(propertyModifiers) prop $(nameToken): $(typeTokens) {
            get() {
                match ($(storage)) {
                    case Some(value) => value
                    case None => throw ContractCheckGhostStateException()
                }
            }
            set(value) { $(storage) = Some(value) }
        }
    ))
    // Both declarations are emitted in order by the caller.
    let declarations = ArrayList<Decl>()
    declarations.add(declaration)
    declarations.add(property)
    declarations
}

/// Rewrite references to earlier initialized abstract variables inside an initializer.
/// The same-name property cannot be read before every member is initialized, so the
/// initializer reads the ghost storage directly.
func rewriteVariableInitializer(tokens: Tokens, names: HashSet<String>,
    callableNames: HashSet<String>): Tokens {
    if (names.isEmpty()) {
        return tokens
    }
    let output = Tokens()
    var index = 0
    while (index < tokens.size) {
        let token = tokens[index]
        // String interpolation is invisible at token level; an earlier variable read
        // inside `${...}` must be rewritten exactly like the surrounding stream.
        if (token.kind == STRING_LITERAL) {
            output.append(rewriteStringInterpolation(token,
                {inner => rewriteVariableInitializer(inner, names, callableNames)}))
            index += 1
            continue
        }
        // A function-typed variable is invoked directly (`f(1)`): the callee is a value
        // read, so the call-position guard is disabled for those names.
        if (token.kind == IDENTIFIER && names.contains(token.value) && !precededByDot(tokens, index) &&
            !isCallOrLabelPosition(tokens, index, callable: callableNames.contains(token.value))) { // cjlint-ignore !G.EXP.03 right operand is a pure predicate; short-circuit keeps per-token work minimal
            let storage = Token(IDENTIFIER, "_abs_" + token.value)
            output.append(quote(contractGhostGet($(storage), $(token.value))))
            index += 1
            continue
        }
        output.append(token)
        index += 1
    }
    output
}
