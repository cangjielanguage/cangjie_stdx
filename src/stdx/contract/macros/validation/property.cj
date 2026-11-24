/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.validation

import stdx.contract.macros.syntax.{Diagnostic, FunctionClause, PropContract, PropKind}
import std.ast.{ASTException, FuncDecl, PropDecl}
import std.collection.{ArrayList, isEmpty}

/**
 * @brief Validate a property contract against its `prop` declaration.
 *
 * Checks that `set` clauses appear only on a `mut prop`, that clause names are unique
 * within the getter and the setter namespaces (which are distinct), and that contract
 * `variable` names are not shadowed by the accessor's parameter or by local declarations
 * in the accessor body.
 *
 * @param contract The parsed property contract to validate.
 * @param owner The property declaration carrying the contract.
 * @return true when the contract is valid, false otherwise (diagnostics are reported).
 */
public func validatePropertyContract(contract: PropContract, owner: PropDecl): Bool {
    let diagnostics = ArrayList<Diagnostic>()
    var hasSetter = false
    for (clause in contract.clauses) {
        match (clause.kind) {
            case PropKind.Setter => hasSetter = true
            case PropKind.Getter => ()
        }
    }
    if (hasSetter && !hasModifier(owner.modifiers, "mut")) {
        diagnostics.add(
            Diagnostic("property contract: `set` clauses are only allowed on `mut prop`", "property contract",
                contract.tokens))
    }
    // Getter and setter names are distinct namespaces.
    let getterNames = ContractNames()
    let setterNames = ContractNames()
    for (clause in contract.clauses) {
        let names = match (clause.kind) {
            case PropKind.Getter => getterNames
            case PropKind.Setter => setterNames
        }
        for (body in clause.clauses) {
            names.record(body, diagnostics)
        }
    }
    // Contract `variable` clauses are rewritten by name inside the accessor bodies: a
    // setter parameter or a local declaration with the same name would silently capture
    // the auxiliary storage and check the wrong value. Functions go through
    // `validateVariableNames`; property contracts must not skip that check. The setter
    // parameter itself counts as a shadowing declaration, which also covers `variable
    // value` after the alias was rewritten to the real parameter name by the parser.
    let getterClauses = ArrayList<FunctionClause>()
    let setterClauses = ArrayList<FunctionClause>()
    for (clause in contract.clauses) {
        match (clause.kind) {
            case PropKind.Getter => getterClauses.add(all: clause.clauses)
            case PropKind.Setter => setterClauses.add(all: clause.clauses)
        }
    }
    let getterParameters = ArrayList<String>()
    validatePropertyVariableNames(getterClauses, getterParameters, {=> owner.getter}, diagnostics)
    let setterParameters = ArrayList<String>()
    setterParameters.add(setterBindingName(owner))
    validatePropertyVariableNames(setterClauses, setterParameters, {=> owner.setter}, diagnostics)
    for (diagnostic in diagnostics) {
        diagnostic.show()
    }
    diagnostics.isEmpty()
}

func validatePropertyVariableNames(clauses: ArrayList<FunctionClause>, parameters: ArrayList<String>,
    accessor: () -> FuncDecl, diagnostics: ArrayList<Diagnostic>): Unit {
    var hasVariable = false
    for (clause in clauses) {
        if (let Variable(_) <- clause) {
            hasVariable = true
            break
        }
    }
    if (!hasVariable) {
        return
    }
    let target = try {
        accessor()
    } catch (_: ASTException) {
        return
    }
    validateVariableNames(clauses, parameters, blockTokensOrEmpty({=> target.block}), diagnostics)
}

/// Real name of the setter's value parameter, or the canonical `value` alias when the
/// accessor is missing or unnamed. Local copy of the generate-package helper: importing
/// `generate` here would create a package cycle (`generate` already imports `validation`).
func setterBindingName(owner: PropDecl): String {
    try {
        owner.setter.funcParams[0].identifier.value
    } catch (_: Exception) {
        "value"
    }
}

/**
 * @brief Validate `@ghost` usage in the accessors of a property contract.
 *
 * `@ghost` blocks declared inside property accessors obey the same visibility rule as
 * function bodies; each accessor is validated with its own contract clauses.
 *
 * @param contract The parsed property contract.
 * @param owner The property declaration carrying the contract.
 */
public func validatePropertyGhostUsage(contract: PropContract, owner: PropDecl): Unit {
    for (clause in contract.clauses) {
        match (clause.kind) {
            case PropKind.Getter => validateAccessorGhostUsage(clause.clauses, {=> owner.getter})
            case PropKind.Setter => validateAccessorGhostUsage(clause.clauses, {=> owner.setter})
        }
    }
}

/// A bodiless property (interface or abstract member) has no accessor node at all, so both
/// the accessor and its body must be read lazily.
func validateAccessorGhostUsage(clauses: ArrayList<FunctionClause>, accessor: () -> FuncDecl): Unit {
    let target = try {
        accessor()
    } catch (_: ASTException) {
        return
    }
    validateGhostUsage(clauses, callableBlock({=> target.block}), target.funcParams)
}
