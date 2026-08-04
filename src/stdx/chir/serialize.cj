/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.chir

import std.collection.{HashMap, ArrayList}
import flatbuffers.*

let fbBuilder = Builder(0)

/**
 * Resets the shared FlatBuffers builder state produced by the last serialization.
 */
@C
public func freeSerializedMemory(): Unit {
    fbBuilder.reset()
}

/**
 * Serializes an in-memory `Package` into a CHIR FlatBuffers byte blob.
 * @param pkg Package graph to serialize.
 * @return Pointer to the first byte and the total byte length of the finished buffer.
 * @exception Exception when serialization invariants fail or the FlatBuffers root cannot be built.
 */
public func serializePackage(pkg: Package): (CPointer<UInt8>, Int64) {
    fbBuilder.reset()
    let serializer = CHIRSerializerImpl(pkg, fbBuilder)
    serializer.initialize()
    serializer.dispatch()
    return serializer.convertToMemoryData()
}

private func serializePackageAccessLevel(accessLevel: AccessLevel): CHIRFormat_PackageAccessLevel {
    return match (accessLevel) {
        case AccessLevel.Internal => CHIRFormat_PackageAccessLevel.PackageAccessLevel_INTERNAL
        case AccessLevel.Protected => CHIRFormat_PackageAccessLevel.PackageAccessLevel_PROTECTED
        case AccessLevel.Public => CHIRFormat_PackageAccessLevel.PackageAccessLevel_PUBLIC
    }
}

// CHIR package serializer implementation (FlatBuffers).
class CHIRSerializerImpl {
    private let pkg: Package

    // ID maps from CHIR nodes to stable FlatBuffers slot ids (defs, expressions, types, values).
    private var def2Id = HashMap<CustomTypeDef, UInt32>()
    private var expr2Id = HashMap<Expression, UInt32>()
    private var type2Id = HashMap<Type, UInt32>()
    private var value2Id = HashMap<Value, UInt32>()

    // Per-kind counters for the next assigned id.
    private var defCount: UInt32 = 0
    private var exprCount: UInt32 = 0
    private var typeCount: UInt32 = 0
    private var valueCount: UInt32 = 0

    // Work queues populated during preorder traversal.
    private var defQueue = ArrayQueue<CustomTypeDef>()
    private var exprQueue = ArrayQueue<Expression>()
    private var typeQueue = ArrayQueue<Type>()
    private var valueQueue = ArrayQueue<Value>()

    private var allCustomTypeDef = ArrayList<UInt32>()
    private var allExpression = ArrayList<UInt32>()
    private var allType = ArrayList<UInt32>()
    private var allValue = ArrayList<UInt32>()
    private var defKind = ArrayList<UInt8>()
    private var exprKind = ArrayList<UInt8>()
    private var typeKind = ArrayList<UInt8>()
    private var valueKind = ArrayList<UInt8>()

    init(pkg: Package, fbBuilder: Builder) {
        this.pkg = pkg
        type2Id[InvalidType.get()] = 0
    }

    // Obtain or allocate a stable id for a Value/Type/Expression/CustomTypeDef.
    func getId(obj: CustomTypeDef): UInt32 {
        if (let Some(id) <- def2Id.get(obj)) {
            return id
        }
        defCount += 1
        def2Id[obj] = defCount
        allCustomTypeDef.add(0)
        defKind.add(0)
        defQueue.add(obj)
        return defCount
    }

    func getId(obj: Expression): UInt32 {
        if (let Some(id) <- expr2Id.get(obj)) {
            return id
        }
        exprCount += 1
        expr2Id[obj] = exprCount
        allExpression.add(0)
        exprKind.add(0)
        exprQueue.add(obj)
        return exprCount
    }

    func getId(obj: Type): UInt32 {
        if (let Some(id) <- type2Id.get(obj)) {
            return id
        }
        typeCount += 1
        type2Id[obj] = typeCount
        allType.add(0)
        typeKind.add(0)
        typeQueue.add(obj)
        return typeCount
    }

    func getId(obj: Value): UInt32 {
        if (let Some(id) <- value2Id.get(obj)) {
            return id
        }
        valueCount += 1
        value2Id[obj] = valueCount
        allValue.add(0)
        valueKind.add(0)
        valueQueue.add(obj)
        return valueCount
    }

    // Map each element in list to its stable id.
    func getDefIdList<T>(list: ArrayList<T>): Array<UInt32> where T <: CustomTypeDef {
        return Array<UInt32>(list.size, { i => getId(list[i]) })
    }

    func getExprIdList<T>(list: ArrayList<T>): Array<UInt32> where T <: Expression {
        return Array<UInt32>(list.size, { i => getId(list[i]) })
    }

    func getTypeIdList<T>(list: ArrayList<T>): Array<UInt32> where T <: Type {
        return Array<UInt32>(list.size, { i => getId(list[i]) })
    }

    func getValueIdList<T>(list: ArrayList<T>): Array<UInt32> where T <: Value {
        return Array<UInt32>(list.size, { i => getId(list[i]) })
    }

    // Pre-scan: enqueue globals, functions, and all custom type defs; pre-allocate ids.
    func initialize(): Unit {
        // Enqueue package global variables and functions.
        for (v in pkg._globalVars) {
            valueQueue.add(v)
        }
        for (f in pkg._functions) {
            valueQueue.add(f)
        }
        for (def in pkg.allCustomTypeDefs) {
            defQueue.add(def)
        }
        // Pre-allocate CustomTypeDef ids and side-table slots.
        for (def in defQueue) {
            defCount += 1
            def2Id[def] = defCount
            allCustomTypeDef.add(0)
            defKind.add(0)
        }
        // Pre-allocate Value ids and side-table slots.
        for (obj in valueQueue) {
            valueCount += 1
            value2Id[obj] = valueCount
            allValue.add(0)
            valueKind.add(0)
        }
    }

    // ----- Helper serializers (CHIRFormat tables) -----

    private func serializeDebugLocation(loc: DebugLocation): UInt32 {
        let filePath = fbBuilder.createString(loc.filePath.toString())
        let beginPos = CHIRFormat_Pos.createPos(fbBuilder, UInt32(loc.start.line), UInt32(loc.start.column))
        let endPos = CHIRFormat_Pos.createPos(fbBuilder, UInt32(loc.end.line), UInt32(loc.end.column))
        let scopeArray = Array<Int32>(loc._scopeInfo.size, { i => Int32(loc._scopeInfo[i]) })
        let scopeVec = fbBuilder.createInt32Vector(scopeArray)
        return CHIRFormat_DebugLocation.createDebugLocation(
            fbBuilder, filePath, UInt32(loc._fileId), beginPos, endPos, scopeVec
        )
    }

    private func serializeBase(obj: Base): UInt32 {
        let annoTypes = ArrayList<UInt8>()
        let annos = ArrayList<UInt32>()
        for (anno in obj._chirAnno) {
            match (anno) {
                case a: DebugLocationInfoForWarning =>
                    let warnLoc = a.get()
                    if (warnLoc.isValid()) {
                        annoTypes.add(EnumCHIRFormat_AnnotationValues(CHIRFormat_Annotation.Annotation_DEBUGLOCATIONINFOFORWARNING))
                        annos.add(serializeDebugLocation(warnLoc))
                    }
                case a: NeedCheckArrayBound =>
                    let need = a.get()
                    annoTypes.add(EnumCHIRFormat_AnnotationValues(CHIRFormat_Annotation.Annotation_NEEDCHECKARRAYBOUND))
                    annos.add(CHIRFormat_NeedCheckArrayBound.createNeedCheckArrayBound(fbBuilder, need))
                case a: NeedCheckCast =>
                    let need = a.get()
                    annoTypes.add(EnumCHIRFormat_AnnotationValues(CHIRFormat_Annotation.Annotation_NEEDCHECKCAST))
                    annos.add(CHIRFormat_NeedCheckCast.createNeedCheckCast(fbBuilder, need))
                case a: GenerateFromForIn =>
                    let value = a.get()
                    annoTypes.add(EnumCHIRFormat_AnnotationValues(CHIRFormat_Annotation.Annotation_GENERATEDFROMFORIN))
                    annos.add(CHIRFormat_GeneratedFromForIn.createGeneratedFromForIn(fbBuilder, value))
                case a: GeneratedFromForIn =>
                    let value = a.get()
                    annoTypes.add(EnumCHIRFormat_AnnotationValues(CHIRFormat_Annotation.Annotation_GENERATEDFROMFORIN))
                    annos.add(CHIRFormat_GeneratedFromForIn.createGeneratedFromForIn(fbBuilder, value))
                case a: IsAutoEnvClass =>
                    let value = a.get()
                    annoTypes.add(EnumCHIRFormat_AnnotationValues(CHIRFormat_Annotation.Annotation_ISAUTOENVCLASS))
                    annos.add(CHIRFormat_IsAutoEnvClass.createIsAutoEnvClass(fbBuilder, value))
                case a: IsCapturedClassInCC =>
                    let value = a.get()
                    annoTypes.add(EnumCHIRFormat_AnnotationValues(CHIRFormat_Annotation.Annotation_ISCAPTUREDCLASSINCC))
                    annos.add(CHIRFormat_IsCapturedClassInCC.createIsCapturedClassInCC(fbBuilder, value))
                case a: LinkTypeInfo =>
                    let linkType = a.get()
                    let linkage = match (linkType) {
                        case LinkType.External => CHIRFormat_Linkage.Linkage_EXTERNAL
                        case LinkType.Internal => CHIRFormat_Linkage.Linkage_INTERNAL
                        case LinkType.WeakOdr => CHIRFormat_Linkage.Linkage_WEAK_ODR
                        case LinkType.LinkonceOdr => CHIRFormat_Linkage.Linkage_LINKONCE_ODR
                        case LinkType.ExternalWeak => CHIRFormat_Linkage.Linkage_EXTERNAL_WEAK
                    }
                    annoTypes.add(EnumCHIRFormat_AnnotationValues(CHIRFormat_Annotation.Annotation_LINKTYPEINFO))
                    annos.add(CHIRFormat_LinkTypeInfo.createLinkTypeInfo(fbBuilder, linkage))
                case a: SkipCheck =>
                    let skipKind = a.get()
                    let pkgSkipKind = match (skipKind) {
                        case SkipKind.NoSkip => CHIRFormat_SkipKind.SkipKind_NO_SKIP
                        case SkipKind.SkipDceWarning => CHIRFormat_SkipKind.SkipKind_SKIP_DCE_WARNING
                        case SkipKind.SkipForinExit => CHIRFormat_SkipKind.SkipKind_SKIP_FORIN_EXIT
                        case SkipKind.SkipVic => CHIRFormat_SkipKind.SkipKind_SKIP_VIC
                    }
                    annoTypes.add(EnumCHIRFormat_AnnotationValues(CHIRFormat_Annotation.Annotation_SKIPCHECK))
                    annos.add(CHIRFormat_SkipCheck.createSkipCheck(fbBuilder, pkgSkipKind))
                case a: NeverOverflowInfo =>
                    let neverOverflow = a.get()
                    annoTypes.add(EnumCHIRFormat_AnnotationValues(CHIRFormat_Annotation.Annotation_NEVEROVERFLOWINFO))
                    annos.add(CHIRFormat_NeverOverflowInfo.createNeverOverflowInfo(fbBuilder, neverOverflow))
                case a: EnumCaseIndex =>
                    let indexOpt = a.get()
                    let index = if (let Some(i) <- indexOpt) { Int64(i) } else { Int64(-1) }
                    annoTypes.add(EnumCHIRFormat_AnnotationValues(CHIRFormat_Annotation.Annotation_ENUMCASEINDEX))
                    annos.add(CHIRFormat_EnumCaseIndex.createEnumCaseIndex(fbBuilder, index))
                case a: VirMethodOffset =>
                    let offsetOpt = a.get()
                    let offset = if (let Some(o) <- offsetOpt) { Int64(o) } else { Int64(-1) }
                    annoTypes.add(EnumCHIRFormat_AnnotationValues(CHIRFormat_Annotation.Annotation_VIRMETHODOFFSET))
                    annos.add(CHIRFormat_VirMethodOffset.createVirMethodOffset(fbBuilder, offset))
                case a: WrappedRawMethod =>
                    let funcOpt = a.get()
                    let skipWrapped = if (let Some(f) <- funcOpt) { f.body.isNone() } else { false }
                    if (!skipWrapped) {
                        let funcId = if (let Some(f) <- funcOpt) { getId(f) } else { UInt32(0) }
                        annoTypes.add(EnumCHIRFormat_AnnotationValues(CHIRFormat_Annotation.Annotation_WRAPPEDRAWMETHOD))
                        annos.add(CHIRFormat_WrappedRawMethod.createWrappedRawMethod(fbBuilder, funcId))
                    }
                case a: OverrideSrcFuncType =>
                    let funcTypeOpt = a.get()
                    let typeId = if (let Some(ft) <- funcTypeOpt) { getId(ft) } else { UInt32(0) }
                    annoTypes.add(EnumCHIRFormat_AnnotationValues(CHIRFormat_Annotation.Annotation_OVERRIDESRCFUNCTYPE))
                    annos.add(CHIRFormat_OverrideSrcFuncType.createOverrideSrcFuncType(fbBuilder, typeId))
                case _ => ()
            }
        }
        let annoTypesArray = Array<UInt8>(annoTypes.size, { i => annoTypes[i] })
        let annoTypesVec = fbBuilder.createByteVector(annoTypesArray)
        let annosArray = Array<UInt32>(annos.size, { i => annos[i] })
        let annosVec = fbBuilder.createVectorOfTables(annosArray)

        let locOffset: UInt32 = if (obj._debugLocation.isValid()) {
            serializeDebugLocation(obj._debugLocation)
        } else {
            UInt32(0)
        }

        let attributes: UInt64 = obj._attributes.getRawAttrs()
        return CHIRFormat_Base.createBase(fbBuilder, annoTypesVec, annosVec, locOffset, attributes)
    }

    private func serializeType(obj: Type): UInt32 {
        let kind = serializeTypeKind(obj._kind)
        let argTys = getTypeIdList(obj._typeArgs)
        let argTysVec = if (argTys.size == 0) {
            UInt32(0)
        } else {
            fbBuilder.createUInt32Vector(argTys)
        }
        return CHIRFormat_Type.createType(fbBuilder, kind, argTysVec)
    }

