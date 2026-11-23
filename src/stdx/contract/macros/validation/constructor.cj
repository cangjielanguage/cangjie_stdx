/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.validation

import stdx.contract.macros.syntax.{Diagnostic, FunctionContract}
import std.ast.{PrimaryCtorDecl, Tokens}
import std.collection.{ArrayList, forEach, isEmpty}

/**
 * @brief Validate a constructor contract against its primary constructor declaration.
 *
 * Checks that parameters avoid the reserved `_contract_` and `_abs_` prefixes, that clause
 * names are unique within their clause kind, and that contract `variable` names are not
 * shadowed by parameters or by local declarations in the constructor body.
 *
 * @param contract The parsed constructor contract to validate.
 * @param owner The primary constructor declaration carrying the contract.
 * @return true when the contract is valid, false otherwise (diagnostics are reported).
 */
public func validateConstructorContract(contract: FunctionContract, owner: PrimaryCtorDecl): Bool {
    let diagnostics = ArrayList<Diagnostic>()
    let parameters = ArrayList<String>()

    for (parameter in owner.funcParams) {
        parameters.add(parameter.identifier.value)
        validateReservedName(parameter.identifier.value, Tokens(parameter.identifier))
    }
    validateReservedName("init", Tokens())

    collectContractNames(contract.clauses, diagnostics)
    validateVariableNames(contract.clauses, parameters, blockTokensOrEmpty({=> owner.block}), diagnostics)
    diagnostics.forEach {diagnostic => diagnostic.show()}
    diagnostics.isEmpty()
}

/**
 * @brief Report `ensures` return bindings on constructor contracts.
 *
 * Constructors return no value, so an `ensures` return binding (`ensures ret: expr`) has
 * nothing to bind. Report a targeted diagnostic instead of letting generation emit a
 * meaningless `let ret = ()` whose type error points at unrelated code.
 *
 * @param contract The parsed constructor contract to inspect.
 * @return true when no `ensures` clause carries a return binding, false otherwise
 * (diagnostics are reported).
 */
public func reportConstructorEnsuresReturn(contract: FunctionContract): Bool {
    let diagnostics = ArrayList<Diagnostic>()
    for (clause in contract.clauses) {
        if (let Ensures(c) <- clause && let Some(ret) <- c.ret) {
            diagnostics.add(
                Diagnostic("`ensures` return binding is not supported on constructor contracts; constructors return no value",
                    "Contract", ret.tokens))
        }
    }
    diagnostics.forEach {diagnostic => diagnostic.show()}
    diagnostics.isEmpty()
}
