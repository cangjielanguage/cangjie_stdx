/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

macro package stdx.contract.macros

public import stdx.contract.runtime.{ContractCheckAssertException, ContractCheckEnsuresException, ContractCheckException, ContractCheckGhostStateException, ContractCheckInvariantException, ContractCheckLoopInvariantException, ContractCheckRequiresException, ContractCheckThrowsException, ContractVisibility, _contract_gateEnabled, contractCaptureSnapshot, contractCheckEnabled, contractEvalEnter, contractEvalExit, contractGhostGet, contractInEvaluation, disableContractChecks, isContractException}
import stdx.contract.macros.generate.{ResolvedInvariant, absorbLocalFunctionContracts, absorbPropertyLocalContracts, declaresMemberInheritClause, genAssert, genClassContract, genConstructorContract, genConstructorFuncContract, genExtendContract, genFunction, genGhost, genInterfaceContract, genLoopInvariant, genPropertyContract, genStructContract, setterParameterName, storeDeferredMethodContract, storeDeferredPropertyContract}
import stdx.contract.macros.parse.{parseContract, parseContractAssert, parseContractGhost, parseLoopInvariant, parsePropertyContract}
import stdx.contract.macros.syntax.{ContractSyntax, Diagnostic, FunctionClause, FunctionContract, PropContract, PropKind, TypeContract}
import stdx.contract.macros.validation.{callableBlock, reportConstructorEnsuresReturn, validateConstructorContract, validateFunctionContract, validateGhostUsage, validatePropertyContract, validatePropertyGhostUsage, validateTypeContract}
import stdx.contract.macros.tokens.isValue
import std.ast.{ASTException, ClassDecl, Decl, DiagReportLevel, ExtendDecl, FuncDecl, InterfaceDecl, ParseASTException, PrimaryCtorDecl, PropDecl, StructDecl, Tokens, diagReport, insideParentContext}
import std.collection.{ArrayList, HashSet}

/**
 * @brief Declares ghost code: auxiliary statements that execute only when contract
 * checking is enabled and the current execution is not inside contract-expression
 * evaluation.
 *
 * The ghost body is preserved as written and lowered behind the contract eligibility
 * gate, so it is typically used to maintain auxiliary logic such as the abstract state
 * declared in type contracts, without affecting business behavior. The macro does not
 * require the host function to be annotated with `@Contract`; when unannotated, it
 * still expands and execution is gated only by the `contract_check` switch.
 *
 * Usage: `@ghost(<statements>)`.
 *
 * @param input The ghost code.
 * @return The lowered tokens; the original input when the ghost block fails to parse.
 */
public macro ghost(input: Tokens): Tokens {
    Diagnostic.fallback = input
    let parsed = try {
        parseContractGhost(input)
    } catch (error: ParseASTException) {
        diagReport(DiagReportLevel.ERROR, input, "ghost block failed to parse: ${error.message}", "ghost")
        return input
    }
    genGhost(parsed)
}

/**
 * @brief Declares assertions in a function body. When checking is enabled and an
 * assertion expression evaluates to false, `ContractCheckAssertException` is thrown
 * with the message `assertion failed: <assertion expression>`.
 *
 * The macro does not require the host function to be annotated with `@Contract`; when
 * unannotated, it still expands and execution is gated only by the `contract_check`
 * switch. At least one assertion expression is required, and `$pre` snapshots are not
 * available here.
 *
 * Usage: `@contractAssert(<expression>)`.
 *
 * @param input The assertion expression(s).
 * @return The lowered tokens; the original input when parsing reports an error, so
 * error recovery does not change program semantics.
 */
public macro contractAssert(input: Tokens): Tokens {
    let parsed = parseContractAssert(input)
    if (parsed.hasError()) {
        parsed.report()
        // Keep the original code so error recovery does not change program semantics,
        // mirroring the other macros of this package.
        return input
    }
    genAssert(parsed.value)
}

