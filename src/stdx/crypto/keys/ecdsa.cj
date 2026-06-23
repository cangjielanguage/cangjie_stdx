/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.crypto.keys

import std.sync.AtomicReference
import stdx.crypto.digest.*
import stdx.crypto.common.*

public enum Curve {
    P224 | P256 | P384 | P521 | BP256 | BP320 | BP384 | BP512

    func getNum() {
        match (this) {
            case P224 => NID_secp224r1
            case P256 => NID_X9_62_prime256v1
            case P384 => NID_secp384r1
            case P521 => NID_secp521r1
            case BP256 => NID_brainpoolP256r1
            case BP320 => NID_brainpoolP320r1
            case BP384 => NID_brainpoolP384r1
            case BP512 => NID_brainpoolP512r1
        }
    }
}

public class ECDSAPrivateKey <: PrivateKey {
    var pkey = CPointer<UInt64>()
    var evpKeyCtx: EVPKEYCTX

    init(blob: DerBlob) {
        pkey = loadPrivateKey(EC_id, blob.body)
        if (pkey.isNull()) {
            throw CryptoException("Init ECDSA PrivateKey failed.")
        }
        evpKeyCtx = EVPKEYCTX(pkey)
    }

    public init(curve: Curve) {
        pkey = unsafe { generateECDSA(curve) }
        if (pkey.isNull()) {
            throw CryptoException("Init ECDSA PrivateKey failed.")
        }
        evpKeyCtx = EVPKEYCTX(pkey)
    }

    public func encodeToDer(): DerBlob {
        var content = getPrivateKeyDer(pkey)
        keepAlive(this)
        DerBlob(content)
    }

    public func encodeToDer(password!: ?String): DerBlob {
        var blob: DerBlob = encodeToDer()
        return match (password) {
            case Some(password) => try {
                var key = GeneralPrivateKey.decodeDer(blob)
                key.encodeToDer(password: password) // route to GeneralPrivateKey::encodeToDer
            } catch (e: CryptoException) {
                throw CryptoException(e.message)
            }
            case None => blob
        }
    }

    public func encodeToPem(): PemEntry {
        PemEntry(PemEntry.LABEL_EC_PRIVATE_KEY, encodeToDer())
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

    public static func decodeDer(blob: DerBlob): ECDSAPrivateKey {
        ECDSAPrivateKey(blob)
    }

    public static func decodeDer(blob: DerBlob, password!: ?String): ECDSAPrivateKey {
        match (password) {
            case Some(password) => try {
                var priKey = GeneralPrivateKey.decodeDer(blob, password: password)
                ECDSAPrivateKey(priKey.encodeToDer())
            } catch (e: CryptoException) {
                throw CryptoException(e.message)
            }
            case None => ECDSAPrivateKey(blob)
        }
    }
    public static func decodeFromPem(text: String): ECDSAPrivateKey {
        decodeFromPem(text, password: None)
    }

    public static func decodeFromPem(
        text: String,
        password!: ?String
    ): ECDSAPrivateKey {
        try {
            var priKey = GeneralPrivateKey.decodeFromPem(text, password: password)
            ECDSAPrivateKey(priKey.encodeToDer())
        } catch (e: CryptoException) {
            throw CryptoException(e.message)
        }
    }

    public func sign(digest: Array<Byte>): Array<Byte> {
        keepAlive(this)
        sign(evpKeyCtx, pkey, digest)
    }

    public override func toString(): String {
        "ECDSA PRIVATE KEY"
    }

    ~init() {
        if (!pkey.isNull()) {
            keyFree(pkey)
        }
    }
}

public class ECDSAPublicKey <: PublicKey {
    var pkey: CPointer<UInt64>
    var evpKeyCtx: EVPKEYCTX

    init(blob: DerBlob) {
        pkey = loadPublicKey(EC_id, blob.body)
        if (pkey.isNull()) {
            throw CryptoException("Init ECDSA PublicKey failed.")
        }
        evpKeyCtx = EVPKEYCTX(pkey)
    }

    public init(pri: ECDSAPrivateKey) {
        var content = getPublicKeyDer(pri.pkey)
        pkey = loadPublicKey(EC_id, content)
        if (pkey.isNull()) {
            throw CryptoException("Init ECDSA PublicKey failed.")
        }
        evpKeyCtx = EVPKEYCTX(pkey)
    }

    public func encodeToDer(): DerBlob {
        var content = getPublicKeyDer(pkey)
        keepAlive(this)
        DerBlob(content)
    }

    public static func decodeDer(blob: DerBlob): ECDSAPublicKey {
        ECDSAPublicKey(blob)
    }

