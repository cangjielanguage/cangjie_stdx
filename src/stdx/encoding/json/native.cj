/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.encoding.json

import std.collection.*
import std.convert.*

const MAX_JSON_PARSE_DEPTH = 100
const INITIAL_JSON_OBJECT_CAPACITY = 8
const INITIAL_JSON_ARRAY_CAPACITY = 8

@FastNative
foreign func CJ_JSON_ReplaceEscapeChar(input: CPointer<UInt8>, inputlen: Int64, buffer: CPointer<UInt8>, htmlSafe: Bool): Int64

@FastNative
foreign func CJ_JSON_WriteBufferAppendInt(buffer: CPointer<UInt8>, num: Int64): Int64

@FastNative
foreign func CJ_CORE_Float64ToCPointer(num: Float64): CPointer<UInt8>

@FastNative
foreign func strlen(str: CPointer<UInt8>): UIntNative

@FastNative
foreign func CJ_JSON_StringEscapeCharNumGet(input: CPointer<UInt8>, inputlen: Int64, htmlSafe: Bool): Int64

@FastNative
foreign func CJ_JSON_ParseFloat64(data: CPointer<UInt8>, start: Int64, end: Int64): Float64

/**
 * @brief Get rows and columns of the error position
 *
 * @param Array<UInt8> JSON string array
 * @param Int64 The order of the error characters in the string
 * @return (Int64, Int64) Rows and columns of the error position
 * @throws IllegalArgumentException if there is no valid utf8 leading code in array `strArr`.
 */
func getErrRowAndCol(strArr: Array<UInt8>, errPos: Int64): (Int64, Int64) {
    var tempPos: Int64 = 0
    var errRow: Int64 = 1
    var errCol: Int64 = 1
    var lineStartPos: Int64 = 0
    while (tempPos < errPos) {
        let temp = Rune.fromUtf8(strArr, tempPos)
        let tempChr = temp[0]
        if (tempChr == r'\n') {
            errRow += 1
            lineStartPos = tempPos + 1
        }
        tempPos += temp[1]
    }
    while (lineStartPos < errPos) {
        let tempChr = Rune.fromUtf8(strArr, lineStartPos)[0]
        if (tempChr == r' ') {
            lineStartPos += 1
        } else {
            break
        }
    }
    while (lineStartPos < errPos) {
        let temp = Rune.fromUtf8(strArr, lineStartPos)
        let tempSize = temp[1]
        errCol += 1
        lineStartPos += tempSize
    }
    return (errRow, errCol)
}

/**
 * @brief Handle Escape Characters and Multibyte Characters
 *
 * @param Rune error characters
 * @return String Escaped character string
 */
func handleErrChr(errChr: Rune): String {
    match (errChr) {
        case r'\0' => return "\\0"
        case r'\b' => return "\\b"
        case r'\t' => return "\\t"
        case r'\n' => return "\\n"
        case r'\f' => return "\\f"
        case r'\r' => return "\\r"
        case r'\v' => return "\\v"
        case _ => return "${errChr}"
    }
}

enum NumberSystem {
    Binary |
    Octal |
    Decimal |
    Hex
}

const MAXVAL_I64: UInt64 = 0x7FFF_FFFF_FFFF_FFFF
const MAXVAL_UI64: UInt64 = 0xFFFF_FFFF_FFFF_FFFF
const MAXABSVAL_I64: UInt64 = MAXVAL_I64 + 1
const MINVAL_I64: Int64 = -0x8000_0000_0000_0000
const DECIMAL_OVERFLOW_LIMIT_UI64 = MAXVAL_UI64 / 10

class JsonParser {
    var data: Array<Byte>
    var size: Int64
    var offset: Int64
    var depth: Int64
    let strCache: ArrayList<Byte>

    init(str: String) {
        this.data = unsafe { str.rawData() }
        this.size = data.size
        this.offset = 0
        this.depth = 0
        let estimatedCacheSize = if (str.size / 4 > 64) { str.size / 4 } else { 64 }
        this.strCache = ArrayList<Byte>(estimatedCacheSize)
    }

    func reset(): Unit {
        this.offset = 0
        this.depth = 0
        this.strCache.clear()
    }

    func reinit(str: String): Unit {
        this.data = unsafe { str.rawData() }
        this.size = data.size
        reset()
    }

    @When[env != "ohos"]
    exclave init(this @local!, str: String @local!) {
        this.data = unsafe { str.rawData() }
        this.size = data.size
        this.offset = 0
        this.depth = 0
        let estimatedCacheSize = if (str.size / 4 > 64) { str.size / 4 } else { 64 }
        this.strCache = ArrayList<Byte>(estimatedCacheSize) @local!
    }

    @When[env != "ohos"]
    exclave func reset(this @local!): Unit {
        this.offset = 0
        this.depth = 0
        this.strCache.clear()
    }

    @When[env != "ohos"]
    exclave func reinit(this @local!, str: String @local!): Unit {
        this.data = unsafe { str.rawData() }
        this.size = data.size
        reset()
    }
}

func requireCurrentByte(parser: JsonParser): Byte {
    if (parser.offset >= parser.size) {
        throw JsonException("Failed to parse JSON data.")
    }
    return parser.data[parser.offset]
}

