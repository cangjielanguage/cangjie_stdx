/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

/**
 * @file
 *
 * This is a library for class JsonNull, JsonBool, JsonInt, JsonFloat, JsonString, JsonArray, JsonObject.
 */
package stdx.encoding.json

import std.collection.*

func validateJsonStringFormat(depth: Int64, indent: String): Unit {
    if (depth < 0) {
        throw IllegalArgumentException("Invalid argument 'depth': value cannot be negative, got '${depth}'.")
    }
    if (!indent.isContainOnlySpaceAndTab()) {
        throw IllegalArgumentException("Invalid argument 'indent': contains characters other than spaces and tabs.")
    }
}

@When[env != "ohos"]
func validateJsonStringFormat(depth: Int64, indent: String @local?): Unit {
    if (depth < 0) {
        throw IllegalArgumentException("Invalid argument 'depth': value cannot be negative, got '${depth}'.")
    }
    for (item in indent) {
        if (item != b' ' && item != b'\t') {
            throw IllegalArgumentException("Invalid argument 'indent': contains characters other than spaces and tabs.")
        }
    }
}

func bufferToString(buff: WriteBuffer): String {
    unsafe { String.fromUtf8Unchecked(buff.getAndClear()) }
}

@When[env != "ohos"]
exclave func bufferToString(buff: WriteBuffer @local!): String @local! {
    unsafe { String.fromUtf8Unchecked(buff.getAndClear()) }
}

func jsonValueToCompactString(value: JsonValue, htmlSafe!: Bool = true): String {
    let buff = WriteBuffer(asumecapacity(value))
    jsonWriteWithoutFormat(value, buff, htmlSafe: htmlSafe)
    return bufferToString(buff)
}

@When[env != "ohos"]
exclave func jsonValueToCompactString(value: JsonValue @local?, htmlSafe!: Bool = true): String @local! {
    let buff = WriteBuffer(asumecapacity(value)) @local!
    jsonWriteWithoutFormat(value, buff, htmlSafe: htmlSafe)
    bufferToString(buff)
}

@When[env != "ohos"]
func jsonValueToCompactStringHeap(value: JsonValue @local?, htmlSafe!: Bool = true): String {
    let buff = WriteBuffer(asumecapacity(value)) @local!
    jsonWriteWithoutFormat(value, buff, htmlSafe: htmlSafe)
    String(unsafe { String.fromUtf8Unchecked(buff.getAndClear()) })
}

func jsonPrimitiveToString<T>(value: T): String where T <: ToString {
    value.toString()
}

func jsonFloatToString(value: Float64): String {
    if (isJsonFloatInfinite(value)) {
        throw JsonException("Failed to serialize JSON float.")
    }
    return value.toString()
}

func jsonArrayToFormattedString(
    value: JsonArray,
    depth: Int64,
    bracketInNewLine: Bool,
    indent: String,
    htmlSafe!: Bool = true
): String {
    validateJsonStringFormat(depth, indent)
    let buff = WriteBuffer(asumecapacity(value, depth))
    jsonWriteArray(value, buff, depth, bracketInNewLine, indent, htmlSafe: htmlSafe)
    return bufferToString(buff)
}

@When[env != "ohos"]
func jsonArrayToFormattedString(
    value: JsonArray @local?,
    depth: Int64,
    bracketInNewLine: Bool,
    indent: String @local?,
    htmlSafe!: Bool = true
): String {
    validateJsonStringFormat(depth, indent)
    let buff = WriteBuffer(asumecapacity(value, depth)) @local!
    jsonWriteArray(value, buff, depth, bracketInNewLine, indent, htmlSafe: htmlSafe)
    String(unsafe { String.fromUtf8Unchecked(buff.getAndClear()) })
}

@When[env != "ohos"]
exclave func jsonArrayToFormattedString(
    value: JsonArray @local!,
    depth: Int64,
    bracketInNewLine: Bool,
    indent: String @local?,
    htmlSafe!: Bool = true
): String @local! {
    validateJsonStringFormat(depth, indent)
    let buff = WriteBuffer(asumecapacity(value, depth)) @local!
    jsonWriteArray(value, buff, depth, bracketInNewLine, indent, htmlSafe: htmlSafe)
    bufferToString(buff)
}

func jsonObjectToFormattedString(
    value: JsonObject,
    depth: Int64,
    bracketInNewLine: Bool,
    indent: String,
    htmlSafe!: Bool = true
): String {
    validateJsonStringFormat(depth, indent)
    let buff = WriteBuffer(asumecapacity(value, depth))
    jsonWriteObject(value, buff, depth, bracketInNewLine, indent, htmlSafe: htmlSafe)
    return bufferToString(buff)
}

@When[env != "ohos"]
func jsonObjectToFormattedString(
    value: JsonObject @local?,
    depth: Int64,
    bracketInNewLine: Bool,
    indent: String @local?,
    htmlSafe!: Bool = true
): String {
    validateJsonStringFormat(depth, indent)
    let buff = WriteBuffer(asumecapacity(value, depth)) @local!
    jsonWriteObject(value, buff, depth, bracketInNewLine, indent, htmlSafe: htmlSafe)
    String(unsafe { String.fromUtf8Unchecked(buff.getAndClear()) })
}

