/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.chir

import std.collection.*
import std.deriving.*
import stdx.chir.toStringMacro.*

/**
 * Enumeration of all type kinds in the type system.
 *
 * This enum represents the different categories of types that can exist
 * in the Cangjie type system, including primitive types, composite types,
 * and special types.
 */
@Derive[Equatable]
@CHIREnumToString
internal enum TypeKind {
    | Invalid
    | `Int8`
    | `Int16`
    | `Int32`
    | `Int64`
    | `IntNative`
    | `UInt8`
    | `UInt16`
    | `UInt32`
    | `UInt64`
    | `UIntNative`
    | `Float16`
    | `Float32`
    | `Float64`
    | `Bool`
    | `Rune`
    | `Unit`
    | `Nothing`
    | CPointer
    | CString
    | ClassLike
    | Enum
    | Struct
    | Tuple
    | RawArray
    | `VArray`
    | Generic
    | Ref
    | Box
    | `This`
    | Func

    /**
     * Checks if this type kind is a C type.
     * @return true if the type kind is a C type, false otherwise.
     */
    internal func isCType(): Bool {
        match (this) {
            case `Int8` | `Int16` | `Int32` | `Int64` | `IntNative` |
                `UInt8` | `UInt16` | `UInt32` | `UInt64` | `UIntNative` |
                `Float16` | `Float32` | `Float64` |
                `Bool` | `Rune` | `Unit` | CPointer | CString => true
            case _ => false
        }
    }

    internal func toUInt(): UInt32 {
        match (this) {
            case Invalid =>       0
            case `Int8` =>        1
            case `Int16` =>       2
            case `Int32` =>       3
            case `Int64` =>       4
            case `IntNative` =>   5
            case `UInt8` =>       6
            case `UInt16` =>      7
            case `UInt32` =>      8
            case `UInt64` =>      9
            case `UIntNative` => 10
            case `Float16` =>    11
            case `Float32` =>    12
            case `Float64` =>    13
            case `Bool` =>       14
            case `Rune` =>       15
            case `Unit` =>       16
            case `Nothing` =>    17
            case CPointer =>     18
            case CString =>      19
            case ClassLike =>    20
            case Enum =>         21
            case Struct =>       22
            case Tuple =>        23
            case RawArray =>     24
            case `VArray` =>     25
            case Generic =>      26
            case Ref =>          27
            case Box =>          28
            case `This` =>       29
            case Func =>         30
        }
    }
}

/**
 * Abstract base class representing a type in the type system.
 *
 * This class provides the foundation for all types in Cangjie, including
 * primitive types, composite types, and special types. It implements
 * equality comparison, hashing, and string conversion.
 */
sealed abstract class Type <: ToString & Hashable & Equatable<Type> {
    internal var _hashCode: Int64 = 0
    internal let _kind: TypeKind
    internal let _typeArgs: ArrayList<Type>

    /**
     * Gets the qualified name of this type.
     * @type { String }
     */
    public prop qualifiedName: String {
        get() {
            match (this) {
                case t: RawArrayType =>
                    return "RawArray<" + t.elementType.qualifiedName + ">"
                case t: RefType =>
                    return t.baseType.qualifiedName
                case t: VArrayType =>
                    return "VArray<" + t.elementType.qualifiedName + "," + t.size.toString() + ">"
                case t: CPointerType =>
                    return "CPointer<" + t.elementType.qualifiedName + ">"
                case t: TupleType =>
                    let elementTypeStr = String.join(t.elementTypes.map({ ty => ty.qualifiedName }).toArray(), delimiter: ",")
                    return "Tuple<" + elementTypeStr + ">"
                case t: CustomType =>
                    return qualifiedNameOfCustomType(t)
                case t: FuncType =>
                    let paramTypeStr = String.join(t.paramTypes.map({ ty => ty.qualifiedName }).toArray(), delimiter: ",")
                    let retType = t.returnType.qualifiedName
                    return "(" + paramTypeStr + ")->" + retType
                case t: GenericType =>
                    return t.srcCodeName
                case t: BoxType =>
                    return "Box<" + t.baseType.qualifiedName + ">"
                case _ =>
                    return toString()
            }
        }
    }

    /**
     * Gets the type arguments of this type.
     * @type { Array<Type> }
     */
    public prop typeArgs: Array<Type> {
        get() {
            return _typeArgs.toArray()
        }
    }

    internal init(kind: TypeKind) {
        this._kind = kind
        this._typeArgs = ArrayList<Type>()
    }

    internal init(kind: TypeKind, args: ArrayList<Type>) {
        this._kind = kind
        this._typeArgs = args
    }

    /**
     * Prints the string representation of this type to standard output.
     */
    public func dump(): Unit {
        println(toString())
    }

    /**
     * Gets the hash code of this type.
     * @return The hash code as an Int64.
     */
    public func hashCode(): Int64 {
        return _hashCode
    }

    /**
     * Performs the public behavior of `isAnyTypeInStd`.
     * @return The `Bool` result.
     */
    public func isAnyTypeInStd(): Bool {
        if (_kind != TypeKind.ClassLike) {
            return false
        }
        return (this as ClassLikeType).getOrThrow().classLikeDef.defIsExpected(CORE_PACKAGE_NAME, ANY_NAME_IN_STD)
    }

    /**
     * Checks if this type is the boolean type.
     * @return true if the type is Bool, false otherwise.
     */
    public func isBoolType(): Bool {
        return _kind == TypeKind.`Bool`
    }

    /**
     * Performs the public behavior of `isBoxRefTypeOf`.
     * @param other The `other` parameter.
     * @return The `Bool` result.
     */
    public func isBoxRefTypeOf(other: Type): Bool {
        if (!this.isRefType()) {
            return false
        }
        let boxType = (this as RefType).getOrThrow().baseType
        if (!boxType.isBoxType()) {
            return false
        }
        let baseType = (boxType as BoxType).getOrThrow().baseType
        return baseType == other
    }

    /**
     * Checks if this type is a box type.
     * @return true if the type is a box type, false otherwise.
     */
    public func isBoxType(): Bool {
        return _kind == TypeKind.Box
    }

    /**
     * Checks if this type is a builtin type.
     * @return true if the type is a builtin type, false otherwise.
     */
    public func isBuiltinType(): Bool {
        return _kind == TypeKind.`Int8` || _kind == TypeKind.`Int16` || _kind == TypeKind.`Int32` || _kind == TypeKind.`Int64` ||
            _kind == TypeKind.`IntNative` || _kind == TypeKind.`UInt8` || _kind == TypeKind.`UInt16` || _kind == TypeKind.`UInt32` ||
            _kind == TypeKind.`UInt64` || _kind == TypeKind.`UIntNative` || _kind == TypeKind.`Float16` || _kind == TypeKind.`Float32` ||
            _kind == TypeKind.`Float64` || _kind == TypeKind.`Bool` || _kind == TypeKind.`Rune` || _kind == TypeKind.`Unit` ||
            _kind == TypeKind.`Nothing` || _kind == TypeKind.RawArray || _kind == TypeKind.`VArray` || _kind == TypeKind.CPointer ||
            _kind == TypeKind.CString
    }

    /**
     * Checks if this type is a C function type.
     * @return true if the type is a C function type, false otherwise.
     */
    public func isCFuncType(): Bool {
        if (!isFuncType()) {
            return false
        }
        return (this as FuncType).getOrThrow().isCFunc
    }

    /**
     * Checks if this type is a C pointer type.
     * @return true if the type is a C pointer type, false otherwise.
     */
    public func isCPointerType(): Bool {
        return _kind == TypeKind.CPointer
    }

    /**
     * Checks if this type is a C string type.
     * @return true if the type is a C string type, false otherwise.
     */
    public func isCStringType(): Bool {
        return _kind == TypeKind.CString
    }

    /**
     * Performs the public behavior of `isCTypeInStd`.
     * @return The `Bool` result.
     */
    public func isCTypeInStd(): Bool {
        if (_kind != TypeKind.ClassLike) {
            return false
        }
        return (this as ClassLikeType).getOrThrow().classLikeDef.defIsExpected(CORE_PACKAGE_NAME, CTYPE_NAME_IN_STD)
    }

    /**
     * Checks if this type is a class like type.
     * @return true if the type is a class like type, false otherwise.
     */
    public func isClassLikeType(): Bool {
        return _kind == TypeKind.ClassLike
    }

    /**
     * Performs the public behavior of `isClosureBaseType`.
     * @return The `Bool` result.
     */
    public func isClosureBaseType(): Bool {
        if (!isClosureType()) {
            return false
        }
        return (this as ClassLikeType).getOrThrow().classLikeDef.isAbstract()
    }

    /**
     * Performs the public behavior of `isClosureGenericBaseType`.
     * @return The `Bool` result.
     */
    public func isClosureGenericBaseType(): Bool {
        return isClosureBaseType() && !typeArgs.isEmpty()
    }

