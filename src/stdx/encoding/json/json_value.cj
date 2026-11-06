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
 * This is a library for JsonValue class and JsonKind enum.
 */
package stdx.encoding.json


/**
 * This enum used for identify the JSON type.
 */
public enum JsonKind {
    JsNull | JsBool | JsInt | JsFloat | JsString | JsArray | JsObject
}

/**
 * JsonValue abstract class used for JSON manipulations.
 */
sealed abstract class JsonValue <: ToString {
    public init() {}

    @When[env != "ohos"]
    public exclave init(this @local!) {}

    /**
     * Convert JsonValue to String.
     *
     * @return json-converted String.
     *
     * @since 0.17.4
     *
     * @throws JsonException if there exists JsonValue which cannot be converted to String.
     */
    public func toString(): String
    @When[env != "ohos"]
    public open func toString(this @local?): String @local! {
        throw UnimplementedException("JsonValue.toString(this @local?) not implemented")
    }

    /**
     * Convert JsonValue to json-String.
     *
     * @return json-converted prettified String.
     *
     * @since 0.21.1
     *
     * @throws JsonException if there exists JsonValue which cannot be converted to String.
     */
    public func toJsonString(): String
    @When[env != "ohos"]
    public open func toJsonString(this @local!): String @local! {
        throw UnimplementedException("JsonValue.toJsonString(this @local!) not implemented")
    }

    /**
     * Convert JsonValue to String Without Escaping.
     *
     * @return json-converted String.
     *
     * @throws JsonException if there exists JsonValue which cannot be converted to String.
     */
    public func toStringWithoutEscaping(): String
    @When[env != "ohos"]
    public open func toStringWithoutEscaping(this @local!): String @local! {
        throw UnimplementedException("JsonValue.toStringWithoutEscaping(this @local!) not implemented")
    }

    /**
     * Convert JsonValue to json-String Without Escaping.
     *
     * @return json-converted prettified String.
     *
     * @throws JsonException if there exists JsonValue which cannot be converted to String.
     */
    public func toJsonStringWithoutEscaping(): String
    @When[env != "ohos"]
    public open func toJsonStringWithoutEscaping(this @local!): String @local! {
        throw UnimplementedException("JsonValue.toJsonStringWithoutEscaping(this @local!) not implemented")
    }

    /**
     * Parses string data into JsonValue.
     *
     * @param s String in JSON data format.
     * @throws IllegalArgumentException if string contains null character.
     * @return parsed JsonValue.
     *
     * @since 0.17.4
     *
     * @throws JsonException if malloc failed or json structure is non-standard.
     */
    public static func fromStr(s: String): JsonValue {
        parseString(s)
    }

    // An owned argument is parsed directly; the shared overload materialises an owned
    // copy first. Overload resolution stays unambiguous: a literal or a heap String binds
    // the plain overload above, `@local!` binds this one, `@local?` binds the shared one.
    // The same-name overloads are required by the local-mode adaptation, so the shadow
    // warning does not apply.
    @When[env != "ohos"]
    public exclave static func fromStr(s: String @local!): JsonValue @local! { // cjlint-ignore !G.DCL.01
        parseString(s)
    }

    @When[env != "ohos"]
    public exclave static func fromStr(s: String @local?): JsonValue @local! { // cjlint-ignore !G.DCL.01
        let ls: String @local! = s.toString()
        parseString(ls)
    }

    /**
     * Determine the JSON type to which the JsonValue belongs.
     *
     * @return type of this JsonValue.
     *
     * @since 0.17.4
     */
    public func kind(): JsonKind
    @When[env != "ohos"]
    public open func kind(this @local?): JsonKind {
        throw UnimplementedException("JsonValue.kind(this @local?) not implemented")
    }

    public func estimateCapacity(): Int64 {
        return calculateCapacity()
    }

    @When[env != "ohos"]
    public func estimateCapacity(this @local?): Int64 {
        return calculateCapacity()
    }

    /**
     * Calculate capacity (to be overridden by subclasses)
     */
    protected func calculateCapacity(): Int64
    @When[env != "ohos"]
    protected func calculateCapacity(this @local?): Int64

    /**
     * Invalidate cached capacity when structure changes
     */
    protected func invalidateCapacity(): Unit {
        return
    }

    @When[env != "ohos"]
    protected func invalidateCapacity(this @local!): Unit {
        return
    }

    /**
     * Convert JsonValue to JsonNull. If the failure occurs, Exception will be throwed.
     *
     * @return converted JsonNull.
     *
     * @since 0.17.4
     *
     * @throws JsonException if JsonValue cannot be converted to JsonNull.
     */
    public func asNull(): JsonNull {
        match (this) {
            case jsonNull: JsonNull => jsonNull
            case _ => throw JsonException("Fail to convert to JsonNull")
        }
    }