@When[env != "ohos"]
exclave func jsonObjectToFormattedString(
    value: JsonObject @local!,
    depth: Int64,
    bracketInNewLine: Bool,
    indent: String @local?,
    htmlSafe!: Bool = true
): String @local! {
    validateJsonStringFormat(depth, indent)
    let buff = WriteBuffer(asumecapacity(value, depth)) @local!
    jsonWriteObject(value, buff, depth, bracketInNewLine, indent, htmlSafe: htmlSafe)
    bufferToString(buff)
}
/**
 * JsonNull class used for encapsulate JSON data: null.
 */
public class JsonNull <: JsonValue { // cjlint-ignore !G.ENU.01
    public init() {}

    @When[env != "ohos"]
    public exclave init(this @local!) {}

    /**
     * Determine the JSON type to which the JsonNull belongs.
     *
     * @return type of the JsonNull is JsNull.
     *
     * @since 0.17.4
     */
    public func kind(): JsonKind {
        return JsNull
    }

    @When[env != "ohos"]
    public func kind(this @local?): JsonKind {
        JsNull
    }

    /**
     * Optimized: Calculate capacity for null
     */
    protected func calculateCapacity(): Int64 {
        return 4  // "null"
    }

    @When[env != "ohos"]
    protected func calculateCapacity(this @local?): Int64 {
        return 4  // "null"
    }

    /**
     * Convert JsonNull to String.
     *
     * @return json-converted String is "".
     *
     * @since 0.17.4
     */
    public func toString(): String {
        return "null"
    }

    @When[env != "ohos"]
    public exclave func toString(this @local?): String @local! {
        "null"
    }

    /**
     * Convert JsonNull to json-String.
     *
     * @return json-converted prettified String is "".
     *
     * @since 0.21.1
     */
    public func toJsonString(): String {
        return toString()
    }

    @When[env != "ohos"]
    public exclave func toJsonString(this @local!): String @local! {
        toString()
    }

    /**
     * Convert JsonNull to String Without Escaping.
     *
     * @return json-converted String is "".
     */
    public func toStringWithoutEscaping(): String {
        return "null"
    }

    @When[env != "ohos"]
    public exclave func toStringWithoutEscaping(this @local!): String @local! {
        "null"
    }

    /**
     * Convert JsonNull to json-String Without Escaping.
     *
     * @return json-converted prettified String is "".
     */
    public func toJsonStringWithoutEscaping(): String {
        return toJsonString()
    }

    @When[env != "ohos"]
    public exclave func toJsonStringWithoutEscaping(this @local!): String @local! {
        toJsonString()
    }
}

/**
 * JsonBool class used for encapsulate JSON data: true or false.
 */
public class JsonBool <: JsonValue { // cjlint-ignore !G.ENU.01
    /* Json data of the JsonBool(Bool). */
    private var value: Bool

    /**
     * Create a new JsonBool object.
     * Construction with parameters.
     *
     * @param bv The json data of JsonBool.
     *
     * @since 0.17.4
     */
    public init(bv: Bool) {
        this.value = bv
    }

    @When[env != "ohos"]
    public exclave init(this @local!, bv: Bool) {
        this.value = bv
    }

    /**
     * Get the value data of the JsonBool.
     *
     * @return value of the JsonBool.
     *
     * @since 0.17.4
     */
    public func getValue(): Bool {
        return value
    }

    @When[env != "ohos"]
    public func getValue(this @local?): Bool {
        value
    }

    /**
     * Determine the JSON type to which the JsonBool belongs.
     *
     * @return type of the JsonBool is JsBool.
     *
     * @since 0.17.4
     */
    public func kind(): JsonKind {
        return JsBool
    }

    @When[env != "ohos"]
    public func kind(this @local?): JsonKind {
        JsBool
    }

    /**
     * Optimized: Calculate capacity for bool
     */
    protected func calculateCapacity(): Int64 {
        return 5  // max of "true" and "false"
    }

    @When[env != "ohos"]
    protected func calculateCapacity(this @local?): Int64 {
        return 5  // max of "true" and "false"
    }

    /**
     * Convert JsonBool to String.
     *
     * @return json-converted String is value string data: true or false.
     *
     * @since 0.17.4
     */
    public func toString(): String {
        return jsonPrimitiveToString(value)
    }

    @When[env != "ohos"]
    public exclave func toString(this @local?): String @local! {
        value.toString()
    }

    /**
     * Convert JsonBool to json-String.
     *
     * @return json-converted prettified String is value string data: true or false.
     *
     * @since 0.21.1
     */
    public func toJsonString(): String {
        return toString()
    }

    @When[env != "ohos"]
    public exclave func toJsonString(this @local!): String @local! {
        toString()
    }

    /**
     * Convert JsonBool to String.
     *
     * @return json-converted String is value string data: true or false Without Escaping.
     */
    public func toStringWithoutEscaping(): String {
        return jsonPrimitiveToString(value)
    }

    @When[env != "ohos"]
    public exclave func toStringWithoutEscaping(this @local!): String @local! {
        value.toString()
    }

    /**
     * Convert JsonBool to json-String.
     *
     * @return json-converted prettified String is value string data: true or false Without Escaping.
     */
    public func toJsonStringWithoutEscaping(): String {
        return toString()
    }

