/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx

import std.fs.*

foreign func CJ_OpenSSL_SetPath(cryptoPath: CString, sslPath: CString): Int32

private func formatOpenSslPathError(cryptoPath: String, sslPath: String, reason: String): String {
    return "Failed to set OpenSSL paths. cryptoPath=${cryptoPath}, sslPath=${sslPath}. ${reason}"
}

func setOpenSslPath(cryptoPath: Path, sslPath: Path): Unit {
    let requestedCryptoPath = cryptoPath.toString()
    let requestedSslPath = sslPath.toString()
    unsafe {
        var cryptoPathStr = requestedCryptoPath
        var sslPathStr = requestedSslPath
        try {
            cryptoPathStr = canonicalize(cryptoPath).toString()
            sslPathStr = canonicalize(sslPath).toString()
            try (
                cryptoPathCStr = LibC.mallocCString(cryptoPathStr).asResource(),
                sslPathCStr = LibC.mallocCString(sslPathStr).asResource()
            ) {
                if (CJ_OpenSSL_SetPath(cryptoPathCStr.value, sslPathCStr.value) != 1) {
                    throw IllegalStateException("Call setOpenSslPath before the first OpenSSL usage.")
                }
            }
        } catch(e: Exception) {
            throw IllegalStateException(formatOpenSslPathError(cryptoPathStr, sslPathStr, e.message))
        }
    }
}