    /**
     * Performs the public behavior of `isClosureInstBaseType`.
     * @return The `Bool` result.
     */
    public func isClosureInstBaseType(): Bool {
        return isClosureBaseType() && typeArgs.isEmpty()
    }

    /**
     * Performs the public behavior of `isClosureType`.
     * @return The `Bool` result.
     */
    public func isClosureType(): Bool {
        if (_kind != TypeKind.ClassLike) {
            return false
        }
        return (this as ClassLikeType).getOrThrow().classLikeDef.getAnno<IsAutoEnvClass, Bool>()
    }

    /**
     * Checks if this type is a custom type (class, enum, or struct).
     * @return true if the type is a custom type, false otherwise.
     */
    public func isCustomType(): Bool {
        return isClassLikeType() || isEnumType() || isStructType()
    }

    /**
     * Checks if this type is an enum type.
     * @return true if the type is an enum type, false otherwise.
     */
    public func isEnumType(): Bool {
        return _kind == TypeKind.Enum
    }

    /**
     * Performs the public behavior of `isEqualOrInstantiatedTypeOf`.
     * @param genericRelatedType The `genericRelatedType` parameter.
     * @param visited The `visited ` parameter.
     * @return The `Bool` result.
     */
    public func isEqualOrInstantiatedTypeOf(genericRelatedType: Type, visited !: ArrayList<(Type, Type)> = ArrayList<(Type, Type)>()): Bool {
        if (this == genericRelatedType) {
            return true
        }
        let (success, instMap) = genericRelatedType.calculateGeneric2InstTypeMap(this)
        if (!success) {
            return false
        }
        for ((genericType, instType) in instMap) {
            if (instType.isGenericType()) {
                return false
            }
            if (!instType.satisfyGenericConstraints(genericType, instMap, visited: visited)) {
                return false
            }
        }
        return true
    }

    /**
     * Performs the public behavior of `isEqualOrSubTypeOf`.
     * @param parent The `parent` parameter.
     * @param visited The `visited ` parameter.
     * @return The `Bool` result.
     */
    public func isEqualOrSubTypeOf(parent: Type, visited !: ArrayList<(Type, Type)> = ArrayList<(Type, Type)>()): Bool {
        if (this == parent) {
            return true
        }
        /**
         *  there may be an unresolvable inheritance relationship:
         *  interface I<T> {}
         *  abstract class C<T> {}
         *  extend<T> C<T> <: I<T> where T <: I<T> {}
         *  class D <: C<D> {}
         *  main() {0}
         *
         *  if you want to know if class D is sub type of I<D>, that will be a disaster, because
         *  parent type of class D is C<D>, and in `extend<T> C<T> <: I<T>`, interface I is class C's parent type,
         *  so you only need to know if `C<D> <: I<D>` satisfy generic constraints which `T <: I<T>`, then you need to
         *  compute if the `T` can be class D, that means you have to know if class D is sub type of I<D>, tail bites head.
         *  so we need to check if the sub type and parent type have been visited, if visited, we don't think they have a
         *  parent-child relationship and Sema does the same
         */
        for (i in visited) {
            if (i == (this, parent)) {
                return false
            }
        }
        visited.add((this, parent))
        if (this.isRefType() && parent.isRefType()) {
            let subBaseType = (this as RefType).getOrThrow().baseType
            let parentBaseType = (parent as RefType).getOrThrow().baseType
            return subBaseType.isEqualOrSubTypeOf(parentBaseType, visited: visited)
        }
        let subDeref = this.stripAllRefs()
        let parentDeref = parent.stripAllRefs()
        // we can't think class-A and class-A& is equal
        if ((this.isRefType() || parent.isRefType()) && subDeref == parentDeref) {
            return false
        }
        // Nothing type is all types' sub type, Any type is all types' parent type
        if (subDeref.isNothingType() || parentDeref.isAnyTypeInStd()) {
            return true
        }
        // if parent type is generic type, that means it can be any type, even if it has upper bounds
        if (parentDeref.isGenericType()) {
            return false
        }
        if (parentDeref.isCTypeInStd()) {
            return this.satisfyCType()
        }
        if (subDeref.isGenericType()) {
            let genericType = (subDeref as GenericType).getOrThrow()
            if (genericType.upperBounds.isEmpty()) {
                return false
            }
            for (upperBound in genericType.upperBounds) {
                if (!upperBound.stripAllRefs().isEqualOrSubTypeOf(parentDeref, visited: visited)) {
                    return false
                }
            }
            return true
        }
        if (subDeref.isTupleType()) {
            if (!parentDeref.isTupleType()) {
                return false
            }
            return tupleTypeIsEqualOrSubTypeOf((subDeref as TupleType).getOrThrow(), (parentDeref as TupleType).getOrThrow(), visited)
        }
        if (subDeref.isFuncType()) {
            if (!parentDeref.isFuncType()) {
                return false
            }
            return funcTypeIsEqualOrSubTypeOf((subDeref as FuncType).getOrThrow(), (parentDeref as FuncType).getOrThrow(), visited)
        }
        if (subDeref.isClosureType()) {
            if (!parentDeref.isClosureType()) {
                return false
            }
            return closureTypeIsEqualOrSubTypeOf((subDeref as ClassLikeType).getOrThrow(), (parentDeref as ClassLikeType).getOrThrow(), visited)
        }
        var allParentTypes = Array<ClassLikeType>()
        if (let Some(bt) <- (this as BuiltinType)) {
            allParentTypes = bt.getSuperTypesRecusively(visited: visited)
        } else if (let Some(ct) <- (this as CustomType)) {
            allParentTypes = ct.getSuperTypesRecusively(visited: visited)
        }
        for (parentType in allParentTypes) {
            if (parentDeref == parentType) {
                return true
            }
        }
        return false
    }

    /**
     * Checks if this type is a floating-point type.
     * @return true if the type is Float16, Float32, or Float64, false otherwise.
     */
    public func isFloatType(): Bool {
        return _kind == TypeKind.`Float16` || _kind == TypeKind.`Float32` || _kind == TypeKind.`Float64`
    }

    /**
     * Checks if this type is a function type.
     * @return true if the type is a function type, false otherwise.
     */
    public func isFuncType(): Bool {
        return _kind == TypeKind.Func
    }

    /**
     * Performs the public behavior of `isGenericRelated`.
     * @return The `Bool` result.
     */
    public func isGenericRelated(): Bool {
        if (isGenericType()) {
            return true
        }
        for (arg in _typeArgs) {
            if (arg.isGenericRelated()) {
                return true
            }
        }
        return false
    }

    /**
     * Checks if this type is a generic type.
     * @return true if the type is a generic type, false otherwise.
     */
    public func isGenericType(): Bool {
        return _kind == TypeKind.Generic
    }

    /**
     * Checks if this type is an integer type (signed or unsigned).
     * @return true if the type is any integer type, false otherwise.
     */
    public func isIntType(): Bool {
        let kindId = this._kind.toUInt()
        return kindId >= TypeKind.`Int8`.toUInt() && kindId <= TypeKind.`UIntNative`.toUInt()
    }

    /**
     * Checks if this type is the nothing type.
     * @return true if the type is Nothing, false otherwise.
     */
    public func isNothingType(): Bool {
        return _kind == TypeKind.`Nothing`
    }

    /**
     * Checks if this type is a numeric type (integer or floating-point).
     * @return true if the type is numeric, false otherwise.
     */
    public func isNumericType(): Bool {
        return isFloatType() || isIntType()
    }

    /**
     * Checks if this type is a primitive type.
     * @return true if the type is primitive (Int, Float, Bool, Rune, Unit, or Nothing), false otherwise.
     */
    public func isPrimitiveType(): Bool {
        let kindId = this._kind.toUInt()
        return kindId >= TypeKind.`Int8`.toUInt() && kindId <= TypeKind.`Nothing`.toUInt()
    }

    /**
     * Checks if this type is a raw array type.
     * @return true if the type is a raw array type, false otherwise.
     */
    public func isRawArrayType(): Bool {
        return _kind == TypeKind.RawArray
    }

    /**
     * Checks if this type is a reference type.
     * @return true if the type is a reference type, false otherwise.
     */
    public func isRefType(): Bool {
        return _kind == TypeKind.Ref
    }

    /**
     * Performs the public behavior of `isReferenceType`.
     * @return The `Bool` result.
     */
    public func isReferenceType(): Bool {
        return isClassLikeType() || isRawArrayType() || isBoxType() || isThisType()
    }

    /**
     * Checks if this type is the rune type.
     * @return true if the type is Rune, false otherwise.
     */
    public func isRuneType(): Bool {
        return _kind == TypeKind.`Rune`
    }

    /**
     * Checks if this type is a signed integer type.
     * @return true if the type is a signed integer type, false otherwise.
     */
    public func isSignedIntType(): Bool {
        let kindId = this._kind.toUInt()
        return kindId >= TypeKind.`Int8`.toUInt() && kindId <= TypeKind.`IntNative`.toUInt()
    }