    @When[env != "ohos"]
    public exclave func toJsonStringWithoutEscaping(this @local!): String @local! {
        toJsonString()
    }
}

/**
 * JsonInt class used for encapsulate JSON data: number(integer).
 */
public class JsonInt <: JsonValue {
    /* Json data of the JsonInt(Int64). */
    private var value: Int64

    /**
     * Create a new JsonInt object.
     * Construction with parameters.
     *
     * @param iv The json data of JsonInt.
     *
     * @since 0.17.4
     */
    public init(iv: Int64) {
        this.value = iv
    }

    @When[env != "ohos"]
    public exclave init(this @local!, iv: Int64) {
        this.value = iv
    }

    /**
     * Get the value data of the JsonInt.
     *
     * @return value of the JsonInt.
     *
     * @since 0.17.4
     */
    public func getValue(): Int64 {
        return value
    }

    @When[env != "ohos"]
    public func getValue(this @local?): Int64 {
        value
    }

    /**
     * Determine the JSON type to which the JsonInt belongs.
     *
     * @return type of the JsonInt is JsInt.
     *
     * @since 0.17.4
     */
    public func kind(): JsonKind {
        return JsInt
    }

    @When[env != "ohos"]
    public func kind(this @local?): JsonKind {
        JsInt
    }

    /**
     * Optimized: Calculate capacity for int
     */
    protected func calculateCapacity(): Int64 {
        return 22  // max length of Int64 string
    }

    @When[env != "ohos"]
    protected func calculateCapacity(this @local?): Int64 {
        return 22  // max length of Int64 string
    }

    /**
     * Convert JsonInt to String.
     *
     * @return json-converted String is value string data.
     *
     * @since 0.17.4
     */
    public func toString(): String {
        return jsonPrimitiveToString(value)
    }

    @When[env != "ohos"]
    public exclave func toString(this @local?): String @local! {
        value.toString()
    }

    /**
     * Convert JsonInt to json-String.
     *
     * @return json-converted prettified String is value string data.
     *
     * @since 0.21.1
     */
    public func toJsonString(): String {
        return toString()
    }

    @When[env != "ohos"]
    public exclave func toJsonString(this @local!): String @local! {
        toString()
    }

    /**
     * Convert JsonInt to String Without Escaping.
     *
     * @return json-converted String is value string data.
     */
    public func toStringWithoutEscaping(): String {
        return jsonPrimitiveToString(value)
    }

    @When[env != "ohos"]
    public exclave func toStringWithoutEscaping(this @local!): String @local! {
        value.toString()
    }

    /**
     * Convert JsonInt to json-String Without Escaping.
     *
     * @return json-converted prettified String is value string data.
     */
    public func toJsonStringWithoutEscaping(): String {
        return toString()
    }

    @When[env != "ohos"]
    public exclave func toJsonStringWithoutEscaping(this @local!): String @local! {
        toJsonString()
    }
}

/**
 * JsonFloat class used for encapsulate JSON data: number(float).
 */
public class JsonFloat <: JsonValue {
    /* Json data of the JsonFloat(Float64). */
    private var value: Float64

    /**
     * Create a new JsonFloat object.
     * Construction with parameters.
     *
     * @param fv The json data of JsonFloat.
     *
     * @since 0.17.4
     */
    public init(fv: Float64) {
        this.value = fv
    }

    @When[env != "ohos"]
    public exclave init(this @local!, fv: Float64) {
        this.value = fv
    }

    /**
     * Create a new JsonFloat object.
     * Construction with parameters.
     *
     * @param v The json data of JsonInt.
     *
     * @since 0.17.4
     */
    public init(v: Int64) {
        this.value = Float64(v)
    }

    @When[env != "ohos"]
    public exclave init(this @local!, v: Int64) {
        this.value = Float64(v)
    }

    /**
     * Get the value data of the JsonFloat.
     *
     * @return value of the JsonFloat.
     *
     * @since 0.17.4
     */
    public func getValue(): Float64 {
        return value
    }

    @When[env != "ohos"]
    public func getValue(this @local?): Float64 {
        value
    }

    /**
     * Determine the JSON type to which the JsonFloat belongs.
     *
     * @return type of the JsonFloat is JsFloat.
     *
     * @since 0.17.4
     */
    public func kind(): JsonKind {
        return JsFloat
    }

    @When[env != "ohos"]
    public func kind(this @local?): JsonKind {
        JsFloat
    }

    /**
     * Optimized: Calculate capacity for float
     */
    protected func calculateCapacity(): Int64 {
        return 200  // conservative estimate for float representation
    }

    @When[env != "ohos"]
    protected func calculateCapacity(this @local?): Int64 {
        return 200  // conservative estimate for float representation
    }

    /**
     * Convert JsonFloat to String.
     *
     * @return json-converted String is value string data.
     *
     * @since 0.17.4
     */
    public func toString(): String {
        return jsonFloatToString(value)
    }

    @When[env != "ohos"]
    public exclave func toString(this @local?): String @local! {
        if (isJsonFloatInfinite(value)) {
            throw JsonException("Failed to serialize JSON float.")
        }
        value.toString()
    }

    /**
     * Convert JsonFloat to json-String.
     *
     * @return json-converted prettified String is value string data.
     *
     * @since 0.21.1
     */
    public func toJsonString(): String {
        return toString()
    }

