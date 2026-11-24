/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.inheritance

import stdx.contract.macros.parse.{parseClassContract, parseFunctionContract, parsePropertyContract}
import stdx.contract.macros.syntax.{Diagnostic, FunctionClause, FunctionInheritClause, IdentifierSyntax, InheritClauseKind, InvariantVisibility, PropKind, TypeClause, TypeInheritTarget}
import stdx.contract.macros.tokens.{isValue, rewriteStringInterpolation, tokenValuesCompactString}
import std.ast.{Decl, Token, TokenKind, Tokens, TypeNode, cangjieLex, parseType}
import std.collection.{ArrayList, HashMap, HashSet, contains, isEmpty}

/// Substitute formal type parameter names once; arguments are not rewritten again.
/// Substitution is token-level: member accesses (`x.T`) and named-argument labels (`f(T: 1)`)
/// are excluded, other non-type contexts are not, so callers must only pass type-bearing streams.
func substituteTypeArguments(tokens: Tokens, parameters: ArrayList<String>, arguments: ArrayList<TypeNode>): Tokens {
    let result = Tokens()
    var previous = TokenKind.ILLEGAL
    var index = 0
    while (index < tokens.size) {
        let token = tokens[index]
        var replaced = false
        if (token.kind == IDENTIFIER && previous != DOT && !followedByColon(tokens, index)) {
            if (let Some(replacement) <- substitutedIdentifier(token, parameters, arguments)) {
                result.append(replacement)
                replaced = true
            }
        }
        if (!replaced) {
            result.append(token)
        }
        if (token.kind != NL) {
            previous = token.kind
        }
        index += 1
    }
    result
}

/// The replacement tokens for an identifier naming the first matching formal type parameter,
/// or `None` when the identifier is not a formal type parameter.
private func substitutedIdentifier(token: Token, parameters: ArrayList<String>,
    arguments: ArrayList<TypeNode>): ?Tokens {
    for (parameterIndex in 0..parameters.size) {
        if (isValue(token, parameters[parameterIndex])) {
            return Some(arguments[parameterIndex].toTokens())
        }
    }
    None
}

/// A colon after an identifier makes it a label (`f(T: 1)`) or a map key, never a type.
func followedByColon(tokens: Tokens, index: Int64): Bool {
    var cursor = index + 1
    while (cursor < tokens.size && tokens[cursor].kind == NL) {
        cursor += 1
    }
    cursor < tokens.size && tokens[cursor].kind == COLON
}

/**
 * @brief Sanitize an arbitrary key or qualified type name into identifier characters so it
 * can take part in a generated checker name (`step(Int64)` -> `step_Int64_`).
 *
 * @param text Key or qualified type name to sanitize.
 * @return The text with every byte outside `[A-Za-z0-9_]` replaced by `_`.
 */
public func sanitizeCheckerPart(text: String): String {
    let builder = StringBuilder()
    for (byte in text.toArray()) {
        let keep = (byte >= 97 && byte <= 122) || (byte >= 65 && byte <= 90) ||
            (byte >= 48 && byte <= 57) || byte == 95 // a-z, A-Z, 0-9, '_'
        builder.append(if (keep) {
            String.fromUtf8([byte])
        } else {
            "_"
        })
    }
    builder.toString()
}

/// Whether a condition already consists of a checker call materialized by an earlier
/// inheritance generation (`this._contract_member_cond_...` or a bare static call); such
/// conditions are terminal and only their arguments are renamed further down the chain.
private func isCheckerCallCondition(tokens: Tokens): Bool {
    var index = 0
    while (index < tokens.size && tokens[index].kind == NL) {
        index += 1
    }
    if (index >= tokens.size) {
        return false
    }
    if (tokens[index].kind == TokenKind.THIS) {
        index += 1
        while (index < tokens.size && tokens[index].kind == NL) {
            index += 1
        }
        if (index >= tokens.size || tokens[index].kind != DOT) {
            return false
        }
        index += 1
        while (index < tokens.size && tokens[index].kind == NL) {
            index += 1
        }
    }
    index < tokens.size && tokens[index].kind == IDENTIFIER &&
        tokenText(tokens[index]).startsWith("_contract_member_cond_")
}

/// Whether the condition carries a `$pre(...)` snapshot reference. Snapshots bind values
/// before the body runs, which a checker method called from the post-state cannot receive,
/// so such conditions keep their textual replay.
private func conditionHasPre(tokens: Tokens): Bool {
    for (token in tokens) {
        if (token.kind == DOLLAR_IDENTIFIER && tokenText(token) == "$pre") {
            return true
        }
    }
    false
}

/// Whether an identifier naming one of `names` is read in a value position (not accessed
/// through a dot): such a condition references a function-level contract `variable` slot
/// that only exists inside the generated member body, so no checker can host it.
private func referencesAnyName(tokens: Tokens, names: HashSet<String>): Bool {
    if (names.isEmpty()) {
        return false
    }
    var previous = TokenKind.ILLEGAL
    for (index in 0..tokens.size) {
        let token = tokens[index]
        if (token.kind == IDENTIFIER && previous != DOT && names.contains(tokenText(token))) {
            return true
        }
        if (token.kind != NL) {
            previous = token.kind
        }
    }
    false
}

/**
 * @brief Whether a parent-side checker may be generated for the condition; the child-side
 * materialization uses the same predicate so both sides stay in lockstep.
 *
 * A condition is materializable when it is not already a checker call, carries no `$pre(...)`
 * snapshot reference, and reads no contract `variable` slot of the enclosing member.
 *
 * @param condition Clause condition tokens.
 * @param variableNames Names of contract `variable` slots the condition may read.
 * @return `true` when the condition can be replayed as a call to a generated checker.
 */
public func memberConditionIsMaterializable(condition: Tokens, variableNames: HashSet<String>): Bool {
    let referencesVariable = referencesAnyName(condition, variableNames)
    !isCheckerCallCondition(condition) && !conditionHasPre(condition) && !referencesVariable
}

