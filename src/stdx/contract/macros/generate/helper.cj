/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.macros.generate

import stdx.contract.macros.tokens.{appendLiteralRun, isValue}
import stdx.contract.runtime.ContractVisibility
import std.ast.{FuncDecl, Modifier, Tokens}
import std.collection.{ArrayList, contains}

func modifiersHave(modifiers: ArrayList<Modifier>, name: String): Bool {
    for (modifier in modifiers) {
        if (isValue(modifier.keyword, name)) {
            return true
        }
    }
    false
}

func methodHasModifier(owner: FuncDecl, name: String): Bool {
    modifiersHave(owner.modifiers, name)
}

/// Visibility declared by `modifiers`. Interface members are implicitly `public`, so the
/// interface replay passes `ContractVisibility.Public` as the default for unmodified
/// members; classes and structs keep the `internal` default.
func visibilityOf(modifiers: ArrayList<Modifier>,
    defaultVisibility!: ContractVisibility = ContractVisibility.Internal): ContractVisibility {
    if (modifiersHave(modifiers, "private")) {
        ContractVisibility.Private
    } else if (modifiersHave(modifiers, "public")) {
        ContractVisibility.Public
    } else if (modifiersHave(modifiers, "protected")) {
        ContractVisibility.Protected
    } else {
        defaultVisibility
    }
}

func visibilityTokens(visibility: ContractVisibility): Tokens {
    match (visibility) {
        case ContractVisibility.Private => quote(ContractVisibility.Private)
        case ContractVisibility.Internal => quote(ContractVisibility.Internal)
        case ContractVisibility.Protected => quote(ContractVisibility.Protected)
        case ContractVisibility.Public => quote(ContractVisibility.Public)
    }
}

/// Escape a clause's source text before it is embedded into a generated string literal:
/// - `${` would otherwise interpolate the very identifiers the clause mentions and fail
///   to compile (`undeclared identifier`) instead of showing the clause verbatim;
///   `\u{24}` spells the dollar sign inside the generated literal.
/// - backslashes are doubled because the generated literal's escape sequences are
///   interpreted once at parse time; doubling keeps the message byte-for-byte identical
///   to the clause source (e.g. `\\n` in source must not render as a newline).
func escapeInterpolationText(text: String): String {
    // Split so this source file's own literal does not start an interpolation.
    let marker = "$" + "{"
    let slash = "\\"
    if (!text.contains(marker) && !text.contains(slash)) {
        return text
    }
    let builder = StringBuilder()
    var index = 0
    while (index < text.size) {
        if (text[index] == 92) {
            builder.append("\\\\")
            index += 1
            continue
        }
        if (text[index] == 36 && index + 1 < text.size && text[index + 1] == 123) {
            builder.append("\\u{24}{")
            index += 2
            continue
        }
        index = appendLiteralRun(builder, text, index)
    }
    builder.toString()
}
