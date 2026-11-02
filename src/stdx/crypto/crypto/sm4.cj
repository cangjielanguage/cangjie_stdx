/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.crypto.crypto

import std.crypto.cipher.*
import std.io.{InputStream, OutputStream, ByteBuffer}
import std.collection.ArrayList
import stdx.crypto.digest.*
import stdx.crypto.common.CryptoException

const SM4_BLOCK_SIZE: Int64 = 16
const SM4_KEY_SIZE: Int64 = 16
const SM4_IV_SIZE: Int64 = SM4_BLOCK_SIZE
const SM4_BUFFER_SIZE: Int64 = 1024
const SM4_GCM_TAG_SIZE: Int64 = SM4_BLOCK_SIZE
const SM4_GCM_TAG_MIN_SIZE: Int64 = 12
const SM4_DIGEST_ALGORITHM_NAME = "SM4"
// EVP_CTRL_AEAD_SET_IVLEN = 0x9 (OpenSSL evp.h)
const AEAD_SET_IVLEN: Int32 = 9

public struct OperationMode <: ToString & Equatable<OperationMode> {
    public static let ECB: OperationMode = OperationMode("ECB")
    public static let CBC: OperationMode = OperationMode("CBC")
    public static let OFB: OperationMode = OperationMode("OFB")
    public static let CFB: OperationMode = OperationMode("CFB")
    public static let CTR: OperationMode = OperationMode("CTR")
    public static let GCM: OperationMode = OperationMode("GCM")
    public let mode: String
    init(mode: String) {
        this.mode = mode
    }
    public override func toString(): String {
        mode
    }
    public override operator func ==(other: OperationMode): Bool {
        mode == other.mode
    }

    public override operator func !=(other: OperationMode): Bool {
        mode != other.mode
    }
}

public struct PaddingMode <: Equatable<PaddingMode> {
    public static let NoPadding: PaddingMode = PaddingMode(0)
    public static let PKCS7Padding: PaddingMode = PaddingMode(1)
    public let paddingType: Int64
    init(paddingType: Int64) {
        this.paddingType = paddingType
    }
    public override operator func ==(other: PaddingMode): Bool {
        paddingType == other.paddingType
    }

    public override operator func !=(other: PaddingMode): Bool {
        paddingType != other.paddingType
    }
}

public class SM4 <: BlockCipher {
    var cipherPtr: CPointer<UInt64>
    let _optMode: OperationMode
    let _key: Array<Byte>
    let _iv: Array<Byte>
    let _paddingMode: PaddingMode
    let _aad: Array<Byte>
    let _tagSize: Int64

    public init(
        optMode: OperationMode,
        key: Array<Byte>,
        iv!: Array<Byte> = Array<Byte>(),
        paddingMode!: PaddingMode = PaddingMode.PKCS7Padding,
        aad!: Array<Byte> = Array<Byte>(),
        tagSize!: Int64 = SM4_GCM_TAG_SIZE
    ) {
        if (key.size != SM4_KEY_SIZE) {
            throw CryptoException("Invalid key size: expected '${SM4_KEY_SIZE}' bytes, got '${key.size}' bytes.")
        }
        match (optMode.mode) {
            case "GCM" =>
                if (iv.size <= 0) {
                    throw CryptoException("Invalid IV size: IV must not be empty for GCM mode.")
                }
                if (tagSize < SM4_GCM_TAG_MIN_SIZE || tagSize > SM4_BLOCK_SIZE) {
                    throw CryptoException("Invalid tag size: must be between '${SM4_GCM_TAG_MIN_SIZE}' and '${SM4_BLOCK_SIZE}', got '${tagSize}'.")
                }
            case "ECB" => ()
            case _ =>
                if (iv.size != SM4_IV_SIZE) {
                    throw CryptoException("Invalid IV size: expected '${SM4_IV_SIZE}' bytes, got '${iv.size}' bytes.")
                }
        }

        unsafe {
            let algorithmOptionStr: CString = LibC.mallocCString("SM4-${optMode}")
            try {
                this.cipherPtr = cipherFetch(CPointer<UInt64>(), algorithmOptionStr, CPointer<Byte>())
            } finally {
                LibC.free(algorithmOptionStr)
            }
            if (this.cipherPtr.isNull()) {
                throw CryptoException("Unsupported algorithm or mode: 'SM4-${optMode}'.")
            }
        }
        this._optMode = optMode
        this._key = key.clone()
        this._iv = iv.clone()
        this._paddingMode = paddingMode
        this._aad = aad.clone()
        this._tagSize = tagSize
    }