/**
 * @brief Declares loop invariants for a loop. When checking is enabled and an
 * invariant evaluates to false, `ContractCheckLoopInvariantException` is thrown with
 * the message `loop invariant failed: <invariant expression>`.
 *
 * A `while` loop is checked once at the start of each iteration and once after the
 * loop exits (also when the loop body never executes); a `for-in` loop is checked
 * only at the start of each iteration; a `do-while` loop is checked after each
 * execution of the loop body, before the condition is evaluated. The macro does not
 * require the host function to be annotated with `@Contract`.
 *
 * Usage: `@loopInvariant[<invariant expressions>](<loop expression>)`; the loop must
 * be a `for-in`, `while`, or `do-while` expression (the property-style form
 * `@loopInvariant[...] <loop>` is not supported), and at least one invariant is
 * required.
 *
 * @param definitions The list of invariant expressions, carried in `[]`; at least one.
 * @param input The loop expression to be checked, passed as the second argument in
 * `()`.
 * @return The lowered tokens; the original input when parsing reports an error, so
 * error recovery does not change program semantics.
 */
public macro loopInvariant(definitions: Tokens, input: Tokens): Tokens {
    let parsed = parseLoopInvariant(definitions, input)
    if (parsed.hasError()) {
        parsed.report()
        return input
    }
    genLoopInvariant(parsed.value)
}

/**
 * @brief Declares contract clauses for functions, constructors (including primary
 * constructors), properties, and class, struct, interface, and extend type
 * declarations.
 *
 * The macro parses the clauses carried in `[]`, validates them against the annotated
 * declaration, and rewrites the declaration (or the accessors of a property) to embed
 * the contract checks. Functions and the `get`/`set` of properties support the
 * `requires`, `ensures`, `throws`, `variable`, and `inherits` clauses; types support
 * the `variable`, `invariant` (with visibility selectors such as `on_public`), and
 * `inherits` clauses. Contract checking is controlled by the compile-time
 * `contract_check` conditional compilation variable, with a one-shot one-way runtime
 * demotion through `disableContractChecks`.
 *
 * Supported declaration kinds follow the documented restrictions (e.g. enum is not
 * supported, member contracts using `inherits` require an enclosing type contract,
 * constructor contracts do not support `ensures r: <expr>`). When the expansion fails
 * (a parse error or a validation error), a compile-time diagnostic is reported and the
 * original input tokens are returned unchanged, so error recovery does not change
 * program semantics.
 *
 * Usage: `@Contract[<clauses>] <declaration>`.
 *
 * @param attr The contract clauses carried in `[]`.
 * @param input The annotated declaration.
 * @return The expanded tokens; the original input when expansion reports an error.
 */
public macro Contract(attr: Tokens, input: Tokens): Tokens {
    expandContract(attr, input)
}

/**
 * @brief Declares an empty contract on a declaration, equivalent to
 * `@Contract[] <declaration>` with no clauses.
 *
 * The declaration is still registered with the enclosing type contract, so its
 * type-level generation performs the member rewriting: deferred contracts of local
 * functions inside the body are lowered, member `@Contract` attributes are recorded
 * for contract inheritance, and the declaration participates in type invariant
 * checking according to its visibility.
 *
 * Usage: `@Contract <declaration>`.
 *
 * @param input The annotated declaration.
 * @return The expanded tokens; the original input when expansion reports an error.
 */
public macro Contract(input: Tokens): Tokens {
    expandContract(Tokens(), input)
}

func expandContract(attr: Tokens, input: Tokens): Tokens {
    Diagnostic.fallback = input
    let parsed = try {
        parseContract(attr, input)
    } catch (error: ParseASTException) {
        diagReport(DiagReportLevel.ERROR, input, "contract declaration failed to parse: ${error.message}", "Contract")
        return input
    }
    if (parsed.hasError()) {
        parsed.report()
        return input
    }

    let declaration = parsed.value.declaration
    match (parsed.value.contract) {
        case ContractSyntax.Callable(contract) => expandCallableContract(attr, input, contract, declaration)
        case ContractSyntax.Property(contract) => expandPropertyContract(attr, input, contract, declaration)
        case ContractSyntax.TypeLevel(contract) =>
            if (!validateTypeContract(contract, declaration)) {
                return input
            }
            expandTypeLevelContract(input, contract, declaration)
        case ContractSyntax.Empty => input
    }
}