    @When[env != "ohos"]
    public exclave func toJsonString(this @local!): String @local! {
        toString()
    }

    /**
     * Convert JsonFloat to String Without Escaping.
     *
     * @return json-converted String is value string data.
     */
    public func toStringWithoutEscaping(): String {
        return jsonFloatToString(value)
    }

    @When[env != "ohos"]
    public exclave func toStringWithoutEscaping(this @local!): String @local! {
        toString()
    }

    /**
     * Convert JsonFloat to json-String Without Escaping.
     *
     * @return json-converted prettified String is value string data.
     */
    public func toJsonStringWithoutEscaping(): String {
        return toString()
    }

    @When[env != "ohos"]
    public exclave func toJsonStringWithoutEscaping(this @local!): String @local! {
        toJsonString()
    }
}

/**
 * JsonString class used for encapsulate JSON data: string.
 */
public class JsonString <: JsonValue { // cjlint-ignore !G.ENU.01
    /* Json data of the JsonString(String). */
    var value: String

    /**
     * Create a new JsonString object.
     * Construction with parameters.
     *
     * @param sv The json data of JsonString.
     *
     * @since 0.17.4
     */
    public init(sv: String) {
        this.value = sv
    }

    @When[env != "ohos"]
    public exclave init(this @local!, sv: String @local!) {
        this.value = sv
    }

    /**
     * Get the value data of the JsonString.
     *
     * @return value of the JsonString.
     *
     * @since 0.17.4
     */
    public func getValue(): String {
        return value
    }

    @When[env != "ohos"]
    public exclave func getValue(this @local!): String @local! {
        value
    }

    @When[env != "ohos"]
    public exclave func getValue(this @local?): String @local? {
        value
    }

    /**
     * Determine the JSON type to which the JsonString belongs.
     *
     * @return type of the JsonString is JsString.
     *
     * @since 0.17.4
     */
    public func kind(): JsonKind {
        return JsString
    }

    @When[env != "ohos"]
    public func kind(this @local?): JsonKind {
        JsString
    }

    /**
     * Optimized: Calculate capacity for string
     */
    protected func calculateCapacity(): Int64 {
        var escapenum: Int64 = 0
        unsafe {
            let input = acquireArrayRawData(value.rawData())
            escapenum = CJ_JSON_StringEscapeCharNumGet(input.pointer, value.size, true)
            releaseArrayRawData(input)
        }
        return value.size + 2 + escapenum  // 2 bytes for the surrounding JSON quotes
    }

    @When[env != "ohos"]
    protected func calculateCapacity(this @local?): Int64 {
        var escapenum: Int64 = 0
        unsafe {
            let input = acquireArrayRawData(value.rawData())
            escapenum = CJ_JSON_StringEscapeCharNumGet(input.pointer, value.size, true)
            releaseArrayRawData(input)
        }
        return value.size + 2 + escapenum  // 2 bytes for the surrounding JSON quotes
    }

    /**
     * Convert JsonString to String.
     *
     * @return json-converted String is value string data.
     *
     * @since 0.17.4
     */
    public func toString(): String {
        let buff = WriteBuffer(value.size + 2)
        jsonWriteWithoutFormat(this, buff)
        return bufferToString(buff)
    }

    @When[env != "ohos"]
    public exclave func toString(this @local?): String @local! {
        let buff = WriteBuffer(value.size + 2) @local!
        jsonWriteWithoutFormat(this, buff)
        bufferToString(buff)
    }

    /**
     * Convert JsonString to json-String.
     *
     * @return json-converted prettified String is value string data.
     *
     * @since 0.21.1
     */
    public func toJsonString(): String {
        let buff = WriteBuffer(value.size + 2)
        jsonWriteWithoutFormat(this, buff)
        return bufferToString(buff)
    }

    @When[env != "ohos"]
    public exclave func toJsonString(this @local!): String @local! {
        let buff = WriteBuffer(value.size + 2) @local!
        jsonWriteWithoutFormat(this, buff)
        bufferToString(buff)
    }

    /**
     * Convert JsonString to String Without Escaping.
     *
     * @return json-converted String is value string data.
     */
    public func toStringWithoutEscaping(): String {
        let buff = WriteBuffer(value.size + 2)
        jsonWriteWithoutFormat(this, buff, htmlSafe: false)
        return bufferToString(buff)
    }

    @When[env != "ohos"]
    public exclave func toStringWithoutEscaping(this @local!): String @local! {
        let buff = WriteBuffer(value.size + 2) @local!
        jsonWriteWithoutFormat(this, buff, htmlSafe: false)
        bufferToString(buff)
    }

    /**
     * Convert JsonString to json-String Without Escaping.
     *
     * @return json-converted prettified String is value string data.
     */
    public func toJsonStringWithoutEscaping(): String {
        let buff = WriteBuffer(value.size + 2)
        jsonWriteWithoutFormat(this, buff, htmlSafe: false)
        return bufferToString(buff)
    }

    @When[env != "ohos"]
    public exclave func toJsonStringWithoutEscaping(this @local!): String @local! {
        let buff = WriteBuffer(value.size + 2) @local!
        jsonWriteWithoutFormat(this, buff, htmlSafe: false)
        bufferToString(buff)
    }
}

