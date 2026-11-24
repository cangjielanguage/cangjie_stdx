/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.validation

import stdx.contract.macros.syntax.{Diagnostic, TypeClause, TypeContract, TypeSyntax, VariableClause}
import stdx.contract.macros.tokens.{destructuringGroupSpans, isValue, lambdaAndCaseBindingSpans, precededByDot, skipSeparators}
import std.ast.{ASTException, Body, ClassDecl, Decl, DiagReportLevel, ExtendDecl, FuncDecl, FuncParam, InterfaceDecl, Modifier, PrimaryCtorDecl, PropDecl, StructDecl, Token, TokenKind, Tokens, VarDecl, VarPattern, diagReport}
import std.collection.{ArrayList, HashMap, HashSet, contains, isEmpty}

/**
 * @brief Validate a type-level contract and report violations as diagnostics.
 *
 * Applies to `class`, `struct`, `interface`, and `extend` declarations. Checks that
 * `extend` contracts declare no variables or invariants, that `static invariant` clauses read only static
 * members, that abstract `variable` names do not conflict with existing members, other
 * `variable` clauses, or generated storage names, that variable initializers reference
 * only earlier initialized variables, that auxiliary (ghost) variables are accessed only
 * inside contract blocks, that constructor `@ghost` blocks initialize variables before
 * reading them and do not call member functions, and that no member uses a generated
 * contract name. Variables with no initial value that no constructor assigns are
 * reported as warnings.
 *
 * @param contract The parsed type contract to validate.
 * @param owner The declaration carrying the contract.
 * @return true when the contract is valid, false otherwise (diagnostics are reported).
 */
public func validateTypeContract(contract: TypeContract, owner: Decl): Bool {
    let diagnostics = ArrayList<Diagnostic>()
    // `extend` type-level contracts may not declare or inherit variables/invariants, so
    // every such clause is intercepted here before resolution. `inherits from` itself is
    // allowed: it pulls the interface's member contracts (spec §3.4.5).
    if (!validateExtendTypeClauses(contract, owner, diagnostics)) {
        return false
    }

    // Collect every abstract variable first so forward references in initializers are recognised.
    let declaredVariables = HashSet<String>()
    let instanceVariables = HashSet<String>()
    let staticVariables = HashSet<String>()
    for (clause in contract.clauses) {
        if (let TypeClause.Variable(variable) <- clause) {
            declaredVariables.add(variable.name.name)
            if (variable.isStatic) {
                staticVariables.add(variable.name.name)
            } else {
                instanceVariables.add(variable.name.name)
            }
        }
    }
    let initialized = HashSet<String>()
    let context = TypeValidationContext(owner, declaredVariables, instanceVariables, staticVariables, initialized)
    reportGeneratedMemberNames(owner, diagnostics)

    for (clause in contract.clauses) {
        validateTypeClause(clause, context, diagnostics)
    }
    validateMemberAuxiliaryAccess(owner, context, diagnostics)
    // Report variables whose initialization obligation no constructor fulfils.
    reportUnassignedAuxiliaryVariables(owner, context)
    for (diagnostic in diagnostics) {
        diagnostic.show()
    }
    diagnostics.isEmpty()
}

/// Shared state of one type-level contract validation pass.
class TypeValidationContext {
    let declaredVariables: HashSet<String>
    let instanceVariables: HashSet<String>
    let staticVariables: HashSet<String>
    let initialized: HashSet<String>
    let memberNames: HashSet<String>
    let memberFunctions: HashSet<String>
    let instanceMembers: HashSet<String>
    let ownerName: ?String
    let invariantNames = HashSet<String>()
    let variableNames = HashSet<String>()
    let variableTokens = HashMap<String, Tokens>()

    init(owner: Decl, declaredVariables: HashSet<String>, instanceVariables: HashSet<String>,
        staticVariables: HashSet<String>, initialized: HashSet<String>) {
        this.declaredVariables = declaredVariables
        this.instanceVariables = instanceVariables
        this.staticVariables = staticVariables
        this.initialized = initialized
        this.memberNames = collectMemberNames(owner)
        this.memberFunctions = collectMemberFunctionNames(owner)
        this.instanceMembers = instanceMemberNames(owner)
        this.ownerName = enclosingTypeName(owner)
    }
}

/// Report the type-level clauses an `extend` declaration may not carry; false when any
/// such clause was found.
func validateExtendTypeClauses(contract: TypeContract, owner: Decl,
    diagnostics: ArrayList<Diagnostic>): Bool {
    if (!(owner is ExtendDecl)) {
        return true
    }
    var extendOk = true
    for (clause in contract.clauses) {
        if (let Some((tokens, message)) <- extendClauseDiagnostic(clause)) {
            diagnostics.add(Diagnostic(message, "extend contract", tokens))
            extendOk = false
        }
    }
    if (!extendOk) {
        for (diagnostic in diagnostics) {
            diagnostic.show()
        }
    }
    extendOk
}

/// The diagnostic payload for a type-level clause that `extend` cannot carry, if any.
func extendClauseDiagnostic(clause: TypeClause): Option<(Tokens, String)> {
    match (clause) {
        case TypeClause.Variable(variable) =>
            Some((variable.tokens, "extend type-level contracts cannot declare or inherit abstract variables"))
        case TypeClause.Invariant(invariant) =>
            Some((invariant.tokens, "extend type-level contracts cannot declare or inherit invariants"))
        case TypeClause.Inherits(_) => Option<(Tokens, String)>.None
        case TypeClause.InvariantInherit(target) =>
            Some((target.getType().tokens, "extend contracts cannot use selective `inherits invariant`"))
    }
}

