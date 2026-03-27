# Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
#
# This source file is part of the Cangjie project, licensed under Apache-2.0
# with Runtime Library Exception.
#
# See https://cangjie-lang.cn/pages/LICENSE for license information.

include(AddAndCombineStaticLib)
include(ExtractArchive)

set(BACKEND_TYPE CJNATIVE)

##  Make shared/static library.
# If we support cross-compiling, we need to change here for target type.
string(TOLOWER ${TARGET_TRIPLE_DIRECTORY_PREFIX}_${BACKEND_TYPE} output_cj_object_dir)
string(TOLOWER ${TARGET_TRIPLE_DIRECTORY_PREFIX} output_triple_name)
string(TOLOWER "${CMAKE_BUILD_TYPE}" lowercase_build_type)
set(CJNATIVE_BACKEND "cjnative")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib/${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH})
message(STATUS "CANGJIE_CJPM_DIR ${CANGJIE_CJPM_DIR}")
if(CMAKE_BUILD_STAGE STREQUAL "postBuild")
    if(CMAKE_CROSSCOMPILING)
        set(output_cj_object_dir ${CANGJIE_CJPM_DIR}/target/${TRIPLE}/${lowercase_build_type}/)
    else()
        set(output_cj_object_dir ${CANGJIE_CJPM_DIR}/target/${lowercase_build_type}/)
    endif()
else()
    set(output_cj_object_dir ${CMAKE_BINARY_DIR}/modules/${output_cj_object_dir})
endif()

if(CMAKE_BUILD_STAGE STREQUAL "postBuild")
    if(CMAKE_CROSSCOMPILING)
        set(stdxo_path ${CANGJIE_CJPM_DIR}/target/${TRIPLE}/${lowercase_build_type}/stdx)
    else()
        set(stdxo_path ${CANGJIE_CJPM_DIR}/target/${lowercase_build_type}/stdx)
    endif()
    
else()
    set(stdxo_path ${output_cj_object_dir})
endif()

if(DARWIN)
    set(openssl_flags -lcangjie-dynamicLoader-opensslFFI)
    set(tlsFFI_flags -lstdx.net.tlsFFI)
    set(keysFFI_flags -lstdx.crypto.keysFFI)
    set(x509FFI_flags -lstdx.crypto.x509FFI)
else()
    set(openssl_flags -l:libcangjie-dynamicLoader-opensslFFI${CMAKE_SHARED_LIBRARY_SUFFIX})
    set(tlsFFI_flags -l:libstdx.net.tlsFFI${CMAKE_SHARED_LIBRARY_SUFFIX})
    set(keysFFI_flags -l:libstdx.crypto.keysFFI${CMAKE_SHARED_LIBRARY_SUFFIX})
    set(x509FFI_flags -l:libstdx.crypto.x509FFI${CMAKE_SHARED_LIBRARY_SUFFIX})
endif()

make_cangjie_lib(
    cangjieStdx IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}Stdx cangjie-dynamicLoader-opensslFFI-shared
    CANGJIE_STD_LIB_LINK std-core std-fs
    OBJECTS ${stdxo_path}/stdx.o
    FLAGS ${openssl_flags})

add_library(stdx STATIC ${stdxo_path}/stdx.o)
set_target_properties(stdx PROPERTIES LINKER_LANGUAGE C)
install(TARGETS stdx DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

make_cangjie_lib(
    encoding IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}Encoding
    CANGJIE_STD_LIB_LINK std-core
    OBJECTS ${output_cj_object_dir}/stdx/encoding.o)

add_library(stdx.encoding STATIC ${output_cj_object_dir}/stdx/encoding.o)
set_target_properties(stdx.encoding PROPERTIES LINKER_LANGUAGE C)
install(TARGETS stdx.encoding DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

make_cangjie_lib(
    encoding.base64 IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}Base64
    CANGJIE_STD_LIB_LINK std-core
    OBJECTS ${output_cj_object_dir}/stdx/encoding.base64.o)

add_library(stdx.encoding.base64 STATIC ${output_cj_object_dir}/stdx/encoding.base64.o)
set_target_properties(stdx.encoding.base64 PROPERTIES LINKER_LANGUAGE C)
install(TARGETS stdx.encoding.base64 DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

make_cangjie_lib(
    serialization IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}StdxSerialization
    CANGJIE_STD_LIB_LINK std-core
    OBJECTS ${output_cj_object_dir}/stdx/serialization.o)

add_library(stdx.serialization STATIC ${output_cj_object_dir}/stdx/serialization.o)
set_target_properties(stdx.serialization PROPERTIES LINKER_LANGUAGE C)
install(TARGETS stdx.serialization DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

make_cangjie_lib(
    serialization.serialization IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}Serialization
    CANGJIE_STD_LIB_LINK
        std-core
        std-collection
        std-sort
        std-math
    OBJECTS ${output_cj_object_dir}/stdx/serialization.serialization.o)

add_library(stdx.serialization.serialization STATIC ${output_cj_object_dir}/stdx/serialization.serialization.o)
set_target_properties(stdx.serialization.serialization PROPERTIES LINKER_LANGUAGE C)
install(TARGETS stdx.serialization.serialization
        DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

make_cangjie_lib(
    encoding.json IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}Json stdx.encoding.jsonFFI
    CANGJIE_STDX_LIB_DEPENDS  serialization.serialization
    CANGJIE_STD_LIB_LINK
        std-core
        std-collection
        std-convert
        std-sort
        std-math
    OBJECTS ${output_cj_object_dir}/stdx/encoding.json.o
    FLAGS -lstdx.encoding.jsonFFI)
get_target_property(JSONFFI_OBJS stdx.encoding.jsonFFI SOURCES)