    public static func decodeFromPem(text: String): ECDSAPublicKey {
        var pubKey = GeneralPublicKey.decodeFromPem(text)
        ECDSAPublicKey(pubKey.encodeToDer())
    }

    public func encodeToPem(): PemEntry {
        PemEntry(PemEntry.LABEL_PUBLIC_KEY, encodeToDer())
    }

    public func verify(digest: Array<Byte>, sig: Array<Byte>): Bool {
        verify(evpKeyCtx, digest, sig)
    }

    public override func toString(): String {
        "ECDSA PUBLIC KEY"
    }

    ~init() {
        if (!pkey.isNull()) {
            keyFree(pkey)
        }
    }
}

unsafe func generateECDSA(curve: Curve) {
    let e = CPointer<UInt64>()
    var pkey = CPointer<UInt64>()
    try (ppkey = LibC.malloc<CPointer<UInt64>>().asResource()) {
        if (ppkey.value.isNull()) {
            throw CryptoException("Init ECDSA PrivateKey failed, malloc failed.")
        }

        var ctx = keyCtxNewId(EC_id, e)
        if (ctx.isNull()) {
            throw CryptoException("Init ECDSA PrivateKey failed.")
        }
        try {
            var ret = keygenInit(ctx)
            if (ret != 1) {
                throw CryptoException("Init ECDSA PrivateKey failed.")
            }
            ret = setCurveNid(ctx, curve.getNum())
            if (ret != 1) {
                throw CryptoException("Set ECDSA curve type error.")
            }
            ppkey.value.write(pkey)
            ret = keyGenerate(ctx, ppkey.value)
            if (ret != 1) {
                throw CryptoException("Generate ECDSA PrivateKey failed.")
            }
            pkey = ppkey.value.read()
        } finally {
            keyCtxFree(ctx)
        }
    }
    pkey
}

func sign(ctx: EVPKEYCTX, pkey: CPointer<UInt64>, data: Array<Byte>) {
    unsafe {
        var ecSize = Int64(getSize(pkey))
        var sig: Array<UInt8> = Array<UInt8>(ecSize, repeat: 0)
        let sigHandle: CPointerHandle<Byte> = acquireArrayRawData(sig)
        let dataHandle: CPointerHandle<Byte> = acquireArrayRawData(data)
        try (sizePtr = LibC.malloc<UIntNative>().asResource()) {
            if (sizePtr.value.isNull()) {
                throw CryptoException("Sign init error, malloc failed.")
            }

            sizePtr.value.write(UIntNative(ecSize))
            var ret = signInit(ctx.ptr)
            if (ret <= 0) {
                throw CryptoException("Sign init error.")
            }
            ret = sign(ctx.ptr, sigHandle.pointer, sizePtr.value, dataHandle.pointer, UIntNative(data.size))
            if (ret != 1 || ecSize < Int64(sizePtr.value.read())) {
                throw CryptoException("Sign error.")
            }
            ecSize = Int64(sizePtr.value.read())
        } finally {
            releaseArrayRawData(sigHandle)
            releaseArrayRawData(dataHandle)
        }
        sig[0..ecSize]
    }
}

func verify(ctx: EVPKEYCTX, data: Array<Byte>, sig: Array<Byte>) {
    unsafe {
        let sigHandle: CPointerHandle<Byte> = acquireArrayRawData(sig)
        let dataHandle: CPointerHandle<Byte> = acquireArrayRawData(data)
        var result: Int32 = 0
        try {
            var ret = verifyInit(ctx.ptr)
            if (ret <= 0) {
                throw CryptoException("Verify init error.")
            }
            result = verify(ctx.ptr, sigHandle.pointer, UIntNative(sig.size), dataHandle.pointer, UIntNative(data.size))
        } finally {
            releaseArrayRawData(dataHandle)
            releaseArrayRawData(sigHandle)
        }
        if (result != 1) {
            return false
        } else {
            return true
        }
    }
}

let _privateKeyPhantom = Object()
let _ecdsaPrivateKey = AtomicReference<Object>(_privateKeyPhantom)

func keepAlive(o: ECDSAPrivateKey) {
    _ecdsaPrivateKey.store(o)
    _ecdsaPrivateKey.store(_privateKeyPhantom)
}

let _publicKeyPhantom = Object()
let _ecdsaPublicKey = AtomicReference<Object>(_publicKeyPhantom)

func keepAlive(o: ECDSAPublicKey) {
    _ecdsaPublicKey.store(o)
    _ecdsaPublicKey.store(_publicKeyPhantom)
}