    /**
     * Checks if this type is a struct type.
     * @return true if the type is a struct type, false otherwise.
     */
    public func isStructType(): Bool {
        return _kind == TypeKind.Struct
    }

    /**
     * Checks if this type is a This type.
     * @return true if the type is a This type, false otherwise.
     */
    public func isThisType(): Bool {
        return _kind == TypeKind.`This`
    }

    /**
     * Checks if this type is a tuple type.
     * @return true if the type is a tuple type, false otherwise.
     */
    public func isTupleType(): Bool {
        return _kind == TypeKind.Tuple
    }

    /**
     * Checks if this type is the unit type.
     * @return true if the type is Unit, false otherwise.
     */
    public func isUnitType(): Bool {
        return _kind == TypeKind.`Unit`
    }

    /**
     * Checks if this type is an unsigned integer type.
     * @return true if the type is an unsigned integer type, false otherwise.
     */
    public func isUnsignedIntType(): Bool {
        let kindId = this._kind.toUInt()
        return kindId >= TypeKind.`UInt8`.toUInt() && kindId <= TypeKind.`UIntNative`.toUInt()
    }

    /**
     * Checks if this type is a VArray type.
     * @return true if the type is a VArray type, false otherwise.
     */
    public func isVArrayType(): Bool {
        return _kind == TypeKind.`VArray`
    }

    /**
     * Performs the public behavior of `isValueType`.
     * @return The `Bool` result.
     */
    public func isValueType(): Bool {
        return isPrimitiveType() || isEnumType() || isTupleType() ||
            isStructType() || isVArrayType() || isCPointerType() ||
            isCStringType() || isFuncType()
    }

    /**
     * Performs the public behavior of `satisfyCType`.
     * @return The `Bool` result.
     */
    public func satisfyCType(): Bool {
        if (_kind.isCType()) {
            return true
        }
        if (let Some(s) <- (this as StructType)) {
            return s.structDef.isCStruct
        }
        if (let Some(va) <- (this as VArrayType)) {
            return va.elementType.satisfyCType()
        }
        if (this.isCFuncType()) {
            return true
        }
        return false
    }

    /**
     * Performs the public behavior of `satisfyGenericConstraints`.
     * @param gType The `gType` parameter.
     * @param instMap The `instMap` parameter.
     * @param visited The `visited ` parameter.
     * @return The `Bool` result.
     */
    public func satisfyGenericConstraints(gType: GenericType, instMap: HashMap<GenericType, Type>, visited !: ArrayList<(Type, Type)> = ArrayList<(Type, Type)>()): Bool {
        for (upperBound in gType.upperBounds) {
            let instType = getInstType(upperBound, instMap)
            if (!this.isEqualOrSubTypeOf(instType, visited: visited)) {
                return false
            }
        }
        return true
    }

    /**
     * Strips all reference wrappers from this type.
     *
     * Recursively removes all Ref type wrappers until a non-reference type is reached.
     * @return The base type after removing all reference wrappers.
     */
    public func stripAllRefs(): Type {
        var baseTy: Type = this
        while (baseTy.isRefType()) {
            baseTy = baseTy._typeArgs[0]
        }
        return baseTy
    }

    /**
     * Converts this type to its string representation.
     * @return A string representation of the type.
     */
    public open func toString(): String {
        return _kind.toString()
    }

    internal func calculateGeneric2InstTypeMap(instType: Type): (Bool, HashMap<GenericType, Type>) {
        var result: HashMap<GenericType, Type> = HashMap<GenericType, Type>()
        if (!calculateGeneric2InstTypeMapImpl(instType, result)) {
            return (false, HashMap<GenericType, Type>())
        }
        return (true, result)
    }

    internal func calculateGeneric2InstTypeMapImpl(instType: Type, result: HashMap<GenericType, Type>): Bool {
        if (this == instType) {
            return true
        }
        if (this.isGenericType()) {
            let genericType = (this as GenericType).getOrThrow()
            if (let Some(r) <- result.get(genericType)) {
                return r == instType
            } else {
                result.add(genericType, instType)
                return true
            }
        }
        if (!this.hasSameTypeKindWith(instType)) {
            return false
        }
        if (this.isCustomType()) {
            let thisCustomType = (this as CustomType).getOrThrow()
            let instCustomType = (instType as CustomType).getOrThrow()
            if (thisCustomType.def != instCustomType.def) {
                return false
            }
        }
        let thisTypeArgs = this.typeArgs
        let instTypeArgs = instType.typeArgs
        if (thisTypeArgs.size != instTypeArgs.size) {
            return false
        }
        for (i in 0..thisTypeArgs.size) {
            if (!thisTypeArgs[i].calculateGeneric2InstTypeMapImpl(instTypeArgs[i], result)) {
                return false
            }
        }
        return true
    }

    internal func hasSameTypeKindAndArgs(other: Type): Bool {
        return this._kind == other._kind && this._typeArgs == other._typeArgs
    }

    internal func hasSameTypeKindWith(other: Type): Bool {
        return this._kind == other._kind
    }

    internal func setHashCode(): Unit {
        _hashCode = toString().hashCode()
    }

    private func qualifiedNameOfCustomType(t: CustomType): String {
        let packageName = t.def.packageName.replace("::", "/")
        let defName = t.def.srcCodeName
        if (defName.isEmpty()) {
            return packageName + ":" + t.def.identifierWithoutPrefix
        }
        return packageName + ":" + defName
    }

    /**
     * Checks if this type is equal to another type.
     * @param other The type to compare with.
     * @return true if the types have the same kind and type arguments, false otherwise.
     */
    public operator func ==(other: Type): Bool {
        if (other.isBuiltinType() && this.isBuiltinType()) {
            return (this as BuiltinType).getOrThrow() == (other as BuiltinType).getOrThrow()
        } else if (other.isCustomType() && this.isCustomType()) {
            return (this as CustomType).getOrThrow() == (other as CustomType).getOrThrow()
        } else if (other.isFuncType() && this.isFuncType()) {
            return (this as FuncType).getOrThrow() == (other as FuncType).getOrThrow()
        } else if (other.isGenericType() && this.isGenericType()) {
            return (this as GenericType).getOrThrow() == (other as GenericType).getOrThrow()
        } else if (other.isBoxType() && this.isBoxType()) {
            return (this as BoxType).getOrThrow() == (other as BoxType).getOrThrow()
        } else if (other.isRefType() && this.isRefType()) {
            return (this as RefType).getOrThrow() == (other as RefType).getOrThrow()
        } else if (other.isTupleType() && this.isTupleType()) {
            return (this as TupleType).getOrThrow() == (other as TupleType).getOrThrow()
        } else if (other.isThisType() && this.isThisType()) {
            return (this as ThisType).getOrThrow() == (other as ThisType).getOrThrow()
        }
        return hasSameTypeKindAndArgs(other)
    }
}

/**
 * Base class for built-in primitive and special types that can carry extend blocks.
 *
 * Builtin types may attach ExtendDef nodes (e.g. for synthesized extends) like custom types.
 */
sealed abstract class BuiltinType <: Type & Equatable<BuiltinType> {
    internal let _extends = ArrayList<ExtendDef>()

    internal init(kind: TypeKind) {
        super(kind)
    }

    internal init(kind: TypeKind, typeArgs: ArrayList<Type>) {
        super(kind, typeArgs)
    }

    /**
     * Attaches an extend definition to this built-in type (e.g. plugin-generated extends).
     * @param extendDef The extend block to register.
     */
    public func addExtend(extendDef: ExtendDef): Unit {
        _extends.add(extendDef)
    }

    /**
     * Collects all class-like super types reachable from extend-implemented interfaces.
     * @param visited Optional cache of (from, to) pairs to avoid cycles.
     * @return All instantiated parent ClassLikeType nodes.
     */
    public func getSuperTypesRecusively(visited !: ArrayList<(Type, Type)> = ArrayList<(Type, Type)>()): Array<ClassLikeType> {
        var result: ArrayList<ClassLikeType> = ArrayList<ClassLikeType>()
        for (exDef in getExtendDefs()) {
            for (p in exDef.implementedInterfaceTypes) {
                getAllInstantiatedParentTypes(p, result, visited)
            }
        }
        return result.toArray()
    }

    protected open func getExtendDefs(): Array<ExtendDef> {
        return _extends.toArray()
    }