func isHighSurrogate(num: UInt32): Bool {
    return num >= 0xD800u32 && num <= 0xDBFFu32 // UTF-16 high-surrogate range: D800..DBFF.
}

func isLowSurrogate(num: UInt32): Bool {
    return num >= 0xDC00u32 && num <= 0xDFFFu32 // UTF-16 low-surrogate range: DC00..DFFF.
}

// NaN and Infinity are not valid JSON number literals (RFC 8259); serializing
// them verbatim would produce output that no JSON parser can read back.
// Call sites keep their own exception type and message (read/parse side and
// write side deliberately differ).
func isJsonFloatInfinite(value: Float64): Bool {
    return value.isNaN() || value.isInf()
}

func skipWhiteSpace(parser: JsonParser): Unit {
    if (parser.offset >= parser.size) {
        return
    }
    var tmp = parser.data[parser.offset]
    while (tmp == b' ' || tmp == b'\t' || tmp == b'\n' || tmp == b'\r') {
        parser.offset++
        if (parser.offset >= parser.size) {
            return
        }
        tmp = parser.data[parser.offset]
    }
}

func buildParseErrorMessage(parser: JsonParser): String {
    let strArr = parser.data
    var errPos = parser.offset
    if (errPos >= strArr.size) {
        errPos = strArr.size - 1
        // Report the final UTF-8 character from its leading byte.
        while (errPos > 0 && (strArr[errPos] & 0xC0) == 0x80) {
            errPos--
        }
    }
    let errRowAndCol = getErrRowAndCol(strArr, errPos)
    let (errChr, _) = Rune.fromUtf8(strArr, errPos)
    let errStr = handleErrChr(errChr)
    return "Parse Error: [Line]: ${errRowAndCol[0]}, [Pos]: ${errRowAndCol[1]}, [Error]: Unexpected character: \'${errStr}\'."
}

func parseString(str: String): JsonValue {
    if (str.size == 0) {
        throw JsonException("JSON string is empty.")
    }
    let parser = JsonParser(str)
    try {
        let res = parseJson(parser)
        if (parser.offset <= (parser.size - 1)) {
            skipWhiteSpace(parser)
        }
        if (parser.offset <= (parser.size - 1)) {
            throw JsonException("Failed to parse JSON data.")
        }
        return res
    } catch (_: Exception) {
        let errMsg = buildParseErrorMessage(parser)
        throw JsonException("Invalid JSON data: ${errMsg}")
    }
}

func parseJson(parser: JsonParser): JsonValue {
    skipWhiteSpace(parser)
    let start = requireCurrentByte(parser)
    match {
        case start == b'{' => return parseNestedJson(parser, {=> parseJsonObject(parser)})
        case start == b'[' => return parseNestedJson(parser, {=> parseJsonArray(parser)})
        case start == b'n' => return parseJsonNull(parser)
        case start == b't' => return parseJsonTrue(parser)
        case start == b'f' => return parseJsonFalse(parser)
        case start == b'\"' => return parseJsonString(parser)
        case start >= b'0' && start <= b'9' || start == b'-' => return parseJsonNumber(parser)
        case _ => throw JsonException("Failed to parse JSON data.")
    }
}

func parseNestedJson(parser: JsonParser, block: () -> JsonValue): JsonValue {
    parser.depth++
    if (parser.depth > MAX_JSON_PARSE_DEPTH) {
        throw JsonException("JSON nested depth '${parser.depth}' exceeds maximum '${MAX_JSON_PARSE_DEPTH}'.")
    }
    try {
        return block()
    } finally {
        parser.depth--
    }
}

func parseJsonObject(parser: JsonParser): JsonObject {
    parser.offset++
    skipWhiteSpace(parser)
    let obj = JsonObject(INITIAL_JSON_OBJECT_CAPACITY)
    var first = true
    while (requireCurrentByte(parser) != b'}') {
        if (first) {
            first = false
        } else if (requireCurrentByte(parser) == b',') {
            parser.offset++
        } else {
            throw JsonException("Failed to parse JSON data.")
        }
        skipWhiteSpace(parser)
        let key = parseJsonString(parser)
        skipWhiteSpace(parser)
        if (requireCurrentByte(parser) != b':') {
            throw JsonException("Failed to parse JSON data.")
        }
        parser.offset++
        let value = parseJson(parser)
        skipWhiteSpace(parser)
        obj.put(key.getValue(), value)
    }
    parser.offset++
    return obj
}

func parseJsonArray(parser: JsonParser): JsonArray {
    parser.offset++
    skipWhiteSpace(parser)
    let arr = JsonArray(INITIAL_JSON_ARRAY_CAPACITY)
    var first = true
    while (requireCurrentByte(parser) != b']') {
        if (first) {
            first = false
        } else if (requireCurrentByte(parser) == b',') {
            parser.offset++
        } else {
            throw JsonException("Failed to parse JSON data.")
        }
        let item = parseJson(parser)
        skipWhiteSpace(parser)
        arr.add(item)
    }
    parser.offset++
    return arr
}

func parseJsonNull(parser: JsonParser): JsonNull {
    if (requireCurrentByte(parser) != b'n') {
        throw JsonException("Failed to parse JSON data.")
    }
    parser.offset++
    if (requireCurrentByte(parser) != b'u') {
        throw JsonException("Failed to parse JSON data.")
    }
    parser.offset++
    if (requireCurrentByte(parser) != b'l') {
        throw JsonException("Failed to parse JSON data.")
    }
    parser.offset++
    if (requireCurrentByte(parser) != b'l') {
        throw JsonException("Failed to parse JSON data.")
    }
    parser.offset++
    return JsonNull()
}

