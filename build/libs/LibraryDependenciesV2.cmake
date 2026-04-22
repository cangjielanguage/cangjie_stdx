# Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
#
# This source file is part of the Cangjie project, licensed under Apache-2.0
# with Runtime Library Exception.
#
# See https://cangjie-lang.cn/pages/LICENSE for license information.

# Defining dependencies for all backends, BACKEND_TYPE is defined outside where this file is included

set(LOGGER_DEPENDENCIES
    cangjie${BACKEND_TYPE}Log_bc
    cangjie${BACKEND_TYPE}JsonStream_bc)

set(ENCODING_JSON_DEPENDENCIES
    cangjie${BACKEND_TYPE}Serialization_bc)

set(CRYPTO_COMMON_DEPENDENCIES
    cangjie${BACKEND_TYPE}Base64_bc)

set(CRYPTO_KIT_DEPENDENCIES
    cangjie${BACKEND_TYPE}CryptoCommon_bc
    cangjie${BACKEND_TYPE}Crypto_bc
    cangjie${BACKEND_TYPE}X509_bc
    cangjie${BACKEND_TYPE}Keys_bc)

set(CRYPTO_DEPENDENCIES
    cangjie${BACKEND_TYPE}Digest_bc
    cangjie${BACKEND_TYPE}CryptoCommon_bc)

set(CRYPTO_DIGEST_DEPENDENCIES
    cangjie${BACKEND_TYPE}Hex_bc
    cangjie${BACKEND_TYPE}CryptoCommon_bc)

set(CRYPTO_KEYS_DEPENDENCIES
    cangjie${BACKEND_TYPE}Digest_bc
    cangjie${BACKEND_TYPE}Hex_bc
    cangjie${BACKEND_TYPE}CryptoCommon_bc)

set(X509_DEPENDENCIES
    cangjie${BACKEND_TYPE}Hex_bc
    cangjie${BACKEND_TYPE}Base64_bc
    cangjie${BACKEND_TYPE}Crypto_bc
    cangjie${BACKEND_TYPE}Keys_bc
    cangjie${BACKEND_TYPE}CryptoCommon_bc)

set(NET_TLS_DEPENDENCIES
    cangjie${BACKEND_TYPE}Hex_bc
    cangjie${BACKEND_TYPE}Base64_bc
    cangjie${BACKEND_TYPE}X509_bc
    cangjie${BACKEND_TYPE}Digest_bc
    cangjie${BACKEND_TYPE}CryptoCommon_bc
    cangjie${BACKEND_TYPE}TlsCommon_bc)

set(NET_TLS_COMMON_DEPENDENCIES
    cangjie${BACKEND_TYPE}CryptoCommon_bc)

set(NET_HTTP_DEPENDENCIES
    cangjie${BACKEND_TYPE}Base64_bc
    cangjie${BACKEND_TYPE}Url_bc
    cangjie${BACKEND_TYPE}Log_bc
    cangjie${BACKEND_TYPE}Logger_bc
    cangjie${BACKEND_TYPE}TlsCommon_bc
    cangjie${BACKEND_TYPE}CryptoCommon_bc)

set(UNITTEST_DATA_DEPENDENCIES
    cangjie${BACKEND_TYPE}Serialization_bc
    cangjie${BACKEND_TYPE}Json_bc)
    
set(COMPRESS_DEPENDENCIES
    cangjie${BACKEND_TYPE}ZLIB_bc
    cangjie${BACKEND_TYPE}Tar_bc)

set(ASPECTCJ_DEPENDENCIES)

set(CHIR_TOSTRING_MACRO_DEPENDENCIES)

set(CHIR_DEPENDENCIES cangjie${BACKEND_TYPE}ChirToStringMacro)

if(NOT CANGJIE_BUILD_WITHOUT_EFFECT_HANDLERS)
set(EFFECT_DEPENDENCIES)
endif()

set(ACTORS_DEPENDENCIES)

set(ACTORS_MACROS_DEPENDENCIES)

set(SYNTAX_DEPENDENCIES FLATC_OUTPUTS)