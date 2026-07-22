# Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
#
# This source file is part of the Cangjie project, licensed under Apache-2.0
# with Runtime Library Exception.
#
# See https://cangjie-lang.cn/pages/LICENSE for license information.

# Host-arch shared libraries for macros loaded by host cjc while producing target packages.
# Needed whenever CMAKE_CROSSCOMPILING (cross-OS or same-OS different arch): host cjc cannot
# dlopen target-arch shared libraries.

set(STDX_HOST_STDX_LIB_DIR "")
set(STDX_HOST_RUNTIME_LIB_DIR "")
# STDX_HOST_SHLIB_SUFFIX / STDX_HOST_LIB_PATH_ENV / STDX_HOST_PATH_SEP are set in
# AddCangjieSource.cmake (always host platform).

if(CMAKE_CROSSCOMPILING)
    set(_stdx_host_proc "${CMAKE_HOST_SYSTEM_PROCESSOR}")
    if(_stdx_host_proc STREQUAL "AMD64")
        set(_stdx_host_proc "x86_64")
    elseif(_stdx_host_proc STREQUAL "arm64")
        set(_stdx_host_proc "aarch64")
    endif()
    string(TOLOWER "${CMAKE_HOST_SYSTEM_NAME}_${_stdx_host_proc}" _stdx_host_triple_dir)
    set(STDX_HOST_CJ_LIB_DIR "${_stdx_host_triple_dir}_cjnative")
    set(STDX_HOST_STDX_LIB_DIR "${CMAKE_BINARY_DIR}/lib/${STDX_HOST_CJ_LIB_DIR}")
    set(STDX_HOST_STDX_MOD_DIR "${CMAKE_BINARY_DIR}/modules/${STDX_HOST_CJ_LIB_DIR}/stdx")
    # Host macros dlopen host libcangjie-*.so; always point at host runtime, not target.
    set(STDX_HOST_RUNTIME_LIB_DIR "$ENV{CANGJIE_HOME}/runtime/lib/${STDX_HOST_CJ_LIB_DIR}")

    if(NOT DEFINED ENV{CANGJIE_HOME} OR "$ENV{CANGJIE_HOME}" STREQUAL "")
        message(FATAL_ERROR "CANGJIE_HOME must be set when CMAKE_CROSSCOMPILING (host shared libs)")
    endif()
    set(STDX_HOST_CANGJIE_HOME "$ENV{CANGJIE_HOME}")
    set(STDX_HOST_CJ_LIB_PATH "${STDX_HOST_CANGJIE_HOME}/lib/${STDX_HOST_CJ_LIB_DIR}")
    set(STDX_HOST_RUNTIME_LIB_PATH "${STDX_HOST_CANGJIE_HOME}/runtime/lib/${STDX_HOST_CJ_LIB_DIR}")

    find_program(STDX_HOST_C_COMPILER NAMES clang gcc cc REQUIRED)
    find_program(STDX_HOST_CJC NAMES cjc REQUIRED)
    # Host archive tool (must match the host that produces .a via host cjc), not CMAKE_AR
    # which may point at the cross-target llvm-ar.
    find_program(STDX_HOST_AR NAMES ar llvm-ar REQUIRED)

    set(STDX_HOST_EXTRACT_OBJECT_SCRIPT "${CMAKE_CURRENT_LIST_DIR}/HostExtractObject.cmake")

    # Host link recipe mirrors MakeCJNATIVEStdSharedLib.cmake, but keyed off CMAKE_HOST_*
    # (not DARWIN/MINGW target flags).
    set(STDX_HOST_BASE_LINK_FLAGS)
    set(STDX_HOST_BASE_LINK_LIBS -lcangjie-runtime -lboundscheck)
    if(CMAKE_HOST_WIN32)
        list(APPEND STDX_HOST_BASE_LINK_FLAGS
            -shared
            -static
            -fstack-protector-all
            -Wl,--no-insert-timestamp
            -Wl,--export-all-symbols
            "${STDX_HOST_CJ_LIB_PATH}/section.o"
            "${STDX_HOST_CJ_LIB_PATH}/cjstart.o")
        list(APPEND STDX_HOST_BASE_LINK_LIBS -lm -lclang_rt-builtins)
    elseif(CMAKE_HOST_APPLE)
        list(APPEND STDX_HOST_BASE_LINK_FLAGS -dynamiclib -rpath @loader_path)
    else()
        list(APPEND STDX_HOST_BASE_LINK_FLAGS
            -shared
            -Wl,-z,relro,-z,now,-z,noexecstack
            "-Wl,-T,${STDX_HOST_CJ_LIB_PATH}/cjld.shared.lds"
            "${STDX_HOST_CJ_LIB_PATH}/cjstart.o"
            -Wl,--hash-style=both
            -Wl,--no-undefined
            -Wl,--disable-new-dtags
            "-Wl,-rpath=$ORIGIN")
        list(APPEND STDX_HOST_BASE_LINK_LIBS -lm)
    endif()

    # Compile a stdx package for the host (no --target) and link a host shared library.
    # make_host_cangjie_shared_lib(<name> SOURCE_DIR <dir> [STDX_DEP ...] [STD_LINK ...] DEPENDS ...)
    function(make_host_cangjie_shared_lib lib_name)
        set(one_value_args SOURCE_DIR)
        set(multi_value_args DEPENDS STDX_DEP STD_LINK)
        cmake_parse_arguments(HOSTLIB "" "${one_value_args}" "${multi_value_args}" ${ARGN})

        set(_host_a "${STDX_HOST_STDX_MOD_DIR}/stdx.${lib_name}.a")
        set(_host_o "${STDX_HOST_STDX_MOD_DIR}/${lib_name}.o")
        set(_host_so "${STDX_HOST_STDX_LIB_DIR}/libstdx.${lib_name}${STDX_HOST_SHLIB_SUFFIX}")
        set(_host_target "host_stdx_${lib_name}")
        string(REPLACE "." "_" _host_target "${_host_target}")
        set(_host_extract_dir "${STDX_HOST_STDX_MOD_DIR}/.extract_${_host_target}")

        if(CMAKE_BUILD_TYPE MATCHES "^(Debug|RelWithDebInfo)$")
            set(_host_cjc_opt_flags -g)
            set(_host_debug_or_strip_flags)
            if(NOT CMAKE_HOST_APPLE)
                set(_host_debug_or_strip_flags -g)
            endif()
        else()
            set(_host_cjc_opt_flags -O2)
            set(_host_debug_or_strip_flags)
            if(NOT CMAKE_HOST_APPLE)
                set(_host_debug_or_strip_flags -s)
            endif()
        endif()

        set(_host_link_flags ${STDX_HOST_BASE_LINK_FLAGS})
        if(CMAKE_HOST_APPLE)
            list(APPEND _host_link_flags
                -install_name "@rpath/libstdx.${lib_name}${STDX_HOST_SHLIB_SUFFIX}")
        endif()
        list(APPEND _host_link_flags ${_host_debug_or_strip_flags})

        set(_host_link_libs)
        foreach(_dep IN LISTS HOSTLIB_STDX_DEP)
            list(APPEND _host_link_libs "-lstdx.${_dep}")
        endforeach()
        foreach(_std IN LISTS HOSTLIB_STD_LINK)
            list(APPEND _host_link_libs "-lcangjie-${_std}")
        endforeach()
        list(APPEND _host_link_libs ${STDX_HOST_BASE_LINK_LIBS})

        string(TOLOWER "${TARGET_TRIPLE_DIRECTORY_PREFIX}_cjnative" _target_cj_lib_dir)
        set(_target_cangjie_path "${CMAKE_BINARY_DIR}/modules/${_target_cj_lib_dir}")
        set(_host_library_path
            "${CMAKE_BINARY_DIR}/lib${STDX_HOST_PATH_SEP}$ENV{LIBRARY_PATH}")

        # With VERBATIM, write "-L${path}" (quotes are CMake delimiters). Do not use
        # -L"${path}" — that embeds literal quotes into the linker argument.
        add_custom_command(
            OUTPUT ${_host_so}
            COMMAND ${CMAKE_COMMAND} -E make_directory ${STDX_HOST_STDX_MOD_DIR}
            COMMAND ${CMAKE_COMMAND} -E make_directory ${STDX_HOST_STDX_LIB_DIR}
            # 1) host cjc -> static archive (.a)
            COMMAND ${CMAKE_COMMAND} -E env
                "CANGJIE_PATH=${_target_cangjie_path}"
                "LIBRARY_PATH=${_host_library_path}"
                ${STDX_HOST_CJC}
                --no-sub-pkg
                --trimpath ${CMAKE_SOURCE_DIR}/src/
                --output-type=staticlib
                -Woff=all
                ${_host_cjc_opt_flags}
                -p ${HOSTLIB_SOURCE_DIR}
                --output ${_host_a}
            # 2) host ar -> object (.o)
            COMMAND ${CMAKE_COMMAND}
                -DHOST_AR=${STDX_HOST_AR}
                -DARCHIVE=${_host_a}
                -DOUTPUT_O=${_host_o}
                -DEXTRACT_DIR=${_host_extract_dir}
                -P ${STDX_HOST_EXTRACT_OBJECT_SCRIPT}
            # 3) host C compiler -> shared library (.so / .dylib / .dll)
            COMMAND ${STDX_HOST_C_COMPILER}
                ${_host_link_flags}
                -o ${_host_so}
                ${_host_o}
                -L${STDX_HOST_STDX_LIB_DIR}
                -L${STDX_HOST_RUNTIME_LIB_PATH}
                -L${STDX_HOST_CJ_LIB_PATH}
                ${_host_link_libs}
            DEPENDS ${HOSTLIB_DEPENDS}
            COMMENT "Generating host libstdx.${lib_name}${STDX_HOST_SHLIB_SUFFIX}"
            VERBATIM)

        add_custom_target(${_host_target} ALL DEPENDS ${_host_so})
        set_target_properties(${_host_target} PROPERTIES CJ_LIB_OUTPUT_FILE ${_host_so})
    endfunction()
endif()