    private func serializeTypeKind(kind: TypeKind): CHIRFormat_CHIRTypeKind {
        return match (kind) {
            case TypeKind.`Int8` => CHIRFormat_CHIRTypeKind.CHIRTypeKind_INT8
            case TypeKind.`Int16` => CHIRFormat_CHIRTypeKind.CHIRTypeKind_INT16
            case TypeKind.`Int32` => CHIRFormat_CHIRTypeKind.CHIRTypeKind_INT32
            case TypeKind.`Int64` => CHIRFormat_CHIRTypeKind.CHIRTypeKind_INT64
            case TypeKind.`IntNative` => CHIRFormat_CHIRTypeKind.CHIRTypeKind_INT_NATIVE
            case TypeKind.`UInt8` => CHIRFormat_CHIRTypeKind.CHIRTypeKind_UINT8
            case TypeKind.`UInt16` => CHIRFormat_CHIRTypeKind.CHIRTypeKind_UINT16
            case TypeKind.`UInt32` => CHIRFormat_CHIRTypeKind.CHIRTypeKind_UINT32
            case TypeKind.`UInt64` => CHIRFormat_CHIRTypeKind.CHIRTypeKind_UINT64
            case TypeKind.`UIntNative` => CHIRFormat_CHIRTypeKind.CHIRTypeKind_UINT_NATIVE
            case TypeKind.`Float16` => CHIRFormat_CHIRTypeKind.CHIRTypeKind_FLOAT16
            case TypeKind.`Float32` => CHIRFormat_CHIRTypeKind.CHIRTypeKind_FLOAT32
            case TypeKind.`Float64` => CHIRFormat_CHIRTypeKind.CHIRTypeKind_FLOAT64
            case TypeKind.`Rune` => CHIRFormat_CHIRTypeKind.CHIRTypeKind_RUNE
            case TypeKind.`Bool` => CHIRFormat_CHIRTypeKind.CHIRTypeKind_BOOLEAN
            case TypeKind.`Unit` => CHIRFormat_CHIRTypeKind.CHIRTypeKind_UNIT
            case TypeKind.`Nothing` => CHIRFormat_CHIRTypeKind.CHIRTypeKind_NOTHING
            case TypeKind.Tuple => CHIRFormat_CHIRTypeKind.CHIRTypeKind_TUPLE
            case TypeKind.Struct => CHIRFormat_CHIRTypeKind.CHIRTypeKind_STRUCT
            case TypeKind.Enum => CHIRFormat_CHIRTypeKind.CHIRTypeKind_ENUM
            case TypeKind.Func => CHIRFormat_CHIRTypeKind.CHIRTypeKind_FUNC
            case TypeKind.ClassLike => CHIRFormat_CHIRTypeKind.CHIRTypeKind_CLASS
            case TypeKind.RawArray => CHIRFormat_CHIRTypeKind.CHIRTypeKind_RAWARRAY
            case TypeKind.`VArray` => CHIRFormat_CHIRTypeKind.CHIRTypeKind_VARRAY
            case TypeKind.CPointer => CHIRFormat_CHIRTypeKind.CHIRTypeKind_C_POINTER
            case TypeKind.CString => CHIRFormat_CHIRTypeKind.CHIRTypeKind_C_STRING
            case TypeKind.Generic => CHIRFormat_CHIRTypeKind.CHIRTypeKind_GENERIC
            case TypeKind.Ref => CHIRFormat_CHIRTypeKind.CHIRTypeKind_REFTYPE
            case TypeKind.Box => CHIRFormat_CHIRTypeKind.CHIRTypeKind_BOXTYPE
            case TypeKind.`This` => CHIRFormat_CHIRTypeKind.CHIRTypeKind_THIS
            case TypeKind.Invalid => CHIRFormat_CHIRTypeKind.CHIRTypeKind_INVALID
        }
    }

    // Dispatch Type: align to CHIRFormat TypeElem (Type, RawArrayType, VArrayType, FuncType, CustomType, GenericType).
    private func dispatchType(obj: Type): UInt32 {
        let base = serializeType(obj)
        let typeId = getId(obj)

        return match (obj) {
            case t: RawArrayType =>
                typeKind[Int64(typeId) - 1] = EnumCHIRFormat_TypeElemValues(CHIRFormat_TypeElem.TypeElem_RAWARRAYTYPE)
                CHIRFormat_RawArrayType.createRawArrayType(fbBuilder, base, t.dims)
            case t: VArrayType =>
                typeKind[Int64(typeId) - 1] = EnumCHIRFormat_TypeElemValues(CHIRFormat_TypeElem.TypeElem_VARRAYTYPE)
                CHIRFormat_VArrayType.createVArrayType(fbBuilder, base, t.size)
            case t: FuncType =>
                typeKind[Int64(typeId) - 1] = EnumCHIRFormat_TypeElemValues(CHIRFormat_TypeElem.TypeElem_FUNCTYPE)
                CHIRFormat_FuncType.createFuncType(fbBuilder, base, t.isCFunc, t.hasVarArg)
            case t: GenericType =>
                typeKind[Int64(typeId) - 1] = EnumCHIRFormat_TypeElemValues(CHIRFormat_TypeElem.TypeElem_GENERICTYPE)
                let identifier = fbBuilder.createString(t._identifier)
                let srcCodeIdentifier = fbBuilder.createString(t.srcCodeName)
                let upperBounds = getTypeIdList(t._upperBounds)
                let upperBoundsVec = if (upperBounds.size == 0) {
                    UInt32(0)
                } else {
                    fbBuilder.createUInt32Vector(upperBounds)
                }
                CHIRFormat_GenericType.createGenericType(fbBuilder, base, identifier, srcCodeIdentifier, upperBoundsVec)
            case t: CustomType =>
                match (t) {
                    case ct: ClassLikeType =>
                        typeKind[Int64(typeId) - 1] = EnumCHIRFormat_TypeElemValues(CHIRFormat_TypeElem.TypeElem_CUSTOMTYPE)
                        CHIRFormat_CustomType.createCustomType(fbBuilder, base, getId(ct.def))
                    case st: StructType =>
                        typeKind[Int64(typeId) - 1] = EnumCHIRFormat_TypeElemValues(CHIRFormat_TypeElem.TypeElem_CUSTOMTYPE)
                        CHIRFormat_CustomType.createCustomType(fbBuilder, base, getId(st.def))
                    case et: EnumType =>
                        typeKind[Int64(typeId) - 1] = EnumCHIRFormat_TypeElemValues(CHIRFormat_TypeElem.TypeElem_CUSTOMTYPE)
                        CHIRFormat_CustomType.createCustomType(fbBuilder, base, getId(et.def))
                    case _ =>
                        throw Exception("Invalid custom type '${t.toString()}'.")
                }
            case _ =>
                // Primitives / tuple / ref / box / this / C family: nested Type tables only (kind + argTys).
                typeKind[Int64(typeId) - 1] = EnumCHIRFormat_TypeElemValues(CHIRFormat_TypeElem.TypeElem_TYPE)
                base
        }
    }

    private func serializeCustomAnnoInstance(anno: CustomAnnoInstance): UInt32 {
        let annoClassName = fbBuilder.createString(anno._classSrcCodeName)
        let argValuesVec: UInt32 = if (anno._argValues.isEmpty()) {
            UInt32(0)
        } else {
            let strOffsets = Array<UInt32>(anno._argValues.size, { i => fbBuilder.createString(anno._argValues[i]) })
            fbBuilder.createVectorOfTables(strOffsets)
        }
        let loc: UInt32 = serializeDebugLocation(anno._loc)
        return CHIRFormat_CustomAnnoInstance.createCustomAnnoInstance(fbBuilder, annoClassName, argValuesVec, loc)
    }

    private func serializeAnnoInfo(obj: AnnoInfo): UInt32 {
        let mangledName = fbBuilder.createString(obj._identifier)
        let annoInstancesVec: UInt32 = if (obj._annoInstances.isEmpty()) {
            UInt32(0)
        } else {
            let instanceOffsets = Array<UInt32>(obj._annoInstances.size, { i => serializeCustomAnnoInstance(obj._annoInstances[i]) })
            fbBuilder.createVectorOfTables(instanceOffsets)
        }
        return CHIRFormat_AnnoInfo.createAnnoInfo(fbBuilder, mangledName, annoInstancesVec)
    }

    private func serializeValue(obj: Value): UInt32 {
        let base = serializeBase(obj)
        let identifier = fbBuilder.createString(obj._identifier)
        let typeId = getId(obj._type)
        let kind = serializeValueKind(obj._kind)
        return CHIRFormat_Value.createValue(fbBuilder, base, typeId, identifier, kind)
    }

    private func serializeValueKind(kind: ValueKind): CHIRFormat_ValueKind {
        return match (kind) {
            case ValueKind.Literal => CHIRFormat_ValueKind.ValueKind_LITERAL
            case ValueKind.GlobalVar => CHIRFormat_ValueKind.ValueKind_GLOBALVAR
            case ValueKind.Parameter => CHIRFormat_ValueKind.ValueKind_PARAMETER
            case ValueKind.Func => CHIRFormat_ValueKind.ValueKind_FUNC
            case ValueKind.Block => CHIRFormat_ValueKind.ValueKind_BLOCK
            case ValueKind.BlockGroup => CHIRFormat_ValueKind.ValueKind_BLOCK_GROUP
            case ValueKind.LocalVar => CHIRFormat_ValueKind.ValueKind_LOCALVAR
            case ValueKind.Invalid => throw CHIRException("Invalid value kind.")
        }
    }

    private func serializeGlobalValue(obj: GlobalValue, base: UInt32): UInt32 {
        let srcCodeName = fbBuilder.createString(obj._srcCodeName)
        let rawMangledName = fbBuilder.createString(obj._rawMangledName)
        let packageName = fbBuilder.createString(obj._packageName)
        let declaredParent: UInt32 = if (let Some(dp) <- obj._declaredParent) {
            getId(dp)
        } else {
            UInt32(0)
        }
        let featuresVec: UInt32 = if (obj._features.isEmpty()) {
            UInt32(0)
        } else {
            let featOffsets = Array<UInt32>(obj._features.size, { i => fbBuilder.createString(obj._features[i]) })
            fbBuilder.createVectorOfTables(featOffsets)
        }
        let annoInfo = serializeAnnoInfo(obj._annoInfo)
        return CHIRFormat_GlobalValue.createGlobalValue(
            fbBuilder, base, srcCodeName, rawMangledName, packageName, declaredParent, featuresVec, annoInfo
        )
    }

    private func serializeGlobalVar(obj: GlobalVar, base: UInt32, valueId: UInt32): UInt32 {
        let globalValueBase = serializeGlobalValue(obj, base)
        var initializerId: UInt32 = 0
        if (let Some(v) <- obj._initializer) {
            initializerId = getId(v)
        }
        valueKind[Int64(valueId) - 1] = EnumCHIRFormat_ValueElemValues(CHIRFormat_ValueElem.ValueElem_GLOBALVAR)
        return CHIRFormat_GlobalVar.createGlobalVar(fbBuilder, globalValueBase, initializerId)
    }

    private func serializeParameter(obj: Parameter, base: UInt32, valueId: UInt32): UInt32 {
        var ownedFunc: UInt32 = 0
        var ownedLambda: UInt32 = 0
        if (obj._owner.isFunction()) {
            ownedFunc = getId(obj._owner)
        } else {
            ownedLambda = getId((obj._owner as LocalVar).getOrThrow().expr)
        }
        valueKind[Int64(valueId) - 1] = EnumCHIRFormat_ValueElemValues(CHIRFormat_ValueElem.ValueElem_PARAMETER)
        let srcCodeName = fbBuilder.createString(obj._srcCodeName)
        let annoInfo = serializeAnnoInfo(obj._annoInfo)
        return CHIRFormat_Parameter.createParameter(fbBuilder, base, ownedFunc, ownedLambda, srcCodeName, annoInfo)
    }

    private func serializeLocalVar(obj: LocalVar, base: UInt32, valueId: UInt32): UInt32 {
        let associatedExpr = getId(obj._expr)
        let isRetVal = obj._isRetValue
        valueKind[Int64(valueId) - 1] = EnumCHIRFormat_ValueElemValues(CHIRFormat_ValueElem.ValueElem_LOCALVAR)
        let srcCodeName = fbBuilder.createString(obj._srcCodeName)
        return CHIRFormat_LocalVar.createLocalVar(fbBuilder, base, associatedExpr, isRetVal, srcCodeName)
    }

    private func serializeFuncSigInfo(funcSig: FuncSigInfo): UInt32 {
        let nameOff = fbBuilder.createString(funcSig._name)
        let funcTypeId = getId(funcSig._type)
        let gtpVec = if (funcSig._genericTypeParams.size == 0) {
            UInt32(0)
        } else {
            let gtpIds = getTypeIdList(funcSig._genericTypeParams)
            fbBuilder.createUInt32Vector(gtpIds)
        }
        return CHIRFormat_FuncSigInfo.createFuncSigInfo(fbBuilder, nameOff, funcTypeId, gtpVec)
    }

    private func serializeFunction(obj: Function, base: UInt32, valueId: UInt32): UInt32 {
        var genericDecl: UInt32 = 0
        if (let Some(v) <- obj._genericDecl) {
            genericDecl = getId(v)
        }
        let funcKind = serializeFuncKind(obj._funcKind)
        let isFastNative = obj._isFastNative
        let isCFFIWrapper = obj._isCFFIWrapper
        var originalLambdaInfo: UInt32 = 0
        if (let Some(v) <- obj._originalLambdaInfo) {
            originalLambdaInfo = serializeFuncSigInfo(v)
        }
        let genericTypeParams = getTypeIdList(obj._genericTypeParams)
        let genericTypeParamsVec = if (genericTypeParams.size == 0) {
            UInt32(0)
        } else {
            fbBuilder.createUInt32Vector(genericTypeParams)
        }
        var paramDftValHostFunc: UInt32 = 0
        if (let Some(host) <- obj._paramDftValHostFunc) {
            paramDftValHostFunc = getId(host)
        }
        valueKind[Int64(valueId) - 1] = EnumCHIRFormat_ValueElemValues(CHIRFormat_ValueElem.ValueElem_FUNCTION)
        let globalValueBase = serializeGlobalValue(obj, base)
        var body: UInt32 = 0
        var retVal: UInt32 = 0
        if (let Some(v) <- obj._body) {
            body = getId(v)
            if (let Some(rv) <- obj._retValue) {
                retVal = getId(rv)
            }
        }
        let params = getValueIdList(obj._parameters)
        let paramsVec = if (params.size == 0) {
            UInt32(0)
        } else {
            fbBuilder.createUInt32Vector(params)
        }
        let propLoc = serializeDebugLocation(obj._propLocation)
        return CHIRFormat_Function.createFunction(
            fbBuilder, globalValueBase, genericDecl, funcKind, isFastNative, isCFFIWrapper,
            originalLambdaInfo, genericTypeParamsVec, paramDftValHostFunc, body, paramsVec, retVal, propLoc,
            obj._localId, obj._blockId, obj._blockGroupId
        )
    }