/// Token-level parameter renaming for inherited clause text (#8): a parent parameter name
/// becomes the child's positional counterpart. Member accesses (`x.y`), labels and other
/// colon-followed identifiers (`[pos]`, `ret:`), and generated `_contract_*` names stay.
private func alphaRenameTokens(tokens: Tokens, renames: HashMap<String, String>): Tokens {
    if (renames.isEmpty()) {
        return tokens
    }
    let result = Tokens()
    var previous = TokenKind.ILLEGAL
    for (index in 0..tokens.size) {
        let token = tokens[index]
        // String interpolation is invisible at token level: renamed parameters inside
        // `${...}` would otherwise stay spelled with the parent's name.
        if (token.kind == STRING_LITERAL) {
            result.append(rewriteStringInterpolation(token, {inner => alphaRenameTokens(inner, renames)}))
            previous = token.kind
            continue
        }
        var replaced = false
        if (token.kind == IDENTIFIER && previous != DOT && !followedByColon(tokens, index) &&
            !tokenText(token).startsWith("_contract_")) {
            match (renames.get(tokenText(token))) {
                case Some(name) =>
                    result.append(Token(IDENTIFIER, name))
                    replaced = true
                case None => ()
            }
        }
        if (!replaced) {
            result.append(token)
        }
        if (token.kind != NL) {
            previous = token.kind
        }
    }
    result
}

/// The checker call replacing a materializable clause condition (#9): the ancestor's public
/// checker receives the child's arguments positionally (the method parameters, plus the
/// named result binding for `ensures`). Static ancestors call without a receiver.
func checkerCallTokens(checkerName: String, childParams: ArrayList<String>, instance: Bool,
    ret: ?IdentifierSyntax): Tokens {
    let call = Tokens()
    if (instance) {
        call.append(Token(TokenKind.THIS)).append(Token(DOT))
    }
    call.append(Token(IDENTIFIER, checkerName)).append(Token(LPAREN))
    var first = true
    for (name in childParams) {
        if (!first) {
            call.append(Token(COMMA))
        }
        first = false
        call.append(Token(IDENTIFIER, name))
    }
    if (let Some(binding) <- ret) {
        if (!first) {
            call.append(Token(COMMA))
        }
        call.append(binding.tokens)
    }
    call.append(Token(RPAREN))
    call
}

/// Inputs for adapting one inherited condition into the child scope.
class InheritConditionContext {
    let checkerBase: String
    let parentParams: ArrayList<String>
    let childParams: ArrayList<String>
    let instance: Bool
    let variableNames: HashSet<String>
    let renames: HashMap<String, String>

    init(checkerBase: String, parentParams: ArrayList<String>, childParams: ArrayList<String>,
        instance: Bool, variableNames: HashSet<String>, renames: HashMap<String, String>) {
        this.checkerBase = checkerBase
        this.parentParams = parentParams
        this.childParams = childParams
        this.instance = instance
        this.variableNames = variableNames
        this.renames = renames
    }
}

/// Adapt one inherited clause condition for the child scope. A condition that already is a
/// checker call stays (its arguments are renamed); otherwise the ancestor's public checker
/// replaces the text when a checker base is known and the parameter lists line up and the
/// condition carries neither `$pre` snapshots nor contract-variable references; every other
/// condition keeps its text with the parameters positionally renamed.
func adaptInheritedCondition(condition: Tokens, ret: ?IdentifierSyntax, ordinal: Int64,
    context: InheritConditionContext): Tokens {
    if (isCheckerCallCondition(condition)) {
        return alphaRenameTokens(condition, context.renames)
    }
    let materializable = memberConditionIsMaterializable(condition, context.variableNames)
    if (context.checkerBase != "" && context.parentParams.size == context.childParams.size &&
        materializable) {
        return checkerCallTokens(context.checkerBase + ordinal.toString(), context.childParams,
            context.instance, ret)
    }
    alphaRenameTokens(condition, context.renames)
}

/// Positional rename map from the parent's parameter names to the child's; empty when the
/// parameter lists differ (no reliable positional correspondence).
func inheritedRenameMap(parentParams: ArrayList<String>,
    childParams: ArrayList<String>): HashMap<String, String> {
    let renames = HashMap<String, String>()
    if (parentParams.size == childParams.size) {
        for (index in 0..parentParams.size) {
            renames.add(parentParams[index], childParams[index])
        }
    }
    renames
}

func inheritedConditionVariableNames(clauses: ArrayList<FunctionClause>): HashSet<String> {
    let variableNames = HashSet<String>()
    for (clause in clauses) {
        if (let FunctionClause.Variable(c) <- clause) {
            variableNames.add(c.name.name)
        }
    }
    variableNames
}

/// The value-bearing token stream of a clause (conditions and initializers); declarations
/// and inherit clauses carry no value references.
func clauseValueTokens(clause: FunctionClause): ?Tokens {
    match (clause) {
        case FunctionClause.Requires(c) => Some(c.condition.tokens)
        case FunctionClause.Ensures(c) => Some(c.condition.tokens)
        case FunctionClause.Throws(c) => Some(c.condition.tokens)
        case FunctionClause.Variable(c) =>
            match (c.initExpr) {
                case Some(initializer) => Some(initializer.tokens)
                case None => None
            }
        case FunctionClause.Inherit(_) => None
    }
}