    ~init() {
        _key.fill(0)
        _iv.fill(0)
        _aad.fill(0)
        if (!this.cipherPtr.isNull()) {
            unsafe { cipherFree(this.cipherPtr) }
        }
    }
    public prop blockSize: Int64 {
        get() {
            unsafe {
                return SM4_BLOCK_SIZE
            }
        }
    }
    public prop optMode: OperationMode {
        get() {
            unsafe {
                return _optMode
            }
        }
    }
    public prop keySize: Int64 {
        get() {
            unsafe {
                return SM4_KEY_SIZE
            }
        }
    }
    public prop ivSize: Int64 {
        get() {
            unsafe {
                return _iv.size
            }
        }
    }
    public prop key: Array<Byte> {
        get() {
            unsafe {
                return _key
            }
        }
    }
    public prop iv: Array<Byte> {
        get() {
            unsafe {
                return _iv
            }
        }
    }

    public prop paddingMode: PaddingMode {
        get() {
            unsafe {
                return _paddingMode
            }
        }
    }

    public prop aad: Array<Byte> {
        get() {
            unsafe {
                return _aad
            }
        }
    }

    public prop tagSize: Int64 {
        get() {
            unsafe {
                return _tagSize
            }
        }
    }

    public prop algorithm: String {
        get() {
            unsafe {
                return SM4_DIGEST_ALGORITHM_NAME
            }
        }
    }

    public func encrypt(input: Array<Byte>): Array<Byte> {
        var outPut: Array<Byte> = Array<Byte>(input.size + blockSize * 8, repeat: 0)
        var size = encrypt(input, to: outPut)
        return outPut[0..size]
    }

    public func decrypt(input: Array<Byte>): Array<Byte> {
        var outPut: Array<Byte> = Array<Byte>(input.size + blockSize * 8, repeat: 0)
        var size = decrypt(input, to: outPut)
        return outPut[0..size]
    }

    public func encrypt(input: Array<Byte>, to!: Array<Byte>): Int64 {
        var inputStream: ByteBuffer = ByteBuffer()
        var outPutStream: ByteBuffer = ByteBuffer()
        inputStream.write(input)
        encrypt(inputStream, outPutStream)
        return outPutStream.read(to)
    }

    public func decrypt(input: Array<Byte>, to!: Array<Byte>): Int64 {
        var inputStream: ByteBuffer = ByteBuffer()
        var outPutStream: ByteBuffer = ByteBuffer()
        inputStream.write(input)
        decrypt(inputStream, outPutStream)
        return outPutStream.read(to)
    }

    public func encrypt(input: InputStream, output: OutputStream): Unit {
        unsafe {
            var tag: Array<Byte> = Array<Byte>(tagSize, repeat: 0)
            var readbuff = Array<Byte>(SM4_BUFFER_SIZE, repeat: 0)
            var writebuff = Array<Byte>(SM4_BUFFER_SIZE + SM4_BLOCK_SIZE, repeat: 0)
            var inBlock: CPointerHandle<Byte> = acquireArrayRawData(readbuff)
            var outBlock: CPointerHandle<Byte> = acquireArrayRawData(writebuff)
            var aadM: CPointerHandle<Byte> = acquireArrayRawData(aad.clone())
            var tagM: CPointerHandle<Byte> = acquireArrayRawData(tag)
            var keyM: CPointerHandle<Byte> = acquireArrayRawData(key.clone())
            var ivM: CPointerHandle<Byte> = acquireArrayRawData(iv.clone())
            var ctx = CPointer<UInt64>()
            try (outlenPtr = LibC.malloc<Int32>().asResource(), outlen2Ptr = LibC.malloc<Int32>().asResource()) {
                if (outlenPtr.value.isNull() || outlen2Ptr.value.isNull()) {
                    throw CryptoException("Failed to allocate memory for encryption.")
                }
                ctx = cipherCtxNew()
                if (ctx.isNull()) {
                    throw CryptoException("Failed to create cipher context for encryption.")
                }
                encryptInit(ctx, this.cipherPtr, keyM.pointer, ivM.pointer)
                if (cipherCtxSetPadding(ctx, paddingMode.paddingType) != 1) {
                    throw CryptoException("Failed to set padding mode for encryption.")
                }
                if (optMode == OperationMode.GCM && aad.size > 0 && (encryptUpdate(ctx, CPointer<Byte>(), // cjlint-ignore !G.EXP.03
                    outlenPtr.value, aadM.pointer, aad.size) != 1)) {
                    throw CryptoException("Failed to update AAD for GCM encryption.")
                }
                outlenPtr.value.write(0)
                outlen2Ptr.value.write(0)
                var inLen = input.read(readbuff)
                do {
                    if (encryptUpdate(ctx, outBlock.pointer, outlenPtr.value, inBlock.pointer, inLen) != 1) {
                        throw CryptoException("Encryption update failed.")
                    }
                    let ptrValue = Int64(outlenPtr.value.read())
                    if (ptrValue > 0) {
                        output.write(writebuff[..ptrValue])
                    }
                    inLen = input.read(readbuff)
                } while (inLen > 0)
                if (encryptFinalEx(ctx, outBlock.pointer, outlen2Ptr.value) != 1) {
                    throw CryptoException("Encryption finalization failed.")
                }
                output.write(writebuff[..Int64(outlen2Ptr.value.read())])

                if (optMode == OperationMode.GCM) {
                    // 16 = EVP_CTRL_AEAD_GET_TAG (OpenSSL evp.h)
                    if (cipherCtx(ctx, 16, Int32(tagSize), tagM.pointer) != 1) {
                        throw CryptoException("Failed to get GCM authentication tag.")
                    }
                    output.write(tag)
                }
            } finally {
                releaseArrayRawData(inBlock)
                releaseArrayRawData(outBlock)
                releaseArrayRawData(keyM)
                releaseArrayRawData(ivM)
                releaseArrayRawData(aadM)
                releaseArrayRawData(tagM)
                cipherCtxFree(ctx)
            }
        }
    }