func parseJsonTrue(parser: JsonParser): JsonBool {
    if (requireCurrentByte(parser) != b't') {
        throw JsonException("Failed to parse JSON data.")
    }
    parser.offset++
    if (requireCurrentByte(parser) != b'r') {
        throw JsonException("Failed to parse JSON data.")
    }
    parser.offset++
    if (requireCurrentByte(parser) != b'u') {
        throw JsonException("Failed to parse JSON data.")
    }
    parser.offset++
    if (requireCurrentByte(parser) != b'e') {
        throw JsonException("Failed to parse JSON data.")
    }
    parser.offset++
    return JsonBool(true)
}

func parseJsonFalse(parser: JsonParser): JsonBool {
    if (requireCurrentByte(parser) != b'f') {
        throw JsonException("Failed to parse JSON data.")
    }
    parser.offset++
    if (requireCurrentByte(parser) != b'a') {
        throw JsonException("Failed to parse JSON data.")
    }
    parser.offset++
    if (requireCurrentByte(parser) != b'l') {
        throw JsonException("Failed to parse JSON data.")
    }
    parser.offset++
    if (requireCurrentByte(parser) != b's') {
        throw JsonException("Failed to parse JSON data.")
    }
    parser.offset++
    if (requireCurrentByte(parser) != b'e') {
        throw JsonException("Failed to parse JSON data.")
    }
    parser.offset++
    return JsonBool(false)
}

func tryParseJsonIntFast(parser: JsonParser): (Bool, Int64) {
    let start = parser.offset
    var isNegative = false
    if (parser.data[parser.offset] == b'-') {
        isNegative = true
        parser.offset++
        if (parser.offset >= parser.size) {
            parser.offset = start
            return (false, 0)
        }
    }

    let firstDigit = parser.data[parser.offset]
    if (firstDigit < b'0' || firstDigit > b'9') {
        parser.offset = start
        return (false, 0)
    }

    if (firstDigit == b'0' && parser.offset + 1 < parser.size) {
        let nextByte = parser.data[parser.offset + 1]
        if (nextByte >= b'0' && nextByte <= b'9') {
            throw JsonException("Failed to parse JSON data.")
        }
        if (nextByte == b'b' || nextByte == b'B' || nextByte == b'o' || nextByte == b'O' || nextByte == b'x' ||
            nextByte == b'X' || nextByte == b'd' || nextByte == b'D') {
            parser.offset = start
            return (false, 0)
        }
    }

    var result: UInt64 = 0
    while (parser.offset < parser.size) {
        let nextByte = parser.data[parser.offset]
        if (nextByte < b'0' || nextByte > b'9') {
            break
        }
        let digit = UInt64(nextByte - b'0')
        if (result > DECIMAL_OVERFLOW_LIMIT_UI64) {
            parser.offset = start
            return (false, 0)
        }
        result = result * 10
        if (MAXVAL_UI64 - result < digit) {
            parser.offset = start
            return (false, 0)
        }
        result += digit
        parser.offset++
    }

    if (parser.offset < parser.size) {
        let tail = parser.data[parser.offset]
        if (tail == b'.' || tail == b'e' || tail == b'E') {
            parser.offset = start
            return (false, 0)
        }
    }

    if (isNegative) {
        if (result > MAXABSVAL_I64) {
            parser.offset = start
            return (false, 0)
        }
        if (result == MAXABSVAL_I64) {
            return (true, MINVAL_I64)
        }
        return (true, -Int64(result))
    }
    if (result > MAXVAL_I64) {
        parser.offset = start
        return (false, 0)
    }
    return (true, Int64(result))
}

func parseJsonNumberSlow(parser: JsonParser): JsonValue {
    var isFloat = false
    let leftIndex = parser.offset
    var rightIndex = parser.offset
    parseSign(parser)
    let numSystem = parseNumberSystem(parser)
    let isNumber = checkNumberSystem(numSystem)
    parseInteger(parser, isNumber)
    isFloat = parseDecimal(parser, numSystem)
    if (isFloat) {
        parseExponent(parser, numSystem)
    } else {
        isFloat = parseExponent(parser, numSystem)
    }
    rightIndex = parser.offset
    unsafe {
        if (isFloat) {
            let ptr = acquireArrayRawData(parser.data)
            let value = CJ_JSON_ParseFloat64(ptr.pointer, leftIndex, rightIndex)
            releaseArrayRawData(ptr)
            if (isJsonFloatInfinite(value)) {
                throw JsonException("Invalid float detected.")
            }
            return JsonFloat(value)
        }
    }
    let numStr = unsafe { String.fromUtf8Unchecked(parser.data[leftIndex..rightIndex]) }
    return JsonInt(Int64.parse(numStr))
}

func parseJsonNumber(parser: JsonParser): JsonValue {
    let (success, value) = tryParseJsonIntFast(parser)
    if (success) {
        return JsonInt(value)
    }
    return parseJsonNumberSlow(parser)
}

