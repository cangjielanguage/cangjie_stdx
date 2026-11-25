/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.parse

import stdx.contract.macros.syntax.{ContractDeclaration, ContractSyntax, Diagnostic}
import std.ast.{ClassDecl, Decl, DiagReportLevel, EnumDecl, ExtendDecl, FuncDecl, InterfaceDecl, ParseASTException, PrimaryCtorDecl, PropDecl, StructDecl, Tokens, diagReport, parseDecl}
import std.collection.{ArrayList}

/**
 * @brief Selects the contract grammar from the annotated declaration and parses the
 * `@Contract` clauses into a `ContractDeclaration`.
 *
 * The annotated declaration is parsed first, and its kind picks both the clause
 * grammar and the `ContractSyntax` variant: classes, structs, interfaces, and extends
 * use the type-level grammar, primary constructors and functions use the callable
 * grammar, and properties use the accessor grammar. Enum declarations and `@C` interop
 * types are rejected with a compile-time diagnostic and an empty contract; any other
 * declaration kind yields a diagnostic in the returned `ParseResult` instead.
 *
 * @param attr The contract clauses carried in `@Contract[...]`.
 * @param input The annotated declaration.
 * @return The parsed declaration with its contract syntax, carrying the diagnostics
 * collected while parsing the clauses.
 * @throws ParseASTException When the annotated declaration cannot be parsed and does
 * not have the primary-constructor shape.
 */
public func parseContract(attr: Tokens, input: Tokens): ParseResult<ContractDeclaration> {
    let declaration = parseAnnotatedDecl(input)

    func branch<T>(parser: (Tokens) -> ParseResult<T>, wrap: (T) -> ContractSyntax): ParseResult<ContractDeclaration> {
        let parsed = parser(attr)
        ParseResult(ContractDeclaration(declaration, wrap(parsed.value), attr), parsed.diagnostics)
    }

    // `@C` interop types are foreign memory layouts; contracts cannot be enforced on
    // them (design v2 §3.1.7). Only the `@C` annotation still visible on the parsed
    // declaration can be rejected, i.e. when `@Contract` is written before `@C`; when
    // `@C` comes first the compiler consumes it and this check cannot see it (the
    // documented limitation in contract_package_macros.md).
    if (declaration is StructDecl && hasCAnnotation(declaration)) {
        diagReport(DiagReportLevel.ERROR, input,
            "@Contract is not supported on `@C` interop types", "Contract")
        return ParseResult(ContractDeclaration(declaration, ContractSyntax.Empty, attr), ArrayList<Diagnostic>())
    }

    match (declaration) {
        case _: ClassDecl => branch(parseClassContract, {value => ContractSyntax.TypeLevel(value)})
        case _: StructDecl => branch(parseStructContract, {value => ContractSyntax.TypeLevel(value)})
        case _: InterfaceDecl => branch(parseInterfaceContract, {value => ContractSyntax.TypeLevel(value)})
        case _: ExtendDecl => branch(parseExtendContract, {value => ContractSyntax.TypeLevel(value)})
        case _: PrimaryCtorDecl => branch(parseConstructorContract, {value => ContractSyntax.Callable(value)})
        case _: FuncDecl => branch(parseFunctionContract, {value => ContractSyntax.Callable(value)})
        case _: PropDecl => branch({tokens => parsePropertyContract(tokens)}, {value => ContractSyntax.Property(value)})
        case _: EnumDecl =>
            diagReport(DiagReportLevel.ERROR, input,
                "@Contract has no effect on enum declarations; enums do not support contracts",
                "Contract")
            ParseResult(ContractDeclaration(declaration, ContractSyntax.Empty, attr), ArrayList<Diagnostic>())
        case _ =>
            let diagnostics = ArrayList<Diagnostic>()
            diagnostics.add(
                Diagnostic(
                    "@Contract supports functions, methods, properties, classes, and structs",
                    "bad decl kind", input))
            ParseResult(ContractDeclaration(declaration, ContractSyntax.Empty, attr), diagnostics)
    }
}

/// Whether the declaration carries the built-in `@C` interop annotation. The annotation
/// identifier is `C`; other annotations on the same declaration (including `@Contract`
/// itself) are ignored.
func hasCAnnotation(declaration: Decl): Bool {
    for (annotation in declaration.annotations) {
        if (annotation.identifier.value == "C") {
            return true
        }
    }
    false
}

/// The default `parseDecl` cannot parse a primary constructor (`C(public let x: T) { ... }`)
/// and throws `ParseASTException` because of the missing `func` keyword. When the failed
/// tokens have the primary-constructor shape, retry with `astKind: "PrimaryCtorDecl"`.
func parseAnnotatedDecl(input: Tokens): Decl {
    try {
        return parseDecl(input)
    } catch (e: ParseASTException) {
        if (isPrimaryCtorShape(input)) {
            return parseDecl(input, astKind: "PrimaryCtorDecl")
        }
        throw e
    }
}

/// Whether the tokens look like a primary constructor: an identifier followed by `(` at
/// the head of the declaration, with no declaration keyword in front.
func isPrimaryCtorShape(input: Tokens): Bool {
    var index: Int64 = 0
    while (index < input.size && input[index].kind == NL) {
        index += 1
    }
    index + 1 < input.size && input[index].kind == IDENTIFIER && input[index + 1].kind == LPAREN
}
