/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.net.http

/**
 * incremental UTF-8 validator (RFC 3629) for WebSocket Text data.
 * supports validating bytes that are streamed across multiple
 * fragmented frames, because a multi-byte UTF-8 sequence may be
 * split by frame boundaries.
 *
 * the validator accepts only the strict form of UTF-8:
 *   1-byte : 0x00-0x7F
 *   2-byte : 0xC2-0xDF followed by 0x80-0xBF
 *   3-byte : 0xE0 0xA0-0xBF / 0xE1-0xEC 0x80-0xBF / 0xED 0x80-0x9F / 0xEE-0xEF 0x80-0xBF
 *   4-byte : 0xF0 0x90-0xBF / 0xF1-0xF3 0x80-0xBF / 0xF4 0x80-0x8F
 *
 * thus overlong encodings (e.g. 0xC0 0xC1), UTF-16 surrogates
 * (0xED 0xA0-0xBF), code points above U+10FFFF (0xF5-0xFF) and
 * truncated sequences are rejected.
 * RFC 6455 8.1.
 */
class Utf8Validator {
    // remaining continuation bytes expected for the current sequence
    var remaining: UInt8 = 0
    // the valid range of the next byte
    var lower: UInt8 = 0x80
    var upper: UInt8 = 0xBF

    /**
     * feed a single byte, return false if the byte is invalid
     * in the current context.
     */
    func feed(b: UInt8): Bool {
        if (remaining > 0) {
            if (b < lower || b > upper) {
                return false
            }
            remaining -= 1
            // the constrained range only applies to the first continuation byte,
            // e.g. 0xE0 expects 0xA0-0xBF, but the second byte expects 0x80-0xBF.
            lower = 0x80
            upper = 0xBF
            return true
        }
        if (b <= 0x7F) {
            return true
        }
        if (b >= 0xC2 && b <= 0xDF) {
            remaining = 1
            return true
        }
        if (b == 0xE0) {
            remaining = 2
            lower = 0xA0
            return true
        }
        if ((b >= 0xE1 && b <= 0xEC) || b == 0xEE || b == 0xEF) {
            remaining = 2
            return true
        }
        if (b == 0xED) {
            remaining = 2
            upper = 0x9F
            return true
        }
        if (b == 0xF0) {
            remaining = 3
            lower = 0x90
            return true
        }
        if (b >= 0xF1 && b <= 0xF3) {
            remaining = 3
            return true
        }
        if (b == 0xF4) {
            remaining = 3
            upper = 0x8F
            return true
        }
        // 0x80-0xBF: stray continuation byte,
        // 0xC0-0xC1: overlong 2-byte encoding,
        // 0xF5-0xFF: overlong 4-byte encoding or out of range.
        return false
    }

    /**
     * feed an array of bytes, return false if any byte is invalid.
     */
    func feed(data: Array<UInt8>): Bool {
        for (b in data) {
            if (!feed(b)) {
                return false
            }
        }
        return true
    }

    /**
     * check whether no partial sequence is pending,
     * i.e. the fed data ends at a character boundary.
     */
    func isComplete(): Bool {
        remaining == 0
    }

    func reset(): Unit {
        remaining = 0
        lower = 0x80
        upper = 0xBF
    }
}

/**
 * validate a complete message payload as strict UTF-8 (RFC 3629),
 * rejecting overlong encodings, UTF-16 surrogates, code points above
 * U+10FFFF and truncated sequences.
 * RFC 6455 5.6.
 */
func isValidUtf8Message(data: Array<UInt8>): Bool {
    let validator = Utf8Validator()
    return validator.feed(data) && validator.isComplete()
}