    private func serializeFuncKind(obj: FuncKind): CHIRFormat_FuncKind {
        return match (obj) {
            case FuncKind.Default => CHIRFormat_FuncKind.FuncKind_DEFAULT
            case FuncKind.Getter => CHIRFormat_FuncKind.FuncKind_GETTER
            case FuncKind.Setter => CHIRFormat_FuncKind.FuncKind_SETTER
            case FuncKind.Lambda => CHIRFormat_FuncKind.FuncKind_LAMBDA
            case FuncKind.ClassConstructor => CHIRFormat_FuncKind.FuncKind_CLASS_CONSTRUCTOR
            case FuncKind.PrimaryClassConstructor => CHIRFormat_FuncKind.FuncKind_PRIMAL_CLASS_CONSTRUCTOR
            case FuncKind.StructConstructor => CHIRFormat_FuncKind.FuncKind_STRUCT_CONSTRUCTOR
            case FuncKind.PrimaryStructConstructor => CHIRFormat_FuncKind.FuncKind_PRIMAL_STRUCT_CONSTRUCTOR
            case FuncKind.GlobalVarInit => CHIRFormat_FuncKind.FuncKind_GLOBALVAR_INIT
            case FuncKind.Finalizer => CHIRFormat_FuncKind.FuncKind_FINALIZER
            case FuncKind.MainEntry => CHIRFormat_FuncKind.FuncKind_MAIN_ENTRY
            case FuncKind.AnnoFactoryFunc => CHIRFormat_FuncKind.FuncKind_ANNOFACTORY_FUNC
            case FuncKind.MacroFunc => CHIRFormat_FuncKind.FuncKind_MACRO_FUNC
            case FuncKind.DefaultParameterFunc => CHIRFormat_FuncKind.FuncKind_DEFAULT_PARAMETER_FUNC
            case FuncKind.InstanceVarInit => CHIRFormat_FuncKind.FuncKind_INSTANCEVAR_INIT
        }
    }

    private func serializeBlock(obj: Block, base: UInt32, valueId: UInt32): UInt32 {
        let parentGroup = getId(obj._owner)
        let exprs = getExprIdList(obj._exprs)
        let exprsVec = if (exprs.size == 0) {
            UInt32(0)
        } else {
            fbBuilder.createUInt32Vector(exprs)
        }
        let predecessors = getValueIdList(obj._predecessors)
        let predecessorsVec = if (predecessors.size == 0) {
            UInt32(0)
        } else {
            fbBuilder.createUInt32Vector(predecessors)
        }
        let exceptionCatchListVec: UInt32 = if (let Some(excs) <- obj._exceptions) {
            let typeIds = getTypeIdList(excs)
            if (typeIds.size == 0) {
                UInt32(0)
            } else {
                fbBuilder.createUInt32Vector(typeIds)
            }
        } else {
            UInt32(0)
        }
        valueKind[Int64(valueId) - 1] = EnumCHIRFormat_ValueElemValues(CHIRFormat_ValueElem.ValueElem_BLOCK)
        return CHIRFormat_Block.createBlock(fbBuilder, base, parentGroup, exprsVec, predecessorsVec, obj.isLandingPadBlock, exceptionCatchListVec)
    }

    private func serializeBlockGroup(obj: BlockGroup, base: UInt32, valueId: UInt32): UInt32 {
        let entryBlock = getId(obj.entryBlock)
        let blocks = getValueIdList(obj._blocks)
        let blocksVec = if (blocks.size == 0) { UInt32(0) } else { fbBuilder.createUInt32Vector(blocks) }
        var ownedFunc: UInt32 = 0
        var ownedExpression: UInt32 = 0
        if (obj.owner.isFunction()) {
            ownedFunc = getId(obj.owner)
        } else {
            ownedExpression = getId((obj.owner as LocalVar).getOrThrow().expr)
        }
        valueKind[Int64(valueId) - 1] = EnumCHIRFormat_ValueElemValues(CHIRFormat_ValueElem.ValueElem_BLOCKGROUP)
        return CHIRFormat_BlockGroup.createBlockGroup(fbBuilder, base, entryBlock, blocksVec, ownedFunc, ownedExpression)
    }

    private func serializeLiteralValue(obj: LiteralValue, base: UInt32, valueId: UInt32): UInt32 {
        return match (obj) {
            case v: BoolLiteral =>
                valueKind[Int64(valueId) - 1] = EnumCHIRFormat_ValueElemValues(CHIRFormat_ValueElem.ValueElem_BOOLLITERAL)
                let literalBase = CHIRFormat_LiteralValue.createLiteralValue(fbBuilder, base, CHIRFormat_ConstantValueKind.ConstantValueKind_BOOL)
                CHIRFormat_BoolLiteral.createBoolLiteral(fbBuilder, literalBase, v.value)
            case v: IntLiteral =>
                valueKind[Int64(valueId) - 1] = EnumCHIRFormat_ValueElemValues(CHIRFormat_ValueElem.ValueElem_INTLITERAL)
                let literalBase = CHIRFormat_LiteralValue.createLiteralValue(fbBuilder, base, CHIRFormat_ConstantValueKind.ConstantValueKind_INT)
                CHIRFormat_IntLiteral.createIntLiteral(fbBuilder, literalBase, v.unsignedValue)
            case v: FloatLiteral =>
                valueKind[Int64(valueId) - 1] = EnumCHIRFormat_ValueElemValues(CHIRFormat_ValueElem.ValueElem_FLOATLITERAL)
                let literalBase = CHIRFormat_LiteralValue.createLiteralValue(fbBuilder, base, CHIRFormat_ConstantValueKind.ConstantValueKind_FLOAT)
                CHIRFormat_FloatLiteral.createFloatLiteral(fbBuilder, literalBase, v.value)
            case v: StringLiteral =>
                valueKind[Int64(valueId) - 1] = EnumCHIRFormat_ValueElemValues(CHIRFormat_ValueElem.ValueElem_STRINGLITERAL)
                let literalBase = CHIRFormat_LiteralValue.createLiteralValue(fbBuilder, base, CHIRFormat_ConstantValueKind.ConstantValueKind_STRING)
                let val = fbBuilder.createString(v.value)
                CHIRFormat_StringLiteral.createStringLiteral(fbBuilder, literalBase, val)
            case v: RuneLiteral =>
                valueKind[Int64(valueId) - 1] = EnumCHIRFormat_ValueElemValues(CHIRFormat_ValueElem.ValueElem_RUNELITERAL)
                let literalBase = CHIRFormat_LiteralValue.createLiteralValue(fbBuilder, base, CHIRFormat_ConstantValueKind.ConstantValueKind_RUNE)
                // Rune literal: encode as UInt32 (Unicode scalar value).
                let runeVal = UInt32(v.value)
                CHIRFormat_RuneLiteral.createRuneLiteral(fbBuilder, literalBase, runeVal)
            case v: UnitLiteral =>
                valueKind[Int64(valueId) - 1] = EnumCHIRFormat_ValueElemValues(CHIRFormat_ValueElem.ValueElem_UNITLITERAL)
                let literalBase = CHIRFormat_LiteralValue.createLiteralValue(fbBuilder, base, CHIRFormat_ConstantValueKind.ConstantValueKind_UNIT)
                CHIRFormat_UnitLiteral.createUnitLiteral(fbBuilder, literalBase)
            case v: NullLiteral =>
                valueKind[Int64(valueId) - 1] = EnumCHIRFormat_ValueElemValues(CHIRFormat_ValueElem.ValueElem_NULLLITERAL)
                let literalBase = CHIRFormat_LiteralValue.createLiteralValue(fbBuilder, base, CHIRFormat_ConstantValueKind.ConstantValueKind_NULL)
                CHIRFormat_NullLiteral.createNullLiteral(fbBuilder, literalBase)
            case _ => throw CHIRException("Invalid CHIR literal.")
        }
    }

    // Dispatch Value
    private func dispatchValue(obj: Value): UInt32 {
        let base = serializeValue(obj)
        let valueId = getId(obj)

        return match (obj) {
            case v: GlobalVar =>
                return serializeGlobalVar(v, base, valueId)
            case v: Parameter =>
                return serializeParameter(v, base, valueId)
            case v: LocalVar =>
                return serializeLocalVar(v, base, valueId)
            case v: Function =>
                return serializeFunction(v, base, valueId)
            case v: Block =>
                return serializeBlock(v, base, valueId)
            case v: BlockGroup =>
                return serializeBlockGroup(v, base, valueId)
            case v: LiteralValue =>
                return serializeLiteralValue(v, base, valueId)
            case _ => throw CHIRException("Invalid CHIR value.")
        }
    }

    private func serializeExpression(obj: Expression): UInt32 {
        let base = serializeBase(obj)
        let kind = serializeExprKind(obj._kind)
        let operands = getValueIdList(obj._operands)
        let operandsVec: UInt32 = if (operands.size == 0) { UInt32(0) } else { fbBuilder.createUInt32Vector(operands) }
        let blockGroups = getValueIdList(obj._blockGroups)
        let blockGroupsVec = if (blockGroups.size == 0) { UInt32(0) } else { fbBuilder.createUInt32Vector(blockGroups) }
        let parentBlock = getId(obj._owner.getOrThrow())
        var resultLocalVar: UInt32 = if (let Some(v) <- obj._result) { getId(v) } else { UInt32(0) }
        var resultTy: UInt32 = if (let Some(v) <- obj._result) { getId(v._type) } else { UInt32(0) }

        return CHIRFormat_Expression.createExpression(fbBuilder, base, kind, operandsVec, blockGroupsVec, parentBlock, resultLocalVar, resultTy)
    }