/**
 * JsonArray class used for encapsulate JSON data: array.
 */
public class JsonArray <: JsonValue {
    /* Json data of the JsonArray(ArrayList<JsonValue>). */
    private var items: ArrayList<JsonValue>

    /**
     * Create a new JsonArray object.
     * Construction without parameters.
     *
     * @since 0.17.4
     */
    init(capacity: Int64) {
        items = ArrayList<JsonValue>(capacity)
    }

    @When[env != "ohos"]
    exclave init(this @local!, capacity: Int64) {
        items = ArrayList<JsonValue>(capacity) @local!
    }

    public init() {
        items = ArrayList<JsonValue>()
    }

    @When[env != "ohos"]
    public exclave init(this @local!) {
        items = ArrayList<JsonValue>() @local!
    }
    /**
     * Create a new JsonArray object.
     * Construction with parameters.
     *
     * @param list type ArrayList<JsonValue>, the json data of JsonArray.
     *
     * @since 0.17.4
     */
    public init(list: ArrayList<JsonValue>) {
        items = list
    }

    @When[env != "ohos"]
    public exclave init(this @local!, list: ArrayList<JsonValue> @local!) {
        items = list
    }

    /**
     * Create a new JsonArray object.
     * Construction with parameters.
     *
     * @param list type Array<JsonValue>,The json data of JsonArray.
     *
     * @since 0.17.4
     */
    public init(list: Array<JsonValue>) {
        items = ArrayList<JsonValue>(list)
    }

    @When[env != "ohos"]
    public exclave init(this @local!, list: Array<JsonValue> @local!) {
        items = ArrayList<JsonValue>(list) @local!
    }

    /**
     * Determine the JSON type to which the JsonArray belongs.
     *
     * @return type of the JsonArray is JsArray.
     *
     * @since 0.17.4
     */
    public func kind(): JsonKind {
        return JsArray
    }

    @When[env != "ohos"]
    public func kind(this @local?): JsonKind {
        JsArray
    }

    /**
     * Optimized: Calculate capacity for array
     */
    protected func calculateCapacity(): Int64 {
        var sum: Int64 = 2  // []
        for (v in items) {
            sum += v.estimateCapacity() + 1  // value + comma
        }
        return sum
    }

    @When[env != "ohos"]
    protected func calculateCapacity(this @local?): Int64 {
        var sum: Int64 = 2  // []
        for (v in items) {
            sum += v.estimateCapacity() + 1  // value + comma
        }
        return sum
    }

    /**
     * Convert JsonArray to Json-String.
     *
     * @return json-converted String is items string data.
     *
     * @since 0.17.4
     *
     * @throws JsonException if there exists JsonValue which cannot be converted to String.
     */
    public func toJsonString(): String {
        return toJsonStringBase(0)
    }

    @When[env != "ohos"]
    public exclave func toJsonString(this @local!): String @local! {
        jsonArrayToFormattedString(this, 0, false, "  ")
    }

    @When[env != "ohos"]
    public func toJsonString(this @local?): String {
        jsonArrayToFormattedString(this, 0, false, "  ")
    }

    /**
     * Convert JsonArray to Json-String Without Escaping.
     *
     * @return json-converted String is items string data.
     *
     * @throws JsonException if there exists JsonValue which cannot be converted to String.
     */
    public func toJsonStringWithoutEscaping(): String {
        return toJsonStringBase(0, htmlSafe: false)
    }

    @When[env != "ohos"]
    public exclave func toJsonStringWithoutEscaping(this @local!): String @local! {
        jsonArrayToFormattedString(this, 0, false, "  ", htmlSafe: false)
    }

    @When[env != "ohos"]
    public func toJsonStringWithoutEscaping(this @local?): String {
        jsonArrayToFormattedString(this, 0, false, "  ", htmlSafe: false)
    }

    /**
     * Convert JsonArray to Json-String.
     *
     * @param depth of indentation in JSON format.
     * @return json-converted String is items string data.
     *
     * @since 0.17.4
     *
     * @throws JsonException if there exists JsonValue which cannot be converted to String.
     */
    public func toJsonString(depth: Int64, bracketInNewLine!: Bool = false, indent!: String = "  "): String {
        return toJsonStringBase(depth, bracketInNewLine: bracketInNewLine, indent: indent)
    }

    @When[env != "ohos"]
    public exclave func toJsonString(this @local!, depth: Int64, bracketInNewLine!: Bool = false,
        indent!: String @~local = "  "): String @local! {
        jsonArrayToFormattedString(this, depth, bracketInNewLine, indent)
    }

    @When[env != "ohos"]
    public func toJsonString(this @local?, depth: Int64, bracketInNewLine!: Bool = false,
        indent!: String @local? = "  "): String {
        jsonArrayToFormattedString(this, depth, bracketInNewLine, indent)
    }

    /**
     * Convert JsonArray to Json-String.
     *
     * @param depth of indentation in JSON format.
     * @return json-converted String is items string data.
     *
     * @throws JsonException if there exists JsonValue which cannot be converted to String.
     */
    func toJsonStringBase(depth: Int64, bracketInNewLine!: Bool = false, indent!: String = "  ", htmlSafe!: Bool = true): String {
        return jsonArrayToFormattedString(this, depth, bracketInNewLine, indent, htmlSafe: htmlSafe)
    }

