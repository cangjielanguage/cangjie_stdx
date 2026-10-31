/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.crypto.keys

import std.crypto.digest.Digest
import std.io.*
import std.math.numeric.BigInt
import std.sync.AtomicReference
import stdx.crypto.digest.*
import stdx.crypto.common.*

public enum PadOption {
    OAEP(OAEPOption) | PSS(PSSOption) | PKCS1
}

public struct OAEPOption {
    let label: String
    let hash: Digest
    let mgfHash: Digest

    public init(hash: Digest, mgfHash: Digest, label!: String = "") {
        this.label = label
        this.hash = hash
        this.mgfHash = mgfHash
    }
}

public struct PSSOption {
    let saltLen: Int32
    public init(saltLen: Int32) {
        if (saltLen < 0) {
            throw CryptoException("Salt length cannot be negative.")
        }
        this.saltLen = saltLen
    }
}

const RSA_MIN_MODULUS_BITS: Int32 = 512
const RSA_MAX_MODULUS_BITS: Int32 = 16384
let RSA_MIN_EXPONENT = BigInt(3)
let RSA_MAX_EXPONENT = BigInt(true, Array<Byte>(32, repeat: 255))

public class RSAPrivateKey <: PrivateKey {
    var pkey = CPointer<UInt64>()
    var evpKeyCtx: EVPKEYCTX = unsafe { zeroValue<EVPKEYCTX>() } // redundant member, kept for ABI compatibility, concurrent reuse causes crash

    init(blob: DerBlob) {
        pkey = loadPrivateKey(RSA_id, blob.body)
        if (pkey.isNull()) {
            throw CryptoException("Failed to load RSA private key from DER.")
        }
    }

    public init(bits: Int32) {
        checkBits(bits)
        pkey = unsafe { generateRSA(bits, BigInt.parse("65537")) }
        if (pkey.isNull()) {
            throw CryptoException("Failed to generate RSA private key.")
        }
    }

    public init(bits: Int32, e: BigInt) {
        checkBits(bits)
        checkPublicExponent(e)
        pkey = unsafe { generateRSA(bits, e) }
        if (pkey.isNull()) {
            throw CryptoException("Failed to generate RSA private key.")
        }
    }

    public func encodeToDer(password!: ?String): DerBlob {
        var blob: DerBlob = encodeToDer()
        match (password) {
            case Some(password) => try {
                var key = GeneralPrivateKey.decodeDer(blob)
                key.encodeToDer(password: password)
            } catch (e: CryptoException) {
                throw CryptoException(e.message)
            }
            case None => blob
        }
    }

    public func encodeToDer(): DerBlob {
        var content = getPrivateKeyDer(pkey)
        keepAlive(this)
        DerBlob(content)
    }

    public func encodeToPem(): PemEntry {
        PemEntry(PemEntry.LABEL_RSA_PRIVATE_KEY, encodeToDer())
    }

    /**
     * Encode the key to PemEntry optionally doing encryption using the specified password if any
     * If the passord is None, then the key will be encoded unencrypted.
     * An encrypted key produced by this function is always in PKCS8 format.
     * @throws CryptoException if failed to encode/encrypt or the provided password is empty
     */
    public func encodeToPem(password!: ?String): PemEntry {
        match (password) {
            case Some(password) => PemEntry(PemEntry.LABEL_ENCRYPTED_PRIVATE_KEY, encodeToDer(password: password))
            case None => encodeToPem()
        }
    }

    public static func decodeDer(blob: DerBlob): RSAPrivateKey {
        RSAPrivateKey(blob)
    }

    public static func decodeDer(blob: DerBlob, password!: ?String): RSAPrivateKey {
        match (password) {
            case Some(password) => try {
                var priKey = GeneralPrivateKey.decodeDer(blob, password: password)
                RSAPrivateKey(priKey.encodeToDer())
            } catch (e: CryptoException) {
                throw CryptoException(e.message)
            }
            case None => RSAPrivateKey(blob)
        }
    }

    public static func decodeFromPem(text: String): RSAPrivateKey {
        decodeFromPem(text, password: None)
    }