    private func serializeExprKind(kind: ExprKind): CHIRFormat_CHIRExprKind {
        return match (kind) {
            case ExprKind.Goto => CHIRFormat_CHIRExprKind.CHIRExprKind_GOTO
            case ExprKind.Branch => CHIRFormat_CHIRExprKind.CHIRExprKind_BRANCH
            case ExprKind.MultiBranch => CHIRFormat_CHIRExprKind.CHIRExprKind_MULTIBRANCH
            case ExprKind.Exit => CHIRFormat_CHIRExprKind.CHIRExprKind_EXIT

            case ExprKind.TryApply => CHIRFormat_CHIRExprKind.CHIRExprKind_TRYAPPLY
            case ExprKind.TryInvoke => CHIRFormat_CHIRExprKind.CHIRExprKind_TRYINVOKE
            case ExprKind.TryIntrinsic => CHIRFormat_CHIRExprKind.CHIRExprKind_TRYINTRINSIC
            case ExprKind.RaiseException => CHIRFormat_CHIRExprKind.CHIRExprKind_RAISEEXCEPTION
            case ExprKind.TrySpawn => CHIRFormat_CHIRExprKind.CHIRExprKind_TRYSPAWN
            case ExprKind.TryNumericCast => CHIRFormat_CHIRExprKind.CHIRExprKind_TRYNUMERICCAST
            case ExprKind.TryAllocate => CHIRFormat_CHIRExprKind.CHIRExprKind_TRYALLOCATE
            case ExprKind.TryRawArrayAllocate => CHIRFormat_CHIRExprKind.CHIRExprKind_TRYRAWARRAYALLOCATE
            case ExprKind.TryNeg => CHIRFormat_CHIRExprKind.CHIRExprKind_TRYNEG
            case ExprKind.TryAdd => CHIRFormat_CHIRExprKind.CHIRExprKind_TRYADD
            case ExprKind.TrySub => CHIRFormat_CHIRExprKind.CHIRExprKind_TRYSUB
            case ExprKind.TryMul => CHIRFormat_CHIRExprKind.CHIRExprKind_TRYMUL
            case ExprKind.TryDiv => CHIRFormat_CHIRExprKind.CHIRExprKind_TRYDIV
            case ExprKind.TryMod => CHIRFormat_CHIRExprKind.CHIRExprKind_TRYMOD
            case ExprKind.TryExp => CHIRFormat_CHIRExprKind.CHIRExprKind_TRYEXP
            case ExprKind.TryLShift => CHIRFormat_CHIRExprKind.CHIRExprKind_TRYLSHIFT
            case ExprKind.TryRShift => CHIRFormat_CHIRExprKind.CHIRExprKind_TRYRSHIFT

            case ExprKind.Neg => CHIRFormat_CHIRExprKind.CHIRExprKind_NEG
            case ExprKind.Not => CHIRFormat_CHIRExprKind.CHIRExprKind_NOT
            case ExprKind.BitNot => CHIRFormat_CHIRExprKind.CHIRExprKind_BITNOT

            case ExprKind.Add => CHIRFormat_CHIRExprKind.CHIRExprKind_ADD
            case ExprKind.Sub => CHIRFormat_CHIRExprKind.CHIRExprKind_SUB
            case ExprKind.Mul => CHIRFormat_CHIRExprKind.CHIRExprKind_MUL
            case ExprKind.Div => CHIRFormat_CHIRExprKind.CHIRExprKind_DIV
            case ExprKind.Mod => CHIRFormat_CHIRExprKind.CHIRExprKind_MOD
            case ExprKind.Exp => CHIRFormat_CHIRExprKind.CHIRExprKind_EXP
            case ExprKind.LShift => CHIRFormat_CHIRExprKind.CHIRExprKind_LSHIFT
            case ExprKind.RShift => CHIRFormat_CHIRExprKind.CHIRExprKind_RSHIFT
            case ExprKind.BitAnd => CHIRFormat_CHIRExprKind.CHIRExprKind_BITAND
            case ExprKind.BitOr => CHIRFormat_CHIRExprKind.CHIRExprKind_BITOR
            case ExprKind.BitXor => CHIRFormat_CHIRExprKind.CHIRExprKind_BITXOR
            case ExprKind.LT => CHIRFormat_CHIRExprKind.CHIRExprKind_LT
            case ExprKind.GT => CHIRFormat_CHIRExprKind.CHIRExprKind_GT
            case ExprKind.LE => CHIRFormat_CHIRExprKind.CHIRExprKind_LE
            case ExprKind.GE => CHIRFormat_CHIRExprKind.CHIRExprKind_GE
            case ExprKind.Equal => CHIRFormat_CHIRExprKind.CHIRExprKind_EQUAL
            case ExprKind.NotEqual => CHIRFormat_CHIRExprKind.CHIRExprKind_NOTEQUAL
            case ExprKind.And => CHIRFormat_CHIRExprKind.CHIRExprKind_AND
            case ExprKind.Or => CHIRFormat_CHIRExprKind.CHIRExprKind_OR

            case ExprKind.Allocate => CHIRFormat_CHIRExprKind.CHIRExprKind_ALLOCATE
            case ExprKind.Load => CHIRFormat_CHIRExprKind.CHIRExprKind_LOAD
            case ExprKind.Store => CHIRFormat_CHIRExprKind.CHIRExprKind_STORE
            case ExprKind.GetElementByName => CHIRFormat_CHIRExprKind.CHIRExprKind_GETELEMENTBYNAME
            case ExprKind.GetElementRef => CHIRFormat_CHIRExprKind.CHIRExprKind_GETELEMENTREF
            case ExprKind.StoreElementByName => CHIRFormat_CHIRExprKind.CHIRExprKind_STOREELEMENTBYNAME
            case ExprKind.StoreElementRef => CHIRFormat_CHIRExprKind.CHIRExprKind_STOREELEMENTREF

            case ExprKind.Lambda => CHIRFormat_CHIRExprKind.CHIRExprKind_LAMBDA
            case ExprKind.Constant => CHIRFormat_CHIRExprKind.CHIRExprKind_CONSTANT
            case ExprKind.Debug => CHIRFormat_CHIRExprKind.CHIRExprKind_DEBUG
            case ExprKind.Tuple => CHIRFormat_CHIRExprKind.CHIRExprKind_TUPLE
            case ExprKind.Field => CHIRFormat_CHIRExprKind.CHIRExprKind_FIELD
            case ExprKind.FieldByName => CHIRFormat_CHIRExprKind.CHIRExprKind_FIELDBYNAME

            case ExprKind.Apply => CHIRFormat_CHIRExprKind.CHIRExprKind_APPLY
            case ExprKind.Invoke => CHIRFormat_CHIRExprKind.CHIRExprKind_INVOKE
            case ExprKind.InstanceOf => CHIRFormat_CHIRExprKind.CHIRExprKind_INSTANCEOF
            case ExprKind.StaticCast => CHIRFormat_CHIRExprKind.CHIRExprKind_STATICCAST
            case ExprKind.Box => CHIRFormat_CHIRExprKind.CHIRExprKind_BOX
            case ExprKind.UnboxToValue => CHIRFormat_CHIRExprKind.CHIRExprKind_UNBOXTOVALUE
            case ExprKind.UnboxToRef => CHIRFormat_CHIRExprKind.CHIRExprKind_UNBOXTOREF
            case ExprKind.NumericCast => CHIRFormat_CHIRExprKind.CHIRExprKind_NUMERICCAST
            case ExprKind.CastToConcrete => CHIRFormat_CHIRExprKind.CHIRExprKind_CASTTOCONCRETE
            case ExprKind.CastToGeneric => CHIRFormat_CHIRExprKind.CHIRExprKind_CASTTOGENERIC

            case ExprKind.GetException => CHIRFormat_CHIRExprKind.CHIRExprKind_GETEXCEPTION
            case ExprKind.RawArrayAllocate => CHIRFormat_CHIRExprKind.CHIRExprKind_RAWARRAYALLOCATE
            case ExprKind.RawArrayLiteralInit => CHIRFormat_CHIRExprKind.CHIRExprKind_RAWARRAYLITERALINIT
            case ExprKind.RawArrayInitByValue => CHIRFormat_CHIRExprKind.CHIRExprKind_RAWARRAYINITBYVALUE
            case ExprKind.VArrayExpr => CHIRFormat_CHIRExprKind.CHIRExprKind_VARRAYEXPR
            case ExprKind.VArrayBuilder => CHIRFormat_CHIRExprKind.CHIRExprKind_VARRAYBUILDER

            case ExprKind.Intrinsic => CHIRFormat_CHIRExprKind.CHIRExprKind_INTRINSIC
            case ExprKind.Spawn => CHIRFormat_CHIRExprKind.CHIRExprKind_SPAWN
            case ExprKind.GetInstantiateValue => CHIRFormat_CHIRExprKind.CHIRExprKind_GETINSTANTIATEVALUE
            case ExprKind.GetRtti => CHIRFormat_CHIRExprKind.CHIRExprKind_GETRTTI
            case ExprKind.GetRttiStatic => CHIRFormat_CHIRExprKind.CHIRExprKind_GETRTTISTATIC
            case _ => throw CHIRException("Invalid expression kind '${kind.toString()}'.")
        }
    }

    private func serializeOverflowStrategy(strategy: OverflowStrategy): CHIRFormat_OverflowStrategy {
        return match (strategy) {
            case OverflowStrategy.NA => CHIRFormat_OverflowStrategy.OverflowStrategy_NA
            case OverflowStrategy.Wrapping => CHIRFormat_OverflowStrategy.OverflowStrategy_WRAPPING
            case OverflowStrategy.Throwing => CHIRFormat_OverflowStrategy.OverflowStrategy_THROWING
            case OverflowStrategy.Saturating => CHIRFormat_OverflowStrategy.OverflowStrategy_SATURATING
            case _ => throw CHIRException("Unsupported OverflowStrategy.")
        }
    }

    private func serializeSourceExpr(sourceExpr: SourceExpr): CHIRFormat_SourceExpr {
        return match (sourceExpr) {
            case SourceExpr.IfExpr => CHIRFormat_SourceExpr.SourceExpr_IF_EXPR
            case SourceExpr.WhileExpr => CHIRFormat_SourceExpr.SourceExpr_WHILE_EXPR
            case SourceExpr.DoWhileExpr => CHIRFormat_SourceExpr.SourceExpr_DO_WHILE_EXPR
            case SourceExpr.MatchExpr => CHIRFormat_SourceExpr.SourceExpr_MATCH_EXPR
            case SourceExpr.IfLetOrWhileLet => CHIRFormat_SourceExpr.SourceExpr_IF_LET_OR_WHILE_LET
            case SourceExpr.Quest => CHIRFormat_SourceExpr.SourceExpr_QUEST
            case SourceExpr.Binary => CHIRFormat_SourceExpr.SourceExpr_BINARY
            case SourceExpr.ForInExpr => CHIRFormat_SourceExpr.SourceExpr_FOR_IN_EXPR
            case SourceExpr.Other => CHIRFormat_SourceExpr.SourceExpr_OTHER
        }
    }