    /**
     * Convert JsonArray to Json-String Without Escaping.
     *
     * @param depth of indentation in JSON format.
     * @return json-converted String is items string data.
     *
     * @throws JsonException if there exists JsonValue which cannot be converted to String.
     */
    public func toJsonStringWithoutEscaping(depth: Int64, bracketInNewLine!: Bool = false, indent!: String = "  "): String {
        return toJsonStringBase(depth, bracketInNewLine: bracketInNewLine, indent: indent, htmlSafe: false)
    }

    @When[env != "ohos"]
    public exclave func toJsonStringWithoutEscaping(this @local!, depth: Int64,
        bracketInNewLine!: Bool = false, indent!: String @~local = "  "): String @local! {
        jsonArrayToFormattedString(this, depth, bracketInNewLine, indent, htmlSafe: false)
    }

    @When[env != "ohos"]
    public func toJsonStringWithoutEscaping(this @local?, depth: Int64,
        bracketInNewLine!: Bool = false, indent!: String @local? = "  "): String {
        jsonArrayToFormattedString(this, depth, bracketInNewLine, indent, htmlSafe: false)
    }

    /**
     * Convert JsonArray to String.
     *
     * @return json-converted String is items string data.
     *
     * @since 0.21.1
     *
     * @throws JsonException if there exists JsonValue which cannot be converted to String.
     */
    public func toString(): String {
        return jsonValueToCompactString(this)
    }

    @When[env != "ohos"]
    public exclave func toString(this @local?): String @local! {
        jsonValueToCompactString(this)
    }

    /**
     * Convert JsonArray to String Without Escaping.
     *
     * @return json-converted String is items string data.
     *
     * @throws JsonException if there exists JsonValue which cannot be converted to String.
     */
    public func toStringWithoutEscaping(): String {
        return jsonValueToCompactString(this, htmlSafe: false)
    }

    @When[env != "ohos"]
    public exclave func toStringWithoutEscaping(this @local!): String @local! {
        jsonValueToCompactString(this, htmlSafe: false)
    }

    @When[env != "ohos"]
    public func toStringWithoutEscaping(this @local?): String {
        jsonValueToCompactStringHeap(this, htmlSafe: false)
    }

    /**
     * Get the size of JsonArray.
     *
     * @return the size of items.
     *
     * @since 0.17.4
     */
    public func size(): Int64 {
        return items.size
    }

    @When[env != "ohos"]
    public func size(this @local?): Int64 {
        items.size
    }

    /**
     * Add the Data to JsonArray.
     *
     * @param jv JsonValue data to be added.
     *
     * @since 0.17.4
     */
    public func add(jv: JsonValue): JsonArray {
        items.add(jv)
        return this
    }

    @When[env != "ohos"]
    public exclave func add(this @local!, jv: JsonValue @local!): JsonArray @local! {
        items.add(jv)
        this
    }

    /**
     * Obtains the option version of JsonValue data of JsonArray at a specified location.
     *
     * @param index Index position.
     * @return get the option version of element of the index.
     *
     * @since 0.17.4
     */
    public func get(index: Int64): Option<JsonValue> {
        return items.get(index)
    }

    @When[env != "ohos"]
    public exclave func get(this @local!, index: Int64): Option<JsonValue> @local! {
        items.get(index)
    }

    @When[env != "ohos"]
    public exclave func get(this @local?, index: Int64): Option<JsonValue> @local? {
        items.get(index)
    }

    /**
     * Obtains JsonValue data of JsonArray at a specified location.
     *
     * @param index Index position.
     * @return get the element of the index.
     *
     * @since 0.17.4
     *
     * @throws JsonException if index of JsonArray does not exist.
     */
    public operator func [](index: Int64): JsonValue {
        return match (items.get(index)) {
            case Some(v) => v
            case None => throw JsonException("Index '${index}' does not exist in JsonArray.")
        }
    }

    @When[env != "ohos"]
    public exclave operator func [](this @local!, index: Int64): JsonValue @local! {
        match (get(index)) {
            case Some(v) => v
            case None => throw JsonException("Index '${index}' does not exist in JsonArray.")
        }
    }

    @When[env != "ohos"]
    public exclave operator func [](this @local?, index: Int64): JsonValue @local? {
        match (get(index)) {
            case Some(v) => v
            case None => throw JsonException("Index '${index}' does not exist in JsonArray.")
        }
    }

    /**
     * Get the items data of JsonArray.
     *
     * @return the items of JsonArray.
     *
     * @since 0.17.4
     */
    public func getItems(): ArrayList<JsonValue> {
        return items
    }

    @When[env != "ohos"]
    public exclave func getItems(this @local!): ArrayList<JsonValue> @local! {
        items
    }

    @When[env != "ohos"]
    public func getItems(this @local?): ArrayList<JsonValue> @local? {
        items
    }
}

/**
 * JsonObject class used for encapsulate JSON data: object.
 */
public class JsonObject <: JsonValue {
    /* Json data of the JsonObject(HashMap<String,JsonValue>). */
    private var fields: HashMap<String, JsonValue>

    /**
     * Create a new JsonObject object.
     * Construction without parameters.
     *
     * @since 0.17.4
     */
    public init() {
        fields = HashMap<String, JsonValue>()
    }