func validateTypeClause(clause: TypeClause, context: TypeValidationContext,
    diagnostics: ArrayList<Diagnostic>): Unit {
    match (clause) {
        case TypeClause.Invariant(invariant) =>
            if (invariant.isStatic) {
                // A `static invariant` may only use static members.
                reportStaticContextReads(invariant.condition.tokens, context, "a `static invariant`",
                    HashSet<String>(), diagnostics)
            }
            if (let Some(name) <- invariant.name) {
                if (context.invariantNames.contains(name.name)) {
                    diagnostics.add(
                        Diagnostic("duplicate invariant name `${name.name}`", "type contract", name.tokens))
                } else {
                    context.invariantNames.add(name.name)
                }
            }
        case TypeClause.Variable(variable) =>
            let name = variable.name.name
            if (context.memberNames.contains(name)) {
                diagnostics.add(
                    Diagnostic("abstract variable name `${name}` conflicts with an existing member of the same name",
                        "type contract", variable.name.tokens))
            } else if (storageNameClash(name, context.declaredVariables)) {
                // Two `variable` clauses can collide through generation: `variable x`
                // creates storage named `_abs_x`, so `variable _abs_x` would generate a
                // property with the same name and the compiler would only say
                // "redefinition of '_abs_x'". Report the collision against the clauses.
                diagnostics.add(
                    Diagnostic("abstract variable name `${name}` collides with the storage of another `variable` clause (storage names are prefixed with `_abs_`); rename one of the clauses",
                        "type contract", variable.name.tokens))
            } else if (context.variableNames.contains(name)) {
                diagnostics.add(
                    Diagnostic("duplicate abstract variable name `${name}`", "type contract",
                        variable.name.tokens))
            } else {
                context.variableNames.add(name)
            }
            context.variableTokens.add(name, variable.name.tokens)
            validateVariableDeclaration(variable, context, diagnostics)
            if (variable.initExpr.isSome()) {
                context.initialized.add(name)
            }
        case TypeClause.Inherits(_) => ()
        case TypeClause.InvariantInherit(_) => ()
    }
}

/// True when declaring a `variable` clause named `name` would collide with another
/// clause through generated storage names: `variable x` creates storage `_abs_x`, so a
/// second clause named `_abs_x` (or vice versa) would produce two same-named members.
func storageNameClash(name: String, declaredVariables: HashSet<String>): Bool {
    for (other in declaredVariables) {
        if (other != name && (other == "_abs_" + name || name == "_abs_" + other)) {
            return true
        }
    }
    false
}

/// Type-level auxiliary variables are only meant for contract code, and static
/// members may only touch static auxiliary variables.
func validateMemberAuxiliaryAccess(owner: Decl, context: TypeValidationContext,
    diagnostics: ArrayList<Diagnostic>): Unit {
    match (owner) {
        case value: ClassDecl => validateBodyAuxiliaryAccess(value.body, context, diagnostics, false)
        case value: StructDecl => validateBodyAuxiliaryAccess(value.body, context, diagnostics, false)
        case value: InterfaceDecl => validateBodyAuxiliaryAccess(value.body, context, diagnostics, true)
        case value: ExtendDecl => validateBodyAuxiliaryAccess(value.body, context, diagnostics, false)
        case _ => ()
    }
}

func validateBodyAuxiliaryAccess(body: Body, context: TypeValidationContext,
    diagnostics: ArrayList<Diagnostic>, isInterface: Bool): Unit {
    for (member in body.decls) {
        match (member) {
            case method: FuncDecl => validateCallableAuxiliaryAccess(method, context, diagnostics, isInterface)
            case constructor: PrimaryCtorDecl =>
                let tokens = blockTokensOrEmpty({=> constructor.block})
                let parameters = collectParameterNames(constructor.funcParams)
                validateConstructorAuxiliaryAccess(tokens, context.declaredVariables, parameters, context, diagnostics)
                reportAuxiliaryAccessOutsideContracts(tokens, context.declaredVariables, parameters)
            case property: PropDecl =>
                for (accessor in accessors(property)) {
                    let tokens = blockTokensOrEmpty({=> accessor.block})
                    reportAuxiliaryAccessOutsideContracts(tokens, context.declaredVariables,
                        collectParameterNames(accessor.funcParams))
                }
            case field: VarDecl =>
                validateFieldInitializerAccess(field, context)
            case _ => ()
        }
    }
}

/// Field initializers are implementation code too, so reads of auxiliary variables there
/// must be reported. Scan only the initializer (tokens after `=`) so a type annotation
/// sharing an auxiliary's name does not warn.
func validateFieldInitializerAccess(field: VarDecl, context: TypeValidationContext): Unit {
    let fieldTokens = field.toTokens()
    let initTokens = Tokens()
    var seenAssign = false
    for (token in fieldTokens) {
        if (token.kind == ASSIGN) {
            seenAssign = true
            continue
        }
        if (seenAssign) {
            initTokens.append(token)
        }
    }
    if (seenAssign) {
        let skip = HashSet<String>()
        skip.add(field.identifier.value)
        reportAuxiliaryAccessOutsideContracts(initTokens, context.declaredVariables, skip)
    }
}

func validateCallableAuxiliaryAccess(method: FuncDecl, context: TypeValidationContext,
    diagnostics: ArrayList<Diagnostic>, isInterface: Bool): Unit {
    let tokens = blockTokensOrEmpty({=> method.block})
    let parameters = collectParameterNames(method.funcParams)
    let isStatic = hasModifier(method.modifiers, "static")
    if (isStatic) {
        // Static members and `static init` may only use static auxiliary variables
        // and other static members.
        reportStaticContextReads(tokens, context, "a static context", parameters, diagnostics)
    }
    if (method.identifier.value == "init") {
        let scopeVariables = if (isStatic) {
            context.staticVariables
        } else {
            context.declaredVariables
        }
        validateConstructorAuxiliaryAccess(tokens, scopeVariables, parameters, context, diagnostics)
        return
    }
    // Interface-level `variable`s are storage-backed, so a default member may read
    // them directly — the `@ghost`-only warning does not apply.
    if (!isInterface) {
        reportAuxiliaryAccessOutsideContracts(tokens, if (isStatic) { context.staticVariables } else { context.declaredVariables },
            parameters)
    }
}

/// Mutable state shared while scanning the tokens of one `@ghost` block.
class GhostScanState {
    let scopeVariables: HashSet<String>
    let available: HashSet<String>
    let memberFunctions: HashSet<String>
    let localSpans: ArrayList<(Int64, String)>
    let outerShadow: HashSet<String>
    let reportedReads = HashSet<String>()
    let reportedCalls = HashSet<String>()