    /**
     * Equality for built-in types: same kind and same type arguments.
     */
    public operator func ==(other: BuiltinType): Bool {
        if (other.isBoolType() && this.isBoolType()) {
            return (this as BoolType).getOrThrow() == (other as BoolType).getOrThrow()
        } else if (other.isCPointerType() && this.isCPointerType()) {
            return (this as CPointerType).getOrThrow() == (other as CPointerType).getOrThrow()
        } else if (other.isCStringType() && this.isCStringType()) {
            return (this as CStringType).getOrThrow() == (other as CStringType).getOrThrow()
        } else if (other.isNothingType() && this.isNothingType()) {
            return (this as NothingType).getOrThrow() == (other as NothingType).getOrThrow()
        } else if (other.isNumericType() && this.isNumericType()) {
            return (this as NumericType).getOrThrow() == (other as NumericType).getOrThrow()
        } else if (other.isRawArrayType() && this.isRawArrayType()) {
            return (this as RawArrayType).getOrThrow() == (other as RawArrayType).getOrThrow()
        } else if (other.isRuneType() && this.isRuneType()) {
            return (this as RuneType).getOrThrow() == (other as RuneType).getOrThrow()
        } else if (other.isUnitType() && this.isUnitType()) {
            return (this as UnitType).getOrThrow() == (other as UnitType).getOrThrow()
        } else if (other.isVArrayType() && this.isVArrayType()) {
            return (this as VArrayType).getOrThrow() == (other as VArrayType).getOrThrow()
        }
        return hasSameTypeKindAndArgs(other)
    }
}

/**
 * Represents the Bool type in the type system.
 *
 * This is a singleton type representing the Bool type.
 */
public class BoolType <: BuiltinType & Equatable<BoolType> {
    private static let BOOL_TYPE = BoolType()

    private init() {
        super(TypeKind.`Bool`)
        setHashCode()
    }

    /**
     * Gets the singleton instance of BoolType.
     * @return The BoolType instance.
     */
    public static func get(): BoolType {
        return BOOL_TYPE
    }

    /**
     * Checks if this BoolType is equal to another BoolType.
     * @param _ The other BoolType to compare with (unused, always returns true).
     * @return Always returns true since all BoolType instances are equal.
     */
    public operator func ==(_: BoolType): Bool {
        return true
    }
}

/**
 * Represents a C pointer type in the type system.
 *
 * This type represents a pointer to a C type, used for interoperability with C code.
 * The class maintains a cache of all CPointer types to ensure uniqueness.
 */
public class CPointerType <: BuiltinType & Equatable<CPointerType> {
    //                          elementType -> CPointerType
    private static var CACHE = HashMap<Type, CPointerType>()

    /**
     * Gets the element type that this CPointerType points to.
     * @type { Type }
     */
    public prop elementType: Type {
        get() {
            return _typeArgs[0]
        }
    }

    private init(elementType: Type) {
        super(TypeKind.CPointer, ArrayList<Type>([elementType]))
        setHashCode()
    }

    /**
     * Gets or creates a CPointerType for the given element type.
     *
     * This method ensures that only one CPointerType instance exists for each element type.
     * @param elementType The type that the pointer points to.
     * @return The CPointerType instance for the given element type.
     */
    public static func get(elementType: Type): CPointerType {
        if (let Some(cPointer) <- CACHE.get(elementType)) {
            return cPointer
        }
        let newCPointerType = CPointerType(elementType)
        CACHE[elementType] = newCPointerType
        return newCPointerType
    }

    /**
     * Converts this CPointerType to its string representation.
     * @return A string representation of the CPointerType (CPointer<elementType>).
     */
    public func toString(): String {
        let result = StringBuilder()
        result.append("CPointer<")
        result.append(elementType.toString())
        result.append(">")
        return result.toString()
    }

    protected override func getExtendDefs(): Array<ExtendDef> {
        var result: ArrayList<ExtendDef> = ArrayList<ExtendDef>()
        for ((_, cpType) in CACHE) {
            if (this.isEqualOrInstantiatedTypeOf(cpType)) {
                result.add(all: cpType._extends)
            }
        }
        return result.toArray()
    }

    /**
     * Checks if this CPointerType is equal to another CPointerType.
     * @param other The CPointerType to compare with.
     * @return true if the types are equal, false otherwise.
     */
    public operator func ==(other: CPointerType): Bool {
        return hasSameTypeKindAndArgs(other)
    }
}

/**
 * Represents the C string type in the type system.
 *
 * This type represents a C-style null-terminated string, used for interoperability with C code.
 * This is a singleton type representing the built-in C string type.
 */
public class CStringType <: BuiltinType & Equatable<CStringType> {
    private static let C_STRING_TYPE = CStringType()

    private init() {
        super(TypeKind.CString)
        setHashCode()
    }

    /**
     * Gets the singleton instance of CStringType.
     * @return The CStringType instance.
     */
    public static func get(): CStringType {
        return C_STRING_TYPE
    }

    /**
     * Checks if this CStringType is equal to another CStringType.
     * @param _ The other CStringType to compare with (unused, always returns true).
     * @return Always returns true since all CStringType instances are equal.
     */
    public operator func ==(_: CStringType): Bool {
        return true
    }
}

/**
 * Represents the nothing type in the type system.
 *
 * This type represents the bottom type, used for expressions that never return.
 */
public class NothingType <: BuiltinType & Equatable<NothingType> {
    private static let NOTHING_TYPE = NothingType()

    private init() {
        super(TypeKind.`Nothing`)
        setHashCode()
    }

    /**
     * Gets the singleton instance of NothingType.
     * @return The NothingType instance.
     */
    public static func get(): NothingType {
        return NOTHING_TYPE
    }

    /**
     * Checks if this NothingType is equal to another NothingType.
     * @param _ The other NothingType to compare with (unused, always returns true).
     * @return Always returns true since all NothingType instances are equal.
     */
    public operator func ==(_: NothingType): Bool {
        return true
    }
}

/**
 * Abstract base class for numeric types.
 *
 * This class represents types that are numeric, including both
 * integer and floating-point types.
 */
sealed abstract class NumericType <: BuiltinType & Equatable<NumericType> {
    internal init(kind: TypeKind) {
        super(kind)
    }

    /**
     * Checks if this numeric type is equal to another numeric type.
     * @param other The numeric type to compare with.
     * @return true if the types are equal, false otherwise.
     */
    public operator func ==(other: NumericType): Bool {
        if (other.isFloatType() && this.isFloatType()) {
            return (this as FloatType).getOrThrow() == (other as FloatType).getOrThrow()
        } else if (other.isIntType() && this.isIntType()) {
            return (this as IntType).getOrThrow() == (other as IntType).getOrThrow()
        }
        return hasSameTypeKindAndArgs(other)
    }
}

/**
 * Represents floating-point types in the type system.
 *
 * This class represents the three floating-point types: Float16, Float32, and Float64.
 */
public class FloatType <: NumericType & Equatable<FloatType> {
    private static let FLOAT16_TYPE = FloatType(TypeKind.`Float16`)
    private static let FLOAT32_TYPE = FloatType(TypeKind.`Float32`)
    private static let FLOAT64_TYPE = FloatType(TypeKind.`Float64`)

    private init(kind: TypeKind) {
        super(kind)
        setHashCode()
    }

    /**
     * Gets the Float16 type instance.
     * @return The Float16 type.
     */
    public static func getFloat16(): FloatType {
        return FLOAT16_TYPE
    }

    /**
     * Gets the Float32 type instance.
     * @return The Float32 type.
     */
    public static func getFloat32(): FloatType {
        return FLOAT32_TYPE
    }

    /**
     * Gets the Float64 type instance.
     * @return The Float64 type.
     */
    public static func getFloat64(): FloatType {
        return FLOAT64_TYPE
    }

    /**
     * Checks if this FloatType is equal to another FloatType.
     * @param other The FloatType to compare with.
     * @return true if the types are equal, false otherwise.
     */
    public operator func ==(other: FloatType): Bool {
        return other._kind == this._kind
    }
}

/**
 * Represents integer types in the type system.
 *
 * This class represents both signed and unsigned integer types of various sizes.
 */
public class IntType <: NumericType & Equatable<IntType> {
    private static let INT16_TYPE = IntType(TypeKind.`Int16`)
    private static let INT32_TYPE = IntType(TypeKind.`Int32`)
    private static let INT64_TYPE = IntType(TypeKind.`Int64`)
    private static let INT8_TYPE = IntType(TypeKind.`Int8`)
    private static let INT_NATIVE_TYPE = IntType(TypeKind.`IntNative`)
    private static let UINT16_TYPE = IntType(TypeKind.`UInt16`)
    private static let UINT32_TYPE = IntType(TypeKind.`UInt32`)
    private static let UINT64_TYPE = IntType(TypeKind.`UInt64`)
    private static let UINT8_TYPE = IntType(TypeKind.`UInt8`)
    private static let UINT_NATIVE_TYPE = IntType(TypeKind.`UIntNative`)

    private init(kind: TypeKind) {
        super(kind)
        setHashCode()
    }

    /**
     * Gets the Int16 type instance.
     * @return The Int16 type.
     */
    public static func getInt16(): IntType {
        return INT16_TYPE
    }

    /**
     * Gets the Int32 type instance.
     * @return The Int32 type.
     */
    public static func getInt32(): IntType {
        return INT32_TYPE
    }

    /**
     * Gets the Int64 type instance.
     * @return The Int64 type.
     */
    public static func getInt64(): IntType {
        return INT64_TYPE
    }

    /**
     * Gets the Int8 type instance.
     * @return The Int8 type.
     */
    public static func getInt8(): IntType {
        return INT8_TYPE
    }