add_library(stdx.encoding.json STATIC ${JSONFFI_OBJS} ${output_cj_object_dir}/stdx/encoding.json.o)
set_target_properties(stdx.encoding.json PROPERTIES LINKER_LANGUAGE C)
install(TARGETS stdx.encoding.json DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

make_cangjie_lib(
    encoding.json.stream IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}JsonStream
        stdx.encoding.json.streamFFI
        stdx.encoding.jsonFFI
    CANGJIE_STD_LIB_LINK
        std-core
        std-collection
        std-collection.concurrent
        std-io
        std-math.numeric
        std-math
        std-time
        std-sort
        std-convert
    OBJECTS ${output_cj_object_dir}/stdx/encoding.json.stream.o
    FLAGS
        -lstdx.encoding.json.streamFFI
        -lstdx.encoding.jsonFFI)
get_target_property(JSONFFI_OBJS stdx.encoding.jsonFFI SOURCES)

add_library(
    stdx.encoding.json.stream STATIC
    $<TARGET_OBJECTS:stdx.encoding.json.streamFFI-objs>
    ${JSONFFI_OBJS}
    ${output_cj_object_dir}/stdx/encoding.json.stream.o)
install(TARGETS stdx.encoding.json.stream DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

if(NOT WIN32)
    make_cangjie_lib(
        fuzz IS_SHARED ALLOW_UNDEFINED
        DEPENDS cangjie${BACKEND_TYPE}StdxFuzz
        CANGJIE_STD_LIB_LINK std-core
        OBJECTS ${output_cj_object_dir}/stdx/fuzz.o)

    add_library(stdx.fuzz STATIC ${output_cj_object_dir}/stdx/fuzz.o)
    set_target_properties(stdx.fuzz PROPERTIES LINKER_LANGUAGE C)
    install(TARGETS stdx.fuzz DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

    make_cangjie_lib(
        fuzz.fuzz IS_SHARED ALLOW_UNDEFINED
        DEPENDS
            cangjie${BACKEND_TYPE}Fuzz
            stdx.fuzz.fuzzFFI
        CANGJIE_STD_LIB_LINK
            std-core
            std-collection
            std-process
            std-convert
        OBJECTS ${output_cj_object_dir}/stdx/fuzz.fuzz.o
        FORCE_LINK_ARCHIVES stdx.fuzz.fuzzFFI
        FLAGS -lstdx.fuzz.fuzzFFI)
    get_target_property(FUZZFFI_OBJS stdx.fuzz.fuzzFFI SOURCES)

    add_library(stdx.fuzz.fuzz STATIC ${FUZZFFI_OBJS} ${output_cj_object_dir}/stdx/fuzz.fuzz.o)
    set_target_properties(stdx.fuzz.fuzz PROPERTIES LINKER_LANGUAGE C)
    install(TARGETS stdx.fuzz.fuzz DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)
endif()

make_cangjie_lib(
    compress.zlib IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}ZLIB stdx.compress.zlibFFI
    CANGJIE_STD_LIB_LINK std-core std-collection std-io std-math

    OBJECTS ${output_cj_object_dir}/stdx/compress.zlib.o
    FLAGS -lstdx.compress.zlibFFI)

get_target_property(ZLIBFFI_OBJS stdx.compress.zlibFFI SOURCES)

add_library(stdx.compress.zlib STATIC ${ZLIBFFI_OBJS} ${output_cj_object_dir}/stdx/compress.zlib.o)
set_target_properties(stdx.compress.zlib PROPERTIES LINKER_LANGUAGE C)
install(TARGETS stdx.compress.zlib DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

make_cangjie_lib(
    compress.tar IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}Tar stdx.compress.tarFFI
    CANGJIE_STD_LIB_LINK std-core std-collection std-io std-math std-time std-convert std-fs std-env

    OBJECTS ${output_cj_object_dir}/stdx/compress.tar.o
    FLAGS -lstdx.compress.tarFFI)

    get_target_property(TARFFI_OBJS stdx.compress.tarFFI SOURCES)

    add_library(stdx.compress.tar STATIC ${TARFFI_OBJS} ${output_cj_object_dir}/stdx/compress.tar.o)
    set_target_properties(stdx.compress.tar PROPERTIES LINKER_LANGUAGE C)
    install(TARGETS stdx.compress.tar DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

    make_cangjie_lib(
        compress IS_SHARED
        DEPENDS cangjie${BACKEND_TYPE}StdxCompress cangjie${BACKEND_TYPE}Tar cangjie${BACKEND_TYPE}ZLIB
        CANGJIE_STDX_LIB_DEPENDS compress.tar compress.zlib
        CANGJIE_STD_LIB_LINK std-core std-fs std-io
        OBJECTS ${output_cj_object_dir}/stdx/compress.o)

    add_library(stdx.compress STATIC ${output_cj_object_dir}/stdx/compress.o)
    set_target_properties(stdx.compress PROPERTIES LINKER_LANGUAGE C)
    install(TARGETS stdx.compress DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

make_cangjie_lib(
    encoding.url IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}Url
    CANGJIE_STD_LIB_LINK
        std-core
        std-collection
        std-sort
        std-math
        std-convert
    OBJECTS ${output_cj_object_dir}/stdx/encoding.url.o)

add_library(stdx.encoding.url STATIC ${output_cj_object_dir}/stdx/encoding.url.o)
set_target_properties(stdx.encoding.url PROPERTIES LINKER_LANGUAGE C)
install(TARGETS stdx.encoding.url DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

make_cangjie_lib(
    unittest IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}StdxUnittest
    CANGJIE_STD_LIB_LINK std-core
    OBJECTS ${output_cj_object_dir}/stdx/unittest.o)

add_library(stdx.unittest STATIC ${output_cj_object_dir}/stdx/unittest.o)
set_target_properties(stdx.unittest PROPERTIES LINKER_LANGUAGE C)
install(TARGETS stdx.unittest DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

make_cangjie_lib(
    unittest.data IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}UnittestData
    CANGJIE_STDX_LIB_DEPENDS serialization.serialization encoding.json
    CANGJIE_STD_LIB_LINK
        std-core
        std-collection
        std-convert
        std-sort
        std-math
        std-io
        std-fs
        std-unittest.common
    OBJECTS ${output_cj_object_dir}/stdx/unittest.data.o)

add_library(stdx.unittest.data STATIC ${output_cj_object_dir}/stdx/unittest.data.o)
set_target_properties(stdx.unittest.data PROPERTIES LINKER_LANGUAGE C)
install(TARGETS stdx.unittest.data DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

make_cangjie_lib(
    net IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}StdxNet
    CANGJIE_STD_LIB_LINK std-core
    OBJECTS ${output_cj_object_dir}/stdx/net.o)

add_library(stdx.net STATIC ${output_cj_object_dir}/stdx/net.o)
set_target_properties(stdx.net PROPERTIES LINKER_LANGUAGE C)
install(TARGETS stdx.net DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

make_cangjie_lib(
    net.tls IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}Tls stdx.net.tlsFFI-shared  cangjie-dynamicLoader-opensslFFI-shared
    CANGJIE_STDX_LIB_DEPENDS
        encoding.hex
        crypto.x509
        crypto.digest
        crypto.common
        crypto.keys
        net.tls.common
    CANGJIE_STD_LIB_LINK
        std-core
        std-math
        std-collection
        std-collection.concurrent
        std-io
        std-net
        std-sync
        std-time
        std-sort
    OBJECTS ${output_cj_object_dir}/stdx/net.tls.o
    FLAGS
        ${tlsFFI_flags}
        ${openssl_flags}
        ${ssl_dependencies}
        $<$<BOOL:${MINGW}>:-pthread>
        $<$<BOOL:${MINGW}>:-lws2_32>
        $<$<NOT:$<BOOL:${WIN32}>>:-ldl>)
if(CMAKE_BUILD_STAGE STREQUAL "postBuild")
    set(tls_depends stdx.net.tlsFFI ${CANGJIE_OPENSSL_FFI_OBJECTS_TARGET})
else()
    set(tls_depends cangjie${BACKEND_TYPE}Tls stdx.net.tlsFFI ${CANGJIE_OPENSSL_FFI_OBJECTS_TARGET})
endif()
add_and_combine_static_lib(
    TARGET stdx-net-tls
    OUTPUT_NAME libstdx.net.tls.a
    LIBRARIES
        $<TARGET_OBJECTS:stdx.net.tlsFFI-objs>
        ${output_cj_object_dir}/stdx/net.tls.o
        $<TARGET_OBJECTS:${CANGJIE_OPENSSL_FFI_OBJECTS_TARGET}>
    DEPENDS
        ${tls_depends})
if(CMAKE_BUILD_STAGE STREQUAL "postBuild")
    set(tls_strong_depends stdx.net.tlsFFI-strong ${CANGJIE_OPENSSL_FFI_STRONG_OBJECTS_TARGET})
else()
    set(tls_strong_depends cangjie${BACKEND_TYPE}Tls stdx.net.tlsFFI-strong ${CANGJIE_OPENSSL_FFI_STRONG_OBJECTS_TARGET})
endif()
add_and_combine_static_lib(
    TARGET stdx-net-tls-strong
    OUTPUT_NAME libstdx.net.tls-strong.a
    LIBRARIES
        $<TARGET_OBJECTS:stdx.net.tlsFFI-objs>
        ${output_cj_object_dir}/stdx/net.tls.o
        $<TARGET_OBJECTS:${CANGJIE_OPENSSL_FFI_STRONG_OBJECTS_TARGET}>
    DEPENDS
        ${tls_strong_depends})
install(FILES ${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}/libstdx.net.tls.a
        DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

make_cangjie_lib(
    net.tls.common IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}TlsCommon
    CANGJIE_STDX_LIB_DEPENDS
        crypto.common
    CANGJIE_STD_LIB_LINK
        std-core
        std-collection
        std-net
        std-io
    OBJECTS ${output_cj_object_dir}/stdx/net.tls.common.o)

add_library(stdx.net.tls.common STATIC ${output_cj_object_dir}/stdx/net.tls.common.o)
set_target_properties(stdx.net.tls.common PROPERTIES LINKER_LANGUAGE C)
install(TARGETS stdx.net.tls.common DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

make_cangjie_lib(
    net.http IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}Http cangjie-dynamicLoader-opensslFFI-shared
    CANGJIE_STDX_LIB_DEPENDS
        encoding.base64
        encoding.url
        log
        logger
        net.tls.common
        crypto.common
    CANGJIE_STD_LIB_LINK
        std-core
        std-sync
        std-time
        std-fs
        std-collection
        std-collection.concurrent
        std-io
        std-convert
        std-random
        std-console
        std-sort
        std-unicode
        std-net
        std-process
        std-overflow
        std-math
        std-env
    OBJECTS ${output_cj_object_dir}/stdx/net.http.o
    FLAGS
    ${openssl_flags}
    $<$<BOOL:${MINGW}>:-lws2_32>
    $<$<NOT:$<BOOL:${WIN32}>>:-ldl>)
add_library(stdx.net.http STATIC ${output_cj_object_dir}/stdx/net.http.o)
set_target_properties(stdx.net.http PROPERTIES LINKER_LANGUAGE C)
install(TARGETS stdx.net.http DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

make_cangjie_lib(
    crypto IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}StdxCrypto
    CANGJIE_STD_LIB_LINK std-core
    OBJECTS ${output_cj_object_dir}/stdx/crypto.o)

add_library(stdx.crypto STATIC ${output_cj_object_dir}/stdx/crypto.o)
set_target_properties(stdx.crypto PROPERTIES LINKER_LANGUAGE C)
install(TARGETS stdx.crypto DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

make_cangjie_lib(
    crypto.digest IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}Digest
        cangjie-dynamicLoader-opensslFFI-shared
    CANGJIE_STDX_LIB_DEPENDS crypto.common
    CANGJIE_STD_LIB_LINK
        std-core
        std-crypto.digest
    OBJECTS ${output_cj_object_dir}/stdx/crypto.digest.o
    FLAGS ${openssl_flags} $<$<BOOL:${MINGW}>:-lws2_32>
    $<$<NOT:$<BOOL:${WIN32}>>:-ldl>)

get_target_property(DIGESTFFI_OBJS cangjie-dynamicLoader-opensslFFI SOURCES)
add_library(stdx.crypto.digest STATIC ${DIGESTFFI_OBJS} ${output_cj_object_dir}/stdx/crypto.digest.o)
add_library(stdx.crypto.digest-strong STATIC
    $<TARGET_OBJECTS:${CANGJIE_OPENSSL_FFI_STRONG_OBJECTS_TARGET}>
    ${output_cj_object_dir}/stdx/crypto.digest.o)

set_target_properties(stdx.crypto.digest PROPERTIES LINKER_LANGUAGE C)
set_target_properties(stdx.crypto.digest-strong PROPERTIES LINKER_LANGUAGE C OUTPUT_NAME stdx.crypto.digest-strong)
install(TARGETS stdx.crypto.digest DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

make_cangjie_lib(
    crypto.keys IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}Keys
        stdx.crypto.keysFFI-shared
        cangjie-dynamicLoader-opensslFFI-shared
    CANGJIE_STDX_LIB_DEPENDS crypto.digest crypto.common encoding.hex
    CANGJIE_STD_LIB_LINK
        std-core
        std-io
        std-crypto.digest
        std-math.numeric
        std-sync
    OBJECTS ${output_cj_object_dir}/stdx/crypto.keys.o
    FLAGS
        ${keysFFI_flags}
        ${openssl_flags}
        $<$<BOOL:${MINGW}>:-lws2_32>
        $<$<NOT:$<BOOL:${WIN32}>>:-ldl>)

get_target_property(KEYSFFI_OBJS stdx.crypto.keysFFI SOURCES)
get_target_property(OPENSSLFFI_OBJS cangjie-dynamicLoader-opensslFFI SOURCES)
add_library(stdx.crypto.keys  STATIC ${KEYSFFI_OBJS} ${OPENSSLFFI_OBJS} ${output_cj_object_dir}/stdx/crypto.keys.o)
add_library(stdx.crypto.keys-strong STATIC
    $<TARGET_OBJECTS:stdx.crypto.keysFFI-objs>
    $<TARGET_OBJECTS:${CANGJIE_OPENSSL_FFI_STRONG_OBJECTS_TARGET}>
    ${output_cj_object_dir}/stdx/crypto.keys.o)
set_target_properties(stdx.crypto.keys PROPERTIES LINKER_LANGUAGE C)
set_target_properties(stdx.crypto.keys-strong PROPERTIES LINKER_LANGUAGE C OUTPUT_NAME stdx.crypto.keys-strong)
install(TARGETS stdx.crypto.keys DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

make_cangjie_lib(
    crypto.crypto IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}Crypto cangjie-dynamicLoader-opensslFFI-shared
    CANGJIE_STDX_LIB_DEPENDS crypto.digest crypto.common
    CANGJIE_STD_LIB_LINK  std-core std-math std-sync std-crypto.cipher std-io std-collection
    OBJECTS ${output_cj_object_dir}/stdx/crypto.crypto.o
    FLAGS ${openssl_flags} $<$<BOOL:${MINGW}>:-lws2_32>
    $<$<NOT:$<BOOL:${WIN32}>>:-ldl>)
get_target_property(CRYPTOCRYPTOFFI_OBJS cangjie-dynamicLoader-opensslFFI SOURCES)
add_library(stdx.crypto.crypto STATIC ${CRYPTOCRYPTOFFI_OBJS} ${output_cj_object_dir}/stdx/crypto.crypto.o)
add_library(stdx.crypto.crypto-strong STATIC
    $<TARGET_OBJECTS:${CANGJIE_OPENSSL_FFI_STRONG_OBJECTS_TARGET}>
    ${output_cj_object_dir}/stdx/crypto.crypto.o)
set_target_properties(stdx.crypto.crypto PROPERTIES LINKER_LANGUAGE C)
set_target_properties(stdx.crypto.crypto-strong PROPERTIES LINKER_LANGUAGE C OUTPUT_NAME stdx.crypto.crypto-strong)
install(TARGETS stdx.crypto.crypto DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

make_cangjie_lib(
    actors IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}Actors
    CANGJIE_STD_LIB_LINK std-core std-collection.concurrent std-sync std-time
    OBJECTS ${output_cj_object_dir}/stdx/actors.o)

add_library(stdx.actors STATIC ${output_cj_object_dir}/stdx/actors.o)
set_target_properties(stdx.actors PROPERTIES LINKER_LANGUAGE C)
install(TARGETS stdx.actors DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

if(NOT CMAKE_BUILD_STAGE STREQUAL "postBuild")
    make_cangjie_lib(
        actors.macros IS_SHARED IS_MACRO
        DEPENDS cangjie${BACKEND_TYPE}ActorsMacros
        CANGJIE_STD_LIB_LINK std-core std-ast std-collection std-convert
        OBJECTS ${output_cj_object_dir}/stdx/actors.macros.o)
else()
    string(TOLOWER ${TARGET_TRIPLE_DIRECTORY_PREFIX}_${CJNATIVE_BACKEND} output_stdx_cj_lib_dir)
    set(output_stdx_cj_lib_dir ${output_stdx_cj_lib_dir}${SANITIZER_SUBPATH})
    set(actors_macros_full_name ${CANGJIE_CJPM_DIR}/target/${lowercase_build_type}/stdx/lib-macro_stdx.actors.macros${CMAKE_SHARED_LIBRARY_SUFFIX})
    install(FILES ${actors_macros_full_name} DESTINATION ${output_stdx_cj_lib_dir}/dynamic/stdx)
    install(FILES ${actors_macros_full_name} DESTINATION ${output_stdx_cj_lib_dir}/static/stdx)
endif()

if(NOT CANGJIE_BUILD_WITHOUT_EFFECT_HANDLERS)
make_cangjie_lib(
    effect IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}Effect
    CANGJIE_STD_LIB_LINK std-core std-collection std-sync
    OBJECTS ${output_cj_object_dir}/stdx/effect.o)
 
add_library(stdx.effect STATIC ${output_cj_object_dir}/stdx/effect.o)
set_target_properties(stdx.effect PROPERTIES LINKER_LANGUAGE C)
install(TARGETS stdx.effect DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)
endif()
make_cangjie_lib(
    crypto.common IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}CryptoCommon
    CANGJIE_STDX_LIB_DEPENDS
        encoding.base64
    CANGJIE_STD_LIB_LINK
        std-core
        std-io
    OBJECTS ${output_cj_object_dir}/stdx/crypto.common.o)

add_library(stdx.crypto.common STATIC ${output_cj_object_dir}/stdx/crypto.common.o)
set_target_properties(stdx.crypto.common PROPERTIES LINKER_LANGUAGE C)
install(TARGETS stdx.crypto.common DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}/static/stdx)