/// Detect a rename that would capture a parent contract variable. Renaming the parent's
/// parameters positionally turns `requires x > y` into `requires y > y` when the child's
/// parameter is spelled like the parent's `variable y`; the reference now resolves to the
/// parameter instead of the inherited variable. Returns the first captured variable name.
func inheritedRenameCapture(parentParams: ArrayList<String>, childParams: ArrayList<String>,
    clauses: ArrayList<FunctionClause>): ?String {
    if (parentParams.size != childParams.size) {
        return None
    }
    let variableNames = inheritedConditionVariableNames(clauses)
    if (variableNames.isEmpty()) {
        return None
    }
    let captured = HashSet<String>()
    for (param in childParams) {
        if (variableNames.contains(param)) {
            captured.add(param)
        }
    }
    if (captured.isEmpty()) {
        return None
    }
    for (clause in clauses) {
        if (let Some(tokens) <- clauseValueTokens(clause)) {
            if (let Some(name) <- capturedNameInTokens(tokens, captured)) {
                return Some(name)
            }
        }
    }
    None
}

/// The first captured variable read as a value in `tokens`, if any.
private func capturedNameInTokens(tokens: Tokens, captured: HashSet<String>): ?String {
    for (name in captured) {
        let single = HashSet<String>()
        single.add(name)
        if (referencesAnyName(tokens, single)) {
            return Some(name)
        }
    }
    None
}

/// The parent member's raw clauses, recovered from its published attribute for a selective
/// inheritance reference. Empty when the key addresses no published function attribute.
func inheritedMemberClauses(meta: ContractMetaData, matchedKey: String): ArrayList<FunctionClause> {
    match (meta.memberAttrs.get(matchedKey)) {
        case Some(attr) =>
            let parsed = parseFunctionContract(attr)
            if (!parsed.hasError()) {
                return parsed.value.clauses
            }
        case None => ()
    }
    ArrayList<FunctionClause>()
}

/// Parameter-name lists of one inherited member on both sides of an inheritance edge.
class InheritedMemberParams {
    let parent: ArrayList<String>
    let child: ArrayList<String>

    init(parent: ArrayList<String>, child: ArrayList<String>) {
        this.parent = parent
        this.child = child
    }
}

/// Rebuild an inherited member attribute for the child scope: `requires`/`ensures` conditions
/// materialize as calls to the ancestor's public checkers where recorded (#9), all other
/// conditions and initializers keep their text with the parameters renamed (#8).
func adaptInheritedMemberAttrTokens(attr: Tokens, checkerBase: String, params: InheritedMemberParams,
    instance: Bool, diagnostics: ArrayList<Diagnostic>): Tokens {
    if (checkerBase == "" && params.parent.isEmpty()) {
        return attr
    }
    let parsed = parseFunctionContract(attr)
    if (parsed.hasError()) {
        return attr
    }
    if (let Some(captured) <- inheritedRenameCapture(params.parent, params.child, parsed.value.clauses)) {
        diagnostics.add(Diagnostic(
            "inherited contract variable `${captured}` is shadowed by the inheriting member's parameter of the same name",
            "contract inheritance", attr))
        return attr
    }
    let context = InheritConditionContext(checkerBase, params.parent, params.child, instance,
        inheritedConditionVariableNames(parsed.value.clauses), inheritedRenameMap(params.parent, params.child))
    let result = Tokens()
    var ordinal: Int64 = 0
    for (clause in parsed.value.clauses) {
        if (result.size > 0) {
            result.append(Token(SEMI))
        }
        result.append(adaptInheritedClause(clause, ordinal, context))
        match (clause) {
            case FunctionClause.Requires(_) => ordinal += 1
            case FunctionClause.Ensures(_) => ordinal += 1
            case _ => ()
        }
    }
    if (result.size == 0) {
        return attr
    }
    result
}

/// Rebuild one clause of an inherited member attribute with the parent's own parameter names.
func adaptInheritedClause(clause: FunctionClause, ordinal: Int64,
    context: InheritConditionContext): Tokens {
    let result = Tokens()
    match (clause) {
        case FunctionClause.Requires(c) =>
            result.append(Token(IDENTIFIER, "requires"))
            appendClauseLabel(result, c.name)
            result.append(adaptInheritedCondition(c.condition.tokens, None, ordinal, context))
        case FunctionClause.Ensures(c) =>
            result.append(Token(IDENTIFIER, "ensures"))
            appendClauseLabel(result, c.name)
            if (let Some(binding) <- c.ret) {
                result.append(binding.tokens).append(Token(COLON))
            }
            result.append(adaptInheritedCondition(c.condition.tokens, c.ret, ordinal, context))
        case FunctionClause.Throws(c) =>
            result.append(Token(IDENTIFIER, "throws"))
            appendClauseLabel(result, c.name)
            result.append(c.exception.tokens).append(Token(IF))
            result.append(alphaRenameTokens(c.condition.tokens, context.renames))
        case FunctionClause.Variable(c) =>
            result.append(Token(IDENTIFIER, "variable"))
            result.append(c.name.tokens)
            result.append(Token(COLON))
            result.append(c.ty.tokens)
            if (let Some(initializer) <- c.initExpr) {
                result.append(Token(ASSIGN))
                result.append(alphaRenameTokens(initializer.tokens, context.renames))
            }
        case FunctionClause.Inherit(c) => result.append(c.tokens)
    }
    result
}

/// Instantiate a parent's member attributes for one `inherits from` clause and adapt every
/// clause for the child scope (see `adaptInheritedMemberAttrTokens`).
internal func instantiateAdaptedMemberAttrs(meta: ContractMetaData, actual: ArrayList<TypeNode>,
    childParams: HashMap<String, (ArrayList<String>, Bool)>,
    diagnostics: ArrayList<Diagnostic>): HashMap<String, Tokens> {
    let result = HashMap<String, Tokens>()
    for ((formalKey, attr) in meta.memberAttrs) {
        let newKey = instantiateSignatureKey(formalKey, meta.typeArgs, actual)
        let instantiated = substituteValueTokens(attr, meta.typeArgs, actual, meta.valueNames)
        let parentParams = match (meta.memberParamNames.get(formalKey)) {
            case Some(names) => names
            case None => ArrayList<String>()
        }
        let checkerBase = match (meta.memberCheckerBases.get(formalKey)) {
            case Some(base) => base
            case None => ""
        }
        let child = match (childParams.get(newKey)) {
            case Some(value) => value
            case None => (ArrayList<String>(), false)
        }
        result.add(newKey, adaptInheritedMemberAttrTokens(instantiated, checkerBase,
            InheritedMemberParams(parentParams, child[0]), !child[1], diagnostics))
    }
    result
}

