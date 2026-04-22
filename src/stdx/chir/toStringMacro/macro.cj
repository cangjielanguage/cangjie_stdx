/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

protected macro package stdx.chir.toStringMacro

import std.ast.*

/**
 * Automatically injects `ToString` inheritance and `toString` implementation for enums.
 * @param input Input enum declaration tokens.
 * @return The transformed enum declaration tokens.
 */
public macro CHIREnumToString(input: Tokens): Tokens {
    let enumDecl = (parseDecl(input) as EnumDecl).getOrThrow()
    let superTypes = enumDecl.superTypes
    for (superType in superTypes) {
        let superName = (superType as RefType).getOrThrow().identifier.value
        if (superName == "ToString") {
            diagReport(DiagReportLevel.ERROR, superType.toTokens(), "can't inherit from interface ToString manually.", "")
            return Tokens(Token(TokenKind.ILLEGAL))
        }
    }
    // 1. add super type
    superTypes.add(RefType(quote(ToString)))

    // 2. create match case
    var caseTokens: Tokens = Tokens()
    for (ctor in enumDecl.constructors) {
        let nameStr = ctor.identifier.value.removePrefix("`").removeSuffix("`")
        let ctorName = Token(TokenKind.STRING_LITERAL, nameStr)
        caseTokens += quote(
            case $(ctor.identifier) => $ctorName
        )
    }
    if (enumDecl.ellipsis.kind == TokenKind.ELLIPSIS) {
        caseTokens += quote(
            case _ => throw CHIRException($(enumDecl.identifier.value) + ": Unknown enum element")
        )
    }

    // 3. create func toString
    let toStringFunc = quote(
        /**
         * Performs the public behavior of `toString`.
         * @return The `String` result.
         */
        public func toString(): String {
            match (this) {
                $caseTokens
            }
        }
    )
    let funcDecl = parseDecl(toStringFunc)
    enumDecl.decls.add(funcDecl)
    return enumDecl.toTokens()
}