make_cangjie_lib(
    crypto.kit IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}CryptoKit
    CANGJIE_STDX_LIB_DEPENDS
        crypto.common
        crypto.keys
        crypto.crypto
        crypto.x509
    CANGJIE_STD_LIB_LINK
        std-core
        std-net
    OBJECTS ${output_cj_object_dir}/stdx/crypto.kit.o)

add_library(stdx.crypto.kit STATIC ${output_cj_object_dir}/stdx/crypto.kit.o)
set_target_properties(stdx.crypto.kit PROPERTIES LINKER_LANGUAGE C)
install(TARGETS stdx.crypto.kit DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}/static/stdx)

# Testmacro has no need to cross-compile because it is always used on host platforms.
# Macros should NOT use sanitizers
make_cangjie_lib(
    encoding.hex IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}Hex
    CANGJIE_STD_LIB_LINK std-core
    OBJECTS ${output_cj_object_dir}/stdx/encoding.hex.o)

add_library(stdx.encoding.hex STATIC ${output_cj_object_dir}/stdx/encoding.hex.o)
set_target_properties(stdx.encoding.hex PROPERTIES LINKER_LANGUAGE C)
install(TARGETS stdx.encoding.hex DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

make_cangjie_lib(
    crypto.x509 IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}X509 stdx.crypto.x509FFI-shared cangjie-dynamicLoader-opensslFFI-shared
    CANGJIE_STDX_LIB_DEPENDS
        encoding.hex
        encoding.base64
        crypto.crypto
        crypto.common
        crypto.keys
    CANGJIE_STD_LIB_LINK
        std-core
        std-convert
        std-sort
        std-math
        std-time
        std-collection
        std-fs
        std-io
    OBJECTS
        ${output_cj_object_dir}/stdx/crypto.x509.o
    FLAGS
        ${x509FFI_flags}
        ${openssl_flags}
        $<$<BOOL:${WIN32}>:-lcrypt32>
        ${ssl_dependencies} $<$<BOOL:${MINGW}>:-lws2_32>
        $<$<NOT:$<BOOL:${WIN32}>>:-ldl>)
