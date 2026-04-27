# Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
#
# This source file is part of the Cangjie project, licensed under Apache-2.0
# with Runtime Library Exception.
#
# See https://cangjie-lang.cn/pages/LICENSE for license information.

file(
    GLOB
    x509_ffi_src
    rootca.c
    compat.c
    crypto_errors.c
    der_cert.c
    x509_keys_certs.c
)

set(libname stdx.crypto.x509FFI)
add_library(${libname}-objs OBJECT ${x509_ffi_src})
target_compile_options(${libname}-objs PRIVATE ${CMAKE_C_COVERAGE_FLAGS})
target_include_directories(${libname}-objs PRIVATE ${CMAKE_SOURCE_DIR}/src/stdx/dynamicLoader)
target_include_directories(${libname}-objs PRIVATE ${OPENSSL_INCLUDE_DIR})
if(CANGJIE_CODEGEN_CJNATIVE_BACKEND)
    include(AddAndCombineStaticLib)

    add_and_combine_static_lib(
        TARGET ${libname}
        OUTPUT_NAME lib${libname}.a
        LIBRARIES
            $<TARGET_OBJECTS:${libname}-objs>
            $<TARGET_OBJECTS:${CANGJIE_OPENSSL_FFI_OBJECTS_TARGET}>
        DEPENDS ${libname}-objs ${CANGJIE_OPENSSL_FFI_OBJECTS_TARGET} )
    add_and_combine_static_lib(
        TARGET ${libname}-strong
        OUTPUT_NAME lib${libname}-strong.a
        LIBRARIES
            $<TARGET_OBJECTS:${libname}-objs>
            $<TARGET_OBJECTS:${CANGJIE_OPENSSL_FFI_STRONG_OBJECTS_TARGET}>
        DEPENDS ${libname}-objs ${CANGJIE_OPENSSL_FFI_STRONG_OBJECTS_TARGET} )


    string(TOLOWER ${TARGET_TRIPLE_DIRECTORY_PREFIX} output_lib_dir)
    set(CJNATIVE_BACKEND "cjnative")
    if(DEFINED CANGJIE_CJPM_BUILD_SELF)
        if(CANGJIE_CJPM_BUILD_SELF)
            install(FILES ${CMAKE_BINARY_DIR}/lib/lib${libname}.a DESTINATION ${output_lib_dir}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)
        else()
            install(FILES ${CMAKE_BINARY_DIR}/lib/lib${libname}.a DESTINATION "stdx")
        endif()
    else()
        install(FILES ${CMAKE_BINARY_DIR}/lib/lib${libname}.a DESTINATION ${output_lib_dir}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)
    endif()
    # x509.ffi compile .so
    set(CMAKE_BUILD_WITH_INSTALL_RPATH ON)
    add_library(${libname}-shared SHARED $<TARGET_OBJECTS:${libname}-objs>)
    target_link_libraries(${libname}-shared cangjie-dynamicLoader-opensslFFI-shared)
    target_link_libraries(${libname}-shared boundscheck)
    if(MINGW)
        target_link_libraries(${libname}-shared crypt32)
        target_link_libraries(${libname}-shared ws2_32)
    endif()
    set_target_properties(${libname}-shared PROPERTIES OUTPUT_NAME ${libname})
    install_cangjie_library_ffi_s(${libname}-shared)
endif()