/// Propagate a parent's per-member parameter names under instantiated keys so grandchildren
/// keep renaming parameters positionally across generations.
internal func instantiateMemberParamNames(meta: ContractMetaData,
    actual: ArrayList<TypeNode>): HashMap<String, ArrayList<String>> {
    let result = HashMap<String, ArrayList<String>>()
    for ((formalKey, names) in meta.memberParamNames) {
        result.add(instantiateSignatureKey(formalKey, meta.typeArgs, actual), names)
    }
    result
}

/// Property-free counterpart of `instantiateMemberParamNames` for checker bases.
internal func instantiateMemberCheckerBases(meta: ContractMetaData,
    actual: ArrayList<TypeNode>): HashMap<String, String> {
    let result = HashMap<String, String>()
    for ((formalKey, base) in meta.memberCheckerBases) {
        result.add(instantiateSignatureKey(formalKey, meta.typeArgs, actual), base)
    }
    result
}

/// Substitute formal type parameters inside a VALUE-context token stream (a clause condition,
/// a thrown-expression check, or a variable initializer). An identifier that names a value of
/// the declaring parent (a field, a property, or a method parameter) refers to that value in
/// the clause, not to a type, so it stays untouched even when a formal type parameter happens
/// to share its spelling. Every other identifier is substituted as before, so type parameters
/// used as types inside conditions (`v is T`) still expand. An empty `valueNames` degrades to
/// the plain type-context substitution.
func substituteValueTokens(tokens: Tokens, parameters: ArrayList<String>, arguments: ArrayList<TypeNode>,
    valueNames: HashSet<String>): Tokens {
    if (valueNames.isEmpty()) {
        return substituteTypeArguments(tokens, parameters, arguments)
    }
    let result = Tokens()
    var previous = TokenKind.ILLEGAL
    var index = 0
    while (index < tokens.size) {
        let token = tokens[index]
        var replaced = false
        if (token.kind == IDENTIFIER && previous != DOT && !followedByColon(tokens, index) &&
            !valueNames.contains(tokenText(token))) {
            if (let Some(replacement) <- substitutedIdentifier(token, parameters, arguments)) {
                result.append(replacement)
                replaced = true
            }
        }
        if (!replaced) {
            result.append(token)
        }
        if (token.kind != NL) {
            previous = token.kind
        }
        index += 1
    }
    result
}

/// Instantiate a parent's member signature key for the concrete type arguments of an
/// `inherits from Parent<...>` clause: `f(T,Array<K>)` under `Parent<Int64,Bool>` becomes
/// `f(Int64,Array<Bool>)`, matching what `methodSignatureKey` records for the child's override.
func instantiateSignatureKey(key: String, parameters: ArrayList<String>, arguments: ArrayList<TypeNode>): String {
    if (parameters.isEmpty()) {
        return key
    }
    let tokens = Tokens()
    for (token in cangjieLex(key)) {
        if (token.kind != END && token.kind != NL && token.kind != SEMI) {
            tokens.append(token)
        }
    }
    tokenValuesCompactString(substituteTypeArguments(tokens, parameters, arguments))
}

/// Substitute formal type parameters in inherited member contract attributes: signature keys
/// instantiate as type contexts, while clause conditions are value contexts (see
/// `substituteValueTokens`), so the parent's value names must be passed in.
func instantiateMemberAttrs(attrs: HashMap<String, Tokens>, parameters: ArrayList<String>,
    arguments: ArrayList<TypeNode>, valueNames: HashSet<String>): HashMap<String, Tokens> {
    let result = HashMap<String, Tokens>()
    for ((key, attr) in attrs) {
        result.add(instantiateSignatureKey(key, parameters, arguments),
            substituteValueTokens(attr, parameters, arguments, valueNames))
    }
    result
}

/// Property attribute keys are plain names, but clause bodies may reference type parameters
/// and the parent's values.
func instantiatePropertyAttrs(attrs: HashMap<String, Tokens>, parameters: ArrayList<String>,
    arguments: ArrayList<TypeNode>, valueNames: HashSet<String>): HashMap<String, Tokens> {
    let result = HashMap<String, Tokens>()
    for ((name, attr) in attrs) {
        result.add(name, substituteValueTokens(attr, parameters, arguments, valueNames))
    }
    result
}

/// Instantiate the member keys of a provenance map; the owner/name maps are key-free.
func instantiateMemberAttrOrigins(origins: HashMap<String, HashMap<String, HashSet<String>>>,
    parameters: ArrayList<String>, arguments: ArrayList<TypeNode>):
    HashMap<String, HashMap<String, HashSet<String>>> {
    let result = HashMap<String, HashMap<String, HashSet<String>>>()
    for ((key, owners) in origins) {
        result.add(instantiateSignatureKey(key, parameters, arguments), owners)
    }
    result
}

/// Instantiate a parent's transitive member-signature set for one `inherits` clause.
func instantiateMemberSignatures(signatures: HashSet<String>, parameters: ArrayList<String>,
    arguments: ArrayList<TypeNode>): HashSet<String> {
    let result = HashSet<String>()
    for (signature in signatures) {
        result.add(instantiateSignatureKey(signature, parameters, arguments))
    }
    result
}