if(CMAKE_BUILD_STAGE STREQUAL "postBuild")
    set(x509_depends stdx.crypto.x509FFI ${CANGJIE_OPENSSL_FFI_OBJECTS_TARGET})
else()
    set(x509_depends cangjie${BACKEND_TYPE}X509 stdx.crypto.x509FFI ${CANGJIE_OPENSSL_FFI_OBJECTS_TARGET})
endif()
add_and_combine_static_lib(
    OUTPUT_NAME libstdx.crypto.x509.a
    TARGET stdx.crypto.x509
    LIBRARIES
        $<TARGET_OBJECTS:stdx.crypto.x509FFI-objs>
        ${output_cj_object_dir}/stdx/crypto.x509.o
        $<TARGET_OBJECTS:${CANGJIE_OPENSSL_FFI_OBJECTS_TARGET}>
    DEPENDS
        ${x509_depends})
if(CMAKE_BUILD_STAGE STREQUAL "postBuild")
    set(x509_strong_depends stdx.crypto.x509FFI-strong ${CANGJIE_OPENSSL_FFI_STRONG_OBJECTS_TARGET})
else()
    set(x509_strong_depends cangjie${BACKEND_TYPE}X509 stdx.crypto.x509FFI-strong ${CANGJIE_OPENSSL_FFI_STRONG_OBJECTS_TARGET})