func parseSign(parser: JsonParser): Unit {
    if (parser.offset < parser.size && parser.data[parser.offset] == b'-') {
        parser.offset++
    }
}

func parseNumberSystem(parser: JsonParser): NumberSystem {
    if (requireCurrentByte(parser) == b'0') {
        parser.offset++
        if (parser.offset >= parser.size) {
            parser.offset--
            return Decimal
        }
        match (parser.data[parser.offset]) {
            case 'b' | 'B' =>
                parser.offset++
                return Binary
            case 'o' | 'O' =>
                parser.offset++
                return Octal
            case 'x' | 'X' =>
                parser.offset++
                return Hex
            case _ => parser.offset--
        }
    }
    return Decimal
}

func checkNumberSystem(numSystem: NumberSystem): (Byte) -> Bool {
    match (numSystem) {
        case Binary => return {byte: Byte => byte >= b'0' && byte <= b'1'}
        case Octal => return {byte: Byte => byte >= b'0' && byte <= b'7'}
        case Decimal => return {byte: Byte => byte >= b'0' && byte <= b'9'}
        case Hex => return {
            byte: Byte => byte >= b'0' && byte <= b'9' || byte >= b'a' &&
                byte <= b'f' || byte >= b'A' && byte <= b'F'
        }
    }
}

func parseInteger(parser: JsonParser, isNumber: (Byte) -> Bool): Unit {
    var nextByte = requireCurrentByte(parser)
    var hasNumber = false
    if (nextByte == b'0') {
        parser.offset++
        return
    }
    while (isNumber(nextByte)) {
        hasNumber = true
        parser.offset++
        if (parser.offset >= parser.size) {
            return
        }
        nextByte = parser.data[parser.offset]
    }
    if (!hasNumber) {
        throw JsonException("Failed to parse JSON data.")
    }
}

func parseDecimal(parser: JsonParser, numSystem: NumberSystem): Bool {
    if (parser.offset >= parser.size) {
        return false
    }
    if (parser.data[parser.offset] != b'.') {
        return false
    }
    match (numSystem) {
        case Decimal => ()
        case _ => throw JsonException("Failed to parse JSON data.")
    }
    parser.offset++
    return parseDigit(parser)
}

func parseExponent(parser: JsonParser, numSystem: NumberSystem): Bool {
    if (parser.offset >= parser.size) {
        return false
    }
    var nextByte = requireCurrentByte(parser)
    if (nextByte != b'e' && nextByte != b'E') {
        return false
    }
    match (numSystem) {
        case Decimal => ()
        case _ => throw JsonException("Failed to parse JSON data.")
    }
    parser.offset++
    nextByte = requireCurrentByte(parser)
    if (nextByte == b'+' || nextByte == b'-') {
        parser.offset++
    }
    return parseDigit(parser)
}

func parseDigit(parser: JsonParser): Bool {
    var nextByte = requireCurrentByte(parser)
    var hasNumber = false
    while (nextByte >= b'0' && nextByte <= b'9') {
        hasNumber = true
        parser.offset++
        if (parser.offset >= parser.size) {
            return true
        }
        nextByte = parser.data[parser.offset]
    }
    if (!hasNumber) {
        throw JsonException("Failed to parse JSON data.")
    }
    return true
}

func isHexNum(char: UInt8): Bool {
    if (!((char >= b'0' && char <= b'9') || (char >= b'a' && char <= b'f') ||
        (char >= b'A' && char <= b'F'))) {
        return false
    }
    return true
}

func parseJsonString(parser: JsonParser): JsonString {
    if (requireCurrentByte(parser) != b'\"') {
        throw JsonException("Failed to parse JSON string.")
    }
    parser.offset++
    let start = parser.offset

    while (parser.offset < parser.size) {
        let next = parser.data[parser.offset]
        if (next == b'\"') {
            parser.offset++
            return unsafe { JsonString(String.fromUtf8Unchecked(parser.data[start..(parser.offset - 1)])) }
        }
        if (next == b'\\') {
            break
        }
        // JSON strings must escape all control characters (U+0000..U+001F).
        // Accepting them here creates values that strict JSON parsers reject.
        if (next < 0x20) {
            throw JsonException()
        }
        parser.offset++
    }

    if (parser.offset >= parser.size) {
        throw JsonException("Failed to parse JSON data.")
    }

    var next = parser.data[parser.offset]
    var tmpStart = start
    while (next != b'\"') {
        // Control characters are not allowed unescaped inside a JSON string.
        if (next < 0x20) {
            throw JsonException()
        }
        if (next == b'\\') {
            parser.strCache.add(all: parser.data[tmpStart..parser.offset])
            parser.offset++
            handleEscape(parser)
            tmpStart = parser.offset + 1
        } else if (next < 0x20) {
            throw JsonException()
        }
        parser.offset++
        next = requireCurrentByte(parser)
    }
    parser.offset++
    parser.strCache.add(all: parser.data[tmpStart..parser.offset - 1])
    let res = unsafe { JsonString(String.fromUtf8Unchecked(parser.strCache.getRawArray()[0..parser.strCache.size])) }
    parser.strCache.clear()
    return res
}

func getNextHexNum(parser: JsonParser): Byte {
    parser.offset++
    let byte = requireCurrentByte(parser)
    if (!isHexNum(byte)) {
        throw JsonException("Failed to parse JSON data.")
    }
    return byte
}

