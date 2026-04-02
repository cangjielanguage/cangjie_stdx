/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.chir

import std.deriving.*

@Derive[Equatable]
internal enum CustomDefKind <: ToString {
    ClassLike
    | Enum
    | Extend
    | Struct

    /**
     * Converts this custom definition kind to a short string tag.
     * @return One of "classLike", "enum", "extend", or "struct".
     */
    public func toString(): String {
        return match (this) {
            case ClassLike => "classLike"
            case Enum =>      "enum"
            case Extend =>    "extend"
            case Struct =>    "struct"
        }
    }
}

/**
 * Represents a member variable in a custom type definition.
 *
 * A MemberVar stores information about instance variables in classes, structs, or enums,
 * including their name, type, attributes, and debug location.
 */
public class MemberVar <: ToString {
    internal var _annoInfo: AnnoInfo = AnnoInfo()
    internal var _attributes: AttributeInfo = AttributeInfo()
    internal var _debugLocation: DebugLocation = DebugLocation.invalid()
    internal let _name: String
    internal let _outerDef: CustomTypeDef
    internal var _rawMangledName: String = String.empty
    internal let _type: Type

    /**
     * Gets or sets annotations on this member variable.
     * Getter returns instances for this member; setter replaces the whole list.
     * @type { Array<Annotation> }
     */
    public mut prop annotations: Array<Annotation> {
        get() {
            return _annoInfo._annoClasses.toArray()
        }
        set(v) {
            _annoInfo._annoClasses = ArrayList<Annotation>.of(v)
        }
    }

    /**
     * Gets the source location of this member variable in the original code.
     * @type { DebugLocation }
     */
    public prop location: DebugLocation {
        get() {
            return _debugLocation
        }
    }

    /**
     * Gets the name of this member variable.
     * @type { String }
     */
    public prop name: String {
        get() {
            return _name
        }
    }

    /**
     * Gets the outer definition that contains this member variable.
     * @type { CustomTypeDef }
     */
    public prop outerDef: CustomTypeDef {
        get() {
            return _outerDef
        }
    }

    /**
     * Gets the type of this member variable.
     * @type { Type }
     */
    public prop ty: Type {
        get() {
            return _type
        }
    }

    internal init(name: String, ty: Type, outerDef: CustomTypeDef) {
        this._name = name
        this._type = ty
        this._outerDef = outerDef
    }

    /**
     * Prints the string representation of this member variable to standard output.
     */
    public func dump(): Unit {
        println(toString())
    }

    /**
     * Checks if this member variable has INTERNAL access level.
     * @return true if INTERNAL attribute is set, false otherwise.
     */
    public func isInternal(): Bool {
        return _attributes.testAttr(Attribute.Internal)
    }

    /**
     * Checks if this member variable has PRIVATE access level.
     * @return true if PRIVATE attribute is set, false otherwise.
     */
    public func isPrivate(): Bool {
        return _attributes.testAttr(Attribute.Private)
    }

    /**
     * Checks if this member variable has PROTECTED access level.
     * @return true if PROTECTED attribute is set, false otherwise.
     */
    public func isProtected(): Bool {
        return _attributes.testAttr(Attribute.Protected)
    }

    /**
     * Checks if this member variable has PUBLIC access level.
     * @return true if PUBLIC attribute is set, false otherwise.
     */
    public func isPublic(): Bool {
        return _attributes.testAttr(Attribute.Public)
    }

    /**
     * Checks if this member variable is read-only.
     * @return true if the READONLY attribute is set, false otherwise.
     */
    public func isReadOnly(): Bool {
        return _attributes.testAttr(Attribute.ReadOnly)
    }

    /**
     * Sets the INTERNAL access level attribute for this member variable.
     */
    public func setInternal(): Unit {
        _attributes.setInternal()
    }

    /**
     * Sets the PRIVATE access level attribute for this member variable.
     */
    public func setPrivate(): Unit {
        _attributes.setPrivate()
    }

    /**
     * Sets the PROTECTED access level attribute for this member variable.
     */
    public func setProtected(): Unit {
        _attributes.setProtected()
    }