endif()
add_and_combine_static_lib(
    OUTPUT_NAME libstdx.crypto.x509-strong.a
    TARGET stdx.crypto.x509-strong
    LIBRARIES
        $<TARGET_OBJECTS:stdx.crypto.x509FFI-objs>
        ${output_cj_object_dir}/stdx/crypto.x509.o
        $<TARGET_OBJECTS:${CANGJIE_OPENSSL_FFI_STRONG_OBJECTS_TARGET}>
    DEPENDS
        ${x509_strong_depends})
install(FILES ${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}/libstdx.crypto.x509.a
        DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

make_cangjie_lib(
    log IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}Log
    CANGJIE_STD_LIB_LINK std-core std-time std-collection std-sync std-sort std-math std-convert
    OBJECTS ${output_cj_object_dir}/stdx/log.o)

add_library(stdx.log STATIC ${output_cj_object_dir}/stdx/log.o)
set_target_properties(stdx.log PROPERTIES LINKER_LANGUAGE C)
install(TARGETS stdx.log DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

make_cangjie_lib(
    logger IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}Logger
    CANGJIE_STDX_LIB_DEPENDS log encoding.json.stream
    CANGJIE_STD_LIB_LINK std-core std-collection std-collection.concurrent std-io std-sync std-time std-sort std-math
    OBJECTS ${output_cj_object_dir}/stdx/logger.o)

