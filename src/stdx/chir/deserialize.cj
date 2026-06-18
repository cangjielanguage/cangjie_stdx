/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.chir

import std.collection.*
import std.fs.*

/**
 * Deserializes a CHIR package from a contiguous FlatBuffers buffer.
 * @param root Pointer to the first serialized byte; must not be null.
 * @param length Byte length of the buffer.
 * @return The populated `Package` instance.
 * @exception CHIRException when `root` is null.
 */
public func deserializePackage(root: CPointer<UInt8>, length: Int64): Package {
    if (root.isNull()) {
        throw CHIRException("root is null in deserialize")
    }
    let pkgBuf = Array<UInt8>(length, {x: Int64 => unsafe { root.read(x) }})
    let pkgFormat = PackageFormat_CHIRPackage(pkgBuf, 0)
    return deserializePackage(pkgFormat)
}

private func deserializePackage(pkgFormat: PackageFormat_CHIRPackage): Package {
    let deserializer = CHIRDeserializerImpl(pkgFormat)
    deserializer.run()
    return deserializer.getPkg()
}

private func deserializePackageAccessLevel(accessLevel: PackageFormat_PackageAccessLevel): AccessLevel {
    return match (accessLevel) {
        case PackageFormat_PackageAccessLevel.PackageAccessLevel_INTERNAL => AccessLevel.Internal
        case PackageFormat_PackageAccessLevel.PackageAccessLevel_PROTECTED => AccessLevel.Protected
        case PackageFormat_PackageAccessLevel.PackageAccessLevel_PUBLIC => AccessLevel.Public
        case _ => throw CHIRException("invalid package access level")
    }
}

class CHIRDeserializerImpl {
    let pkgFormat: PackageFormat_CHIRPackage
    let pkg: Package
    let id2Type = HashMap<UInt32, Type>()
    let id2Value = HashMap<UInt32, Value>()
    let id2Expression = HashMap<UInt32, Expression>()
    let id2CustomTypeDef = HashMap<UInt32, CustomTypeDef>()
    let genericTypeConfig = ArrayList<(GenericType, PackageFormat_GenericType)>()

    init(pkgFormat: PackageFormat_CHIRPackage) {
        this.pkgFormat = pkgFormat
        let accessLevel = deserializePackageAccessLevel(pkgFormat.GetPkgAccessLevel())
        this.pkg = Package(pkgFormat.GetName(), accessLevel)
        let valuesSize = pkgFormat.GetValuesSize() + 1
    }

    func run() : Unit {
        // 1. deserialize CustomTypeDef, for order and CustomType
        //    CustomType will be used in Value, we need to prepare in order first
        let defsSize = pkgFormat.GetDefsSize()
        for (id in 1..=defsSize) {
            getCustomTypeDef(UInt32(id))
        }

        // 2. deserialize global function and global variable, only for order
        let valuesSize = pkgFormat.GetValuesSize()
        for (id in 1..=valuesSize) {
            let index = UInt32(id)
            let valueElemKind = pkgFormat.GetValuesType(index - 1)
            match (valueElemKind) {
                case PackageFormat_ValueElem.ValueElem_FUNCTION  => getValue(index)
                case PackageFormat_ValueElem.ValueElem_GLOBALVAR => getValue(index)
                case _ => ()
            }
        }

        // 3. fill in CustomTypeDef, its member methods, member vars and so on
        //    this step must before filling in function, because CustomTypeDef's member var may be used in func body
        for (id in 1..=pkgFormat.GetDefsSize()) {
            let index = UInt32(id)
            let typeFormat = pkgFormat.GetDefsType(index - 1)
            match (typeFormat) {
                case PackageFormat_CustomTypeDefElem.CustomTypeDefElem_ENUMDEF =>
                    configEnumDef(pkgFormat.GetDefsAsEnumDef(index - 1).getOrThrow(), getCustomTypeDefAs<EnumDef>(index))
                case PackageFormat_CustomTypeDefElem.CustomTypeDefElem_STRUCTDEF =>
                    configStructDef(pkgFormat.GetDefsAsStructDef(index - 1).getOrThrow(), getCustomTypeDefAs<StructDef>(index))
                case PackageFormat_CustomTypeDefElem.CustomTypeDefElem_CLASSDEF =>
                    configClassDef(pkgFormat.GetDefsAsClassDef(index - 1).getOrThrow(), getCustomTypeDefAs<ClassLikeDef>(index))
                case PackageFormat_CustomTypeDefElem.CustomTypeDefElem_EXTENDDEF =>
                    configExtendDef(pkgFormat.GetDefsAsExtendDef(index - 1).getOrThrow(), getCustomTypeDefAs<ExtendDef>(index))
                case PackageFormat_CustomTypeDefElem.CustomTypeDefElem_NONE => ()
            }
        }

        // 4. fill in global var, function, block and block group
        //    when fill in function, we only set parameter and func body, not fill in func body,
        //    when fill in block group, we only set sub blocks, not fill in sub blocks,
        //    that means we only fill in sub structure, not recursively, because loop structures can be
        //    constructed from blocks and expressions
        for (id in 1..=pkgFormat.GetValuesSize()) {
            let index = UInt32(id)
            let valueElemKind = pkgFormat.GetValuesType(index - 1)
            match (valueElemKind) {
                case PackageFormat_ValueElem.ValueElem_FUNCTION   =>
                    configFunction(pkgFormat.GetValuesAsFunction(index - 1).getOrThrow(), getValueAs<Function>(index))
                case PackageFormat_ValueElem.ValueElem_GLOBALVAR  =>
                    configGlobalVar(pkgFormat.GetValuesAsGlobalVar(index - 1).getOrThrow(), getValueAs<GlobalVar>(index))
                case PackageFormat_ValueElem.ValueElem_BLOCK      =>
                    configBlock(pkgFormat.GetValuesAsBlock(index - 1).getOrThrow(), getValueAs<Block>(index))
                case PackageFormat_ValueElem.ValueElem_BLOCKGROUP =>
                    configBlockGroup(pkgFormat.GetValuesAsBlockGroup(index - 1).getOrThrow(), getValueAs<BlockGroup>(index))
                case _ => ()
            }
        }

        // 5. update LocalVar's information
        //    if local var is used in expression, its information has been updated while deserializing expression
        //    if local var isn't used in expression, its information need to be updated here
        for (id in 1..=pkgFormat.GetValuesSize()) {
            let index = UInt32(id)
            let valueElemKind = pkgFormat.GetValuesType(index - 1)
            match (valueElemKind) {
                case PackageFormat_ValueElem.ValueElem_LOCALVAR =>
                    configValue(pkgFormat.GetValuesAsLocalVar(index - 1).getOrThrow().GetBase().getOrThrow(), getValueAs<LocalVar>(index))
                case _ => ()
            }
        }

        // 6. fill in generic types' upper bounds
        for ((genericType, rawGenericType) in genericTypeConfig) {
            let upperBounds = collectArrayList<Type>(getTypeAs<Type>(rawGenericType.GetUpperBounds()))
            genericType._upperBounds = upperBounds
        }

        // 7. fill in package's information
        pkg._packageInitFunc = tryGetValueAs<Function>(pkgFormat.GetPackageInitFunc())
        pkg._packageLiteralInitFunc = tryGetValueAs<Function>(pkgFormat.GetPackageLiteralInitFunc())

        // 8. add all extends
        addAllExtends()
    }

    private func addExtends(extendDef: ExtendDef) : Unit {
        let ty = extendDef._extendedType
        if (let Some(v) <- (ty as BuiltinType)) {
            v._extends.add(extendDef)
        } else if (let Some(v) <- (ty as CustomType)) {
            v._def._extends.add(extendDef)
        }
    }

    private func addAllExtends() : Unit {
        for (def in this.pkg._extendDefs) {
            addExtends(def)
        }
    }

    private func getBasicTypeFromBuilder(typeFormat: PackageFormat_CHIRTypeKind) : Option<Type> {
        return match (typeFormat) {
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_BOOLEAN => BoolType.get()
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_INT8 => IntType.getInt8()
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_INT16 => IntType.getInt16()
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_INT32 => IntType.getInt32()
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_INT64 => IntType.getInt64()
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_INT_NATIVE => IntType.getIntNative()
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_UINT8 => IntType.getUInt8()
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_UINT16 => IntType.getUInt16()
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_UINT32 => IntType.getUInt32()
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_UINT64 => IntType.getUInt64()
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_UINT_NATIVE => IntType.getUIntNative()
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_FLOAT16 => FloatType.getFloat16()
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_FLOAT32 => FloatType.getFloat32()
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_FLOAT64 => FloatType.getFloat64()
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_C_STRING => CStringType.get()
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_UNIT => UnitType.get()
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_NOTHING => NothingType.get()
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_RUNE => RuneType.get()
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_THIS => ThisType.get()
            case _ => None
        }
    }

    private func convertTypeKind(typeFormat: PackageFormat_CHIRTypeKind) : TypeKind {
        return match (typeFormat) {
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_INVALID => TypeKind.Invalid
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_INT8 => TypeKind.`Int8`
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_INT16 => TypeKind.`Int16`
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_INT32 => TypeKind.`Int32`
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_INT64 => TypeKind.`Int64`
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_INT_NATIVE => TypeKind.`IntNative`
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_UINT8 => TypeKind.`UInt8`
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_UINT16 => TypeKind.`UInt16`
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_UINT32 => TypeKind.`UInt32`
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_UINT64 => TypeKind.`UInt64`
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_UINT_NATIVE => TypeKind.`UIntNative`
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_FLOAT16 => TypeKind.`Float16`
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_FLOAT32 => TypeKind.`Float32`
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_FLOAT64 => TypeKind.`Float64`
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_BOOLEAN => TypeKind.`Bool`
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_RUNE => TypeKind.`Rune`
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_UNIT => TypeKind.`Unit`
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_NOTHING => TypeKind.`Nothing`
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_CLASS => TypeKind.ClassLike
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_ENUM => TypeKind.Enum
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_STRUCT => TypeKind.Struct
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_TUPLE => TypeKind.Tuple
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_C_POINTER => TypeKind.CPointer
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_C_STRING => TypeKind.CString
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_RAWARRAY => TypeKind.RawArray
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_VARRAY => TypeKind.`VArray`
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_GENERIC => TypeKind.Generic
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_REFTYPE => TypeKind.Ref
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_BOXTYPE => TypeKind.Box
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_THIS => TypeKind.`This`
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_FUNC => TypeKind.Func
            case PackageFormat_CHIRTypeKind.CHIRTypeKind_VOID => throw IllegalArgumentException("Cannot convert CHIRTypeKind.CHIRTypeKind_VOID to TypeKind")
        }
    }

    private func getBasicTypeFromBuilder(typeFormat: UInt32) : Option<Type> {
        return getBasicTypeFromBuilder(EnumValuesPackageFormat_CHIRTypeKind(UInt8(typeFormat)))
    }

    private func getType(id: UInt32): Type {
        if (id == 0) {
            throw CHIRException("id is 0, type is not found")
        }
        if (let Some(v) <- id2Type.get(id)) {
            return v
        }
        let ty: Type = match (pkgFormat.GetTypesType(id - 1)) {
            case PackageFormat_TypeElem.TypeElem_TYPE =>
                let t = pkgFormat.GetTypesAsType(id - 1).getOrThrow()
                let kind = t.GetKind()
                // some types, that don't have argTys, can be directly constructed from kind
                let basicType = getBasicTypeFromBuilder(kind)
                if (let Some(ty) <- basicType) {
                    ty
                } else {
                    let argTys = collectArrayList<Type>(getTypeAs<Type>(t.GetArgTys()))
                    let tk = convertTypeKind(kind)
                    match (tk) {
                        case TypeKind.Tuple =>
                            TupleType.get(argTys.toArray())
                        case TypeKind.Ref =>
                            RefType.get(argTys[0])
                        case TypeKind.Box =>
                            BoxType.get(argTys[0])
                        case TypeKind.CPointer =>
                            CPointerType.get(argTys[0])
                        case _ => throw IllegalArgumentException("Unsupported TYPE kind: ${tk}")
                    }
                }
            case PackageFormat_TypeElem.TypeElem_RAWARRAYTYPE =>
                let rawArrayType = pkgFormat.GetTypesAsRawArrayType(id - 1).getOrThrow()
                let elemTy = getType(rawArrayType.GetBase().getOrThrow().GetArgTys().first.getOrThrow())
                let dims = rawArrayType.GetDims()
                RawArrayType.get(elemTy, dims)
            case PackageFormat_TypeElem.TypeElem_VARRAYTYPE =>
                let varrayType = pkgFormat.GetTypesAsVArrayType(id - 1).getOrThrow()
                let elemTy = getType(varrayType.GetBase().getOrThrow().GetArgTys().first.getOrThrow())
                let size = varrayType.GetSize()
                VArrayType.get(elemTy, size)
            case PackageFormat_TypeElem.TypeElem_FUNCTYPE =>
                let funcType = pkgFormat.GetTypesAsFuncType(id - 1).getOrThrow()
                let argTyIndices = funcType.GetBase().getOrThrow().GetArgTys()
                let retTy = getType(argTyIndices.last.getOrThrow())
                let argTys = collectArrayList<Type>(getTypeAs<Type>(argTyIndices.slice(0, argTyIndices.size - 1))).toArray()
                let hasVarArg = funcType.GetHasVarArg()
                let isCFuncType = funcType.GetIsCFuncType()
                FuncType.get(argTys, retTy, varArg: hasVarArg, cFunc: isCFuncType)
            case PackageFormat_TypeElem.TypeElem_CUSTOMTYPE =>
                let customType = pkgFormat.GetTypesAsCustomType(id - 1).getOrThrow()
                let typeKind = convertTypeKind(customType.GetBase().getOrThrow().GetKind())
                let def = customType.GetCustomTypeDef()
                let typeArgs = getType(customType.GetBase().getOrThrow().GetArgTys())
                match (typeKind) {
                    case TypeKind.ClassLike =>
                        let classDef = getCustomTypeDefAs<ClassLikeDef>(def)
                        ClassLikeType.get(classDef, typeArgs)
                    case TypeKind.Struct =>
                        let structDef = getCustomTypeDefAs<StructDef>(def)
                        StructType.get(structDef, typeArgs)
                    case TypeKind.Enum =>
                        let enumDef = getCustomTypeDefAs<EnumDef>(def)
                        EnumType.get(enumDef, typeArgs)
                    case _ => throw IllegalArgumentException("Illegal custom type kind: ${typeKind}")
                }
            case PackageFormat_TypeElem.TypeElem_GENERICTYPE =>
                let genericType = pkgFormat.GetTypesAsGenericType(id - 1).getOrThrow()
                let identifier = genericType.GetIdentifier()
                let srcCodeIdentifier = genericType.GetSrcCodeIdentifier()
                let result = GenericType.get(identifier, srcCodeIdentifier)
                genericTypeConfig.add((result, genericType))
                result
            case PackageFormat_TypeElem.TypeElem_NONE =>
                throw IllegalArgumentException("none type not supported")
        }
        id2Type[id] = ty
        return ty
    }

    private func getType(ids: Array<UInt32>) : Array<Type> {
        return Array<Type>(ids.size, { i => getType(ids[i]) })
    }

    private func getTypeAs<T>(id: UInt32) : T {
        return (getType(id) as T).getOrThrow()
    }

