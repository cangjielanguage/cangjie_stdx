# Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
#
# This source file is part of the Cangjie project, licensed under Apache-2.0
# with Runtime Library Exception.
#
# See https://cangjie-lang.cn/pages/LICENSE for license information.

set(CANGJIE_LIB_DIR "modules")
string(TOLOWER "${CMAKE_BUILD_TYPE}" lowercase_build_type)

# Host shared-library naming / search path (cjc and linkers run on the build machine).
if(CMAKE_HOST_WIN32)
    set(STDX_HOST_SHLIB_SUFFIX ".dll")
    set(STDX_HOST_LIB_PATH_ENV "PATH")
    set(STDX_HOST_PATH_SEP ";")
elseif(CMAKE_HOST_APPLE)
    set(STDX_HOST_SHLIB_SUFFIX ".dylib")
    set(STDX_HOST_LIB_PATH_ENV "DYLD_LIBRARY_PATH")
    set(STDX_HOST_PATH_SEP ":")
else()
    set(STDX_HOST_SHLIB_SUFFIX ".so")
    set(STDX_HOST_LIB_PATH_ENV "LD_LIBRARY_PATH")
    set(STDX_HOST_PATH_SEP ":")
endif()

# Resolve a list of CMake target names / plain file paths to the actual output
# files those targets produce, so that add_custom_command(OUTPUT) DEPENDS can
# track them via file timestamps.
#
# Targets created by add_cangjie_library store their primary output path in the
# CJ_OUTPUT_FILE property.  Targets created by make_cangjie_lib store theirs in
# CJ_LIB_OUTPUT_FILE.  For any other CMake target the property is absent and we
# fall back to the raw name (which covers plain-file dependencies and native
# add_library / add_executable targets whose output CMake tracks automatically).
#
# Usage:
#   cj_resolve_depends(out_var dep1 dep2 ...)
function(cj_resolve_depends out_var)
    set(resolved)
    foreach(dep ${ARGN})
        if(TARGET ${dep})
            get_target_property(dep_file ${dep} CJ_OUTPUT_FILE)
            if(NOT dep_file)
                get_target_property(dep_file ${dep} CJ_LIB_OUTPUT_FILE)
            endif()
            if(dep_file)
                list(APPEND resolved ${dep_file})
            else()
                # Native target (add_library/add_executable) or custom target
                # without a tracked output – keep the name so CMake can at
                # least enforce ordering.
                list(APPEND resolved ${dep})
            endif()
        else()
            # Plain file path.
            list(APPEND resolved ${dep})
        endif()
    endforeach()
    set(${out_var} ${resolved} PARENT_SCOPE)
endfunction()