    public func decrypt(input: InputStream, output: OutputStream): Unit {
        unsafe {
            var readbuff = Array<Byte>(SM4_BUFFER_SIZE, repeat: 0)
            var writebuff = Array<Byte>(SM4_BUFFER_SIZE + SM4_BLOCK_SIZE, repeat: 0)
            var inBlock: CPointerHandle<Byte> = acquireArrayRawData(readbuff)
            var outBlock: CPointerHandle<Byte> = acquireArrayRawData(writebuff)
            var keyM: CPointerHandle<Byte> = acquireArrayRawData(key.clone())
            var ivM: CPointerHandle<Byte> = acquireArrayRawData(iv.clone())
            var aadM: CPointerHandle<Byte> = acquireArrayRawData(aad.clone())
            var ctx = CPointer<UInt64>()
            try (outlenPtr = LibC.malloc<Int32>().asResource(), outlen2Ptr = LibC.malloc<Int32>().asResource()) {
                if (outlenPtr.value.isNull() || outlen2Ptr.value.isNull()) {
                    throw CryptoException("Failed to allocate memory for decryption.")
                }
                ctx = cipherCtxNew()
                if (ctx.isNull()) {
                    throw CryptoException("Failed to create cipher context for decryption.")
                }
                decryptInit(ctx, this.cipherPtr, keyM.pointer, ivM.pointer)
                if (cipherCtxSetPadding(ctx, paddingMode.paddingType) != 1) {
                    throw CryptoException("Failed to set padding mode for decryption.")
                }
                if (optMode == OperationMode.GCM && aad.size > 0 && (decryptUpdate(ctx, CPointer<Byte>(), // cjlint-ignore !G.EXP.03
                    outlenPtr.value, aadM.pointer, aad.size) != 1)) {
                    throw CryptoException("Failed to update AAD for GCM decryption.")
                }
                var inLen = input.read(readbuff)
                if (optMode == OperationMode.GCM) {
                    var tag = Array<Byte>(tagSize, repeat: 0)
                    var readbuffNext = Array<Byte>(SM4_BUFFER_SIZE, repeat: 0)
                    var inLenNext = input.read(readbuffNext)
                    let decryptedData = ArrayList<Byte>()
                    do {
                        if (inLenNext >= tagSize) {
                            var inBlockDe: CPointerHandle<Byte> = acquireArrayRawData(readbuff)
                            outlenPtr.value.write(0)
                            try {
                                if (decryptUpdate(ctx, outBlock.pointer, outlenPtr.value, inBlockDe.pointer, inLen) != 1) {
                                    throw CryptoException("Decryption update failed.")
                                }
                            } finally {
                                releaseArrayRawData(inBlockDe)
                            }
                            if (outlenPtr.value.read() > 0) {
                                decryptedData.add(all: writebuff[..Int64(outlenPtr.value.read())])
                            }
                        } else {
                            var readbuffTemp = Array<Byte>()
                            readbuffNext = readbuff[(inLen - (tagSize - inLenNext))..inLen].concat(
                                readbuffNext[..inLenNext])
                            readbuffTemp = readbuff[..(inLen - (tagSize - inLenNext))]
                            if (readbuffTemp.size != 0) {
                                outlenPtr.value.write(0)
                                var inBlockTemp: CPointerHandle<Byte> = acquireArrayRawData(readbuffTemp)
                                try {
                                    if (decryptUpdate(ctx, outBlock.pointer, outlenPtr.value, inBlockTemp.pointer,
                                        readbuffTemp.size) != 1) {
                                        throw CryptoException("Decryption update failed.")
                                    }
                                } finally {
                                    releaseArrayRawData(inBlockTemp)
                                }
                                if (outlenPtr.value.read() > 0) {
                                    decryptedData.add(all: writebuff[..Int64(outlenPtr.value.read())])
                                }
                            }
                            tag = readbuffNext.clone()
                            break
                        }
                        readbuff = readbuffNext.clone()
                        inLen = inLenNext
                        inLenNext = input.read(readbuffNext)
                    } while (inLenNext >= 0)
                    var tagM: CPointerHandle<Byte> = acquireArrayRawData(tag)
                    try {
                        // 17 = EVP_CTRL_AEAD_SET_TAG (OpenSSL evp.h)
                        if (cipherCtx(ctx, 17, Int32(tagSize), tagM.pointer) != 1) {
                            throw CryptoException("Failed to set GCM authentication tag.")
                        }
                    } finally {
                        releaseArrayRawData(tagM)
                    }
                    outlen2Ptr.value.write(0)
                    if (decryptFinalEx(ctx, outBlock.pointer, outlen2Ptr.value) != 1) {
                        throw CryptoException("GCM authentication failed: tag verification error.")
                    }
                    if (outlen2Ptr.value.read() > 0) {
                        decryptedData.add(all: writebuff[..Int64(outlen2Ptr.value.read())])
                    }
                    output.write(unsafe { decryptedData.getRawArray()[..decryptedData.size] })
                } else {
                    do {
                        outlenPtr.value.write(0)
                        if (decryptUpdate(ctx, outBlock.pointer, outlenPtr.value, inBlock.pointer, inLen) != 1) {
                            throw CryptoException("Decryption update failed.")
                        }
                        if (outlenPtr.value.read() > 0) {
                            output.write(writebuff[..Int64(outlenPtr.value.read())])
                        }
                        inLen = input.read(readbuff)
                    } while (inLen > 0)
                    outlen2Ptr.value.write(0)
                    if (decryptFinalEx(ctx, outBlock.pointer, outlen2Ptr.value) != 1) {
                        throw CryptoException("Decryption finalization failed.")
                    }
                    if (outlen2Ptr.value.read() > 0) {
                        output.write(writebuff[..Int64(outlen2Ptr.value.read())])
                    }
                }
            } finally {
                releaseArrayRawData(inBlock)
                releaseArrayRawData(outBlock)
                releaseArrayRawData(keyM)
                releaseArrayRawData(ivM)
                releaseArrayRawData(aadM)
                cipherCtxFree(ctx)
            }
        }
    }