    init(scopeVariables: HashSet<String>, available: HashSet<String>, memberFunctions: HashSet<String>,
        localSpans: ArrayList<(Int64, String)>, outerShadow: HashSet<String>) {
        this.scopeVariables = scopeVariables
        this.available = available
        this.memberFunctions = memberFunctions
        this.localSpans = localSpans
        this.outerShadow = outerShadow
    }
}

/// Constructor and `static init` `@ghost` blocks may only read auxiliary variables
/// that are initialized at that point and may not call member functions.
func validateConstructorAuxiliaryAccess(tokens: Tokens, scopeVariables: HashSet<String>,
    parameters: HashSet<String>, context: TypeValidationContext, diagnostics: ArrayList<Diagnostic>): Unit {
    let ranges = contractRanges(tokens)
    if (ranges.isEmpty()) {
        return
    }
    let available = HashSet<String>()
    for (name in context.initialized) {
        available.add(name)
    }
    for (name in parameters) {
        available.add(name)
    }
    for (range in ranges) {
        let (open, close) = range
        // Locals declared in the constructor body before the `@ghost` block legally
        // shadow the same-named auxiliary variable inside the whole block; only locals
        // declared inside the block are tracked per-position by `localSpans`.
        let state = GhostScanState(scopeVariables, available, context.memberFunctions,
            declaredLocalNameSpans(tokens, open + 1, close), declaredLocalNames(tokens, 0, open))
        // Single pass in source order: an assignment makes the variable readable by the
        // statements that follow it, including later reads in this same `@ghost` block
        // (`x = 1; y = x` is legal). Scanning all reads before any assignment would
        // report that shape as a false "read before initialized". Locals only shadow
        // from their declaration point onwards, so a read before a same-name local
        // declaration still refers to the auxiliary variable.
        var index = open + 1
        while (index < close) {
            validateGhostToken(tokens, index, close, state, diagnostics)
            index += 1
        }
    }
}

/// Report the reads and member-function calls at one token of a `@ghost` block and record
/// an assignment that makes an auxiliary variable available.
func validateGhostToken(tokens: Tokens, index: Int64, close: Int64, state: GhostScanState,
    diagnostics: ArrayList<Diagnostic>): Unit {
    let token = tokens[index]
    if (token.kind != IDENTIFIER) {
        return
    }
    let local = isShadowedAt(state.localSpans, index, token.value) || state.outerShadow.contains(token.value)
    let followingKind = nextKind(tokens, index, close)
    if (state.scopeVariables.contains(token.value) && !state.available.contains(token.value) && !local &&
        !precededByDot(tokens, index) && !followedByCallOrLabel(tokens, index) &&
        followingKind != ASSIGN && state.reportedReads.add(token.value)) {
        diagnostics.add(
            Diagnostic("auxiliary variable `${token.value}` is read in `@ghost` before it is initialized",
                "type contract", Tokens(token)))
    } else if (state.memberFunctions.contains(token.value) && !local &&
        isGhostMemberCall(tokens, index, close) && state.reportedCalls.add(token.value)) {
        diagnostics.add(
            Diagnostic("member function calls are not allowed in `@ghost` blocks of constructors",
                "type contract", Tokens(token)))
    }
    if (state.scopeVariables.contains(token.value) && !local && !precededByDot(tokens, index) &&
        followingKind == ASSIGN) {
        state.available.add(token.value)
    }
}

/// An instance auxiliary variable without an initial value must be assigned in a
/// constructor `@ghost` block, and a `static` one in a `static init` `@ghost` block;
/// a variable no constructor ever assigns is reported as a compile-time warning.
func reportUnassignedAuxiliaryVariables(owner: Decl, context: TypeValidationContext): Unit {
    let instancePending = pendingNames(context.instanceVariables, context.initialized)
    let staticPending = pendingNames(context.staticVariables, context.initialized)
    if (instancePending.isEmpty() && staticPending.isEmpty()) {
        return
    }
    let instanceAssigned = HashSet<String>()
    let staticAssigned = HashSet<String>()
    match (ownerBody(owner)) {
        case Some(body) =>
            for (member in body.decls) {
                markConstructorAssignments(member, instancePending, staticPending, instanceAssigned, staticAssigned)
            }
        case None => return
    }
    reportPendingNames(instancePending, instanceAssigned, context.variableTokens, false)
    reportPendingNames(staticPending, staticAssigned, context.variableTokens, true)
}

/// Variables that have no initial value and therefore need a constructor assignment.
func pendingNames(variables: HashSet<String>, initialized: HashSet<String>): HashSet<String> {
    let pending = HashSet<String>()
    for (name in variables) {
        if (!initialized.contains(name)) {
            pending.add(name)
        }
    }
    pending
}

/// The declaration body of a type that has constructors.
func ownerBody(owner: Decl): ?Body {
    match (owner) {
        case value: ClassDecl => Some(value.body)
        case value: StructDecl => Some(value.body)
        case _ => None
    }
}

/// Record the ghost-block assignments performed by one constructor-like member.
func markConstructorAssignments(member: Decl, instancePending: HashSet<String>, staticPending: HashSet<String>,
    instanceAssigned: HashSet<String>, staticAssigned: HashSet<String>): Unit {
    match (member) {
        case ctor: PrimaryCtorDecl =>
            markGhostAssigned(blockTokensOrEmpty({=> ctor.block}), instancePending, instanceAssigned)
        case method: FuncDecl =>
            if (method.identifier.value == "init") {
                let tokens = blockTokensOrEmpty({=> method.block})
                if (hasModifier(method.modifiers, "static")) {
                    markGhostAssigned(tokens, staticPending, staticAssigned)
                } else {
                    markGhostAssigned(tokens, instancePending, instanceAssigned)
                }
            }
        case _ => ()
    }
}