func handleEscape(parser: JsonParser): Unit {
    match (requireCurrentByte(parser)) {
        case '\"' => parser.strCache.add(b'\"')
        case '\\' => parser.strCache.add(b'\\')
        case '/' => parser.strCache.add(b'/')
        case 'b' => parser.strCache.add(b'\b')
        case 'f' => parser.strCache.add(b'\f')
        case 'n' => parser.strCache.add(b'\n')
        case 'r' => parser.strCache.add(b'\r')
        case 't' => parser.strCache.add(b'\t')
        case 'u' =>
            let byte1 = getNextHexNum(parser)
            let byte2 = getNextHexNum(parser)
            let byte3 = getNextHexNum(parser)
            let byte4 = getNextHexNum(parser)
            let arr: Array<Byte> = [b'\'', b'\\', b'u', b'{',
                byte1, byte2, byte3, byte4, b'}', b'\'']
            try {
                let chr = unsafe { Rune.parse(String.fromUtf8Unchecked(arr)) }
                if (UInt32(chr) <= 127) {
                    parser.strCache.add(UInt8(UInt32(chr)))
                } else {
                    let str = chr.toString()
                    unsafe { parser.strCache.add(all: str.rawData()) }
                }
            } catch (_: Exception) {
                parser.offset++
                if (requireCurrentByte(parser) != b'\\') {
                    throw JsonException("Failed to parse JSON data.")
                }
                parser.offset++
                if (requireCurrentByte(parser) != b'u') {
                    throw JsonException("Failed to parse JSON data.")
                }
                let byte5 = getNextHexNum(parser)
                let byte6 = getNextHexNum(parser)
                let byte7 = getNextHexNum(parser)
                let byte8 = getNextHexNum(parser)
                let str1 = unsafe { String.fromUtf8Unchecked([b'0', b'x', byte1, byte2, byte3, byte4]) }
                let str2 = unsafe { String.fromUtf8Unchecked([b'0', b'x', byte5, byte6, byte7, byte8]) }
                let rawNum1 = UInt32.parse(str1)
                let rawNum2 = UInt32.parse(str2)
                if (!isHighSurrogate(rawNum1) || !isLowSurrogate(rawNum2)) {
                    throw JsonException("Failed to parse JSON data.")
                }
                let num1 = rawNum1 & 0b0000001111111111
                let num2 = rawNum2 & 0b0000001111111111
                let str = Rune((((UInt32(num1)) << 10) | (UInt32(num2))) + 0x10000).toString()
                unsafe { parser.strCache.add(all: str.rawData()) }
            }
        case _ => throw JsonException("Failed to parse JSON string.")
    }
}

@When[env != "ohos"]
exclave func requireCurrentByte(parser: JsonParser @local!): Byte {
    if (parser.offset >= parser.size) {
        throw JsonException()
    }
    parser.data[parser.offset]
}

@When[env != "ohos"]
exclave func skipWhiteSpace(parser: JsonParser @local!): Unit {
    if (parser.offset >= parser.size) {
        return
    }
    var tmp = parser.data[parser.offset]
    while (tmp == b' ' || tmp == b'\t' || tmp == b'\n' || tmp == b'\r') {
        parser.offset++
        if (parser.offset >= parser.size) {
            return
        }
        tmp = parser.data[parser.offset]
    }
}

@When[env != "ohos"]
exclave func buildParseErrorMessage(parser: JsonParser @local!): String {
    // Copy the raw bytes into a plain array so the non-local overloads apply.
    let localRaw = unsafe { String.fromUtf8Unchecked(parser.data) }
    let strArr: Array<UInt8> = String(localRaw).toArray()
    var errPos = parser.offset
    if (errPos >= strArr.size) {
        errPos = strArr.size - 1
        // Report the final UTF-8 character from its leading byte.
        while (errPos > 0 && (strArr[errPos] & 0xC0) == 0x80) {
            errPos--
        }
    }
    let errRowAndCol = getErrRowAndCol(strArr, errPos)
    let (errChr, _) = Rune.fromUtf8(strArr, errPos)
    let errStr = handleErrChr(errChr)
    "Parse Error: [Line]: ${errRowAndCol[0]}, [Pos]: ${errRowAndCol[1]}, [Error]: Unexpected character: \'${errStr}\'."
}

@When[env != "ohos"]
func parseString(str: String @local!): JsonValue @local! {
    exclave {
        if (str.size == 0) {
            throw JsonException("Json String is empty!")
        }
        let parser = JsonParser(str) @local!
        try {
            let res = parseJson(parser)
            if (parser.offset <= (parser.size - 1)) {
                skipWhiteSpace(parser)
            }
            if (parser.offset <= (parser.size - 1)) {
                throw JsonException()
            }
            res
        } catch (_: Exception) {
            let errMsg = buildParseErrorMessage(parser)
            throw JsonException("The json data is Non-standard, please check:\n${errMsg}")
        }
    }
}

