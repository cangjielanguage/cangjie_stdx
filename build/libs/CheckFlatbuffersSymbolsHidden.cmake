# Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
#
# This source file is part of the Cangjie project, licensed under Apache-2.0
# with Runtime Library Exception.
#
# See https://cangjie-lang.cn/pages/LICENSE for license information.

# Fails if LIB dynamically exports Cangjie package `flatbuffers` symbols.
# std.ast, stdx.syntax and stdx.chir each statically embed this package.
# Default visibility would let the ELF dynamic linker interpose one copy.
#
# Expected -D:
#   LIB  path to the DSO that force-links cangjie-flatbuffers
#   NM   optional nm / llvm-nm executable

if(NOT DEFINED LIB OR "${LIB}" STREQUAL "")
    message(FATAL_ERROR "CheckFlatbuffersSymbolsHidden: LIB is not set")
endif()
if(NOT EXISTS "${LIB}")
    message(FATAL_ERROR "CheckFlatbuffersSymbolsHidden: library not found: ${LIB}")
endif()

set(_nm_candidates)
if(DEFINED NM AND NOT "${NM}" STREQUAL "")
    list(APPEND _nm_candidates "${NM}")
endif()
list(APPEND _nm_candidates nm llvm-nm)

set(_nm_out "")
set(_nm_ok FALSE)
foreach(_nm ${_nm_candidates})
    execute_process(
        COMMAND ${_nm} -D --defined-only "${LIB}"
        OUTPUT_VARIABLE _nm_out
        ERROR_VARIABLE _nm_err
        RESULT_VARIABLE _nm_rc
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(_nm_rc EQUAL 0)
        set(_nm_ok TRUE)
        break()
    endif()
endforeach()

if(NOT _nm_ok)
    execute_process(
        COMMAND readelf --dyn-syms -W "${LIB}"
        OUTPUT_VARIABLE _nm_out
        ERROR_VARIABLE _nm_err
        RESULT_VARIABLE _nm_rc
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(NOT _nm_rc EQUAL 0)
        message(FATAL_ERROR
            "CheckFlatbuffersSymbolsHidden: cannot read dynamic symbols of ${LIB}: ${_nm_err}")
    endif()
endif()

string(REGEX MATCH "_C(N|GP)11flatbuffers" _hit "${_nm_out}")
if(_hit)
    message(FATAL_ERROR
        "CheckFlatbuffersSymbolsHidden: ${LIB} exports Cangjie flatbuffers package "
        "symbol(s) (e.g. ${_hit}). They must be hidden (link with "
        "--exclude-libs=libcangjie-flatbuffers.a) so a process that also loads "
        "std.ast / stdx.syntax / stdx.chir cannot interpose a second copy.")
endif()