    /**
     * Gets the IntNative type instance.
     * @return The IntNative type.
     */
    public static func getIntNative(): IntType {
        return INT_NATIVE_TYPE
    }

    /**
     * Gets the UInt16 type instance.
     * @return The UInt16 type.
     */
    public static func getUInt16(): IntType {
        return UINT16_TYPE
    }

    /**
     * Gets the UInt32 type instance.
     * @return The UInt32 type.
     */
    public static func getUInt32(): IntType {
        return UINT32_TYPE
    }

    /**
     * Gets the UInt64 type instance.
     * @return The UInt64 type.
     */
    public static func getUInt64(): IntType {
        return UINT64_TYPE
    }

    /**
     * Gets the UInt8 type instance.
     * @return The UInt8 type.
     */
    public static func getUInt8(): IntType {
        return UINT8_TYPE
    }

    /**
     * Gets the UIntNative type instance.
     * @return The UIntNative type.
     */
    public static func getUIntNative(): IntType {
        return UINT_NATIVE_TYPE
    }

    /**
     * Checks if this integer type is signed.
     * @return true if the type is signed, false if it is unsigned.
     */
    public func isSigned(): Bool {
        return isSignedIntType()
    }

    /**
     * Checks if this IntType is equal to another IntType.
     * @param other The IntType to compare with.
     * @return true if the types are equal, false otherwise.
     */
    public operator func ==(other: IntType): Bool {
        return this._kind == other._kind
    }
}

/**
 * Represents the rune type in the type system.
 *
 * This type represents a character type.
 */
public class RuneType <: BuiltinType & Equatable<RuneType> {
    private static let RUNE_TYPE = RuneType()

    private init() {
        super(TypeKind.`Rune`)
        setHashCode()
    }

    /**
     * Gets the singleton instance of RuneType.
     * @return The RuneType instance.
     */
    public static func get(): RuneType {
        return RUNE_TYPE
    }

    /**
     * Checks if this RuneType is equal to another RuneType.
     * @param _ The other RuneType to compare with (unused, always returns true).
     * @return Always returns true since all RuneType instances are equal.
     */
    public operator func ==(_: RuneType): Bool {
        return true
    }
}

/**
 * Represents the unit type in the type system.
 *
 * This type represents the absence of a meaningful value, similar to void in C.
 */
public class UnitType <: BuiltinType & Equatable<UnitType> {
    private static let UNIT_TYPE = UnitType()

    private init() {
        super(TypeKind.`Unit`)
        setHashCode()
    }

    /**
     * Gets the singleton instance of UnitType.
     * @return The UnitType instance.
     */
    public static func get(): UnitType {
        return UNIT_TYPE
    }

    /**
     * Checks if this UnitType is equal to another UnitType.
     * @param _ The other UnitType to compare with (unused, always returns true).
     * @return Always returns true since all UnitType instances are equal.
     */
    public operator func ==(_: UnitType): Bool {
        return true
    }
}

/**
 * Sentinel type used internally when a type placeholder is required before resolution.
 *
 * Not part of the public type surface for normal CHIR consumers; singleton via get().
 */
internal class InvalidType <: Type & Equatable<InvalidType> {
    private static let INVALID_TYPE = InvalidType()

    private init() {
        super(TypeKind.Invalid)
    }

    /**
     * Gets the singleton InvalidType instance.
     * @return The shared InvalidType.
     */
    public static func get(): InvalidType {
        return INVALID_TYPE
    }

    /**
     * All InvalidType instances compare equal.
     */
    public operator func ==(_: InvalidType): Bool {
        return true
    }
}

/**
 * Represents a reference type in the type system.
 *
 * This type wraps another type to represent a reference to that type.
 * The class maintains a cache of all reference types to ensure uniqueness.
 */
public class RefType <: Type & Equatable<RefType> {
    //                             baseType -> RefType
    private static var CACHE = HashMap<Type, RefType>()

    /**
     * Gets the base type that this reference type refers to.
     * @type { Type }
     */
    public prop baseType: Type {
        get() {
            return _typeArgs[0]
        }
    }

    private init(baseType: Type) {
        super(TypeKind.Ref, ArrayList<Type>([baseType]))
        setHashCode()
    }

    /**
     * Gets or creates a RefType for the given base type.
     *
     * This method ensures that only one RefType instance exists for each base type.
     * @param baseType The base type to create a reference to.
     * @return The RefType instance for the given base type.
     */
    public static func get(baseType: Type): RefType {
        if (let Some(refType) <- CACHE.get(baseType)) {
            return refType
        }
        let newRefType = RefType(baseType)
        CACHE[baseType] = newRefType
        return newRefType
    }

    /**
     * Converts this RefType to its string representation.
     * @return A string representation of the reference type (base type followed by '&').
     */
    public func toString(): String {
        let result = StringBuilder()
        result.append(baseType.toString())
        result.append("&")
        return result.toString()
    }

    /**
     * Checks if this RefType is equal to another RefType.
     * @param other The RefType to compare with.
     * @return true if the types are equal, false otherwise.
     */
    public operator func ==(other: RefType): Bool {
        return this._typeArgs[0] == other._typeArgs[0]
    }
}

/**
 * Represents a box type in the type system.
 *
 * This type wraps another type in a box, used for heap allocation.
 * The class maintains a cache of all box types to ensure uniqueness.
 */
public class BoxType <: Type & Equatable<BoxType> {
    //                             baseType -> BoxType
    private static var CACHE = HashMap<Type, BoxType>()

    /**
     * Gets the base type that this box type wraps.
     * @type { Type }
     */
    public prop baseType: Type {
        get() {
            return _typeArgs[0]
        }
    }

    private init(baseType: Type) {
        super(TypeKind.Box, ArrayList<Type>([baseType]))
        setHashCode()
    }

    /**
     * Gets or creates a BoxType for the given base type.
     *
     * This method ensures that only one BoxType instance exists for each base type.
     * @param baseType The base type to create a box for.
     * @return The BoxType instance for the given base type.
     */
    public static func get(baseType: Type): BoxType {
        if (let Some(boxType) <- CACHE.get(baseType)) {
            return boxType
        }
        let newBoxType = BoxType(baseType)
        CACHE[baseType] = newBoxType
        return newBoxType
    }

    /**
     * Converts this BoxType to its string representation.
     * @return A string representation of the box type (Box<baseType>).
     */
    public func toString(): String {
        let result = StringBuilder()
        result.append("Box<")
        result.append(baseType.toString())
        result.append(">")
        return result.toString()
    }

    /**
     * Checks if this BoxType is equal to another BoxType.
     * @param other The BoxType to compare with.
     * @return true if the types are equal, false otherwise.
     */
    public operator func ==(other: BoxType): Bool {
        return hasSameTypeKindAndArgs(other)
    }
}

/**
 * Represents a raw array type in the type system.
 *
 * This type represents a multi-dimensional raw array with a specified number of dimensions.
 * The class maintains a cache of all raw array types to ensure uniqueness.
 */
public class RawArrayType <: BuiltinType & Equatable<RawArrayType> {
    //                          element type -> (dims, RawArrayType)
    private static var CACHE = HashMap<Type, HashMap<UInt32, RawArrayType>>()
    internal let _dims: UInt32

    /**
     * Gets the number of dimensions of this raw array.
     * @type { UInt32 }
     */
    public prop dims: UInt32 {
        get() {
            return _dims
        }
    }

    /**
     * Gets the element type of this raw array.
     * @type { Type }
     */
    public prop elementType: Type {
        get() {
            return _typeArgs[0]
        }
    }

    private init(elementType: Type, dims: UInt32) {
        super(TypeKind.RawArray, ArrayList<Type>([elementType]))
        this._dims = dims
        setHashCode()
    }

    /**
     * Gets or creates a RawArrayType for the given element type and dimensions.
     *
     * This method ensures that only one RawArrayType instance exists for each element type and dimension combination.
     * @param elementType The element type of the array.
     * @param dims The number of dimensions.
     * @return The RawArrayType instance.
     */
    public static func get(elementType: Type, dims: UInt32): RawArrayType {
        if (let Some(rawArrayTypes) <- CACHE.get(elementType)) {
            if (let Some(rawArrayType) <- rawArrayTypes.get(dims)) {
                return rawArrayType
            } else {
                let newRawArrayType = RawArrayType(elementType, dims)
                rawArrayTypes[dims] = newRawArrayType
                return newRawArrayType
            }
        }
        let newRawArrayType = RawArrayType(elementType, dims)
        CACHE[elementType] = HashMap<UInt32, RawArrayType>((dims, newRawArrayType))
        return newRawArrayType
    }

    /**
     * Converts this RawArrayType to its string representation.
     * @return A string representation of the raw array type.
     */
    public func toString(): String {
        let result = StringBuilder()
        for (_ in 0..dims) {
            result.append("RawArray<")
        }
        result.append(elementType.toString())
        for (_ in 0..dims) {
            result.append(">")
        }
        return result.toString()
    }

