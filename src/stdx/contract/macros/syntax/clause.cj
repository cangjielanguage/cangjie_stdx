/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.syntax

import std.ast.{Tokens}
import std.collection.{ArrayList}

/**
 * @brief A parsed `requires` clause: a precondition checked before the callable body
 * runs.
 *
 * The optional `name` labels the clause so that selective inheritance can reference it.
 */
public class RequiresClause <: SyntaxNode {
    /**
     * @brief The clause label, or `None` when the clause is unlabeled.
     */
    public var name: ?IdentifierSyntax
    /**
     * @brief The precondition expression; the check passes when it evaluates to true.
     */
    public var condition: ExprSyntax
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
     * @brief Builds a `requires` clause node.
     *
     * @param condition The precondition expression.
     * @param tokens The source tokens this clause covers.
     * @param name The clause label, or `None` when the clause is unlabeled.
     */
    public init(condition: ExprSyntax, tokens: Tokens, name!: ?IdentifierSyntax = None) {
        this.name = name
        this.condition = condition
        this._tokens = tokens
    }
}

/**
 * @brief A parsed `ensures` clause: a postcondition checked after the callable body
 * runs.
 *
 * `ret` names the result value when the user writes `ensures(name)`. The condition may
 * reference `$pre(expr)` snapshots, so it is modeled as an `ExprWithPreSyntax`.
 */
public class EnsuresClause <: SyntaxNode {
    /**
     * @brief The clause label, or `None` when the clause is unlabeled.
     */
    public var name: ?IdentifierSyntax
    /**
     * @brief The name bound to the result value inside the condition, or `None` when the
     * condition does not reference it.
     */
    public var ret: ?IdentifierSyntax
    /**
     * @brief The postcondition expression; the check passes when it evaluates to true.
     */
    public var condition: ExprWithPreSyntax
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
     * @brief Builds an `ensures` clause node.
     *
     * @param ret The name bound to the result value, or `None` when absent.
     * @param condition The postcondition expression.
     * @param tokens The source tokens this clause covers.
     * @param name The clause label, or `None` when the clause is unlabeled.
     */
    public init(ret: ?IdentifierSyntax, condition: ExprWithPreSyntax, tokens: Tokens,
        name!: ?IdentifierSyntax = None) {
        this.name = name
        this.ret = ret
        this.condition = condition
        this._tokens = tokens
    }
}

/**
 * @brief A parsed `throws` clause: an exceptional postcondition of the form
 * `throws <ExceptionType> if <condition>`.
 *
 * The check passes when the callable throws an exception of (or assignable to)
 * `exception` and `condition` holds for that exception.
 */
public class ThrowsClause <: SyntaxNode {
    /**
     * @brief The clause label, or `None` when the clause is unlabeled.
     */
    public var name: ?IdentifierSyntax
    /**
     * @brief The exception type this clause admits.
     */
    public var exception: TypeSyntax
    /**
     * @brief The condition evaluated when such an exception is thrown; the check passes
     * when it evaluates to true.
     */
    public var condition: ExprSyntax
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
     * @brief Builds a `throws` clause node.
     *
     * @param exception The exception type this clause admits.
     * @param condition The condition evaluated when the exception is thrown.
     * @param tokens The source tokens this clause covers.
     * @param name The clause label, or `None` when the clause is unlabeled.
     */
    public init(exception: TypeSyntax, condition: ExprSyntax, tokens: Tokens,
        name!: ?IdentifierSyntax = None) {
        this.name = name
        this.exception = exception
        this.condition = condition
        this._tokens = tokens
    }
}

/**
 * @brief Visibility selector of a type `invariant` clause, written as `on_public`,
 * `on_protected`, or `on_private` before the condition.
 *
 * The selector sets the visibility threshold of the generated checks: `OnPublic` checks
 * only public members, `OnProtected` additionally covers protected members, and
 * `OnPrivate` additionally covers private members. A missing selector (i.e. `None` in
 * `InvariantClause.visibility`) also covers package-level (internal) members.
 */
public enum InvariantVisibility {
    | OnPublic
    | OnProtected
    | OnPrivate
}

/**
 * @brief A parsed `invariant` clause of a type contract: a condition that must hold for
 * the type's members as guarded by the generated checks.
 *
 * `isStatic` marks an invariant declared inside a `static` context, and `visibility`
 * restricts which members the checks apply to.
 */
public class InvariantClause <: SyntaxNode {
    /**
     * @brief The clause label, or `None` when the clause is unlabeled.
     */
    public var name: ?IdentifierSyntax
    /**
     * @brief Whether the invariant is declared `static`.
     */
    public var isStatic: Bool
    /**
     * @brief The visibility selector before the condition, or `None` when the invariant
     * applies regardless of visibility.
     */
    public var visibility: ?InvariantVisibility
    /**
     * @brief The invariant condition; `$pre` snapshots are rejected here, so `pre` is
     * always empty on this node.
     */
    public var condition: ExprWithPreSyntax
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
     * @brief Builds an `invariant` clause node.
     *
     * @param isStatic Whether the invariant is declared `static`.
     * @param visibility The visibility selector, or `None` when absent.
     * @param condition The invariant condition.
     * @param tokens The source tokens this clause covers.
     * @param name The clause label, or `None` when the clause is unlabeled.
     */
    public init(isStatic: Bool, visibility: ?InvariantVisibility, condition: ExprWithPreSyntax, tokens: Tokens,
        name!: ?IdentifierSyntax = None) {
        this.name = name
        this.isStatic = isStatic
        this.visibility = visibility
        this.condition = condition
        this._tokens = tokens
    }
}

