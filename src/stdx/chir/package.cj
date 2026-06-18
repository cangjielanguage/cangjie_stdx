/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.chir

internal import std.collection.*
import std.deriving.*

/**
 * Represents the access level of a package or declaration.
 */
@Derive[Equatable]
public enum AccessLevel <: ToString {
    Internal
    | Protected
    | Public

    /**
     * Converts this AccessLevel to its string representation.
     * @return A string representation of the access level ("internal", "protected", or "public").
     */
    public func toString(): String {
        return match (this) {
            case Internal => "internal"
            case Protected => "protected"
            case Public => "public"
        }
    }
}

/**
 * Represents a package in the CHIR representation.
 *
 * A package contains classDefs, structDefs, enumDefs, and extendDefs. Imported
 * definitions are stored in the same lists and distinguished by the Imported attribute.
 * It also has an access level that controls the visibility of its contents.
 */
public class Package <: ToString {
    internal var _classDefs = ArrayList<ClassLikeDef>()
    internal var _enumDefs = ArrayList<EnumDef>()
    internal var _extendDefs = ArrayList<ExtendDef>()
    internal var _functions = ArrayList<Function>()
    internal var _globalVars = ArrayList<GlobalVar>()
    internal var _structDefs = ArrayList<StructDef>()
    internal var _packageInitFunc: ?Function = None
    internal var _packageLiteralInitFunc: ?Function = None
    private let _accessLevel: AccessLevel
    private let _name: String

    /**
     * Gets the access level of this package.
     * @type { AccessLevel }
     */
    public prop accessLevel: AccessLevel {
        get() {
            return _accessLevel
        }
    }

    /**
     * Gets all custom type definitions (classes, enums, extends, structs) in this package, including imported ones.
     * @type { Array<CustomTypeDef> }
     */
    public prop allCustomTypeDefs: Array<CustomTypeDef> {
        get() {
            return _classDefs.toArray().mapTo<CustomTypeDef>({ d => d })
                .concat(_enumDefs.toArray().mapTo<CustomTypeDef>({ d => d }))
                .concat(_extendDefs.toArray().mapTo<CustomTypeDef>({ d => d }))
                .concat(_structDefs.toArray().mapTo<CustomTypeDef>({ d => d }))
        }
    }

    /**
     * Gets global variable definitions in this package.
     * @type { Array<GlobalVar> }
     */
    public prop globalVars: Array<GlobalVar> {
        get() {
            return _globalVars.toArray()
        }
    }

    /**
     * Gets function definitions in this package.
     * @type { Array<Function> }
     */
    public prop functions: Array<Function> {
        get() {
            return _functions.toArray()
        }
    }

    /**
     * Gets class and interface definitions defined in this package.
     * @type { Array<ClassLikeDef> }
     */
    public prop classDefs: Array<ClassLikeDef> {
        get() {
            return filterClassDefs(imported: false)
        }
    }

    /**
     * Gets enum definitions defined in this package.
     * @type { Array<EnumDef> }
     */
    public prop enumDefs: Array<EnumDef> {
        get() {
            return filterEnumDefs(imported: false)
        }
    }

    /**
     * Gets extend definitions defined in this package.
     * @type { Array<ExtendDef> }
     */
    public prop extendDefs: Array<ExtendDef> {
        get() {
            return filterExtendDefs(imported: false)
        }
    }

    /**
     * Gets class or interface definitions imported into this package.
     * @type { Array<ClassLikeDef> }
     */
    public prop importedClassDefs: Array<ClassLikeDef> {
        get() {
            return filterClassDefs(imported: true)
        }
    }

    /**
     * Gets enum definitions imported into this package.
     * @type { Array<EnumDef> }
     */
    public prop importedEnumDefs: Array<EnumDef> {
        get() {
            return filterEnumDefs(imported: true)
        }
    }

    /**
     * Gets extend definitions imported into this package.
     * @type { Array<ExtendDef> }
     */
    public prop importedExtendDefs: Array<ExtendDef> {
        get() {
            return filterExtendDefs(imported: true)
        }
    }

    /**
     * Gets struct definitions imported into this package.
     * @type { Array<StructDef> }
     */
    public prop importedStructDefs: Array<StructDef> {
        get() {
            return filterStructDefs(imported: true)
        }
    }

    /**
     * Gets the logical package name.
     * @type { String }
     */
    public prop name: String {
        get() {
            return _name
        }
    }

    /**
     * Gets the package initialization function, when present.
     * @type { ?Function }
     */
    public prop packageInitFunc: ?Function {
        get() {
            return _packageInitFunc
        }
    }

