/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.generate

import stdx.contract.macros.syntax.{Diagnostic}
import std.ast.{Token, Tokens}
import std.collection.{ArrayList, forEach, isEmpty}

/// Collects generation-time diagnostics and allocates shared names.
internal class GenContext {
    /**
     * @brief The generation-time diagnostics collected so far.
     */
    public var diagnostics: ArrayList<Diagnostic> = ArrayList<Diagnostic>()
    private var nextPreId: Int64 = 0

    /**
     * @brief Records one generation-time diagnostic.
     *
     * @param message The diagnostic message.
     * @param category The diagnostic category shown to the user.
     * @param tokens The source tokens the diagnostic points at.
     */
    public func error(message: String, category: String, tokens: Tokens): Unit {
        diagnostics.add(Diagnostic(message, category, tokens))
    }

    /**
     * @brief Whether any diagnostic has been collected.
     *
     * @return `true` when at least one diagnostic was recorded.
     */
    public func hasErrors(): Bool {
        !diagnostics.isEmpty()
    }

    /**
     * @brief Shows all collected diagnostics to the user.
     */
    public func report(): Unit {
        diagnostics.forEach {diagnostic => diagnostic.show()}
    }

    /**
     * @brief Allocates a `$pre` snapshot binding shared by all clauses generated for one
     * callable.
     *
     * @return The next unique `_contract_pre_<n>` identifier token.
     */
    public func nextPreName(): Token {
        nextPreId += 1
        Token(IDENTIFIER, "_contract_pre_" + nextPreId.toString())
    }
}
