# Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
#
# This source file is part of the Cangjie project, licensed under Apache-2.0
# with Runtime Library Exception.
#
# See https://cangjie-lang.cn/pages/LICENSE for license information.

set(CANGJIE_LIB_DIR "modules")
string(TOLOWER "${CMAKE_BUILD_TYPE}" lowercase_build_type)

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
        NO_SUB_PKG)
    set(one_value_args
        OUTPUT_NAME
        OUTPUT_DIR
        PACKAGE_NAME
        MODULE_NAME
        SOURCE_DIR)
    set(multi_value_args SOURCES DEPENDS FFI)
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

    if(NOT ("${CANGJIELIB_MODULE_NAME}" STREQUAL ""))
        set(output_dir "${CANGJIE_LIB_DIR}/${TARGET_TRIPLE_DIRECTORY_PREFIX}_${BACKEND}/${CANGJIELIB_MODULE_NAME}")
    else()
        set(output_dir "${CANGJIE_LIB_DIR}/${TARGET_TRIPLE_DIRECTORY_PREFIX}_${BACKEND}")
    endif()
    if(NOT ("${CANGJIELIB_OUTPUT_DIR}" STREQUAL ""))
        set(output_dir "${output_dir}/${CANGJIELIB_OUTPUT_DIR}")
    endif()

    if(NOT ("${CANGJIELIB_MODULE_NAME}" STREQUAL ""))
        set(output_full_name "${CMAKE_BINARY_DIR}/${output_dir}/lib-macro_${CANGJIELIB_MODULE_NAME}.${CANGJIELIB_PACKAGE_NAME}")
    else()
        set(output_full_name "${CMAKE_BINARY_DIR}/${output_dir}/lib-macro_${CANGJIELIB_PACKAGE_NAME}")
    endif()

    set(COMPILE_CMD
        ${cangjie_compiler_tool}
        ${no_sub_pkg}
        ${cangjie_compile_flags}
        -p ${CANGJIELIB_SOURCE_DIR})

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

    add_custom_command(
        OUTPUT ${output_full_name}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/${output_dir}
        COMMAND ${CMAKE_COMMAND} -E env "CANGJIE_PATH=${CMAKE_BINARY_DIR}/modules/${output_cj_lib_dir}"  "LIBRARY_PATH=${CMAKE_BINARY_DIR}/lib"
                ${COMPILE_CMD}
        DEPENDS ${resolved_depends} ${source_files} ${CANGJIELIB_SOURCE_DIR}
        COMMENT "Generating ${target_name}")

    add_custom_target(
        ${target_name} ALL
        DEPENDS ${output_full_name} ${CANGJIELIB_DEPENDS})
endfunction()