    /**
     * Sets the PUBLIC access level attribute for this member variable.
     */
    public func setPublic(): Unit {
        _attributes.setPublic()
    }

    /**
     * Sets the READONLY attribute for this member variable.
     * @param enable true to enable READONLY, false to disable.
     */
    public func setReadOnly(enable: Bool): Unit {
        _attributes.setAttr(Attribute.ReadOnly, enable)
    }

    /**
     * Converts this MemberVar to its string representation.
     * @return A string representation including attributes, name, type, and debug location.
     */
    public func toString(): String {
        let result = StringBuilder()
        result.append(_attributes.toString())
        result.append(if (isReadOnly()) { "let " } else { "var " })
        result.append(_name)
        result.append(": ")
        result.append(ty.toString())
        var comment = ArrayList<String>()
        if (_debugLocation.isValid()) {
            comment.add("loc: " + _debugLocation.toString())
        }
        if (!comment.isEmpty()) {
            result.append(" // ")
            result.append(String.join(comment.toArray(), delimiter: ", "))
        }
        return result.toString()
    }
}

/**
 * Abstract base class for custom type definitions (class, enum, struct, extend).
 *
 * CustomTypeDef provides common functionality for all user-defined types, including
 * generic type parameters, instance variables, implemented interfaces, and extends.
 */
sealed abstract class CustomTypeDef <: Base & Equatable<CustomTypeDef> & Hashable {
    internal var _extends = ArrayList<ExtendDef>()
    internal var _genericDecl : ?CustomTypeDef = None
    internal var _hashCode: Int64 = 0
    internal let _identifier: String
    internal var _implementedInterfaceTypes = ArrayList<ClassLikeType>()
    internal var _instanceVars = ArrayList<MemberVar>()
    internal let _kind: CustomDefKind
    internal var _methods = ArrayList<Function>()
    internal var _packageName: String
    internal let _srcCodeName: String
    internal var _staticVars = ArrayList<GlobalVar>()
    internal var _type : ?CustomType = None

    /**
     * Gets or sets the extend definitions nested under this type (e.g. inner extend blocks).
     * @type { Array<ExtendDef> }
     */
    public mut prop extends: Array<ExtendDef> {
        get() {
            return _extends.toArray()
        }
        set(v) {
            _extends = ArrayList<ExtendDef>.of(v)
        }
    }

    /**
     * Gets or sets the generic declaration paired with this monomorphic definition.
     *
     * Used when the same source name has both a generic template and a concrete instantiation;
     * constraints are documented on the setter.
     * @type { ?CustomTypeDef }
     */
    public mut prop genericDecl: ?CustomTypeDef {
        get() {
            return _genericDecl
        }
        set(v) {
            if (let Some(gDef) <- v) {
                assert(gDef._srcCodeName == _srcCodeName,
                    "genericDecl's srcCodeName must be the same as the current def's srcCodeName")
                assert(gDef._kind == _kind, "genericDecl's kind must be the same as the current def's kind")
                assert(gDef.isGeneric(), "genericDecl must be generic")
                assert(!this.isGeneric(), "current def can't be generic")
                // we don't check whether this.ty meet generic constraint of gDef.ty, it will cost much time
                // we will check it in ir checker
            }
            _genericDecl = v
        }
    }