/// Report the variables that no constructor ever assigns.
func reportPendingNames(pending: HashSet<String>, assigned: HashSet<String>,
    variableTokens: HashMap<String, Tokens>, staticScope: Bool): Unit {
    for (name in pending) {
        if (!assigned.contains(name)) {
            let message = if (staticScope) {
                "static auxiliary variable `${name}` has no initial value and is never assigned in a `static init` `@ghost` block"
            } else {
                "auxiliary variable `${name}` has no initial value and is never assigned in a constructor `@ghost` block"
            }
            diagReport(DiagReportLevel.WARNING, variableTokens.get(name) ?? Tokens(), message, "type contract")
        }
    }
}

func isBodySeparator(kind: TokenKind): Bool {
    kind == NL || kind == SEMI || kind == COMMENT
}

/// Record `name = ...` assignments to `pending` variables inside the contract blocks
/// (`@ghost`, `@contractAssert`, `@loopInvariant`) of `tokens`. Only assignments that
/// provably run count: blocks nested in braced control flow or after a `return` do not.
func markGhostAssigned(tokens: Tokens, pending: HashSet<String>, assigned: HashSet<String>): Unit {
    if (pending.isEmpty() || assigned.size == pending.size) {
        return
    }
    // Strip the declaration body's own braces so depth 0 means "directly in the
    // body" no matter whether the token stream carries the outer pair.
    let (begin, _) = bodyContentBounds(tokens)
    for (range in contractRanges(tokens)) {
        markAssignmentsInRange(tokens, begin, range, pending, assigned)
    }
}

/// The first and last content token indexes of a declaration body, with the outer
/// braces excluded when present.
func bodyContentBounds(tokens: Tokens): (Int64, Int64) {
    var begin = 0
    var end = tokens.size
    while (begin < end && isBodySeparator(tokens[begin].kind)) {
        begin += 1
    }
    while (end > begin && isBodySeparator(tokens[end - 1].kind)) {
        end -= 1
    }
    if (begin < end && tokens[begin].kind == LCURL && tokens[end - 1].kind == RCURL) {
        begin += 1
        end -= 1
    }
    (begin, end)
}

/// Walk the tokens that precede a contract block, returning the brace depth at the block
/// and whether a top-level `return` already runs before it.
func scanBeforeContractRange(tokens: Tokens, begin: Int64, open: Int64): (Int64, Bool) {
    var depth: Int64 = 0
    var topLevelReturned = false
    var pre = begin
    while (pre < open) {
        if (tokens[pre].kind == LCURL) {
            depth += 1
        } else if (tokens[pre].kind == RCURL) {
            if (depth > 0) {
                depth -= 1
            }
        } else if (tokens[pre].kind == RETURN && depth == 0) {
            topLevelReturned = true
        }
        pre += 1
    }
    (depth, topLevelReturned)
}

/// Record the assignments to `pending` variables inside one contract block.
func markAssignmentsInRange(tokens: Tokens, begin: Int64, range: (Int64, Int64),
    pending: HashSet<String>, assigned: HashSet<String>): Unit {
    let (open, close) = range
    // Brace depth of the contract block's position in the body and whether a
    // top-level `return` precedes it: both make its assignments conditional.
    let (depthBefore, returnedBefore) = scanBeforeContractRange(tokens, begin, open)
    var depth = depthBefore
    var topLevelReturned = returnedBefore
    let local = declaredLocalNames(tokens, open + 1, close)
    var index = open + 1
    while (index < close) {
        let token = tokens[index]
        if (token.kind == LCURL) {
            depth += 1
        } else if (token.kind == RCURL) {
            if (depth > 0) {
                depth -= 1
            }
        } else if (token.kind == RETURN && depth == 0) {
            topLevelReturned = true
        } else if (depth == 0 && !topLevelReturned && token.kind == IDENTIFIER &&
            pending.contains(token.value) && !assigned.contains(token.value) &&
            !local.contains(token.value) && !precededByDot(tokens, index) &&
            nextKind(tokens, index, close) == ASSIGN && assigned.add(token.value)) { // cjlint-ignore !G.EXP.03 nextKind is a pure lookahead; short-circuit keeps per-token work minimal
            ()
        }
        index += 1
    }
}

/// A static context may only use static members. Ordinary instance members are
/// also reported so the diagnostic names the member; names shared with a
/// same-name static declaration are excluded (the overload may resolve statically).
func reportStaticContextReads(tokens: Tokens, validation: TypeValidationContext, label: String,
    skipNames: HashSet<String>, diagnostics: ArrayList<Diagnostic>): Unit {
    let instanceVariables = validation.instanceVariables
    let instanceMembers = validation.instanceMembers
    if (instanceVariables.isEmpty() && instanceMembers.isEmpty()) {
        return
    }
    let shadowed = declaredLocalNames(tokens, 0, tokens.size)
    let reported = HashSet<String>()
    var index = 0
    while (index < tokens.size) {
        let token = tokens[index]
        if (token.kind == IDENTIFIER && !shadowed.contains(token.value) && !skipNames.contains(token.value) &&
            !precededByDot(tokens, index) && !followedByCallOrLabel(tokens, index) &&
            instanceVariables.contains(token.value) && reported.add(token.value)) {
            diagnostics.add(
                Diagnostic("instance auxiliary variable `${token.value}` cannot be accessed from ${label}",
                    "type contract", Tokens(token)))
        } else if (token.kind == IDENTIFIER && !shadowed.contains(token.value) && !skipNames.contains(token.value) &&
            !precededByDot(tokens, index) && !followedByLabelColon(tokens, index) && // cjlint-ignore !G.EXP.03 pure lookahead; short-circuit keeps per-token work minimal
            instanceMembers.contains(token.value) && reported.add(token.value)) {
            // A call position (`name(...)`) is reported too: calling an instance function
            // from a static context is itself illegal (the implicit `this` cannot bind).
            // Only a named-argument label or a type annotation stays exempt.
            diagnostics.add(
                Diagnostic("instance member `${token.value}` cannot be accessed from ${label}",
                    "type contract", Tokens(token)))
        }
        index += 1
    }
}

/// Non-static member names (functions, properties, fields) declared directly on
/// the type, excluding names that also have a same-name static declaration
/// (such overloads may resolve statically).
func instanceMemberNames(owner: Decl): HashSet<String> {
    let names = HashSet<String>()
    let staticNames = HashSet<String>() // cjlint-ignore !G.VAR.02 the set is filled by the static scan and consumed by the instance scan
    if (let Some(body) <- memberBody(owner)) {
        collectStaticMemberNames(body, staticNames)
        collectInstanceMemberNames(body, staticNames, names)
    }
    names
}

