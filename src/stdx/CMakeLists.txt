# Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
#
# This source file is part of the Cangjie project, licensed under Apache-2.0
# with Runtime Library Exception.
#
# See https://cangjie-lang.cn/pages/LICENSE for license information.

add_subdirectory(dynamicLoader)
add_subdirectory(compress)
add_subdirectory(serialization)
add_subdirectory(encoding)
if(NOT CANGJIE_CJPM_BUILD_TYPE OR NOT WIN32)
    add_subdirectory(fuzz)
endif()
add_subdirectory(log)
add_subdirectory(logger)
add_subdirectory(crypto)
add_subdirectory(net)
add_subdirectory(unittest)
add_subdirectory(actors)
add_subdirectory(string_intern)

if(DEFINED CHIR_FLATC_SOURCE_FILES)
    set(CHIR_FLATC_SOURCE_FILES ${CHIR_FLATC_SOURCE_FILES} PARENT_SCOPE)
endif()

message(STATUS "CMAKE_BUILD_STAGE ${CMAKE_BUILD_STAGE}")
if(NOT CANGJIE_CJPM_BUILD_TYPE AND NOT CANGJIE_BUILD_WITHOUT_CHIR)
    add_subdirectory(chir)
endif()
if(NOT CANGJIE_CJPM_BUILD_TYPE AND NOT CANGJIE_BUILD_WITHOUT_SYNTAX AND NOT TRIPLE STREQUAL "arm-linux-ohos")
    add_subdirectory(syntax)
endif()

if(CANGJIE_CODEGEN_CJNATIVE_BACKEND AND "$ENV{NO_ASPECT_CJ}" STREQUAL "" AND NOT CANGJIE_CJPM_BUILD_TYPE)
    if(CMAKE_CROSSCOMPILING AND "$ENV{CANGJIE_LSP_PATH}" STREQUAL "")
        # Nothing to do
    elseif(NOT CANGJIE_BUILD_WITHOUT_CHIR)
        if(NOT CANGJIE_BUILD_WITHOUT_PLUGIN)
            add_subdirectory(plugin)
        endif()
        if(NOT CANGJIE_BUILD_WITHOUT_ASPECT_CJ)
            add_subdirectory(aspect_cj)
        endif()
    endif()
endif()

if(NOT CANGJIE_BUILD_WITHOUT_EFFECT_HANDLERS)
    add_subdirectory(effect)
endif()