func expandTypeLevelContract(input: Tokens, contract: TypeContract, declaration: Decl): Tokens {
    match (declaration) {
        case owner: ClassDecl => genClassContract(contract, owner)
        case owner: StructDecl => genStructContract(contract, owner)
        case owner: InterfaceDecl => genInterfaceContract(contract, owner)
        case owner: ExtendDecl => genExtendContract(contract, owner)
        case _ =>
            diagReport(DiagReportLevel.WARNING, input,
                "@Contract type-level clauses do not apply to this declaration kind; the contract is ignored",
                "Contract")
            input
    }
}

func expandCallableContract(attr: Tokens, input: Tokens, contract: FunctionContract, declaration: Decl): Tokens {
    match (declaration) {
        case owner: PrimaryCtorDecl => expandConstructorCallable(input, contract, owner)
        case owner: FuncDecl => expandFunctionCallable(attr, input, contract, owner)
        case _ =>
            diagReport(DiagReportLevel.WARNING, input,
                "@Contract callable clauses do not apply to this declaration kind; the contract is ignored",
                "Contract")
            input
    }
}

func expandConstructorCallable(input: Tokens, contract: FunctionContract, owner: PrimaryCtorDecl): Tokens {
    let returnBindingOk = reportConstructorEnsuresReturn(contract)
    if (!returnBindingOk || !validateConstructorContract(contract, owner)) {
        return input
    }
    validateGhostUsage(contract.clauses, callableBlock({=> owner.block}), owner.funcParams)
    genConstructorContract(contract, owner)
}

func expandFunctionCallable(attr: Tokens, input: Tokens, contract: FunctionContract, owner: FuncDecl): Tokens {
    // The body-less guard must run before validation: validation reads
    // `owner.block`, which throws `ASTException` for a declaration without a
    // body and would surface as a macro-internal failure instead of this
    // diagnostic. Inside an enclosing type contract the guard does not apply:
    // bodiless interface/abstract members are legitimate there, their contract
    // is deferred to the type-level generation via `storeDeferredMethodContract`.
    if (!insideParentContext("Contract") && !directFuncHasModifier(owner, "foreign") &&
        !functionHasBody(owner)) {
        diagReport(DiagReportLevel.ERROR, attr,
            "`@Contract` cannot annotate a function without a body; declare the contract on the enclosing type instead",
            "Contract")
        return input
    }
    if (!validateFunctionContract(contract, owner)) {
        return input
    }
    validateGhostUsage(contract.clauses, callableBlock({=> owner.block}), owner.funcParams)
    if (owner.identifier.value == "init") {
        return expandInitCallable(input, contract, owner)
    }
    if (insideParentContext("Contract")) {
        return expandDeferredCallable(attr, input, owner)
    }
    if (declaresMemberInheritClause(contract)) {
        // Contract inheritance is defined on type members; a top-level function
        // has no enclosing type whose parents could provide the contracts.
        diagReport(DiagReportLevel.ERROR, attr,
            "inherited function contracts require an enclosing type contract",
            "contract inheritance")
        return input
    }
    absorbLocalFunctionContracts(owner)
    genFunction(contract, owner)
}

func expandInitCallable(input: Tokens, contract: FunctionContract, owner: FuncDecl): Tokens {
    if (!reportConstructorEnsuresReturn(contract)) {
        return input
    }
    absorbLocalFunctionContracts(owner)
    genConstructorFuncContract(contract, owner)
}

func expandDeferredCallable(attr: Tokens, input: Tokens, owner: FuncDecl): Tokens {
    // Only the enclosing type contract knows the declared parents and the
    // members' contracts, so every member is generated there exactly once.
    // Local functions inside this body deferred their contracts to this
    // context; lower them before the declaration is stored or passed on.
    let absorbed = absorbLocalFunctionContracts(owner)
    if (attr.size > 0) {
        storeDeferredMethodContract(owner, attr)
    }
    if (absorbed) {
        owner.toTokens()
    } else {
        input
    }
}