    private func getTypeAs<T>(ids: Array<UInt32>) : Array<T> {
        return Array<T>(ids.size, { i => getTypeAs<T>(ids[i]) })
    }

    private func tryGetType(id: UInt32): ?Type {
        if (id == 0) {
            return None
        }
        return getType(id)
    }

    private func tryGetTypeAs<T>(id: UInt32): ?T {
        if (let Some(v) <- tryGetType(id)) {
            return v as T
        }
        return None
    }

    private func getExpression(id: UInt32): Expression {
        if (id == 0) {
            throw CHIRException("id is 0, expression not found")
        }
        if (let Some(v) <- id2Expression.get(id)) {
            return v
        }
        match (pkgFormat.GetExprsType(id - 1)) {
            case PackageFormat_ExpressionElem.ExpressionElem_LAMBDA =>
                let exprFormat = pkgFormat.GetExprsAsLambda(id-1).getOrThrow()
                let expr = deserializeLambda(exprFormat)
                id2Expression[id] = expr
                configLambda(exprFormat, expr)
                return expr
            case _ => ()
        }
        let (expr, exprFormat): (Expression, PackageFormat_Expression) = match (pkgFormat.GetExprsType(id - 1)) {
            case PackageFormat_ExpressionElem.ExpressionElem_ALLOCATEBASE =>
                let exprFormat = pkgFormat.GetExprsAsAllocateBase(id-1).getOrThrow()
                (deserializeAllocateBase(exprFormat), exprFormat.GetBase().getOrThrow())
            case PackageFormat_ExpressionElem.ExpressionElem_APPLYBASE =>
                let exprFormat = pkgFormat.GetExprsAsApplyBase(id-1).getOrThrow()
                (deserializeApplyBase(exprFormat), exprFormat.GetBase().getOrThrow().GetBase().getOrThrow())
            case PackageFormat_ExpressionElem.ExpressionElem_BINARYEXPRESSIONBASE =>
                let exprFormat = pkgFormat.GetExprsAsBinaryExpressionBase(id-1).getOrThrow()
                (deserializeBinaryExpressionBase(exprFormat), exprFormat.GetBase().getOrThrow())
            case PackageFormat_ExpressionElem.ExpressionElem_BRANCH =>
                let exprFormat = pkgFormat.GetExprsAsBranch(id-1).getOrThrow()
                (deserializeBranch(exprFormat), exprFormat.GetBase().getOrThrow())
            case PackageFormat_ExpressionElem.ExpressionElem_DEBUG =>
                let exprFormat = pkgFormat.GetExprsAsDebug(id-1).getOrThrow()
                (deserializeDebug(exprFormat), exprFormat.GetBase().getOrThrow())
            case PackageFormat_ExpressionElem.ExpressionElem_EXPRESSION =>
                let exprFormat = pkgFormat.GetExprsAsExpression(id-1).getOrThrow()
                (deserializeExpression(exprFormat), exprFormat)
            case PackageFormat_ExpressionElem.ExpressionElem_FIELD =>
                let exprFormat = pkgFormat.GetExprsAsField(id-1).getOrThrow()
                (deserializeField(exprFormat), exprFormat.GetBase().getOrThrow())
            case PackageFormat_ExpressionElem.ExpressionElem_FIELDBYNAME =>
                let exprFormat = pkgFormat.GetExprsAsFieldByName(id-1).getOrThrow()
                (deserializeFieldByName(exprFormat), exprFormat.GetBase().getOrThrow())
            case PackageFormat_ExpressionElem.ExpressionElem_GETELEMENTBYNAME =>
                let exprFormat = pkgFormat.GetExprsAsGetElementByName(id-1).getOrThrow()
                (deserializeGetElementByName(exprFormat), exprFormat.GetBase().getOrThrow())
            case PackageFormat_ExpressionElem.ExpressionElem_GETELEMENTREF =>
                let exprFormat = pkgFormat.GetExprsAsGetElementRef(id-1).getOrThrow()
                (deserializeGetElementRef(exprFormat), exprFormat.GetBase().getOrThrow())
            case PackageFormat_ExpressionElem.ExpressionElem_GETINSTANTIATEVALUE =>
                let exprFormat = pkgFormat.GetExprsAsGetInstantiateValue(id-1).getOrThrow()
                (deserializeGetInstantiateValue(exprFormat), exprFormat.GetBase().getOrThrow())
            case PackageFormat_ExpressionElem.ExpressionElem_GETRTTISTATIC =>
                let exprFormat = pkgFormat.GetExprsAsGetRTTIStatic(id-1).getOrThrow()
                (deserializeGetRTTIStatic(exprFormat), exprFormat.GetBase().getOrThrow())
            case PackageFormat_ExpressionElem.ExpressionElem_INSTANCEOF =>
                let exprFormat = pkgFormat.GetExprsAsInstanceOf(id-1).getOrThrow()
                (deserializeInstanceOf(exprFormat), exprFormat.GetBase().getOrThrow())
            case PackageFormat_ExpressionElem.ExpressionElem_INTRINSICBASE =>
                let exprFormat = pkgFormat.GetExprsAsIntrinsicBase(id-1).getOrThrow()
                (deserializeIntrinsicBase(exprFormat), exprFormat.GetBase().getOrThrow().GetBase().getOrThrow())
            case PackageFormat_ExpressionElem.ExpressionElem_INVOKEBASE =>
                let exprFormat = pkgFormat.GetExprsAsInvokeBase(id-1).getOrThrow()
                (deserializeInvoke(exprFormat), exprFormat.GetBase().getOrThrow().GetBase().getOrThrow())
            case PackageFormat_ExpressionElem.ExpressionElem_MULTIBRANCH =>
                let exprFormat = pkgFormat.GetExprsAsMultiBranch(id-1).getOrThrow()
                (deserializeMultiBranch(exprFormat), exprFormat.GetBase().getOrThrow())
            case PackageFormat_ExpressionElem.ExpressionElem_NUMERICCASTBASE =>
                let exprFormat = pkgFormat.GetExprsAsNumericCastBase(id-1).getOrThrow()
                (deserializeNumericCastBase(exprFormat), exprFormat.GetBase().getOrThrow())
            case PackageFormat_ExpressionElem.ExpressionElem_RAWARRAYALLOCATEBASE =>
                let exprFormat = pkgFormat.GetExprsAsRawArrayAllocateBase(id-1).getOrThrow()
                (deserializeRawArrayAllocateBase(exprFormat), exprFormat.GetBase().getOrThrow())
            case PackageFormat_ExpressionElem.ExpressionElem_SPAWNBASE =>
                let exprFormat = pkgFormat.GetExprsAsSpawnBase(id-1).getOrThrow()
                (deserializeSpawnBase(exprFormat), exprFormat.GetBase().getOrThrow())
            case PackageFormat_ExpressionElem.ExpressionElem_STOREELEMENTBYNAME =>
                let exprFormat = pkgFormat.GetExprsAsStoreElementByName(id-1).getOrThrow()
                (deserializeStoreElementByName(exprFormat), exprFormat.GetBase().getOrThrow())
            case PackageFormat_ExpressionElem.ExpressionElem_STOREELEMENTREF =>
                let exprFormat = pkgFormat.GetExprsAsStoreElementRef(id-1).getOrThrow()
                (deserializeStoreElementRef(exprFormat), exprFormat.GetBase().getOrThrow())
            case PackageFormat_ExpressionElem.ExpressionElem_UNARYEXPRESSIONBASE =>
                let exprFormat = pkgFormat.GetExprsAsUnaryExpressionBase(id-1).getOrThrow()
                (deserializeUnaryExpressionBase(exprFormat), exprFormat.GetBase().getOrThrow())
            case _ =>
                throw IllegalArgumentException("unsupported expression type in chir deserialization.")
        }
        id2Expression[id] = expr
        configExpression(exprFormat, expr)
        return expr
    }

    private func tryGetExpressionAs<T>(id: UInt32) : ?T {
        if (let Some(v) <- tryGetExpression(id)) {
            return v as T
        }
        return None
    }

    private func tryGetExpression(id: UInt32): ?Expression {
        if (id == 0) {
            return None
        }
        return getExpression(id)
    }

    private func getCustomTypeDef(id : UInt32) : CustomTypeDef {
        if (id == 0) {
            throw CHIRException("id is 0, CustomTypeDef not found")
        }
        if (let Some(v) <- id2CustomTypeDef.get(id)) {
            return v
        }
        let typeFormat = pkgFormat.GetDefsType(id - 1)
        let value : CustomTypeDef = match (typeFormat) {
            case PackageFormat_CustomTypeDefElem.CustomTypeDefElem_ENUMDEF =>
                deserializeEnumDef(pkgFormat.GetDefsAsEnumDef(id-1).getOrThrow())
            case PackageFormat_CustomTypeDefElem.CustomTypeDefElem_STRUCTDEF =>
                deserializeStructDef(pkgFormat.GetDefsAsStructDef(id-1).getOrThrow())
            case PackageFormat_CustomTypeDefElem.CustomTypeDefElem_CLASSDEF =>
                deserializeClassDef(pkgFormat.GetDefsAsClassDef(id-1).getOrThrow())
            case PackageFormat_CustomTypeDefElem.CustomTypeDefElem_EXTENDDEF =>
                deserializeExtendDef(pkgFormat.GetDefsAsExtendDef(id-1).getOrThrow())
            case PackageFormat_CustomTypeDefElem.CustomTypeDefElem_NONE =>
                throw CHIRException("Invalid PackageFormat_CustomTypeDefElem")
        }
        id2CustomTypeDef.add(id, value)
        return value
    }

    private func getCustomTypeDefAs<T>(id: UInt32) : T {
        return (getCustomTypeDef(id) as T).getOrThrow()
    }

    private func tryGetCustomTypeDef(id: UInt32): Option<CustomTypeDef> {
        if (id == 0) {
            return None
        }
        return getCustomTypeDef(id)
    }

    private func tryGetCustomTypeDefAs<T>(id: UInt32): ?T {
        if (let Some(v) <- tryGetCustomTypeDef(id)) {
            return v as T
        }
        return None
    }

    private func configValue(valueFormat: PackageFormat_Value, value: Value) {
        let baseFormat = valueFormat.GetBase().getOrThrow()
        configBase(baseFormat, value)
        value._identifier = valueFormat.GetIdentifier()
    }

    private func deserializeEnumDef(enumDefFormat: PackageFormat_EnumDef): EnumDef {
        let base = enumDefFormat.GetBase().getOrThrow()
        let srcCodeName = base.GetSrcCodeIdentifier()
        let pkgName = base.GetPackageName()
        let nonExhaustive = enumDefFormat.GetNonExhaustive()
        let identifier = base.GetIdentifier()
        let enumDef = EnumDef(identifier, srcCodeName, pkgName, nonExhaustive)
        pkg._enumDefs.add(enumDef)
        return enumDef
    }

    private func deserializeStructDef(structDefFormat: PackageFormat_StructDef): StructDef {
        let base = structDefFormat.GetBase().getOrThrow()
        let identifier = base.GetIdentifier()
        let srcCodeName = base.GetSrcCodeIdentifier()
        let pkgName = base.GetPackageName()
        let structDef = StructDef(identifier, srcCodeName, pkgName)
        pkg._structDefs.add(structDef)
        return structDef
    }

    private func deserializeClassDef(classDefFormat: PackageFormat_ClassDef): ClassLikeDef {
        let base = classDefFormat.GetBase().getOrThrow()
        let identifier = base.GetIdentifier()
        let srcCodeName = base.GetSrcCodeIdentifier()
        let pkgName = base.GetPackageName()
        let classDef = ClassLikeDef(identifier, srcCodeName, pkgName, classDefFormat.GetIsClass())
        pkg._classDefs.add(classDef)
        return classDef
    }

    private func deserializeExtendDef(extendDefFormat: PackageFormat_ExtendDef): ExtendDef {
        let base = extendDefFormat.GetBase().getOrThrow()
        let identifier = base.GetIdentifier()
        let pkgName = base.GetPackageName()
        let extendedType = getType(extendDefFormat.GetExtendedType())
        let genericTypeParams = getTypeAs<GenericType>(extendDefFormat.GetGenericParams())
        let extendDef = ExtendDef(identifier, pkgName, extendedType, ArrayList<GenericType>.of(genericTypeParams))
        pkg._extendDefs.add(extendDef)
        return extendDef
    }

    private func deserializeAnnoInstance(annoFormat: PackageFormat_CustomAnnoInstance): CustomAnnoInstance {
        let className = annoFormat.GetAnnoClassName()
        let loc = if (let Some(locFormat) <- annoFormat.GetLoc()) {
            deserializeDebugLocation(locFormat)
        } else {
            DebugLocation.invalid()
        }
        let anno = CustomAnnoInstance(className, loc)
        let argValues = annoFormat.GetArgValues()
        anno._argValues = ArrayList<String>(argValues.size, { i => argValues[i].getOrThrow() })
        return anno
    }

    private func deserializeAnnoInfo(annoInfoFormat: PackageFormat_AnnoInfo): AnnoInfo {
        let mangledName = annoInfoFormat.GetMangledName()
        let annoInfo = AnnoInfo(mangledName)
        if (let annoInstanceFormat <- annoInfoFormat.GetAnnoInstances() && !annoInstanceFormat.isEmpty()) {
            for (anno in annoInstanceFormat) {
                annoInfo._annoInstances.add(deserializeAnnoInstance(anno.getOrThrow()))
            }
        }
        return annoInfo
    }

    private func deserializeParameter(parameterFormat: PackageFormat_Parameter): Parameter {
        let valueFormat = parameterFormat.GetBase().getOrThrow()
        let ty = getType(valueFormat.GetType())
        let param: Parameter
        if (let Some(v) <- tryGetValueAs<Function>(parameterFormat.GetOwnedFunc())) {
            param = Parameter(ty, "", v)
        } else if (let Some(v) <- tryGetExpressionAs<Lambda>(parameterFormat.GetOwnedLambda())) {
            param = Parameter(ty, "", v)
        } else {
            throw CHIRException("Parameter must have either ownedFunc or ownedLambda")
        }
        param._srcCodeName = parameterFormat.GetSrcCodeIdentifier()
        if (let Some(v) <- parameterFormat.GetAnnoInfo()) {
            param._annoInfo = deserializeAnnoInfo(v)
        }
        return param
    }

    private func deserializeLocalVar(localVarFormat: PackageFormat_LocalVar): LocalVar {
        // LocalVar is created automatically when the associated expression is created
        // We just need to get it from the expression's result
        let expr = getExpression(localVarFormat.GetAssociatedExpr())
        let localVar = expr.result
        localVar._srcCodeName = localVarFormat.GetSrcCodeIdentifier()
        if (localVarFormat.GetIsRetVal()) {
            localVar._isRetValue = true
        }

        return localVar
    }