    /**
     * Checks if this RawArrayType is equal to another RawArrayType.
     * @param other The RawArrayType to compare with.
     * @return true if the types are equal, false otherwise.
     */
    public operator func ==(other: RawArrayType): Bool {
        return hasSameTypeKindAndArgs(other) && this._dims == other._dims
    }
}

/**
 * Represents a VArray type in the type system.
 *
 * This type represents a variable-length array with a fixed size at compile time.
 * The class maintains a cache of all VArray types to ensure uniqueness.
 */
public class VArrayType <: BuiltinType & Equatable<VArrayType> {
    private static var CACHE = HashMap<Type, HashMap<Int64, VArrayType>>()
    internal let _size: Int64

    /**
     * Gets the element type of this VArray.
     * @type { Type }
     */
    public prop elementType: Type {
        get() {
            return _typeArgs[0]
        }
    }

    /**
     * Gets the size of this VArray.
     * @type { Int64 }
     */
    public prop size: Int64 {
        get() {
            return _size
        }
    }

    private init(elementType: Type, size: Int64) {
        super(TypeKind.`VArray`, ArrayList<Type>([elementType]))
        this._size = size
        setHashCode()
    }

    /**
     * Gets or creates a VArrayType for the given element type and size.
     *
     * This method ensures that only one VArrayType instance exists for each element type and size combination.
     * @param elementType The element type of the array.
     * @param size The size of the array.
     * @return The VArrayType instance.
     */
    public static func get(elementType: Type, size: Int64): VArrayType {
        if (let Some(vArrayTypes) <- CACHE.get(elementType)) {
            if (let Some(vArrayType) <- vArrayTypes.get(size)) {
                return vArrayType
            } else {
                let newVArrayType = VArrayType(elementType, size)
                vArrayTypes[size] = newVArrayType
                return newVArrayType
            }
        }
        let newVArrayType = VArrayType(elementType, size)
        CACHE[elementType] = HashMap<Int64, VArrayType>((size, newVArrayType))
        return newVArrayType
    }

    /**
     * Converts this VArrayType to its string representation.
     * @return A string representation of the VArray type (VArray<elementType, $size>).
     */
    public func toString(): String {
        let result = StringBuilder()
        result.append("VArray<")
        result.append(elementType.toString())
        result.append(", $")
        result.append(size.toString())
        result.append(">")
        return result.toString()
    }

    /**
     * Checks if this VArrayType is equal to another VArrayType.
     * @param other The VArrayType to compare with.
     * @return true if the types are equal, false otherwise.
     */
    public operator func ==(other: VArrayType): Bool {
        return hasSameTypeKindAndArgs(other) && this._size == other._size
    }
}

/**
 * Abstract base class for custom types (class, enum, struct).
 *
 * This class represents user-defined types in the type system.
 */
sealed abstract class CustomType <: Type & Equatable<CustomType> {
    internal var _def: CustomTypeDef

    /**
     * All instance member names in linearization order (superclass chain then this type).
     * @type { Array<String> }
     */
    public prop allMemberVarNames: Array<String> {
        get() {
            var result: ArrayList<String> = ArrayList<String>()
            if (isClassLikeType()) {
                let classLikeDef = (def as ClassLikeDef).getOrThrow()
                if (let Some(superClass) <- classLikeDef.superClass) {
                    result = ArrayList<String>.of(superClass.allMemberVarNames)
                }
            }
            for (memberVar in def.instanceVars) {
                result.add(memberVar.name)
            }
            return result.toArray()
        }
    }

    /**
     * Gets the definition of this custom type.
     * @type { CustomTypeDef }
     */
    public prop def: CustomTypeDef {
        get() {
            return _def
        }
    }

    /**
     * Gets the generic type arguments of this custom type.
     * @type { Array<Type> }
     */
    public prop genericTypeArgs: Array<Type> {
        get() {
            return _typeArgs.toArray()
        }
    }

    internal prop generic2InstTypeMap: HashMap<GenericType, Type> {
        get() {
            let genericTypeParams = def.genericTypeParams
            assert(genericTypeParams.size == genericTypeArgs.size, "Generic type params size mismatch")
            var replaceTable: HashMap<GenericType, Type> = HashMap<GenericType, Type>()
            for (i in 0..genericTypeParams.size) {
                let genericTypeParam = genericTypeParams[i]
                let genericTypeArg = genericTypeArgs[i]
                replaceTable.add(genericTypeParam, genericTypeArg)
            }
            return replaceTable
        }
    }

    internal init(kind: TypeKind, def: CustomTypeDef, genericTypeParams: ArrayList<Type>) {
        super(kind, genericTypeParams)
        this._def = def
    }

    /**
     * Extend definitions whose extended type matches this type or an instantiation of it.
     * @param visited Used when matching generic-related extended types.
     * @return Applicable ExtendDef nodes from the owning CustomTypeDef.
     */
    public func getExtendDefs(visited !: ArrayList<(Type, Type)> = ArrayList<(Type, Type)>()): Array<ExtendDef> {
        var result: ArrayList<ExtendDef> = ArrayList<ExtendDef>()
        for (exDef in def.extends) {
            if (this.isEqualOrInstantiatedTypeOf(exDef.extendedType, visited: visited)) {
                result.add(exDef)
            }
        }
        return result.toArray()
    }

    /**
     * Interface types implemented via extend blocks that apply to this instantiated type.
     * @param visited Cycle guard for recursive graph walks.
     * @return Instantiated interface ClassLikeType nodes from matching extends.
     */
    public func getExtendImplementedInterfaceTypes(visited !: ArrayList<(Type, Type)> = ArrayList<(Type, Type)>()): Array<ClassLikeType> {
        var result: ArrayList<ClassLikeType> = ArrayList<ClassLikeType>()
        for (exDef in getExtendDefs(visited: visited)) {
            let (success, instMap) = exDef.extendedType.calculateGeneric2InstTypeMap(this)
            assert(success, "Failed to calculate generic 2 inst type map")
            for (p in exDef.implementedInterfaceTypes) {
                let instType = (getInstType(p, instMap) as ClassLikeType).getOrThrow()
                result.add(instType)
            }
        }
        return result.toArray()
    }

    /**
     * All interfaces this type implements: from extends plus declared implementedInterfaceTypes on the def.
     * @param visited Cycle guard for recursive graph walks.
     * @return Combined list of instantiated ClassLikeType interfaces.
     */
    public func getImplementedInterfaceTypes(visited !: ArrayList<(Type, Type)> = ArrayList<(Type, Type)>()): Array<ClassLikeType> {
        var result = ArrayList<ClassLikeType>.of(this.getExtendImplementedInterfaceTypes(visited: visited))
        for (p in _def.implementedInterfaceTypes) {
            let instType = (getInstType(p, generic2InstTypeMap) as ClassLikeType).getOrThrow()
            result.add(instType)
        }
        return result.toArray()
    }

    /**
     * Member variable types with generic parameters replaced by this type's arguments.
     * @return Instantiated field types in the same order as allMemberVarNames.
     */
    public func getInstantiatedMemberVarTypes(): Array<Type> {
        var result: ArrayList<Type> = ArrayList<Type>()
        if (isClassLikeType()) {
            let cType = (this as ClassLikeType).getOrThrow()
            if (cType.hasSuperClassType()) {
                result = ArrayList<Type>.of(cType.getSuperClassType().getInstantiatedMemberVarTypes())
            }
        }
        for (memberVar in def.instanceVars) {
            result.add(getInstType(memberVar.ty, generic2InstTypeMap))
        }
        return result.toArray()
    }

    /**
     * Looks up the instantiated type of a member variable by name (searches from innermost shadowing outward).
     * @param name Field name in source.
     * @return The instantiated Type for that field.
     * @throws Exception if the name is not found.
     */
    public func getMemberVarInstantiatedType(name: String): Type {
        let memberVarInstTypes = getInstantiatedMemberVarTypes()
        let memberVarNames = allMemberVarNames
        assert(memberVarInstTypes.size == memberVarNames.size, "Member variable size mismatch")
        var index = memberVarNames.size - 1
        while (index >= 0) {
            if (memberVarNames[index] == name) {
                return memberVarInstTypes[index]
            }
            index -= 1
        }
        throw CHIRException("Member variable `" + name + "` not found in " + toString())
    }

    /**
     * All superclass and interface parents reachable from this custom type (recursive).
     * @param visited Cycle guard for recursive graph walks.
     * @return Every ClassLikeType ancestor or interface parent.
     */
    public func getSuperTypesRecusively(visited !: ArrayList<(Type, Type)> = ArrayList<(Type, Type)>()): Array<ClassLikeType> {
        var result: ArrayList<ClassLikeType> = ArrayList<ClassLikeType>()
        for (p in this.getImplementedInterfaceTypes(visited: visited)) {
            getAllInstantiatedParentTypes(p, result, visited)
        }
        if (let Some(c) <- (this as ClassLikeType) && c.hasSuperClassType()) {
            getAllInstantiatedParentTypes(c.getSuperClassType(), result, visited)
        }
        return result.toArray()
    }