    /**
     * Gets the package literal initialization function, when present.
     * @type { ?Function }
     */
    public prop packageLiteralInitFunc: ?Function {
        get() {
            return _packageLiteralInitFunc
        }
    }

    /**
     * Gets struct definitions defined in this package.
     * @type { Array<StructDef> }
     */
    public prop structDefs: Array<StructDef> {
        get() {
            return filterStructDefs(imported: false)
        }
    }

    /**
     * Creates a new Package instance.
     * @param name The name of the package.
     * @param accessLevel The access level of the package.
     */
    public init(name: String, accessLevel: AccessLevel) {
        this._name = name
        this._accessLevel = accessLevel
    }

    /**
     * Adds a new class or interface definition to this package.
     * @param identifier Globally unique name.
     * @param srcCodeName Name as written in source.
     * @param isClass true for class, false for interface.
     * @param genericTypeParams Generic type parameters; empty if non-generic.
     * @return The created ClassLikeDef.
     */
    public func addClass(identifier: String, srcCodeName: String, isClass: Bool, genericTypeParams!: Array<GenericType> = Array<GenericType>()): ClassLikeDef {
        let temp = createClassDef(identifier, srcCodeName, isClass, genericTypeParams)
        _classDefs.add(temp)
        return temp
    }

    /**
     * Adds a new enum definition to this package.
     * @param identifier Globally unique name.
     * @param srcCodeName Name as written in source.
     * @param isExhaustive true if the enum is exhaustive in source semantics.
     * @param genericTypeParams Generic type parameters; empty if non-generic.
     * @return The created EnumDef.
     */
    public func addEnum(identifier: String, srcCodeName: String, isExhaustive: Bool, genericTypeParams!: Array<GenericType> = Array<GenericType>()): EnumDef {
        let temp = createEnumDef(identifier, srcCodeName, isExhaustive, genericTypeParams)
        _enumDefs.add(temp)
        return temp
    }

    /**
     * Adds a new extend definition to this package.
     * @param identifier Globally unique name.
     * @param extendedType The type being extended.
     * @param genericTypeParams Generic parameters of the extend block; empty if non-generic.
     * @return The created ExtendDef.
     */
    public func addExtend(identifier: String, extendedType: Type, genericTypeParams!: Array<GenericType> = Array<GenericType>()): ExtendDef {
        let temp = createExtendDef(identifier, extendedType, genericTypeParams)
        _extendDefs.add(temp)
        return temp
    }

    /**
     * Adds a new function definition to this package.
     * @param ty The function type (parameter types and return type).
     * @param identifier Globally unique name.
     * @param srcCodeName Name as written in source.
     * @param packageName Declaring package name.
     * @return The created Function with parameters pre-populated from ty.
     */
    public func addFunction(ty: FuncType, identifier: String, srcCodeName: String, packageName: String): Function {
        let temp = Function(ty, GLOBAL_SYMBOL_PREFIX + identifier, srcCodeName, packageName)
        temp._attributes.setAttr(Attribute.PluginAdded, true)
        _functions.add(temp)
        for (paramTy in ty.paramTypes) {
            temp.appendParameter(paramTy)
        }
        return temp
    }

    /**
     * Adds a new global variable definition to this package.
     * @param ty The type of the global variable.
     * @param identifier Globally unique name.
     * @param srcCodeName Name as written in source.
     * @param packageName Declaring package name.
     * @return The created GlobalVar.
     */
    public func addGlobalVar(ty: Type, identifier: String, srcCodeName: String, packageName: String): GlobalVar {
        let temp = GlobalVar(ty, GLOBAL_SYMBOL_PREFIX + identifier, srcCodeName, packageName)
        temp._attributes.setAttr(Attribute.PluginAdded, true)
        _globalVars.add(temp)
        return temp
    }

    /**
     * Adds an imported class or interface definition.
     * @param identifier Globally unique name.
     * @param srcCodeName Name as written in source.
     * @param packageName Declaring package name of the imported symbol.
     * @param isClass true for class, false for interface.
     * @param genericTypeParams Generic type parameters; empty if non-generic.
     * @return The created ClassLikeDef marked as imported.
     */
    public func addImportedClass(identifier: String, srcCodeName: String, packageName: String, isClass: Bool, genericTypeParams!: Array<GenericType> = Array<GenericType>()): ClassLikeDef {
        let temp = createClassDef(identifier, srcCodeName, isClass, genericTypeParams)
        temp._packageName = packageName
        temp._attributes.setAttr(Attribute.Imported, true)
        _classDefs.add(temp)
        return temp
    }