    @When[env != "ohos"]
    public exclave init(this @local!) {
        fields = HashMap<String, JsonValue>() @local!
    }

    init(capacity: Int64) {
        fields = HashMap<String, JsonValue>(capacity)
    }

    @When[env != "ohos"]
    exclave init(this @local!, capacity: Int64) {
        fields = HashMap<String, JsonValue>(capacity) @local!
    }

    /**
     * Create a new JsonObject object.
     * Construction with parameters.
     *
     * @param map The json data of JsonObject.
     *
     * @since 0.17.4
     */
    public init(map: HashMap<String, JsonValue>) {
        fields = map
    }

    @When[env != "ohos"]
    public exclave init(this @local!, map: HashMap<String, JsonValue> @local!) {
        fields = map
    }

    /**
     * Determine the JSON type to which the JsonObject belongs.
     *
     * @return type of the JsonObject is JsObject.
     *
     * @since 0.17.4
     */
    public func kind(): JsonKind {
        return JsObject
    }

    @When[env != "ohos"]
    public func kind(this @local?): JsonKind {
        JsObject
    }

    /**
     * Optimized: Calculate capacity for object
     */
    protected func calculateCapacity(): Int64 {
        var sum: Int64 = 2  // {}
        for ((k, v) in fields) {
            sum += k.size + 4  // "key": ,
            sum += v.estimateCapacity()
        }
        return sum
    }

    @When[env != "ohos"]
    protected func calculateCapacity(this @local?): Int64 {
        var sum: Int64 = 2  // {}
        for ((k, v) in fields) {
            sum += k.size + 4  // "key": ,
            sum += v.estimateCapacity()
        }
        return sum
    }

    /**
     * Convert JsonObject to Json-String.
     *
     * @return json-converted String is fields string data.
     *
     * @since 0.17.4
     *
     * @throws JsonException if there exists JsonValue which cannot be converted to String.
     */
    public func toJsonString(): String {
        return toJsonStringBase(0)
    }

    @When[env != "ohos"]
    public exclave func toJsonString(this @local!): String @local! {
        jsonObjectToFormattedString(this, 0, false, "  ")
    }

    @When[env != "ohos"]
    public func toJsonString(this @local?): String {
        jsonObjectToFormattedString(this, 0, false, "  ")
    }

     /**
     * Convert JsonObject to Json-String Without Escaping.
     *
     * @return json-converted String is fields string data.
     *
     * @throws JsonException if there exists JsonValue which cannot be converted to String.
     */
    public func toJsonStringWithoutEscaping(): String {
        return toJsonStringBase(0, htmlSafe: false)
    }

    @When[env != "ohos"]
    public exclave func toJsonStringWithoutEscaping(this @local!): String @local! {
        jsonObjectToFormattedString(this, 0, false, "  ", htmlSafe: false)
    }

    @When[env != "ohos"]
    public func toJsonStringWithoutEscaping(this @local?): String {
        jsonObjectToFormattedString(this, 0, false, "  ", htmlSafe: false)
    }

    /**
     * Convert JsonObject to Json-String.
     *
     * @param depth of indentation in JSON format.
     * @return json-converted String is fields string data.
     *
     * @since 0.17.4
     *
     * @throws JsonException if there exists JsonValue which cannot be converted to String.
     */
    public func toJsonString(depth: Int64, bracketInNewLine!: Bool = false, indent!: String = "  "): String {
        return toJsonStringBase(depth, bracketInNewLine: bracketInNewLine, indent: indent)
    }

    @When[env != "ohos"]
    public exclave func toJsonString(this @local!, depth: Int64, bracketInNewLine!: Bool = false,
        indent!: String @~local = "  "): String @local! {
        jsonObjectToFormattedString(this, depth, bracketInNewLine, indent)
    }

    @When[env != "ohos"]
    public func toJsonString(this @local?, depth: Int64, bracketInNewLine!: Bool = false,
        indent!: String @local? = "  "): String {
        jsonObjectToFormattedString(this, depth, bracketInNewLine, indent)
    }

    /**
     * Convert JsonObject to Json-String.
     *
     * @param depth of indentation in JSON format.
     * @return json-converted String is fields string data.
     *
     * @throws JsonException if there exists JsonValue which cannot be converted to String.
     */
    func toJsonStringBase(depth: Int64, bracketInNewLine!: Bool = false, indent!: String = "  ", htmlSafe!: Bool = true): String {
        return jsonObjectToFormattedString(this, depth, bracketInNewLine, indent, htmlSafe: htmlSafe)
    }

    /**
     * Convert JsonObject to Json-String Without Escaping.
     *
     * @param depth of indentation in JSON format.
     * @return json-converted String is fields string data.
     *
     * @throws JsonException if there exists JsonValue which cannot be converted to String.
     */
    public func toJsonStringWithoutEscaping(depth: Int64, bracketInNewLine!: Bool = false, indent!: String = "  "): String {
        return toJsonStringBase(depth, bracketInNewLine: bracketInNewLine, indent: indent, htmlSafe: false)
    }

    @When[env != "ohos"]
    public exclave func toJsonStringWithoutEscaping(this @local!, depth: Int64,
        bracketInNewLine!: Bool = false, indent!: String @~local = "  "): String @local! {
        jsonObjectToFormattedString(this, depth, bracketInNewLine, indent, htmlSafe: false)
    }