    /**
     * Converts this CustomType to its string representation.
     * @return A string representation of the custom type.
     */
    public func toString(): String {
        let result = StringBuilder()
        result.append(this._kind.toString())
        result.append("-")
        result.append(_def.identifierWithoutPrefix)
        result.append(typeVecToString("<", genericTypeArgs, ">"))
        return result.toString()
    }

    /**
     * Checks if this CustomType is equal to another CustomType.
     * @param other The CustomType to compare with.
     * @return true if the types are equal, false otherwise.
     */
    public operator func ==(other: CustomType): Bool {
        return hasSameTypeKindAndArgs(other) && this._def == other._def
    }
}

/**
 * Represents a class type in the type system.
 *
 * This type represents a user-defined class with optional generic type parameters.
 * The class maintains a cache of all class types to ensure uniqueness.
 */
public class ClassLikeType <: CustomType & Equatable<ClassLikeType> {
    //                    def -> (generic type args signature -> ClassLikeType)
    private static var CACHE = HashMap<ClassLikeDef, HashMap<String, ClassLikeType>>()

    /**
     * Gets the ClassLikeDef associated with this class type.
     * @type { ClassLikeDef }
     */
    public prop classLikeDef: ClassLikeDef {
        get() {
            return (def as ClassLikeDef).getOrThrow()
        }
    }

    private init(def: ClassLikeDef, genericTypeParams: ArrayList<Type>) {
        super(TypeKind.ClassLike, def, genericTypeParams)
        setHashCode()
    }

    /**
     * Gets or creates a ClassLikeType for the given class definition and generic type parameters.
     *
     * This method ensures that only one ClassLikeType instance exists for each class definition and generic type parameter combination.
     * @param def The class definition.
     * @param genericTypeParams The generic type parameters.
     * @return The ClassLikeType instance.
     */
    public static func get(def: ClassLikeDef, genericTypeParams: Array<Type>): ClassLikeType {
        let key = typeVecToString("<", genericTypeParams, ">")
        if (let Some(classTypes) <- CACHE.get(def)) {
            if (let Some(classType) <- classTypes.get(key)) {
                return classType
            } else {
                let newClassType = ClassLikeType(def, ArrayList<Type>.of(genericTypeParams))
                classTypes[key] = newClassType
                return newClassType
            }
        }
        let newClassType = ClassLikeType(def, ArrayList<Type>.of(genericTypeParams))
        CACHE[def] = HashMap<String, ClassLikeType>((key, newClassType))
        return newClassType
    }

    /**
     * Gets the super class type of this class.
     * @return The super class type.
     */
    internal func getSuperClassType(): ClassLikeType {
        let res = getInstType(classLikeDef.superClass.getOrThrow(), generic2InstTypeMap)
        return (res as ClassLikeType).getOrThrow()
    }

    /**
     * Checks if this class type has a super class.
     * @return true if the class has a super class, false otherwise.
     */
    internal func hasSuperClassType(): Bool {
        return classLikeDef.superClass.isSome()
    }

    /**
     * Checks if this ClassLikeType is equal to another ClassLikeType.
     * @param other The ClassLikeType to compare with.
     * @return true if the types are equal, false otherwise.
     */
    public operator func ==(other: ClassLikeType): Bool {
        return hasSameTypeKindAndArgs(other) && this._def == other._def
    }
}

/**
 * Represents a struct type in the type system.
 *
 * This type represents a user-defined struct with optional generic type parameters.
 * The class maintains a cache of all struct types to ensure uniqueness.
 */
public class StructType <: CustomType & Equatable<StructType> {
    //                def -> (generic type args signature -> StructType)
    private static var CACHE = HashMap<StructDef, HashMap<String, StructType>>()

    /**
     * Gets the StructDef associated with this struct type.
     * @type { StructDef }
     */
    public prop structDef: StructDef {
        get() {
            return (def as StructDef).getOrThrow()
        }
    }

    private init(def: StructDef, genericTypeParams: ArrayList<Type>) {
        super(TypeKind.Struct, def, genericTypeParams)
        setHashCode()
    }

    /**
     * Gets or creates a StructType for the given struct definition and generic type parameters.
     *
     * This method ensures that only one StructType instance exists for each struct definition and generic type parameter combination.
     * @param def The struct definition.
     * @param genericTypeParams The generic type parameters.
     * @return The StructType instance.
     */
    public static func get(def: StructDef, genericTypeParams: Array<Type>): StructType {
        let key = typeVecToString("<", genericTypeParams, ">")
        if (let Some(structTypes) <- CACHE.get(def)) {
            if (let Some(structType) <- structTypes.get(key)) {
                return structType
            } else {
                let newStructType = StructType(def, ArrayList<Type>.of(genericTypeParams))
                structTypes[key] = newStructType
                return newStructType
            }
        }
        let newStructType = StructType(def, ArrayList<Type>.of(genericTypeParams))
        CACHE[def] = HashMap<String, StructType>((key, newStructType))
        return newStructType
    }

    /**
     * Checks if this StructType is equal to another StructType.
     * @param other The StructType to compare with.
     * @return true if the types are equal, false otherwise.
     */
    public operator func ==(other: StructType): Bool {
        return hasSameTypeKindAndArgs(other) && this._def == other._def
    }
}

/**
 * Represents an enum type in the type system.
 *
 * This type represents a user-defined enum with optional generic type parameters.
 * The class maintains a cache of all enum types to ensure uniqueness.
 */
public class EnumType <: CustomType & Equatable<EnumType> {
    //              def -> (generic type args signature -> EnumType)
    private static var CACHE = HashMap<EnumDef, HashMap<String, EnumType>>()

    /**
     * Gets the EnumDef associated with this enum type.
     * @type { EnumDef }
     */
    public prop enumDef: EnumDef {
        get() {
            return (def as EnumDef).getOrThrow()
        }
    }

    private init(def: EnumDef, genericTypeParams: ArrayList<Type>) {
        super(TypeKind.Enum, def, genericTypeParams)
        setHashCode()
    }

    /**
     * Gets or creates an EnumType for the given enum definition and generic type parameters.
     *
     * This method ensures that only one EnumType instance exists for each enum definition and generic type parameter combination.
     * @param def The enum definition.
     * @param genericTypeParams The generic type parameters.
     * @return The EnumType instance.
     */
    public static func get(def: EnumDef, genericTypeParams: Array<Type>): EnumType {
        let key = typeVecToString("<", genericTypeParams, ">")
        if (let Some(enumTypes) <- CACHE.get(def)) {
            if (let Some(enumType) <- enumTypes.get(key)) {
                return enumType
            } else {
                let newEnumType = EnumType(def, ArrayList<Type>.of(genericTypeParams))
                enumTypes[key] = newEnumType
                return newEnumType
            }
        }
        let newEnumType = EnumType(def, ArrayList<Type>.of(genericTypeParams))
        CACHE[def] = HashMap<String, EnumType>((key, newEnumType))
        return newEnumType
    }

    /**
     * Checks if this EnumType is equal to another EnumType.
     * @param other The EnumType to compare with.
     * @return true if the types are equal, false otherwise.
     */
    public operator func ==(other: EnumType): Bool {
        return hasSameTypeKindAndArgs(other) && this._def == other._def
    }
}

/**
 * Represents a function type in the type system.
 *
 * This type represents a function signature with parameter types and return type.
 * The class maintains a cache of all function types to ensure uniqueness.
 */
public class FuncType <: Type & Equatable<FuncType> {
    //                             signature -> FuncType
    private static var CACHE = HashMap<String, FuncType>()
    private let _hasVarArg: Bool
    private let _isCFunc: Bool

    /**
     * Checks if this function type has variable arguments.
     * @type { Bool }
     */
    public prop hasVarArg: Bool {
        get() {
            return _hasVarArg
        }
    }

    /**
     * Checks if this is a C function type.
     * @type { Bool }
     */
    public prop isCFunc: Bool {
        get() {
            return _isCFunc
        }
    }

    /**
     * Gets the parameter types of this function.
     * @type { Array<Type> }
     */
    public prop paramTypes: Array<Type> {
        get() {
            return _typeArgs[0..(_typeArgs.size - 1)].toArray()
        }
    }

    /**
     * Gets the return type of this function.
     * @type { Type }
     */
    public prop returnType: Type {
        get() {
            return _typeArgs.last.getOrThrow()
        }
    }

    private init(paramTypes: ArrayList<Type>, retType: Type, varArg: Bool, cFunc: Bool) {
        super(TypeKind.Func, paramTypes)
        this._hasVarArg = varArg
        this._isCFunc = cFunc
        _typeArgs.add(retType)
        setHashCode()
    }