@When[env != "ohos"]
exclave func parseJson(parser: JsonParser @local!): JsonValue @local! {
    skipWhiteSpace(parser)
    let start = requireCurrentByte(parser)
    match {
        case start == b'{' => parseNestedJsonKind(parser, true)
        case start == b'[' => parseNestedJsonKind(parser, false)
        case start == b'n' => parseJsonNull(parser)
        case start == b't' => parseJsonTrue(parser)
        case start == b'f' => parseJsonFalse(parser)
        case start == b'\"' => parseJsonString(parser)
        case start >= b'0' && start <= b'9' || start == b'-' => parseJsonNumber(parser)
        case _ => throw JsonException()
    }
}

@When[env != "ohos"]
exclave func parseNestedJsonKind(parser: JsonParser @local!, isObject: Bool): JsonValue @local! {
    parser.depth++
    if (parser.depth > MAX_JSON_PARSE_DEPTH) {
        throw JsonException("Json nested depth exceeds ${MAX_JSON_PARSE_DEPTH}.")
    }
    try {
        if (isObject) {
            parseJsonObject(parser)
        } else {
            parseJsonArray(parser)
        }
    } finally {
        parser.depth--
    }
}

@When[env != "ohos"]
exclave func parseNestedJson(parser: JsonParser @local!, block: () -> JsonValue @local!): JsonValue @local! {
    parser.depth++
    if (parser.depth > MAX_JSON_PARSE_DEPTH) {
        throw JsonException("Json nested depth exceeds ${MAX_JSON_PARSE_DEPTH}.")
    }
    try {
        block()
    } finally {
        parser.depth--
    }
}

@When[env != "ohos"]
exclave func parseJsonObject(parser: JsonParser @local!): JsonObject @local! {
    parser.offset++
    skipWhiteSpace(parser)
    let obj = JsonObject(INITIAL_JSON_OBJECT_CAPACITY) @local!
    var first = true
    while (requireCurrentByte(parser) != b'}') {
        if (first) {
            first = false
        } else if (requireCurrentByte(parser) == b',') {
            parser.offset++
        } else {
            throw JsonException()
        }
        skipWhiteSpace(parser)
        let key = parseJsonString(parser)
        skipWhiteSpace(parser)
        if (requireCurrentByte(parser) != b':') {
            throw JsonException()
        }
        parser.offset++
        let value = parseJson(parser)
        skipWhiteSpace(parser)
        obj.put(key.getValue(), value)
    }
    parser.offset++
    obj
}

@When[env != "ohos"]
exclave func parseJsonArray(parser: JsonParser @local!): JsonArray @local! {
    parser.offset++
    skipWhiteSpace(parser)
    let arr = JsonArray(INITIAL_JSON_ARRAY_CAPACITY) @local!
    var first = true
    while (requireCurrentByte(parser) != b']') {
        if (first) {
            first = false
        } else if (requireCurrentByte(parser) == b',') {
            parser.offset++
        } else {
            throw JsonException()
        }
        let item = parseJson(parser)
        skipWhiteSpace(parser)
        arr.add(item)
    }
    parser.offset++
    arr
}

@When[env != "ohos"]
exclave func parseJsonNull(parser: JsonParser @local!): JsonNull @local! {
    if (requireCurrentByte(parser) != b'n') {
        throw JsonException()
    }
    parser.offset++
    if (requireCurrentByte(parser) != b'u') {
        throw JsonException()
    }
    parser.offset++
    if (requireCurrentByte(parser) != b'l') {
        throw JsonException()
    }
    parser.offset++
    if (requireCurrentByte(parser) != b'l') {
        throw JsonException()
    }
    parser.offset++
    JsonNull() @local!
}

@When[env != "ohos"]
exclave func parseJsonTrue(parser: JsonParser @local!): JsonBool @local! {
    if (requireCurrentByte(parser) != b't') {
        throw JsonException()
    }
    parser.offset++
    if (requireCurrentByte(parser) != b'r') {
        throw JsonException()
    }
    parser.offset++
    if (requireCurrentByte(parser) != b'u') {
        throw JsonException()
    }
    parser.offset++
    if (requireCurrentByte(parser) != b'e') {
        throw JsonException()
    }
    parser.offset++
    JsonBool(true) @local!
}

@When[env != "ohos"]
exclave func parseJsonFalse(parser: JsonParser @local!): JsonBool @local! {
    if (requireCurrentByte(parser) != b'f') {
        throw JsonException()
    }
    parser.offset++
    if (requireCurrentByte(parser) != b'a') {
        throw JsonException()
    }
    parser.offset++
    if (requireCurrentByte(parser) != b'l') {
        throw JsonException()
    }
    parser.offset++
    if (requireCurrentByte(parser) != b's') {
        throw JsonException()
    }
    parser.offset++
    if (requireCurrentByte(parser) != b'e') {
        throw JsonException()
    }
    parser.offset++
    JsonBool(false) @local!
}