function(add_cangjie_macro_library_in_local target_name)
    set(options
        NO_SUB_PKG
        INSTALL)
    set(one_value_args
        OUTPUT_NAME
        OUTPUT_DIR
        PACKAGE_NAME
        MODULE_NAME
        SOURCE_DIR)
    set(multi_value_args SOURCES DEPENDS FFI LINK_LIBS)
    cmake_parse_arguments(
        CANGJIELIB
        "${options}"
        "${one_value_args}"
        "${multi_value_args}"
        ${ARGN})

    # Do not use ${CMAKE_EXECUTABLE_SUFFIX} here, because its value is determined by the target platform, not the host.
    # Determine the suffix according to the host instead.
    set(cangjie_compiler_tool "cjc$<$<BOOL:${CMAKE_HOST_WIN32}>:.exe>")

    # Set no-sub-pkg
    if(CANGJIELIB_NO_SUB_PKG)
        set(no_sub_pkg "--no-sub-pkg")
    endif()

    list(APPEND cangjie_compile_flags "--compile-macro")

    set(BACKEND "cjnative")
    string(TOLOWER "${TARGET_TRIPLE_DIRECTORY_PREFIX}_${BACKEND}" output_cj_lib_dir)
    set(_stdx_dylib_dir "${CMAKE_BINARY_DIR}/lib/${output_cj_lib_dir}${SANITIZER_SUBPATH}")
    set(output_dir "${CMAKE_BINARY_DIR}/${CANGJIE_LIB_DIR}/${TARGET_TRIPLE_DIRECTORY_PREFIX}_${BACKEND}/${CANGJIELIB_MODULE_NAME}/${CANGJIELIB_OUTPUT_DIR}")

    set(full_package_name "${CANGJIELIB_PACKAGE_NAME}")
    if(NOT ("${CANGJIELIB_MODULE_NAME}" STREQUAL ""))
        set(full_package_name "${CANGJIELIB_MODULE_NAME}.${CANGJIELIB_PACKAGE_NAME}")
    endif()
    # --compile-macro conflicts with --output; use --output-dir. Product is always host-arch.
    set(output_full_name "${output_dir}/lib-macro_${full_package_name}${STDX_HOST_SHLIB_SUFFIX}")
    set(output_cjo_full_name "${output_dir}/${full_package_name}.cjo")

    set(COMPILE_CMD
        ${cangjie_compiler_tool}
        ${no_sub_pkg}
        ${cangjie_compile_flags}
        --output-dir ${output_dir}
        -p ${CANGJIELIB_SOURCE_DIR})
    # Macro libraries are loaded by host cjc at compile time; never cross-compile them.
    # When cross-compiling, STDX_HOST_* is set (see MakeHostCJNATIVESharedLib.cmake).
    if(CANGJIELIB_LINK_LIBS)
        if(CMAKE_CROSSCOMPILING)
            list(APPEND COMPILE_CMD -L "${STDX_HOST_STDX_LIB_DIR}" ${CANGJIELIB_LINK_LIBS})
        else()
            list(APPEND COMPILE_CMD -L "${_stdx_dylib_dir}" ${CANGJIELIB_LINK_LIBS})
        endif()
    endif()

    cj_resolve_depends(resolved_depends ${CANGJIELIB_DEPENDS})

    # pre-process source files: optional explicit SOURCES (globs or paths relative to
    # SOURCE_DIR); otherwise only top-level *.cj (subdirectories are not included).
    if(CANGJIELIB_SOURCES)
        set(source_files)
        foreach(pattern IN LISTS CANGJIELIB_SOURCES)
            if(pattern MATCHES "[*?]")
                file(GLOB _cj CONFIGURE_DEPENDS ${CANGJIELIB_SOURCE_DIR}/${pattern})
                list(APPEND source_files ${_cj})
            else()
                list(APPEND source_files ${CANGJIELIB_SOURCE_DIR}/${pattern})
            endif()
        endforeach()
    else()
        file(GLOB source_files CONFIGURE_DEPENDS ${CANGJIELIB_SOURCE_DIR}/*.cj)
    endif()

    set(_macro_library_path "${CMAKE_BINARY_DIR}/lib")
    set(_macro_compile_env
        "CANGJIE_PATH=${CMAKE_BINARY_DIR}/modules/${output_cj_lib_dir}")
    if(CMAKE_CROSSCOMPILING AND CANGJIELIB_LINK_LIBS)
        # Prefer host stdx + host runtime so dlopen(lib-macro_*.so) can resolve libcangjie-*.so.
        set(_macro_library_path "${STDX_HOST_STDX_LIB_DIR}${STDX_HOST_PATH_SEP}${_macro_library_path}")
        set(_macro_host_ld_path
            "${STDX_HOST_STDX_LIB_DIR}${STDX_HOST_PATH_SEP}${STDX_HOST_RUNTIME_LIB_DIR}")
        list(APPEND _macro_compile_env
            "${STDX_HOST_LIB_PATH_ENV}=${_macro_host_ld_path}${STDX_HOST_PATH_SEP}$ENV{${STDX_HOST_LIB_PATH_ENV}}")
    endif()
    list(APPEND _macro_compile_env "LIBRARY_PATH=${_macro_library_path}")

    # cjc --compile-macro links against stdx dylibs with @rpath install names but does not
    # set LC_RPATH. On macOS, stage plugin.manager next to the macro and add @loader_path.
    if(DARWIN AND CANGJIELIB_LINK_LIBS)
        if(CMAKE_CROSSCOMPILING)
            set(_plugin_manager_dylib "${STDX_HOST_STDX_LIB_DIR}/libstdx.plugin.manager${STDX_HOST_SHLIB_SUFFIX}")
        else()
            set(_plugin_manager_dylib "${_stdx_dylib_dir}/libstdx.plugin.manager${CMAKE_SHARED_LIBRARY_SUFFIX}")
        endif()
        set(_macro_rpath_runner "${CMAKE_CURRENT_BINARY_DIR}/macro_rpath_${target_name}.cmake")
        file(WRITE "${_macro_rpath_runner}" "
cmake_minimum_required(VERSION 3.16.5)
execute_process(
    COMMAND install_name_tool -add_rpath @loader_path \"${output_full_name}\"
    ERROR_QUIET)
")
        add_custom_command(
            OUTPUT ${output_full_name} ${output_cjo_full_name}
            COMMAND ${CMAKE_COMMAND} -E make_directory ${output_dir}
            COMMAND ${CMAKE_COMMAND} -E env ${_macro_compile_env}
                    ${COMPILE_CMD}
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${_plugin_manager_dylib}" "${output_dir}/"
            COMMAND ${CMAKE_COMMAND} -P ${_macro_rpath_runner}
            DEPENDS ${resolved_depends} ${source_files} ${CANGJIELIB_SOURCE_DIR}
                ${_macro_rpath_runner}
            COMMENT "Generating ${target_name}")
    else()
        add_custom_command(
            OUTPUT ${output_full_name} ${output_cjo_full_name}
            COMMAND ${CMAKE_COMMAND} -E make_directory ${output_dir}
            COMMAND ${CMAKE_COMMAND} -E env ${_macro_compile_env}
                    ${COMPILE_CMD}
            DEPENDS ${resolved_depends} ${source_files} ${CANGJIELIB_SOURCE_DIR}
            COMMENT "Generating ${target_name}")
    endif()

    add_custom_target(
        ${target_name} ALL
        DEPENDS ${output_full_name} ${CANGJIELIB_DEPENDS})
    set_target_properties(${target_name} PROPERTIES CJ_OUTPUT_FILE ${output_full_name})
endfunction()

function(add_cangjie_library target_name
)
    set(options
        IS_PACKAGE
        IS_CJNATIVE_BACKEND
        NO_SUB_PKG)
    set(one_value_args
        OUTPUT_NAME
        OUTPUT_DIR
        PACKAGE_NAME
        MODULE_NAME
        SOURCE_DIR)
    set(multi_value_args SOURCES DEPENDS FFI LINK_MACRO_LIBS)
    cmake_parse_arguments(
        CANGJIELIB
        "${options}"
        "${one_value_args}"
        "${multi_value_args}"
        ${ARGN})

    # pre-process source files: optional explicit SOURCES (globs or paths relative to
    # SOURCE_DIR); otherwise only top-level *.cj (subdirectories are not included).
    if(CANGJIELIB_SOURCES)
        set(source_files)
        foreach(pattern IN LISTS CANGJIELIB_SOURCES)
            if(pattern MATCHES "[*?]")
                file(GLOB _cj CONFIGURE_DEPENDS ${CANGJIELIB_SOURCE_DIR}/${pattern})
                list(APPEND source_files ${_cj})
            else()
                list(APPEND source_files ${CANGJIELIB_SOURCE_DIR}/${pattern})
            endif()
        endforeach()
    else()
        file(GLOB source_files CONFIGURE_DEPENDS ${CANGJIELIB_SOURCE_DIR}/*.cj)
    endif()

    set(BACKEND)
    if(CANGJIELIB_IS_CJNATIVE_BACKEND)
        set(BACKEND "cjnative")
    endif()
    # Set output directory (absolute under the build tree).
    set(output_dir "${CMAKE_BINARY_DIR}/${CANGJIE_LIB_DIR}/${TARGET_TRIPLE_DIRECTORY_PREFIX}_${BACKEND}/${CANGJIELIB_MODULE_NAME}/${CANGJIELIB_OUTPUT_DIR}")
    set(output_bc_dir "${CMAKE_BINARY_DIR}/${CANGJIE_LIB_DIR}/${TARGET_TRIPLE_DIRECTORY_PREFIX}_${BACKEND}_bc/${CANGJIELIB_MODULE_NAME}/${CANGJIELIB_OUTPUT_DIR}")

    set(cangjie_compile_flags)
    if(CMAKE_BUILD_TYPE MATCHES Debug)
        list(APPEND cangjie_compile_flags "-g")
    elseif(CMAKE_BUILD_TYPE MATCHES RelWithDebInfo)
        list(APPEND cangjie_compile_flags "-g")
        if(CANGJIE_CODEGEN_CJNATIVE_BACKEND)
            # The -g will enable aggressive-parallel-compile, so we need limit --apc to 1 to disable it forcibly.
            list(APPEND cangjie_compile_flags "--apc=1")
        endif()
    else()
       if(NOT CANGJIE_BUILD_STDLIB_WITH_COVERAGE)
            list(APPEND cangjie_compile_flags "--trimpath")
            list(APPEND cangjie_compile_flags "${CMAKE_SOURCE_DIR}/src/")
        endif()
    endif()

    if(NOT ("${CANGJIELIB_MODULE_NAME}" STREQUAL ""))
        set(output_full_name "${output_dir}/${CANGJIELIB_MODULE_NAME}.${CANGJIELIB_PACKAGE_NAME}")
    else()
        set(output_full_name "${output_dir}/${CANGJIELIB_PACKAGE_NAME}")
    endif()

    set(output_full_name_prefix "${output_dir}/${CANGJIELIB_PACKAGE_NAME}")
    if(CANGJIE_CODEGEN_CJNATIVE_BACKEND)
        set(output_full_name "${output_full_name}.a") # Set output path and output name
        if(NOT ("${CANGJIELIB_MODULE_NAME}" STREQUAL ""))
            set(output_lto_bc_full_name "${output_bc_dir}/lib${CANGJIELIB_MODULE_NAME}.${CANGJIELIB_PACKAGE_NAME}")
        else()
            set(output_lto_bc_full_name "${output_bc_dir}/lib${CANGJIELIB_PACKAGE_NAME}")
        endif()
        set(output_lto_bc_full_name "${output_lto_bc_full_name}.bc") # Set output path and output name
    endif()

    if(CANGJIE_CODEGEN_CJNATIVE_BACKEND)
        list(APPEND cangjie_compile_flags "--output-type=staticlib")
    endif()

    if(TRIPLE STREQUAL "arm-linux-ohos")
        list(APPEND cangjie_compile_flags "--disable-reflection")
    endif()

    # Set compiler path
    if(CMAKE_CROSSCOMPILING)
        set(CANGJIE_NATIVE_CANGJIE_TOOLS_PATH ${CMAKE_BINARY_DIR}/../build/bin)
    endif()
    # Do not use ${CMAKE_EXECUTABLE_SUFFIX} here, because its value is determined by the target platform, not the host.
    # Determine the suffix according to the host instead.
    set(cangjie_compiler_tool "cjc$<$<BOOL:${CMAKE_HOST_WIN32}>:.exe>")

    # Set no-sub-pkg
    if(CANGJIELIB_NO_SUB_PKG)
        set(no_sub_pkg "--no-sub-pkg")
    endif()

    set(output_argument "--output") # Output argument to specify the output file dir and name
    set(module_name_argument) # Module name argument to specify which module the project belongs to
    set(CJNATIVE_PATH)
    # Use the installed llvm tools,
    # in case the backend is compiled from source in previous native-building step
    set(CJNATIVE_PATH $ENV{CANGJIE_HOME}/third_party/llvm/bin)
    set(COMPILE_CMD)
    if(CANGJIELIB_IS_PACKAGE)
        set(COMPILE_CMD
            ${cangjie_compiler_tool}
            ${no_prelude}
            ${no_sub_pkg}
            ${cangjie_compile_flags}
            -p
            ${CANGJIELIB_SOURCE_DIR}
            ${module_name_argument})
    else()
        set(COMPILE_CMD
            ${cangjie_compiler_tool}
            ${no_prelude}
            ${cangjie_compile_flags}
            ${source_files}
            ${module_name_argument})
    endif()
    if(CMAKE_CROSSCOMPILING)
        set(COMPILE_CMD ${COMPILE_CMD} "--target=${TRIPLE}")
        if(NOT ("${CANGJIE_TARGET_TOOLCHAIN}" STREQUAL ""))
            set(COMPILE_CMD ${COMPILE_CMD} "-B${CANGJIE_TARGET_TOOLCHAIN}")
        endif()
    endif()

    list(APPEND COMPILE_CMD "-Woff=all")

    foreach(build_args ${CANGJIE_BUILD_ARGS})
        list(APPEND COMPILE_CMD "${build_args}")
    endforeach()

    string(TOLOWER ${TARGET_TRIPLE_DIRECTORY_PREFIX}_${BACKEND} output_cj_lib_dir)
    if(CANGJIELIB_LINK_MACRO_LIBS)
        set(_compile_stdx_dylib_dir "${CMAKE_BINARY_DIR}/lib/${output_cj_lib_dir}${SANITIZER_SUBPATH}")
        # Host macros live next to the compile cwd / modules; also search host lib dir when cross-compiling.
        if(CMAKE_CROSSCOMPILING)
            list(APPEND COMPILE_CMD -L "${STDX_HOST_STDX_LIB_DIR}")
        endif()
        list(APPEND COMPILE_CMD
            -L "${_compile_stdx_dylib_dir}"
            -L "${CMAKE_BINARY_DIR}/modules/${output_cj_lib_dir}/stdx"
            ${CANGJIELIB_LINK_MACRO_LIBS})
    endif()

    set(COMPILE_BC_CMD
        ${COMPILE_CMD}
        --lto=full
        $<$<BOOL:${IOS}>:--experimental>
        ${output_argument}
        ${output_lto_bc_full_name})
    set(COMPILE_CMD ${COMPILE_CMD} ${output_argument} ${output_full_name})
    
    if(CANGJIE_CODEGEN_CJNATIVE_BACKEND)
        if(TRIPLE STREQUAL "arm-linux-ohos")
            list(APPEND COMPILE_CMD "$<IF:$<CONFIG:MinSizeRel>,-Os,-O0>")
            # .bc files is for LTO mode and LTO mode does not support -Os and -Oz.
            list(APPEND COMPILE_BC_CMD "-O0")
        else()
            list(APPEND COMPILE_CMD "$<IF:$<CONFIG:MinSizeRel>,-Os,-O2>")
            # The .bc files is for LTO mode and LTO mode does not support -Os and -Oz.
            list(APPEND COMPILE_BC_CMD "-O2")
        endif()
    endif()
    
    if(CANGJIE_BUILD_STDLIB_WITH_COVERAGE)
        list(APPEND COMPILE_CMD "--coverage")
    endif()

    set(ENV{${STDX_HOST_LIB_PATH_ENV}} "$ENV{${STDX_HOST_LIB_PATH_ENV}}${STDX_HOST_PATH_SEP}${CMAKE_BINARY_DIR}/lib")

    cj_resolve_depends(resolved_depends ${CANGJIELIB_DEPENDS})

    set(_cj_lib_compile_env
        "CANGJIE_PATH=${CMAKE_BINARY_DIR}/modules/${output_cj_lib_dir}"
        "LIBRARY_PATH=${CMAKE_BINARY_DIR}/lib")
    if(CANGJIELIB_LINK_MACRO_LIBS)
        set(_cj_stdx_dylib_dir "${CMAKE_BINARY_DIR}/lib/${output_cj_lib_dir}${SANITIZER_SUBPATH}")
        set(_cj_runtime_lib_dir "$ENV{CANGJIE_HOME}/runtime/lib/${output_cj_lib_dir}${SANITIZER_SUBPATH}")
        # Host cjc loads host macros; put host stdx/runtime before target paths.
        set(_cj_host_lib_prefix "")
        if(CMAKE_CROSSCOMPILING)
            set(_cj_host_lib_prefix
                "${STDX_HOST_STDX_LIB_DIR}${STDX_HOST_PATH_SEP}${STDX_HOST_RUNTIME_LIB_DIR}${STDX_HOST_PATH_SEP}")
        endif()
        list(APPEND _cj_lib_compile_env
            "${STDX_HOST_LIB_PATH_ENV}=${_cj_host_lib_prefix}${_cj_stdx_dylib_dir}${STDX_HOST_PATH_SEP}${_cj_runtime_lib_dir}${STDX_HOST_PATH_SEP}$ENV{${STDX_HOST_LIB_PATH_ENV}}")
    endif()

    if(NOT CMAKE_BUILD_STAGE STREQUAL "postBuild")
        if(CANGJIELIB_LINK_MACRO_LIBS AND APPLE)
            set(_cj_plugin_manager_dylib
                "${CMAKE_BINARY_DIR}/lib/${output_cj_lib_dir}${SANITIZER_SUBPATH}/libstdx.plugin.manager${CMAKE_SHARED_LIBRARY_SUFFIX}")
            add_custom_command(
                OUTPUT ${output_full_name}
                COMMAND ${CMAKE_COMMAND} -E make_directory ${output_dir}
                COMMAND ${CMAKE_COMMAND} -E copy_if_different
                    "${_cj_plugin_manager_dylib}" "${CMAKE_CURRENT_BINARY_DIR}/"
                COMMAND ${CMAKE_COMMAND} -E env ${_cj_lib_compile_env}
                        ${COMPILE_CMD}
                DEPENDS ${resolved_depends} ${source_files} ${CANGJIELIB_SOURCE_DIR}
                COMMENT "Generating ${target_name}")
        else()
            add_custom_command(
                OUTPUT ${output_full_name}
                COMMAND ${CMAKE_COMMAND} -E make_directory ${output_dir}
                COMMAND ${CMAKE_COMMAND} -E env ${_cj_lib_compile_env}
                        ${COMPILE_CMD}
                DEPENDS ${resolved_depends} ${source_files} ${CANGJIELIB_SOURCE_DIR}
                COMMENT "Generating ${target_name}")
        endif()

        add_custom_target(
            ${target_name} ALL
            DEPENDS ${output_full_name} ${CANGJIELIB_DEPENDS})
        
        set_target_properties(${target_name} PROPERTIES CJ_OUTPUT_FILE ${output_full_name})
    endif()
    if(CMAKE_BUILD_STAGE STREQUAL "postBuild")
        set(bc_depends ${CANGJIELIB_DEPENDS} ${CANGJIELIB_SOURCE_DIR})
        if(CMAKE_CROSSCOMPILING)
            set(bc_cangjie_path ${CMAKE_SOURCE_DIR}/${target_dir}/${TRIPLE}/${lowercase_build_type}/stdx)
        else()
            set(bc_cangjie_path ${CMAKE_SOURCE_DIR}/${target_dir}/${lowercase_build_type}/stdx)
        endif()
    else()
        set(bc_depends ${CANGJIELIB_DEPENDS} ${CANGJIELIB_SOURCE_DIR} ${target_name})
        set(bc_cangjie_path ${CMAKE_BINARY_DIR}/modules/${output_cj_lib_dir})
    endif()
    if(CANGJIE_CODEGEN_CJNATIVE_BACKEND
       AND NOT WIN32
       AND (NOT DARWIN OR IOS))
        if(CMAKE_BUILD_STAGE STREQUAL "postBuild")
            add_custom_target(
                ${target_name}_bc ALL
                COMMAND ${CMAKE_COMMAND} -E make_directory ${output_bc_dir}
                COMMAND ${CMAKE_COMMAND} -E env "CANGJIE_PATH=${bc_cangjie_path}" "LIBRARY_PATH=${CMAKE_BINARY_DIR}/lib"
                        ${COMPILE_BC_CMD}
                BYPRODUCTS ${output_lto_bc_full_name}
                # The ${target_name}_bc depends on ${target_name} so they will not run simultaneously. <target> and <target>_bc
                # compile the same package, which means they may write the same bc cache file. Running simultaneously
                # may cause IO error on windows in some cases.
                DEPENDS ${bc_depends}
                COMMENT "Generating ${target_name}_bc")
        else()
            add_custom_command(
                OUTPUT ${output_lto_bc_full_name}
                COMMAND ${CMAKE_COMMAND} -E make_directory ${output_bc_dir}
                COMMAND ${CMAKE_COMMAND} -E env ${_cj_lib_compile_env}
                        ${COMPILE_BC_CMD}
                # ${target_name}_bc depends on ${target_name} so they will not run simultaneously. <target> and <target>_bc
                # compile the same package, which means they may write the same bc cache file. Running simultaneously
                # may cause IO error on windows in some cases.
                DEPENDS ${target_name} ${bc_depends}
                COMMENT "Generating ${target_name}_bc")

            add_custom_target(
                ${target_name}_bc ALL
                DEPENDS ${output_lto_bc_full_name})
        endif()
    endif()

    if(NOT CMAKE_BUILD_STAGE STREQUAL "postBuild")
        if(CANGJIE_CODEGEN_CJNATIVE_BACKEND)
            set(TARGET_AR ar)
            if(CMAKE_CROSSCOMPILING)
                if(IOS)
                    set(TARGET_AR ${CANGJIE_TARGET_TOOLCHAIN}/ar)
                elseif(CMAKE_C_COMPILER_ID STREQUAL "Clang")
                    set(TARGET_AR ${CANGJIE_TARGET_TOOLCHAIN}/llvm-ar)
                else()
                    set(TARGET_AR ${CANGJIE_TARGET_TOOLCHAIN}/${TRIPLE}-ar)
                endif()
            endif()
            if(CMAKE_HOST_UNIX)
                set(MOVE_CMD mv)
            elseif(CMAKE_HOST_WIN32)
                set(MOVE_CMD move)
            endif()
            add_custom_command(
                TARGET ${target_name}
                POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E make_directory ${target_name} && cd ${target_name}
                COMMAND ${CMAKE_COMMAND} -E remove_directory tmp
                COMMAND ${CMAKE_COMMAND} -E make_directory tmp && cd tmp
                COMMAND ${TARGET_AR} x ${output_full_name}
                COMMAND ${MOVE_CMD} *.o ${output_full_name_prefix}.o
                COMMAND cd ..
                COMMAND ${CMAKE_COMMAND} -E remove_directory tmp
                BYPRODUCTS ${output_full_name_prefix}.o)
        endif()
    endif()

    # Install
    if(NOT ("${CANGJIELIB_MODULE_NAME}" STREQUAL ""))
        set(file_name "${CANGJIELIB_MODULE_NAME}.${CANGJIELIB_PACKAGE_NAME}")
    else()
        set(file_name "${CANGJIELIB_PACKAGE_NAME}")
    endif()
    if(CMAKE_BUILD_STAGE STREQUAL "postBuild")
        if(CMAKE_CROSSCOMPILING)
            if(${CANGJIELIB_PACKAGE_NAME} STREQUAL "actors.macros")
                set(install_files "${CANGJIE_CJPM_DIR}/${target_dir}/${lowercase_build_type}/stdx/${file_name}.cjo")
            else()
                set(install_files "${CANGJIE_CJPM_DIR}/${target_dir}/${TRIPLE}/${lowercase_build_type}/stdx/${file_name}.cjo")
            endif()
        else()
            set(install_files "${CANGJIE_CJPM_DIR}/${target_dir}/${lowercase_build_type}/stdx/${file_name}.cjo")
        endif()
    else()
        set(install_files "${output_dir}/${file_name}.cjo")
    endif()
    if(CANGJIE_CODEGEN_CJNATIVE_BACKEND)
    else()
        list(APPEND install_files "${output_dir}/${file_name}.bchir")
        list(APPEND install_files "${output_dir}/${file_name}.pdba")
    endif()

    if(CANGJIE_CODEGEN_CJNATIVE_BACKEND
       AND NOT WIN32
       AND (NOT DARWIN OR IOS))
        list(APPEND install_files ${output_lto_bc_full_name})
    endif()
    if(CANGJIE_CODEGEN_CJNATIVE_BACKEND)
        install(FILES ${install_files} DESTINATION "${TARGET_TRIPLE_DIRECTORY_PREFIX}_${BACKEND}/static/stdx")
        install(FILES ${install_files} DESTINATION "${TARGET_TRIPLE_DIRECTORY_PREFIX}_${BACKEND}/dynamic/stdx")
    endif()
endfunction()

set(CJNATIVE_BACKEND "cjnative")
# Install cangjie library FFI
function(install_cangjie_library_ffi lib_name)
    # Set install dir
    string(TOLOWER ${TARGET_TRIPLE_DIRECTORY_PREFIX} output_lib_dir)
    if(CANGJIE_CODEGEN_CJNATIVE_BACKEND)
        if(DEFINED CANGJIE_CJPM_BUILD_SELF)
            if(CANGJIE_CJPM_BUILD_SELF)
                install(TARGETS ${lib_name} DESTINATION ${output_lib_dir}_${CJNATIVE_BACKEND}/static/stdx)
            else()
                install(TARGETS ${lib_name} DESTINATION "stdx")
            endif()
        else()
            install(TARGETS ${lib_name} DESTINATION ${output_lib_dir}_${CJNATIVE_BACKEND}/static/stdx)
        endif()
    endif()
endfunction()

function(install_cangjie_library_ffi_s lib_name)
    # Set install dir
    string(TOLOWER ${TARGET_TRIPLE_DIRECTORY_PREFIX} output_lib_dir)
    if(CANGJIE_CODEGEN_CJNATIVE_BACKEND)
        if(DEFINED CANGJIE_CJPM_BUILD_SELF)
            if(CANGJIE_CJPM_BUILD_SELF)
                install(TARGETS ${lib_name} DESTINATION ${output_lib_dir}_${CJNATIVE_BACKEND}/static/stdx)
            else()
                install(TARGETS ${lib_name} DESTINATION "stdx")
            endif()
        else()
            install(TARGETS ${lib_name} DESTINATION ${output_lib_dir}_${CJNATIVE_BACKEND}/dynamic/stdx)
        endif()
    endif()
endfunction()
