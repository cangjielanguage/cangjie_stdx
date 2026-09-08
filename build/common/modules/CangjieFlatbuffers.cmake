# Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
#
# This source file is part of the Cangjie project, licensed under Apache-2.0
# with Runtime Library Exception.
#
# See https://cangjie-lang.cn/pages/LICENSE for license information.

# Resolve FlatBuffers toolchain from the compiler SDK ($CANGJIE_HOME).
# Used by stdx.chir / stdx.syntax (same model as std.ast).

if(NOT DEFINED ENV{CANGJIE_HOME} OR "$ENV{CANGJIE_HOME}" STREQUAL "")
    message(FATAL_ERROR "CANGJIE_HOME is not set. Source the compiler envsetup.sh first.")
endif()

set(CANGJIE_FLATBUFFERS_DIR "$ENV{CANGJIE_HOME}/third_party/flatbuffers")
set(CANGJIE_FLATBUFFERS_FLATC "${CANGJIE_FLATBUFFERS_DIR}/bin/flatc")
set(CANGJIE_FLATBUFFERS_INCLUDE_DIR "${CANGJIE_FLATBUFFERS_DIR}/include")
set(CANGJIE_FLATBUFFERS_CANGJIE_DIR "${CANGJIE_FLATBUFFERS_DIR}/cangjie")
set(CANGJIE_CHIR_FORMAT_FBS "$ENV{CANGJIE_HOME}/schema/StdxChirFormat.fbs")

if(NOT EXISTS "${CANGJIE_FLATBUFFERS_FLATC}")
    message(FATAL_ERROR "flatc not found: ${CANGJIE_FLATBUFFERS_FLATC}")
endif()
if(NOT EXISTS "${CANGJIE_FLATBUFFERS_INCLUDE_DIR}/flatbuffers/flatbuffers.h")
    message(FATAL_ERROR "flatbuffers headers not found under ${CANGJIE_FLATBUFFERS_INCLUDE_DIR}")
endif()
if(NOT EXISTS "${CANGJIE_FLATBUFFERS_CANGJIE_DIR}")
    message(FATAL_ERROR "flatbuffers cangjie sources not found: ${CANGJIE_FLATBUFFERS_CANGJIE_DIR}")
endif()
if(NOT EXISTS "${CANGJIE_CHIR_FORMAT_FBS}")
    message(FATAL_ERROR "StdxChirFormat.fbs not found: ${CANGJIE_CHIR_FORMAT_FBS}")
endif()

message(STATUS "Cangjie flatbuffers dir: ${CANGJIE_FLATBUFFERS_DIR}")
message(STATUS "Cangjie flatbuffers flatc: ${CANGJIE_FLATBUFFERS_FLATC}")

# Generate *_generated.cj from a .fbs schema into OUTPUT_DIR (no vendored runtime embed).
# Usage:
#   cangjie_add_flatbuffers_cj_outputs(
#       TARGET <custom_target_name>
#       SCHEMA <path/to/Foo.fbs>
#       OUTPUT_DIR <dir for Foo_generated.cj>
#       [OUTPUT_VAR <var>])   # optional: set var to the generated .cj path
function(cangjie_add_flatbuffers_cj_outputs)
    set(one_value_args TARGET SCHEMA OUTPUT_DIR OUTPUT_VAR)
    cmake_parse_arguments(FB "" "${one_value_args}" "" ${ARGN})
    if(NOT FB_TARGET OR NOT FB_SCHEMA OR NOT FB_OUTPUT_DIR)
        message(FATAL_ERROR "cangjie_add_flatbuffers_cj_outputs requires TARGET, SCHEMA, OUTPUT_DIR")
    endif()
    if(NOT EXISTS "${FB_SCHEMA}")
        message(FATAL_ERROR "FlatBuffers schema not found: ${FB_SCHEMA}")
    endif()

    get_filename_component(_fb_name "${FB_SCHEMA}" NAME_WE)
    set(_fb_gen_cj "${FB_OUTPUT_DIR}/${_fb_name}_generated.cj")
    set(_fb_tmp_cj "${CMAKE_BINARY_DIR}/${_fb_name}_generated.cj")

    add_custom_command(
        OUTPUT "${_fb_gen_cj}"
        COMMAND "${CANGJIE_FLATBUFFERS_FLATC}" --no-warnings --cangjie
                -o "${CMAKE_BINARY_DIR}" "${FB_SCHEMA}"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${_fb_tmp_cj}" "${_fb_gen_cj}"
        DEPENDS "${CANGJIE_FLATBUFFERS_FLATC}" "${FB_SCHEMA}"
        COMMENT "generate ${_fb_name}_generated.cj"
        VERBATIM)

    add_custom_target(${FB_TARGET} ALL DEPENDS "${_fb_gen_cj}")
    if(FB_OUTPUT_VAR)
        set(${FB_OUTPUT_VAR} "${_fb_gen_cj}" PARENT_SCOPE)
    endif()
endfunction()