    func encryptInit(ctx: CPointer<UInt64>, mType: CPointer<UInt64>, key: CPointer<Byte>, iv: CPointer<Byte>) {
        if (encryptInitEx(ctx, mType, CPointer<UInt64>(), CPointer<Byte>(), CPointer<Byte>()) != 1) {
            throw CryptoException("Encryption initialization failed.")
        }
        if (optMode == OperationMode.GCM) {
            if (cipherCtx(ctx, AEAD_SET_IVLEN, Int32(ivSize), CPointer<Byte>()) != 1) {
                throw CryptoException("Failed to set IV length for GCM encryption.")
            }
        }
        if (encryptInitEx(ctx, CPointer<UInt64>(), CPointer<UInt64>(), key, iv) != 1) {
            throw CryptoException("Encryption initialization failed.")
        }
    }
    func decryptInit(ctx: CPointer<UInt64>, mType: CPointer<UInt64>, key: CPointer<Byte>, iv: CPointer<Byte>) {
        if (decryptInitEx(ctx, mType, CPointer<UInt64>(), CPointer<Byte>(), CPointer<Byte>()) != 1) {
            throw CryptoException("Decryption initialization failed.")
        }
        if (optMode == OperationMode.GCM) {
            if (cipherCtx(ctx, AEAD_SET_IVLEN, Int32(ivSize), CPointer<Byte>()) != 1) {
                throw CryptoException("Failed to set IV length for GCM decryption.")
            }
        }
        if (decryptInitEx(ctx, CPointer<UInt64>(), CPointer<UInt64>(), key, iv) != 1) {
            throw CryptoException("Decryption initialization failed.")
        }
    }
}