    /**
     * Gets or creates a FuncType for the given parameter types and return type.
     *
     * This method ensures that only one FuncType instance exists for each function signature.
     * @param paramTypes The parameter types.
     * @param retType The return type.
     * @param varArg Whether the function has variable arguments (default: false).
     * @param cFunc Whether this is a C function (default: false).
     * @return The FuncType instance.
     */
    public static func get(paramTypes: Array<Type>, retType: Type, varArg!: Bool = false, cFunc!: Bool = false): FuncType {
        var key = typeVecToString("(", paramTypes, ")") + "->" + retType.toString()
        key += if (varArg) { "|1" } else { "|0" }
        key += if (cFunc)  { "|1" } else { "|0" }
        if (let Some(funcType) <- CACHE.get(key)) {
            return funcType
        }
        let newFuncType = FuncType(ArrayList<Type>.of(paramTypes), retType, varArg, cFunc)
        CACHE[key] = newFuncType
        return newFuncType
    }

    /**
     * Converts this FuncType to its string representation.
     * @return A string representation of the function type.
     */
    public func toString(): String {
        let result = StringBuilder()
        let suffix = if (_hasVarArg) {
            "...)"
        } else {
            ")"
        }
        var paramTypesStr = typeVecToString("(", paramTypes, suffix)
        if (paramTypesStr.isEmpty()) {
            paramTypesStr = "()"
        }
        if (_isCFunc) {
            result.append("CFunc<")
        }
        result.append(paramTypesStr)
        result.append(" -> ")
        result.append(returnType.toString())
        if (_isCFunc) {
            result.append(">")
        }
        return result.toString()
    }

    /**
     * Checks if this FuncType is equal to another FuncType.
     * @param other The FuncType to compare with.
     * @return true if the types are equal, false otherwise.
     */
    public operator func ==(other: FuncType): Bool {
        return hasSameTypeKindAndArgs(other) &&
            this._hasVarArg == other._hasVarArg &&
            this._isCFunc == other._isCFunc
    }
}

/**
 * Represents a generic type parameter in the type system.
 *
 * This type represents a generic type parameter with optional upper bounds.
 * The class maintains a cache of all generic types to ensure uniqueness.
 */
public class GenericType <: Type & Equatable<GenericType> {
    //                            identifier -> GenericType
    private static var CACHE = HashMap<String, GenericType>()
    internal let _identifier: String
    internal var _upperBounds: ArrayList<Type> = ArrayList<Type>()
    private let _srcCodeName: String

    /**
     * Gets the source code identifier of this generic type.
     * @type { String }
     */
    public prop srcCodeName: String {
        get() {
            return _srcCodeName
        }
    }

    /**
     * Gets or sets the upper bounds of this generic type.
     *
     * Upper bounds specify the types that this generic type parameter must be a subtype of.
     * @type { Array<Type> }
     * @throws IllegalArgumentException if the upper bound is a value type
     */
    public mut prop upperBounds: Array<Type> {
        get() {
            return _upperBounds.toArray()
        }
        set(v) {
            for (bound in v) {
                if (bound.stripAllRefs().isValueType()) {
                    throw IllegalArgumentException("Generic type upper bound should NOT be value type!")
                }
            }
            _upperBounds = ArrayList<Type>.of(v)
        }
    }

    private init(identifier: String, srcCodeName: String) {
        super(TypeKind.Generic)
        this._identifier = identifier
        this._srcCodeName = srcCodeName
        setHashCode()
    }

    /**
     * Gets or creates a GenericType for the given identifier.
     *
     * This method ensures that only one GenericType instance exists for each identifier.
     * @param identifier The internal identifier of the generic type.
     * @param srcCodeName The source code identifier of the generic type.
     * @return The GenericType instance.
     */
    public static func get(identifier: String, srcCodeName: String): GenericType {
        if (let Some(gType) <- CACHE.get(identifier)) {
            return gType
        }
        let newGType = GenericType(identifier, srcCodeName)
        CACHE[identifier] = newGType
        return newGType
    }

    /**
     * Converts this GenericType to its string representation.
     * @return A string representation of the generic type.
     */
    public func toString(): String {
        let result = StringBuilder()
        result.append(this._kind.toString())
        result.append("-")
        result.append(this._identifier)
        return result.toString()
    }

    /**
     * Checks if this GenericType is equal to another GenericType.
     * @param other The GenericType to compare with.
     * @return true if the types are equal, false otherwise.
     */
    public operator func ==(other: GenericType): Bool {
        return this._identifier == other._identifier &&
            this._srcCodeName == other.srcCodeName &&
            this._upperBounds == other._upperBounds
    }
}

/**
 * Represents the This type in the type system.
 *
 * This type represents the current instance type within a class or struct.
 * This is a singleton type.
 */
public class ThisType <: Type & Equatable<ThisType> {
    private static let THIS_TYPE = ThisType()

    private init() {
        super(TypeKind.`This`)
        setHashCode()
    }

    /**
     * Gets the singleton instance of ThisType.
     * @return The ThisType instance.
     */
    public static func get(): ThisType {
        return THIS_TYPE
    }

    /**
     * Checks if this ThisType is equal to another ThisType.
     * @param _ The other ThisType to compare with (unused, always returns true).
     * @return Always returns true since all ThisType instances are equal.
     */
    public operator func ==(_: ThisType): Bool {
        return true
    }
}

/**
 * Represents a tuple type in the type system.
 *
 * This type represents a tuple with multiple element types.
 * The class maintains a cache of all tuple types to ensure uniqueness.
 */
public class TupleType <: Type & Equatable<TupleType> {
    //                             signature -> TupleType
    private static var CACHE = HashMap<String, TupleType>()

    /**
     * Gets the element types of this tuple.
     * @type { Array<Type> }
     */
    public prop elementTypes: Array<Type> {
        get() {
            return _typeArgs.toArray()
        }
    }

    private init(elementType: ArrayList<Type>) {
        super(TypeKind.Tuple, elementType)
        setHashCode()
    }

    /**
     * Gets or creates a TupleType for the given element types.
     *
     * This method ensures that only one TupleType instance exists for each element type combination.
     * @param elementTypes The element types of the tuple.
     * @return The TupleType instance.
     */
    public static func get(elementTypes: Array<Type>): TupleType {
        let key = typeVecToString("(", elementTypes, ")")
        if (let Some(tupleType) <- CACHE.get(key)) {
            return tupleType
        }
        let newTupleType = TupleType(ArrayList<Type>.of(elementTypes))
        CACHE[key] = newTupleType
        return newTupleType
    }

    /**
     * Converts this TupleType to its string representation.
     * @return A string representation of the tuple type.
     */
    public func toString(): String {
        let result = StringBuilder()
        result.append(this._kind.toString())
        result.append(typeVecToString("(", elementTypes, ")"))
        return result.toString()
    }

    /**
     * Checks if this TupleType is equal to another TupleType.
     * @param other The TupleType to compare with.
     * @return true if the types are equal, false otherwise.
     */
    public operator func ==(other: TupleType): Bool {
        return hasSameTypeKindAndArgs(other)
    }
}

private func tupleTypeIsEqualOrSubTypeOf(subType: TupleType, parentType: TupleType, visited: ArrayList<(Type, Type)>): Bool {
    let subElementTypes = subType.elementTypes
    let parentElementTypes = parentType.elementTypes
    if (subElementTypes.size != parentElementTypes.size) {
        return false
    }
    for (i in 0..subElementTypes.size) {
        if (!subElementTypes[i].isEqualOrSubTypeOf(parentElementTypes[i], visited: visited)) {
            return false
        }
    }
    return true
}

private func funcTypeIsEqualOrSubTypeOf(subType: FuncType, parentType: FuncType, visited: ArrayList<(Type, Type)>): Bool {
    if (subType.hasVarArg != parentType.hasVarArg) {
        return false
    }
    if (subType.isCFunc != parentType.isCFunc) {
        return false
    }
    let subParamTypes = subType.paramTypes
    let parentParamTypes = parentType.paramTypes
    if (subParamTypes.size != parentParamTypes.size) {
        return false
    }
    for (i in 0..subParamTypes.size) {
        if (!parentParamTypes[i].isEqualOrSubTypeOf(subParamTypes[i], visited: visited)) {
            return false
        }
    }
    return subType.returnType.isEqualOrSubTypeOf(parentType.returnType, visited: visited)
}

private func getClosureGenericBaseType(closureType: ClassLikeType): ClassLikeType {
    if (closureType.isClosureGenericBaseType()) {
        return closureType
    }
    return getClosureGenericBaseType(closureType.getSuperClassType())
}

private func convertClosureType2FuncType(closureType: ClassLikeType): FuncType {
    let baseType = getClosureGenericBaseType(closureType)
    let typeArgs = baseType.genericTypeArgs
    let (paramTypes, returnType) = typeArgs.splitAt(typeArgs.size - 1)
    return FuncType.get(paramTypes, returnType[0])
}

private func closureTypeIsEqualOrSubTypeOf(subType: ClassLikeType, parentType: ClassLikeType, visited: ArrayList<(Type, Type)>): Bool {
    let subFuncType = convertClosureType2FuncType(subType)
    let parentFuncType = convertClosureType2FuncType(parentType)
    return funcTypeIsEqualOrSubTypeOf(subFuncType, parentFuncType, visited)
}