    private func deserializeMemberVarInfo(memberVarInfoFormat: PackageFormat_MemberVarInfo, outerDef: CustomTypeDef): MemberVar {
        let name = memberVarInfoFormat.GetName()
        let ty = getType(memberVarInfoFormat.GetType())
        let memberVar = MemberVar(name, ty, outerDef)
        
        // Set annoInfo
        if (let Some(v) <- memberVarInfoFormat.GetAnnoInfo()) {
            memberVar._annoInfo = deserializeAnnoInfo(v)
        }
        
        // Set attributes
        memberVar._attributes = AttributeInfo(memberVarInfoFormat.GetAttributes())
        
        // Set DebugLocation
        if (let Some(v) <- memberVarInfoFormat.GetLoc()) {
            memberVar._debugLocation = deserializeDebugLocation(v)
        }
        
        // Set initializerFunc
        if (let Some(v) <- tryGetValueAs<Function>(memberVarInfoFormat.GetInitializerFunc())) {
            memberVar._initializerFunc = v
        }

        // Set rawMangledName
        memberVar._rawMangledName = memberVarInfoFormat.GetRawMangledName()
        
        return memberVar
    }

    private func deserializeFeatures(globalValueFormat: PackageFormat_GlobalValue): ArrayList<String> {
        let featuresRaw = globalValueFormat.GetFeatures()
        return ArrayList<String>(featuresRaw.size, { i => featuresRaw[i].getOrThrow() })
    }

    private func deserializeGlobalVar(globalVarFormat: PackageFormat_GlobalVar): GlobalVar {
        let globalValueFormat = globalVarFormat.GetBase().getOrThrow()
        let valueFormat = globalValueFormat.GetBase().getOrThrow()
        let ty = getType(valueFormat.GetType())
        let identifier = valueFormat.GetIdentifier()
        let srcCodeName = globalValueFormat.GetSrcCodeIdentifier()
        let pkgName = globalValueFormat.GetPackageName()
        let globalVar = GlobalVar(ty, identifier, srcCodeName, pkgName)
        pkg._globalVars.add(globalVar)
        return globalVar
    }

    private func deserializeFunction(funcFormat: PackageFormat_Function): Function {
        let globalValueFormat = funcFormat.GetBase().getOrThrow()
        let valueFormat = globalValueFormat.GetBase().getOrThrow()
        let funcTy = getTypeAs<FuncType>(valueFormat.GetType())
        let identifier = valueFormat.GetIdentifier()
        let srcCodeName = globalValueFormat.GetSrcCodeIdentifier()
        let packageName = globalValueFormat.GetPackageName()
        let function = Function(funcTy, identifier, srcCodeName, packageName)
        pkg._functions.add(function)
        return function
    }

    private func deserializeBlock(blockFormat: PackageFormat_Block): Block {
        let parentGroup = getValueAs<BlockGroup>(blockFormat.GetParentGroup())
        return Block("", parentGroup)
    }

    private func deserializeBlockGroup(blockGroupFormat: PackageFormat_BlockGroup): BlockGroup {
        var result: BlockGroup
        if (let Some(owner) <- tryGetValueAs<Function>(blockGroupFormat.GetOwnedFunc())) {
            result = BlockGroup("", owner)
        } else if (let Some(owner) <- tryGetExpressionAs<Lambda>(blockGroupFormat.GetOwnedExpression())) {
            result = BlockGroup("", owner._result.getOrThrow())
        } else {
            throw CHIRException("Invalid owner, neither Function or Lambda")
        }
        return result
    }

    private func getValue(id : UInt32): Value {
        if (id == 0) {
            throw CHIRException("id is 0, value is not found")
        }
        if (let Some(v) <- id2Value.get(id)) {
            return v
        }
        match (pkgFormat.GetValuesType(id - 1)) {
            case PackageFormat_ValueElem.ValueElem_BLOCK =>
                let blockFormat = pkgFormat.GetValuesAsBlock(id - 1).getOrThrow()
                let block = deserializeBlock(blockFormat)
                id2Value[id] = block
                configValue(blockFormat.GetBase().getOrThrow(), block)
            case PackageFormat_ValueElem.ValueElem_BLOCKGROUP =>
                let blockGroupFormat = pkgFormat.GetValuesAsBlockGroup(id - 1).getOrThrow()
                let blockGroup = deserializeBlockGroup(blockGroupFormat)
                id2Value[id] = blockGroup
                configValue(blockGroupFormat.GetBase().getOrThrow(), blockGroup)
            case PackageFormat_ValueElem.ValueElem_BOOLLITERAL =>
                let boolLiteralFormat = pkgFormat.GetValuesAsBoolLiteral(id - 1).getOrThrow()
                let boolLiteral = BoolLiteral.get(boolLiteralFormat.GetVal())
                id2Value[id] = boolLiteral
                configValue(boolLiteralFormat.GetBase().getOrThrow().GetBase().getOrThrow(), boolLiteral)
            case PackageFormat_ValueElem.ValueElem_FLOATLITERAL =>
                let floatLiteralFormat = pkgFormat.GetValuesAsFloatLiteral(id - 1).getOrThrow()
                let valueType = floatLiteralFormat.GetBase().getOrThrow().GetBase().getOrThrow().GetType()
                let floatType = getTypeAs<FloatType>(valueType)
                let floatLiteral = FloatLiteral.get(floatType, floatLiteralFormat.GetVal())
                id2Value[id] = floatLiteral
                configValue(floatLiteralFormat.GetBase().getOrThrow().GetBase().getOrThrow(), floatLiteral)
            case PackageFormat_ValueElem.ValueElem_FUNCTION =>
                let funcFormat = pkgFormat.GetValuesAsFunction(id - 1).getOrThrow()
                let function = deserializeFunction(funcFormat)
                id2Value[id] = function
            case PackageFormat_ValueElem.ValueElem_GLOBALVAR =>
                let globalVarFormat = pkgFormat.GetValuesAsGlobalVar(id - 1).getOrThrow()
                let globalVar = deserializeGlobalVar(globalVarFormat)
                id2Value[id] = globalVar
            case PackageFormat_ValueElem.ValueElem_INTLITERAL =>
                let intLiteralFormat = pkgFormat.GetValuesAsIntLiteral(id - 1).getOrThrow()
                let valueType = intLiteralFormat.GetBase().getOrThrow().GetBase().getOrThrow().GetType()
                let intType = getTypeAs<IntType>(valueType)
                let intLiteral = IntLiteral.get(intType, intLiteralFormat.GetVal())
                id2Value[id] = intLiteral
                configValue(intLiteralFormat.GetBase().getOrThrow().GetBase().getOrThrow(), intLiteral)
            case PackageFormat_ValueElem.ValueElem_LOCALVAR =>
                let localVarFormat = pkgFormat.GetValuesAsLocalVar(id - 1).getOrThrow()
                let localVar = deserializeLocalVar(localVarFormat)
                id2Value[id] = localVar
                configValue(localVarFormat.GetBase().getOrThrow(), localVar)
            case PackageFormat_ValueElem.ValueElem_NULLLITERAL =>
                let nullLiteralFormat = pkgFormat.GetValuesAsNullLiteral(id - 1).getOrThrow()
                let valueType = nullLiteralFormat.GetBase().getOrThrow().GetBase().getOrThrow().GetType()
                let convertedType = getType(valueType)
                let nullLiteral = NullLiteral.get(convertedType)
                id2Value[id] = nullLiteral
                configValue(nullLiteralFormat.GetBase().getOrThrow().GetBase().getOrThrow(), nullLiteral)
            case PackageFormat_ValueElem.ValueElem_PARAMETER =>
                let parameterFormat = pkgFormat.GetValuesAsParameter(id - 1).getOrThrow()
                let parameter = deserializeParameter(parameterFormat)
                id2Value[id] = parameter
                configValue(parameterFormat.GetBase().getOrThrow(), parameter)
            case PackageFormat_ValueElem.ValueElem_RUNELITERAL =>
                let runeLiteralFormat = pkgFormat.GetValuesAsRuneLiteral(id - 1).getOrThrow()
                let runeLiteral = RuneLiteral.get(Rune(runeLiteralFormat.GetVal()))
                id2Value[id] = runeLiteral
                configValue(runeLiteralFormat.GetBase().getOrThrow().GetBase().getOrThrow(), runeLiteral)
            case PackageFormat_ValueElem.ValueElem_STRINGLITERAL =>
                let stringLiteralFormat = pkgFormat.GetValuesAsStringLiteral(id - 1).getOrThrow()
                let base = stringLiteralFormat.GetBase().getOrThrow().GetBase().getOrThrow()
                let stringType = getTypeAs<StructType>(base.GetType())
                let stringLiteral = StringLiteral.get(stringType, stringLiteralFormat.GetVal())
                id2Value[id] = stringLiteral
                configValue(base, stringLiteral)
            case PackageFormat_ValueElem.ValueElem_UNITLITERAL =>
                let unitLiteralFormat = pkgFormat.GetValuesAsUnitLiteral(id - 1).getOrThrow()
                let unitLiteral = UnitLiteral.get()
                id2Value[id] = unitLiteral
                configValue(unitLiteralFormat.GetBase().getOrThrow().GetBase().getOrThrow(), unitLiteral)
            case _ =>
                throw CHIRException("Unsupported value type")
        }
        return id2Value[id]
    }

    private func getValue(ids: Array<UInt32>) : Array<Value> {
        return Array<Value>(ids.size, { i => getValue(ids[i]) })
    }

    private func getValueAs<T>(id: UInt32): T {
        return (getValue(id) as T).getOrThrow()
    }

    private func getValueAs<T>(ids: Array<UInt32>) : Array<T> {
        return Array<T>(ids.size, { i => getValueAs<T>(ids[i]) })
    }

    private func tryGetValueAs<T>(id: UInt32): ?T {
        if (let Some(v) <- tryGetValue(id)) {
            return v as T
        }
        return None
    }

    private func tryGetValue(id: UInt32): ?Value {
        if (id == 0) {
            return None
        }
        return getValue(id)
    }

    private func createPosition(positionFormat: PackageFormat_Pos) {
        return Position(Int64(positionFormat.GetLine()), Int64(positionFormat.GetColumn()))
    }

    private func deserializeDebugLocation(debugLocationFormat : PackageFormat_DebugLocation) {
        let start = createPosition(debugLocationFormat.GetBeginPos().getOrThrow())
        let end = createPosition(debugLocationFormat.GetEndPos().getOrThrow())
        let debugLocation = DebugLocation(start, end, Path(debugLocationFormat.GetFilePath()))
        debugLocation._fileId = UInt64(debugLocationFormat.GetFileId())
        debugLocation._scopeInfo = ArrayList<Int64>.of(debugLocationFormat.GetScope().mapTo<Int64>({ v => Int64(v) }))
        return debugLocation
    }

    private func configBase(baseFormat: PackageFormat_Base, base: Base) {
        let annosSize = baseFormat.GetAnnosSize()
        for (i in 0..annosSize) {
            let index = UInt32(i)
            match (baseFormat.GetAnnosType(index)) {
                case PackageFormat_Annotation.Annotation_NEEDCHECKARRAYBOUND =>
                    base.setAnno<NeedCheckArrayBound, Bool>(
                        baseFormat.GetAnnosAsNeedCheckArrayBound(index)
                        .getOrThrow().GetNeed())
                case PackageFormat_Annotation.Annotation_NEEDCHECKCAST =>
                    base.setAnno<NeedCheckCast, Bool>(
                        baseFormat.GetAnnosAsNeedCheckCast(index)
                        .getOrThrow().GetNeed())
                case PackageFormat_Annotation.Annotation_DEBUGLOCATIONINFOFORWARNING =>
                    base.setAnno<DebugLocationInfoForWarning, DebugLocation>(
                        deserializeDebugLocation(baseFormat.GetAnnosAsDebugLocationInfoForWarning(index)
                        .getOrThrow()))
                case PackageFormat_Annotation.Annotation_LINKTYPEINFO =>
                    base.setAnno<LinkTypeInfo, LinkType>(
                        match(baseFormat.GetAnnosAsLinkTypeInfo(index)
                        .getOrThrow().GetLinkage()) {
                            case PackageFormat_Linkage.Linkage_WEAK_ODR =>
                                LinkType.WeakOdr
                            case PackageFormat_Linkage.Linkage_EXTERNAL =>
                                LinkType.External
                            case PackageFormat_Linkage.Linkage_INTERNAL =>
                                LinkType.Internal
                            case PackageFormat_Linkage.Linkage_LINKONCE_ODR =>
                                LinkType.LinkonceOdr
                            case PackageFormat_Linkage.Linkage_EXTERNAL_WEAK =>
                                LinkType.ExternalWeak
                        }
                    )
                case PackageFormat_Annotation.Annotation_SKIPCHECK =>
                    base.setAnno<SkipCheck, SkipKind>(
                        match(baseFormat.GetAnnosAsSkipCheck(index)
                        .getOrThrow().GetSkipKind()){
                            case PackageFormat_SkipKind.SkipKind_NO_SKIP =>
                                SkipKind.NoSkip
                            case PackageFormat_SkipKind.SkipKind_SKIP_DCE_WARNING =>
                                SkipKind.SkipDceWarning
                            case PackageFormat_SkipKind.SkipKind_SKIP_FORIN_EXIT =>
                                SkipKind.SkipForinExit
                            case PackageFormat_SkipKind.SkipKind_SKIP_VIC =>
                                SkipKind.SkipVic
                        })
                case PackageFormat_Annotation.Annotation_NEVEROVERFLOWINFO =>
                    base.setAnno<NeverOverflowInfo, Bool>(
                        baseFormat.GetAnnosAsNeverOverflowInfo(index)
                        .getOrThrow().GetNeverOverflow())
                case PackageFormat_Annotation.Annotation_GENERATEDFROMFORIN =>
                    base.setAnno<GeneratedFromForIn, Bool>(
                        baseFormat.GetAnnosAsGeneratedFromForIn(index)
                        .getOrThrow().GetValue())
                case PackageFormat_Annotation.Annotation_ISAUTOENVCLASS =>
                    base.setAnno<IsAutoEnvClass, Bool>(
                        baseFormat.GetAnnosAsIsAutoEnvClass(index)
                        .getOrThrow().GetValue())
                case PackageFormat_Annotation.Annotation_ISCAPTUREDCLASSINCC =>
                    base.setAnno<IsCapturedClassInCC, Bool>(
                        baseFormat.GetAnnosAsIsCapturedClassInCC(index)
                        .getOrThrow().GetValue())
                case PackageFormat_Annotation.Annotation_ENUMCASEINDEX =>
                    let caseIndex = baseFormat.GetAnnosAsEnumCaseIndex(index)
                        .getOrThrow().GetIndex()
                    if (caseIndex != -1) {
                        base.setAnno<EnumCaseIndex, Option<UInt64>>(Some(UInt64(caseIndex)))
                    }
                case PackageFormat_Annotation.Annotation_VIRMETHODOFFSET =>
                    let offset = baseFormat.GetAnnosAsVirMethodOffset(index).getOrThrow().GetOffset()
                    if (offset != -1) {
                        base.setAnno<VirMethodOffset, Option<UInt64>>(Some(UInt64(offset)))
                    }
                case PackageFormat_Annotation.Annotation_WRAPPEDRAWMETHOD =>
                    base.setAnno<WrappedRawMethod, Option<Function>>(Some(getValueAs<Function>(
                        baseFormat.GetAnnosAsWrappedRawMethod(index).getOrThrow().GetRawMethod())))
                case PackageFormat_Annotation.Annotation_OVERRIDESRCFUNCTYPE =>
                    base.setAnno<OverrideSrcFuncType, Option<FuncType>>(Some(getTypeAs<FuncType>(
                        baseFormat.GetAnnosAsOverrideSrcFuncType(index).getOrThrow().GetType())))
                case _ => ()
            }
        }
        if (let Some(v) <- baseFormat.GetLoc()) {
            base._debugLocation = deserializeDebugLocation(v)
        }
        base._attributes.appendAttrs(AttributeInfo(baseFormat.GetAttributes()))
    }