/**
 * @brief A selective inheritance reference: `<type>.<name>` or `<new-name> = <type>.<name>`.
 *
 * `ByType` carries only a parent type (`inherits from <type>`); `ByMember` additionally
 * names the parent's member being inherited; for `ByRename` the second field is the new
 * local name and the third is the parent's member name being renamed (bound as
 * `memberName` at match sites).
 */
public enum TypeInheritTarget {
    | ByType(TypeSyntax)
    | ByMember(TypeSyntax, IdentifierSyntax)
    | ByRename(TypeSyntax, IdentifierSyntax, IdentifierSyntax)

    /**
     * @brief The parent type this reference points at, regardless of the case.
     *
     * @return The type carried by the first field of the selected case.
     */
    public func getType(): TypeSyntax {
        match (this) {
            case ByType(ty) => ty
            case ByMember(ty, _) => ty
            case ByRename(ty, _, _) => ty
        }
    }
}

/**
 * @brief A parsed `inherits from <type> [conforming]` clause of a type contract: the
 * parent type whose contract is inherited.
 *
 * `isConforming` reflects the `[conforming]` modifier: the parent is a conforming parent
 * and the inherited rules are restricted to its members, while overrides of other
 * parents may still strengthen their preconditions.
 */
public class TypeInheritsClause <: SyntaxNode {
    /**
     * @brief The parent type whose contract is inherited; parsing always produces
     * `TypeInheritTarget.ByType` for this clause.
     */
    public var target: TypeInheritTarget
    /**
     * @brief Whether the `[conforming]` modifier is present.
     */
    public var isConforming: Bool
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
     * @brief Builds an `inherits from` clause node.
     *
     * @param target The parent type whose contract is inherited.
     * @param tokens The source tokens this clause covers.
     * @param isConforming Whether the `[conforming]` modifier is present.
     */
    public init(target: TypeInheritTarget, tokens: Tokens, isConforming!: Bool = false) {
        this.target = target
        this.isConforming = isConforming
        this._tokens = tokens
    }
}

/**
 * @brief A parsed `variable` clause: a contract-local declaration of the form
 * `variable <name>: <Type> (= <init>)?`.
 *
 * Variable clauses are accepted in both callable and type contracts; `isStatic` marks
 * the `static` form used in type contracts.
 */
public class VariableClause <: SyntaxNode {
    /**
     * @brief Whether the variable is declared `static` (type contracts only).
     */
    public var isStatic: Bool
    /**
     * @brief The declared variable name.
     */
    public var name: IdentifierSyntax
    /**
     * @brief The declared variable type.
     */
    public var ty: TypeSyntax
    /**
     * @brief The initializer expression after `=`, or `None` when the clause omits it.
     */
    public var initExpr: ?ExprSyntax
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
     * @brief Builds a `variable` clause node.
     *
     * @param isStatic Whether the variable is declared `static`.
     * @param name The declared variable name.
     * @param ty The declared variable type.
     * @param initExpr The initializer expression, or `None` when absent.
     * @param tokens The source tokens this clause covers.
     */
    public init(isStatic: Bool, name: IdentifierSyntax, ty: TypeSyntax, initExpr: ?ExprSyntax, tokens: Tokens) {
        this.isStatic = isStatic
        this.name = name
        this.ty = ty
        this.initExpr = initExpr
        this._tokens = tokens
    }
}

/**
 * @brief One clause of a type contract, as written inside `@Contract[...]` on a type
 * declaration.
 *
 * `Invariant` carries an `invariant` condition, `Variable` carries a contract-local
 * `variable` declaration, `Inherits` carries `inherits from <type> [conforming]`, and
 * `InvariantInherit` carries `inherits invariant <type>.<name>` (optionally renamed via
 * `<new-name> = <type>.<name>`).
 */
public enum TypeClause {
    | Invariant(InvariantClause)
    | Variable(VariableClause)
    | Inherits(TypeInheritsClause)
    | InvariantInherit(TypeInheritTarget)
}

/**
 * @brief The property accessor a `PropClause` belongs to.
 *
 * `Getter` covers clauses written for the `get` accessor and `Setter` those for the
 * `set` accessor; the two accessors use distinct name spaces for clause labels.
 */
public enum PropKind {
    | Getter
    | Setter
}

/**
 * @brief The contract clauses of one property accessor (`get` or `set`).
 *
 * A property contract groups function-level clauses per accessor: `kind` selects the
 * accessor and `clauses` lists the clauses written for it.
 */
public class PropClause <: SyntaxNode {
    /**
     * @brief The accessor these clauses belong to.
     */
    public var kind: PropKind
    /**
     * @brief The function-level clauses written for this accessor.
     */
    public var clauses: ArrayList<FunctionClause>
    private let _tokens: Tokens

    /**
     * @brief The source tokens this clause group was parsed from.
     */
    public prop tokens: Tokens {
        get() {
            _tokens
        }
    }

    /**
     * @brief Builds a property accessor clause group.
     *
     * @param kind The accessor these clauses belong to.
     * @param clauses The function-level clauses written for this accessor.
     * @param tokens The source tokens this node covers.
     */
    public init(kind: PropKind, clauses: ArrayList<FunctionClause>, tokens: Tokens) {
        this.kind = kind
        this.clauses = clauses
        this._tokens = tokens
    }
}
