/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.syntax

import std.ast.{Expr, Tokens, TypeNode}
import std.collection.{ArrayList}

/**
 * @brief The common interface of all syntax nodes produced by parsing contract clause
 * input.
 *
 * Parse stages of the macro pipeline build these nodes from tokens; validation and
 * macro-expansion generation stages consume them. Every node keeps the tokens it was
 * parsed from so diagnostics can point at the exact source text.
 */
public interface SyntaxNode {
    /**
     * @brief The source tokens this node was parsed from.
     */
    prop tokens: Tokens
}

/**
 * @brief An identifier appearing in a contract clause, e.g. a clause label, a `variable`
 * clause name, or a member name in a selective inheritance reference.
 */
public class IdentifierSyntax <: SyntaxNode {
    /**
     * @brief The identifier text without surrounding tokens.
     */
    public var name: String
    private let _tokens: Tokens

    /**
     * @brief The source tokens this identifier was parsed from.
     */
    public prop tokens: Tokens {
        get() {
            _tokens
        }
    }

    /**
     * @brief Builds an identifier node from its text and source tokens.
     *
     * @param name The identifier text.
     * @param tokens The source tokens this node covers.
     */
    public init(name: String, tokens: Tokens) {
        this.name = name
        this._tokens = tokens
    }
}

/**
 * @brief A type reference appearing in a contract clause, e.g. the exception type of a
 * `throws` clause or the parent type of an `inherits` clause.
 *
 * When the tokens fail to parse as a type, `parsed` is `None` while the raw tokens stay
 * available for diagnostics.
 */
public class TypeSyntax <: SyntaxNode {
    /**
     * @brief The parsed type tree, or `None` when the tokens failed to parse.
     */
    public var parsed: Option<TypeNode>
    private let _tokens: Tokens

    /**
     * @brief The source tokens this type reference was parsed from.
     */
    public prop tokens: Tokens {
        get() {
            _tokens
        }
    }

    /**
     * @brief Builds a type node from its source tokens and parsed tree.
     *
     * @param tokens The source tokens this node covers.
     * @param parsed The parsed type tree, or `None` when parsing failed.
     */
    public init(tokens: Tokens, parsed: Option<TypeNode>) {
        this._tokens = tokens
        this.parsed = parsed
    }
}

/**
 * @brief An expression appearing in a contract clause, e.g. a `requires` condition or a
 * `variable` initializer.
 *
 * When the tokens fail to parse, `parsed` is `None` while the raw tokens stay available
 * for diagnostics.
 */
public class ExprSyntax <: SyntaxNode {
    /**
     * @brief The parsed expression, or `None` when the tokens failed to parse.
     */
    public let parsed: ?Expr
    private let _tokens: Tokens

    /**
     * @brief The source tokens this expression was parsed from.
     */
    public prop tokens: Tokens {
        get() {
            _tokens
        }
    }

    /**
     * @brief Builds an expression node from its source tokens and parsed expression.
     *
     * @param tokens The source tokens this node covers.
     * @param parsed The parsed expression, or `None` when parsing failed.
     */
    public init(tokens: Tokens, parsed: ?Expr) {
        this._tokens = tokens
        this.parsed = parsed
    }
}

/**
 * @brief A clause condition that may reference `$pre(expr)` snapshots; used for `ensures`
 * conditions and, with an empty `pre`, for `invariant` conditions.
 *
 * During parsing of an `ensures` condition every `$pre(expr)` call is replaced by a
 * synthetic `_pre_<index>` identifier: `parseTokens` is the token stream containing
 * these placeholders and `pre` records each placeholder position together with its
 * snapshot argument, so generation can evaluate the snapshots before the condition and
 * use the recorded values in place of the placeholders. A condition without `$pre`
 * yields an empty `pre` and `parseTokens` equal to `tokens`; `$pre` is rejected in
 * `invariant` conditions, whose nodes always carry an empty `pre`.
 */
public class ExprWithPreSyntax <: SyntaxNode {
    /**
     * @brief The parsed condition over `parseTokens`, or `None` when parsing failed.
     */
    public let parsed: ?Expr
    /**
     * @brief The token stream actually parsed, with each `$pre(expr)` call replaced by a
     * `_pre_<index>` placeholder identifier.
     */
    public let parseTokens: Tokens
    /**
     * @brief One entry per `$pre` snapshot: the index in `parseTokens` where the
     * placeholder identifier sits, and the snapshot argument expression.
     */
    public let pre: ArrayList<(Int64, ExprSyntax)>
    private let _tokens: Tokens

    /**
     * @brief The original source tokens, before `$pre` substitution.
     */
    public prop tokens: Tokens {
        get() {
            _tokens
        }
    }

    /**
     * @brief Builds a snapshot-aware condition node.
     *
     * @param tokens The original source tokens, before `$pre` substitution.
     * @param parsed The parsed condition over `parseTokens`, or `None` when parsing
     * failed.
     * @param parseTokens The token stream actually parsed, with `$pre` placeholders.
     * @param pre The recorded `$pre` snapshots as `(index in parseTokens, argument)`
     * pairs.
     */
    public init(tokens: Tokens, parsed: ?Expr, parseTokens: Tokens, pre: ArrayList<(Int64, ExprSyntax)>) {
        this._tokens = tokens
        this.parsed = parsed
        this.parseTokens = parseTokens
        this.pre = pre
    }
}