    private func configExpression(exprFormat: PackageFormat_Expression, expr: Expression) {
        configBase(exprFormat.GetBase().getOrThrow(), expr)

        expr._owner = getValueAs<Block>(exprFormat.GetOwner())
        // some terminators don't have result
        if (let Some(v) <- tryGetType(exprFormat.GetResultTy())) {
            let result = LocalVar(v, expr)
            expr._result = result
        }
        for (id in exprFormat.GetBlockGroups()) {
            expr.addBlockGroup(getValueAs<BlockGroup>(id))
        }
    }

    private func configLambda(buffer: PackageFormat_Lambda, lambda: Lambda) {
        configExpression(buffer.GetBase().getOrThrow(), lambda)
        for (id in buffer.GetParams()) {
            lambda._parameters.add(getValueAs<Parameter>(id))
        }
        lambda._returnValue = getValueAs<LocalVar>(buffer.GetRetVal())
    }

    private func convertExprKind(kind: PackageFormat_CHIRExprKind): ExprKind {
        return match (kind) {
            case PackageFormat_CHIRExprKind.CHIRExprKind_INVALID => throw IllegalArgumentException("Invalid ExprKind")
            case PackageFormat_CHIRExprKind.CHIRExprKind_GOTO => ExprKind.Goto
            case PackageFormat_CHIRExprKind.CHIRExprKind_BRANCH => ExprKind.Branch
            case PackageFormat_CHIRExprKind.CHIRExprKind_MULTIBRANCH => ExprKind.MultiBranch
            case PackageFormat_CHIRExprKind.CHIRExprKind_EXIT => ExprKind.Exit
            case PackageFormat_CHIRExprKind.CHIRExprKind_TRYAPPLY => ExprKind.TryApply
            case PackageFormat_CHIRExprKind.CHIRExprKind_TRYINVOKE => ExprKind.TryInvoke
            case PackageFormat_CHIRExprKind.CHIRExprKind_TRYINTRINSIC => ExprKind.TryIntrinsic
            case PackageFormat_CHIRExprKind.CHIRExprKind_RAISEEXCEPTION => ExprKind.RaiseException
            case PackageFormat_CHIRExprKind.CHIRExprKind_TRYSPAWN => ExprKind.TrySpawn
            case PackageFormat_CHIRExprKind.CHIRExprKind_TRYNUMERICCAST => ExprKind.TryNumericCast
            case PackageFormat_CHIRExprKind.CHIRExprKind_TRYALLOCATE => ExprKind.TryAllocate
            case PackageFormat_CHIRExprKind.CHIRExprKind_TRYRAWARRAYALLOCATE => ExprKind.TryRawArrayAllocate
            case PackageFormat_CHIRExprKind.CHIRExprKind_TRYNEG => ExprKind.TryNeg
            case PackageFormat_CHIRExprKind.CHIRExprKind_TRYADD => ExprKind.TryAdd
            case PackageFormat_CHIRExprKind.CHIRExprKind_TRYSUB => ExprKind.TrySub
            case PackageFormat_CHIRExprKind.CHIRExprKind_TRYMUL => ExprKind.TryMul
            case PackageFormat_CHIRExprKind.CHIRExprKind_TRYDIV => ExprKind.TryDiv
            case PackageFormat_CHIRExprKind.CHIRExprKind_TRYMOD => ExprKind.TryMod
            case PackageFormat_CHIRExprKind.CHIRExprKind_TRYEXP => ExprKind.TryExp
            case PackageFormat_CHIRExprKind.CHIRExprKind_TRYLSHIFT => ExprKind.TryLShift
            case PackageFormat_CHIRExprKind.CHIRExprKind_TRYRSHIFT => ExprKind.TryRShift
            case PackageFormat_CHIRExprKind.CHIRExprKind_NEG => ExprKind.Neg
            case PackageFormat_CHIRExprKind.CHIRExprKind_NOT => ExprKind.Not
            case PackageFormat_CHIRExprKind.CHIRExprKind_BITNOT => ExprKind.BitNot
            case PackageFormat_CHIRExprKind.CHIRExprKind_ADD => ExprKind.Add
            case PackageFormat_CHIRExprKind.CHIRExprKind_SUB => ExprKind.Sub
            case PackageFormat_CHIRExprKind.CHIRExprKind_MUL => ExprKind.Mul
            case PackageFormat_CHIRExprKind.CHIRExprKind_DIV => ExprKind.Div
            case PackageFormat_CHIRExprKind.CHIRExprKind_MOD => ExprKind.Mod
            case PackageFormat_CHIRExprKind.CHIRExprKind_EXP => ExprKind.Exp
            case PackageFormat_CHIRExprKind.CHIRExprKind_LSHIFT => ExprKind.LShift
            case PackageFormat_CHIRExprKind.CHIRExprKind_RSHIFT => ExprKind.RShift
            case PackageFormat_CHIRExprKind.CHIRExprKind_BITAND => ExprKind.BitAnd
            case PackageFormat_CHIRExprKind.CHIRExprKind_BITOR => ExprKind.BitOr
            case PackageFormat_CHIRExprKind.CHIRExprKind_BITXOR => ExprKind.BitXor
            case PackageFormat_CHIRExprKind.CHIRExprKind_LT => ExprKind.LT
            case PackageFormat_CHIRExprKind.CHIRExprKind_GT => ExprKind.GT
            case PackageFormat_CHIRExprKind.CHIRExprKind_LE => ExprKind.LE
            case PackageFormat_CHIRExprKind.CHIRExprKind_GE => ExprKind.GE
            case PackageFormat_CHIRExprKind.CHIRExprKind_EQUAL => ExprKind.Equal
            case PackageFormat_CHIRExprKind.CHIRExprKind_NOTEQUAL => ExprKind.NotEqual
            case PackageFormat_CHIRExprKind.CHIRExprKind_AND => ExprKind.And
            case PackageFormat_CHIRExprKind.CHIRExprKind_OR => ExprKind.Or
            case PackageFormat_CHIRExprKind.CHIRExprKind_STATICCAST => ExprKind.StaticCast
            case PackageFormat_CHIRExprKind.CHIRExprKind_BOX => ExprKind.Box
            case PackageFormat_CHIRExprKind.CHIRExprKind_UNBOXTOVALUE => ExprKind.UnboxToValue
            case PackageFormat_CHIRExprKind.CHIRExprKind_UNBOXTOREF => ExprKind.UnboxToRef
            case PackageFormat_CHIRExprKind.CHIRExprKind_NUMERICCAST => ExprKind.NumericCast
            case PackageFormat_CHIRExprKind.CHIRExprKind_CASTTOCONCRETE => ExprKind.CastToConcrete
            case PackageFormat_CHIRExprKind.CHIRExprKind_CASTTOGENERIC => ExprKind.CastToGeneric
            case PackageFormat_CHIRExprKind.CHIRExprKind_ALLOCATE => ExprKind.Allocate
            case PackageFormat_CHIRExprKind.CHIRExprKind_LOAD => ExprKind.Load
            case PackageFormat_CHIRExprKind.CHIRExprKind_STORE => ExprKind.Store
            case PackageFormat_CHIRExprKind.CHIRExprKind_GETELEMENTBYNAME => ExprKind.GetElementByName
            case PackageFormat_CHIRExprKind.CHIRExprKind_GETELEMENTREF => ExprKind.GetElementRef
            case PackageFormat_CHIRExprKind.CHIRExprKind_STOREELEMENTBYNAME => ExprKind.StoreElementByName
            case PackageFormat_CHIRExprKind.CHIRExprKind_STOREELEMENTREF => ExprKind.StoreElementRef
            case PackageFormat_CHIRExprKind.CHIRExprKind_FIELD => ExprKind.Field
            case PackageFormat_CHIRExprKind.CHIRExprKind_FIELDBYNAME => ExprKind.FieldByName
            case PackageFormat_CHIRExprKind.CHIRExprKind_RAWARRAYALLOCATE => ExprKind.RawArrayAllocate
            case PackageFormat_CHIRExprKind.CHIRExprKind_RAWARRAYLITERALINIT => ExprKind.RawArrayLiteralInit
            case PackageFormat_CHIRExprKind.CHIRExprKind_RAWARRAYINITBYVALUE => ExprKind.RawArrayInitByValue
            case PackageFormat_CHIRExprKind.CHIRExprKind_VARRAYEXPR => ExprKind.VArrayExpr
            case PackageFormat_CHIRExprKind.CHIRExprKind_VARRAYBUILDER => ExprKind.VArrayBuilder
            case PackageFormat_CHIRExprKind.CHIRExprKind_CONSTANT => ExprKind.Constant
            case PackageFormat_CHIRExprKind.CHIRExprKind_DEBUG => ExprKind.Debug
            case PackageFormat_CHIRExprKind.CHIRExprKind_TUPLE => ExprKind.Tuple
            case PackageFormat_CHIRExprKind.CHIRExprKind_INSTANCEOF => ExprKind.InstanceOf
            case PackageFormat_CHIRExprKind.CHIRExprKind_GETEXCEPTION => ExprKind.GetException
            case PackageFormat_CHIRExprKind.CHIRExprKind_SPAWN => ExprKind.Spawn
            case PackageFormat_CHIRExprKind.CHIRExprKind_LAMBDA => ExprKind.Lambda
            case PackageFormat_CHIRExprKind.CHIRExprKind_GETINSTANTIATEVALUE => ExprKind.GetInstantiateValue
            case PackageFormat_CHIRExprKind.CHIRExprKind_APPLY => ExprKind.Apply
            case PackageFormat_CHIRExprKind.CHIRExprKind_INVOKE => ExprKind.Invoke
            case PackageFormat_CHIRExprKind.CHIRExprKind_INTRINSIC => ExprKind.Intrinsic
            case PackageFormat_CHIRExprKind.CHIRExprKind_GETRTTI => ExprKind.GetRtti
            case PackageFormat_CHIRExprKind.CHIRExprKind_GETRTTISTATIC => ExprKind.GetRttiStatic
        }
    }

    private func convertOverflowStrategy(strategy: PackageFormat_OverflowStrategy): OverflowStrategy {
        return match (strategy) {
            case PackageFormat_OverflowStrategy.OverflowStrategy_WRAPPING => OverflowStrategy.Wrapping
            case PackageFormat_OverflowStrategy.OverflowStrategy_THROWING => OverflowStrategy.Throwing
            case PackageFormat_OverflowStrategy.OverflowStrategy_SATURATING => OverflowStrategy.Saturating
            case PackageFormat_OverflowStrategy.OverflowStrategy_NA => OverflowStrategy.NA
            case _ => throw CHIRException("Unsupported OverflowStrategy")
        }
    }

    private func convertSourceExpr(sourceExpr: PackageFormat_SourceExpr): SourceExpr {
        return match (sourceExpr) {
            case PackageFormat_SourceExpr.SourceExpr_IF_EXPR => SourceExpr.IfExpr
            case PackageFormat_SourceExpr.SourceExpr_WHILE_EXPR => SourceExpr.WhileExpr
            case PackageFormat_SourceExpr.SourceExpr_DO_WHILE_EXPR => SourceExpr.DoWhileExpr
            case PackageFormat_SourceExpr.SourceExpr_MATCH_EXPR => SourceExpr.MatchExpr
            case PackageFormat_SourceExpr.SourceExpr_IF_LET_OR_WHILE_LET => SourceExpr.IfLetOrWhileLet
            case PackageFormat_SourceExpr.SourceExpr_QUEST => SourceExpr.Quest
            case PackageFormat_SourceExpr.SourceExpr_BINARY => SourceExpr.Binary
            case PackageFormat_SourceExpr.SourceExpr_FOR_IN_EXPR => SourceExpr.ForInExpr
            case PackageFormat_SourceExpr.SourceExpr_OTHER => SourceExpr.Other
        }
    }

