# Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
#
# This source file is part of the Cangjie project, licensed under Apache-2.0
# with Runtime Library Exception.
#
# See https://cangjie-lang.cn/pages/LICENSE for license information.

add_subdirectory(native)

# SYNTAX_SRCS: generated FlatBuffers code (explicit) + hand-written sources from GLOB.
set(_syntax_flatbuffer_sources StdxSyntaxFormat_generated.cj)
set(_syntax_srcs ${_syntax_flatbuffer_sources})
file(GLOB _syntax_glob CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/*.cj")
foreach(_syntax_file ${_syntax_glob})
    get_filename_component(_syntax_basename ${_syntax_file} NAME)
    if(NOT _syntax_basename IN_LIST _syntax_flatbuffer_sources)
        list(APPEND _syntax_srcs ${_syntax_basename})
    endif()
endforeach()
set(SYNTAX_SRCS ${_syntax_srcs} CACHE INTERNAL "")