foreign func DYN_EVP_CIPHER_CTX_set_padding(ctx: CPointer<UInt64>, padding: Int64, msg: CPointer<DynMsg>): Int32

foreign func DYN_EVP_sm4_cbc(msg: CPointer<DynMsg>): CPointer<UInt64>

foreign func DYN_EVP_sm4_ecb(msg: CPointer<DynMsg>): CPointer<UInt64>

foreign func DYN_EVP_sm4_ctr(msg: CPointer<DynMsg>): CPointer<UInt64>

foreign func DYN_EVP_sm4_ofb(msg: CPointer<DynMsg>): CPointer<UInt64>

foreign func DYN_EVP_sm4_cfb(msg: CPointer<DynMsg>): CPointer<UInt64>

foreign func DYN_EVP_CIPHER_CTX_free(ctx: CPointer<UInt64>, msg: CPointer<DynMsg>): Unit

foreign func DYN_EVP_CIPHER_free(ctx: CPointer<UInt64>, msg: CPointer<DynMsg>): Unit

foreign func DYN_EVP_CIPHER_CTX_new(msg: CPointer<DynMsg>): CPointer<UInt64>

foreign func DYN_EVP_EncryptInit_ex(ctx: CPointer<UInt64>, mType: CPointer<UInt64>, impl: CPointer<UInt64>,
    key: CPointer<Byte>, iv: CPointer<Byte>, msg: CPointer<DynMsg>): Int32

foreign func DYN_EVP_EncryptUpdate(ctx: CPointer<UInt64>, outPut: CPointer<Byte>, outLen: CPointer<Int32>,
    intPut: CPointer<Byte>, intLen: Int64, msg: CPointer<DynMsg>): Int32

foreign func DYN_EVP_EncryptFinal_ex(ctx: CPointer<UInt64>, outPut: CPointer<Byte>, outLen: CPointer<Int32>,
    msg: CPointer<DynMsg>): Int32

foreign func DYN_EVP_DecryptInit_ex(ctx: CPointer<UInt64>, mType: CPointer<UInt64>, impl: CPointer<UInt64>,
    key: CPointer<Byte>, iv: CPointer<Byte>, msg: CPointer<DynMsg>): Int32

foreign func DYN_EVP_DecryptUpdate(ctx: CPointer<UInt64>, outPut: CPointer<Byte>, outLen: CPointer<Int32>,
    intPut: CPointer<Byte>, intLen: Int64, msg: CPointer<DynMsg>): Int32

foreign func DYN_EVP_DecryptFinal_ex(ctx: CPointer<UInt64>, outPut: CPointer<Byte>, outLen: CPointer<Int32>,
    msg: CPointer<DynMsg>): Int32

foreign func DYN_EVP_CIPHER_fetch(ctx: CPointer<UInt64>, algorithm: CString, properties: CPointer<Byte>,
    msg: CPointer<DynMsg>): CPointer<UInt64>

foreign func DYN_EVP_CIPHER_CTX_ctrl(ctx: CPointer<UInt64>, paramsType: Int32, arg: Int32, ptr: CPointer<Byte>,
    msg: CPointer<DynMsg>): Int32

func cipherCtx(ctx: CPointer<UInt64>, paramsType: Int32, arg: Int32, ptr: CPointer<Byte>): Int32 {
    let dynMsgPtr = generateDynMsg()
    let res = unsafe { DYN_EVP_CIPHER_CTX_ctrl(ctx, paramsType, arg, ptr, dynMsgPtr) }
    checkError(dynMsgPtr)
    return res
}

func cipherFetch(ctx: CPointer<UInt64>, algorithm: CString, properties: CPointer<Byte>): CPointer<UInt64> {
    let dynMsgPtr = generateDynMsg()
    let res = unsafe { DYN_EVP_CIPHER_fetch(ctx, algorithm, properties, dynMsgPtr) }
    checkError(dynMsgPtr)
    return res
}

