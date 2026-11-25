# Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
#
# This source file is part of the Cangjie project, licensed under Apache-2.0
# with Runtime Library Exception.
#
# See https://cangjie-lang.cn/pages/LICENSE for license information.

set(CONTRACT_RUNTIME_SRCS
    runtime.cj
    visibility.cj
    CACHE INTERNAL "")

set(CONTRACT_MACROS_SRCS
    contract_macro.cj
    CACHE INTERNAL "")

set(CONTRACT_MACROS_TOKENS_SRCS
    token_cursor.cj
    tokens.cj
    CACHE INTERNAL "")

set(CONTRACT_MACROS_SYNTAX_SRCS
    clause.cj
    contract.cj
    diagnostic.cj
    node.cj
    CACHE INTERNAL "")

set(CONTRACT_MACROS_PARSE_SRCS
    body.cj
    clause.cj
    parse_result.cj
    declaration.cj
    expression.cj
    function.cj
    property.cj
    snapshot.cj
    type.cj
    CACHE INTERNAL "")

set(CONTRACT_MACROS_VALIDATION_SRCS
    constructor.cj
    function.cj
    ghost.cj
    property.cj
    type.cj
    CACHE INTERNAL "")

set(CONTRACT_MACROS_INHERITANCE_SRCS
    expand.cj
    metadata.cj
    persist.cj
    resolve.cj
    CACHE INTERNAL "")

set(CONTRACT_MACROS_GENERATE_SRCS
    auxiliary.cj
    body.cj
    callable.cj
    constructor.cj
    context.cj
    deferred.cj
    function.cj
    helper.cj
    interface.cj
    resolved_invariant.cj
    property.cj
    type.cj
    variable.cj
    CACHE INTERNAL "")