    public static func decodeFromPem(
        text: String,
        password!: ?String
    ): RSAPrivateKey {
        try {
            var priKey = GeneralPrivateKey.decodeFromPem(text, password: password)
            RSAPrivateKey(priKey.encodeToDer())
        } catch (e: CryptoException) {
            throw CryptoException(e.message)
        }
    }

    public func sign(hash: Digest, digest: Array<Byte>, padType!: PadOption): Array<Byte> {
        let ctx = EVPKEYCTX(pkey)
        let result = match (padType) {
            case PKCS1 => signPKCS1(ctx, pkey, hash, digest)
            case PSS(pss) => signPSS(ctx, pkey, hash, digest, pss.saltLen)
            case OAEP(_) => throw CryptoException("OAEPOption is only applicable to encryption or decryption operations.")
        }
        keepAlive(this)
        result
    }

    public func decrypt(input: InputStream, output: OutputStream, padType!: PadOption): Unit {
        let ctx = EVPKEYCTX(pkey)
        match (padType) {
            case PKCS1 => unsafe { decryptPKCS1(ctx, pkey, input, output) }
            case OAEP(oaep) => unsafe { decryptOAEP(ctx, pkey, input, output, oaep.label, oaep.hash, oaep.mgfHash) }
            case PSS(_) => throw CryptoException("PSSOption is only applicable to signing or verification operations.")
        }
        keepAlive(this)
    }

    public override func toString(): String {
        "RSA PRIVATE KEY"
    }

    ~init() {
        if (!pkey.isNull()) {
            keyFree(pkey)
        }
    }
}

public class RSAPublicKey <: PublicKey {
    var pkey: CPointer<UInt64>
    var evpKeyCtx: EVPKEYCTX = unsafe { zeroValue<EVPKEYCTX>() } // redundant member, kept for ABI compatibility, concurrent reuse causes crash

    init(blob: DerBlob) {
        pkey = loadPublicKey(RSA_id, blob.body)
        if (pkey.isNull()) {
            throw CryptoException("Failed to initialize RSA public key.")
        }
    }

    public init(pri: RSAPrivateKey) {
        var content = getPublicKeyDer(pri.pkey)
        keepAlive(pri)
        pkey = loadPublicKey(RSA_id, content)
        if (pkey.isNull()) {
            throw CryptoException("Failed to initialize RSA public key.")
        }
    }

    public func encodeToDer(): DerBlob {
        var content = getPublicKeyDer(pkey)
        keepAlive(this)
        DerBlob(content)
    }
    public func encodeToPem(): PemEntry {
        PemEntry(PemEntry.LABEL_PUBLIC_KEY, encodeToDer())
    }

    public static func decodeDer(blob: DerBlob): RSAPublicKey {
        RSAPublicKey(blob)
    }

    public static func decodeFromPem(text: String): RSAPublicKey {
        try {
            var pubKey = GeneralPublicKey.decodeFromPem(text)
            RSAPublicKey(pubKey.encodeToDer())
        } catch (e: CryptoException | CryptoException) {
            throw CryptoException(e.message)
        }
    }

    public func verify(hash: Digest, digest: Array<Byte>, sig: Array<Byte>, padType!: PadOption): Bool {
        let ctx = EVPKEYCTX(pkey)
        let result = match (padType) {
            case PKCS1 => verifyPKCS1(ctx, hash, digest, sig)
            case PSS(pss) => verifyPSS(ctx, hash, digest, sig, pss.saltLen)
            case OAEP(_) => throw CryptoException("OAEPOption is only applicable to encryption or decryption operations.")
        }
        keepAlive(this)
        result
    }

    public func encrypt(input: InputStream, output: OutputStream, padType!: PadOption): Unit {
        let ctx = EVPKEYCTX(pkey)
        match (padType) {
            case PKCS1 => unsafe { encryptPKCS1(ctx, pkey, input, output) }
            case OAEP(oaep) => unsafe { encryptOAEP(ctx, pkey, input, output, oaep.label, oaep.hash, oaep.mgfHash) }
            case PSS(_) => throw CryptoException("PSSOption is only applicable to signing or verification operations.")
        }
        keepAlive(this)
    }

    public override func toString(): String {
        "RSA PUBLIC KEY"
    }

    ~init() {
        if (!pkey.isNull()) {
            keyFree(pkey)
        }
    }
}

