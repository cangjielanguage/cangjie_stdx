# Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
#
# This source file is part of the Cangjie project, licensed under Apache-2.0
# with Runtime Library Exception.
#
# See https://cangjie-lang.cn/pages/LICENSE for license information.
#
# Shared FlatBuffers generation for chir. Invoked via:
#   cmake -DCHIR_SOURCE_DIR=... -DCHIR_BUILD_DIR=... -DCHIR_REPO_DIR=... -DCHIR_SCHEMA_SRC=... -P GenerateFlatbuffers.cmake

if(NOT CHIR_SOURCE_DIR OR NOT CHIR_BUILD_DIR OR NOT CHIR_REPO_DIR OR NOT CHIR_SCHEMA_SRC)
    message(FATAL_ERROR "GenerateFlatbuffers.cmake: missing required -D arguments")
endif()

get_filename_component(_filename ${CHIR_SCHEMA_SRC} NAME_WE)
set(_flatc "${CHIR_BUILD_DIR}/bin/flatc")
set(_fb_cj "${CHIR_REPO_DIR}/third_party/flatbuffers/cangjie")
set(_flatc_out "${CHIR_BUILD_DIR}/${_filename}_generated.cj")

if(NOT EXISTS "${_flatc}")
    message(FATAL_ERROR "flatc not found: ${_flatc}")
endif()

execute_process(
    COMMAND "${_flatc}" --no-warnings --cangjie -o "${CHIR_BUILD_DIR}" "${CHIR_SCHEMA_SRC}"
    RESULT_VARIABLE _flatc_result)
if(NOT _flatc_result EQUAL 0)
    message(FATAL_ERROR "flatc failed with code ${_flatc_result}")
endif()

function(_chir_sed_replace in_file out_file)
    execute_process(
        COMMAND sed "s/std.ast/stdx.chir/g" "${in_file}"
        OUTPUT_FILE "${out_file}"
        RESULT_VARIABLE _sed_result)
    if(NOT _sed_result EQUAL 0)
        message(FATAL_ERROR "sed failed for ${in_file}")
    endif()
endfunction()

# sed outputs go directly into the chir package directory (distinct from syntax under src/stdx/syntax).
_chir_sed_replace("${_fb_cj}/flatbuffer_object.cj" "${CHIR_SOURCE_DIR}/flatbuffer_object.cj")
_chir_sed_replace("${_fb_cj}/decode.cj" "${CHIR_SOURCE_DIR}/decode.cj")
_chir_sed_replace("${_fb_cj}/table.cj" "${CHIR_SOURCE_DIR}/table.cj")
_chir_sed_replace("${_fb_cj}/builder.cj" "${CHIR_SOURCE_DIR}/builder.cj")
_chir_sed_replace("${_fb_cj}/constants.cj" "${CHIR_SOURCE_DIR}/constants.cj")
_chir_sed_replace("${_fb_cj}/exception.cj" "${CHIR_SOURCE_DIR}/exception.cj")
_chir_sed_replace("${_flatc_out}" "${CHIR_SOURCE_DIR}/${_filename}_generated.cj")