/// Rebuild the clause source with type parameters substituted; then reparse it so
/// tokens, AST and `$pre` snapshots stay consistent. Types substitute as type contexts,
/// while invariant conditions and initializers substitute as value contexts.
func substituteTypeClause(clause: TypeClause, parameters: ArrayList<String>, arguments: ArrayList<TypeNode>,
    valueNames: HashSet<String>): Tokens {
    let result = Tokens()
    match (clause) {
        case TypeClause.Variable(variable) =>
            if (variable.isStatic) {
                result.append(Token(IDENTIFIER, "static"))
            }
            result.append(Token(IDENTIFIER, "variable"))
            result.append(variable.name.tokens)
            result.append(Token(COLON))
            result.append(substituteTypeArguments(variable.ty.tokens, parameters, arguments))
            if (let Some(initializer) <- variable.initExpr) {
                result.append(Token(ASSIGN))
                result.append(substituteValueTokens(initializer.tokens, parameters, arguments, valueNames))
            }
        case TypeClause.Invariant(invariant) =>
            if (let Some(visibility) <- invariant.visibility) {
                result.append(
                    match (visibility) {
                        case InvariantVisibility.OnPublic => Token(IDENTIFIER, "on_public")
                        case InvariantVisibility.OnProtected => Token(IDENTIFIER, "on_protected")
                        case InvariantVisibility.OnPrivate => Token(IDENTIFIER, "on_private")
                    })
            }
            if (invariant.isStatic) {
                result.append(Token(IDENTIFIER, "static"))
            }
            result.append(Token(IDENTIFIER, "invariant"))
            if (let Some(name) <- invariant.name) {
                result.append(Token(LSQUARE)).append(name.tokens).append(Token(RSQUARE))
            }
            result.append(substituteValueTokens(invariant.condition.tokens, parameters, arguments, valueNames))
        case TypeClause.InvariantInherit(target) =>
            result.append(Token(IDENTIFIER, "inherits"))
            result.append(Token(IDENTIFIER, "invariant"))
            result.append(emitInheritTarget(target, parameters, arguments))
        case TypeClause.Inherits(_) => ()
    }
    result
}

/**
 * @brief Expand function-level `<clause> <type>.<name>` and `<new-name> = <type>.<name>`
 * references; the attribute is returned unchanged when it declares no inheritance.
 *
 * `memberKey` is the inheriting member's full signature key (`name(T1,T2)`) or property
 * name. `childParams` carries the inheriting method's ordered parameter names and staticness
 * so inherited conditions are renamed positionally (#8) and materialized as checker
 * calls (#9). Unmatched or ambiguous references are reported through `diagnostics`.
 *
 * @param attr Member contract attribute tokens.
 * @param memberKey Inheriting member's signature key or property name.
 * @param isProperty Whether `attr` follows the property-clause grammar.
 * @param owner Declaration that owns the inheriting member.
 * @param diagnostics Expansion diagnostics.
 * @param childParams Ordered parameter names of the inheriting method plus its staticness.
 * @return The rebuilt attribute tokens, or `attr` unchanged when nothing is inherited.
 */
public func expandMemberInherits(attr: Tokens, memberKey: String, isProperty: Bool, owner: Decl, // cjlint-ignore !G.FUN.01 public API signature is fixed
    diagnostics: ArrayList<Diagnostic>,
    childParams!: (ArrayList<String>, Bool) = (ArrayList<String>(), false)): Tokens {
    if (isProperty) {
        return expandPropertyInherits(attr, memberKey, owner, diagnostics)
    }
    let parsed = parseFunctionContract(attr)
    if (parsed.hasError()) {
        return attr
    }
    var hasInherit = false
    for (clause in parsed.value.clauses) {
        if (let FunctionClause.Inherit(_) <- clause) {
            hasInherit = true
            break
        }
    }
    if (!hasInherit) {
        return attr
    }
    let result = Tokens()
    for (clause in parsed.value.clauses) {
        match (clause) {
            case FunctionClause.Inherit(inherit) =>
                appendInheritedClause(result, expandInheritClause(inherit, InheritMemberSelector(memberKey, None),
                    owner, diagnostics, childParams: childParams))
            case _ => appendInheritedClause(result, functionClauseTokens(clause))
        }
    }
    result
}

func expandPropertyInherits(attr: Tokens, memberName: String, owner: Decl,
    diagnostics: ArrayList<Diagnostic>): Tokens {
    let parsed = parsePropertyContract(attr, setterAlias: "value")
    if (parsed.hasError()) {
        return attr
    }
    var hasInherit = false
    for (clause in parsed.value.clauses) {
        for (body in clause.clauses) {
            if (let FunctionClause.Inherit(_) <- body) {
                hasInherit = true
                break
            }
        }
        if (hasInherit) {
            break
        }
    }
    if (!hasInherit) {
        return attr
    }
    let result = Tokens()
    for (clause in parsed.value.clauses) {
        for (body in clause.clauses) {
            appendInheritedClause(result,
                expandPropertyClauseTokens(clause.kind, body, memberName, owner, diagnostics))
        }
    }
    result
}

/// Expand one accessor clause of an inherited property contract into tokens.
private func expandPropertyClauseTokens(kind: PropKind, body: FunctionClause, memberName: String,
    owner: Decl, diagnostics: ArrayList<Diagnostic>): Tokens {
    let expandedResult = Tokens()
    match (body) {
        case FunctionClause.Inherit(inherit) =>
            let expanded = expandInheritClause(inherit,
                InheritMemberSelector(memberName, Some(kind)), owner, diagnostics)
            if (expanded.size > 0) {
                appendInheritedClause(expandedResult, prefixPropertyClause(kind, expanded))
            }
        case _ =>
            appendInheritedClause(expandedResult, prefixPropertyClause(kind, functionClauseTokens(body)))
    }
    expandedResult
}

/// Identifies the inheriting member: its signature key (or property name) and, for property
/// clauses, the accessor kind being inherited.
class InheritMemberSelector {
    let key: String
    let kind: ?PropKind

    init(key: String, kind: ?PropKind) {
        this.key = key
        this.kind = kind
    }
}