    private func serializeIntrinsicKind(kind: IntrinsicKind): CHIRFormat_IntrinsicKind {
        return match (kind) {
            case IntrinsicKind.NotIntrinsic => CHIRFormat_IntrinsicKind.IntrinsicKind_NOT_INTRINSIC
            case IntrinsicKind.NotImplemented => CHIRFormat_IntrinsicKind.IntrinsicKind_NOT_IMPLEMENTED
            case IntrinsicKind.ArrayInit => CHIRFormat_IntrinsicKind.IntrinsicKind_ARRAY_INIT
            case IntrinsicKind.SizeOf => CHIRFormat_IntrinsicKind.IntrinsicKind_SIZE_OF
            case IntrinsicKind.AlignOf => CHIRFormat_IntrinsicKind.IntrinsicKind_ALIGN_OF
            case IntrinsicKind.ArrayAcquireRawData => CHIRFormat_IntrinsicKind.IntrinsicKind_ARRAY_ACQUIRE_RAW_DATA
            case IntrinsicKind.ArrayReleaseRawData => CHIRFormat_IntrinsicKind.IntrinsicKind_ARRAY_RELEASE_RAW_DATA
            case IntrinsicKind.ArrayBuiltInCopyTo => CHIRFormat_IntrinsicKind.IntrinsicKind_ARRAY_BUILT_IN_COPY_TO
            case IntrinsicKind.ArrayGet => CHIRFormat_IntrinsicKind.IntrinsicKind_ARRAY_GET
            case IntrinsicKind.ArraySet => CHIRFormat_IntrinsicKind.IntrinsicKind_ARRAY_SET
            case IntrinsicKind.ArrayGetUnchecked => CHIRFormat_IntrinsicKind.IntrinsicKind_ARRAY_GET_UNCHECKED
            case IntrinsicKind.ArrayGetRefUnchecked => CHIRFormat_IntrinsicKind.IntrinsicKind_ARRAY_GET_REF_UNCHECKED
            case IntrinsicKind.ArraySetUnchecked => CHIRFormat_IntrinsicKind.IntrinsicKind_ARRAY_SET_UNCHECKED
            case IntrinsicKind.ArraySize => CHIRFormat_IntrinsicKind.IntrinsicKind_ARRAY_SIZE
            case IntrinsicKind.ArrayClone => CHIRFormat_IntrinsicKind.IntrinsicKind_ARRAY_CLONE
            case IntrinsicKind.ArraySliceInit => CHIRFormat_IntrinsicKind.IntrinsicKind_ARRAY_SLICE_INIT
            case IntrinsicKind.ArraySlice => CHIRFormat_IntrinsicKind.IntrinsicKind_ARRAY_SLICE
            case IntrinsicKind.ArraySliceRawArray => CHIRFormat_IntrinsicKind.IntrinsicKind_ARRAY_SLICE_RAWARRAY
            case IntrinsicKind.ArraySliceStart => CHIRFormat_IntrinsicKind.IntrinsicKind_ARRAY_SLICE_START
            case IntrinsicKind.ArraySliceSize => CHIRFormat_IntrinsicKind.IntrinsicKind_ARRAY_SLICE_SIZE
            case IntrinsicKind.ArraySliceGetElement => CHIRFormat_IntrinsicKind.IntrinsicKind_ARRAY_SLICE_GET_ELEMENT
            case IntrinsicKind.ArraySliceGetElementUnchecked => CHIRFormat_IntrinsicKind.IntrinsicKind_ARRAY_SLICE_GET_ELEMENT_UNCHECKED
            case IntrinsicKind.ArraySliceSetElement => CHIRFormat_IntrinsicKind.IntrinsicKind_ARRAY_SLICE_SET_ELEMENT
            case IntrinsicKind.ArraySliceSetElementUnchecked => CHIRFormat_IntrinsicKind.IntrinsicKind_ARRAY_SLICE_SET_ELEMENT_UNCHECKED
            case IntrinsicKind.FillInStackTrace => CHIRFormat_IntrinsicKind.IntrinsicKind_FILL_IN_STACK_TRACE
            case IntrinsicKind.DecodeStackTrace => CHIRFormat_IntrinsicKind.IntrinsicKind_DECODE_STACK_TRACE
            case IntrinsicKind.DumpCurrentThreadInfo => CHIRFormat_IntrinsicKind.IntrinsicKind_DUMP_CURRENT_THREAD_INFO
            case IntrinsicKind.DumpAllThreadsInfo => CHIRFormat_IntrinsicKind.IntrinsicKind_DUMP_ALL_THREADS_INFO
            case IntrinsicKind.Chr => CHIRFormat_IntrinsicKind.IntrinsicKind_CHR
            case IntrinsicKind.Ord => CHIRFormat_IntrinsicKind.IntrinsicKind_ORD
            case IntrinsicKind.CPointerGetPointerAddress => CHIRFormat_IntrinsicKind.IntrinsicKind_CPOINTER_GET_POINTER_ADDRESS
            case IntrinsicKind.CPointerInit0 => CHIRFormat_IntrinsicKind.IntrinsicKind_CPOINTER_INIT0
            case IntrinsicKind.CPointerInit1 => CHIRFormat_IntrinsicKind.IntrinsicKind_CPOINTER_INIT1
            case IntrinsicKind.CPointerRead => CHIRFormat_IntrinsicKind.IntrinsicKind_CPOINTER_READ
            case IntrinsicKind.CPointerWrite => CHIRFormat_IntrinsicKind.IntrinsicKind_CPOINTER_WRITE
            case IntrinsicKind.CPointerAdd => CHIRFormat_IntrinsicKind.IntrinsicKind_CPOINTER_ADD
            case IntrinsicKind.CStringInit => CHIRFormat_IntrinsicKind.IntrinsicKind_CSTRING_INIT
            case IntrinsicKind.CStringConvertCstrToPtr => CHIRFormat_IntrinsicKind.IntrinsicKind_CSTRING_CONVERT_CSTR_TO_PTR
            case IntrinsicKind.InoutParam => CHIRFormat_IntrinsicKind.IntrinsicKind_INOUT_PARAM
            case IntrinsicKind.RegisterWatchedObject => CHIRFormat_IntrinsicKind.IntrinsicKind_REGISTER_WATCHED_OBJECT
            case IntrinsicKind.ObjectRefeq => CHIRFormat_IntrinsicKind.IntrinsicKind_OBJECT_REFEQ
            case IntrinsicKind.RawArrayRefeq => CHIRFormat_IntrinsicKind.IntrinsicKind_RAW_ARRAY_REFEQ
            case IntrinsicKind.FuncRefeq => CHIRFormat_IntrinsicKind.IntrinsicKind_FUNC_REFEQ
            case IntrinsicKind.ObjectZeroValue => CHIRFormat_IntrinsicKind.IntrinsicKind_OBJECT_ZERO_VALUE
            case IntrinsicKind.InvokeGc => CHIRFormat_IntrinsicKind.IntrinsicKind_INVOKE_GC
            case IntrinsicKind.SetGcThreshold => CHIRFormat_IntrinsicKind.IntrinsicKind_SET_GC_THRESHOLD
            case IntrinsicKind.DumpCjHeapData => CHIRFormat_IntrinsicKind.IntrinsicKind_DUMP_CJ_HEAP_DATA
            case IntrinsicKind.GetGcCount => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_GC_COUNT
            case IntrinsicKind.GetGcTimeUs => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_GC_TIME_US
            case IntrinsicKind.GetGcFreedSize => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_GC_FREED_SIZE
            case IntrinsicKind.StartCjCpuProfiling => CHIRFormat_IntrinsicKind.IntrinsicKind_START_CJ_CPU_PROFILING
            case IntrinsicKind.StopCjCpuProfiling => CHIRFormat_IntrinsicKind.IntrinsicKind_STOP_CJ_CPU_PROFILING
            case IntrinsicKind.BlackBox => CHIRFormat_IntrinsicKind.IntrinsicKind_BLACK_BOX
            case IntrinsicKind.GetMaxHeapSize => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_MAX_HEAP_SIZE
            case IntrinsicKind.GetAllocateHeapSize => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_ALLOCATE_HEAP_SIZE
            case IntrinsicKind.GetRealHeapSize => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_REAL_HEAP_SIZE
            case IntrinsicKind.GetThreadNumber => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_THREAD_NUMBER
            case IntrinsicKind.GetBlockingThreadNumber => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_BLOCKING_THREAD_NUMBER
            case IntrinsicKind.GetNativeThreadNumber => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_NATIVE_THREAD_NUMBER
            case IntrinsicKind.VArraySet => CHIRFormat_IntrinsicKind.IntrinsicKind_VARRAY_SET
            case IntrinsicKind.VArrayGet => CHIRFormat_IntrinsicKind.IntrinsicKind_VARRAY_GET
            case IntrinsicKind.FutureInit => CHIRFormat_IntrinsicKind.IntrinsicKind_FUTURE_INIT
            case IntrinsicKind.FutureIsComplete => CHIRFormat_IntrinsicKind.IntrinsicKind_FUTURE_IS_COMPLETE
            case IntrinsicKind.FutureWait => CHIRFormat_IntrinsicKind.IntrinsicKind_FUTURE_WAIT
            case IntrinsicKind.FutureNotifyAll => CHIRFormat_IntrinsicKind.IntrinsicKind_FUTURE_NOTIFYALL
            case IntrinsicKind.IsThreadObjectInited => CHIRFormat_IntrinsicKind.IntrinsicKind_IS_THREAD_OBJECT_INITED
            case IntrinsicKind.GetThreadObject => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_THREAD_OBJECT
            case IntrinsicKind.SetThreadObject => CHIRFormat_IntrinsicKind.IntrinsicKind_SET_THREAD_OBJECT
            case IntrinsicKind.OverflowCheckedAdd => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_CHECKED_ADD
            case IntrinsicKind.OverflowCheckedSub => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_CHECKED_SUB
            case IntrinsicKind.OverflowCheckedMul => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_CHECKED_MUL
            case IntrinsicKind.OverflowCheckedDiv => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_CHECKED_DIV
            case IntrinsicKind.OverflowCheckedMod => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_CHECKED_MOD
            case IntrinsicKind.OverflowCheckedPow => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_CHECKED_POW
            case IntrinsicKind.OverflowCheckedInc => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_CHECKED_INC
            case IntrinsicKind.OverflowCheckedDec => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_CHECKED_DEC
            case IntrinsicKind.OverflowCheckedNeg => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_CHECKED_NEG
            case IntrinsicKind.OverflowThrowingAdd => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_THROWING_ADD
            case IntrinsicKind.OverflowThrowingSub => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_THROWING_SUB
            case IntrinsicKind.OverflowThrowingMul => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_THROWING_MUL
            case IntrinsicKind.OverflowThrowingDiv => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_THROWING_DIV
            case IntrinsicKind.OverflowThrowingMod => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_THROWING_MOD
            case IntrinsicKind.OverflowThrowingPow => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_THROWING_POW
            case IntrinsicKind.OverflowThrowingInc => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_THROWING_INC
            case IntrinsicKind.OverflowThrowingDec => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_THROWING_DEC
            case IntrinsicKind.OverflowThrowingNeg => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_THROWING_NEG
            case IntrinsicKind.OverflowSaturatingAdd => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_SATURATING_ADD
            case IntrinsicKind.OverflowSaturatingSub => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_SATURATING_SUB
            case IntrinsicKind.OverflowSaturatingMul => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_SATURATING_MUL
            case IntrinsicKind.OverflowSaturatingDiv => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_SATURATING_DIV
            case IntrinsicKind.OverflowSaturatingMod => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_SATURATING_MOD
            case IntrinsicKind.OverflowSaturatingPow => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_SATURATING_POW
            case IntrinsicKind.OverflowSaturatingInc => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_SATURATING_INC
            case IntrinsicKind.OverflowSaturatingDec => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_SATURATING_DEC
            case IntrinsicKind.OverflowSaturatingNeg => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_SATURATING_NEG
            case IntrinsicKind.OverflowWrappingAdd => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_WRAPPING_ADD
            case IntrinsicKind.OverflowWrappingSub => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_WRAPPING_SUB
            case IntrinsicKind.OverflowWrappingMul => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_WRAPPING_MUL
            case IntrinsicKind.OverflowWrappingDiv => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_WRAPPING_DIV
            case IntrinsicKind.OverflowWrappingMod => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_WRAPPING_MOD
            case IntrinsicKind.OverflowWrappingPow => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_WRAPPING_POW
            case IntrinsicKind.OverflowWrappingInc => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_WRAPPING_INC
            case IntrinsicKind.OverflowWrappingDec => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_WRAPPING_DEC
            case IntrinsicKind.OverflowWrappingNeg => CHIRFormat_IntrinsicKind.IntrinsicKind_OVERFLOW_WRAPPING_NEG
            case IntrinsicKind.VectorCompare32 => CHIRFormat_IntrinsicKind.IntrinsicKind_VECTOR_COMPARE_32
            case IntrinsicKind.VectorIndexByte32 => CHIRFormat_IntrinsicKind.IntrinsicKind_VECTOR_INDEX_BYTE_32
            case IntrinsicKind.CjCoreCanUseSimd => CHIRFormat_IntrinsicKind.IntrinsicKind_CJ_CORE_CAN_USE_SIMD
            case IntrinsicKind.CjTlsDynSetSessionCallback => CHIRFormat_IntrinsicKind.IntrinsicKind_CJ_TLS_DYN_SET_SESSION_CALLBACK
            case IntrinsicKind.CjTlsDynSslInit => CHIRFormat_IntrinsicKind.IntrinsicKind_CJ_TLS_DYN_SSL_INIT
            case IntrinsicKind.ReflectionIntrinsicStartFlag => CHIRFormat_IntrinsicKind.IntrinsicKind_REFLECTION_INTRINSIC_START_FLAG
            case IntrinsicKind.IsInterface => CHIRFormat_IntrinsicKind.IntrinsicKind_IS_INTERFACE
            case IntrinsicKind.IsClass => CHIRFormat_IntrinsicKind.IntrinsicKind_IS_CLASS
            case IntrinsicKind.IsPrimitive => CHIRFormat_IntrinsicKind.IntrinsicKind_IS_PRIMITIVE
            case IntrinsicKind.IsStruct => CHIRFormat_IntrinsicKind.IntrinsicKind_IS_STRUCT
            case IntrinsicKind.IsGeneric => CHIRFormat_IntrinsicKind.IntrinsicKind_IS_GENERIC
            case IntrinsicKind.GetOrCreateTypeInfoForReflect => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_OR_CREATE_TYPEINFO_FOR_REFLECT
            case IntrinsicKind.GetTypeTemplate => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_TYPETEMPLATE
            case IntrinsicKind.CheckMethodActualArgs => CHIRFormat_IntrinsicKind.IntrinsicKind_CHECK_METHOD_ACTUAL_ARGS
            case IntrinsicKind.MethodEntrypointIsNull => CHIRFormat_IntrinsicKind.IntrinsicKind_METHOD_ENTRYPOINT_IS_NULL
            case IntrinsicKind.IsRelectUnsupportedType => CHIRFormat_IntrinsicKind.IntrinsicKind_IS_RELECT_UNSUPPORTED_TYPE
            case IntrinsicKind.GetTypeForAny => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_TYPE_FOR_ANY
            case IntrinsicKind.GetTypeByMangledName => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_TYPE_BY_MANGLED_NAME
            case IntrinsicKind.GetTypeName => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_TYPE_NAME
            case IntrinsicKind.GetTypeByQualifiedName => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_TYPE_BY_QUALIFIED_NAME
            case IntrinsicKind.GetTypeQualifiedNameLength => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_TYPE_QUALIFIED_NAME_LENGTH
            case IntrinsicKind.GetTypeQualifiedName => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_TYPE_QUALIFIED_NAME
            case IntrinsicKind.GetNumOfInterface => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_NUM_OF_INTERFACE
            case IntrinsicKind.GetInterface => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_INTERFACE
            case IntrinsicKind.IsSubtype => CHIRFormat_IntrinsicKind.IntrinsicKind_IS_SUBTYPE
            case IntrinsicKind.GetTypeInfoModifier => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_TYPE_INFO_MODIFIER
            case IntrinsicKind.GetTypeInfoAnnotations => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_TYPE_INFO_ANNOTATIONS
            case IntrinsicKind.GetObjClass => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_OBJ_CLASS
            case IntrinsicKind.GetSuperTypeInfo => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_SUPER_TYPE_INFO
            case IntrinsicKind.GetNumOfInstanceMethodInfos => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_NUM_OF_INSTANCE_METHOD_INFOS
            case IntrinsicKind.GetInstanceMethodInfo => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_INSTANCE_METHOD_INFO
            case IntrinsicKind.GetNumOfStaticMethodInfos => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_NUM_OF_STATIC_METHOD_INFOS
            case IntrinsicKind.GetStaticMethodInfo => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_STATIC_METHOD_INFO
            case IntrinsicKind.GetMethodName => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_METHOD_NAME
            case IntrinsicKind.GetMethodReturnType => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_METHOD_RETURN_TYPE
            case IntrinsicKind.GetMethodModifier => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_METHOD_MODIFIER
            case IntrinsicKind.GetMethodAnnotations => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_METHOD_ANNOTATIONS
            case IntrinsicKind.ApplyCjMethod => CHIRFormat_IntrinsicKind.IntrinsicKind_APPLY_CJ_METHOD
            case IntrinsicKind.ApplyCjStaticMethod => CHIRFormat_IntrinsicKind.IntrinsicKind_APPLY_CJ_STATIC_METHOD
            case IntrinsicKind.ApplyCjGenericMethod => CHIRFormat_IntrinsicKind.IntrinsicKind_APPLY_CJ_GENERIC_METHOD
            case IntrinsicKind.ApplyCjGenericStaticMethod => CHIRFormat_IntrinsicKind.IntrinsicKind_APPLY_CJ_GENERIC_STATIC_METHOD
            case IntrinsicKind.GetNumOfActualParameters => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_NUM_OF_ACTUAL_PARAMETERS
            case IntrinsicKind.GetNumOfGenericParameters => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_NUM_OF_GENERIC_PARAMETERS
            case IntrinsicKind.GetActualParameterInfo => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_ACTUAL_PARAMETER_INFO
            case IntrinsicKind.GetGenericParameterInfo => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_GENERIC_PARAMETER_INFO
            case IntrinsicKind.GetNumOfInstanceFieldInfos => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_NUM_OF_INSTANCE_FIELD_INFOS
            case IntrinsicKind.GetInstanceFieldInfo => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_INSTANCE_FIELD_INFO
            case IntrinsicKind.GetNumOfStaticFieldInfos => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_NUM_OF_STATIC_FIELD_INFOS
            case IntrinsicKind.GetStaticFieldInfo => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_STATIC_FIELD_INFO
            case IntrinsicKind.GetStaticFieldName => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_STATIC_FIELD_NAME
            case IntrinsicKind.GetStaticFieldType => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_STATIC_FIELD_TYPE
            case IntrinsicKind.GetStaticFieldAnnotations => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_STATIC_FIELD_ANNOTATIONS
            case IntrinsicKind.GetStaticFieldModifier => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_STATIC_FIELD_MODIFIER
            case IntrinsicKind.GetFieldValue => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_FIELD_VALUE
            case IntrinsicKind.SetFieldValue => CHIRFormat_IntrinsicKind.IntrinsicKind_SET_FIELD_VALUE
            case IntrinsicKind.GetStaticFieldValue => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_STATIC_FIELD_VALUE
            case IntrinsicKind.SetStaticFieldValue => CHIRFormat_IntrinsicKind.IntrinsicKind_SET_STATIC_FIELD_VALUE
            case IntrinsicKind.GetFieldDeclaringType => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_FIELD_DECLARING_TYPE
            case IntrinsicKind.GetParameterIndex => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_PARAMETER_INDEX
            case IntrinsicKind.GetParameterName => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_PARAMETER_NAME
            case IntrinsicKind.GetParameterType => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_PARAMETER_TYPE
            case IntrinsicKind.GetParameterAnnotations => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_PARAMETER_ANNOTATIONS
            case IntrinsicKind.GetRelatedPackageInf => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_RELATED_PACKAGE_INF
            case IntrinsicKind.GetPackageName => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_PACKAGE_NAME
            case IntrinsicKind.GetPackageNumOfTypeInfos => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_PACKAGE_NUM_OF_TYPE_INFOS
            case IntrinsicKind.GetPackageTypeInfo => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_PACKAGE_TYPE_INFO
            case IntrinsicKind.GetPackageNumOfGlobalMethods => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_PACKAGE_NUM_OF_GLOBAL_METHODS
            case IntrinsicKind.GetPackageGlobalMethodInfo => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_PACKAGE_GLOBAL_METHOD_INFO
            case IntrinsicKind.GetPackageNumOfGlobalFieldInfos => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_PACKAGE_NUM_OF_GLOBAL_FIELD_INFOS
            case IntrinsicKind.GetPackageGlobalFieldInfo => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_PACKAGE_GLOBAL_FIELD_INFO
            case IntrinsicKind.LoadPackage => CHIRFormat_IntrinsicKind.IntrinsicKind_LOAD_PACKAGE
            case IntrinsicKind.GetPackageByQualifiedName => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_PACKAGE_BY_QUALIFIEDNAME
            case IntrinsicKind.GetPackageVersion => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_PACKAGE_VERSION
            case IntrinsicKind.GetSubPackages => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_SUB_PACKAGES
            case IntrinsicKind.ReflectionIntrinsicEndFlag => CHIRFormat_IntrinsicKind.IntrinsicKind_REFLECTION_INTRINSIC_END_FLAG
            case IntrinsicKind.Sleep => CHIRFormat_IntrinsicKind.IntrinsicKind_SLEEP
            case IntrinsicKind.SourceFile => CHIRFormat_IntrinsicKind.IntrinsicKind_SOURCE_FILE
            case IntrinsicKind.SourceLine => CHIRFormat_IntrinsicKind.IntrinsicKind_SOURCE_LINE
            case IntrinsicKind.IdentityHashCode => CHIRFormat_IntrinsicKind.IntrinsicKind_IDENTITY_HASHCODE
            case IntrinsicKind.IdentityHashCodeForArray => CHIRFormat_IntrinsicKind.IntrinsicKind_IDENTITY_HASHCODE_FOR_ARRAY
            case IntrinsicKind.AtomicLoad => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_LOAD
            case IntrinsicKind.AtomicStore => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_STORE
            case IntrinsicKind.AtomicSwap => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_SWAP
            case IntrinsicKind.AtomicCompareAndSwap => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_COMPARE_AND_SWAP
            case IntrinsicKind.AtomicFetchAdd => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_FETCH_ADD
            case IntrinsicKind.AtomicFetchSub => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_FETCH_SUB
            case IntrinsicKind.AtomicFetchAnd => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_FETCH_AND
            case IntrinsicKind.AtomicFetchOr => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_FETCH_OR
            case IntrinsicKind.AtomicFetchXor => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_FETCH_XOR
            case IntrinsicKind.MutexInit => CHIRFormat_IntrinsicKind.IntrinsicKind_MUTEX_INIT
            case IntrinsicKind.CjMutexLock => CHIRFormat_IntrinsicKind.IntrinsicKind_CJ_MUTEX_LOCK
            case IntrinsicKind.MutexTryLock => CHIRFormat_IntrinsicKind.IntrinsicKind_MUTEX_TRY_LOCK
            case IntrinsicKind.MutexCheckStatus => CHIRFormat_IntrinsicKind.IntrinsicKind_MUTEX_CHECK_STATUS
            case IntrinsicKind.MutexUnlock => CHIRFormat_IntrinsicKind.IntrinsicKind_MUTEX_UNLOCK
            case IntrinsicKind.WaitQueueInit => CHIRFormat_IntrinsicKind.IntrinsicKind_WAITQUEUE_INIT
            case IntrinsicKind.MonitorInit => CHIRFormat_IntrinsicKind.IntrinsicKind_MONITOR_INIT
            case IntrinsicKind.MoitiorWait => CHIRFormat_IntrinsicKind.IntrinsicKind_MOITIOR_WAIT
            case IntrinsicKind.MoitiorNotify => CHIRFormat_IntrinsicKind.IntrinsicKind_MOITIOR_NOTIFY
            case IntrinsicKind.MoitiorNotifyAll => CHIRFormat_IntrinsicKind.IntrinsicKind_MOITIOR_NOTIFY_ALL
            case IntrinsicKind.MulticonditionWait => CHIRFormat_IntrinsicKind.IntrinsicKind_MULTICONDITION_WAIT
            case IntrinsicKind.MulticonditionNotify => CHIRFormat_IntrinsicKind.IntrinsicKind_MULTICONDITION_NOTIFY
            case IntrinsicKind.MulticonditionNotifyAll => CHIRFormat_IntrinsicKind.IntrinsicKind_MULTICONDITION_NOTIFY_ALL
            case IntrinsicKind.CrossAccessBarrier => CHIRFormat_IntrinsicKind.IntrinsicKind_CROSS_ACCESS_BARRIER
            case IntrinsicKind.CreateExportHandle => CHIRFormat_IntrinsicKind.IntrinsicKind_CREATE_EXPORT_HANDLE
            case IntrinsicKind.GetExportedRef => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_EXPORTED_REF
            case IntrinsicKind.RemoveExportedRef => CHIRFormat_IntrinsicKind.IntrinsicKind_REMOVE_EXPORTED_REF
            case IntrinsicKind.FfiCjAstLex => CHIRFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_AST_LEX
            case IntrinsicKind.FfiCjAstParseExpr => CHIRFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_AST_PARSEEXPR
            case IntrinsicKind.FfiCjAstParseDecl => CHIRFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_AST_PARSEDECL
            case IntrinsicKind.FfiCjAstParsePropMemberDecl => CHIRFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_AST_PARSE_PROPMEMBERDECL
            case IntrinsicKind.FfiCjAstParsePriConstructor => CHIRFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_AST_PARSE_PRICONSTRUCTOR
            case IntrinsicKind.FfiCjAstParsePattern => CHIRFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_AST_PARSE_PATTERN
            case IntrinsicKind.FfiCjAstParseType => CHIRFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_AST_PARSE_TYPE
            case IntrinsicKind.FfiCjAstParseTopLevel => CHIRFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_AST_PARSETOPLEVEL
            case IntrinsicKind.FfiCjAstDiagReport => CHIRFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_AST_DIAGREPORT
            case IntrinsicKind.FfiCjParentContext => CHIRFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_PARENT_CONTEXT
            case IntrinsicKind.FfiCjMacroItemInfo => CHIRFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_MACRO_ITEM_INFO
            case IntrinsicKind.FfiCjGetChildMessages => CHIRFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_GET_CHILD_MESSAGES
            case IntrinsicKind.FfiCjCheckAddSpace => CHIRFormat_IntrinsicKind.IntrinsicKind_FFI_CJ_CHECK_ADD_SPACE
            case IntrinsicKind.CgUnsafeBegin => CHIRFormat_IntrinsicKind.IntrinsicKind_CG_UNSAFE_BEGIN
            case IntrinsicKind.CgUnsafeEnd => CHIRFormat_IntrinsicKind.IntrinsicKind_CG_UNSAFE_END
            case IntrinsicKind.Strlen => CHIRFormat_IntrinsicKind.IntrinsicKind_STRLEN
            case IntrinsicKind.MemcpyS => CHIRFormat_IntrinsicKind.IntrinsicKind_MEMCPY_S
            case IntrinsicKind.MemsetS => CHIRFormat_IntrinsicKind.IntrinsicKind_MEMSET_S
            case IntrinsicKind.Free => CHIRFormat_IntrinsicKind.IntrinsicKind_FREE
            case IntrinsicKind.Malloc => CHIRFormat_IntrinsicKind.IntrinsicKind_MALLOC
            case IntrinsicKind.Strcmp => CHIRFormat_IntrinsicKind.IntrinsicKind_STRCMP
            case IntrinsicKind.Memcmp => CHIRFormat_IntrinsicKind.IntrinsicKind_MEMCMP
            case IntrinsicKind.Strncmp => CHIRFormat_IntrinsicKind.IntrinsicKind_STRNCMP
            case IntrinsicKind.Strcasecmp => CHIRFormat_IntrinsicKind.IntrinsicKind_STRCASECMP
            case IntrinsicKind.AtomicInt8Load => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT8_LOAD
            case IntrinsicKind.AtomicInt8Store => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT8_STORE
            case IntrinsicKind.AtomicInt8Swap => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT8_SWAP
            case IntrinsicKind.AtomicInt8Cas => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT8_CAS
            case IntrinsicKind.AtomicInt8FetchAdd => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT8_FETCH_ADD
            case IntrinsicKind.AtomicInt8FetchSub => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT8_FETCH_SUB
            case IntrinsicKind.AtomicInt8FetchAnd => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT8_FETCH_AND
            case IntrinsicKind.AtomicInt8FetchOr => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT8_FETCH_OR
            case IntrinsicKind.AtomicInt8FetchXor => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT8_FETCH_XOR
            case IntrinsicKind.AtomicInt16Load => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT16_LOAD
            case IntrinsicKind.AtomicInt16Store => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT16_STORE
            case IntrinsicKind.AtomicInt16Swap => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT16_SWAP
            case IntrinsicKind.AtomicInt16Cas => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT16_CAS
            case IntrinsicKind.AtomicInt16FetchAdd => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT16_FETCH_ADD
            case IntrinsicKind.AtomicInt16FetchSub => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT16_FETCH_SUB
            case IntrinsicKind.AtomicInt16FetchAnd => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT16_FETCH_AND
            case IntrinsicKind.AtomicInt16FetchOr => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT16_FETCH_OR
            case IntrinsicKind.AtomicInt16FetchXor => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT16_FETCH_XOR
            case IntrinsicKind.AtomicInt32Load => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT32_LOAD
            case IntrinsicKind.AtomicInt32Store => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT32_STORE
            case IntrinsicKind.AtomicInt32Swap => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT32_SWAP
            case IntrinsicKind.AtomicInt32Cas => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT32_CAS
            case IntrinsicKind.AtomicInt32FetchAdd => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT32_FETCH_ADD
            case IntrinsicKind.AtomicInt32FetchSub => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT32_FETCH_SUB
            case IntrinsicKind.AtomicInt32FetchAnd => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT32_FETCH_AND
            case IntrinsicKind.AtomicInt32FetchOr => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT32_FETCH_OR
            case IntrinsicKind.AtomicInt32FetchXor => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT32_FETCH_XOR
            case IntrinsicKind.AtomicInt64Load => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT64_LOAD
            case IntrinsicKind.AtomicInt64Store => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT64_STORE
            case IntrinsicKind.AtomicInt64Swap => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT64_SWAP
            case IntrinsicKind.AtomicInt64Cas => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT64_CAS
            case IntrinsicKind.AtomicInt64FetchAdd => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT64_FETCH_ADD
            case IntrinsicKind.AtomicInt64FetchSub => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT64_FETCH_SUB
            case IntrinsicKind.AtomicInt64FetchAnd => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT64_FETCH_AND
            case IntrinsicKind.AtomicInt64FetchOr => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT64_FETCH_OR
            case IntrinsicKind.AtomicInt64FetchXor => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_INT64_FETCH_XOR
            case IntrinsicKind.AtomicUint8Load => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT8_LOAD
            case IntrinsicKind.AtomicUint8Store => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT8_STORE
            case IntrinsicKind.AtomicUint8Swap => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT8_SWAP
            case IntrinsicKind.AtomicUint8Cas => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT8_CAS
            case IntrinsicKind.AtomicUint8FetchAdd => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT8_FETCH_ADD
            case IntrinsicKind.AtomicUint8FetchSub => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT8_FETCH_SUB
            case IntrinsicKind.AtomicUint8FetchAnd => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT8_FETCH_AND
            case IntrinsicKind.AtomicUint8FetchOr => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT8_FETCH_OR
            case IntrinsicKind.AtomicUint8FetchXor => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT8_FETCH_XOR
            case IntrinsicKind.AtomicUint16Load => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT16_LOAD
            case IntrinsicKind.AtomicUint16Store => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT16_STORE
            case IntrinsicKind.AtomicUint16Swap => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT16_SWAP
            case IntrinsicKind.AtomicUint16Cas => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT16_CAS
            case IntrinsicKind.AtomicUint16FetchAdd => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT16_FETCH_ADD
            case IntrinsicKind.AtomicUint16FetchSub => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT16_FETCH_SUB
            case IntrinsicKind.AtomicUint16FetchAnd => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT16_FETCH_AND
            case IntrinsicKind.AtomicUint16FetchOr => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT16_FETCH_OR
            case IntrinsicKind.AtomicUint16FetchXor => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT16_FETCH_XOR
            case IntrinsicKind.AtomicUint32Load => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT32_LOAD
            case IntrinsicKind.AtomicUint32Store => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT32_STORE
            case IntrinsicKind.AtomicUint32Swap => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT32_SWAP
            case IntrinsicKind.AtomicUint32Cas => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT32_CAS
            case IntrinsicKind.AtomicUint32FetchAdd => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT32_FETCH_ADD
            case IntrinsicKind.AtomicUint32FetchSub => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT32_FETCH_SUB
            case IntrinsicKind.AtomicUint32FetchAnd => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT32_FETCH_AND
            case IntrinsicKind.AtomicUint32FetchOr => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT32_FETCH_OR
            case IntrinsicKind.AtomicUint32FetchXor => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT32_FETCH_XOR
            case IntrinsicKind.AtomicUint64Load => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT64_LOAD
            case IntrinsicKind.AtomicUint64Store => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT64_STORE
            case IntrinsicKind.AtomicUint64Swap => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT64_SWAP
            case IntrinsicKind.AtomicUint64Cas => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT64_CAS
            case IntrinsicKind.AtomicUint64FetchAdd => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT64_FETCH_ADD
            case IntrinsicKind.AtomicUint64FetchSub => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT64_FETCH_SUB
            case IntrinsicKind.AtomicUint64FetchAnd => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT64_FETCH_AND
            case IntrinsicKind.AtomicUint64FetchOr => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT64_FETCH_OR
            case IntrinsicKind.AtomicUint64FetchXor => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_UINT64_FETCH_XOR
            case IntrinsicKind.AtomicBoolLoad => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_BOOL_LOAD
            case IntrinsicKind.AtomicBoolStore => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_BOOL_STORE
            case IntrinsicKind.AtomicBoolSwap => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_BOOL_SWAP
            case IntrinsicKind.AtomicBoolCas => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_BOOL_CAS
            case IntrinsicKind.AtomicReferenceBaseLoad => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_REFERENCEBASE_LOAD
            case IntrinsicKind.AtomicReferenceBaseStore => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_REFERENCEBASE_STORE
            case IntrinsicKind.AtomicReferenceBaseSwap => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_REFERENCEBASE_SWAP
            case IntrinsicKind.AtomicReferenceBaseCas => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_REFERENCEBASE_CAS
            case IntrinsicKind.AtomicOptionReferenceLoad => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_OPTIONREFERENCE_LOAD
            case IntrinsicKind.AtomicOptionReferenceStore => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_OPTIONREFERENCE_STORE
            case IntrinsicKind.AtomicOptionReferenceSwap => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_OPTIONREFERENCE_SWAP
            case IntrinsicKind.AtomicOptionReferenceCas => CHIRFormat_IntrinsicKind.IntrinsicKind_ATOMIC_OPTIONREFERENCE_CAS
            case IntrinsicKind.BeginCatch => CHIRFormat_IntrinsicKind.IntrinsicKind_BEGIN_CATCH
            case IntrinsicKind.Abs => CHIRFormat_IntrinsicKind.IntrinsicKind_ABS
            case IntrinsicKind.Fabs => CHIRFormat_IntrinsicKind.IntrinsicKind_FABS
            case IntrinsicKind.Floor => CHIRFormat_IntrinsicKind.IntrinsicKind_FLOOR
            case IntrinsicKind.Ceil => CHIRFormat_IntrinsicKind.IntrinsicKind_CEIL
            case IntrinsicKind.Trunc => CHIRFormat_IntrinsicKind.IntrinsicKind_TRUNC
            case IntrinsicKind.Sin => CHIRFormat_IntrinsicKind.IntrinsicKind_SIN
            case IntrinsicKind.Cos => CHIRFormat_IntrinsicKind.IntrinsicKind_COS
            case IntrinsicKind.Exp => CHIRFormat_IntrinsicKind.IntrinsicKind_EXP
            case IntrinsicKind.Exp2 => CHIRFormat_IntrinsicKind.IntrinsicKind_EXP2
            case IntrinsicKind.Log => CHIRFormat_IntrinsicKind.IntrinsicKind_LOG
            case IntrinsicKind.Log2 => CHIRFormat_IntrinsicKind.IntrinsicKind_LOG2
            case IntrinsicKind.Log10 => CHIRFormat_IntrinsicKind.IntrinsicKind_LOG10
            case IntrinsicKind.Sqrt => CHIRFormat_IntrinsicKind.IntrinsicKind_SQRT
            case IntrinsicKind.Round => CHIRFormat_IntrinsicKind.IntrinsicKind_ROUND
            case IntrinsicKind.Pow => CHIRFormat_IntrinsicKind.IntrinsicKind_POW
            case IntrinsicKind.Powi => CHIRFormat_IntrinsicKind.IntrinsicKind_POWI
            case IntrinsicKind.BitCast => CHIRFormat_IntrinsicKind.IntrinsicKind_BIT_CAST
            case IntrinsicKind.Preinitialize => CHIRFormat_IntrinsicKind.IntrinsicKind_PREINITIALIZE
            case IntrinsicKind.ObjectAs => CHIRFormat_IntrinsicKind.IntrinsicKind_OBJECT_AS
            case IntrinsicKind.IsNull => CHIRFormat_IntrinsicKind.IntrinsicKind_IS_NULL
            case IntrinsicKind.GetTypeForTypeParameter => CHIRFormat_IntrinsicKind.IntrinsicKind_GET_TYPE_FOR_TYPE_PARAMETER
            case IntrinsicKind.IsSubtypeTypes => CHIRFormat_IntrinsicKind.IntrinsicKind_IS_SUBTYPE_TYPES
        }
    }