/// The body of a declaration that lists ordinary members.
func memberBody(owner: Decl): ?Body {
    match (owner) {
        case value: ClassDecl => Some(value.body)
        case value: StructDecl => Some(value.body)
        case value: InterfaceDecl => Some(value.body)
        case value: ExtendDecl => Some(value.body)
        case _ => None
    }
}

/// Record the members that also have a same-name static declaration.
func collectStaticMemberNames(body: Body, names: HashSet<String>): Unit {
    for (member in body.decls) {
        match (member) {
            case method: FuncDecl => collectStaticName(method.modifiers, method.identifier.value, names)
            case property: PropDecl => collectStaticName(property.modifiers, property.identifier.value, names)
            case field: VarDecl => collectStaticName(field.modifiers, field.identifier.value, names)
            case _ => ()
        }
    }
}

func collectStaticName(modifiers: ArrayList<Modifier>, name: String, names: HashSet<String>): Unit {
    if (hasModifier(modifiers, "static")) {
        names.add(name)
    }
}

/// Record the members whose name has no same-name static declaration.
func collectInstanceMemberNames(body: Body, staticNames: HashSet<String>, names: HashSet<String>): Unit {
    for (member in body.decls) {
        match (member) {
            case method: FuncDecl =>
                collectInstanceName(method.modifiers, method.identifier.value, staticNames, names)
            case property: PropDecl =>
                collectInstanceName(property.modifiers, property.identifier.value, staticNames, names)
            case field: VarDecl =>
                collectInstanceName(field.modifiers, field.identifier.value, staticNames, names)
            case _ => ()
        }
    }
}

func collectInstanceName(modifiers: ArrayList<Modifier>, name: String, staticNames: HashSet<String>,
    names: HashSet<String>): Unit {
    if (!hasModifier(modifiers, "static") && !staticNames.contains(name)) {
        names.add(name)
    }
}

/// Implementation code must not read or write auxiliary variables. Local
/// `let`/`var`/`for` declarations shadow auxiliary variables, so their names
/// (and every use inside the body) are exempt.
func reportAuxiliaryAccessOutsideContracts(tokens: Tokens, auxNames: HashSet<String>,
    skipNames: HashSet<String>): Unit {
    if (auxNames.isEmpty()) {
        return
    }
    let ranges = contractRanges(tokens)
    let shadowed = declaredLocalNames(tokens, 0, tokens.size)
    let reported = HashSet<String>()
    var index = 0
    while (index < tokens.size) {
        let token = tokens[index]
        if (token.kind == IDENTIFIER && auxNames.contains(token.value) && !skipNames.contains(token.value) &&
            !shadowed.contains(token.value) &&
            !precededByDot(tokens, index) && !followedByCallOrLabel(tokens, index) &&
            !insideRanges(index, ranges) && reported.add(token.value)) {
            diagReport(DiagReportLevel.WARNING, Tokens(token),
                "auxiliary variable `${token.value}` may only be accessed in `@ghost`, `@contractAssert`, or `@loopInvariant` blocks",
                "type contract")
        }
        index += 1
    }
}

func collectMemberFunctionNames(owner: Decl): HashSet<String> {
    let names = HashSet<String>()
    match (owner) {
        case value: ClassDecl => collectBodyFunctionNames(value.body, names)
        case value: StructDecl => collectBodyFunctionNames(value.body, names)
        case value: InterfaceDecl => collectBodyFunctionNames(value.body, names)
        case value: ExtendDecl => collectBodyFunctionNames(value.body, names)
        case _ => ()
    }
    names
}

func collectBodyFunctionNames(body: Body, names: HashSet<String>): Unit {
    for (member in body.decls) {
        if (let method: FuncDecl <- member) {
            if (method.identifier.value.size > 0 && method.identifier.value != "init") {
                names.add(method.identifier.value)
            }
        }
    }
}

func collectParameterNames(params: ArrayList<FuncParam>): HashSet<String> {
    let names = HashSet<String>()
    for (parameter in params) {
        names.add(parameter.identifier.value)
    }
    names
}

func accessors(property: PropDecl): ArrayList<FuncDecl> {
    let result = ArrayList<FuncDecl>()
    if (let Some(getter) <- accessorOrNone({=> property.getter})) {
        result.add(getter)
    }
    if (let Some(setter) <- accessorOrNone({=> property.setter})) {
        result.add(setter)
    }
    result
}

/// A bodiless property (interface or abstract member) has no accessor node at all.
func accessorOrNone(accessor: () -> FuncDecl): ?FuncDecl {
    try {
        Some(accessor())
    } catch (_: ASTException) {
        None
    }
}

func hasModifier(modifiers: ArrayList<Modifier>, keyword: String): Bool {
    for (modifier in modifiers) {
        if (isValue(modifier.keyword, keyword)) {
            return true
        }
    }
    false
}

/// The eligibility gate `if (_contract_gateEnabled()) { ... }` emitted by
/// `@ghost`, `@contractAssert`, and `@loopInvariant`; returns the brace indexes of each block.
func ghostGateRanges(tokens: Tokens): ArrayList<(Int64, Int64)> {
    let ranges = ArrayList<(Int64, Int64)>()
    var index: Int64 = 0
    while (index < tokens.size) {
        if (tokens[index].kind == IDENTIFIER && tokens[index].value == "_contract_gateEnabled") {
            match (gateBlock(tokens, index)) {
                case Some(range) =>
                    let (_, close) = range
                    ranges.add(range)
                    index = close + 1
                case None => index += 1
            }
        } else {
            index += 1
        }
    }
    ranges
}

