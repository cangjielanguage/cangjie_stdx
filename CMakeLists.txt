# Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
#
# This source file is part of the Cangjie project, licensed under Apache-2.0
# with Runtime Library Exception.
#
# See https://cangjie-lang.cn/pages/LICENSE for license information.

cmake_minimum_required(VERSION 3.16.5)
project(stdx)
# Add path for custom CMake modules and add cmake modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/build/common/modules")
include(AddCangjieSource)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_EXTENSIONS OFF)

if(NOT CMAKE_INCLUDE_SYSTEM_FLAG_CXX)
    set(CXX_SYSTEM_INCLUDE_CONFIGURATION_FLAG /experimental:external /external:W0)
    set(CMAKE_INCLUDE_SYSTEM_FLAG_CXX /external:I)
endif()

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    message(STATUS "No build type selected, default to Debug")
    set(CMAKE_BUILD_TYPE
        "Debug"
        CACHE STRING "Build type (default Debug)" FORCE)
endif()

string(TOUPPER "${CMAKE_BUILD_TYPE}" uppercase_CMAKE_BUILD_TYPE)

if(CMAKE_BUILD_TYPE AND NOT ("${uppercase_CMAKE_BUILD_TYPE}" MATCHES "^(DEBUG|RELEASE|RELWITHDEBINFO)$"))
    message(FATAL_ERROR "Invalid value for CMAKE_BUILD_TYPE: ${CMAKE_BUILD_TYPE}")
endif()


set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_SKIP_INSTALL_ALL_DEPENDENCY TRUE)

option(CANGJIE_CODEGEN_CJNATIVE_BACKEND "Build a version for CJNATIVE backend" ON)
option(CANGJIE_SKIP_FIND_OPENSSL "Do not look for OpenSSL package, OpenSSL library will be searched by linker" OFF)

# Static stdx artifacts keep the legacy auto resolver by default.
set(CANGJIE_OPENSSL_FFI_OBJECTS_TARGET "cangjie-dynamicLoader-opensslFFI-auto-objs")
# Strong resolver objects are built in parallel for the opt-in OpenSSL-strong package variant.
set(CANGJIE_OPENSSL_FFI_STRONG_OBJECTS_TARGET "cangjie-dynamicLoader-opensslFFI-strong-objs")

message(STATUS "Build type for the current project: ${CMAKE_BUILD_TYPE}")


if(CANGJIE_CODEGEN_CJNATIVE_BACKEND)
    add_compile_definitions(CANGJIE_CODEGEN_CJNATIVE_BACKEND)
endif()

if(OHOS)
    # This is a CMake bug until 3.22, where MINGW is wrongly set
    # when targeting other platforms on a Windows machine with a MinGW toolchain.
    # See more at CMake issue tracker #22647.
    set(MINGW 0)
endif()

if(NOT TRIPLE)
    string(TOLOWER "${CMAKE_SYSTEM_PROCESSOR}-${CMAKE_SYSTEM_NAME}-gnu" TRIPLE)
endif()

if(MINGW)
    set(TRIPLE x86_64-w64-mingw32)
endif()

if(NOT TARGET_TRIPLE_DIRECTORY_PREFIX)
    if(IOS AND IOS_PLATFORM MATCHES "SIMULATOR")
        set(EXTRA_OS_SUFFIX _simulator)
    endif()
    string(REPLACE "-" "_" TARGET_TRIPLE_DIRECTORY_PREFIX "${CMAKE_SYSTEM_NAME}${EXTRA_OS_SUFFIX}_${CMAKE_SYSTEM_PROCESSOR}")
    string(TOLOWER "${TARGET_TRIPLE_DIRECTORY_PREFIX}" TARGET_TRIPLE_DIRECTORY_PREFIX)
endif()

if(CMAKE_CROSSCOMPILING)
    message(STATUS "CROSS COMPILING libs from ${CMAKE_HOST_SYSTEM_PROCESSOR}-${CMAKE_HOST_SYSTEM_NAME} to ${TRIPLE}")
endif()

include(SetupAr)

message(STATUS "Building with target=${TRIPLE}")

if(MACOS)
    include(ReadDarwinSDKInfo)
    set(CMAKE_OSX_DEPLOYMENT_TARGET 12.0.0)
endif()

if(CANGJIE_INCLUDE)
    foreach(include_path ${CANGJIE_INCLUDE})
        include_directories(${include_path})
    endforeach()
endif()

if(NOT (CMAKE_BUILD_TYPE MATCHES Debug))
    add_definitions(-DNDEBUG)
endif()

if(CMAKE_BUILD_TYPE MATCHES Release)
    add_definitions(-DRELEASE)
endif()

if(BUILD_GCC_TOOLCHAIN AND (CMAKE_C_COMPILER_ID STREQUAL "Clang" OR (CMAKE_CXX_COMPILER_ID STREQUAL "Clang"))
)# It is clang that takes --gcc-toolchain options.
    message(STATUS "Add compile option for clang, --gcc-toolchain=${BUILD_GCC_TOOLCHAIN}")
    add_compile_options(--gcc-toolchain=${BUILD_GCC_TOOLCHAIN})
    add_link_options(--gcc-toolchain=${BUILD_GCC_TOOLCHAIN})
endif()

foreach(libpath ${CANGJIE_TARGET_LIB})
    add_link_options("-L${libpath}")
endforeach()

add_compile_options(${CXX_SYSTEM_INCLUDE_CONFIGURATION_FLAG})