    /**
     * Adds an imported enum definition.
     * @param identifier Globally unique name.
     * @param srcCodeName Name as written in source.
     * @param packageName Declaring package name of the imported symbol.
     * @param isExhaustive true if the enum is exhaustive in source semantics.
     * @param genericTypeParams Generic type parameters; empty if non-generic.
     * @return The created EnumDef marked as imported.
     */
    public func addImportedEnum(identifier: String, srcCodeName: String, packageName: String, isExhaustive: Bool, genericTypeParams!: Array<GenericType> = Array<GenericType>()): EnumDef {
        let temp = createEnumDef(identifier, srcCodeName, isExhaustive, genericTypeParams)
        temp._packageName = packageName
        temp._attributes.setAttr(Attribute.Imported, true)
        _enumDefs.add(temp)
        return temp
    }

    /**
     * Adds an imported extend definition.
     * @param identifier Globally unique name.
     * @param packageName Declaring package name of the imported extend.
     * @param extendedType The type being extended.
     * @param genericTypeParams Generic parameters of the extend block; empty if non-generic.
     * @return The created ExtendDef marked as imported.
     */
    public func addImportedExtend(identifier: String, packageName: String, extendedType: Type, genericTypeParams!: Array<GenericType> = Array<GenericType>()): ExtendDef {
        let temp = createExtendDef(identifier, extendedType, genericTypeParams)
        temp._packageName = packageName
        temp._attributes.setAttr(Attribute.Imported, true)
        _extendDefs.add(temp)
        return temp
    }

    /**
     * Adds an imported struct definition.
     * @param identifier Globally unique name.
     * @param srcCodeName Name as written in source.
     * @param packageName Declaring package name of the imported symbol.
     * @param genericTypeParams Generic type parameters; empty if non-generic.
     * @return The created StructDef marked as imported.
     */
    public func addImportedStruct(identifier: String, srcCodeName: String, packageName: String, genericTypeParams!: Array<GenericType> = Array<GenericType>()): StructDef {
        let temp = createStructDef(identifier, srcCodeName, genericTypeParams)
        temp._packageName = packageName
        temp._attributes.setAttr(Attribute.Imported, true)
        _structDefs.add(temp)
        return temp
    }

    /**
     * Adds a new struct definition to this package.
     * @param identifier Globally unique name.
     * @param srcCodeName Name as written in source.
     * @param genericTypeParams Generic type parameters; empty if non-generic.
     * @return The created StructDef.
     */
    public func addStruct(identifier: String, srcCodeName: String, genericTypeParams!: Array<GenericType> = Array<GenericType>()): StructDef {
        let temp = createStructDef(identifier, srcCodeName, genericTypeParams)
        _structDefs.add(temp)
        return temp
    }

    /**
     * Prints the string representation of this package to standard output.
     */
    public func dump(): Unit {
        println(toString())
    }

    /**
     * Looks up a class or interface definition by package and source name.
     * @param packageName Full package name where the type is declared.
     * @param srcCodeName Source-level type name.
     * @return The matching ClassLikeDef if found in imports or local defs, else None.
     */
    public func getSpecifiedClassDef(packageName: String, srcCodeName: String): ?ClassLikeDef {
        for (def in _classDefs) {
            if (def.packageName == packageName && def.srcCodeName == srcCodeName) {
                return def
            }
        }
        return None
    }

    /**
     * Looks up an enum definition by package and source name.
     * @param packageName Full package name where the enum is declared.
     * @param srcCodeName Source-level enum name.
     * @return The matching EnumDef if found, else None.
     */
    public func getSpecifiedEnumDef(packageName: String, srcCodeName: String): ?EnumDef {
        for (def in _enumDefs) {
            if (def.packageName == packageName && def.srcCodeName == srcCodeName) {
                return def
            }
        }
        return None
    }

    public func getSpecifiedFunction(mangledName: String): ?Function {
        for (f in _functions) {
            if (f.identifierWithoutPrefix == mangledName) {
                return f
            }
        }
        return None
    }

    /**
     * Looks up a struct definition by package and source name.
     * @param packageName Full package name where the struct is declared.
     * @param srcCodeName Source-level struct name.
     * @return The matching StructDef if found, else None.
     */
    public func getSpecifiedStructDef(packageName: String, srcCodeName: String): ?StructDef {
        for (def in _structDefs) {
            if (def.packageName == packageName && def.srcCodeName == srcCodeName) {
                return def
            }
        }
        return None
    }