func checkBits(bits: Int32) {
    if (bits < RSA_MIN_MODULUS_BITS) {
        throw CryptoException("Key size is too small: '${bits}' bits, minimum is '${RSA_MIN_MODULUS_BITS}' bits.")
    }
    if (bits > RSA_MAX_MODULUS_BITS) {
        throw CryptoException("Key size is too large: '${bits}' bits, maximum is '${RSA_MAX_MODULUS_BITS}' bits.")
    }
}

func checkPublicExponent(e: BigInt) {
    let lastBit = e & BigInt(1)
    if (lastBit == BigInt(0)) {
        throw CryptoException("Invalid public exponent '${e}': must be odd.")
    }
    if (e < RSA_MIN_EXPONENT) {
        throw CryptoException("Invalid public exponent '${e}': expected at least '${RSA_MIN_EXPONENT}'.")
    }
    if (e > RSA_MAX_EXPONENT) {
        throw CryptoException("Invalid public exponent '${e}': expected at most '${RSA_MAX_EXPONENT}'.")
    }
}

unsafe func generateRSA(bits: Int32, e: BigInt) {
    let engine = CPointer<UInt64>()
    var pkey = CPointer<UInt64>()
    var exp = CPointer<BIGNUM>()
    var ctx = keyCtxNewId(RSA_id, engine)
    if (ctx.isNull()) {
        throw CryptoException("Failed to initialize RSA private key.")
    }
    let binPtr: CPointerHandle<Byte> = acquireArrayRawData(e.toBytes())
    try (ppkey = LibC.malloc<CPointer<UInt64>>().asResource()) {
        if (ppkey.value.isNull()) {
            throw CryptoException("Failed to initialize RSA private key: failed to allocate memory.")
        }

        var ret = keygenInit(ctx)
        if (ret != 1) {
            throw CryptoException("Failed to initialize RSA private key.")
        }
        ret = setRSABits(ctx, bits)
        if (ret != 1) {
            throw CryptoException("Failed to set RSA key bits.")
        }
        exp = bin2bn(binPtr.pointer, Int32(e.toBytes().size), exp)
        if (exp.isNull()) {
            throw CryptoException("Failed to set RSA public exponent.")
        }
        ret = setRSAPubExp(ctx, exp)
        if (ret != 1) {
            throw CryptoException("Failed to set RSA public exponent.")
        }
        ppkey.value.write(pkey)
        ret = keyGenerate(ctx, ppkey.value)
        if (ret != 1) {
            throw CryptoException("Failed to generate RSA private key.")
        }
        pkey = ppkey.value.read()
    } finally {
        bnFree(exp)
        keyCtxFree(ctx)
        releaseArrayRawData(binPtr)
    }
    pkey
}

func getPrivateKeyDer(pkey: CPointer<UInt64>) {
    unsafe {
        var keySize = getSize(pkey)
        var readBuf = Array<Byte>(Int64(keySize * 8), repeat: 0)
        let read: CPointerHandle<Byte> = acquireArrayRawData(readBuf)
        var readLen: Int32
        var readPtr = LibC.malloc<CPointer<Byte>>()
        if (readPtr.isNull()) {
            releaseArrayRawData(read)
            throw CryptoException("Failed to initialize private key.")
        }
        readPtr.write(read.pointer)
        try {
            readLen = privateKey2d(pkey, readPtr)
            if (readLen < 0 || Int64(readLen) > readBuf.size) {
                throw CryptoException("Failed to load private key.")
            }
        } finally {
            LibC.free(readPtr)
            releaseArrayRawData(read)
        }
        readBuf[0..Int64(readLen)]
    }
}

func getPublicKeyDer(pkey: CPointer<UInt64>) {
    unsafe {
        var keySize = getSize(pkey)
        var readBuf = Array<Byte>(Int64(keySize * 2), repeat: 0)
        let read: CPointerHandle<Byte> = acquireArrayRawData(readBuf)
        var readLen: Int32
        var readPtr = LibC.malloc<CPointer<Byte>>()
        if (readPtr.isNull()) {
            releaseArrayRawData(read)
            throw CryptoException("Failed to initialize public key.")
        }
        readPtr.write(read.pointer)
        try {
            readLen = pubKey2d(pkey, readPtr)
            if (readLen < 0 || Int64(readLen) > readBuf.size) {
                throw CryptoException("Failed to load public key.")
            }
        } finally {
            LibC.free(readPtr)
            releaseArrayRawData(read)
        }
        readBuf[0..Int64(readLen)]
    }
}