function(add_cangjie_library target_name
)
    set(options
        IS_PACKAGE
        IS_STDXLIB
        IS_CJNATIVE_BACKEND
        NO_SUB_PKG)
    set(one_value_args
        OUTPUT_NAME
        OUTPUT_DIR
        PACKAGE_NAME
        MODULE_NAME
        SOURCE_DIR)
    set(multi_value_args SOURCES DEPENDS FFI)
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
    # Set output directory
    set(output_dir)
    set(output_bc_dir)
    if(CANGJIELIB_IS_STDXLIB)
        if(NOT ("${CANGJIELIB_MODULE_NAME}" STREQUAL ""))
            set(output_dir "${CANGJIE_LIB_DIR}/${TARGET_TRIPLE_DIRECTORY_PREFIX}_${BACKEND}/${CANGJIELIB_MODULE_NAME}")
            set(output_bc_dir "${CANGJIE_LIB_DIR}/${TARGET_TRIPLE_DIRECTORY_PREFIX}_${BACKEND}_bc/${CANGJIELIB_MODULE_NAME}")
        else()
            set(output_dir "${CANGJIE_LIB_DIR}/${TARGET_TRIPLE_DIRECTORY_PREFIX}_${BACKEND}")
            set(output_bc_dir "${CANGJIE_LIB_DIR}/${TARGET_TRIPLE_DIRECTORY_PREFIX}_${BACKEND}_bc")
        endif()
        if(NOT ("${CANGJIELIB_OUTPUT_DIR}" STREQUAL ""))
            set(output_dir "${output_dir}/${CANGJIELIB_OUTPUT_DIR}")
            set(output_bc_dir "${output_bc_dir}/${CANGJIELIB_OUTPUT_DIR}")
        endif()
    endif()

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
        set(output_full_name "${CMAKE_BINARY_DIR}/${output_dir}/${CANGJIELIB_MODULE_NAME}.${CANGJIELIB_PACKAGE_NAME}")
    else()
        set(output_full_name "${CMAKE_BINARY_DIR}/${output_dir}/${CANGJIELIB_PACKAGE_NAME}")
    endif()

    set(output_full_name_prefix "${CMAKE_BINARY_DIR}/${output_dir}/${CANGJIELIB_PACKAGE_NAME}")
    if(CANGJIE_CODEGEN_CJNATIVE_BACKEND)
        set(output_full_name "${output_full_name}.a") # Set output path and output name
        if(NOT ("${CANGJIELIB_MODULE_NAME}" STREQUAL ""))
            set(output_lto_bc_full_name "${CMAKE_BINARY_DIR}/${output_bc_dir}/lib${CANGJIELIB_MODULE_NAME}.${CANGJIELIB_PACKAGE_NAME}")
        else()
            set(output_lto_bc_full_name "${CMAKE_BINARY_DIR}/${output_bc_dir}/lib${CANGJIELIB_PACKAGE_NAME}")
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

    set(COMPILE_BC_CMD
        ${COMPILE_CMD}
        --lto=full
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

    set(ENV{LD_LIBRARY_PATH} $ENV{LD_LIBRARY_PATH}:${CMAKE_BINARY_DIR}/lib)
    string(TOLOWER ${TARGET_TRIPLE_DIRECTORY_PREFIX}_${BACKEND} output_cj_lib_dir)
    
    cj_resolve_depends(resolved_depends ${CANGJIELIB_DEPENDS})
    
    if(NOT CMAKE_BUILD_STAGE STREQUAL "postBuild")
        add_custom_command(
            OUTPUT ${output_full_name}
            COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/${output_dir}
            COMMAND ${CMAKE_COMMAND} -E env "CANGJIE_PATH=${CMAKE_BINARY_DIR}/modules/${output_cj_lib_dir}"  "LIBRARY_PATH=${CMAKE_BINARY_DIR}/lib"
                    ${COMPILE_CMD}
            DEPENDS ${resolved_depends} ${source_files} ${CANGJIELIB_SOURCE_DIR}
            COMMENT "Generating ${target_name}")

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
       AND NOT DARWIN)
        if(CMAKE_BUILD_STAGE STREQUAL "postBuild")
            add_custom_target(	 
                ${target_name}_bc ALL	 
                COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/${output_bc_dir}	 
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
                COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/${output_bc_dir}
                COMMAND ${CMAKE_COMMAND} -E env "CANGJIE_PATH=${bc_cangjie_path}" "LIBRARY_PATH=${CMAKE_BINARY_DIR}/lib"
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
        set(install_files "${CMAKE_BINARY_DIR}/${output_dir}/${file_name}.cjo")
    endif()
    if(CANGJIE_CODEGEN_CJNATIVE_BACKEND)
    else()
        list(APPEND install_files "${CMAKE_BINARY_DIR}/${output_dir}/${file_name}.bchir")
        list(APPEND install_files "${CMAKE_BINARY_DIR}/${output_dir}/${file_name}.pdba")
    endif()

    if(CANGJIE_CODEGEN_CJNATIVE_BACKEND
       AND NOT WIN32
       AND NOT DARWIN)
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