    private func serializeFuncCall(base: UInt32, exprId: UInt32, obj: FuncCall): UInt32 {
        let instTypeArgs = getTypeIdList(obj._instantiatedTypeArgs)
        let instTypeArgsVec = if (instTypeArgs.size == 0) { UInt32(0) } else { fbBuilder.createUInt32Vector(instTypeArgs) }
        var objType: UInt32 = 0
        if (let Some(v) <- obj._objType) {
            objType = getId(v)
        }
        return CHIRFormat_FuncCall.createFuncCall(fbBuilder, base, instTypeArgsVec, objType)
    }

    // Dispatch Expression
    private func dispatchExpression(obj: Expression): UInt32 {
        let base = serializeExpression(obj)
        let exprId = getId(obj)

        return match (obj) {
            case e: AllocateBase =>
                exprKind[Int64(exprId) - 1] = EnumCHIRFormat_ExpressionElemValues(CHIRFormat_ExpressionElem.ExpressionElem_ALLOCATEBASE)
                let allocatedType = getId(e._allocatedType)
                CHIRFormat_AllocateBase.createAllocateBase(fbBuilder, base, allocatedType)
            case e: ApplyBase =>
                exprKind[Int64(exprId) - 1] = EnumCHIRFormat_ExpressionElemValues(CHIRFormat_ExpressionElem.ExpressionElem_APPLYBASE)
                let funcCallBase = serializeFuncCall(base, exprId, e)
                return CHIRFormat_ApplyBase.createApplyBase(fbBuilder, funcCallBase, e._isSuperCall)
            case e: BinaryExpressionBase =>
                exprKind[Int64(exprId) - 1] = EnumCHIRFormat_ExpressionElemValues(CHIRFormat_ExpressionElem.ExpressionElem_BINARYEXPRESSIONBASE)
                let overflowStrategy = serializeOverflowStrategy(e._overflow)
                CHIRFormat_BinaryExpressionBase.createBinaryExpressionBase(fbBuilder, base, overflowStrategy)
            case e: Branch =>
                exprKind[Int64(exprId) - 1] = EnumCHIRFormat_ExpressionElemValues(CHIRFormat_ExpressionElem.ExpressionElem_BRANCH)
                let sourceExpr = serializeSourceExpr(e._sourceExpr)
                CHIRFormat_Branch.createBranch(fbBuilder, base, sourceExpr)
            case e: Debug =>
                exprKind[Int64(exprId) - 1] = EnumCHIRFormat_ExpressionElemValues(CHIRFormat_ExpressionElem.ExpressionElem_DEBUG)
                let srcCodeName = fbBuilder.createString(e._srcCodeName)
                CHIRFormat_Debug.createDebug(fbBuilder, base, srcCodeName)
            case e: Field =>
                exprKind[Int64(exprId) - 1] = EnumCHIRFormat_ExpressionElemValues(CHIRFormat_ExpressionElem.ExpressionElem_FIELD)
                let path = Array<UInt64>(e.path.size, { i => e.path[i] })
                let pathVec = if (path.size == 0) { UInt32(0) } else { fbBuilder.createUInt64Vector(path) }
                CHIRFormat_Field.createField(fbBuilder, base, pathVec)
            case e: FieldByName =>
                exprKind[Int64(exprId) - 1] = EnumCHIRFormat_ExpressionElemValues(CHIRFormat_ExpressionElem.ExpressionElem_FIELDBYNAME)
                let path = Array<UInt32>(e.fieldNames.size, { i => fbBuilder.createString(e.fieldNames[i]) })
                let pathVec = if (path.size == 0) { UInt32(0) } else { fbBuilder.createVectorOfTables(path) }
                CHIRFormat_FieldByName.createFieldByName(fbBuilder, base, pathVec)
            case e: GetElementByName =>
                exprKind[Int64(exprId) - 1] = EnumCHIRFormat_ExpressionElemValues(CHIRFormat_ExpressionElem.ExpressionElem_GETELEMENTBYNAME)
                let path = Array<UInt32>(e.fieldNames.size, { i => fbBuilder.createString(e.fieldNames[i]) })
                let pathVec = if (path.size == 0) { UInt32(0) } else { fbBuilder.createVectorOfTables(path) }
                CHIRFormat_GetElementByName.createGetElementByName(fbBuilder, base, pathVec)
            case e: GetElementRef =>
                exprKind[Int64(exprId) - 1] = EnumCHIRFormat_ExpressionElemValues(CHIRFormat_ExpressionElem.ExpressionElem_GETELEMENTREF)
                let path = Array<UInt64>(e.path.size, { i => e.path[i] })
                let pathVec = if (path.size == 0) { UInt32(0) } else { fbBuilder.createUInt64Vector(path) }
                CHIRFormat_GetElementRef.createGetElementRef(fbBuilder, base, pathVec)
            case e: GetInstantiateValue =>
                exprKind[Int64(exprId) - 1] = EnumCHIRFormat_ExpressionElemValues(CHIRFormat_ExpressionElem.ExpressionElem_GETINSTANTIATEVALUE)
                let instantiateTys = getTypeIdList(e._instantiateTypes)
                let instantiateTysVec = if (instantiateTys.size == 0) { UInt32(0) } else { fbBuilder.createUInt32Vector(instantiateTys) }
                CHIRFormat_GetInstantiateValue.createGetInstantiateValue(fbBuilder, base, instantiateTysVec)
            case e: GetRTTIStatic =>
                exprKind[Int64(exprId) - 1] = EnumCHIRFormat_ExpressionElemValues(CHIRFormat_ExpressionElem.ExpressionElem_GETRTTISTATIC)
                let rttiType = getId(e._ty)
                CHIRFormat_GetRTTIStatic.createGetRTTIStatic(fbBuilder, base, rttiType)
            case e: InstanceOf =>
                exprKind[Int64(exprId) - 1] = EnumCHIRFormat_ExpressionElemValues(CHIRFormat_ExpressionElem.ExpressionElem_INSTANCEOF)
                let targetType = getId(e.targetType)
                CHIRFormat_InstanceOf.createInstanceOf(fbBuilder, base, targetType)
            case e: IntrinsicBase =>
                exprKind[Int64(exprId) - 1] = EnumCHIRFormat_ExpressionElemValues(CHIRFormat_ExpressionElem.ExpressionElem_INTRINSICBASE)
                let funcCallBase = serializeFuncCall(base, exprId, e)
                let intrinsicKind = serializeIntrinsicKind(e._calleeKind)
                CHIRFormat_IntrinsicBase.createIntrinsicBase(fbBuilder, funcCallBase, intrinsicKind)
            case e: InvokeBase =>
                exprKind[Int64(exprId) - 1] = EnumCHIRFormat_ExpressionElemValues(CHIRFormat_ExpressionElem.ExpressionElem_INVOKEBASE)
                let funcCallBase = serializeFuncCall(base, exprId, e)
                let overflowStrategy = serializeOverflowStrategy(e._overflowStrategy)
                CHIRFormat_InvokeBase.createInvokeBase(fbBuilder, funcCallBase, overflowStrategy)
            case e: Lambda =>
                exprKind[Int64(exprId) - 1] = EnumCHIRFormat_ExpressionElemValues(CHIRFormat_ExpressionElem.ExpressionElem_LAMBDA)
                let funcTy = getId(e._funcType)
                let isLocalFunc = e._isLocalFunc
                let identifier = fbBuilder.createString(e._identifier)
                let srcCodeName = fbBuilder.createString(e._srcCodeName)
                let params = getValueIdList(e._parameters)
                let paramsVec = if (params.size == 0) { UInt32(0) } else { fbBuilder.createUInt32Vector(params) }
                let genericTypeParams = getTypeIdList(e._genericTypeParams)
                let genericTypeParamsVec = if (genericTypeParams.size == 0) { UInt32(0) } else { fbBuilder.createUInt32Vector(genericTypeParams) }
                let body = getId(e.body)
                let retVal = getId(e._returnValue.getOrThrow())
                let isCompileTimeValue = e._isCompileTimeValue
                CHIRFormat_Lambda.createLambda(fbBuilder, base, funcTy, isLocalFunc, identifier, srcCodeName, paramsVec, genericTypeParamsVec, body, retVal, isCompileTimeValue)
            case e: MultiBranch =>
                exprKind[Int64(exprId) - 1] = EnumCHIRFormat_ExpressionElemValues(CHIRFormat_ExpressionElem.ExpressionElem_MULTIBRANCH)
                let caseValues = Array<UInt64>(e.caseValues.size, { i => e.caseValues[i] })
                let caseValuesVec = if (caseValues.isEmpty()) { UInt32(0) } else { fbBuilder.createUInt64Vector(caseValues) }
                CHIRFormat_MultiBranch.createMultiBranch(fbBuilder, base, caseValuesVec)
            case e: NumericCastBase =>
                exprKind[Int64(exprId) - 1] = EnumCHIRFormat_ExpressionElemValues(CHIRFormat_ExpressionElem.ExpressionElem_NUMERICCASTBASE)
                let overflowStrategy = serializeOverflowStrategy(e._overflow)
                CHIRFormat_NumericCastBase.createNumericCastBase(fbBuilder, base, overflowStrategy)
            case e: RawArrayAllocateBase =>
                exprKind[Int64(exprId) - 1] = EnumCHIRFormat_ExpressionElemValues(CHIRFormat_ExpressionElem.ExpressionElem_RAWARRAYALLOCATEBASE)
                let elementType = getId(e.elementType)
                CHIRFormat_RawArrayAllocateBase.createRawArrayAllocateBase(fbBuilder, base, elementType)
            case e: SpawnBase =>
                exprKind[Int64(exprId) - 1] = EnumCHIRFormat_ExpressionElemValues(CHIRFormat_ExpressionElem.ExpressionElem_SPAWNBASE)
                let executeClosure: UInt32 = if (let Some(v) <- e._executeClosure) { getId(v) } else { UInt32(0) }
                CHIRFormat_SpawnBase.createSpawnBase(fbBuilder, base, executeClosure)
            case e: StoreElementByName =>
                exprKind[Int64(exprId) - 1] = EnumCHIRFormat_ExpressionElemValues(CHIRFormat_ExpressionElem.ExpressionElem_STOREELEMENTBYNAME)
                let path = Array<UInt32>(e._fieldNames.size, { i => fbBuilder.createString(e._fieldNames[i]) })
                let pathVec = if (path.size == 0) { UInt32(0) } else { fbBuilder.createVectorOfTables(path) }
                CHIRFormat_StoreElementByName.createStoreElementByName(fbBuilder, base, pathVec)
            case e: StoreElementRef =>
                exprKind[Int64(exprId) - 1] = EnumCHIRFormat_ExpressionElemValues(CHIRFormat_ExpressionElem.ExpressionElem_STOREELEMENTREF)
                let path = Array<UInt64>(e._path.size, { i => e._path[i] })
                let pathVec = if (path.size == 0) { UInt32(0) } else { fbBuilder.createUInt64Vector(path) }
                CHIRFormat_StoreElementRef.createStoreElementRef(fbBuilder, base, pathVec)
            case e: UnaryExpressionBase =>
                exprKind[Int64(exprId) - 1] = EnumCHIRFormat_ExpressionElemValues(CHIRFormat_ExpressionElem.ExpressionElem_UNARYEXPRESSIONBASE)
                let overflowStrategy = serializeOverflowStrategy(e._overflow)
                CHIRFormat_UnaryExpressionBase.createUnaryExpressionBase(fbBuilder, base, overflowStrategy)
            case _ =>
                exprKind[Int64(exprId) - 1] = EnumCHIRFormat_ExpressionElemValues(CHIRFormat_ExpressionElem.ExpressionElem_EXPRESSION)
                base
        }
    }