    @When[env != "ohos"]
    public exclave func asNull(this @local!): JsonNull @local! {
        match (this) {
            case jsonNull: JsonNull => jsonNull
            case _ => throw JsonException("Fail to convert to JsonNull")
        }
    }

    /**
     * Convert JsonValue to JsonBool. If the failure occurs, Exception will be throwed.
     *
     * @return converted JsonBool.
     *
     * @since 0.17.4
     *
     * @throws JsonException if JsonValue cannot be converted to JsonBool.
     */
    public func asBool(): JsonBool {
        match (this) {
            case jsonBool: JsonBool => jsonBool
            case _ => throw JsonException("Fail to convert to JsonBool")
        }
    }

    @When[env != "ohos"]
    public exclave func asBool(this @local!): JsonBool @local! {
        match (this) {
            case jsonBool: JsonBool => jsonBool
            case _ => throw JsonException("Fail to convert to JsonBool")
        }
    }

    /**
     * Convert JsonValue to JsonInt. If the failure occurs, Exception will be throwed.
     *
     * @return converted JsonInt.
     *
     * @since 0.17.4
     *
     * @throws JsonException if JsonValue cannot be converted to JsonInt.
     */
    public func asInt(): JsonInt {
        match (this) {
            case jsonInt: JsonInt => jsonInt
            case _ => throw JsonException("Fail to convert to JsonInt")
        }
    }

    @When[env != "ohos"]
    public exclave func asInt(this @local!): JsonInt @local! {
        match (this) {
            case jsonInt: JsonInt => jsonInt
            case _ => throw JsonException("Fail to convert to JsonInt")
        }
    }

    /**
     * Convert JsonValue to JsonFloat. If the failure occurs, Exception will be throwed.
     *
     * @return converted JsonFloat.
     *
     * @since 0.17.4
     *
     * @throws JsonException if JsonValue cannot be converted to JsonFloat.
     */
    public func asFloat(): JsonFloat {
        match (this) {
            case jsonFloat: JsonFloat => jsonFloat
            case jsonInt: JsonInt => JsonFloat(jsonInt.getValue())
            case _ => throw JsonException("Fail to convert to JsonFloat")
        }
    }

    @When[env != "ohos"]
    public exclave func asFloat(this @local!): JsonFloat @local! {
        match (this) {
            case jsonFloat: JsonFloat => jsonFloat
            case jsonInt: JsonInt =>
                let value: Int64 @local! = jsonInt.getValue()
                JsonFloat(value) @local!
            case _ => throw JsonException("Fail to convert to JsonFloat")
        }
    }

    /**
     * Convert JsonValue to JsonString. If the failure occurs, Exception will be throwed.
     *
     * @return converted JsonString.
     *
     * @since 0.17.4
     *
     * @throws JsonException if JsonValue cannot be converted to JsonString.
     */
    public func asString(): JsonString {
        match (this) {
            case jsonString: JsonString => jsonString
            case _ => throw JsonException("Fail to convert to JsonString")
        }
    }

    @When[env != "ohos"]
    public exclave func asString(this @local!): JsonString @local! {
        match (this) {
            case jsonString: JsonString => jsonString
            case _ => throw JsonException("Fail to convert to JsonString")
        }
    }

    /**
     * Convert JsonValue to JsonArray. If the failure occurs, Exception will be throwed.
     *
     * @return converted JsonArray.
     *
     * @since 0.17.4
     *
     * @throws JsonException if JsonValue cannot be converted to JsonArray.
     */
    public func asArray(): JsonArray {
        match (this) {
            case jsonArray: JsonArray => jsonArray
            case _ => throw JsonException("Fail to convert to JsonArray")
        }
    }

    @When[env != "ohos"]
    public exclave func asArray(this @local!): JsonArray @local! {
        match (this) {
            case jsonArray: JsonArray => jsonArray
            case _ => throw JsonException("Fail to convert to JsonArray")
        }
    }

    /**
     * Convert JsonValue to JsonObject. If the failure occurs, Exception will be throwed.
     *
     * @return converted JsonObject.
     *
     * @since 0.17.4
     *
     * @throws JsonException if JsonValue cannot be converted to JsonObject.
     */
    public func asObject(): JsonObject {
        match (this) {
            case jsonObject: JsonObject => jsonObject
            case _ => throw JsonException("Fail to convert to JsonObject")
        }
    }

    @When[env != "ohos"]
    public exclave func asObject(this @local!): JsonObject @local! {
        match (this) {
            case jsonObject: JsonObject => jsonObject
            case _ => throw JsonException("Fail to convert to JsonObject")
        }
    }
}
