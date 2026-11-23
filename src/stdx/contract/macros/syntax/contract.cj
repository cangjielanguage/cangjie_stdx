/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.syntax

import std.ast.{Decl, Tokens}
import std.collection.{ArrayList}

/**
 * @brief Which function-level contract a selective inheritance clause refers to.
 *
 * `Requires`, `Ensures`, and `Throws` select preconditions, postconditions, and
 * exceptional postconditions; `Variable` selects inherited contract-local variable
 * declarations.
 */
public enum InheritClauseKind {
    | Requires
    | Ensures
    | Throws
    | Variable
}

/**
 * @brief A parsed selective inheritance clause of a callable contract:
 * `requires/ensures/throws/variable <type>.<name>` or `<new-name> = <type>.<name>`.
 *
 * `kind` selects which clause kind is inherited and `target` references the parent
 * declaration's member; it is resolved against the enclosing type contract's `inherits`
 * parents during macro expansion.
 */
public class FunctionInheritClause <: SyntaxNode {
    /**
     * @brief The function-level clause kind being inherited.
     */
    public var kind: InheritClauseKind
    /**
     * @brief The reference to the parent declaration's member or type.
     */
    public var target: TypeInheritTarget
    private let _tokens: Tokens

    /**
     * @brief The source tokens this clause was parsed from.
     */
    public prop tokens: Tokens {
        get() {
            _tokens
        }
    }

    /**
     * @brief Builds a selective inheritance clause node.
     *
     * @param kind The function-level clause kind being inherited.
     * @param target The reference to the parent declaration's member or type.
     * @param tokens The source tokens this clause covers.
     */
    public init(kind: InheritClauseKind, target: TypeInheritTarget, tokens: Tokens) {
        this.kind = kind
        this.target = target
        this._tokens = tokens
    }
}

/**
 * @brief One clause of a function contract, as written inside `@Contract[...]` on a
 * callable or a property accessor.
 *
 * `Requires`, `Ensures`, `Throws`, and `Variable` carry clauses written in place;
 * `Inherit` carries a selective inheritance clause referencing a parent declaration's
 * contract.
 */
public enum FunctionClause {
    | Requires(RequiresClause)
    | Ensures(EnsuresClause)
    | Throws(ThrowsClause)
    | Variable(VariableClause)
    | Inherit(FunctionInheritClause)
}

/**
 * @brief The parsed contract of a function or constructor.
 *
 * Produced by parsing the clause list of `@Contract[...]` on a callable; validation
 * checks it against the annotated declaration and macro-expansion generation embeds the
 * checks into the callable body.
 */
public class FunctionContract <: SyntaxNode {
    /**
     * @brief The clauses written in the contract, in source order.
     */
    public var clauses: ArrayList<FunctionClause>
    private let _tokens: Tokens

    /**
     * @brief The source tokens this contract was parsed from.
     */
    public prop tokens: Tokens {
        get() {
            _tokens
        }
    }

    /**
     * @brief Creates an empty contract anchored to the given tokens.
     *
     * @param tokens The source tokens this contract covers.
     */
    public init(tokens: Tokens) {
        this.clauses = ArrayList<FunctionClause>()
        this._tokens = tokens
    }
}

/**
 * @brief The parsed contract of a property.
 *
 * Clauses are grouped per accessor (`get`/`set`) as `PropClause` entries; validation
 * checks them against the property declaration and generation embeds the checks into
 * the accessors.
 */
public class PropContract <: SyntaxNode {
    /**
     * @brief The per-accessor clause groups written in the contract.
     */
    public var clauses: ArrayList<PropClause>
    private let _tokens: Tokens

    /**
     * @brief The source tokens this contract was parsed from.
     */
    public prop tokens: Tokens {
        get() {
            _tokens
        }
    }

    /**
     * @brief Creates an empty contract anchored to the given tokens.
     *
     * @param tokens The source tokens this contract covers.
     */
    public init(tokens: Tokens) {
        this.clauses = ArrayList<PropClause>()
        this._tokens = tokens
    }
}

/**
 * @brief The parsed contract of a class, struct, interface, or extend declaration.
 *
 * Type-level clauses (`invariant`, `variable`, `inherits`) are validated against the
 * type, and inherited contracts are expanded into members during macro expansion.
 */
public class TypeContract <: SyntaxNode {
    /**
     * @brief The type-level clauses written in the contract.
     */
    public var clauses: ArrayList<TypeClause>
    private let _tokens: Tokens

    /**
     * @brief The source tokens this contract was parsed from.
     */
    public prop tokens: Tokens {
        get() {
            _tokens
        }
    }