func loadPrivateKey(id: Int32, der: Array<Byte>) {
    unsafe {
        let derHandle: CPointerHandle<Byte> = acquireArrayRawData(der)
        var pkey = CPointer<UInt64>()
        var ppkey = CPointer<CPointer<UInt64>>()
        var readPtr = LibC.malloc<CPointer<Byte>>()
        if (readPtr.isNull()) {
            releaseArrayRawData(derHandle)
            throw CryptoException("Failed to initialize private key.")
        }
        readPtr.write(derHandle.pointer)
        try {
            pkey = d2PrivateKey(id, ppkey, readPtr, der.size)
            if (pkey.isNull()) {
                throw CryptoException("Failed to load private key.")
            }
            if (readPtr.read().toUIntNative() != derHandle.pointer.toUIntNative() + UIntNative(der.size)) {
                keyFree(pkey)
                throw CryptoException("Failed to load private key.")
            }
            if (!keyTypeCheck(id, pkey)) {
                keyFree(pkey)
                throw CryptoException("Private key type mismatch.")
            }
        } finally {
            LibC.free(readPtr)
            releaseArrayRawData(derHandle)
        }
        pkey
    }
}

func loadPublicKey(id: Int32, der: Array<Byte>) {
    unsafe {
        let derHandle: CPointerHandle<Byte> = acquireArrayRawData(der)
        var pkey = CPointer<UInt64>()
        var ppkey = CPointer<CPointer<UInt64>>()
        var readPtr = LibC.malloc<CPointer<Byte>>()
        if (readPtr.isNull()) {
            releaseArrayRawData(derHandle)
            throw CryptoException("Failed to initialize public key.")
        }
        readPtr.write(derHandle.pointer)
        try {
            pkey = d2Pubkey(ppkey, readPtr, der.size)
            if (pkey.isNull()) {
                throw CryptoException("Failed to load public key.")
            }
            if (readPtr.read().toUIntNative() != derHandle.pointer.toUIntNative() + UIntNative(der.size)) {
                keyFree(pkey)
                throw CryptoException("Failed to load public key.")
            }
            if (!keyTypeCheck(id, pkey)) {
                keyFree(pkey)
                throw CryptoException("Public key type mismatch.")
            }
        } finally {
            LibC.free(readPtr)
            releaseArrayRawData(derHandle)
        }
        return pkey
    }
}

func keyTypeCheck(id: Int32, pkey: CPointer<UInt64>) {
    let pkeyId = getPkeyId(pkey)
    if (id == pkeyId) {
        return true
    }
    // if id is sm2 and getPkeyId return -1(find Provider Key failed) need check name again
    if (pkeyId == -1 && id == NID_sm2) {
        if (pkeyIs(pkey, "SM2")) { // SM2 is type name
            return true
        }
    }
    false
}

func getDigest(hash: Digest) {
    var md = match (hash) {
        case _: MD5 => md5()
        case _: SHA1 => sha1()
        case _: SHA224 => sha224()
        case _: SHA256 => sha256()
        case _: SHA384 => sha384()
        case _: SHA512 => sha512()
        case _: SM3 => sm3()
        case _ => throw CryptoException("Unsupported digest type.")
    }
    return md
}

