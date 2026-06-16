# Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
#
# This source file is part of the Cangjie project, licensed under Apache-2.0
# with Runtime Library Exception.
#
# See https://cangjie-lang.cn/pages/LICENSE for license information.

set(_chir_flatbuffer_sources)

# Generate cangjie flatbuffers files for chir (schema from cangjie_compiler, not in-tree).
if(NOT CANGJIE_CJPM_BUILD_TYPE)
    if(DEFINED CANGJIE_SCHEMA_DIR)
        set(CHIR_SCHEMA_SRC ${CANGJIE_SCHEMA_DIR}/PackageFormat.fbs)
    else()
        set(CHIR_SCHEMA_SRC ${CMAKE_SOURCE_DIR}/../cangjie_compiler/schema/PackageFormat.fbs)
    endif()
    if(NOT EXISTS ${CHIR_SCHEMA_SRC})
        message(FATAL_ERROR "CHIR PackageFormat.fbs not found: ${CHIR_SCHEMA_SRC}")
    endif()

    get_filename_component(FILENAME ${CHIR_SCHEMA_SRC} NAME_WE)
    set(CHIR_FB_GEN_SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/GenerateFlatbuffers.cmake)
    set(CHIR_FB_GEN_ARGS
        -DCHIR_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
        -DCHIR_BUILD_DIR=${CMAKE_BINARY_DIR}
        -DCHIR_REPO_DIR=${CMAKE_SOURCE_DIR}
        -DCHIR_SCHEMA_SRC=${CHIR_SCHEMA_SRC})

    set(_chir_flatbuffer_sources
        flatbuffer_object.cj
        decode.cj
        table.cj
        builder.cj
        constants.cj
        exception.cj
        ${FILENAME}_generated.cj)

    set(CHIR_FLATC_SOURCE_FILES
        ${CMAKE_CURRENT_SOURCE_DIR}/flatbuffer_object.cj
        ${CMAKE_CURRENT_SOURCE_DIR}/decode.cj
        ${CMAKE_CURRENT_SOURCE_DIR}/table.cj
        ${CMAKE_CURRENT_SOURCE_DIR}/builder.cj
        ${CMAKE_CURRENT_SOURCE_DIR}/constants.cj
        ${CMAKE_CURRENT_SOURCE_DIR}/exception.cj
        ${CMAKE_CURRENT_SOURCE_DIR}/${FILENAME}_generated.cj)

    # Build-time generation (flatc is produced by the flatbuffers ExternalProject).
    add_custom_command(
        OUTPUT ${CHIR_FLATC_SOURCE_FILES}
        COMMAND ${CMAKE_COMMAND} ${CHIR_FB_GEN_ARGS} -P ${CHIR_FB_GEN_SCRIPT}
        DEPENDS flatbuffers ${CHIR_SCHEMA_SRC} ${CHIR_FB_GEN_SCRIPT}
        COMMENT "generate cangjie flatbuffers files for chir"
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

    add_custom_target(CHIR_FLATC_OUTPUTS ALL DEPENDS ${CHIR_FLATC_SOURCE_FILES})

    # Configure-time generation when flatc is already available (e.g. after the first
    # flatbuffers build or on re-configure).
    if(EXISTS "${CMAKE_BINARY_DIR}/bin/flatc")
        execute_process(
            COMMAND ${CMAKE_COMMAND} ${CHIR_FB_GEN_ARGS} -P ${CHIR_FB_GEN_SCRIPT}
            RESULT_VARIABLE _chir_gen_result)
        if(NOT _chir_gen_result EQUAL 0)
            message(FATAL_ERROR "CHIR flatbuffers configure-time generation failed")
        endif()
    endif()

    set(CHIR_FLATC_SOURCE_FILES ${CHIR_FLATC_SOURCE_FILES} PARENT_SCOPE)
endif()

# CHIR_SRCS: FlatBuffers outputs (listed explicitly) + hand-written sources from GLOB.
set(_chir_srcs ${_chir_flatbuffer_sources})
file(GLOB _chir_glob CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/*.cj")
foreach(_chir_file ${_chir_glob})
    get_filename_component(_chir_basename ${_chir_file} NAME)
    if(NOT _chir_basename IN_LIST _chir_flatbuffer_sources)
        list(APPEND _chir_srcs ${_chir_basename})
    endif()
endforeach()
set(CHIR_SRCS ${_chir_srcs} CACHE INTERNAL "")

add_subdirectory(to_string_macro)