/// Contract code of a body: either the expanded gate or a source-level `@ghost`,
/// `@contractAssert`, or `@loopInvariant` invocation (type-level validation sees the
/// unexpanded form inside member bodies).
func contractRanges(tokens: Tokens): ArrayList<(Int64, Int64)> {
    let ranges = ghostGateRanges(tokens)
    var index: Int64 = 0
    while (index < tokens.size) {
        if (let Some(close) <- contractMacroExtentAt(tokens, index)) {
            ranges.add((index, close))
            index = close + 1
            continue
        }
        index += 1
    }
    ranges
}

/// End index of the contract macro invocation starting at `index`, when it is one.
func contractMacroExtentAt(tokens: Tokens, index: Int64): ?Int64 {
    if (tokens[index].kind != AT) {
        return None
    }
    let nameIndex = skipSeparators(tokens, index + 1)
    if (nameIndex >= tokens.size || tokens[nameIndex].kind != IDENTIFIER ||
        !isContractMacroName(tokens[nameIndex].value)) {
        return None
    }
    macroExtent(tokens, nameIndex)
}

func isContractMacroName(name: String): Bool {
    name == "ghost" || name == "contractAssert" || name == "loopInvariant"
}

/// Index of the last token of the invocation whose macro name is at `nameIndex`.
func macroExtent(tokens: Tokens, nameIndex: Int64): ?Int64 {
    var cursor = skipSeparators(tokens, nameIndex + 1)
    if (cursor < tokens.size && tokens[cursor].kind == LSQUARE) {
        match (matchingKind(tokens, cursor, LSQUARE, RSQUARE)) {
            case Some(close) => cursor = skipSeparators(tokens, close + 1)
            case None => return None
        }
    }
    if (cursor < tokens.size && tokens[cursor].kind == LPAREN) {
        return matchingKind(tokens, cursor, LPAREN, RPAREN)
    }
    None
}

func matchingKind(tokens: Tokens, open: Int64, openKind: TokenKind, closeKind: TokenKind): ?Int64 {
    var depth: Int64 = 0
    var cursor = open
    while (cursor < tokens.size) {
        let kind = tokens[cursor].kind
        if (kind == openKind) {
            depth += 1
        } else if (kind == closeKind) {
            depth -= 1
            if (depth == 0) {
                return Some(cursor)
            }
        }
        cursor += 1
    }
    None
}

func gateBlock(tokens: Tokens, start: Int64): ?(Int64, Int64) {
    // Skip the `_contract_gateEnabled()` condition up to its block; paren balancing
    // is all that matters here since the emitted condition is a single call.
    var cursor = start + 1
    var depth: Int64 = 0
    while (cursor < tokens.size) {
        let kind = tokens[cursor].kind
        if (kind == LPAREN) {
            depth += 1
        } else if (kind == RPAREN) {
            depth -= 1
        } else if (depth <= 0 && kind == LCURL) {
            break
        } else if (depth <= 0 && kind == RCURL) {
            return None
        }
        cursor += 1
    }
    if (cursor >= tokens.size) {
        return None
    }
    let open = cursor
    var level: Int64 = 0
    while (cursor < tokens.size) {
        match (tokens[cursor].kind) {
            case LCURL => level += 1
            case RCURL =>
                level -= 1
                if (level == 0) {
                    return Some((open, cursor))
                }
            case _ => ()
        }
        cursor += 1
    }
    None
}

func insideRanges(index: Int64, ranges: ArrayList<(Int64, Int64)>): Bool {
    for (range in ranges) {
        let (open, close) = range
        if (index > open && index < close) {
            return true
        }
    }
    false
}

func followedByLParen(tokens: Tokens, index: Int64): Bool {
    var cursor = index + 1
    while (cursor < tokens.size && (tokens[cursor].kind == NL || tokens[cursor].kind == SEMI)) {
        cursor += 1
    }
    cursor < tokens.size && tokens[cursor].kind == LPAREN
}

/// Whether the identifier at `index` invokes a member function of the type under
/// construction: a bare `foo(`, a generic `foo<T>(`, or an explicit `this.foo(` /
/// `super.foo(`. A receiver other than `this`/`super` is another object's method, not a
/// member call of the partially constructed value.
func isGhostMemberCall(tokens: Tokens, index: Int64, close: Int64): Bool {
    if (!followedByInvocation(tokens, index, close)) {
        return false
    }
    if (!precededByDot(tokens, index)) {
        return true
    }
    return index >= 2 && isValue(tokens[index - 2], "this") || index >= 2 && isValue(tokens[index - 2], "super")
}

/// True when a direct call `foo(` or a generic call `foo<...>(` follows the identifier.
/// A lone comparison `foo < bar` never closes the angle-bracket depth and yields false.
func followedByInvocation(tokens: Tokens, index: Int64, close: Int64): Bool {
    let cursor = skipNewlinesAndSemis(tokens, index + 1, close)
    if (cursor >= close) {
        return false
    }
    if (tokens[cursor].kind == LPAREN) {
        return true
    }
    if (!isValue(tokens[cursor], "<")) {
        return false
    }
    let afterGeneric = skipAngleBrackets(tokens, cursor, close)
    afterGeneric < close && tokens[afterGeneric].kind == LPAREN
}

/// Index of the first token at or after `start` that is neither a line break nor a
/// semicolon, bounded by `limit`.
func skipNewlinesAndSemis(tokens: Tokens, start: Int64, limit: Int64): Int64 {
    var cursor = start
    while (cursor < limit && (tokens[cursor].kind == NL || tokens[cursor].kind == SEMI)) {
        cursor += 1
    }
    cursor
}

/// Index just past the angle-bracket group opened at `start`, or `limit` when the group
/// stays unbalanced before `limit`.
func skipAngleBrackets(tokens: Tokens, start: Int64, limit: Int64): Int64 {
    var depth = 0
    var cursor = start
    while (cursor < limit) {
        if (isValue(tokens[cursor], "<")) {
            depth += 1
        } else if (isValue(tokens[cursor], ">")) {
            depth -= 1
            if (depth == 0) {
                return skipNewlinesAndSemis(tokens, cursor + 1, limit)
            }
        }
        cursor += 1
    }
    limit
}

func nextKind(tokens: Tokens, index: Int64, limit: Int64): TokenKind {
    var cursor = index + 1
    while (cursor < limit && (tokens[cursor].kind == NL || tokens[cursor].kind == SEMI)) {
        cursor += 1
    }
    if (cursor < limit) {
        return tokens[cursor].kind
    }
    TokenKind.NL
}