func signWithPadding(
    ctx: EVPKEYCTX,
    pkey: CPointer<UInt64>,
    hash: Digest,
    data: Array<Byte>,
    padding: Int32,
    saltLen: ?Int32
) {
    unsafe {
        var rsaSize = Int64(getSize(pkey))
        var sig: Array<UInt8> = Array<UInt8>(rsaSize, repeat: 0)
        let sigHandle: CPointerHandle<Byte> = acquireArrayRawData(sig)
        let dataHandle: CPointerHandle<Byte> = acquireArrayRawData(data)
        try (sizePtr = LibC.malloc<UIntNative>().asResource()) {
            if (sizePtr.value.isNull()) {
                throw CryptoException("Failed to initialize signing: failed to allocate memory.")
            }

            sizePtr.value.write(UIntNative(rsaSize))
            if (signInit(ctx.ptr) <= 0) {
                throw CryptoException("Failed to initialize signing.")
            }

            if (setRSAPadding(ctx.ptr, padding) <= 0) {
                throw CryptoException("Failed to set RSA padding.")
            }

            if (setSignatureMD(ctx.ptr, getDigest(hash)) <= 0) {
                throw CryptoException("Failed to set signature digest algorithm.")
            }

            if (let Some(len) <- saltLen) {
                if (setRSAPssSaltLen(ctx.ptr, len) <= 0) {
                    throw CryptoException("Failed to set RSA PSS salt length.")
                }
            }

            let ret = sign(ctx.ptr, sigHandle.pointer, sizePtr.value, dataHandle.pointer, UIntNative(data.size))
            if (ret != 1 || sizePtr.value.read() > UIntNative(rsaSize)) {
                throw CryptoException("Failed to sign data.")
            }
            rsaSize = Int64(sizePtr.value.read())
        } finally {
            releaseArrayRawData(sigHandle)
            releaseArrayRawData(dataHandle)
        }
        sig[0..rsaSize]
    }
}

func signPKCS1(ctx: EVPKEYCTX, pkey: CPointer<UInt64>, hash: Digest, data: Array<Byte>) {
    signWithPadding(ctx, pkey, hash, data, RSA_PKCS1_PADDING, None<Int32>)
}

func signPSS(ctx: EVPKEYCTX, pkey: CPointer<UInt64>, hash: Digest, data: Array<Byte>, saltLen: Int32) {
    signWithPadding(ctx, pkey, hash, data, RSA_PKCS1_PSS_PADDING, Some(saltLen))
}

func verifyWithPadding(
    ctx: EVPKEYCTX,
    hash: Digest,
    data: Array<Byte>,
    sig: Array<Byte>,
    padding: Int32,
    saltLen: ?Int32
) {
    unsafe {
        let sigHandle: CPointerHandle<Byte> = acquireArrayRawData(sig)
        let dataHandle: CPointerHandle<Byte> = acquireArrayRawData(data)
        var result: Int32 = 0
        try {
            var ret = verifyInit(ctx.ptr)
            if (ret <= 0) {
                throw CryptoException("Failed to initialize verification.")
            }
            ret = setRSAPadding(ctx.ptr, padding)
            if (ret <= 0) {
                throw CryptoException("Failed to set RSA padding.")
            }
            ret = setSignatureMD(ctx.ptr, getDigest(hash))
            if (ret <= 0) {
                throw CryptoException("Failed to set signature digest algorithm.")
            }
            if (let Some(len) <- saltLen) {
                ret = setRSAPssSaltLen(ctx.ptr, len)
                if (ret <= 0) {
                    throw CryptoException("Failed to set RSA PSS salt length.")
                }
            }
            result = verify(ctx.ptr, sigHandle.pointer, UIntNative(sig.size), dataHandle.pointer, UIntNative(data.size))
        } finally {
            releaseArrayRawData(sigHandle)
            releaseArrayRawData(dataHandle)
        }
        if (result != 1) {
            return false
        } else {
            return true
        }
    }
}

func verifyPKCS1(ctx: EVPKEYCTX, hash: Digest, data: Array<Byte>, sig: Array<Byte>) {
    verifyWithPadding(ctx, hash, data, sig, RSA_PKCS1_PADDING, None<Int32>)
}

func verifyPSS(
    ctx: EVPKEYCTX,
    hash: Digest,
    data: Array<Byte>,
    sig: Array<Byte>,
    saltLen: Int32
) {
    verifyWithPadding(ctx, hash, data, sig, RSA_PKCS1_PSS_PADDING, Some(saltLen))
}

