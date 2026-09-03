/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

macro package stdx.plugin

public import stdx.plugin.manager.*
import std.ast.*

public macro CHIRPlugin(input: Tokens): Tokens {
    var subClassDecl: ClassDecl
    if (let Some(decl) <- (parseDecl(input) as ClassDecl)) {
        subClassDecl = decl
    } else {
        throw Exception("CHIRPlugin must be applied to a class declaration.")
    }
    if (subClassDecl.isGenericDecl) {
        throw Exception("CHIRPlugin cannot be applied to a generic class.")
    }
    var superTypes = subClassDecl.superTypes
    for (superType in superTypes) {
        if (let Some(refType) <- (superType as RefType)) {
            let superName = refType.identifier.value
            if (superName == "CHIRPluginBase") {
                throw Exception("Class '${subClassDecl.identifier.value}' must not inherit from CHIRPluginBase manually; the @CHIRPlugin macro adds this base class.")
            }
        }
    }

    // 1. add super type (class must be first in the supertype list)
    superTypes.add(RefType(quote(CHIRPluginBase)), at: 0)

    // 2. add init func
    let subClassName = Token(TokenKind.STRING_LITERAL, subClassDecl.identifier.value)
    let initToken = quote(
        internal init() {
            super($subClassName)
        }
    )
    let initDecl = parseDecl(initToken)
    subClassDecl.body.decls.add(initDecl)

    // 3. add registerPlugin func
    let registerPluginToken = quote(
        static init() {
            PluginManager.registerCHIRPlugin({ => $(subClassDecl.identifier)() })
        }
    )
    let registerPluginDecl = parseDecl(registerPluginToken)
    subClassDecl.body.decls.add(registerPluginDecl)

    return subClassDecl.toTokens()
}
