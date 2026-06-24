/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.crypto.digest

import std.crypto.digest.Digest
import stdx.crypto.common.CryptoException

public class SM3 <: Digest {
    private var sm3Ctx = CPointer<Unit>()
    private var hasFinished = false

    public init() {
        unsafe {
            sm3Ctx = mdCtxNew()
            if (sm3Ctx.isNull()) {
                throw CryptoException("SM3 init failed due to create ctx error.")
            }
            try {
                var ret = digestInitEx(sm3Ctx, sm3())
                if (ret != 1) {
                    throw CryptoException("SM3 init failed due to inner error.")
                }
            } catch (e: Exception) {
                mdCtxFree(sm3Ctx)
                throw e
            }
        }
        hasFinished = false
    }
    ~init() {
        if (!sm3Ctx.isNull()) {
            mdCtxFree(sm3Ctx)
        }
    }
    public prop size: Int64 {
        get() {
            return SM3_DIGEST_LENGTH
        }
    }

    public prop blockSize: Int64 {
        get() {
            return SM3_BLOCK_SIZE
        }
    }

    public prop algorithm: String {
        get() {
            return SM3_DIGEST_ALGORITHM_NAME
        }
    }

    public func write(buffer: Array<Byte>): Unit {
        if (hasFinished) {
            throw CryptoException("SM3 write failed, digest calculation has been completed.")
        }
        sm3Update(sm3Ctx, buffer)
    }

    public func finish(): Array<Byte> {
        var md = Array<Byte>(size, repeat: 0)
        finish(to: md)
        md
    }

    public func finish(to!: Array<Byte>): Unit {
        if (hasFinished) {
            throw CryptoException("SM3 finish failed, digest calculation has been completed.")
        }
        if (to.size != size) {
            throw CryptoException("The length of output is not equal to the digest length.")
        }
        sm3Final(sm3Ctx, to)
        hasFinished = true
    }

    public func reset(): Unit {
        unsafe {
            if (!sm3Ctx.isNull()) {
                mdCtxFree(sm3Ctx)
                sm3Ctx = CPointer<Unit>()
            }
            sm3Ctx = mdCtxNew()
            if (sm3Ctx.isNull()) {
                throw CryptoException("SM3 reset failed due to create ctx error.")
            }
            try {
                var res = digestInitEx(sm3Ctx, sm3())
                if (res != 1) {
                    throw CryptoException("SM3 reset failed due to inner error.")
                }
            } catch (e: Exception) {
                mdCtxFree(sm3Ctx)
                throw e
            }
        }
        hasFinished = false
    }
}

func sm3Update(c: CPointer<Unit>, data: Array<Byte>): Unit {
    let dynMsgPtr = generateDynMsg()
    unsafe {
        let p: CPointerHandle<Byte> = acquireArrayRawData(data)
        let res = try {
            DYN_EVP_DigestUpdate(c, p.pointer, data.size, dynMsgPtr)
        } finally {
            releaseArrayRawData(p)
        }
        checkError(dynMsgPtr)
        if (res != 1) {
            throw CryptoException("SM3 write error.")
        }
    }
}

func sm3Final(c: CPointer<Unit>, md: Array<Byte>): Unit {
    var md_len: UInt32 = 0
    let dynMsgPtr = generateDynMsg()
    unsafe {
        let p: CPointerHandle<Byte> = acquireArrayRawData(md)
        let res = try {
            DYN_EVP_DigestFinal_ex(c, p.pointer, inout md_len, dynMsgPtr)
        } finally {
            releaseArrayRawData(p)
        }
        checkError(dynMsgPtr)
        if (res != 1) {
            throw CryptoException("SM3 finish error.")
        }
    }
}