/// Locate the referenced contract in the direct parent's published member attribute, substitute
/// type arguments, then rebuild the clause with the requested name. `selector.key` must equal the
/// parent's member signature key (function overloads) or the property name.
func expandInheritClause(inherit: FunctionInheritClause, selector: InheritMemberSelector, owner: Decl,
    diagnostics: ArrayList<Diagnostic>,
    childParams!: (ArrayList<String>, Bool) = (ArrayList<String>(), false)): Tokens {
    var targetName = ""
    var renamed: ?IdentifierSyntax = None
    match (inherit.target) {
        case TypeInheritTarget.ByMember(_, name) => targetName = name.name
        case TypeInheritTarget.ByRename(_, newName, memberName) =>
            targetName = memberName.name
            renamed = newName
        case TypeInheritTarget.ByType(_) => return Tokens()
    }
    let ty = inherit.target.getType()
    let (_, meta, actual) = match (parentMeta(ty, owner, diagnostics, inherit.tokens)) {
        case Some(value) => value
        case None => return Tokens()
    }
    var matched = ArrayList<FunctionClause>()
    var matchedKey = ""
    var matchedOrdinal: Int64 = 0
    match (selector.kind) {
        case Some(kind) => matched = matchPropertyInheritedClauses(meta, selector.key, kind, inherit, targetName)
        case None =>
            let (found, key, ordinal) = matchMethodInheritedClauses(meta, selector.key, actual, inherit, targetName)
            matched = found
            matchedKey = key
            matchedOrdinal = ordinal
    }
    if (!validateInheritedMatch(matched, ty.tokens, targetName, inherit, diagnostics)) {
        return Tokens()
    }
    let (parentParams, checkerBase) = inheritedCheckTarget(meta, matchedKey)
    let parentClauses = inheritedMemberClauses(meta, matchedKey)
    if (let Some(captured) <- inheritedRenameCapture(parentParams, childParams[0], parentClauses)) {
        diagnostics.add(Diagnostic(
            "inherited contract variable `${captured}` is shadowed by the inheriting member's parameter of the same name",
            "contract inheritance", inherit.tokens))
        return Tokens()
    }
    let renames = inheritedRenameMap(parentParams, childParams[0])
    rebuildInheritedClause(matched[0], renamed,
        RebuildClauseContext(meta.typeArgs, actual, meta.valueNames,
            inheritedConditionVariableNames(parentClauses), checkerBase, parentParams, childParams[0],
            !childParams[1], matchedOrdinal, renames))
}

/// Collect the parent property clauses of `kind` whose label or name matches the reference.
func matchPropertyInheritedClauses(meta: ContractMetaData, memberKey: String, kind: PropKind,
    inherit: FunctionInheritClause, targetName: String): ArrayList<FunctionClause> {
    let matched = ArrayList<FunctionClause>()
    let parentAttr = match (meta.propertyAttrs.get(memberKey)) {
        case Some(value) => value
        case None => return matched
    }
    let parsed = parsePropertyContract(parentAttr, setterAlias: "value")
    if (parsed.hasError()) {
        return matched
    }
    for (clause in parsed.value.clauses) {
        if (!samePropKind(clause.kind, kind)) {
            continue
        }
        for (body in clause.clauses) {
            if (matchesInheritKind(body, inherit.kind, targetName)) {
                matched.add(body)
            }
        }
    }
    matched
}

/// Whether a matched clause takes part in the `requires`/`ensures` ordinal numbering used by
/// generated checker names.
func isNumberedClause(clause: FunctionClause): Bool {
    match (clause) {
        case FunctionClause.Requires(_) => true
        case FunctionClause.Ensures(_) => true
        case _ => false
    }
}

/// Collect the parent function clauses of the exact signature match together with the key and
/// ordinal (among `requires`/`ensures`) that identify their generated checker.
func matchMethodInheritedClauses(meta: ContractMetaData, memberKey: String, actual: ArrayList<TypeNode>,
    inherit: FunctionInheritClause, targetName: String): (ArrayList<FunctionClause>, String, Int64) {
    let matched = ArrayList<FunctionClause>()
    var matchedKey = ""
    var matchedOrdinal: Int64 = 0
    for ((key, parentAttr) in meta.memberAttrs) {
        // Exact signature match: a clause attached to `f(String)` must not replay the
        // contract of an unrelated `f(Int64)` overload. The parent's key is written in
        // its formal type parameters, so instantiate it before comparing.
        if (instantiateSignatureKey(key, meta.typeArgs, actual) != memberKey) {
            continue
        }
        let parsed = parseFunctionContract(parentAttr) // cjlint-ignore !G.VAR.02 the parse result is shared by the error check and the clause collection; narrowing would force a re-parse
        if (parsed.hasError()) {
            continue
        }
        let (any, ordinal) = collectMethodMatchedClauses(parsed.value.clauses, inherit, targetName, matched) // cjlint-ignore !G.VAR.02 both values come from one call and are consumed by the branch below
        if (any) {
            matchedKey = key
            if (let Some(value) <- ordinal) {
                matchedOrdinal = value
            }
        }
    }
    (matched, matchedKey, matchedOrdinal)
}

/// Append the clauses of one parent attribute that match the reference. Returns whether any
/// clause matched and, if so, the ordinal of the last matching numbered clause.
private func collectMethodMatchedClauses(clauses: ArrayList<FunctionClause>,
    inherit: FunctionInheritClause, targetName: String,
    matched: ArrayList<FunctionClause>): (Bool, ?Int64) {
    // Ordinals count the parent attribute's `requires`/`ensures` clauses in order;
    // checker names use the same enumeration on both sides.
    var ordinal: Int64 = 0 // cjlint-ignore !G.VAR.02 the ordinal counts every clause in the loop, so it must outlive each iteration
    var matchedOrdinal: ?Int64 = None
    var any = false
    for (clause in clauses) {
        if (matchesInheritKind(clause, inherit.kind, targetName)) {
            matched.add(clause)
            any = true
            if (isNumberedClause(clause)) {
                matchedOrdinal = ordinal
            }
        }
        if (isNumberedClause(clause)) {
            ordinal += 1
        }
    }
    (any, matchedOrdinal)
}

