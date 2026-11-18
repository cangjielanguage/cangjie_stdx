/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.syntax

import std.ast.{ASTException, DiagReportLevel, Tokens, diagReport}
import std.sync.{ReentrantMutex}

/**
 * @brief A diagnostic collected while parsing or validating contract clauses.
 *
 * Parse and validation stages collect diagnostics instead of failing fast; the macro
 * entry point reports them through `show()` and keeps the original tokens so error
 * recovery does not change program semantics.
 */
public class Diagnostic {
    /**
     * @brief The diagnostic text shown to the user.
     */
    public var message: String
    /**
     * @brief The clause or construct this diagnostic belongs to, e.g. `ContractClause` or
     * `loopInvariant`.
     */
    public var category: String
    private let _tokens: Tokens

    // Anchor for diagnostics whose tokens come from a foreign expansion; `diagReport` rejects
    // such tokens, so `show()` falls back to these. Macro expansion may run in parallel, so
    // every access is guarded by `_FALLBACK_MUTEX` (concurrent swaps may only degrade anchoring).
    private static let _FALLBACK_MUTEX = ReentrantMutex()
    private static var _fallback: Tokens = Tokens()

    /**
     * @brief Anchor tokens for diagnostics whose own tokens come from a foreign macro
     * expansion, which `diagReport` rejects.
     *
     * `show()` falls back to these tokens when reporting against a diagnostic's own
     * tokens fails. Macro expansion may run in parallel, so every access is
     * synchronized; concurrent swaps may only degrade which tokens a diagnostic is
     * anchored to.
     */
    public static mut prop fallback: Tokens {
        get() {
            synchronized(_FALLBACK_MUTEX) {
                _fallback
            }
        }
        set(value) {
            synchronized(_FALLBACK_MUTEX) {
                _fallback = value
            }
        }
    }

    /**
     * @brief The source tokens this diagnostic is anchored to.
     *
     * Reporting may reject these tokens when they originate from a foreign expansion; in
     * that case `show()` falls back to `fallback`.
     */
    public prop tokens: Tokens {
        get() {
            _tokens
        }
    }

    /**
     * @brief Builds a diagnostic anchored to source tokens.
     *
     * @param message The diagnostic text shown to the user.
     * @param category The clause or construct this diagnostic belongs to.
     * @param tokens The source tokens this diagnostic is anchored to.
     */
    public init(message: String, category: String, tokens: Tokens) {
        this.message = message
        this.category = category
        this._tokens = tokens
    }

    /**
     * @brief Reports this diagnostic as an error through `diagReport`.
     *
     * When the SDK rejects the diagnostic's own tokens (they originate from a foreign
     * expansion), reporting falls back to `fallback`.
     */
    public func show(): Unit {
        try {
            diagReport(DiagReportLevel.ERROR, tokens, message, category)
        } catch (e: ASTException) {
            diagReport(DiagReportLevel.ERROR, Diagnostic.fallback, message, category)
        }
    }
}
