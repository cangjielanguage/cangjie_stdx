/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.tokens

import std.ast.{Token, TokenKind, Tokens}
import std.collection.{ArrayList}

/**
 * @brief A sequential cursor over a token stream, used to parse declaration text.
 *
 * It supports lookahead matching, ordered consumption of token kinds or text, and
 * skipping of the separators between contract clauses.
 *
 * Internal helper for macro expansion; not part of the public documentation API.
 */
public class TokenCursor {
    /**
     * @brief The token stream the cursor walks.
     */
    public let tokens: Tokens
    /**
     * @brief The current cursor position, as an index into `tokens`.
     */
    public var pos: Int64 = 0

    /**
     * @brief Creates a cursor positioned at the start of the token stream.
     *
     * @param tokens The token stream to walk.
     */
    public init(tokens: Tokens) {
        this.tokens = tokens
    }

    /**
     * @brief Tells whether the cursor has reached the end of the token stream.
     *
     * @return `true` when the position is at or beyond the stream size.
     */
    public func atEnd(): Bool {
        pos >= tokens.size
    }

    /**
     * @brief Reads the current token.
     *
     * The caller must ensure the cursor is not at end.
     *
     * @return The token at the current position.
     */
    public func current(): Token {
        tokens[pos]
    }

    /**
     * @brief Matches a token at a nonnegative offset without consuming it.
     *
     * @param kind The token kind to match.
     * @param offset The nonnegative lookahead offset relative to the current position.
     * @param value When supplied, the token text must also equal it.
     * @return `true` when the token at the offset matches; missing tokens never match.
     */
    public func matches(kind: TokenKind, offset!: Int64 = 0, value!: ?String = None): Bool {
        if (offset < 0 || offset >= tokens.size - pos) {
            return false
        }
        let token = tokens[pos + offset]
        token.kind == kind && (value.map {expected => token.value == expected} ?? true)
    }

    /**
     * @brief Consumes all remaining tokens, preserving newlines and semicolons.
     *
     * @return The tokens from the current position to the end of the stream.
     */
    public func takeRest(): Tokens {
        let rest = tokens[pos..tokens.size]
        pos = tokens.size
        rest
    }

    /**
     * @brief Advances by one token without skipping separators.
     */
    public func step(): Unit {
        pos += 1
    }

    /**
     * @brief Advances past the line breaks at the current position.
     */
    public func skipNewLine(): Unit {
        pos = skipNewLine(tokens, pos)
    }

    /**
     * @brief Skips the newline and semicolon separators between contract clauses.
     */
    public func skipClauseSeparators(): Unit {
        pos = skipSeparators(tokens, pos)
    }

    /**
     * @brief Consumes the current token when its text matches.
     *
     * @param value The token text to match.
     * @return `true` when the token was consumed; otherwise the position is left
     * unchanged.
     */
    public func consumeValue(value: String): Bool {
        if (!atEnd() && current().value == value) {
            forward()
            return true
        }
        false
    }

    /**
     * @brief Consumes the exact sequence of token kinds in order.
     *
     * @param kinds The token kinds to consume, in order.
     * @return The consumed tokens, or `None` when the sequence does not match; the
     * position is then left unchanged.
     */
    public func consumeKinds(kinds: Array<TokenKind>): ?ArrayList<Token> {
        let start = pos // cjlint-ignore !G.VAR.02 the entry position must survive the loop so a failed match can roll back
        let consumed = ArrayList<Token>()
        for (kind in kinds) {
            if (matches(kind)) {
                consumed.add(current())
                forward()
            } else {
                pos = start
                return None
            }
        }
        Some(consumed)
    }

    /**
     * @brief Advances by one token, then skips the following newlines.
     */
    public func forward(): Unit {
        step()
        skipNewLine()
    }

    /**
     * @brief Consumes the current token when its kind matches, then skips newlines.
     *
     * @param kind The token kind to match.
     * @return The consumed token, or `None` when it does not match; the position is then
     * left unchanged.
     */
    public func consumeKind(kind: TokenKind): ?Token {
        if (matches(kind)) {
            let token = current()
            forward()
            return Some(token)
        }
        None
    }
}
