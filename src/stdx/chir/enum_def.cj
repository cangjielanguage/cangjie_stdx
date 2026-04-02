/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.chir

/**
 * Represents information about an enum constructor.
 *
 * An enum constructor is a variant of an enum type with optional parameters.
 */
public class EnumCtorInfo <: ToString {
    internal var _annotations = AnnoInfo()
    internal let _funcType: FuncType
    internal let _identifier: String
    internal let _outerDef: EnumDef
    internal let _srcCodeName: String

    /**
     * Gets or sets annotations attached to this enum constructor.
     * Getter returns all instances; setter replaces the whole list.
     * @type { Array<Annotation> }
     */
    public mut prop annotations: Array<Annotation> {
        get() {
            return _annotations._annoClasses.toArray()
        }
        set(v) {
            _annotations._annoClasses = ArrayList<Annotation>.of(v)
        }
    }

    /**
     * Gets the function type of this enum constructor.
     *
     * The function type represents the parameter types and return type (which is the enum type).
     * @type { FuncType }
     */
    public prop funcType: FuncType {
        get() {
            return _funcType
        }
    }

    /**
     * Gets the internal identifier, a globally unique name.
     * @type { String }
     */
    public prop identifier: String {
        get() {
            return _identifier
        }
    }

    /**
     * Gets the source code identifier of this enum constructor.
     * @type { String }
     */
    public prop srcCodeName: String {
        get() {
            return _srcCodeName
        }
    }

    internal init(srcCodeName: String, identifier: String, funcType: FuncType, outerDef: EnumDef) {
        this._srcCodeName = srcCodeName
        this._identifier = identifier
        this._funcType = funcType
        this._outerDef = outerDef
    }

    /**
     * Converts this EnumCtorInfo to its string representation.
     * @return A string representation in the format "ConstructorName(param1, param2, ...)".
     */
    public func toString(): String {
        return enumCtorInfoToString(this, 0)
    }
}

/**
 * Represents an enum definition in the CHIR representation.
 *
 * An EnumDef extends CustomTypeDef and provides methods to access enum-specific
 * information such as whether it is exhaustive and its constructors.
 */
public class EnumDef <: CustomTypeDef & Equatable<EnumDef> {
    internal var _ctors = ArrayList<EnumCtorInfo>()
    private var _nonExhaustive: Bool

    /**
     * Gets all enum constructors (variants) in declaration order.
     * @type { Array<EnumCtorInfo> }
     */
    public prop constructors: Array<EnumCtorInfo> {
        get() {
            return _ctors.toArray()
        }
    }

    /**
     * Gets the EnumType associated with this enum definition.
     * @type { EnumType }
     */
    public prop enumType: EnumType {
        get() {
            return (_type.getOrThrow() as EnumType).getOrThrow()
        }
    }

    /**
     * Checks if this enum is exhaustive.
     *
     * An exhaustive enum is one where all possible values are known at compile time.
     * @type { Bool }
     */
    public prop isExhaustive: Bool {
        get() {
            return !_nonExhaustive
        }
    }

    internal init(identifier: String, srcName: String, pkgName: String, nonExhaustive: Bool) {
        super(CustomDefKind.Enum, identifier, srcName, pkgName)
        this._nonExhaustive = nonExhaustive
        this._hashCode = calculateHashCode()
    }

    /**
     * Appends a new enum constructor with the given parameter types.
     * @param identifier Globally unique name.
     * @param name Source-level constructor / variant name.
     * @param argTypes Parameter types of the variant; empty for nullary variants.
     * @return The created EnumCtorInfo.
     */
    public func appendEnumCtorInfo(identifier: String, name: String, argTypes!: Array<Type> = Array<Type>()): EnumCtorInfo {
        let funcType = FuncType.get(argTypes, enumType)
        let ctor = EnumCtorInfo(name, identifier, funcType, this)
        _ctors.add(ctor)
        return ctor
    }

    protected override func printMemberVars(indent: UInt64): String {
        let result = StringBuilder()
        for (ctor in _ctors) {
            result.append("\n")
            result.append(enumCtorInfoToString(ctor, indent))
            result.append(" |")
        }
        if (_nonExhaustive) {
            result.append("\n")
            result.append(indentToString(indent))
            result.append("...")
        }
        return result.toString()
    }

    /**
     * Checks if this EnumDef is equal to another EnumDef.
     * @param other The EnumDef to compare with.
     * @return true if the definitions are equal, false otherwise.
     */
    public operator func==(other: EnumDef): Bool {
        return isSameDef(other)
    }
}
