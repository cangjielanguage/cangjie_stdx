/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.parse

import stdx.contract.macros.tokens.{TokenCursor}
import stdx.contract.macros.syntax.{Diagnostic}
import std.ast.{Tokens}
import std.collection.{ArrayList, forEach, isEmpty, max, min}

/**
 * @brief The outcome of parsing a construct of the `@Contract` macro family: the parsed
 * value plus the diagnostics collected while parsing.
 *
 * Parsers of this package do not throw on malformed clause bodies; they return a
 * best-effort `value` together with the diagnostics, and the macro expansion reports
 * them as compile-time errors before consuming the value. Check `hasError` or inspect
 * `diagnostics` before using `value`.
 */
public class ParseResult<T> {
    /**
     * @brief The parsed construct.
     *
     * Populated on a best-effort basis: even when diagnostics were collected, the value
     * holds the part of the construct that could be recovered from the input.
     */
    public var value: T

    /**
     * @brief The diagnostics collected while parsing, in the order they were reported.
     *
     * Every diagnostic carries the message, the reporting category, and the tokens that
     * anchor the compile-time error.
     */
    public var diagnostics: ArrayList<Diagnostic>

    /**
     * @brief Creates a result from the parsed value and the diagnostics collected while
     * parsing.
     *
     * @param value The parsed construct.
     * @param diagnostics The collected diagnostics, possibly empty.
     */
    public init(value: T, diagnostics: ArrayList<Diagnostic>) {
        this.value = value
        this.diagnostics = diagnostics
    }

    /**
     * @brief Whether any diagnostic was collected while parsing.
     *
     * @return `true` when `diagnostics` is not empty, `false` otherwise.
     */
    public func hasError(): Bool {
        !diagnostics.isEmpty()
    }

    /**
     * @brief Reports every collected diagnostic as a compile-time error.
     *
     * Each diagnostic is anchored at its own tokens; when those tokens cannot be
     * reported by `diagReport`, the diagnostic falls back to the macro input recorded in
     * `Diagnostic.fallback`.
     */
    public func report(): Unit {
        diagnostics.forEach {d => d.show()}
    }
}

internal class ParseState {
    let cursor: TokenCursor
    public let diagnostics: ArrayList<Diagnostic>

    public init(tokens: Tokens, diagnostics!: ArrayList<Diagnostic> = ArrayList<Diagnostic>()) {
        this.cursor = TokenCursor(tokens)
        this.diagnostics = diagnostics
    }

    public func reportError(message: String): Unit {
        let pos = min(cursor.pos, max(0, cursor.tokens.size - 1))
        reportError(message, "function contract", cursor.tokens[pos..min(pos + 1, cursor.tokens.size)])
    }

    public func reportError(message: String, category: String, tokens: Tokens): Unit {
        diagnostics.add(Diagnostic(message, category, tokens))
    }
}