    /**
     * @brief Creates an empty contract anchored to the given tokens.
     *
     * @param tokens The source tokens this contract covers.
     */
    public init(tokens: Tokens) {
        this.clauses = ArrayList<TypeClause>()
        this._tokens = tokens
    }
}

/**
 * @brief The contract syntax selected by a `@Contract` declaration.
 *
 * `Callable` wraps a function or constructor contract, `Property` wraps a property
 * contract, `TypeLevel` wraps a type contract, and `Empty` means the declaration carries
 * no clauses.
 */
public enum ContractSyntax {
    | Callable(FunctionContract)
    | Property(PropContract)
    | TypeLevel(TypeContract)
    | Empty
}

/**
 * @brief An annotated declaration paired with its parsed contract syntax.
 *
 * This is the unit handed from parsing to validation and generation: `declaration` is
 * the SDK declaration the `@Contract` macro was applied to, `contract` is the parsed
 * clause tree, and `tokens` are the source tokens of the contract text.
 */
public class ContractDeclaration {
    /**
     * @brief The declaration the `@Contract` macro was applied to.
     */
    public let declaration: Decl
    /**
     * @brief The parsed contract syntax of the declaration.
     */
    public let contract: ContractSyntax
    /**
     * @brief The source tokens of the contract text.
     */
    public let tokens: Tokens

    /**
     * @brief Pairs a declaration with its parsed contract.
     *
     * @param declaration The declaration the `@Contract` macro was applied to.
     * @param contract The parsed contract syntax of the declaration.
     * @param tokens The source tokens of the contract text.
     */
    public init(declaration: Decl, contract: ContractSyntax, tokens: Tokens) {
        this.declaration = declaration
        this.contract = contract
        this.tokens = tokens
    }
}

/**
 * @brief The parsed body of a `@ghost` block.
 *
 * Ghost code is auxiliary logic that executes only when contract checking is enabled and
 * the current execution is not inside contract-expression evaluation. The node carries
 * only the source tokens; generation preserves the body as written and lowers it behind
 * the contract eligibility gate.
 */
public class GhostBlock <: SyntaxNode {
    private let _tokens: Tokens

    /**
     * @brief The source tokens of the ghost body.
     */
    public prop tokens: Tokens {
        get() {
            _tokens
        }
    }

    /**
     * @brief Builds a ghost block from its source tokens.
     *
     * @param tokens The source tokens of the ghost body.
     */
    public init(tokens: Tokens) {
        this._tokens = tokens
    }
}

/**
 * @brief The parsed body of a `@contractAssert` block.
 *
 * `conditions` lists the assertion expressions written in the block (separated by
 * whitespace or `;`); when checking is enabled and one of them evaluates to false, the
 * generated code throws `ContractCheckAssertException`.
 */
public class AssertBlock <: SyntaxNode {
    /**
     * @brief The assertion expressions written in the block.
     */
    public let conditions: ArrayList<ExprSyntax>
    private let _tokens: Tokens

    /**
     * @brief The source tokens of the assertion block.
     */
    public prop tokens: Tokens {
        get() {
            _tokens
        }
    }

    /**
     * @brief Builds an assertion block from its conditions and source tokens.
     *
     * @param conditions The assertion expressions written in the block.
     * @param tokens The source tokens of the assertion block.
     */
    public init(conditions: ArrayList<ExprSyntax>, tokens: Tokens) {
        this.conditions = conditions
        this._tokens = tokens
    }
}

/**
 * @brief The parsed body of a `@loopInvariant[...](...)` macro application.
 *
 * `definitions` lists the invariant expressions written in `[]` and `loop` is the loop
 * expression wrapped in `()` (a `for-in`, `while`, or `do-while` expression); generation
 * checks the invariants around the loop according to its kind.
 */
public class LoopInvariant <: SyntaxNode {
    /**
     * @brief The invariant expressions written in `[]`.
     */
    public let definitions: ArrayList<ExprSyntax>
    /**
     * @brief The loop expression wrapped in `()`.
     */
    public let loop: ExprSyntax
    private let _tokens: Tokens
    private let _bodyTokens: Tokens

    /**
     * @brief The source tokens of the invariant definitions.
     */
    public prop tokens: Tokens {
        get() {
            _tokens
        }
    }

    /**
     * @brief Builds a loop invariant node.
     *
     * @param definitions The invariant expressions written in `[]`.
     * @param loop The loop expression wrapped in `()`.
     * @param tokens The source tokens of the invariant definitions.
     * @param bodyTokens The source tokens of the loop expression.
     */
    public init(definitions: ArrayList<ExprSyntax>, loop: ExprSyntax, tokens: Tokens, bodyTokens: Tokens) {
        this.definitions = definitions
        this.loop = loop
        this._tokens = tokens
        this._bodyTokens = bodyTokens
    }
}