@When[env != "ohos"]
exclave func tryParseJsonIntFast(parser: JsonParser @local!): (Bool, Int64) {
    let start = parser.offset
    var isNegative = false
    if (parser.data[parser.offset] == b'-') {
        isNegative = true
        parser.offset++
        if (parser.offset >= parser.size) {
            parser.offset = start
            return (false, 0)
        }
    }

    let firstDigit = parser.data[parser.offset]
    if (firstDigit < b'0' || firstDigit > b'9') {
        parser.offset = start
        return (false, 0)
    }

    if (firstDigit == b'0' && parser.offset + 1 < parser.size) {
        let nextByte = parser.data[parser.offset + 1]
        if (nextByte >= b'0' && nextByte <= b'9') {
            throw JsonException()
        }
        if (nextByte == b'b' || nextByte == b'B' || nextByte == b'o' || nextByte == b'O' || nextByte == b'x' ||
            nextByte == b'X' || nextByte == b'd' || nextByte == b'D') {
            parser.offset = start
            return (false, 0)
        }
    }

    var result: UInt64 = 0
    while (parser.offset < parser.size) {
        let nextByte = parser.data[parser.offset]
        if (nextByte < b'0' || nextByte > b'9') {
            break
        }
        let digit = UInt64(nextByte - b'0')
        if (result > DECIMAL_OVERFLOW_LIMIT_UI64) {
            parser.offset = start
            return (false, 0)
        }
        result = result * 10
        if (MAXVAL_UI64 - result < digit) {
            parser.offset = start
            return (false, 0)
        }
        result += digit
        parser.offset++
    }

    if (parser.offset < parser.size) {
        let tail = parser.data[parser.offset]
        if (tail == b'.' || tail == b'e' || tail == b'E') {
            parser.offset = start
            return (false, 0)
        }
    }

    if (isNegative) {
        if (result > MAXABSVAL_I64) {
            parser.offset = start
            return (false, 0)
        }
        if (result == MAXABSVAL_I64) {
            return (true, MINVAL_I64)
        }
        return (true, -Int64(result))
    }
    if (result > MAXVAL_I64) {
        parser.offset = start
        return (false, 0)
    }
    (true, Int64(result))
}

@When[env != "ohos"]
exclave func parseJsonNumberSlow(parser: JsonParser @local!): JsonValue @local! {
    var isFloat = false
    let leftIndex = parser.offset
    var rightIndex = parser.offset
    parseSign(parser)
    let numSystem = parseNumberSystem(parser)
    let isNumber = checkNumberSystem(numSystem)
    parseInteger(parser, isNumber)
    isFloat = parseDecimal(parser, numSystem)
    if (isFloat) {
        parseExponent(parser, numSystem)
    } else {
        isFloat = parseExponent(parser, numSystem)
    }
    rightIndex = parser.offset
    unsafe {
        if (isFloat) {
            let ptr = acquireArrayRawData(parser.data)
            let value = CJ_JSON_ParseFloat64(ptr.pointer, leftIndex, rightIndex)
            releaseArrayRawData(ptr)
            if (isJsonFloatInfinite(value)) {
                throw JsonException("Invalid float detected.")
            }
            let localValue: Float64 @local! = value
            return JsonFloat(localValue) @local!
        }
    }
    let numStr = unsafe { String.fromUtf8Unchecked(parser.data[leftIndex..rightIndex]) }
    let localValue = Int64.parse(String(numStr))
    JsonInt(localValue) @local!
}

@When[env != "ohos"]
exclave func parseJsonNumber(parser: JsonParser @local!): JsonValue @local! {
    let (success, value) = tryParseJsonIntFast(parser)
    if (success) {
        let localValue: Int64 @local! = value
        return JsonInt(localValue) @local!
    }
    parseJsonNumberSlow(parser)
}

@When[env != "ohos"]
exclave func parseSign(parser: JsonParser @local!): Unit {
    if (parser.offset < parser.size && parser.data[parser.offset] == b'-') {
        parser.offset++
    }
}

@When[env != "ohos"]
exclave func parseNumberSystem(parser: JsonParser @local!): NumberSystem {
    if (requireCurrentByte(parser) == b'0') {
        parser.offset++
        if (parser.offset >= parser.size) {
            parser.offset--
            return Decimal
        }
        match (parser.data[parser.offset]) {
            case 'b' | 'B' =>
                parser.offset++
                return Binary
            case 'o' | 'O' =>
                parser.offset++
                return Octal
            case 'x' | 'X' =>
                parser.offset++
                return Hex
            case _ => parser.offset--
        }
    }
    Decimal
}

@When[env != "ohos"]
exclave func parseInteger(parser: JsonParser @local!, isNumber: (Byte) -> Bool): Unit {
    var nextByte = requireCurrentByte(parser)
    var hasNumber = false
    if (nextByte == b'0') {
        parser.offset++
        return
    }
    while (isNumber(nextByte)) {
        hasNumber = true
        parser.offset++
        if (parser.offset >= parser.size) {
            return
        }
        nextByte = parser.data[parser.offset]
    }
    if (!hasNumber) {
        throw JsonException()
    }
}

@When[env != "ohos"]
exclave func parseDecimal(parser: JsonParser @local!, numSystem: NumberSystem): Bool {
    if (parser.offset >= parser.size || parser.data[parser.offset] != b'.') {
        return false
    }
    match (numSystem) {
        case Decimal => ()
        case _ => throw JsonException()
    }
    parser.offset++
    parseDigit(parser)
}

@When[env != "ohos"]
exclave func parseExponent(parser: JsonParser @local!, numSystem: NumberSystem): Bool {
    if (parser.offset >= parser.size) {
        return false
    }
    var nextByte = requireCurrentByte(parser)
    if (nextByte != b'e' && nextByte != b'E') {
        return false
    }
    match (numSystem) {
        case Decimal => ()
        case _ => throw JsonException()
    }
    parser.offset++
    nextByte = requireCurrentByte(parser)
    if (nextByte == b'+' || nextByte == b'-') {
        parser.offset++
    }
    parseDigit(parser)
}