/// Names introduced by `let`/`var`/`const`/`for` bindings in `tokens[start..end]`, plus
/// lambda parameters, `match` case bindings and `catch` bindings; a local with the same
/// name shadows the auxiliary variable instead of accessing it. Each declaration is
/// recorded with its token position so shadowing can be applied from the declaration
/// point onwards instead of across the whole block.
func declaredLocalNameSpans(tokens: Tokens, start: Int64, end: Int64): ArrayList<(Int64, String)> {
    let spans = ArrayList<(Int64, String)>()
    var index = start
    while (index < end) {
        index = scanLocalBindingAt(tokens, index, end, spans)
    }
    for (span in lambdaAndCaseBindingSpans(tokens, start, end)) {
        spans.add((span[0], span[1].value))
    }
    // Destructuring groups (`let (a, (b, _)) = ...`, `(a, b) = ...`) bind locals by
    // name; the identifiers inside them shadow the auxiliary variable. The keyword
    // scan above already records same-statement patterns, so duplicate spans are fine:
    // consumers either deduplicate by name or only test membership.
    for (span in destructuringGroupSpans(tokens, start, end)) {
        addDestructuringNameSpans(tokens, span, spans)
    }
    spans
}

/// Record the binding names declared at `index` and return the next index to scan.
func scanLocalBindingAt(tokens: Tokens, index: Int64, end: Int64,
    spans: ArrayList<(Int64, String)>): Int64 {
    let token = tokens[index]
    if (isValue(token, "let") || isValue(token, "var") || isValue(token, "for") ||
        isValue(token, "const")) {
        // `const func` declares a nested function, not a binding list.
        if (isLocalConstFuncAt(tokens, index, end)) {
            return index + 1
        }
        collectBindingNameSpans(tokens, index, token, end, spans)
    }
    index + 1
}

/// True when the `const` at `index` (bounded by `end`) introduces a nested function.
func isLocalConstFuncAt(tokens: Tokens, index: Int64, end: Int64): Bool {
    if (!isValue(tokens[index], "const")) {
        return false
    }
    var cursor = index + 1
    while (cursor < end && (tokens[cursor].kind == NL || tokens[cursor].kind == SEMI)) {
        cursor += 1
    }
    cursor < end && isValue(tokens[cursor], "func")
}

/// Record every identifier of the binding list opened by `keyword`.
func collectBindingNameSpans(tokens: Tokens, index: Int64, keyword: Token, end: Int64,
    spans: ArrayList<(Int64, String)>): Unit {
    var cursor = index + 1
    var depth: Int64 = 0
    while (cursor < end) {
        let current = tokens[cursor]
        if (isBindingSpanEnd(keyword, current, depth)) {
            break
        }
        if (current.kind == IDENTIFIER) {
            spans.add((cursor, current.value))
        }
        match (current.kind) {
            case LPAREN | LSQUARE => depth += 1
            case RPAREN | RSQUARE =>
                if (depth > 0) {
                    depth -= 1
                }
            case _ => ()
        }
        cursor += 1
    }
}

func isBindingSpanEnd(keyword: Token, current: Token, depth: Int64): Bool {
    (isValue(keyword, "for") && isValue(current, "in")) ||
        (depth == 0 && (current.kind == NL || current.kind == ASSIGN || current.kind == COLON ||
        isValue(current, "<-")))
}

/// Record the identifiers of one destructuring group.
func addDestructuringNameSpans(tokens: Tokens, span: (Int64, Int64),
    spans: ArrayList<(Int64, String)>): Unit {
    var cursor = span[0]
    while (cursor <= span[1]) {
        if (tokens[cursor].kind == IDENTIFIER) {
            spans.add((cursor, tokens[cursor].value))
        }
        cursor += 1
    }
}

/// Whether `name` is shadowed at token position `index` by a local declared at or
/// before it: reads before the declaration point are not covered by the local.
func isShadowedAt(spans: ArrayList<(Int64, String)>, index: Int64, name: String): Bool {
    for (span in spans) {
        if (span[0] <= index && span[1] == name) {
            return true
        }
    }
    false
}

func declaredLocalNames(tokens: Tokens, start: Int64, end: Int64): HashSet<String> {
    let names = HashSet<String>()
    for (span in declaredLocalNameSpans(tokens, start, end)) {
        names.add(span[1])
    }
    names
}

/// Constructor name of a type reference with qualified prefixes resolved to the last
/// segment (`mypkg.Foo` -> `Foo`); generic arguments are ignored (`Foo<T>` -> `Foo`).
/// Returns None for an `?`-wrapped indirect reference, which stays allowed.
func directTypeName(ty: TypeSyntax): ?String {
    let tokens = ty.tokens
    var index = 0
    if (index < tokens.size && tokens[index].kind == QUEST) {
        return None
    }
    var name: ?String = None
    while (index < tokens.size) {
        let token = tokens[index]
        if (token.kind == IDENTIFIER) {
            name = token.value
        } else if (token.kind != DOT) {
            break
        }
        index += 1
    }
    name
}

/// Check the type and initializer restrictions for an abstract variable.
func validateVariableDeclaration(variable: VariableClause, context: TypeValidationContext,
    diagnostics: ArrayList<Diagnostic>): Unit {
    validateVariableType(variable, context.ownerName, diagnostics)
    match (variable.initExpr) {
        case Some(initValue) =>
            validateInitializerReferences(initValue.tokens, context, diagnostics)
        case None => ()
    }
}

/// An abstract variable may not name the enclosing type directly.
func validateVariableType(variable: VariableClause, ownerName: ?String,
    diagnostics: ArrayList<Diagnostic>): Unit {
    match (ownerName) {
        case Some(name) =>
            // Compare the direct constructor name instead of the raw token text, so
            // `Foo<T>` and `mypkg.Foo` are caught even though their token strings differ.
            // An `?`-wrapped (Option) indirect reference stays allowed.
            if (let Some(base) <- directTypeName(variable.ty)) {
                if (base == name) {
                    diagnostics.add(
                        Diagnostic("abstract variable `${variable.name.name}` cannot use the enclosing type `${name}`",
                            "type contract", variable.ty.tokens))
                }
            }
        case None => ()
    }
}

