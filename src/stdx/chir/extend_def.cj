/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.chir

/**
 * Represents an extend definition in the CHIR representation.
 *
 * An ExtendDef extends a type (class, struct, or enum) with additional functionality
 * through interface implementations. It can have generic type parameters.
 */
public class ExtendDef <: CustomTypeDef {
    internal var _extendedType: Type
    internal var _genericTypeParams = ArrayList<GenericType>()

    /**
     * Gets the type that is being extended.
     * @type { Type }
     */
    public prop extendedType: Type {
        get() {
            return _extendedType
        }
    }

    internal init(identifier: String, pkgName: String, extendedType: Type, genericTypeParams: ArrayList<GenericType>) {
        super(CustomDefKind.Extend, identifier, String.empty, pkgName)
        this._extendedType = extendedType
        this._genericTypeParams = genericTypeParams
        this._hashCode = calculateHashCode()
    }

    protected override func printComment(): String {
        let extraStr = "id: " + identifier
        if (let str <- super.printComment() && !str.isEmpty()) {
            return str + ", " + extraStr
        }
        return "// " + extraStr
    }

    protected override func printTitle(): String {
        var typeStr = extendedType.toString()
        if (extendedType.isCustomType()) {
            typeStr = GLOBAL_SYMBOL_PREFIX + typeStr
        }
        var result = "extend" + typeVecToString("<", _genericTypeParams.toArray(), ">") + " " + typeStr
        if (!implementedInterfaceTypes.isEmpty()) {
            result += " <: "
            var superTypeStr = ArrayList<String>()
            for (superType in implementedInterfaceTypes) {
                superTypeStr.add(superType.toString())
            }
            result += String.join(superTypeStr.toArray(), delimiter: " & ")
        }
        return result
    }
}