    private func getNonAbstractMethods(allMethods: ArrayList<Function>, isInterface: Bool): Array<UInt32> {
        // Schema does not split abstract vs imported methods; emit all method ids.
        return Array<UInt32>(allMethods.size, { i => getId(allMethods[i]) })
    }
    private func serializeMemberVarInfo(obj: MemberVar): UInt32 {
        let name = fbBuilder.createString(obj.name)
        let rawMangledName = fbBuilder.createString(obj._rawMangledName)
        let typeId = getId(obj.ty)
        // MemberVar.attributes are read through the protected property surface.
        let attributes: UInt64 = obj._attributes.getRawAttrs()
        let loc: UInt32 = if (obj.location.isValid()) {
            serializeDebugLocation(obj.location)
        } else {
            UInt32(0)
        }
        let annoInfo = serializeAnnoInfo(obj._annoInfo)
        let initializerFunc: UInt32 = if (let Some(v) <- obj._initializerFunc) {
            getId(v)
        } else {
            UInt32(0)
        }
        let outerDef = getId(obj.outerDef)
        return CHIRFormat_MemberVarInfo.createMemberVarInfo(
            fbBuilder, name, rawMangledName, typeId, attributes, loc, annoInfo, initializerFunc, outerDef
        )
    }

    private func serializeCustomTypeDef(obj: CustomTypeDef): UInt32 {
        let base = serializeBase(obj)
        let kind = serializeCustomDefKind(obj._kind)
        let customTypeDefID = getId(obj)
        let srcCodeIdentifier = fbBuilder.createString(obj._srcCodeName)
        let identifier = fbBuilder.createString(obj._identifier)
        let packageName = fbBuilder.createString(obj._packageName)
        let typeId: UInt32 = if (let Some(t) <- obj._type) { getId(t) } else { UInt32(0) }
        let genericDecl: UInt32 = if (let Some(v) <- obj.genericDecl) { getId(v) } else { UInt32(0) }
        let methods = getNonAbstractMethods(obj._methods, obj.isInterface())
        let methodsVec = if (methods.isEmpty()) { UInt32(0) } else { fbBuilder.createUInt32Vector(methods) }
        let instanceMemberVars = Array<UInt32>(obj.instanceVars.size, { i => serializeMemberVarInfo(obj.instanceVars[i]) })
        let instanceMemberVarsVec = if (instanceMemberVars.isEmpty()) { UInt32(0) } else { fbBuilder.createVectorOfTables(instanceMemberVars) }
        let staticMemberVars = Array<UInt32>(obj.staticVars.size, { i => getId(obj.staticVars[i]) })
        let staticMemberVarsVec = if (staticMemberVars.isEmpty()) { UInt32(0) } else { fbBuilder.createUInt32Vector(staticMemberVars) }
        let annoInfo: UInt32 = serializeAnnoInfo(obj._annoInfo)
        let vtableVec: UInt32 = 0
        let varInitializationFunc: UInt32 = if (let Some(v) <- obj._instanceVarInitFunc) { getId(v) } else { UInt32(0) }
        let implementedInterfaces = Array<UInt32>(obj.implementedInterfaceTypes.size, { i => getId(obj.implementedInterfaceTypes[i]) })
        let implementedInterfacesVec = if (implementedInterfaces.isEmpty()) { UInt32(0) } else { fbBuilder.createUInt32Vector(implementedInterfaces) }
        return CHIRFormat_CustomTypeDef.createCustomTypeDef(
            fbBuilder, base, kind, customTypeDefID, srcCodeIdentifier, identifier, packageName, typeId, genericDecl,
            methodsVec, implementedInterfacesVec, instanceMemberVarsVec, staticMemberVarsVec, annoInfo, vtableVec,
            varInitializationFunc
        )
    }