add_library(stdx.logger STATIC ${output_cj_object_dir}/stdx/logger.o)
set_target_properties(stdx.logger PROPERTIES LINKER_LANGUAGE C)
install(TARGETS stdx.logger DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx)

if(NOT CANGJIE_CJPM_BUILD_TYPE)
    make_cangjie_lib(
        aspectCJ IS_SHARED
        DEPENDS cangjie${BACKEND_TYPE}AspectCJ
        CANGJIE_STD_LIB_LINK std-core
        OBJECTS ${output_cj_object_dir}/stdx/aspectCJ.o)

    add_library(stdx.aspectCJ STATIC ${output_cj_object_dir}/stdx/aspectCJ.o)
    set_target_properties(stdx.aspectCJ PROPERTIES LINKER_LANGUAGE C)
    install(TARGETS stdx.aspectCJ DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}/static/stdx)
endif()

make_cangjie_lib(
    string_intern IS_SHARED
    DEPENDS cangjie${BACKEND_TYPE}StringIntern
    CANGJIE_STD_LIB_LINK
        std-core
        std-collection
        std-sync
        std-time
    OBJECTS ${output_cj_object_dir}/stdx/string_intern.o)

add_library(stdx.string_intern STATIC ${output_cj_object_dir}/stdx/string_intern.o)
set_target_properties(stdx.string_intern PROPERTIES LINKER_LANGUAGE C)
install(TARGETS stdx.string_intern DESTINATION ${output_triple_name}_${CJNATIVE_BACKEND}/static/stdx)
 	 

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# Defined all xxx_DEPENDENCIES, which are for all backends.
if(CMAKE_BUILD_STAGE STREQUAL "postBuild")
    include(LibraryDependenciesV2)
else()
    include(LibraryDependencies)
endif()

add_cangjie_library(
    cangjie${BACKEND_TYPE}Stdx
    NO_SUB_PKG
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    OUTPUT_NAME "cangjieStdx"
    PACKAGE_NAME "stdx"
    MODULE_NAME ""
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx
    DEPENDS ${STDX_DEPENDENCIES})

add_cangjie_library(
    cangjie${BACKEND_TYPE}Encoding
    NO_SUB_PKG
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    OUTPUT_NAME "cangjieEncoding"
    PACKAGE_NAME "encoding"
    MODULE_NAME "stdx"
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/encoding
    DEPENDS ${ENCODING_DEPENDENCIES})

add_cangjie_library(
    cangjie${BACKEND_TYPE}Base64
    NO_SUB_PKG
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    OUTPUT_NAME "cangjieBase64"
    PACKAGE_NAME "encoding.base64"
    MODULE_NAME "stdx"
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/encoding/base64
    DEPENDS ${ENCODING_BASE64_DEPENDENCIES})


add_cangjie_library(
    cangjie${BACKEND_TYPE}Log
    NO_SUB_PKG
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    PACKAGE_NAME "log"
    MODULE_NAME "stdx"
    SOURCES ${LOG_SRCS}
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/log
    DEPENDS ${LOG_DEPENDENCIES})

add_cangjie_library(
    cangjie${BACKEND_TYPE}Logger
    NO_SUB_PKG
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    PACKAGE_NAME "logger"
    MODULE_NAME "stdx"
    SOURCES ${LOGGER_SRCS}
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/logger
    DEPENDS ${LOGGER_DEPENDENCIES})

if(NOT CANGJIE_CJPM_BUILD_TYPE)
    add_cangjie_library(
        cangjie${BACKEND_TYPE}AspectCJ
        NO_SUB_PKG
        IS_STDXLIB
        IS_PACKAGE
        IS_CJNATIVE_BACKEND
        PACKAGE_NAME "aspectCJ"
        MODULE_NAME "stdx"
        SOURCES ${ASPECTCJ_SRCS}
        SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/aspectCJ
        DEPENDS ${ASPECTCJ_DEPENDENCIES})
endif()

add_cangjie_library(
    cangjie${BACKEND_TYPE}StdxSerialization
    NO_SUB_PKG
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    PACKAGE_NAME "serialization"
    MODULE_NAME "stdx"
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/serialization
    DEPENDS ${SERIALIZATIONBASE_DEPENDENCIES})

add_cangjie_library(
    cangjie${BACKEND_TYPE}Serialization
    NO_SUB_PKG
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    PACKAGE_NAME "serialization.serialization"
    MODULE_NAME "stdx"
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/serialization/serialization
    DEPENDS ${SERIALIZATION_DEPENDENCIES})

add_cangjie_library(
    cangjie${BACKEND_TYPE}Json
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    PACKAGE_NAME "encoding.json"
    MODULE_NAME "stdx"
    SOURCES ${JSON_SRCS}
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/encoding/json
    DEPENDS ${ENCODING_JSON_DEPENDENCIES})

add_cangjie_library(
    cangjie${BACKEND_TYPE}JsonStream
    NO_SUB_PKG
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    OUTPUT_NAME "cangjieJson"
    PACKAGE_NAME "encoding.json.stream"
    MODULE_NAME "stdx"
    SOURCES ${JSON_STREAM_SRCS}
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/encoding/json/stream
    DEPENDS ${ENCODING_JSON_STREAM_DEPENDENCIES})

