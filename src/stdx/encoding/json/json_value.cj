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

    public open func toString(this @local?): String @local! {
        throw Exception()
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

    /**
     * Convert JsonValue to String Without Escaping.
     *
     * @return json-converted String.
     *
     * @throws JsonException if there exists JsonValue which cannot be converted to String.
     */
    public func toStringWithoutEscaping(): String

    /**
     * Convert JsonValue to json-String Without Escaping.
     *
     * @return json-converted prettified String.
     *
     * @throws JsonException if there exists JsonValue which cannot be converted to String.
     */
    public func toJsonStringWithoutEscaping(): String

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
    public static exclave func fromStrLocal(s: String): JsonValue @local! {
        parseStringLocal(s)
    }

    /**
     * Determine the JSON type to which the JsonValue belongs.
     *
     * @return type of this JsonValue.
     *
     * @since 0.17.4
     */
    public func kind(): JsonKind
    public func kind(this @local?): JsonKind

    public func estimateCapacity(): Int64 {
        return calculateCapacity()
    }
    public func estimateCapacity(this @local?): Int64 {
        return calculateCapacity()
    }

    /**
     * Calculate capacity (to be overridden by subclasses)
     */
    protected func calculateCapacity(): Int64
    protected func calculateCapacity(this @local?): Int64

    /**
     * Invalidate cached capacity when structure changes
     */
    protected func invalidateCapacity(): Unit {
        return
    }
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
}