if(CANGJIE_LINK_JOB_POOL AND CMAKE_GENERATOR MATCHES "Ninja")
    set_property(GLOBAL APPEND PROPERTY JOB_POOLS link_job_pool=${CANGJIE_LINK_JOB_POOL})
    set(CMAKE_JOB_POOL_LINK link_job_pool)
endif()


if(WIN32)
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_DEBUG ${CMAKE_BINARY_DIR}/lib)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG ${CMAKE_BINARY_DIR}/lib)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG ${CMAKE_BINARY_DIR}/bin)
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_RELEASE ${CMAKE_BINARY_DIR}/lib)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE ${CMAKE_BINARY_DIR}/lib)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE ${CMAKE_BINARY_DIR}/bin)
endif()
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

if(NOT CANGJIE_SKIP_FIND_OPENSSL AND NOT ANDROID)
    include(PrepareOpenSSL)
else()
    # OpenSSL library wil be searched by the linker at build time
    set(OPENSSL_CRYPTO_LINK_OPTIONS -lcrypto)
    set(OPENSSL_SSL_LINK_OPTIONS -lssl -lcrypto)
endif()

string(TOLOWER "${CMAKE_SYSTEM_NAME}" TARGET_OS)
add_compile_definitions(__${TARGET_OS}__)


set(CANGJIE_ZLIB_SOURCE_DIR "${CMAKE_SOURCE_DIR}/third_party/zlib")

set(GCC_TOOLCHAIN_FLAG "")
if(MINGW)
    # There will be lots of warnings when compiling backend with MinGW toolchain, temporarily suppress them.
    set(GCC_TOOLCHAIN_FLAG "${GCC_TOOLCHAIN_FLAG} -w")
endif()
if(BUILD_GCC_TOOLCHAIN)
    message(STATUS "Set GCC toolchain: ${BUILD_GCC_TOOLCHAIN}")
    set(GCC_TOOLCHAIN_FLAG "${GCC_TOOLCHAIN_FLAG} --gcc-toolchain=\"${BUILD_GCC_TOOLCHAIN}\"")
endif()

if(NOT EXISTS ${CANGJIE_ZLIB_SOURCE_DIR})
    set(REPOSITORY_PATH https://gitcode.com/openharmony/third_party_zlib.git)
    message(STATUS "Set Zlib REPOSITORY_PATH: ${REPOSITORY_PATH}")
    message(STATUS "CANGJIE_ZLIB_SOURCE_DIR: ${CANGJIE_ZLIB_SOURCE_DIR}")
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -E env
                --unset=GIT_DIR
                --unset=GIT_WORK_TREE
                --unset=GIT_INDEX_FILE
                git clone --branch OpenHarmony-v6.0-Release
                "${REPOSITORY_PATH}" "${CANGJIE_ZLIB_SOURCE_DIR}"
    )
endif()
include(Zlib)

set(BOUNDSCHECK ${CMAKE_SOURCE_DIR}/third_party/boundscheck-v1.1.16)

# Provide secure functions.
if(NOT EXISTS ${BOUNDSCHECK})
    set(REPOSITORY_PATH https://gitcode.com/openharmony/third_party_bounds_checking_function.git)
    message(STATUS "Set boundscheck REPOSITORY_PATH: ${REPOSITORY_PATH}")
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -E env
                --unset=GIT_DIR
                --unset=GIT_WORK_TREE
                --unset=GIT_INDEX_FILE
                git clone --branch OpenHarmony-v6.0-Release ${REPOSITORY_PATH} ${BOUNDSCHECK}
    )
endif()
file(COPY ${CMAKE_MODULE_PATH}/BoundsCheck.cmake DESTINATION ${BOUNDSCHECK}/)
file(RENAME ${BOUNDSCHECK}/BoundsCheck.cmake ${BOUNDSCHECK}/CMakeLists.txt)

if(CANGJIE_CODEGEN_CJNATIVE_BACKEND)
    add_subdirectory(third_party/boundscheck-v1.1.16)
    if(DEFINED CANGJIE_CJPM_BUILD_SELF)
        if(CANGJIE_CJPM_BUILD_SELF)
            set(BOUNDSCHECK_DESTINATION_DYNAMIC ${TARGET_TRIPLE_DIRECTORY_PREFIX}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/dynamic/stdx)
            set(BOUNDSCHECK_DESTINATION_STATIC ${TARGET_TRIPLE_DIRECTORY_PREFIX}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)
        else()
            set(BOUNDSCHECK_DESTINATION_DYNAMIC stdx)
            set(BOUNDSCHECK_DESTINATION_STATIC stdx)
        endif()
    else()
        set(BOUNDSCHECK_DESTINATION_DYNAMIC ${TARGET_TRIPLE_DIRECTORY_PREFIX}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/dynamic/stdx)
        set(BOUNDSCHECK_DESTINATION_STATIC ${TARGET_TRIPLE_DIRECTORY_PREFIX}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)
    endif()
    install(
        TARGETS boundscheck
        RUNTIME
            DESTINATION
            ${BOUNDSCHECK_DESTINATION_DYNAMIC} # RUNTIME includes DLLs. This takes effect on Windows.
        LIBRARY
            DESTINATION
            ${BOUNDSCHECK_DESTINATION_DYNAMIC} # LIBRARY includes shared libraries except DLLs.
    )
    install(TARGETS boundscheck-static DESTINATION ${BOUNDSCHECK_DESTINATION_STATIC})
endif()

add_subdirectory(src)