if(NOT WIN32)
    # Fuzz library is not expect to be sancov instrumented:
    # Fuzz library is utilizing sancov to guide fuzz input generation,
    # instrumentation in fuzz library is useless and make fuzzing less
    # effecient.

    add_cangjie_library(
        cangjie${BACKEND_TYPE}StdxFuzz
        NO_SUB_PKG
        IS_STDXLIB
        IS_PACKAGE
        IS_CJNATIVE_BACKEND
        PACKAGE_NAME "fuzz"
        MODULE_NAME "stdx"
        SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/fuzz
        DEPENDS ${FUZZBASE_DEPENDENCIES})

    add_cangjie_library(
        cangjie${BACKEND_TYPE}Fuzz
        NO_SUB_PKG
        IS_STDXLIB IS_PACKAGE
        IS_CJNATIVE_BACKEND
        PACKAGE_NAME "fuzz.fuzz"
        MODULE_NAME "stdx"
        SOURCES ${FUZZ_SRCS}
        SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/fuzz/fuzz
        DEPENDS ${FUZZ_FUZZ_DEPENDENCIES})
endif()

add_cangjie_library(
    cangjie${BACKEND_TYPE}StdxCrypto
    NO_SUB_PKG
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    PACKAGE_NAME "crypto"
    MODULE_NAME "stdx"
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/crypto
    DEPENDS ${CRYPTOBASE_DEPENDENCIES})


add_cangjie_library(
    cangjie${BACKEND_TYPE}Digest
    NO_SUB_PKG
    IS_STDXLIB
    IS_CJNATIVE_BACKEND
    PACKAGE_NAME "crypto.digest"
    MODULE_NAME "stdx"
    SOURCES ${CRYPTODIGEST_SRCS}
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/crypto/digest
    DEPENDS ${CRYPTO_DIGEST_DEPENDENCIES})

add_cangjie_library(
    cangjie${BACKEND_TYPE}Keys
    NO_SUB_PKG
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    PACKAGE_NAME "crypto.keys"
    MODULE_NAME "stdx"
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/crypto/keys
    DEPENDS ${CRYPTO_KEYS_DEPENDENCIES})


add_cangjie_library(
    cangjie${BACKEND_TYPE}X509
    NO_SUB_PKG
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    PACKAGE_NAME "crypto.x509"
    MODULE_NAME "stdx"
    SOURCES ${X509_SRCS}
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/crypto/x509
    DEPENDS ${X509_DEPENDENCIES})

add_cangjie_library(
    cangjie${BACKEND_TYPE}Crypto
    NO_SUB_PKG
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    PACKAGE_NAME "crypto.crypto"
    MODULE_NAME "stdx"
    SOURCES ${CRYPTO_SRCS}
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/crypto/crypto
    DEPENDS ${CRYPTO_DEPENDENCIES})

add_cangjie_library(
    cangjie${BACKEND_TYPE}CryptoCommon
    NO_SUB_PKG
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    PACKAGE_NAME "crypto.common"
    MODULE_NAME "stdx"
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/crypto/common
    DEPENDS ${CRYPTO_COMMON_DEPENDENCIES})

add_cangjie_library(
    cangjie${BACKEND_TYPE}CryptoKit
    NO_SUB_PKG
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    PACKAGE_NAME "crypto.kit"
    MODULE_NAME "stdx"
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/crypto/kit
    DEPENDS ${CRYPTO_KIT_DEPENDENCIES})

add_cangjie_library(
    cangjie${BACKEND_TYPE}ZLIB
    NO_SUB_PKG
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    PACKAGE_NAME "compress.zlib"
    MODULE_NAME "stdx"
    SOURCES ${ZLIB_SRCS}
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/compress/zlib
    DEPENDS ${COMPRESS_ZLIB_DEPENDENCIES})

add_cangjie_library(
    cangjie${BACKEND_TYPE}Tar
    NO_SUB_PKG
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    PACKAGE_NAME "compress.tar"
    MODULE_NAME "stdx"
    SOURCES ${TAR_SRCS}
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/compress/tar
    DEPENDS ${COMPRESS_TAR_DEPENDENCIES})

add_cangjie_library(
    cangjie${BACKEND_TYPE}StdxCompress
    NO_SUB_PKG
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    OUTPUT_NAME "cangjieCompress"
    PACKAGE_NAME "compress"
    MODULE_NAME "stdx"
    SOURCES ${COMPRESS_SRCS}
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/compress
    DEPENDS ${COMPRESS_DEPENDENCIES})

add_cangjie_library(
    cangjie${BACKEND_TYPE}Url
    NO_SUB_PKG
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    PACKAGE_NAME "encoding.url"
    MODULE_NAME "stdx"
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/encoding/url
    DEPENDS ${ENCODING_URL_DEPENDENCIES})

add_cangjie_library(
    cangjie${BACKEND_TYPE}StdxUnittest
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    PACKAGE_NAME "unittest"
    MODULE_NAME "stdx"
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/unittest
    DEPENDS ${UNITTESTBASE_DEPENDENCIES})

add_cangjie_library(
    cangjie${BACKEND_TYPE}UnittestData
    NO_SUB_PKG
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    PACKAGE_NAME "unittest.data"
    MODULE_NAME "stdx"
    SOURCES ${UNITTEST_DATA_SRCS}
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/unittest/data
    DEPENDS ${UNITTEST_DATA_DEPENDENCIES})

add_cangjie_library(
    cangjie${BACKEND_TYPE}StdxNet
    NO_SUB_PKG
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    PACKAGE_NAME "net"
    MODULE_NAME "stdx"
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/net
    DEPENDS ${NETBASE_DEPENDENCIES})

add_cangjie_library(
    cangjie${BACKEND_TYPE}StringIntern
    NO_SUB_PKG
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    PACKAGE_NAME "string_intern"
    MODULE_NAME "stdx"
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/string_intern
    DEPENDS ${STRING_INTERN_DEPENDENCIES})
    