unsafe func encryptPKCS1(ctx: EVPKEYCTX, pkey: CPointer<UInt64>, input: InputStream, output: OutputStream) {
    var keySize = getSize(pkey)
    var blockSize = Int64(keySize - PKCS1_PADDING_SIZE)
    if (blockSize < 0) {
        throw CryptoException("Invalid block size: '${blockSize}'.")
    }
    var readbuff = Array<Byte>(blockSize, repeat: 0)
    var writebuff = Array<Byte>(Int64(keySize), repeat: 0)
    var inBlock: CPointerHandle<Byte> = acquireArrayRawData(readbuff)
    var outBlock: CPointerHandle<Byte> = acquireArrayRawData(writebuff)
    try (outlenPtr = LibC.malloc<UIntNative>().asResource()) {
        if (outlenPtr.value.isNull()) {
            throw CryptoException("Failed to initialize encryption: failed to allocate memory.")
        }

        if (encryInit(ctx.ptr) <= 0) {
            throw CryptoException("Failed to initialize encryption.")
        }

        if (setRSAPadding(ctx.ptr, RSA_PKCS1_PADDING) <= 0) {
            throw CryptoException("Failed to set RSA padding type.")
        }

        var inLength = UIntNative(input.read(readbuff))
        do {
            outlenPtr.value.write(UIntNative(keySize))
            let ret = encrypt(ctx.ptr, outBlock.pointer, outlenPtr.value, inBlock.pointer, inLength)
            if (ret != 1 || outlenPtr.value.read() > UIntNative(keySize)) {
                throw CryptoException("Failed to encrypt data.")
            }
            output.write(writebuff[..Int64(outlenPtr.value.read())])
            inLength = UIntNative(input.read(readbuff))
        } while (inLength > 0)
    } finally {
        releaseArrayRawData(inBlock)
        releaseArrayRawData(outBlock)
    }
}

unsafe func encryptOAEP(
    ctx: EVPKEYCTX,
    pkey: CPointer<UInt64>,
    input: InputStream,
    output: OutputStream,
    label: String,
    hash: Digest,
    mgfHash: Digest
) {
    var keySize = getSize(pkey)
    var blockSize = Int64(keySize) - 2 * hash.size - 2
    if (blockSize < 0) {
        throw CryptoException("RSA key size is smaller than (2 * hash size - 2).")
    }
    var readbuff = Array<Byte>(blockSize, repeat: 0)
    var writebuff = Array<Byte>(Int64(keySize), repeat: 0)
    var inBlock: CPointerHandle<Byte> = acquireArrayRawData(readbuff)
    var outBlock: CPointerHandle<Byte> = acquireArrayRawData(writebuff)
    try (outlenPtr = LibC.malloc<UIntNative>().asResource(), lablePtr = LibC.mallocCString(label).asResource()) {
        if (outlenPtr.value.isNull() || lablePtr.value.isNull()) {
            throw CryptoException("Failed to initialize encryption: failed to allocate memory.")
        }

        if (encryInit(ctx.ptr) <= 0) {
            throw CryptoException("Failed to initialize encryption.")
        }

        if (setRSAPadding(ctx.ptr, RSA_PKCS1_OAEP_PADDING) <= 0) {
            throw CryptoException("Failed to set RSA padding type.")
        }

        var ret = keysOAEPSetting(ctx.ptr, lablePtr.value, label.size, getDigest(hash), getDigest(mgfHash))
        if (ret == -1) {
            throw CryptoException("Failed to set RSA OAEP options.")
        }
        var inLen = UIntNative(input.read(readbuff))
        do {
            outlenPtr.value.write(UIntNative(keySize))
            ret = encrypt(ctx.ptr, outBlock.pointer, outlenPtr.value, inBlock.pointer, inLen)
            if (ret != 1 || outlenPtr.value.read() > UIntNative(keySize)) {
                throw CryptoException("Failed to encrypt data.")
            }
            output.write(writebuff[..Int64(outlenPtr.value.read())])
            inLen = UIntNative(input.read(readbuff))
        } while (inLen > 0)
    } finally {
        releaseArrayRawData(inBlock)
        releaseArrayRawData(outBlock)
    }
}