func expandPropertyContract(attr: Tokens, input: Tokens, contract: PropContract, declaration: Decl): Tokens {
    match (declaration) {
        case owner: PropDecl => expandPropertyOwner(attr, input, contract, owner)
        case _ =>
            diagReport(DiagReportLevel.WARNING, input,
                "@Contract property clauses do not apply to this declaration kind; the contract is ignored",
                "Contract")
            input
    }
}

func expandPropertyOwner(attr: Tokens, input: Tokens, contract: PropContract, owner: PropDecl): Tokens {
    let effective = match (effectivePropertyContract(attr, contract, owner)) {
        case Some(value) => value
        case None => return input
    }
    if (!validatePropertyContract(effective, owner)) {
        return input
    }
    validatePropertyGhostUsage(effective, owner)
    if (insideParentContext("Contract")) {
        storeDeferredPropertyContract(owner, attr)
        return input
    }
    if (propertyDeclaresInherit(effective)) {
        diagReport(DiagReportLevel.ERROR, attr,
            "inherited property contracts require an enclosing type contract",
            "contract inheritance")
        return input
    }
    // Accessor bodies are required to wrap the checks; an abstract property
    // (interface / abstract class) has none.
    if (!propertyHasAccessorBody(owner, declaresSetterClauses(effective))) {
        diagReport(DiagReportLevel.ERROR, attr,
            "`@Contract` requires accessor bodies; declare contracts of abstract properties on the enclosing type instead",
            "Contract")
        return input
    }
    // Property contracts do not require an enclosing type `@Contract`, so the
    // accessors are generated without invariant calls.
    // Local functions inside the accessor bodies deferred their contracts to
    // this context; lower them before the accessors are wrapped.
    absorbPropertyLocalContracts(owner)
    genPropertyContract(effective, owner, ArrayList<ResolvedInvariant>(), false,
        HashSet<String>(), hostKnown: false)
}

func effectivePropertyContract(attr: Tokens, contract: PropContract, owner: PropDecl): ?PropContract {
    // Clauses are parsed against the canonical setter alias `value`; when the
    // setter's real parameter carries another name, re-parse with the real
    // name so alias rewriting happens up front.
    let alias = setterParameterName(owner)
    if (alias == "value") {
        return Some(contract)
    }
    let reparsed = parsePropertyContract(attr, setterAlias: alias)
    if (reparsed.hasError()) {
        reparsed.report()
        return None
    }
    Some(reparsed.value)
}

func propertyDeclaresInherit(contract: PropContract): Bool {
    for (clause in contract.clauses) {
        for (functionClause in clause.clauses) {
            if (let FunctionClause.Inherit(_) <- functionClause) {
                return true
            }
        }
    }
    false
}

/// Whether the function carries a real body: interface/abstract declarations have no
/// block tokens at all, while an empty `{}` body keeps its braces.
func functionHasBody(owner: FuncDecl): Bool {
    try {
        owner.block.toTokens().size != 0
    } catch (_: ASTException) {
        false
    }
}

/// Whether the property declares any `set` clause, so a setter body is required too.
func declaresSetterClauses(contract: PropContract): Bool {
    for (clause in contract.clauses) {
        match (clause.kind) {
            case PropKind.Setter => return true
            case _ => ()
        }
    }
    false
}

/// Whether the directly annotated function carries one of the given declaration modifiers.
func directFuncHasModifier(owner: FuncDecl, name: String): Bool {
    for (modifier in owner.modifiers) {
        if (isValue(modifier.keyword, name)) {
            return true
        }
    }
    false
}

/// Whether every accessor the contract needs carries a body. Reading `.block` of a
/// body-less accessor throws `ASTException`.
func propertyHasAccessorBody(owner: PropDecl, needSetter: Bool): Bool {
    let getterOk = try {
        owner.getter.block.toTokens().size != 0
    } catch (_: ASTException) {
        false
    }
    if (!getterOk) {
        return false
    }
    if (!needSetter) {
        return true
    }
    try {
        owner.setter.block.toTokens().size != 0
    } catch (_: ASTException) {
        false
    }
}