@When[env != "ohos"]
exclave func parseDigit(parser: JsonParser @local!): Bool {
    var nextByte = requireCurrentByte(parser)
    var hasNumber = false
    while (nextByte >= b'0' && nextByte <= b'9') {
        hasNumber = true
        parser.offset++
        if (parser.offset >= parser.size) {
            return true
        }
        nextByte = parser.data[parser.offset]
    }
    if (!hasNumber) {
        throw JsonException()
    }
    true
}

@When[env != "ohos"]
exclave func parseJsonString(parser: JsonParser @local!): JsonString @local! {
    if (requireCurrentByte(parser) != b'\"') {
        throw JsonException("Fail to parseJsonString")
    }
    parser.offset++
    let start = parser.offset

    while (parser.offset < parser.size) {
        let next = parser.data[parser.offset]
        if (next == b'\"') {
            parser.offset++
            let value: String @local! = unsafe { String.fromUtf8Unchecked(parser.data[start..(parser.offset - 1)]) }
            return JsonString(value) @local!
        }
        if (next == b'\\') {
            break
        }
        if (next < 0x20) {
            throw JsonException()
        }
        parser.offset++
    }

    if (parser.offset >= parser.size) {
        throw JsonException()
    }

    var next = parser.data[parser.offset]
    var tmpStart = start
    while (next != b'\"') {
        if (next == b'\\') {
            let segment = parser.data[tmpStart..parser.offset]
            for (index in 0..segment.size) {
                parser.strCache.add(segment[index])
            }
            parser.offset++
            handleEscape(parser)
            tmpStart = parser.offset + 1
        } else if (next < 0x20) {
            throw JsonException()
        }
        parser.offset++
        next = requireCurrentByte(parser)
    }
    parser.offset++
    let segment = parser.data[tmpStart..parser.offset - 1]
    for (index in 0..segment.size) {
        parser.strCache.add(segment[index])
    }
    let value: String @local! = unsafe { String.fromUtf8Unchecked(parser.strCache.toArray()) }
    parser.strCache.clear()
    JsonString(value) @local!
}


@When[env != "ohos"]
exclave func getNextHexNum(parser: JsonParser @local!): Byte {
    parser.offset++
    let byte = requireCurrentByte(parser)
    if (!isHexNum(byte)) {
        throw JsonException()
    }
    byte
}

@When[env != "ohos"]
exclave func appendLocalBytes(cache: ArrayList<Byte> @local!, bytes: Array<Byte> @local?): Unit {
    for (index in 0..bytes.size) {
        cache.add(bytes[index])
    }
}

@When[env != "ohos"]
exclave func handleEscape(parser: JsonParser @local!): Unit {
    match (requireCurrentByte(parser)) {
        case '"' => parser.strCache.add(b'"')
        case '\\' => parser.strCache.add(b'\\')
        case '/' => parser.strCache.add(b'/')
        case 'b' => parser.strCache.add(b'\b')
        case 'f' => parser.strCache.add(b'\f')
        case 'n' => parser.strCache.add(b'\n')
        case 'r' => parser.strCache.add(b'\r')
        case 't' => parser.strCache.add(b'\t')
        case 'u' =>
            let byte1 = getNextHexNum(parser)
            let byte2 = getNextHexNum(parser)
            let byte3 = getNextHexNum(parser)
            let byte4 = getNextHexNum(parser)
            let arr: Array<Byte> @local! = [b'\'', b'\\', b'u', b'{',
                byte1, byte2, byte3, byte4, b'}', b'\'']
            try {
                let chr = unsafe { Rune.parse(String(String.fromUtf8Unchecked(arr))) }
                if (UInt32(chr) <= 127) {
                    parser.strCache.add(UInt8(UInt32(chr)))
                } else {
                    let str = chr.toString()
                    appendLocalBytes(parser.strCache, unsafe { str.rawData() })
                }
            } catch (_: Exception) {
                parser.offset++
                if (requireCurrentByte(parser) != b'\\') {
                    throw JsonException()
                }
                parser.offset++
                if (requireCurrentByte(parser) != b'u') {
                    throw JsonException()
                }
                let byte5 = getNextHexNum(parser)
                let byte6 = getNextHexNum(parser)
                let byte7 = getNextHexNum(parser)
                let byte8 = getNextHexNum(parser)
                let str1 = unsafe { String.fromUtf8Unchecked([b'0', b'x', byte1, byte2, byte3, byte4]) }
                let str2 = unsafe { String.fromUtf8Unchecked([b'0', b'x', byte5, byte6, byte7, byte8]) }
                let rawNum1 = UInt32.parse(String(str1))
                let rawNum2 = UInt32.parse(String(str2))
                if (!isHighSurrogate(rawNum1) || !isLowSurrogate(rawNum2)) {
                    throw JsonException()
                }
                let num1 = rawNum1 & 0b0000001111111111
                let num2 = rawNum2 & 0b0000001111111111
                let str = Rune((((UInt32(num1)) << 10) | (UInt32(num2))) + 0x10000).toString()
                appendLocalBytes(parser.strCache, unsafe { str.rawData() })
            }
        case _ => throw JsonException("Fail to parseJsonString")
    }
}