/// Report an unmatched or ambiguous reference; returns whether exactly one clause was matched.
func validateInheritedMatch(matched: ArrayList<FunctionClause>, tyTokens: Tokens, targetName: String,
    inherit: FunctionInheritClause, diagnostics: ArrayList<Diagnostic>): Bool {
    if (matched.isEmpty()) {
        diagnostics.add(
            Diagnostic("no inherited contract matches the requested kind and name: `${tyTokens}.${targetName}`",
                "contract inheritance", inherit.tokens))
        return false
    }
    if (matched.size > 1) {
        diagnostics.add(
            Diagnostic("ambiguous inherited contract: multiple members declare the requested kind and name: `${tyTokens}.${targetName}`",
                "contract inheritance", inherit.tokens))
        return false
    }
    true
}

/// The matched parent member's recorded parameter names and checker base, if any.
func inheritedCheckTarget(meta: ContractMetaData, matchedKey: String): (ArrayList<String>, String) {
    let parentParams = match (meta.memberParamNames.get(matchedKey)) {
        case Some(names) => names
        case None => ArrayList<String>()
    }
    let checkerBase = match (meta.memberCheckerBases.get(matchedKey)) {
        case Some(base) => base
        case None => ""
    }
    (parentParams, checkerBase)
}

/// Inputs for rebuilding one inherited member contract clause in the child scope.
class RebuildClauseContext {
    let parameters: ArrayList<String>
    let arguments: ArrayList<TypeNode>
    let valueNames: HashSet<String>
    let inheritedVariableNames: HashSet<String>
    let checkerBase: String
    let parentParams: ArrayList<String>
    let childParams: ArrayList<String>
    let instance: Bool
    let ordinal: Int64
    let renames: HashMap<String, String>

    init(parameters: ArrayList<String>, arguments: ArrayList<TypeNode>, valueNames: HashSet<String>,
        inheritedVariableNames: HashSet<String>, checkerBase: String, parentParams: ArrayList<String>,
        childParams: ArrayList<String>, instance: Bool, ordinal: Int64, renames: HashMap<String, String>) {
        this.parameters = parameters
        this.arguments = arguments
        this.valueNames = valueNames
        this.inheritedVariableNames = inheritedVariableNames
        this.checkerBase = checkerBase
        this.parentParams = parentParams
        this.childParams = childParams
        this.instance = instance
        this.ordinal = ordinal
        this.renames = renames
    }
}

/// Rebuild one inherited member contract clause with the child's type arguments. Clause
/// conditions and initializers are value contexts, so the parent's value names are kept;
/// the declared type of an inherited `variable` clause stays a type context. Parameters are
/// renamed positionally (#8) before the type-argument substitution, and materializable
/// `requires`/`ensures` conditions become calls to the ancestor's public checkers (#9).
func rebuildInheritedClause(clause: FunctionClause, renamed: ?IdentifierSyntax,
    context: RebuildClauseContext): Tokens {
    let result = Tokens()
    match (clause) {
        case FunctionClause.Requires(c) =>
            result.append(Token(IDENTIFIER, "requires"))
            appendClauseLabel(result, selectLabel(c.name, renamed))
            appendRebuiltCondition(result, c.condition.tokens, None, context)
        case FunctionClause.Ensures(c) =>
            result.append(Token(IDENTIFIER, "ensures"))
            appendClauseLabel(result, selectLabel(c.name, renamed))
            if (let Some(ret) <- c.ret) {
                result.append(ret.tokens).append(Token(COLON))
            }
            appendRebuiltCondition(result, c.condition.tokens, c.ret, context)
        case FunctionClause.Throws(c) =>
            result.append(Token(IDENTIFIER, "throws"))
            appendClauseLabel(result, selectLabel(c.name, renamed))
            result.append(substituteValueTokens(c.exception.tokens, context.parameters, context.arguments,
                context.valueNames))
            result.append(Token(IF))
            // No checker exists for `throws` conditions; always replay the renamed text.
            result.append(substituteValueTokens(alphaRenameTokens(c.condition.tokens, context.renames),
                context.parameters, context.arguments, context.valueNames))
        case FunctionClause.Variable(c) =>
            result.append(Token(IDENTIFIER, "variable"))
            match (renamed) {
                case Some(label) => result.append(label.tokens)
                case None => result.append(c.name.tokens)
            }
            result.append(Token(COLON))
            result.append(substituteTypeArguments(c.ty.tokens, context.parameters, context.arguments))
            if (let Some(initializer) <- c.initExpr) {
                result.append(Token(ASSIGN))
                result.append(substituteValueTokens(alphaRenameTokens(initializer.tokens, context.renames),
                    context.parameters, context.arguments, context.valueNames))
            }
        case FunctionClause.Inherit(_) => ()
    }
    result
}

/// Append one inherited condition, materializing it as a checker call where possible and
/// substituting type arguments in the replayed text otherwise.
func appendRebuiltCondition(result: Tokens, condition: Tokens, ret: ?IdentifierSyntax,
    context: RebuildClauseContext): Unit {
    let conditionContext = InheritConditionContext(context.checkerBase, context.parentParams,
        context.childParams, context.instance, context.inheritedVariableNames, context.renames)
    let adapted = adaptInheritedCondition(condition, ret, context.ordinal, conditionContext)
    if (isCheckerCallCondition(adapted)) {
        result.append(adapted)
    } else {
        result.append(substituteValueTokens(adapted, context.parameters, context.arguments, context.valueNames))
    }
}

func selectLabel(original: ?IdentifierSyntax, renamed: ?IdentifierSyntax): ?IdentifierSyntax {
    match (renamed) {
        case Some(label) => Some(label)
        case None => original
    }
}