unsafe func decryptPKCS1(ctx: EVPKEYCTX, pkey: CPointer<UInt64>, input: InputStream, output: OutputStream) {
    var keySize = getSize(pkey)
    var blockSize = Int64(keySize)
    var readbuff = Array<Byte>(blockSize, repeat: 0)
    var writebuff = Array<Byte>(Int64(keySize), repeat: 0)
    var inBlock: CPointerHandle<Byte> = acquireArrayRawData(readbuff)
    var outBlock: CPointerHandle<Byte> = acquireArrayRawData(writebuff)
    try (outlenPtr = LibC.malloc<UIntNative>().asResource()) {
        if (outlenPtr.value.isNull()) {
            throw CryptoException("Failed to initialize decryption: failed to allocate memory.")
        }

        if (decryptInit(ctx.ptr) <= 0) {
            throw CryptoException("Failed to initialize decryption.")
        }

        if (setRSAPadding(ctx.ptr, RSA_PKCS1_PADDING) <= 0) {
            throw CryptoException("Failed to set RSA padding.")
        }

        var inLen = UIntNative(input.read(readbuff))
        while (inLen > 0) {
            outlenPtr.value.write(UIntNative(keySize))
            let ret = decrypt(ctx.ptr, outBlock.pointer, outlenPtr.value, inBlock.pointer, inLen)
            if (ret != 1 || outlenPtr.value.read() > UIntNative(keySize)) {
                throw CryptoException("Failed to decrypt data.")
            }
            output.write(writebuff[..Int64(outlenPtr.value.read())])
            inLen = UIntNative(input.read(readbuff))
        }
    } finally {
        releaseArrayRawData(outBlock)
        releaseArrayRawData(inBlock)
    }
}

unsafe func decryptOAEP(
    ctx: EVPKEYCTX,
    pkey: CPointer<UInt64>,
    input: InputStream,
    output: OutputStream,
    label: String,
    hash: Digest,
    mgfHash: Digest
) {
    var keySize = getSize(pkey)
    var blockSize = Int64(keySize)
    var readbuff = Array<Byte>(blockSize, repeat: 0)
    var writebuff = Array<Byte>(Int64(keySize), repeat: 0)
    var inBlock: CPointerHandle<Byte> = acquireArrayRawData(readbuff)
    var outBlock: CPointerHandle<Byte> = acquireArrayRawData(writebuff)
    try (outlenPtr = LibC.malloc<UIntNative>().asResource(), lablePtr = LibC.mallocCString(label).asResource()) {
        if (outlenPtr.value.isNull() || lablePtr.value.isNull()) {
            throw CryptoException("Failed to initialize decryption: failed to allocate memory.")
        }

        var ret = decryptInit(ctx.ptr)
        if (ret <= 0) {
            throw CryptoException("Failed to initialize decryption.")
        }
        ret = setRSAPadding(ctx.ptr, RSA_PKCS1_OAEP_PADDING)
        if (ret <= 0) {
            throw CryptoException("Failed to set RSA padding type.")
        }
        ret = keysOAEPSetting(ctx.ptr, lablePtr.value, label.size, getDigest(hash), getDigest(mgfHash))
        if (ret == -1) {
            throw CryptoException("Failed to set RSA OAEP options.")
        }
        var inLen = UIntNative(input.read(readbuff))
        while (inLen > 0) {
            outlenPtr.value.write(UIntNative(keySize))
            ret = decrypt(ctx.ptr, outBlock.pointer, outlenPtr.value, inBlock.pointer, inLen)
            if (ret != 1 || outlenPtr.value.read() > UIntNative(keySize)) {
                throw CryptoException("Failed to decrypt data.")
            }
            output.write(writebuff[..Int64(outlenPtr.value.read())])
            inLen = UIntNative(input.read(readbuff))
        }
    } finally {
        releaseArrayRawData(inBlock)
        releaseArrayRawData(outBlock)
    }
}

let _privateKeyRsaPhantom = Object()
let _rsaPrivateKey = AtomicReference<Object>(_privateKeyRsaPhantom)

func keepAlive(o: RSAPrivateKey) {
    _rsaPrivateKey.store(o)
    _rsaPrivateKey.store(_privateKeyRsaPhantom)
}

let _publicKeyRsaPhantom = Object()
let _rsaPublicKey = AtomicReference<Object>(_publicKeyRsaPhantom)

func keepAlive(o: RSAPublicKey) {
    _rsaPublicKey.store(o)
    _rsaPublicKey.store(_publicKeyRsaPhantom)
}