    @When[env != "ohos"]
    public func toJsonStringWithoutEscaping(this @local?, depth: Int64,
        bracketInNewLine!: Bool = false, indent!: String @local? = "  "): String {
        jsonObjectToFormattedString(this, depth, bracketInNewLine, indent, htmlSafe: false)
    }

    /**
     * Convert JsonObject to String.
     *
     * @return json-converted String is fields string data.
     *
     * @since 0.21.1
     *
     * @throws JsonException if there exists JsonValue which cannot be converted to String.
     */
    public func toString(): String {
        return jsonValueToCompactString(this)
    }

    @When[env != "ohos"]
    public exclave func toString(this @local?): String @local! {
        jsonValueToCompactString(this)
    }

    /**
     * Convert JsonObject to String Without Escaping.
     *
     * @return json-converted String is fields string data.
     *
     * @throws JsonException if there exists JsonValue which cannot be converted to String.
     */
    public func toStringWithoutEscaping(): String {
        return jsonValueToCompactString(this, htmlSafe: false)
    }

    @When[env != "ohos"]
    public exclave func toStringWithoutEscaping(this @local!): String @local! {
        jsonValueToCompactString(this, htmlSafe: false)
    }

    @When[env != "ohos"]
    public func toStringWithoutEscaping(this @local?): String {
        jsonValueToCompactStringHeap(this, htmlSafe: false)
    }

    /**
     * Get the size of JsonObject.
     *
     * @return the size of fields.
     *
     * @since 0.17.4
     */
    public func size(): Int64 {
        return fields.size
    }

    @When[env != "ohos"]
    public func size(this @local?): Int64 {
        fields.size
    }

    /**
     * Check whether the JsonObject contains a key.
     *
     * @param key Key position.
     * @return check whether the fields contains the key.
     *
     * @since 0.17.4
     */
    public func containsKey(key: String): Bool {
        return fields.contains(key)
    }

    @When[env != "ohos"]
    public func containsKey(this @local?, key: String @local?): Bool {
        fields.contains(key)
    }

    /**
     * Put the Data to JsonObject.
     *
     * @param key Key position.
     * @param v JsonValue data.
     *
     * @since 0.17.4
     */
    public func put(key: String, v: JsonValue): Unit {
        fields.add(key, v)
    }

    @When[env != "ohos"]
    public exclave func put(this @local!, key: String @local!, v: JsonValue @local!): Unit {
        fields.add(key, v)
    }

    @When[env != "ohos"]
    public exclave func put(this @local!, key: String @local?, v: JsonValue @local!): Unit {
        // Keys are stored as owned heap Strings.
        fields.add(unsafe { String.fromUtf8Unchecked(key.toString().rawData()) }, v)
    }

    /**
     * Obtains the option version of JsonValue data of JsonObject at a specified location.
     *
     * @param key Key position.
     * @return get option version of data corresponding to the key.
     *
     * @since 0.17.4
     */
    public func get(key: String): Option<JsonValue> {
        return fields.get(key)
    }

    @When[env != "ohos"]
    public exclave func get(this @local!, key: String @local!): Option<JsonValue> @local! {
        // Bind through a typed local: an explicit `Option<JsonValue>.Some(v) @local!` loses
        // the payload's dynamic type in a `@local!` context.
        match (fields.get(key)) {
            case Some(found) =>
                let localValue: JsonValue @local! = found
                let result: Option<JsonValue> @local! = localValue
                result
            case None => None
        }
    }

    @When[env != "ohos"]
    public exclave func get(this @local?, key: String @local?): Option<JsonValue> @local? {
        fields.get(key)
    }

    /**
     * Obtains JsonValue data of JsonObject at a specified location.
     *
     * @param key Key position.
     * @return get data corresponding to the key.
     *
     * @since 0.17.4
     *
     * @throws JsonException if key of JsonObject does not exist.
     */
    public operator func [](key: String): JsonValue {
        return match (fields.get(key)) {
            case Some(v) => v
            case None => throw JsonException("Key '${key}' does not exist in JsonObject.")
        }
    }

    @When[env != "ohos"]
    public exclave operator func [](this @local!, key: String @local!): JsonValue @local! {
        match (get(key)) {
            case Some(value) => value
            case None => throw JsonException("Key '${key}' does not exist in JsonObject.")
        }
    }

    @When[env != "ohos"]
    public exclave operator func [](this @local?, key: String @local?): JsonValue @local? {
        match (get(key)) {
            case Some(value) => value
            case None => throw JsonException("Key '${key}' does not exist in JsonObject.")
        }
    }

    /**
     * Get the fields data of JsonObject.
     *
     * @return the fields of JsonObject.
     *
     * @since 0.17.4
     */
    public func getFields(): HashMap<String, JsonValue> {
        return fields
    }

    @When[env != "ohos"]
    public exclave func getFields(this @local!): HashMap<String, JsonValue> @local! {
        fields
    }

    @When[env != "ohos"]
    public func getFields(this @local?): HashMap<String, JsonValue> @local? {
        fields
    }
}

extend String {
    func isContainOnlySpaceAndTab() {
        for (i in this) {
            if (i != b' ' && i != b'\t') {
                return false
            }
        }
        return true
    }
}