/// An initializer may only reference earlier abstract variables that have initial values.
func validateInitializerReferences(tokens: Tokens, context: TypeValidationContext,
    diagnostics: ArrayList<Diagnostic>): Unit {
    let reported = HashSet<String>()
    let reportedMembers = HashSet<String>()
    var index = 0
    while (index < tokens.size) {
        let token = tokens[index]
        if (token.kind == IDENTIFIER) {
            // `precededByDot` must be excluded here too: `other.size` in the
            // initializer reads another value's member, not the abstract variable
            // being referenced by name.
            if (context.declaredVariables.contains(token.value) && !context.initialized.contains(token.value) &&
                !precededByDot(tokens, index) && reported.add(token.value)) {
                diagnostics.add(
                    Diagnostic("abstract variable initializer may only reference earlier abstract variables with initial values: `${token.value}`",
                        "type contract", Tokens(token)))
            } else if (context.memberNames.contains(token.value) && !context.declaredVariables.contains(token.value) &&
                !precededByDot(tokens, index) && reportedMembers.add(token.value)) {
                diagnostics.add(
                    Diagnostic("abstract variable initializer may not read ordinary members or call member functions: `${token.value}`",
                        "type contract", Tokens(token)))
            }
        }
        index += 1
    }
}

/// Collect the names of members declared directly on a type so abstract variables can be checked
/// against them.
func collectMemberNames(owner: Decl): HashSet<String> {
    let names = HashSet<String>()
    match (owner) {
        case value: ClassDecl => collectBodyMemberNames(value.body, names)
        case value: StructDecl => collectBodyMemberNames(value.body, names)
        case value: InterfaceDecl => collectBodyMemberNames(value.body, names)
        case _ => ()
    }
    names
}

func collectBodyMemberNames(body: Body, names: HashSet<String>): Unit {
    for (member in body.decls) {
        collectMemberName(member, names)
    }
}

func collectMemberName(member: Decl, names: HashSet<String>): Unit {
    match (member) {
        case value: FuncDecl => addNonEmptyName(value.identifier.value, names)
        case value: PropDecl => addNonEmptyName(value.identifier.value, names)
        case value: VarDecl => addDeclaredVariableName(value, names)
        case _ => ()
    }
}

func addNonEmptyName(name: String, names: HashSet<String>): Unit {
    if (name.size > 0) {
        names.add(name)
    }
}

/// The identifier token bound by a variable-like declaration, including a simple
/// pattern binding.
func declaredVariableIdentifier(variable: VarDecl): ?Token {
    if (variable.identifier.value.size > 0) {
        return Some(variable.identifier)
    }
    if (let pattern: VarPattern <- variable.pattern) {
        return Some(pattern.identifier)
    }
    None
}

func addDeclaredVariableName(variable: VarDecl, names: HashSet<String>): Unit {
    if (let Some(identifier) <- declaredVariableIdentifier(variable)) {
        names.add(identifier.value)
    }
}

/// Generator-owned member names that user code must not declare. Exact `_contract_invariant`
/// and `_contract_static_invariant` stay available because users may supply their own checker.
func isGeneratedMemberName(name: String): Bool {
    name == "_contract_body" || name == "_contract_property_body" || name == "_contract_do_while_first_iteration" ||
        name.startsWith("_abs_") ||
        name.startsWith("_contract_aux_") ||
        name.startsWith("_contract_ctor_") ||
        name.startsWith("_contract_invariant_body") ||
        name.startsWith("_contract_property_body_") ||
        (name.startsWith("_contract_invariant_") && name != "_contract_invariant") ||
        (name.startsWith("_contract_static_invariant_") && name != "_contract_static_invariant")
}

func reportGeneratedMemberNames(owner: Decl, diagnostics: ArrayList<Diagnostic>): Unit {
    match (owner) {
        case value: ClassDecl => reportGeneratedNamesInBody(value.body, diagnostics)
        case value: StructDecl => reportGeneratedNamesInBody(value.body, diagnostics)
        case value: InterfaceDecl => reportGeneratedNamesInBody(value.body, diagnostics)
        case value: ExtendDecl => reportGeneratedNamesInBody(value.body, diagnostics)
        case _ => ()
    }
}

func reportGeneratedNamesInBody(body: Body, diagnostics: ArrayList<Diagnostic>): Unit {
    for (member in body.decls) {
        reportGeneratedNameOf(member, diagnostics)
    }
}

func reportGeneratedNameOf(member: Decl, diagnostics: ArrayList<Diagnostic>): Unit {
    match (member) {
        case method: FuncDecl => reportGeneratedMemberName(method.identifier, "function name", diagnostics)
        case value: PropDecl => reportGeneratedMemberName(value.identifier, "member name", diagnostics)
        case value: VarDecl => reportGeneratedVariableName(value, diagnostics)
        case _ => ()
    }
}

func reportGeneratedVariableName(variable: VarDecl, diagnostics: ArrayList<Diagnostic>): Unit {
    if (let Some(identifier) <- declaredVariableIdentifier(variable)) {
        reportGeneratedMemberName(identifier, "member name", diagnostics)
    }
}

func reportGeneratedMemberName(identifier: Token, kind: String, diagnostics: ArrayList<Diagnostic>): Unit {
    let name = identifier.value
    if (isGeneratedMemberName(name)) {
        let purpose = if (name.startsWith("_abs_") || name.startsWith("_contract_aux_")) {
            "storage"
        } else {
            "helpers"
        }
        diagnostics.add(
            Diagnostic("${kind} `${name}` is reserved for generated contract ${purpose}", "type contract",
                Tokens(identifier)))
    }
}

func enclosingTypeName(owner: Decl): ?String {
    match (owner) {
        case value: ClassDecl => Some(value.identifier.value)
        case value: StructDecl => Some(value.identifier.value)
        case value: InterfaceDecl => Some(value.identifier.value)
        case _ => None
    }
}