add_cangjie_library(
    cangjie${BACKEND_TYPE}Tls
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    PACKAGE_NAME "net.tls"
    MODULE_NAME "stdx"
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/net/tls
    DEPENDS ${NET_TLS_DEPENDENCIES})

add_cangjie_library(
    cangjie${BACKEND_TYPE}TlsCommon
    NO_SUB_PKG
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    PACKAGE_NAME "net.tls.common"
    MODULE_NAME "stdx"
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/net/tls/common
    DEPENDS ${NET_TLS_COMMON_DEPENDENCIES})

add_cangjie_library(
    cangjie${BACKEND_TYPE}Http IS_STDXLIB IS_CJNATIVE_BACKEND
    NO_SUB_PKG
    PACKAGE_NAME "net.http"
    MODULE_NAME "stdx"
    SOURCES ${HTTP_SRCS}
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/net/http
    DEPENDS ${NET_HTTP_DEPENDENCIES})

if(NOT CANGJIE_BUILD_WITHOUT_EFFECT_HANDLERS)
add_cangjie_library(
    cangjie${BACKEND_TYPE}Effect
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    PACKAGE_NAME "effect"
    MODULE_NAME "stdx"
    SOURCES ${EFFECT_SRCS}
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/effect
    DEPENDS ${EFFECT_DEPENDENCIES})
endif()

add_cangjie_library(
    cangjie${BACKEND_TYPE}Hex
    NO_SUB_PKG
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    PACKAGE_NAME "encoding.hex"
    MODULE_NAME "stdx"
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/encoding/hex
    DEPENDS ${ENCODING_HEX_DEPENDENCIES})

add_cangjie_library(
    cangjie${BACKEND_TYPE}Actors
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    PACKAGE_NAME "actors"
    MODULE_NAME "stdx"
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/actors
    DEPENDS ${ACTORS_DEPENDENCIES})

add_cangjie_library(
    cangjie${BACKEND_TYPE}ActorsMacros
    NO_SUB_PKG
    IS_STDXLIB
    IS_PACKAGE
    IS_CJNATIVE_BACKEND
    PACKAGE_NAME "actors.macros"
    MODULE_NAME "stdx"
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/stdx/actors/macros
    DEPENDS ${ACTORS_MACROS_DEPENDENCIES})

set(OPENSSL_STRONG_STATIC_VARIANT_DIR
    "${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static-static-link-extern/stdx")
set(OPENSSL_STRONG_PACKAGE_ARCHIVE_DIR
    "${CMAKE_BINARY_DIR}/lib/${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}")
set(OPENSSL_STRONG_FFI_ARCHIVE_DIR
    "${CMAKE_BINARY_DIR}/lib")
install(CODE "
    set(default_dir \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${output_triple_name}_${CJNATIVE_BACKEND}${SANITIZER_SUBPATH}/static/stdx\")
    set(variant_dir \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${OPENSSL_STRONG_STATIC_VARIANT_DIR}\")
    file(REMOVE_RECURSE \"\${variant_dir}\")
    file(MAKE_DIRECTORY \"\${variant_dir}\")
    file(COPY \"\${default_dir}/\" DESTINATION \"\${variant_dir}\")
    execute_process(COMMAND \"${CMAKE_COMMAND}\" -E copy_if_different \"${OPENSSL_STRONG_FFI_ARCHIVE_DIR}/libcangjie-dynamicLoader-opensslFFI-strong.a\" \"\${variant_dir}/libcangjie-dynamicLoader-opensslFFI.a\")
    execute_process(COMMAND \"${CMAKE_COMMAND}\" -E copy_if_different \"${OPENSSL_STRONG_FFI_ARCHIVE_DIR}/libstdx.net.tlsFFI-strong.a\" \"\${variant_dir}/libstdx.net.tlsFFI.a\")
    execute_process(COMMAND \"${CMAKE_COMMAND}\" -E copy_if_different \"${OPENSSL_STRONG_FFI_ARCHIVE_DIR}/libstdx.crypto.keysFFI-strong.a\" \"\${variant_dir}/libstdx.crypto.keysFFI.a\")
    execute_process(COMMAND \"${CMAKE_COMMAND}\" -E copy_if_different \"${OPENSSL_STRONG_FFI_ARCHIVE_DIR}/libstdx.crypto.x509FFI-strong.a\" \"\${variant_dir}/libstdx.crypto.x509FFI.a\")
    execute_process(COMMAND \"${CMAKE_COMMAND}\" -E copy_if_different \"${OPENSSL_STRONG_PACKAGE_ARCHIVE_DIR}/libstdx.net.tls-strong.a\" \"\${variant_dir}/libstdx.net.tls.a\")
    execute_process(COMMAND \"${CMAKE_COMMAND}\" -E copy_if_different \"${OPENSSL_STRONG_PACKAGE_ARCHIVE_DIR}/libstdx.crypto.digest-strong.a\" \"\${variant_dir}/libstdx.crypto.digest.a\")
    execute_process(COMMAND \"${CMAKE_COMMAND}\" -E copy_if_different \"${OPENSSL_STRONG_PACKAGE_ARCHIVE_DIR}/libstdx.crypto.keys-strong.a\" \"\${variant_dir}/libstdx.crypto.keys.a\")
    execute_process(COMMAND \"${CMAKE_COMMAND}\" -E copy_if_different \"${OPENSSL_STRONG_PACKAGE_ARCHIVE_DIR}/libstdx.crypto.crypto-strong.a\" \"\${variant_dir}/libstdx.crypto.crypto.a\")
    execute_process(COMMAND \"${CMAKE_COMMAND}\" -E copy_if_different \"${OPENSSL_STRONG_PACKAGE_ARCHIVE_DIR}/libstdx.crypto.x509-strong.a\" \"\${variant_dir}/libstdx.crypto.x509.a\")
")