    private func serializeCustomDefKind(kind: CustomDefKind): CHIRFormat_CustomDefKind {
        return match (kind) {
            case CustomDefKind.ClassLike => CHIRFormat_CustomDefKind.CustomDefKind_CLASS
            case CustomDefKind.Enum => CHIRFormat_CustomDefKind.CustomDefKind_ENUM
            case CustomDefKind.Extend => CHIRFormat_CustomDefKind.CustomDefKind_EXTEND
            case CustomDefKind.Struct => CHIRFormat_CustomDefKind.CustomDefKind_STRUCT
        }
    }

    private func serializeEnumCtorInfo(ctor: EnumCtorInfo): UInt32 {
        // Schema: identifier is source name; mangledName is globally unique (mangled / identifier).
        let identifier = fbBuilder.createString(ctor.srcCodeName)
        let mangledName = fbBuilder.createString(ctor.identifier)
        let funcType = getId(ctor.funcType)
        let annoInfo = serializeAnnoInfo(ctor._annoInfo)
        return CHIRFormat_EnumCtorInfo.createEnumCtorInfo(fbBuilder, identifier, mangledName, funcType, annoInfo)
    }

    // Dispatch CustomTypeDef
    private func dispatchCustomTypeDef(obj: CustomTypeDef): UInt32 {
        let base = serializeCustomTypeDef(obj)
        let defId = getId(obj)

        return match (obj) {
            case d: StructDef =>
                defKind[Int64(defId) - 1] = EnumCHIRFormat_CustomTypeDefElemValues(CHIRFormat_CustomTypeDefElem.CustomTypeDefElem_STRUCTDEF)
                let isCStruct: Bool = d.isCStruct
                CHIRFormat_StructDef.createStructDef(fbBuilder, base, isCStruct)
            case d: EnumDef =>
                defKind[Int64(defId) - 1] = EnumCHIRFormat_CustomTypeDefElemValues(CHIRFormat_CustomTypeDefElem.CustomTypeDefElem_ENUMDEF)
                let ctors = ArrayList<UInt32>()
                for (ctor in d.constructors) {
                    ctors.add(serializeEnumCtorInfo(ctor))
                }
                let ctorsArray = Array<UInt32>(ctors.size, { i => ctors[i] })
                let ctorsVec = if (ctors.isEmpty()) { UInt32(0) } else { fbBuilder.createVectorOfTables(ctorsArray) }
                let isExhaustive = d.isExhaustive
                CHIRFormat_EnumDef.createEnumDef(fbBuilder, base, ctorsVec, !isExhaustive)
            case d: ClassLikeDef =>
                defKind[Int64(defId) - 1] = EnumCHIRFormat_CustomTypeDefElemValues(CHIRFormat_CustomTypeDefElem.CustomTypeDefElem_CLASSDEF)
                let superClass: UInt32 = if (d.superClass.isSome()) { getId(d.superClass.getOrThrow()) } else { UInt32(0) }
                let annotationTargetsVec: UInt32 = if (let Some(targets) <- d._annotationTargets) {
                    let ids = getValueIdList(targets)
                    if (ids.size == 0) { UInt32(0) } else { fbBuilder.createUInt32Vector(ids) }
                } else {
                    UInt32(0)
                }
                CHIRFormat_ClassDef.createClassDef(fbBuilder, base, d.isClass(), d.isAnnotation, annotationTargetsVec, superClass)
            case d: ExtendDef =>
                defKind[Int64(defId) - 1] = EnumCHIRFormat_CustomTypeDefElemValues(CHIRFormat_CustomTypeDefElem.CustomTypeDefElem_EXTENDDEF)
                let extendedType: UInt32 = getId(d.extendedType)
                let genericParams = getTypeIdList(d._genericTypeParams)
                let genericParamsVec = if (genericParams.isEmpty()) { UInt32(0) } else { fbBuilder.createUInt32Vector(genericParams) }
                CHIRFormat_ExtendDef.createExtendDef(fbBuilder, base, extendedType, genericParamsVec)
            case _ => throw CHIRException("Invalid custom type definition.")
        }
    }

    // Dispatch: drain queues until all types, values, expressions, and defs are serialized.
    func dispatch(): Unit {
        while (!valueQueue.isEmpty() || !exprQueue.isEmpty() || !defQueue.isEmpty() || !typeQueue.isEmpty()) {
            while (let Some(ty) <- typeQueue.remove()) {
                let typeId = getId(ty)
                allType[Int64(typeId) - 1] = dispatchType(ty)
            }
            while (let Some(value) <- valueQueue.remove()) {
                let valueId = getId(value)
                allValue[Int64(valueId) - 1] = dispatchValue(value)
            }
            while (let Some(expr) <- exprQueue.remove()) {
                let exprId = getId(expr)
                allExpression[Int64(exprId) - 1] = dispatchExpression(expr)
            }
            while (let Some(def) <- defQueue.remove()) {
                let defId = getId(def)
                allCustomTypeDef[Int64(defId) - 1] = dispatchCustomTypeDef(def)
            }
        }
    }

    // Finish FlatBuffers: pack side vectors and CHIRPackage root.
    func convertToMemoryData(): (CPointer<UInt8>, Int64) {
        let name = fbBuilder.createString(pkg.name)
        let path = fbBuilder.createString("")

        // Build types byte + table vectors.
        // Guard: typeKind length must match allType length.
        if (typeKind.size != allType.size) {
            throw Exception("Type-kind count '${typeKind.size}' does not match type count '${allType.size}'.")
        }
        // Guard: every type slot must be non-zero (fully serialized).
        for (i in 0..allType.size) {
            if (allType[i] == UInt32(0)) {
                throw Exception("Invalid type slot '${i}': expected a nonzero serialized table offset, got 0.")
            }
        }
        let typesTypeArray = Array<UInt8>(typeKind.size, { i => typeKind[i] })
        let typesTypeVec = if (typesTypeArray.isEmpty()) { UInt32(0) } else { fbBuilder.createByteVector(typesTypeArray) }
        let typesArray = Array<UInt32>(allType.size, { i => allType[i] })
        let typesVec = if (typesArray.isEmpty()) { UInt32(0) } else { fbBuilder.createVectorOfTables(typesArray) }

        // Build values byte + table vectors.
        // Guard: valueKind length must match allValue length.
        if (valueKind.size != allValue.size) {
            throw Exception("Value-kind count '${valueKind.size}' does not match value count '${allValue.size}'.")
        }
        for (i in 0..valueKind.size) {
            if (valueKind[i] == UInt8(0)) {
                throw Exception("Invalid value kind at slot '${i}': expected a nonzero value, got 0.")
            }
        }
        // Guard: every value slot must be non-zero (fully serialized).
        for (i in 0..allValue.size) {
            if (allValue[i] == UInt32(0)) {
                throw Exception("Invalid value slot '${i}': expected a nonzero serialized table offset, got 0.")
            }
        }
        let valuesTypeArray = Array<UInt8>(valueKind.size, { i => valueKind[i] })
        let valuesTypeVec = if (valuesTypeArray.isEmpty()) { UInt32(0) } else { fbBuilder.createByteVector(valuesTypeArray) }
        let valuesArray = Array<UInt32>(allValue.size, { i => allValue[i] })
        let valuesVec = if (valuesArray.isEmpty()) { UInt32(0) } else { fbBuilder.createVectorOfTables(valuesArray) }

        // Build expressions byte + table vectors.
        // Guard: exprKind length must match allExpression length.
        if (exprKind.size != allExpression.size) {
            throw Exception("Expression-kind count '${exprKind.size}' does not match expression count '${allExpression.size}'.")
        }
        // Guard: every expression slot must be non-zero (fully serialized).
        for (i in 0..allExpression.size) {
            if (allExpression[i] == UInt32(0)) {
                throw Exception("Invalid expression slot '${i}': expected a nonzero serialized table offset, got 0.")
            }
        }
        let exprsTypeArray = Array<UInt8>(exprKind.size, { i => exprKind[i] })
        let exprsTypeVec = if (exprsTypeArray.isEmpty()) { UInt32(0) } else { fbBuilder.createByteVector(exprsTypeArray) }
        let exprsArray = Array<UInt32>(allExpression.size, { i => allExpression[i] })
        let exprsVec = if (exprsArray.isEmpty()) { UInt32(0) } else { fbBuilder.createVectorOfTables(exprsArray) }

        // Build custom type defs byte + table vectors.
        // Guard: defKind length must match allCustomTypeDef length.
        if (defKind.size != allCustomTypeDef.size) {
            throw Exception("Definition-kind count '${defKind.size}' does not match definition count '${allCustomTypeDef.size}'.")
        }
        // Guard: every def slot must be non-zero (fully serialized).
        for (i in 0..allCustomTypeDef.size) {
            if (allCustomTypeDef[i] == UInt32(0)) {
                throw Exception("Invalid custom type definition slot '${i}': expected a nonzero serialized table offset, got 0.")
            }
        }
        let defsTypeArray = Array<UInt8>(defKind.size, { i => defKind[i] })
        let defsTypeVec = if (defsTypeArray.isEmpty()) { UInt32(0) } else { fbBuilder.createByteVector(defsTypeArray) }
        let defsArray = Array<UInt32>(allCustomTypeDef.size, { i => allCustomTypeDef[i] })
        let defsVec = if (defsArray.isEmpty()) { UInt32(0) } else { fbBuilder.createVectorOfTables(defsArray) }

        // Create CHIRPackage root table.
        let packageInitFunc: UInt32 = if (let Some(v) <- pkg._packageInitFunc) { getId(v) } else { UInt32(0) }
        let packageLiteralInitFunc: UInt32 = if (let Some(v) <- pkg._packageLiteralInitFunc) { getId(v) } else { UInt32(0) }
        let rootTable = CHIRFormat_CHIRPackage.createCHIRPackage(
            fbBuilder,
            name,
            path,
            serializePackageAccessLevel(pkg.accessLevel),
            typesTypeVec,
            typesVec,
            valuesTypeVec,
            valuesVec,
            exprsTypeVec,
            exprsVec,
            defsTypeVec,
            defsVec,
            packageInitFunc,
            CHIRFormat_Phase.Phase_RAW,
            packageLiteralInitFunc
        )

        fbBuilder.finishWithFileIdentifier(rootTable, "CHIR".toArray())
        let data = unsafe { acquireArrayRawData<UInt8>(fbBuilder.finishedBytes()) }
        return (data.pointer, data.array.size)
    }
}