    /**
     * Converts this Package to its string representation.
     *
     * The string includes package name, access level, imported declarations,
     * and locally defined types (classDefs, structDefs, enumDefs, and extendDefs).
     * @return A string representation of the package.
     */
    public func toString(): String {
        let result = StringBuilder()
        result.append("package: ${name}\n")
        result.append("packageAccessLevel: ${accessLevel}\n")
        result.append("\n")

        for (d in allCustomTypeDefs) {
            result.append(d.toString())
            result.append("\n\n")
        }
        for (gv in _globalVars) {
            result.append(gv.toString())
            result.append("\n\n")
        }
        for (f in _functions) {
            result.append(f.toString())
            result.append("\n\n")
        }
        return result.toString()
    }

    private func createClassDef(identifier: String, srcCodeName: String, isClass: Bool, genericTypeParams: Array<GenericType>): ClassLikeDef {
        let temp = ClassLikeDef(GLOBAL_SYMBOL_PREFIX + identifier, srcCodeName, _name, isClass)
        if (!genericTypeParams.isEmpty()) {
            temp._attributes.setAttr(Attribute.Generic, true)
        }
        let ty = ClassLikeType.get(temp, Array<Type>(genericTypeParams.size, { i => genericTypeParams[i] }))
        temp._type = ty
        temp._attributes.setAttr(Attribute.PluginAdded, true)
        return temp
    }

    private func createEnumDef(identifier: String, srcCodeName: String, isExhaustive: Bool, genericTypeParams: Array<GenericType>): EnumDef {
        let temp = EnumDef(GLOBAL_SYMBOL_PREFIX + identifier, srcCodeName, _name, !isExhaustive)
        if (!genericTypeParams.isEmpty()) {
            temp._attributes.setAttr(Attribute.Generic, true)
        }
        let ty = EnumType.get(temp, Array<Type>(genericTypeParams.size, { i => genericTypeParams[i] }))
        temp._type = ty
        temp._attributes.setAttr(Attribute.PluginAdded, true)
        return temp
    }

    private func createExtendDef(identifier: String, extendedType: Type, genericTypeParams: Array<GenericType>): ExtendDef {
        let temp = ExtendDef(GLOBAL_SYMBOL_PREFIX + identifier, _name, extendedType, ArrayList<GenericType>.of(genericTypeParams))
        if (!genericTypeParams.isEmpty()) {
            temp._attributes.setAttr(Attribute.Generic, true)
        }
        temp._attributes.setAttr(Attribute.PluginAdded, true)
        if (let Some(v) <- (extendedType as BuiltinType)) {
            v._extends.add(temp)
        } else if (let Some(v) <- (extendedType as CustomType)) {
            v._def._extends.add(temp)
        }
        return temp
    }

    private func createStructDef(identifier: String, srcCodeName: String, genericTypeParams: Array<GenericType>): StructDef {
        let temp = StructDef(GLOBAL_SYMBOL_PREFIX + identifier, srcCodeName, _name)
        if (!genericTypeParams.isEmpty()) {
            temp._attributes.setAttr(Attribute.Generic, true)
        }
        let ty = StructType.get(temp, Array<Type>(genericTypeParams.size, { i => genericTypeParams[i] }))
        temp._type = ty
        temp._attributes.setAttr(Attribute.PluginAdded, true)
        return temp
    }

    private func filterClassDefs(imported!: Bool): Array<ClassLikeDef> {
        let result = ArrayList<ClassLikeDef>()
        for (def in _classDefs) {
            if (def.isImported() == imported) {
                result.add(def)
            }
        }
        return result.toArray()
    }

    private func filterEnumDefs(imported!: Bool): Array<EnumDef> {
        let result = ArrayList<EnumDef>()
        for (def in _enumDefs) {
            if (def.isImported() == imported) {
                result.add(def)
            }
        }
        return result.toArray()
    }

    private func filterExtendDefs(imported!: Bool): Array<ExtendDef> {
        let result = ArrayList<ExtendDef>()
        for (def in _extendDefs) {
            if (def.isImported() == imported) {
                result.add(def)
            }
        }
        return result.toArray()
    }

    private func filterStructDefs(imported!: Bool): Array<StructDef> {
        let result = ArrayList<StructDef>()
        for (def in _structDefs) {
            if (def.isImported() == imported) {
                result.add(def)
            }
        }
        return result.toArray()
    }
}