func cipherCtxSetPadding(ctx: CPointer<UInt64>, padding: Int64): Int32 {
    let dynMsgPtr = generateDynMsg()
    let res = unsafe { DYN_EVP_CIPHER_CTX_set_padding(ctx, padding, dynMsgPtr) }
    checkError(dynMsgPtr)
    return res
}

func cipherCtxFree(ctx: CPointer<UInt64>): Unit {
    let dynMsgPtr = generateDynMsg()
    unsafe { DYN_EVP_CIPHER_CTX_free(ctx, dynMsgPtr) }
    checkError(dynMsgPtr)
}

func cipherFree(ctx: CPointer<UInt64>): Unit {
    let dynMsgPtr = generateDynMsg()
    unsafe { DYN_EVP_CIPHER_free(ctx, dynMsgPtr) }
    checkError(dynMsgPtr)
}

func cipherCtxNew(): CPointer<UInt64> {
    let dynMsgPtr = generateDynMsg()
    let res = unsafe { DYN_EVP_CIPHER_CTX_new(dynMsgPtr) }
    checkError(dynMsgPtr)
    return res
}

func encryptInitEx(ctx: CPointer<UInt64>, mType: CPointer<UInt64>, impl: CPointer<UInt64>, key: CPointer<Byte>,
    iv: CPointer<Byte>): Int32 {
    let dynMsgPtr = generateDynMsg()
    let res = unsafe { DYN_EVP_EncryptInit_ex(ctx, mType, impl, key, iv, dynMsgPtr) }
    checkError(dynMsgPtr)
    return res
}

func encryptUpdate(ctx: CPointer<UInt64>, outPut: CPointer<Byte>, outLen: CPointer<Int32>, intPut: CPointer<Byte>,
    intLen: Int64): Int32 {
    let dynMsgPtr = generateDynMsg()
    let res = unsafe { DYN_EVP_EncryptUpdate(ctx, outPut, outLen, intPut, intLen, dynMsgPtr) }
    checkError(dynMsgPtr)
    return res
}

func encryptFinalEx(ctx: CPointer<UInt64>, outPut: CPointer<Byte>, outLen: CPointer<Int32>): Int32 {
    let dynMsgPtr = generateDynMsg()
    let res = unsafe { DYN_EVP_EncryptFinal_ex(ctx, outPut, outLen, dynMsgPtr) }
    checkError(dynMsgPtr)
    return res
}

func decryptInitEx(ctx: CPointer<UInt64>, mType: CPointer<UInt64>, impl: CPointer<UInt64>, key: CPointer<Byte>,
    iv: CPointer<Byte>): Int32 {
    let dynMsgPtr = generateDynMsg()
    let res = unsafe { DYN_EVP_DecryptInit_ex(ctx, mType, impl, key, iv, dynMsgPtr) }
    checkError(dynMsgPtr)
    return res
}

func decryptUpdate(ctx: CPointer<UInt64>, outPut: CPointer<Byte>, outLen: CPointer<Int32>, intPut: CPointer<Byte>,
    intLen: Int64): Int32 {
    let dynMsgPtr = generateDynMsg()
    let res = unsafe { DYN_EVP_DecryptUpdate(ctx, outPut, outLen, intPut, intLen, dynMsgPtr) }
    checkError(dynMsgPtr)
    return res
}

func decryptFinalEx(ctx: CPointer<UInt64>, outPut: CPointer<Byte>, outLen: CPointer<Int32>): Int32 {
    let dynMsgPtr = generateDynMsg()
    let res = unsafe { DYN_EVP_DecryptFinal_ex(ctx, outPut, outLen, dynMsgPtr) }
    checkError(dynMsgPtr)
    return res
}

func generateDynMsg(): CPointer<DynMsg> {
    unsafe {
        let dynMsgPtr = MallocDynMsg()
        if (dynMsgPtr.isNull()) {
            throw CryptoException("Failed to allocate memory.")
        }
        return dynMsgPtr
    }
}

func checkError(dynMsgPtr: CPointer<DynMsg>): Unit {
    unsafe {
        if (dynMsgPtr.isNull()) {
            throw CryptoException("Null pointer encountered.")
        }
        try {
            if (!dynMsgPtr.read().found) {
                let funcName = CString(dynMsgPtr.read().funcName).toString()
                throw CryptoException("Cannot load OpenSSL library or function '${funcName}'.")
            }
        } finally {
            FreeDynMsg(dynMsgPtr)
        }
    }
}