    private func convertIntrinsicKind(kind: PackageFormat_IntrinsicKind): IntrinsicKind {
        return match (kind) {
            case PackageFormat_IntrinsicKind.IntrinsicKind_NOT_INTRINSIC => IntrinsicKind.NotIntrinsic
            case PackageFormat_IntrinsicKind.IntrinsicKind_NOT_IMPLEMENTED => IntrinsicKind.NotImplemented
            case PackageFormat_IntrinsicKind.IntrinsicKind_ARRAY_INIT => IntrinsicKind.ArrayInit
            case PackageFormat_IntrinsicKind.IntrinsicKind_SIZE_OF => IntrinsicKind.SizeOf
            case PackageFormat_IntrinsicKind.IntrinsicKind_ALIGN_OF => IntrinsicKind.AlignOf
            case PackageFormat_IntrinsicKind.IntrinsicKind_ARRAY_ACQUIRE_RAW_DATA => IntrinsicKind.ArrayAcquireRawData
            case PackageFormat_IntrinsicKind.IntrinsicKind_ARRAY_RELEASE_RAW_DATA => IntrinsicKind.ArrayReleaseRawData
            case PackageFormat_IntrinsicKind.IntrinsicKind_ARRAY_BUILT_IN_COPY_TO => IntrinsicKind.ArrayBuiltInCopyTo
            case PackageFormat_IntrinsicKind.IntrinsicKind_ARRAY_GET => IntrinsicKind.ArrayGet
            case PackageFormat_IntrinsicKind.IntrinsicKind_ARRAY_SET => IntrinsicKind.ArraySet
            case PackageFormat_IntrinsicKind.IntrinsicKind_ARRAY_GET_UNCHECKED => IntrinsicKind.ArrayGetUnchecked
            case PackageFormat_IntrinsicKind.IntrinsicKind_ARRAY_GET_REF_UNCHECKED => IntrinsicKind.ArrayGetRefUnchecked
            case PackageFormat_IntrinsicKind.IntrinsicKind_ARRAY_SET_UNCHECKED => IntrinsicKind.ArraySetUnchecked
            case PackageFormat_IntrinsicKind.IntrinsicKind_ARRAY_SIZE => IntrinsicKind.ArraySize
            case PackageFormat_IntrinsicKind.IntrinsicKind_ARRAY_CLONE => IntrinsicKind.ArrayClone
            case PackageFormat_IntrinsicKind.IntrinsicKind_ARRAY_SLICE_INIT => IntrinsicKind.ArraySliceInit
            case PackageFormat_IntrinsicKind.IntrinsicKind_ARRAY_SLICE => IntrinsicKind.ArraySlice
            case PackageFormat_IntrinsicKind.IntrinsicKind_ARRAY_SLICE_RAWARRAY => IntrinsicKind.ArraySliceRawArray
            case PackageFormat_IntrinsicKind.IntrinsicKind_ARRAY_SLICE_START => IntrinsicKind.ArraySliceStart
            case PackageFormat_IntrinsicKind.IntrinsicKind_ARRAY_SLICE_SIZE => IntrinsicKind.ArraySliceSize
            case PackageFormat_IntrinsicKind.IntrinsicKind_ARRAY_SLICE_GET_ELEMENT => IntrinsicKind.ArraySliceGetElement
            case PackageFormat_IntrinsicKind.IntrinsicKind_ARRAY_SLICE_GET_ELEMENT_UNCHECKED => IntrinsicKind.ArraySliceGetElementUnchecked
            case PackageFormat_IntrinsicKind.IntrinsicKind_ARRAY_SLICE_SET_ELEMENT => IntrinsicKind.ArraySliceSetElement
            case PackageFormat_IntrinsicKind.IntrinsicKind_ARRAY_SLICE_SET_ELEMENT_UNCHECKED => IntrinsicKind.ArraySliceSetElementUnchecked
            case PackageFormat_IntrinsicKind.IntrinsicKind_FILL_IN_STACK_TRACE => IntrinsicKind.FillInStackTrace
            case PackageFormat_IntrinsicKind.IntrinsicKind_DECODE_STACK_TRACE => IntrinsicKind.DecodeStackTrace
            case PackageFormat_IntrinsicKind.IntrinsicKind_DUMP_CURRENT_THREAD_INFO => IntrinsicKind.DumpCurrentThreadInfo
            case PackageFormat_IntrinsicKind.IntrinsicKind_DUMP_ALL_THREADS_INFO => IntrinsicKind.DumpAllThreadsInfo
            case PackageFormat_IntrinsicKind.IntrinsicKind_CHR => IntrinsicKind.Chr
            case PackageFormat_IntrinsicKind.IntrinsicKind_ORD => IntrinsicKind.Ord
            case PackageFormat_IntrinsicKind.IntrinsicKind_CPOINTER_GET_POINTER_ADDRESS => IntrinsicKind.CPointerGetPointerAddress
            case PackageFormat_IntrinsicKind.IntrinsicKind_CPOINTER_INIT0 => IntrinsicKind.CPointerInit0
            case PackageFormat_IntrinsicKind.IntrinsicKind_CPOINTER_INIT1 => IntrinsicKind.CPointerInit1
            case PackageFormat_IntrinsicKind.IntrinsicKind_CPOINTER_READ => IntrinsicKind.CPointerRead
            case PackageFormat_IntrinsicKind.IntrinsicKind_CPOINTER_WRITE => IntrinsicKind.CPointerWrite
            case PackageFormat_IntrinsicKind.IntrinsicKind_CPOINTER_ADD => IntrinsicKind.CPointerAdd
            case PackageFormat_IntrinsicKind.IntrinsicKind_CSTRING_INIT => IntrinsicKind.CStringInit
            case PackageFormat_IntrinsicKind.IntrinsicKind_CSTRING_CONVERT_CSTR_TO_PTR => IntrinsicKind.CStringConvertCstrToPtr
            case PackageFormat_IntrinsicKind.IntrinsicKind_INOUT_PARAM => IntrinsicKind.InoutParam
            case PackageFormat_IntrinsicKind.IntrinsicKind_REGISTER_WATCHED_OBJECT => IntrinsicKind.RegisterWatchedObject
            case PackageFormat_IntrinsicKind.IntrinsicKind_OBJECT_REFEQ => IntrinsicKind.ObjectRefeq
            case PackageFormat_IntrinsicKind.IntrinsicKind_RAW_ARRAY_REFEQ => IntrinsicKind.RawArrayRefeq
            case PackageFormat_IntrinsicKind.IntrinsicKind_FUNC_REFEQ => IntrinsicKind.FuncRefeq
            case PackageFormat_IntrinsicKind.IntrinsicKind_OBJECT_ZERO_VALUE => IntrinsicKind.ObjectZeroValue
            case PackageFormat_IntrinsicKind.IntrinsicKind_INVOKE_GC => IntrinsicKind.InvokeGc
            case PackageFormat_IntrinsicKind.IntrinsicKind_SET_GC_THRESHOLD => IntrinsicKind.SetGcThreshold
            case PackageFormat_IntrinsicKind.IntrinsicKind_DUMP_CJ_HEAP_DATA => IntrinsicKind.DumpCjHeapData
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_GC_COUNT => IntrinsicKind.GetGcCount
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_GC_TIME_US => IntrinsicKind.GetGcTimeUs
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_GC_FREED_SIZE => IntrinsicKind.GetGcFreedSize
            case PackageFormat_IntrinsicKind.IntrinsicKind_START_CJ_CPU_PROFILING => IntrinsicKind.StartCjCpuProfiling
            case PackageFormat_IntrinsicKind.IntrinsicKind_STOP_CJ_CPU_PROFILING => IntrinsicKind.StopCjCpuProfiling
            case PackageFormat_IntrinsicKind.IntrinsicKind_BLACK_BOX => IntrinsicKind.BlackBox
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_MAX_HEAP_SIZE => IntrinsicKind.GetMaxHeapSize
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_ALLOCATE_HEAP_SIZE => IntrinsicKind.GetAllocateHeapSize
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_REAL_HEAP_SIZE => IntrinsicKind.GetRealHeapSize
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_THREAD_NUMBER => IntrinsicKind.GetThreadNumber
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_BLOCKING_THREAD_NUMBER => IntrinsicKind.GetBlockingThreadNumber
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_NATIVE_THREAD_NUMBER => IntrinsicKind.GetNativeThreadNumber
            case PackageFormat_IntrinsicKind.IntrinsicKind_VARRAY_SET => IntrinsicKind.VArraySet
            case PackageFormat_IntrinsicKind.IntrinsicKind_VARRAY_GET => IntrinsicKind.VArrayGet
            case PackageFormat_IntrinsicKind.IntrinsicKind_FUTURE_INIT => IntrinsicKind.FutureInit
            case PackageFormat_IntrinsicKind.IntrinsicKind_FUTURE_IS_COMPLETE => IntrinsicKind.FutureIsComplete
            case PackageFormat_IntrinsicKind.IntrinsicKind_FUTURE_WAIT => IntrinsicKind.FutureWait
            case PackageFormat_IntrinsicKind.IntrinsicKind_FUTURE_NOTIFYALL => IntrinsicKind.FutureNotifyAll
            case PackageFormat_IntrinsicKind.IntrinsicKind_IS_THREAD_OBJECT_INITED => IntrinsicKind.IsThreadObjectInited
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_THREAD_OBJECT => IntrinsicKind.GetThreadObject
            case PackageFormat_IntrinsicKind.IntrinsicKind_SET_THREAD_OBJECT => IntrinsicKind.SetThreadObject
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_CHECKED_ADD => IntrinsicKind.OverflowCheckedAdd
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_CHECKED_SUB => IntrinsicKind.OverflowCheckedSub
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_CHECKED_MUL => IntrinsicKind.OverflowCheckedMul
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_CHECKED_DIV => IntrinsicKind.OverflowCheckedDiv
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_CHECKED_MOD => IntrinsicKind.OverflowCheckedMod
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_CHECKED_POW => IntrinsicKind.OverflowCheckedPow
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_CHECKED_INC => IntrinsicKind.OverflowCheckedInc
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_CHECKED_DEC => IntrinsicKind.OverflowCheckedDec
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_CHECKED_NEG => IntrinsicKind.OverflowCheckedNeg
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_THROWING_ADD => IntrinsicKind.OverflowThrowingAdd
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_THROWING_SUB => IntrinsicKind.OverflowThrowingSub
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_THROWING_MUL => IntrinsicKind.OverflowThrowingMul
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_THROWING_DIV => IntrinsicKind.OverflowThrowingDiv
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_THROWING_MOD => IntrinsicKind.OverflowThrowingMod
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_THROWING_POW => IntrinsicKind.OverflowThrowingPow
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_THROWING_INC => IntrinsicKind.OverflowThrowingInc
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_THROWING_DEC => IntrinsicKind.OverflowThrowingDec
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_THROWING_NEG => IntrinsicKind.OverflowThrowingNeg
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_SATURATING_ADD => IntrinsicKind.OverflowSaturatingAdd
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_SATURATING_SUB => IntrinsicKind.OverflowSaturatingSub
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_SATURATING_MUL => IntrinsicKind.OverflowSaturatingMul
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_SATURATING_DIV => IntrinsicKind.OverflowSaturatingDiv
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_SATURATING_MOD => IntrinsicKind.OverflowSaturatingMod
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_SATURATING_POW => IntrinsicKind.OverflowSaturatingPow
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_SATURATING_INC => IntrinsicKind.OverflowSaturatingInc
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_SATURATING_DEC => IntrinsicKind.OverflowSaturatingDec
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_SATURATING_NEG => IntrinsicKind.OverflowSaturatingNeg
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_WRAPPING_ADD => IntrinsicKind.OverflowWrappingAdd
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_WRAPPING_SUB => IntrinsicKind.OverflowWrappingSub
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_WRAPPING_MUL => IntrinsicKind.OverflowWrappingMul
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_WRAPPING_DIV => IntrinsicKind.OverflowWrappingDiv
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_WRAPPING_MOD => IntrinsicKind.OverflowWrappingMod
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_WRAPPING_POW => IntrinsicKind.OverflowWrappingPow
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_WRAPPING_INC => IntrinsicKind.OverflowWrappingInc
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_WRAPPING_DEC => IntrinsicKind.OverflowWrappingDec
            case PackageFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_WRAPPING_NEG => IntrinsicKind.OverflowWrappingNeg
            case PackageFormat_IntrinsicKind.IntrinsicKind_VECTOR_COMPARE_32 => IntrinsicKind.VectorCompare32
            case PackageFormat_IntrinsicKind.IntrinsicKind_VECTOR_INDEX_BYTE_32 => IntrinsicKind.VectorIndexByte32
            case PackageFormat_IntrinsicKind.IntrinsicKind_CJ_CORE_CAN_USE_SIMD => IntrinsicKind.CjCoreCanUseSimd
            case PackageFormat_IntrinsicKind.IntrinsicKind_CJ_TLS_DYN_SET_SESSION_CALLBACK => IntrinsicKind.CjTlsDynSetSessionCallback
            case PackageFormat_IntrinsicKind.IntrinsicKind_CJ_TLS_DYN_SSL_INIT => IntrinsicKind.CjTlsDynSslInit
            case PackageFormat_IntrinsicKind.IntrinsicKind_REFLECTION_INTRINSIC_START_FLAG => IntrinsicKind.ReflectionIntrinsicStartFlag
            case PackageFormat_IntrinsicKind.IntrinsicKind_IS_INTERFACE => IntrinsicKind.IsInterface
            case PackageFormat_IntrinsicKind.IntrinsicKind_IS_CLASS => IntrinsicKind.IsClass
            case PackageFormat_IntrinsicKind.IntrinsicKind_IS_PRIMITIVE => IntrinsicKind.IsPrimitive
            case PackageFormat_IntrinsicKind.IntrinsicKind_IS_STRUCT => IntrinsicKind.IsStruct
            case PackageFormat_IntrinsicKind.IntrinsicKind_IS_GENERIC => IntrinsicKind.IsGeneric
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_OR_CREATE_TYPEINFO_FOR_REFLECT => IntrinsicKind.GetOrCreateTypeInfoForReflect
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_TYPETEMPLATE => IntrinsicKind.GetTypeTemplate
            case PackageFormat_IntrinsicKind.IntrinsicKind_CHECK_METHOD_ACTUAL_ARGS => IntrinsicKind.CheckMethodActualArgs
            case PackageFormat_IntrinsicKind.IntrinsicKind_METHOD_ENTRYPOINT_IS_NULL => IntrinsicKind.MethodEntrypointIsNull
            case PackageFormat_IntrinsicKind.IntrinsicKind_IS_RELECT_UNSUPPORTED_TYPE => IntrinsicKind.IsRelectUnsupportedType
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_TYPE_FOR_ANY => IntrinsicKind.GetTypeForAny
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_TYPE_BY_MANGLED_NAME => IntrinsicKind.GetTypeByMangledName
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_TYPE_NAME => IntrinsicKind.GetTypeName
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_TYPE_BY_QUALIFIED_NAME => IntrinsicKind.GetTypeByQualifiedName
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_TYPE_QUALIFIED_NAME_LENGTH => IntrinsicKind.GetTypeQualifiedNameLength
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_TYPE_QUALIFIED_NAME => IntrinsicKind.GetTypeQualifiedName
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_NUM_OF_INTERFACE => IntrinsicKind.GetNumOfInterface
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_INTERFACE => IntrinsicKind.GetInterface
            case PackageFormat_IntrinsicKind.IntrinsicKind_IS_SUBTYPE => IntrinsicKind.IsSubtype
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_TYPE_INFO_MODIFIER => IntrinsicKind.GetTypeInfoModifier
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_TYPE_INFO_ANNOTATIONS => IntrinsicKind.GetTypeInfoAnnotations
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_OBJ_CLASS => IntrinsicKind.GetObjClass
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_SUPER_TYPE_INFO => IntrinsicKind.GetSuperTypeInfo
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_NUM_OF_INSTANCE_METHOD_INFOS => IntrinsicKind.GetNumOfInstanceMethodInfos
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_INSTANCE_METHOD_INFO => IntrinsicKind.GetInstanceMethodInfo
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_NUM_OF_STATIC_METHOD_INFOS => IntrinsicKind.GetNumOfStaticMethodInfos
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_STATIC_METHOD_INFO => IntrinsicKind.GetStaticMethodInfo
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_METHOD_NAME => IntrinsicKind.GetMethodName
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_METHOD_RETURN_TYPE => IntrinsicKind.GetMethodReturnType
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_METHOD_MODIFIER => IntrinsicKind.GetMethodModifier
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_METHOD_ANNOTATIONS => IntrinsicKind.GetMethodAnnotations
            case PackageFormat_IntrinsicKind.IntrinsicKind_APPLY_CJ_METHOD => IntrinsicKind.ApplyCjMethod
            case PackageFormat_IntrinsicKind.IntrinsicKind_APPLY_CJ_STATIC_METHOD => IntrinsicKind.ApplyCjStaticMethod
            case PackageFormat_IntrinsicKind.IntrinsicKind_APPLY_CJ_GENERIC_METHOD => IntrinsicKind.ApplyCjGenericMethod
            case PackageFormat_IntrinsicKind.IntrinsicKind_APPLY_CJ_GENERIC_STATIC_METHOD => IntrinsicKind.ApplyCjGenericStaticMethod
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_NUM_OF_ACTUAL_PARAMETERS => IntrinsicKind.GetNumOfActualParameters
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_NUM_OF_GENERIC_PARAMETERS => IntrinsicKind.GetNumOfGenericParameters
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_ACTUAL_PARAMETER_INFO => IntrinsicKind.GetActualParameterInfo
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_GENERIC_PARAMETER_INFO => IntrinsicKind.GetGenericParameterInfo
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_NUM_OF_INSTANCE_FIELD_INFOS => IntrinsicKind.GetNumOfInstanceFieldInfos
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_INSTANCE_FIELD_INFO => IntrinsicKind.GetInstanceFieldInfo
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_NUM_OF_STATIC_FIELD_INFOS => IntrinsicKind.GetNumOfStaticFieldInfos
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_STATIC_FIELD_INFO => IntrinsicKind.GetStaticFieldInfo
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_STATIC_FIELD_NAME => IntrinsicKind.GetStaticFieldName
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_STATIC_FIELD_TYPE => IntrinsicKind.GetStaticFieldType
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_STATIC_FIELD_ANNOTATIONS => IntrinsicKind.GetStaticFieldAnnotations
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_STATIC_FIELD_MODIFIER => IntrinsicKind.GetStaticFieldModifier
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_FIELD_VALUE => IntrinsicKind.GetFieldValue
            case PackageFormat_IntrinsicKind.IntrinsicKind_SET_FIELD_VALUE => IntrinsicKind.SetFieldValue
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_STATIC_FIELD_VALUE => IntrinsicKind.GetStaticFieldValue
            case PackageFormat_IntrinsicKind.IntrinsicKind_SET_STATIC_FIELD_VALUE => IntrinsicKind.SetStaticFieldValue
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_FIELD_DECLARING_TYPE => IntrinsicKind.GetFieldDeclaringType
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_PARAMETER_INDEX => IntrinsicKind.GetParameterIndex
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_PARAMETER_NAME => IntrinsicKind.GetParameterName
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_PARAMETER_TYPE => IntrinsicKind.GetParameterType
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_PARAMETER_ANNOTATIONS => IntrinsicKind.GetParameterAnnotations
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_RELATED_PACKAGE_INF => IntrinsicKind.GetRelatedPackageInf
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_PACKAGE_NAME => IntrinsicKind.GetPackageName
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_PACKAGE_NUM_OF_TYPE_INFOS => IntrinsicKind.GetPackageNumOfTypeInfos
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_PACKAGE_TYPE_INFO => IntrinsicKind.GetPackageTypeInfo
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_PACKAGE_NUM_OF_GLOBAL_METHODS => IntrinsicKind.GetPackageNumOfGlobalMethods
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_PACKAGE_GLOBAL_METHOD_INFO => IntrinsicKind.GetPackageGlobalMethodInfo
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_PACKAGE_NUM_OF_GLOBAL_FIELD_INFOS => IntrinsicKind.GetPackageNumOfGlobalFieldInfos
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_PACKAGE_GLOBAL_FIELD_INFO => IntrinsicKind.GetPackageGlobalFieldInfo
            case PackageFormat_IntrinsicKind.IntrinsicKind_LOAD_PACKAGE => IntrinsicKind.LoadPackage
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_PACKAGE_BY_QUALIFIEDNAME => IntrinsicKind.GetPackageByQualifiedName
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_PACKAGE_VERSION => IntrinsicKind.GetPackageVersion
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_SUB_PACKAGES => IntrinsicKind.GetSubPackages
            case PackageFormat_IntrinsicKind.IntrinsicKind_REFLECTION_INTRINSIC_END_FLAG => IntrinsicKind.ReflectionIntrinsicEndFlag
            case PackageFormat_IntrinsicKind.IntrinsicKind_SLEEP => IntrinsicKind.Sleep
            case PackageFormat_IntrinsicKind.IntrinsicKind_SOURCE_FILE => IntrinsicKind.SourceFile
            case PackageFormat_IntrinsicKind.IntrinsicKind_SOURCE_LINE => IntrinsicKind.SourceLine
            case PackageFormat_IntrinsicKind.IntrinsicKind_IDENTITY_HASHCODE => IntrinsicKind.IdentityHashCode
            case PackageFormat_IntrinsicKind.IntrinsicKind_IDENTITY_HASHCODE_FOR_ARRAY => IntrinsicKind.IdentityHashCodeForArray
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_LOAD => IntrinsicKind.AtomicLoad
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_STORE => IntrinsicKind.AtomicStore
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_SWAP => IntrinsicKind.AtomicSwap
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_COMPARE_AND_SWAP => IntrinsicKind.AtomicCompareAndSwap
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_FETCH_ADD => IntrinsicKind.AtomicFetchAdd
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_FETCH_SUB => IntrinsicKind.AtomicFetchSub
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_FETCH_AND => IntrinsicKind.AtomicFetchAnd
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_FETCH_OR => IntrinsicKind.AtomicFetchOr
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_FETCH_XOR => IntrinsicKind.AtomicFetchXor
            case PackageFormat_IntrinsicKind.IntrinsicKind_MUTEX_INIT => IntrinsicKind.MutexInit
            case PackageFormat_IntrinsicKind.IntrinsicKind_CJ_MUTEX_LOCK => IntrinsicKind.CjMutexLock
            case PackageFormat_IntrinsicKind.IntrinsicKind_MUTEX_TRY_LOCK => IntrinsicKind.MutexTryLock
            case PackageFormat_IntrinsicKind.IntrinsicKind_MUTEX_CHECK_STATUS => IntrinsicKind.MutexCheckStatus
            case PackageFormat_IntrinsicKind.IntrinsicKind_MUTEX_UNLOCK => IntrinsicKind.MutexUnlock
            case PackageFormat_IntrinsicKind.IntrinsicKind_WAITQUEUE_INIT => IntrinsicKind.WaitQueueInit
            case PackageFormat_IntrinsicKind.IntrinsicKind_MONITOR_INIT => IntrinsicKind.MonitorInit
            case PackageFormat_IntrinsicKind.IntrinsicKind_MOITIOR_WAIT => IntrinsicKind.MoitiorWait
            case PackageFormat_IntrinsicKind.IntrinsicKind_MOITIOR_NOTIFY => IntrinsicKind.MoitiorNotify
            case PackageFormat_IntrinsicKind.IntrinsicKind_MOITIOR_NOTIFY_ALL => IntrinsicKind.MoitiorNotifyAll
            case PackageFormat_IntrinsicKind.IntrinsicKind_MULTICONDITION_WAIT => IntrinsicKind.MulticonditionWait
            case PackageFormat_IntrinsicKind.IntrinsicKind_MULTICONDITION_NOTIFY => IntrinsicKind.MulticonditionNotify
            case PackageFormat_IntrinsicKind.IntrinsicKind_MULTICONDITION_NOTIFY_ALL => IntrinsicKind.MulticonditionNotifyAll
            case PackageFormat_IntrinsicKind.IntrinsicKind_CROSS_ACCESS_BARRIER => IntrinsicKind.CrossAccessBarrier
            case PackageFormat_IntrinsicKind.IntrinsicKind_CREATE_EXPORT_HANDLE => IntrinsicKind.CreateExportHandle
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_EXPORTED_REF => IntrinsicKind.GetExportedRef
            case PackageFormat_IntrinsicKind.IntrinsicKind_REMOVE_EXPORTED_REF => IntrinsicKind.RemoveExportedRef
            case PackageFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_AST_LEX => IntrinsicKind.FfiCjAstLex
            case PackageFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_AST_PARSEEXPR => IntrinsicKind.FfiCjAstParseExpr
            case PackageFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_AST_PARSEDECL => IntrinsicKind.FfiCjAstParseDecl
            case PackageFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_AST_PARSE_PROPMEMBERDECL => IntrinsicKind.FfiCjAstParsePropMemberDecl
            case PackageFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_AST_PARSE_PRICONSTRUCTOR => IntrinsicKind.FfiCjAstParsePriConstructor
            case PackageFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_AST_PARSE_PATTERN => IntrinsicKind.FfiCjAstParsePattern
            case PackageFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_AST_PARSE_TYPE => IntrinsicKind.FfiCjAstParseType
            case PackageFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_AST_PARSETOPLEVEL => IntrinsicKind.FfiCjAstParseTopLevel
            case PackageFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_AST_DIAGREPORT => IntrinsicKind.FfiCjAstDiagReport
            case PackageFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_PARENT_CONTEXT => IntrinsicKind.FfiCjParentContext
            case PackageFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_MACRO_ITEM_INFO => IntrinsicKind.FfiCjMacroItemInfo
            case PackageFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_GET_CHILD_MESSAGES => IntrinsicKind.FfiCjGetChildMessages
            case PackageFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_CHECK_ADD_SPACE => IntrinsicKind.FfiCjCheckAddSpace
            case PackageFormat_IntrinsicKind.IntrinsicKind_CG_UNSAFE_BEGIN => IntrinsicKind.CgUnsafeBegin
            case PackageFormat_IntrinsicKind.IntrinsicKind_CG_UNSAFE_END => IntrinsicKind.CgUnsafeEnd
            case PackageFormat_IntrinsicKind.IntrinsicKind_STRLEN => IntrinsicKind.Strlen
            case PackageFormat_IntrinsicKind.IntrinsicKind_MEMCPY_S => IntrinsicKind.MemcpyS
            case PackageFormat_IntrinsicKind.IntrinsicKind_MEMSET_S => IntrinsicKind.MemsetS
            case PackageFormat_IntrinsicKind.IntrinsicKind_FREE => IntrinsicKind.Free
            case PackageFormat_IntrinsicKind.IntrinsicKind_MALLOC => IntrinsicKind.Malloc
            case PackageFormat_IntrinsicKind.IntrinsicKind_STRCMP => IntrinsicKind.Strcmp
            case PackageFormat_IntrinsicKind.IntrinsicKind_MEMCMP => IntrinsicKind.Memcmp
            case PackageFormat_IntrinsicKind.IntrinsicKind_STRNCMP => IntrinsicKind.Strncmp
            case PackageFormat_IntrinsicKind.IntrinsicKind_STRCASECMP => IntrinsicKind.Strcasecmp
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT8_LOAD => IntrinsicKind.AtomicInt8Load
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT8_STORE => IntrinsicKind.AtomicInt8Store
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT8_SWAP => IntrinsicKind.AtomicInt8Swap
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT8_CAS => IntrinsicKind.AtomicInt8Cas
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT8_FETCH_ADD => IntrinsicKind.AtomicInt8FetchAdd
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT8_FETCH_SUB => IntrinsicKind.AtomicInt8FetchSub
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT8_FETCH_AND => IntrinsicKind.AtomicInt8FetchAnd
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT8_FETCH_OR => IntrinsicKind.AtomicInt8FetchOr
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT8_FETCH_XOR => IntrinsicKind.AtomicInt8FetchXor
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT16_LOAD => IntrinsicKind.AtomicInt16Load
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT16_STORE => IntrinsicKind.AtomicInt16Store
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT16_SWAP => IntrinsicKind.AtomicInt16Swap
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT16_CAS => IntrinsicKind.AtomicInt16Cas
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT16_FETCH_ADD => IntrinsicKind.AtomicInt16FetchAdd
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT16_FETCH_SUB => IntrinsicKind.AtomicInt16FetchSub
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT16_FETCH_AND => IntrinsicKind.AtomicInt16FetchAnd
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT16_FETCH_OR => IntrinsicKind.AtomicInt16FetchOr
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT16_FETCH_XOR => IntrinsicKind.AtomicInt16FetchXor
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT32_LOAD => IntrinsicKind.AtomicInt32Load
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT32_STORE => IntrinsicKind.AtomicInt32Store
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT32_SWAP => IntrinsicKind.AtomicInt32Swap
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT32_CAS => IntrinsicKind.AtomicInt32Cas
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT32_FETCH_ADD => IntrinsicKind.AtomicInt32FetchAdd
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT32_FETCH_SUB => IntrinsicKind.AtomicInt32FetchSub
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT32_FETCH_AND => IntrinsicKind.AtomicInt32FetchAnd
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT32_FETCH_OR => IntrinsicKind.AtomicInt32FetchOr
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT32_FETCH_XOR => IntrinsicKind.AtomicInt32FetchXor
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT64_LOAD => IntrinsicKind.AtomicInt64Load
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT64_STORE => IntrinsicKind.AtomicInt64Store
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT64_SWAP => IntrinsicKind.AtomicInt64Swap
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT64_CAS => IntrinsicKind.AtomicInt64Cas
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT64_FETCH_ADD => IntrinsicKind.AtomicInt64FetchAdd
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT64_FETCH_SUB => IntrinsicKind.AtomicInt64FetchSub
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT64_FETCH_AND => IntrinsicKind.AtomicInt64FetchAnd
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT64_FETCH_OR => IntrinsicKind.AtomicInt64FetchOr
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT64_FETCH_XOR => IntrinsicKind.AtomicInt64FetchXor
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT8_LOAD => IntrinsicKind.AtomicUint8Load
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT8_STORE => IntrinsicKind.AtomicUint8Store
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT8_SWAP => IntrinsicKind.AtomicUint8Swap
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT8_CAS => IntrinsicKind.AtomicUint8Cas
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT8_FETCH_ADD => IntrinsicKind.AtomicUint8FetchAdd
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT8_FETCH_SUB => IntrinsicKind.AtomicUint8FetchSub
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT8_FETCH_AND => IntrinsicKind.AtomicUint8FetchAnd
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT8_FETCH_OR => IntrinsicKind.AtomicUint8FetchOr
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT8_FETCH_XOR => IntrinsicKind.AtomicUint8FetchXor
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT16_LOAD => IntrinsicKind.AtomicUint16Load
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT16_STORE => IntrinsicKind.AtomicUint16Store
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT16_SWAP => IntrinsicKind.AtomicUint16Swap
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT16_CAS => IntrinsicKind.AtomicUint16Cas
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT16_FETCH_ADD => IntrinsicKind.AtomicUint16FetchAdd
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT16_FETCH_SUB => IntrinsicKind.AtomicUint16FetchSub
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT16_FETCH_AND => IntrinsicKind.AtomicUint16FetchAnd
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT16_FETCH_OR => IntrinsicKind.AtomicUint16FetchOr
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT16_FETCH_XOR => IntrinsicKind.AtomicUint16FetchXor
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT32_LOAD => IntrinsicKind.AtomicUint32Load
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT32_STORE => IntrinsicKind.AtomicUint32Store
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT32_SWAP => IntrinsicKind.AtomicUint32Swap
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT32_CAS => IntrinsicKind.AtomicUint32Cas
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT32_FETCH_ADD => IntrinsicKind.AtomicUint32FetchAdd
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT32_FETCH_SUB => IntrinsicKind.AtomicUint32FetchSub
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT32_FETCH_AND => IntrinsicKind.AtomicUint32FetchAnd
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT32_FETCH_OR => IntrinsicKind.AtomicUint32FetchOr
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT32_FETCH_XOR => IntrinsicKind.AtomicUint32FetchXor
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT64_LOAD => IntrinsicKind.AtomicUint64Load
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT64_STORE => IntrinsicKind.AtomicUint64Store
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT64_SWAP => IntrinsicKind.AtomicUint64Swap
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT64_CAS => IntrinsicKind.AtomicUint64Cas
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT64_FETCH_ADD => IntrinsicKind.AtomicUint64FetchAdd
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT64_FETCH_SUB => IntrinsicKind.AtomicUint64FetchSub
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT64_FETCH_AND => IntrinsicKind.AtomicUint64FetchAnd
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT64_FETCH_OR => IntrinsicKind.AtomicUint64FetchOr
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT64_FETCH_XOR => IntrinsicKind.AtomicUint64FetchXor
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_BOOL_LOAD => IntrinsicKind.AtomicBoolLoad
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_BOOL_STORE => IntrinsicKind.AtomicBoolStore
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_BOOL_SWAP => IntrinsicKind.AtomicBoolSwap
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_BOOL_CAS => IntrinsicKind.AtomicBoolCas
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_REFERENCEBASE_LOAD => IntrinsicKind.AtomicReferenceBaseLoad
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_REFERENCEBASE_STORE => IntrinsicKind.AtomicReferenceBaseStore
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_REFERENCEBASE_SWAP => IntrinsicKind.AtomicReferenceBaseSwap
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_REFERENCEBASE_CAS => IntrinsicKind.AtomicReferenceBaseCas
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_OPTIONREFERENCE_LOAD => IntrinsicKind.AtomicOptionReferenceLoad
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_OPTIONREFERENCE_STORE => IntrinsicKind.AtomicOptionReferenceStore
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_OPTIONREFERENCE_SWAP => IntrinsicKind.AtomicOptionReferenceSwap
            case PackageFormat_IntrinsicKind.IntrinsicKind_ATOMIC_OPTIONREFERENCE_CAS => IntrinsicKind.AtomicOptionReferenceCas
            case PackageFormat_IntrinsicKind.IntrinsicKind_BEGIN_CATCH => IntrinsicKind.BeginCatch
            case PackageFormat_IntrinsicKind.IntrinsicKind_ABS => IntrinsicKind.Abs
            case PackageFormat_IntrinsicKind.IntrinsicKind_FABS => IntrinsicKind.Fabs
            case PackageFormat_IntrinsicKind.IntrinsicKind_FLOOR => IntrinsicKind.Floor
            case PackageFormat_IntrinsicKind.IntrinsicKind_CEIL => IntrinsicKind.Ceil
            case PackageFormat_IntrinsicKind.IntrinsicKind_TRUNC => IntrinsicKind.Trunc
            case PackageFormat_IntrinsicKind.IntrinsicKind_SIN => IntrinsicKind.Sin
            case PackageFormat_IntrinsicKind.IntrinsicKind_COS => IntrinsicKind.Cos
            case PackageFormat_IntrinsicKind.IntrinsicKind_EXP => IntrinsicKind.Exp
            case PackageFormat_IntrinsicKind.IntrinsicKind_EXP2 => IntrinsicKind.Exp2
            case PackageFormat_IntrinsicKind.IntrinsicKind_LOG => IntrinsicKind.Log
            case PackageFormat_IntrinsicKind.IntrinsicKind_LOG2 => IntrinsicKind.Log2
            case PackageFormat_IntrinsicKind.IntrinsicKind_LOG10 => IntrinsicKind.Log10
            case PackageFormat_IntrinsicKind.IntrinsicKind_SQRT => IntrinsicKind.Sqrt
            case PackageFormat_IntrinsicKind.IntrinsicKind_ROUND => IntrinsicKind.Round
            case PackageFormat_IntrinsicKind.IntrinsicKind_POW => IntrinsicKind.Pow
            case PackageFormat_IntrinsicKind.IntrinsicKind_POWI => IntrinsicKind.Powi
            case PackageFormat_IntrinsicKind.IntrinsicKind_BIT_CAST => IntrinsicKind.BitCast
            case PackageFormat_IntrinsicKind.IntrinsicKind_PREINITIALIZE => IntrinsicKind.Preinitialize
            case PackageFormat_IntrinsicKind.IntrinsicKind_OBJECT_AS => IntrinsicKind.ObjectAs
            case PackageFormat_IntrinsicKind.IntrinsicKind_IS_NULL => IntrinsicKind.IsNull
            case PackageFormat_IntrinsicKind.IntrinsicKind_GET_TYPE_FOR_TYPE_PARAMETER => IntrinsicKind.GetTypeForTypeParameter
            case PackageFormat_IntrinsicKind.IntrinsicKind_IS_SUBTYPE_TYPES => IntrinsicKind.IsSubtypeTypes

            case _ => throw IllegalArgumentException("Unsupported IntrinsicKind")
        }
    }

