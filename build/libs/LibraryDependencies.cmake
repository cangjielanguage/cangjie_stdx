# Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
#
# This source file is part of the Cangjie project, licensed under Apache-2.0
# with Runtime Library Exception.
#
# See https://cangjie-lang.cn/pages/LICENSE for license information.

# Defining dependencies for all backends, BACKEND_TYPE is defined outside where this file is included

set(LOGGER_DEPENDENCIES
    cangjie${BACKEND_TYPE}Log
    cangjie${BACKEND_TYPE}JsonStream)

set(ENCODING_JSON_DEPENDENCIES
    cangjie${BACKEND_TYPE}Serialization)

set(CRYPTO_COMMON_DEPENDENCIES
    cangjie${BACKEND_TYPE}Base64)

set(CRYPTO_KIT_DEPENDENCIES
    cangjie${BACKEND_TYPE}CryptoCommon
    cangjie${BACKEND_TYPE}Crypto
    cangjie${BACKEND_TYPE}X509
    cangjie${BACKEND_TYPE}Keys)

set(CRYPTO_DEPENDENCIES
    cangjie${BACKEND_TYPE}Digest
    cangjie${BACKEND_TYPE}CryptoCommon)

set(CRYPTO_DIGEST_DEPENDENCIES
    cangjie${BACKEND_TYPE}Hex
    cangjie${BACKEND_TYPE}CryptoCommon)

set(CRYPTO_KEYS_DEPENDENCIES
    cangjie${BACKEND_TYPE}Digest
    cangjie${BACKEND_TYPE}Hex
    cangjie${BACKEND_TYPE}CryptoCommon)

set(X509_DEPENDENCIES
    cangjie${BACKEND_TYPE}Hex
    cangjie${BACKEND_TYPE}Base64
    cangjie${BACKEND_TYPE}Crypto
    cangjie${BACKEND_TYPE}Keys
    cangjie${BACKEND_TYPE}CryptoCommon)

set(NET_TLS_DEPENDENCIES
    cangjie${BACKEND_TYPE}Hex
    cangjie${BACKEND_TYPE}Base64
    cangjie${BACKEND_TYPE}X509
    cangjie${BACKEND_TYPE}Digest
    cangjie${BACKEND_TYPE}CryptoCommon
    cangjie${BACKEND_TYPE}TlsCommon)

set(NET_TLS_COMMON_DEPENDENCIES
    cangjie${BACKEND_TYPE}CryptoCommon)

set(NET_HTTP_DEPENDENCIES
    cangjie${BACKEND_TYPE}Base64
    cangjie${BACKEND_TYPE}Url
    cangjie${BACKEND_TYPE}Log
    cangjie${BACKEND_TYPE}Logger
    cangjie${BACKEND_TYPE}TlsCommon
    cangjie${BACKEND_TYPE}CryptoCommon)

set(UNITTEST_DATA_DEPENDENCIES
    cangjie${BACKEND_TYPE}Serialization
    cangjie${BACKEND_TYPE}Json)
    
set(COMPRESS_DEPENDENCIES
    cangjie${BACKEND_TYPE}ZLIB
    cangjie${BACKEND_TYPE}Tar)

set(STRING_INTERN_DEPENDENCIES)

set(ASPECTCJ_DEPENDENCIES)

set(CHIR_TOSTRING_MACRO_DEPENDENCIES)

set(CHIR_DEPENDENCIES cangjie${BACKEND_TYPE}ChirToStringMacro)

if(NOT CANGJIE_BUILD_WITHOUT_EFFECT_HANDLERS)
set(EFFECT_DEPENDENCIES)
endif()

set(ACTORS_DEPENDENCIES)

set(ACTORS_MACROS_DEPENDENCIES)

set(SYNTAX_DEPENDENCIES FLATC_OUTPUTS)