# Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
#
# This source file is part of the Cangjie project, licensed under Apache-2.0
# with Runtime Library Exception.
#
# See https://cangjie-lang.cn/pages/LICENSE for license information.

# cmake -P helper: extract the single object file from a static archive.
# Required variables: HOST_AR, ARCHIVE, OUTPUT_O, EXTRACT_DIR

if(NOT HOST_AR OR NOT ARCHIVE OR NOT OUTPUT_O OR NOT EXTRACT_DIR)
    message(FATAL_ERROR "HostExtractObject.cmake requires HOST_AR, ARCHIVE, OUTPUT_O, EXTRACT_DIR")
endif()

file(REMOVE_RECURSE "${EXTRACT_DIR}")
file(MAKE_DIRECTORY "${EXTRACT_DIR}")

execute_process(
    COMMAND "${HOST_AR}" x "${ARCHIVE}"
    WORKING_DIRECTORY "${EXTRACT_DIR}"
    RESULT_VARIABLE _ar_rv
    ERROR_VARIABLE _ar_err)
if(NOT _ar_rv EQUAL 0)
    message(FATAL_ERROR "Failed to extract ${ARCHIVE} with ${HOST_AR}: ${_ar_err}")
endif()

file(GLOB _objs LIST_DIRECTORIES false "${EXTRACT_DIR}/*.o")
list(LENGTH _objs _n_objs)
if(NOT _n_objs EQUAL 1)
    message(FATAL_ERROR "Expected exactly one .o in ${ARCHIVE}, found ${_n_objs}: ${_objs}")
endif()

get_filename_component(_out_dir "${OUTPUT_O}" DIRECTORY)
file(MAKE_DIRECTORY "${_out_dir}")
execute_process(
    COMMAND "${CMAKE_COMMAND}" -E copy "${_objs}" "${OUTPUT_O}"
    RESULT_VARIABLE _cp_rv)
if(NOT _cp_rv EQUAL 0)
    message(FATAL_ERROR "Failed to copy ${_objs} to ${OUTPUT_O}")
endif()
file(REMOVE_RECURSE "${EXTRACT_DIR}")