    private func deserializeUnaryExpressionBase(exprFormat: PackageFormat_UnaryExpressionBase): UnaryExpressionBase {
        let base = exprFormat.GetBase().getOrThrow()
        let kind = convertExprKind(base.GetKind())
        let operands = base.GetOperands()
        let op = getValue(operands[0])
        let expr: UnaryExpressionBase = if (kind.isTerminator()) {
            let normal = getValueAs<Block>(operands[1])
            let err = getValueAs<Block>(operands[2])
            TryUnaryExpression(kind, op, normal, err)
        } else {
            UnaryExpression(kind, op)
        }
        expr._overflow = convertOverflowStrategy(exprFormat.GetOverflowStrategy())
        return expr
    }

    private func deserializeBinaryExpressionBase(exprFormat: PackageFormat_BinaryExpressionBase): BinaryExpressionBase {
        let base = exprFormat.GetBase().getOrThrow()
        let kind = convertExprKind(base.GetKind())
        let operands = base.GetOperands()
        let lhs = getValue(operands[0])
        let rhs = getValue(operands[1])
        let expr: BinaryExpressionBase = if (kind.isTerminator()) {
            let normal = getValueAs<Block>(operands[2])
            let err = getValueAs<Block>(operands[3])
            TryBinaryExpression(kind, lhs, rhs, normal, err)
        } else {
            BinaryExpression(kind, lhs, rhs)
        }
        expr._overflow = convertOverflowStrategy(exprFormat.GetOverflowStrategy())
        return expr
    }