    /**
     * Gets the generic type parameters of this custom type definition.
     *
     * If this type is not generic, returns an empty array.
     * @type { Array<GenericType> }
     */
    public prop genericTypeParams: Array<GenericType> {
        get() {
            if (!isGeneric()) {
                return Array<GenericType>()
            }
            if (_kind == CustomDefKind.Extend) {
                return (this as ExtendDef).getOrThrow()._genericTypeParams.toArray()
            } else {
                let typeArgs = _type.getOrThrow().typeArgs
                return Array<GenericType>(typeArgs.size, { i =>
                    (typeArgs[i] as GenericType).getOrThrow()
                })
            }
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
     * Gets or sets the list of interface types implemented by this custom type.
     * @type { Array<ClassLikeType> }
     */
    public mut prop implementedInterfaceTypes: Array<ClassLikeType> {
        get() {
            return _implementedInterfaceTypes.toArray()
        }
        set(v) {
            _implementedInterfaceTypes = ArrayList<ClassLikeType>.of(v)
        }
    }

    /**
     * Gets all instance (member) variables declared on this custom type.
     * @type { Array<MemberVar> }
     */
    public prop instanceVars: Array<MemberVar> {
        get() {
            return _instanceVars.toArray()
        }
    }

    /**
     * Gets the `methods` property.
     * @type { Array<Function> }
     */
    public prop methods: Array<Function> {
        get() {
            return _methods.toArray()
        }
    }

    /**
     * Gets the package name where this custom type is defined.
     * @type { String }
     */
    public prop packageName: String {
        get() {
            return _packageName
        }
    }

    /**
     * Gets the source code identifier of this custom type definition.
     * @type { String }
     */
    public prop srcCodeName: String {
        get() {
            return _srcCodeName
        }
    }

    /**
     * Gets the `staticVars` property.
     * @type { Array<GlobalVar> }
     */
    public prop staticVars: Array<GlobalVar> {
        get() {
            return _staticVars.toArray()
        }
    }

    /**
     * Gets the Type associated with this custom type definition.
     *
     * For ExtendDef, returns the extended type. For other types, returns the type itself.
     * @type { Type }
     */
    public prop ty: Type {
        get() {
            if (this.isExtend()) {
                return (this as ExtendDef).getOrThrow().extendedType
            }
            return _type.getOrThrow()
        }
    }

    internal prop identifierWithoutPrefix: String {
        get() {
            return _identifier.removePrefix(GLOBAL_SYMBOL_PREFIX)
        }
    }

    internal init(kind: CustomDefKind, identifier: String, srcName: String, pkgName: String) {
        this._kind = kind
        this._identifier = identifier
        this._srcCodeName = srcName
        this._packageName = pkgName
    }

    /**
     * Appends an instance member variable to this type definition and returns it.
     *
     * Used by plugins and tests to build CHIR; declaration order matches append order.
     * @param name Source-level member name.
     * @param ty Member type.
     * @return The created `MemberVar`.
     */
    public func appendInstanceMemberVar(name: String, ty: Type): MemberVar {
        let v = MemberVar(name, ty, this)
        _instanceVars.add(v)
        return v
    }

    /**
     * Performs the public behavior of `appendMethod`.
     * @param method The `method` parameter.
     * @return The `Unit` result.
     */
    public func appendMethod(method: Function): Unit {
        _methods.add(method)
        method._declaredParent = this
    }

    /**
     * Performs the public behavior of `appendStaticVar`.
     * @param staticVar The `staticVar` parameter.
     * @return The `Unit` result.
     */
    public func appendStaticVar(staticVar: GlobalVar): Unit {
        staticVar.setStatic(true)
        _staticVars.add(staticVar)
        staticVar._declaredParent = this
    }

    /**
     * Prints the string representation of this custom type definition to standard output.
     */
    public func dump(): Unit {
        println(toString())
    }

    /** visit super def and super def's all extend defs which meet the condition,
     *  and get their super classes or interfaces recursively, not including current def's extend defs
     *
     *  interface I1 {}
     *  interface I2 <: I1 {}
     *  class C1 <: I2
     *
     *  interface I3 {}
     *  interface I4 <: I3 {}
     *  extend C1 <: I4
     *
     *  interface I5 {}
     *  class C2 <: C1 & I5
     *
     *  interface I6 {}
     *  extend C2 <: I6 {}
     *
     *  so the result of `C2.getSuperTypesRecusively()` is {I1 ~ I5, C1}, not including I6
     *
     * @return super types, but we don't guarantee the order
     */
    public func getSuperTypesRecusively(): Array<ClassLikeType> {
        var result = ArrayList<ClassLikeType>()
        var visited = ArrayList<(Type, Type)>()
        for (interfaceType in _implementedInterfaceTypes) {
            getAllInstantiatedParentTypes(interfaceType, result, visited)
        }
        if (let Some(c) <- (this as ClassLikeDef)) {
            if (let Some(superClass) <- c.superClass) {
                getAllInstantiatedParentTypes(superClass, result, visited)
            }
        }
        return result.toArray()
    }

    /**
     * Gets the hash code of this custom type definition.
     * @return The hash code as an Int64.
     */
    public func hashCode(): Int64 {
        return _hashCode
    }

    /**
     * Checks whether this definition is abstract.
     * @return true if the Abstract attribute is set.
     */
    public func isAbstract(): Bool {
        return _attributes.testAttr(Attribute.Abstract)
    }

    /**
     * Checks if this definition represents a class (not an interface).
     * @return true if this is a class, false otherwise. Overridden in ClassLikeDef.
     */
    public func isClass(): Bool {
        if (_kind == CustomDefKind.ClassLike) {
            return (this as ClassLikeDef).getOrThrow()._isClass
        }
        return false
    }

    /**
     * Checks if this definition is class-like (class or interface).
     * @return true if the kind is ClassLike, false otherwise.
     */
    public func isClassLike(): Bool {
        return _kind == CustomDefKind.ClassLike
    }

    /**
     * Checks if this definition represents an enum.
     * @return true if the kind is Enum, false otherwise.
     */
    public func isEnum(): Bool {
        return _kind == CustomDefKind.Enum
    }

    /**
     * Checks if this definition represents an extend.
     * @return true if the kind is Extend, false otherwise.
     */
    public func isExtend(): Bool {
        return _kind == CustomDefKind.Extend
    }

    /**
     * Checks whether this definition is generic.
     * @return true if the Generic attribute is set.
     */
    public func isGeneric(): Bool {
        return _attributes.testAttr(Attribute.Generic)
    }

    /**
     * Checks whether this definition is marked as imported from another package.
     * @return true if the Imported attribute is set.
     */
    public func isImported(): Bool {
        return _attributes.testAttr(Attribute.Imported)
    }

    /**
     * Checks if this definition represents an interface (not a class).
     * @return true if this is an interface, false otherwise. Overridden in ClassLikeDef.
     */
    public func isInterface(): Bool {
        if (_kind == CustomDefKind.ClassLike) {
            return !(this as ClassLikeDef).getOrThrow()._isClass
        }
        return false
    }

    /**
     * Checks whether this definition has INTERNAL visibility.
     * @return true if the Internal attribute is set.
     */
    public func isInternal(): Bool {
        return _attributes.testAttr(Attribute.Internal)
    }

    /**
     * Checks whether this definition is open for subclassing / implementation (virtual or abstract).
     * @return true if Virtual or Abstract attribute is set.
     */
    public func isOpen(): Bool {
        return _attributes.testAttr(Attribute.Virtual) || _attributes.testAttr(Attribute.Abstract)
    }

    /**
     * Checks whether this definition has PRIVATE visibility.
     * @return true if the Private attribute is set.
     */
    public func isPrivate(): Bool {
        return _attributes.testAttr(Attribute.Private)
    }

    /**
     * Checks whether this definition has PROTECTED visibility.
     * @return true if the Protected attribute is set.
     */
    public func isProtected(): Bool {
        return _attributes.testAttr(Attribute.Protected)
    }

    /**
     * Checks whether this definition has PUBLIC visibility.
     * @return true if the Public attribute is set.
     */
    public func isPublic(): Bool {
        return _attributes.testAttr(Attribute.Public)
    }

    /**
     * Checks whether this definition is sealed.
     * @return true if the Sealed attribute is set.
     */
    public func isSealed(): Bool {
        return _attributes.testAttr(Attribute.Sealed)
    }

    /**
     * Checks if this definition represents a struct.
     * @return true if the kind is Struct, false otherwise.
     */
    public func isStruct(): Bool {
        return _kind == CustomDefKind.Struct
    }

    /**
     * Sets the INTERNAL visibility attribute on this custom type definition.
     */
    public func setInternal(): Unit {
        _attributes.setInternal()
    }

    /**
     * Sets the PRIVATE visibility attribute on this custom type definition.
     */
    public func setPrivate(): Unit {
        _attributes.setPrivate()
    }

    /**
     * Sets the PROTECTED visibility attribute on this custom type definition.
     */
    public func setProtected(): Unit {
        _attributes.setProtected()
    }

    /**
     * Sets the PUBLIC visibility attribute on this custom type definition.
     */
    public func setPublic(): Unit {
        _attributes.setPublic()
    }

    /**
     * Converts this CustomTypeDef to its string representation.
     *
     * The string includes attributes, title, generic constraints, member variables,
     * and extends.
     * @return A string representation of the custom type definition.
     */
    public open func toString(): String {
        /**
         *  [public][generic][...] class XXX {      // loc: xxx, genericDecl: xxx
         *  ^^^^^^^^^^^^^^ attr    ^^^^^^^^^ title  ^^^^^^^^^^^^^^^^^^ comment
         *      local var
         *      static var
         *      method
         *  }
         */
        let result = StringBuilder()
        result.append(_attributes.toString())
        result.append(printTitle())
        result.append(genericTypeParamsConstraintToString(genericTypeParams))
        result.append(" {")
        result.append(printComment())
        result.append(printMemberVars(INDENT_SPACE))
        for (method in _methods) {
            result.append("\n" + indentToString(INDENT_SPACE))
            result.append(method._attributes.toString() + "func " + method._identifier + ": " + method._type.toString())
        }
        for (exDef in _extends) {
            result.append("\n")
            result.append(indentToString(INDENT_SPACE))
            result.append("extend ")
            result.append(exDef._identifier)
        }
        result.append("\n}")
        return result.toString()
    }

    protected open func printComment(): String {
        var comment = ArrayList<String>()
        if (let str <- baseCommentToString() && !str.isEmpty()) {
            comment.add(str)
        }
        if (!_srcCodeName.isEmpty()) {
            comment.add("srcCodeName: " + _srcCodeName)
        }
        if (!_packageName.isEmpty()) {
            comment.add("packageName: " + _packageName)
        }
        if (let Some(gDecl) <- _genericDecl) {
            comment.add("genericDecl: " + gDecl.identifier)
        }
        if (!comment.isEmpty()) {
            return " // " + String.join(comment.toArray(), delimiter: ", ")
        }
        return String.empty
    }

    protected open func printMemberVars(indent: UInt64): String {
        let result = StringBuilder()
        var index = 0
        while (index < _instanceVars.size) {
            result.append("\n" + indentToString(indent))
            result.append(_instanceVars[index].toString())
            index += 1
        }
        index = 0
        while (index < _staticVars.size) {
            result.append("\n" + indentToString(indent))
            let staticVar = _staticVars[index]
            result.append("[static] " + staticVar._identifier + ": " + staticVar._type.toString())
            index += 1
        }
        return result.toString()
    }

    protected open func printTitle(): String {
        var kindStr = String.empty
        if (isInterface()) {
            kindStr = "interface"
        } else if (isClass()) {
            kindStr = "class"
        } else {
            kindStr = _kind.toString()
        }
        let result = StringBuilder()
        result.append(kindStr)
        result.append(" ")
        result.append(identifier)
        result.append(typeVecToString("<", genericTypeParams, ">"))
        if (!_implementedInterfaceTypes.isEmpty()) {
            result.append(" <: ")
            var superTypeStr = ArrayList<String>()
            for (superType in _implementedInterfaceTypes) {
                superTypeStr.add(superType.toString())
            }
            result.append(String.join(superTypeStr.toArray(), delimiter: " & "))
        }
        return result.toString()
    }

    internal func calculateHashCode(): Int64 {
        return identifier.hashCode()
    }

    internal func defIsExpected(packageName: String, srcCodeName: String): Bool {
        return this.packageName == packageName && this.srcCodeName == srcCodeName
    }

    internal func isSameDef(other: CustomTypeDef): Bool {
        return this.identifier == other.identifier
    }

    /**
     * Checks if this CustomTypeDef is equal to another CustomTypeDef.
     * @param other The CustomTypeDef to compare with.
     * @return true if the definitions are equal (same kind, identifier, source code identifier, and package name), false otherwise.
     */
    public operator func==(other: CustomTypeDef): Bool {
        return isSameDef(other)
    }
}
