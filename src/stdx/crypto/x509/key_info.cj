/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.crypto.x509

import stdx.crypto.common.*
import stdx.crypto.keys.*

func encodePublicKeyToPem(key: PublicKey): PemEntry {
    PemEntry(PemEntry.LABEL_PUBLIC_KEY, key.encodeToDer())
}

func decodePublicKeyFromDer(blob: DerBlob): PublicKey {
    GeneralPublicKey.decodeDer(blob)
}

func decodePublicKeyFromPem(text: String): PublicKey {
    for (entry in Pem.decode(text)) {
        if (isPublicKey(entry)) {
            if (let Some(v) <- entry.body) {
                return decodePublicKeyFromDer(v)
            }
        }
    }

    throw X509Exception("No ${PemEntry.LABEL_PUBLIC_KEY} entry found in PEM file.")
}

class CertPublicKey <: PublicKey {
    CertPublicKey(private let blob: X509Blob) {}

    public func encodeToDer(): DerBlob {
        blob.publicKey.blob
    }

    /**
     * Encode to PemEntry
     * @throws X509Exception if failed to encode
     */
    public func encodeToPem(): PemEntry {
        encodePublicKeyToPem(this)
    }

    /**
     * Decode a key from a DerBlob (DER/ASN1 binary format).
     * @throws X509Exception if failed to decode
     */
    public static func decodeDer(blob: DerBlob): PublicKey {
        decodePublicKeyFromDer(blob)
    }

    /**
     * Load the first key from PEM text.
     * @throws X509Exception if failed to parse or decode key or there are no public keys in the PEM
     */
    public static func decodeFromPem(text: String): PublicKey {
        decodePublicKeyFromPem(text)
    }

    public override func toString(): String {
        "PublicKey(for ${blob.subject})"
    }
}

class CertRequestPublicKey <: PublicKey {
    CertRequestPublicKey(private let blob: X509CsrBlob) {}

    public override func encodeToDer(): DerBlob {
        blob.publicKey.blob
    }

    /**
     * Encode to PemEntry
     * @throws X509Exception if failed to encode
     */
    public func encodeToPem(): PemEntry {
        encodePublicKeyToPem(this)
    }

    /**
     * Decode a key from a DerBlob (DER/ASN1 binary format).
     * @throws X509Exception if failed to decode
     */
    public static func decodeDer(blob: DerBlob): PublicKey {
        decodePublicKeyFromDer(blob)
    }

    /**
     * Load the first key from PEM text.
     * @throws X509Exception if failed to parse or decode key or there are no public keys in the PEM
     */
    public static func decodeFromPem(text: String): PublicKey {
        decodePublicKeyFromPem(text)
    }

    public override func toString(): String {
        "PublicKey(for ${blob.subject})"
    }
}

public enum PublicKeyAlgorithm <: Equatable<PublicKeyAlgorithm> & ToString {
    RSA | DSA | ECDSA | UnknownPublicKeyAlgorithm

    public override operator func ==(other: PublicKeyAlgorithm): Bool {
        this.toString() == other.toString()
    }

    public override operator func !=(other: PublicKeyAlgorithm): Bool {
        !(this == other)
    }

    public override func toString(): String {
        var res: String = "Public Key Algorithm: "
        match (this) {
            case RSA => res = res + "rsaEncryption"
            case DSA => res = res + "dsaEncryption"
            case ECDSA => res = res + "id-ecPublicKey"
            case UnknownPublicKeyAlgorithm => res = res + "unknown public key algorithm"
        }
        res
    }
}