    private func deserializeExpression(exprFormat: PackageFormat_Expression): Expression {
        let kind = convertExprKind(exprFormat.GetKind())
        let operands = exprFormat.GetOperands()
        let expr: Expression = match (kind) {
            case ExprKind.Box =>
                Box(getValue(operands[0]))
            case ExprKind.CastToConcrete =>
                CastToConcrete(getValue(operands[0]))
            case ExprKind.CastToGeneric =>
                CastToGeneric(getValue(operands[0]))
            case ExprKind.Constant =>
                Constant(getValueAs<LiteralValue>(operands[0]))
            case ExprKind.Exit =>
                Exit()
            case ExprKind.GetException =>
                GetException()
            case ExprKind.GetRtti =>
                GetRTTI(getValue(operands[0]))
            case ExprKind.Goto =>
                GoTo(getValueAs<Block>(operands[0]))
            case ExprKind.Load =>
                Load(getValue(operands[0]))
            case ExprKind.RaiseException =>
                let value = getValue(operands[0])
                if (operands.size > 1) {
                    RaiseException(value, getValueAs<Block>(operands[1]))
                } else {
                    RaiseException(value)
                }
            case ExprKind.RawArrayInitByValue =>
                RawArrayInitByValue(getValue(operands[0]), getValue(operands[1]), getValue(operands[2]))
            case ExprKind.RawArrayLiteralInit =>
                let elements = collectArrayList<Value>(getValue(operands))
                RawArrayLiteralInit(elements[0], elements[1..])
            case ExprKind.StaticCast =>
                StaticCast(getValue(operands[0]))
            case ExprKind.Store =>
                Store(getValue(operands[0]), getValue(operands[1]))
            case ExprKind.Tuple =>
                Tuple(collectArrayList<Value>(getValue(operands)))
            case ExprKind.UnboxToRef =>
                UnboxToRef(getValue(operands[0]))
            case ExprKind.UnboxToValue =>
                UnboxToValue(getValue(operands[0]))
            case ExprKind.VArrayBuilder =>
                VArrayBuilder(getValue(operands[0]), getValue(operands[1]), getValue(operands[2]))
            case ExprKind.VArrayExpr =>
                VArrayExpr(collectArrayList<Value>(getValue(operands)))
            case _ => throw CHIRException("Unsupported EXPRESSION kind: " + kind.toString())
        }
        return expr
    }

    private func deserializeAllocateBase(exprFormat: PackageFormat_AllocateBase): Expression {
        let base = exprFormat.GetBase().getOrThrow()
        let kind = convertExprKind(base.GetKind())
        let targetType = getTypeAs<Type>(exprFormat.GetAllocatedType())
        if (kind.isTerminator()) {
            let operands = base.GetOperands()
            let normal = getValueAs<Block>(operands[operands.size - 2])
            let err = getValueAs<Block>(operands[operands.size - 1])
            return TryAllocate(targetType, normal, err)
        } else {
            return Allocate(targetType)
        }
    }

    private func deserializeIntrinsicBase(exprFormat: PackageFormat_IntrinsicBase): Expression {
        let funcCall = exprFormat.GetBase().getOrThrow()
        let base = funcCall.GetBase().getOrThrow()
        let kind = convertExprKind(base.GetKind())
        let intrinsicKind = convertIntrinsicKind(exprFormat.GetIntrinsicKind())
        let operands = base.GetOperands()
        let instantiatedTypeArgs = getTypeAs<Type>(funcCall.GetInstantiatedTypeArgs())
        if (kind.isTerminator()) {
            let args = getValue(operands.slice(0, operands.size - 2))
            let normal = getValueAs<Block>(operands[operands.size - 2])
            let err = getValueAs<Block>(operands[operands.size - 1])
            let funcCallCtx = FuncCallContext(args, instantiatedTypeArgs, None)
            return TryIntrinsic(intrinsicKind, funcCallCtx, normal, err)
        } else {
            let args = getValue(operands)
            let funcCallCtx = FuncCallContext(args, instantiatedTypeArgs, None)
            return Intrinsic(intrinsicKind, funcCallCtx)
        }
    }

    private func deserializeRawArrayAllocateBase(exprFormat: PackageFormat_RawArrayAllocateBase): Expression {
        let base = exprFormat.GetBase().getOrThrow()
        let kind = convertExprKind(base.GetKind())
        let elementType = getType(exprFormat.GetElementType())
        let operands = base.GetOperands()
        let size = getValue(operands[0])
        if (kind.isTerminator()) {
            let normal = getValueAs<Block>(operands[operands.size - 2])
            let err = getValueAs<Block>(operands[operands.size - 1])
            return TryRawArrayAllocate(elementType, size, normal, err)
        } else {
            return RawArrayAllocate(elementType, size)
        }
    }

    private func deserializeSpawnBase(exprFormat: PackageFormat_SpawnBase): Expression {
        let base = exprFormat.GetBase().getOrThrow()
        let kind = convertExprKind(base.GetKind())
        let operands = base.GetOperands()
        let val = getValue(operands[0])
        var result: SpawnBase
        if (kind.isTerminator()) {
            let normal = getValueAs<Block>(operands[operands.size - 2])
            let err = getValueAs<Block>(operands[operands.size - 1])
            if (operands.size > 3) {
                let arg = getValue(operands[1])
                result = TrySpawn(val, arg, normal, err)
            } else {
                result = TrySpawn(val, normal, err)
            }
        } else {
            if (operands.size > 1) {
                let arg = getValue(operands[1])
                result = Spawn(val, arg)
            } else {
                result = Spawn(val)
            }
        }
        if (let Some(v) <- tryGetValueAs<Function>(exprFormat.GetExecuteClosure())) {
            result.executeClosure = v
        }
        return result
    }

    private func deserializeGetElementRef(exprFormat: PackageFormat_GetElementRef): GetElementRef {
        let base = exprFormat.GetBase().getOrThrow()
        let location = getValue(base.GetOperands()[0])
        let path = collectArrayList<UInt64>(exprFormat.GetPath())
        return GetElementRef(location, path)
    }

    private func deserializeGetElementByName(exprFormat: PackageFormat_GetElementByName): GetElementByName {
        let base = exprFormat.GetBase().getOrThrow()
        let location = getValue(base.GetOperands()[0])
        var names = ArrayList<String>()
        for (nameOpt in exprFormat.GetFieldNames()) {
            names.add(nameOpt.getOrThrow())
        }
        return GetElementByName(location, names)
    }

    private func deserializeStoreElementRef(exprFormat: PackageFormat_StoreElementRef): StoreElementRef {
        let base = exprFormat.GetBase().getOrThrow()
        let operands = base.GetOperands()
        let value = getValue(operands[0])
        let location = getValue(operands[1])
        let path = collectArrayList<UInt64>(exprFormat.GetPath())
        return StoreElementRef(value, location, path)
    }

    private func deserializeStoreElementByName(exprFormat: PackageFormat_StoreElementByName): StoreElementByName {
        let base = exprFormat.GetBase().getOrThrow()
        let operands = base.GetOperands()
        let value = getValue(operands[0])
        let location = getValue(operands[1])
        var names = ArrayList<String>()
        for (nameOpt in exprFormat.GetFieldNames()) {
            names.add(nameOpt.getOrThrow())
        }
        return StoreElementByName(value, location, names)
    }

    private func deserializeApplyBase(exprFormat: PackageFormat_ApplyBase): ApplyBase {
        let funcCall = exprFormat.GetBase().getOrThrow()
        let base = funcCall.GetBase().getOrThrow()
        let kind = convertExprKind(base.GetKind())
        let operands = base.GetOperands()
        let callee = getValue(operands[0])
        let instantiatedTypeArgs = getType(funcCall.GetInstantiatedTypeArgs())
        let objType: ?Type = if (let Some(v) <- tryGetType(funcCall.GetObjType())) { v } else { None }
        if (kind.isTerminator()) {
            let args = getValue(operands.slice(1, operands.size - 3))
            let normal = getValueAs<Block>(operands[operands.size - 2])
            let err = getValueAs<Block>(operands[operands.size - 1])
            let funcCallCtx = FuncCallContext(args, instantiatedTypeArgs, objType)
            return TryApply(callee, funcCallCtx, normal, err)
        } else {
            let args = getValue(operands.slice(1, operands.size - 1))
            let funcCallCtx = FuncCallContext(args, instantiatedTypeArgs, objType)
            let result = Apply(callee, funcCallCtx)
            if (exprFormat.GetIsSuperCall()) {
                result._isSuperCall = true
            }
            return result
        }
    }

    // Helper function to deserialize FuncSigInfo from PackageFormat_FuncSigInfo
    private func deserializeFuncSigInfo(funcSigInfoFormat: PackageFormat_FuncSigInfo): FuncSigInfo {
        let funcName = funcSigInfoFormat.GetFuncName()
        let funcTypeId = funcSigInfoFormat.GetFuncType()
        let funcType = getTypeAs<FuncType>(funcTypeId)
        let genericTypeParams = collectArrayList<GenericType>(getTypeAs<GenericType>(funcSigInfoFormat.GetGenericTypeParams()))
        return FuncSigInfo(funcName, funcType, genericTypeParams.toArray())
    }

    private func deserializeInvoke(exprFormat: PackageFormat_InvokeBase): Expression {
        let funcCall = exprFormat.GetBase().getOrThrow()
        let base = funcCall.GetBase().getOrThrow()
        let kind = convertExprKind(base.GetKind())
        let operands = base.GetOperands()
        let caller = getValue(operands[0])
        let instantiatedTypeArgs = getType(funcCall.GetInstantiatedTypeArgs())
        let objType: ?Type = if (let Some(v) <- tryGetType(funcCall.GetObjType())) { v } else { None }
        let virMethodCtx = deserializeFuncSigInfo(exprFormat.GetVirMethodCtx().getOrThrow())
        if (kind.isTerminator()) {
            let args = getValue(operands.slice(1, operands.size - 3))
            let normal = getValueAs<Block>(operands[operands.size - 2])
            let err = getValueAs<Block>(operands[operands.size - 1])
            let funcCallCtx = FuncCallContext(args, instantiatedTypeArgs, objType)
            let invokeCallCtx = InvokeCallContext(caller, virMethodCtx, funcCallCtx)
            return TryInvoke(invokeCallCtx, normal, err)
        } else {
            let args = getValue(operands.slice(1, operands.size - 1))
            let funcCallCtx = FuncCallContext(args, instantiatedTypeArgs, objType)
            let invokeCallCtx = InvokeCallContext(caller, virMethodCtx, funcCallCtx)
            return Invoke(invokeCallCtx)
        }
    }