func appendClauseLabel(result: Tokens, label: ?IdentifierSyntax): Unit {
    match (label) {
        case Some(name) => result.append(Token(LSQUARE)).append(name.tokens).append(Token(RSQUARE))
        case None => ()
    }
}

func prefixPropertyClause(kind: PropKind, body: Tokens): Tokens {
    let result = Tokens()
    match (kind) {
        case PropKind.Getter => result.append(Token(IDENTIFIER, "get"))
        case PropKind.Setter => result.append(Token(IDENTIFIER, "set"))
    }
    result.append(body)
    result
}

func appendInheritedClause(result: Tokens, clause: Tokens): Unit {
    if (clause.size == 0) {
        return
    }
    if (result.size > 0) {
        result.append(Token(SEMI))
    }
    result.append(clause)
}

func functionClauseTokens(clause: FunctionClause): Tokens {
    match (clause) {
        case FunctionClause.Requires(c) => c.tokens
        case FunctionClause.Ensures(c) => c.tokens
        case FunctionClause.Throws(c) => c.tokens
        case FunctionClause.Variable(c) => c.tokens
        case FunctionClause.Inherit(c) => c.tokens
    }
}

func matchesInheritKind(clause: FunctionClause, kind: InheritClauseKind, name: String): Bool {
    match ((kind, clause)) {
        case (InheritClauseKind.Requires, FunctionClause.Requires(c)) => labelName(c.name) == name
        case (InheritClauseKind.Ensures, FunctionClause.Ensures(c)) => labelName(c.name) == name
        case (InheritClauseKind.Throws, FunctionClause.Throws(c)) => labelName(c.name) == name
        case (InheritClauseKind.Variable, FunctionClause.Variable(c)) => c.name.name == name
        case _ => false
    }
}

func labelName(name: ?IdentifierSyntax): String {
    match (name) {
        case Some(label) => label.name
        case None => ""
    }
}

func samePropKind(left: PropKind, right: PropKind): Bool {
    match ((left, right)) {
        case (PropKind.Getter, PropKind.Getter) => true
        case (PropKind.Setter, PropKind.Setter) => true
        case _ => false
    }
}

/// Rebuild `<type>.<name>` or `<new-name> = <type>.<name>` with type parameters substituted.
func emitInheritTarget(target: TypeInheritTarget, parameters: ArrayList<String>,
    arguments: ArrayList<TypeNode>): Tokens {
    let result = Tokens()
    match (target) {
        case TypeInheritTarget.ByType(ty) =>
            result.append(substituteTypeArguments(ty.tokens, parameters, arguments))
        case TypeInheritTarget.ByMember(ty, name) =>
            result.append(substituteTypeArguments(ty.tokens, parameters, arguments))
            result.append(Token(DOT)).append(name.tokens)
        case TypeInheritTarget.ByRename(ty, newName, memberName) =>
            result.append(newName.tokens).append(Token(ASSIGN))
            result.append(substituteTypeArguments(ty.tokens, parameters, arguments))
            result.append(Token(DOT)).append(memberName.tokens)
    }
    result
}

func substituteClauseOrigin(origin: ClauseOrigin, parameters: ArrayList<String>,
    arguments: ArrayList<TypeNode>): ClauseOrigin {
    let instantiated = ArrayList<TypeNode>()
    for (argument in origin.typeArguments) {
        let text = substituteTypeArguments(argument.toTokens(), parameters, arguments)
        // The read side only lexes origin arguments, so a corrupt `.cmeta` can hold text
        // that lexes cleanly yet fails to parse; degrade to the unsubstituted origin
        // instead of letting the `ASTException` pierce the macro expansion.
        try {
            instantiated.add(parseType(text))
        } catch (e: Exception) {
            println(
                "[stdx.contract] WARNING: contract metadata origin type `${text}` could not be parsed (${e.message}); keeping the unsubstituted origin")
            return origin
        }
    }
    ClauseOrigin(origin.declaringType, origin.clauseIndex, instantiated)
}

/// Type-argument substitution input: formal parameter names, concrete arguments, and the
/// declaring parent's value names (identifiers that name values, not types).
class TypeSubstitution {
    let parameters: ArrayList<String>
    let arguments: ArrayList<TypeNode>
    let valueNames: HashSet<String>

    init(parameters: ArrayList<String>, arguments: ArrayList<TypeNode>, valueNames: HashSet<String>) {
        this.parameters = parameters
        this.arguments = arguments
        this.valueNames = valueNames
    }
}

internal func substituteContract(contract: ResolvedTypeContract, substitution: TypeSubstitution,
    diagnostics: ArrayList<Diagnostic>,
    emitStorage!: Bool, fromInterface!: Bool = false): ?ResolvedTypeContract {
    let result = ResolvedTypeContract(contract.tokens)
    let before = diagnostics.size
    for (resolved in contract.clauses) {
        if (let TypeClause.Inherits(inherits) <- resolved.clause) {
            diagnostics.add(
                Diagnostic("parent contract metadata contains unresolved inherits", "contract inheritance",
                    inherits.tokens))
            continue
        }
        let parsed = parseClassContract(substituteTypeClause(resolved.clause, substitution.parameters,
            substitution.arguments, substitution.valueNames))
        diagnostics.add(all: parsed.diagnostics)
        if (parsed.hasError()) {
            continue
        }
        let origin = substituteClauseOrigin(resolved.origin, substitution.parameters, substitution.arguments)
        for (instantiated in parsed.value.clauses) {
            let (inheritedStorage, inheritedInterface) = match (instantiated) {
                case TypeClause.Variable(_) => (emitStorage, fromInterface)
                case _ => (true, false)
            }
            result.add(ResolvedTypeClause(origin, instantiated, emitStorage: inheritedStorage,
                fromInterface: inheritedInterface))
        }
    }
    if (diagnostics.size != before) {
        return None
    }
    Some(result)
}