    private func deserializeNumericCastBase(exprFormat: PackageFormat_NumericCastBase): NumericCastBase {
        let base = exprFormat.GetBase().getOrThrow()
        let kind = convertExprKind(base.GetKind())
        let operands = base.GetOperands()
        let operand = getValue(operands[0])
        let overflow = convertOverflowStrategy(exprFormat.GetOverflowStrategy())
        if (kind.isTerminator()) {
            let normal = getValueAs<Block>(operands[operands.size - 2])
            let err = getValueAs<Block>(operands[operands.size - 1])
            return TryNumericCast(operand, normal, err)
        } else {
            return NumericCast(operand, overflow)
        }
    }

    private func deserializeInstanceOf(exprFormat: PackageFormat_InstanceOf): InstanceOf {
        let base = exprFormat.GetBase().getOrThrow()
        let operand = getValue(base.GetOperands()[0])
        let targetTy = getType(exprFormat.GetTargetType())
        return InstanceOf(operand, targetTy)
    }

    private func deserializeField(exprFormat: PackageFormat_Field): Field {
        let base = exprFormat.GetBase().getOrThrow()
        let val = getValue(base.GetOperands()[0])
        let path = collectArrayList<UInt64>(exprFormat.GetPath())
        return Field(val, path)
    }

    private func deserializeFieldByName(exprFormat: PackageFormat_FieldByName): FieldByName {
        let base = exprFormat.GetBase().getOrThrow()
        let val = getValue(base.GetOperands()[0])
        var names = ArrayList<String>()
        for (nameOpt in exprFormat.GetFieldNames()) {
            names.add(nameOpt.getOrThrow())
        }
        return FieldByName(val, names)
    }

    private func deserializeBranch(exprFormat: PackageFormat_Branch): Branch {
        let base = exprFormat.GetBase().getOrThrow()
        let operands = base.GetOperands()
        let condition = getValue(operands[0])
        let trueTarget = getValueAs<Block>(operands[1])
        let falseTarget = getValueAs<Block>(operands[2])
        let expr = Branch(condition, trueTarget, falseTarget)
        expr._sourceExpr = convertSourceExpr(exprFormat.GetSourceExpr())
        return expr
    }

    private func deserializeMultiBranch(exprFormat: PackageFormat_MultiBranch): MultiBranch {
        let base = exprFormat.GetBase().getOrThrow()
        let operands = base.GetOperands()
        let condition = getValue(operands[0])
        let defaultTarget = getValueAs<Block>(operands[1])
        let targets = ArrayList<Block>()
        for (i in 2..operands.size) {
            targets.add(getValueAs<Block>(operands[i]))
        }
        let caseValues = collectArrayList<UInt64>(exprFormat.GetCaseValues())
        return MultiBranch(condition, defaultTarget, targets, caseValues)
    }

    private func deserializeDebug(exprFormat: PackageFormat_Debug): Debug {
        let base = exprFormat.GetBase().getOrThrow()
        let operands = base.GetOperands()
        let location = getValue(operands[0])
        let srcCodeName = exprFormat.GetSrcCodeName()
        return Debug(location, srcCodeName)
    }

    private func deserializeLambda(exprFormat: PackageFormat_Lambda): Lambda {
        let funcTy = getTypeAs<FuncType>(exprFormat.GetFuncTy())
        let identifier = exprFormat.GetIdentifier()
        let srcCodeName = exprFormat.GetSrcCodeName()
        let genericTypeParams = ArrayList<GenericType>()
        for (id in exprFormat.GetGenericTypeParams()) {
            genericTypeParams.add(getTypeAs<GenericType>(id))
        }
        return Lambda(funcTy, identifier, srcCodeName, genericTypeParams)
    }

    private func deserializeGetInstantiateValue(exprFormat: PackageFormat_GetInstantiateValue): GetInstantiateValue {
        let base = exprFormat.GetBase().getOrThrow()
        let funcDecl = getValueAs<Function>(base.GetOperands()[0])
        let instantiateTypes = ArrayList<Type>()
        for (id in exprFormat.GetInstantiateTypes()) {
            instantiateTypes.add(getType(id))
        }
        return GetInstantiateValue(funcDecl, instantiateTypes)
    }

    private func deserializeGetRTTIStatic(exprFormat: PackageFormat_GetRTTIStatic): GetRTTIStatic {
        let base = exprFormat.GetBase().getOrThrow()
        let rttiType = getType(exprFormat.GetRttiType())
        return GetRTTIStatic(rttiType)
    }

    private func configBlock(blockFormat: PackageFormat_Block, block: Block) {
        configValue(blockFormat.GetBase().getOrThrow(), block)

        // Set expressions
        for (exprId in blockFormat.GetExprs()) {
            block._exprs.add(getExpression(exprId))
        }

        // Set exceptions if it's a landing pad block
        if (blockFormat.GetIsLandingPadBlock()) {
            // Note: you shouldn't use `block._exception.add(...)`, because this block may catch all exceptions,
            // then its `_exception` should be empty ArrayList, not `Option<ArrayList<ClassLikeType>>.None`
            let exceptions = ArrayList<ClassLikeType>()
            for (id in blockFormat.GetExceptionCatchList()) {
                exceptions.add(getTypeAs<ClassLikeType>(id))
            }
            block._exceptions = exceptions
        }

        // Set predecessors
        for (id in blockFormat.GetPredecessors()) {
            block._predecessors.add(getValueAs<Block>(id))
        }
    }

    private func configBlockGroup(blockGroupFormat: PackageFormat_BlockGroup, blockGroup: BlockGroup) {
        configValue(blockGroupFormat.GetBase().getOrThrow(), blockGroup)

        // Set entry block
        blockGroup._entryBlock = getValueAs<Block>(blockGroupFormat.GetEntryBlock())

        // Set blocks
        for (id in blockGroupFormat.GetBlocks()) {
            blockGroup._blocks.add(getValueAs<Block>(id))
        }
    }

    private func configGlobalVar(globalVarFormat: PackageFormat_GlobalVar, globalVar: GlobalVar) {
        configGlobalValue(globalVarFormat.GetBase().getOrThrow(), globalVar)

        // Set initializer
        if (let Some(v) <- tryGetValue(globalVarFormat.GetInitializer())) {
            globalVar.setInitializer(v)
        }
    }

    private func convertFuncKind(packageFormatFuncKind: PackageFormat_FuncKind): FuncKind {
        match(packageFormatFuncKind) {
            case PackageFormat_FuncKind.FuncKind_DEFAULT => FuncKind.Default
            case PackageFormat_FuncKind.FuncKind_GETTER => FuncKind.Getter
            case PackageFormat_FuncKind.FuncKind_SETTER => FuncKind.Setter
            case PackageFormat_FuncKind.FuncKind_LAMBDA => FuncKind.Lambda
            case PackageFormat_FuncKind.FuncKind_CLASS_CONSTRUCTOR => FuncKind.ClassConstructor
            case PackageFormat_FuncKind.FuncKind_PRIMAL_CLASS_CONSTRUCTOR => FuncKind.PrimaryClassConstructor
            case PackageFormat_FuncKind.FuncKind_STRUCT_CONSTRUCTOR => FuncKind.StructConstructor
            case PackageFormat_FuncKind.FuncKind_PRIMAL_STRUCT_CONSTRUCTOR => FuncKind.PrimaryStructConstructor
            case PackageFormat_FuncKind.FuncKind_GLOBALVAR_INIT => FuncKind.GlobalVarInit
            case PackageFormat_FuncKind.FuncKind_FINALIZER => FuncKind.Finalizer
            case PackageFormat_FuncKind.FuncKind_MAIN_ENTRY => FuncKind.MainEntry
            case PackageFormat_FuncKind.FuncKind_ANNOFACTORY_FUNC => FuncKind.AnnoFactoryFunc
            case PackageFormat_FuncKind.FuncKind_MACRO_FUNC => FuncKind.MacroFunc
            case PackageFormat_FuncKind.FuncKind_DEFAULT_PARAMETER_FUNC => FuncKind.DefaultParameterFunc
            case PackageFormat_FuncKind.FuncKind_INSTANCEVAR_INIT => FuncKind.InstanceVarInit
        }
    }

    private func configGlobalValue(globalValueFormat: PackageFormat_GlobalValue, globalValue: GlobalValue) {
        configValue(globalValueFormat.GetBase().getOrThrow(), globalValue)

        // Set Features
        globalValue._features = deserializeFeatures(globalValueFormat)

        // Set annoInfo
        if (let Some(annoInfoFormat) <- globalValueFormat.GetAnnoInfo()) {
            globalValue._annoInfo = deserializeAnnoInfo(annoInfoFormat)
        }

        // Set rawManlgedName
        globalValue._rawMangledName = globalValueFormat.GetRawMangledName()

        // Set declaredParent
        if (let Some(v) <- tryGetCustomTypeDef(globalValueFormat.GetDeclaredParent())) {
            globalValue._declaredParent = v
        }

        // packageName and srcCodeName are deserialized before
    }
    private func configFunction(funcFormat: PackageFormat_Function, function: Function) {
        configGlobalValue(funcFormat.GetBase().getOrThrow(), function)

        // Set body
        if (let Some(v) <- tryGetValueAs<BlockGroup>(funcFormat.GetBody())) {
            function._body = v
        }

        // Set funcKind
        let funcKind = funcFormat.GetFuncKind()
        function._funcKind = convertFuncKind(funcKind)

        // Set genericDecl
        if (let Some(v) <- tryGetValueAs<Function>(funcFormat.GetGenericDecl())) {
            function._genericDecl = v
        }

        // Set genericTypeParams
        let genericTypeParams = getTypeAs<GenericType>(funcFormat.GetGenericTypeParams())
        function._genericTypeParams = collectArrayList<GenericType>(genericTypeParams)

        // Set ids
        function._localId = funcFormat.GetLocalId()
        function._blockId = funcFormat.GetBlockId()
        function._blockGroupId = funcFormat.GetBlockGroupId()

        // Set isFastNative and isCFFIWrapper
        function._isFastNative = funcFormat.GetIsFastNative()
        function._isCFFIWrapper = funcFormat.GetIsCFFIWrapper()

        // Set originalLambdaInfo
        if (let Some(v) <- funcFormat.GetOriginalLambdaInfo()) {
            function._originalLambdaInfo = deserializeFuncSigInfo(v)
        }

        // Set paramDftValHostFunc
        if (let Some(v) <- tryGetValueAs<Function>(funcFormat.GetParamDftValHostFunc())) {
            function._paramDftValHostFunc = v
        }

        // Set parameters
        for (id in funcFormat.GetParams()) {
            function._parameters.add(getValueAs<Parameter>(id))
        }

        // Set propLocation
        if (let Some(v) <- funcFormat.GetPropLoc()) {
            function._propLocation = deserializeDebugLocation(v)
        }

        // Set retValue
        if (let Some(v) <- tryGetValueAs<LocalVar>(funcFormat.GetRetVal())) {
            function._retValue = v
        }

        // blockGroupId, blockId and localId are set in the end of "run()", avoid being modified in configBlockGroup and configBlock
    }

    private func configCustomTypeDef(customTypeDefFormat: PackageFormat_CustomTypeDef, customTypeDef: CustomTypeDef) {
        configBase(customTypeDefFormat.GetBase().getOrThrow(), customTypeDef)

        // Set AnnoInfo
        if (let Some(annoInfoFormat) <- customTypeDefFormat.GetAnnoInfo()) {
            customTypeDef._annoInfo = deserializeAnnoInfo(annoInfoFormat)
        }

        // Set genericDecl
        if (let Some(v) <- tryGetCustomTypeDef(customTypeDefFormat.GetGenericDecl())) {
            customTypeDef._genericDecl = v
        }

        // Set implementedInterfaceTypes
        for (id in customTypeDefFormat.GetImplementedInterfaces()) {
            customTypeDef._implementedInterfaceTypes.add(getTypeAs<ClassLikeType>(id))
        }

        // Set instanceVarInitFunc
        if (let Some(v) <- tryGetValueAs<Function>(customTypeDefFormat.GetInstanceVarInitFunc())) {
            customTypeDef._instanceVarInitFunc = v
        }

        // Set instanceVars
        for (memberVarInfoOpt in customTypeDefFormat.GetInstanceMemberVars()) {
            customTypeDef._instanceVars.add(
                deserializeMemberVarInfo(memberVarInfoOpt.getOrThrow(), customTypeDef))
        }

        // Set CustomType
        let typeId = customTypeDefFormat.GetType()
        if (let Some(v) <- tryGetTypeAs<CustomType>(customTypeDefFormat.GetType())) {
            customTypeDef._type = v
        }

        // Set methods
        for (id in customTypeDefFormat.GetMethods()) {
            customTypeDef._methods.add(getValueAs<Function>(id))
        }

        // Set staticVars
        for (id in customTypeDefFormat.GetStaticMemberVars()) {
            customTypeDef._staticVars.add(getValueAs<GlobalVar>(id))
        }
    }

    private func configEnumDef(enumDefFormat: PackageFormat_EnumDef, enumDef: EnumDef) {
        let base = enumDefFormat.GetBase().getOrThrow()
        configCustomTypeDef(base, enumDef)

        // Configure constructors
        for (ctorOpt in enumDefFormat.GetCtors()) {
            let ctorFormat = ctorOpt.getOrThrow()
            let srcCodeName = ctorFormat.GetSrcCodeName()
            let mangledName = ctorFormat.GetMangledName()
            let funcType = getTypeAs<FuncType>(ctorFormat.GetFuncType())
            let ctorInfo = EnumCtorInfo(srcCodeName, mangledName, funcType, enumDef)
            if (let Some(annoInfoFormat) <- ctorFormat.GetAnnoInfo()) {
                ctorInfo._annoInfo = deserializeAnnoInfo(annoInfoFormat)
            }
            enumDef._ctors.add(ctorInfo)
        }
    }

    private func configStructDef(structDefFormat: PackageFormat_StructDef, structDef: StructDef) {
        let base = structDefFormat.GetBase().getOrThrow()
        configCustomTypeDef(base, structDef)

        // Configure isCStruct
        structDef.isCStruct = structDefFormat.GetIsCStruct()
    }

    private func configClassDef(classDefFormat: PackageFormat_ClassDef, classDef: ClassLikeDef) {
        let base = classDefFormat.GetBase().getOrThrow()
        configCustomTypeDef(base, classDef)

        // Set annotationTargets
        if (classDefFormat.GetIsAnnotation()) {
            var targets = ArrayList<GlobalVar>()
            for (id in classDefFormat.GetAnnotationTargets()) {
                targets.add(getValueAs<GlobalVar>(id))
            }
            classDef._annotationTargets = targets
        }

        // Set isClass
        classDef._isClass = classDefFormat.GetIsClass()

        // Set superClass
        if (let Some(v) <- tryGetTypeAs<ClassLikeType>(classDefFormat.GetSuperClass())) {
            classDef.superClass = v
        }
    }

    private func configExtendDef(extendDefFormat: PackageFormat_ExtendDef, extendDef: ExtendDef) {
        let base = extendDefFormat.GetBase().getOrThrow()
        configCustomTypeDef(base, extendDef)
    }

    func getPkg() : Package {
        this.pkg
    }
}
