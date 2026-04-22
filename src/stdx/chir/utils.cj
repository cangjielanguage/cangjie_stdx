/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.chir

import std.collection.*

internal func updateLocalVarIdAndHashCode(v: LocalVar): Unit {
    if (v._identifier.isEmpty()) {
        let id = LOCAL_VAR_PREFIX + v.topLevelFunc.generateLocalId().toString()
        v._identifier = id
        v._hashCode = v.calculateHashCode()
    }
}

internal func getFieldOfType(baseTy: Type, path: ArrayList<Int64>): Type {
    var resType = baseTy
    for (i in path) {
        resType = getFieldOfTypeImpl(resType, i)
    }
    return resType
}

internal func isOptionLike(def: EnumDef): Bool {
    if (!def.isExhaustive) {
        return false
    }
    let ctors = def.constructors
    if (ctors.size != 2) {
        return false
    }
    // `enum EA { A(xxx) | B }` or `enum EA { A | B(xxx) }`
    return ctors[0].funcType.paramTypes.size + ctors[1].funcType.paramTypes.size == 1
}

internal func getEnumSelectorType(def: EnumDef): TypeKind {
    if (isOptionLike(def)) {
        return TypeKind.`Bool`
    }
    return TypeKind.`UInt32`
}

private func getFieldOfTypeImpl(baseTy: Type, index: Int64): Type {
    if (baseTy.isRefType()) {
        return getFieldOfTypeImpl(baseTy.stripAllRefs(), index)
    } else if (let Some(tt) <- (baseTy as TupleType)) {
        return tt.elementTypes[index]
    } else if (let Some(et) <- (baseTy as EnumType)) {
        assert(index == 0, "Enum type can only have one element")
        if (getEnumSelectorType(et.enumDef) == TypeKind.`Bool`) {
            return BoolType.get()
        }
        return IntType.getUInt32()
    } else if (let Some(ct) <- (baseTy as CustomType)) {
        // only struct type and class type have member variables
        let memberVarTypes = ct.getInstantiatedMemberVarTypes()
        assert(memberVarTypes.size > index, "Member variable size mismatch, ${memberVarTypes.size} vs ${index}")
        return memberVarTypes[index]
    } else if (let Some(rat) <- (baseTy as RawArrayType)) {
        return rat.elementType
    }
    throw CHIRException("Invalid type: " + baseTy.toString())
}

internal func getFieldOfType(baseTy: Type, fieldNames: ArrayList<String>): Type {
    var resType = baseTy
    for (name in fieldNames) {
        resType = getFieldOfTypeImpl(resType, name)
    }
    return resType
}

private func getFieldOfTypeImpl(baseTy: Type, name: String): Type {
    if (baseTy.isRefType()) {
        return getFieldOfTypeImpl(baseTy.stripAllRefs(), name)
    } else if (let Some(ct) <- (baseTy as CustomType)) {
        // only struct type and class type have member variables
        return ct.getMemberVarInstantiatedType(name)
    }
    throw CHIRException("Invalid type: " + baseTy.toString())
}

internal func getInstMapFromCurDefAndExDefToCurType(curType: CustomType): HashMap<GenericType, Type> {
    let (res, instMap) = curType.def.ty.calculateGeneric2InstTypeMap(curType)
    assert(res, "Failed to calculate generic 2 inst type map")
    for (exDef in curType.def.extends) {
        // maybe we can meet `extend<T> A<B<T>> {}`, and `curType` is A<Int32>, then ignore this def,
        // so not need to check `res`
        let (_, tempTable) = exDef.extendedType.calculateGeneric2InstTypeMap(curType)
        instMap.add(all: tempTable)
    }
    return instMap
}

internal func getInstType(genericType: Type, f: Value, funcCallCtx: FuncCallContext): Type {
    if (!genericType.isGenericRelated()) {
        return genericType
    }
    let genericTypeParams: Array<GenericType>
    if (let Some(lv) <- (f as LocalVar)) {
        let e = lv.expr as Lambda
        genericTypeParams = e.getOrThrow().genericTypeParams
    } else if (let Some(tempFunc) <- (f as Function)) {
        genericTypeParams = tempFunc.genericTypeParams
    } else {
        // maybe parameter or something else
        return genericType
    }

    if (genericTypeParams.size != funcCallCtx.instTypeArgs.size) {
        throw CHIRException("getInstType: genericTypeParams.size != instArgs.size")
    }
    var replaceTable: HashMap<GenericType, Type> = HashMap<GenericType, Type>()
    let instParentType = getInstParentCustomTypeOfCallee(f, funcCallCtx)
    if (let Some(ct) <- (instParentType as CustomType)) {
        replaceTable = getInstMapFromCurDefAndExDefToCurType(ct)
    }
    for (i in 0..genericTypeParams.size) {
        let genericTypeParam = genericTypeParams[i]
        let instType = funcCallCtx.instTypeArgs[i]
        replaceTable.add(genericTypeParam, instType)
    }
    return getInstType(genericType, replaceTable)
}

internal func getInstType(genericType: Type, replaceTable: HashMap<GenericType, Type>): Type {
    if (!genericType.isGenericRelated()) {
        return genericType
    }
    if (genericType.isGenericType()) {
        let res = replaceTable.get((genericType as GenericType).getOrThrow())
        if (let Some(r) <- res) {
            return r
        }
        return genericType
    }
    var newTypeArgs: ArrayList<Type> = ArrayList<Type>()
    for (arg in genericType.typeArgs) {
        newTypeArgs.add(getInstType(arg, replaceTable))
    }
    return createNewTypeWithArgs(genericType, newTypeArgs)
}

internal func createNewTypeWithArgs(oldType: Type, newTypeArgs: ArrayList<Type>): Type {
    if (newTypeArgs.isEmpty()) {
        return oldType
    }
    match (oldType._kind) {
        case TypeKind.Tuple =>
            return TupleType.get(newTypeArgs.toArray())
        case TypeKind.Struct =>
            let def = (oldType as StructType).getOrThrow().structDef
            return StructType.get(def, newTypeArgs.toArray())
        case TypeKind.ClassLike =>
            let def = (oldType as ClassLikeType).getOrThrow().classLikeDef
            return ClassLikeType.get(def, newTypeArgs.toArray())
        case TypeKind.Enum =>
            let def = (oldType as EnumType).getOrThrow().enumDef
            return EnumType.get(def, newTypeArgs.toArray())
        case TypeKind.Func =>
            let paramTypes = newTypeArgs[0..(newTypeArgs.size - 1)]
            let returnType = newTypeArgs.last.getOrThrow()
            let varArg = (oldType as FuncType).getOrThrow().hasVarArg
            let cFunc = (oldType as FuncType).getOrThrow().isCFunc
            return FuncType.get(paramTypes.toArray(), returnType, varArg: varArg, cFunc: cFunc)
        case TypeKind.Ref =>
            return RefType.get(newTypeArgs.first.getOrThrow())
        case TypeKind.Box =>
            return BoxType.get(newTypeArgs.first.getOrThrow())
        case TypeKind.CPointer =>
            return CPointerType.get(newTypeArgs.first.getOrThrow())
        case TypeKind.RawArray =>
            let elementType = newTypeArgs.first.getOrThrow()
            let dims = (oldType as RawArrayType).getOrThrow().dims
            return RawArrayType.get(elementType, dims)
        case TypeKind.`VArray` =>
            let elementType = newTypeArgs.first.getOrThrow()
            let size = (oldType as VArrayType).getOrThrow().size
            return VArrayType.get(elementType, size)
        case _ =>
            throw CHIRException(oldType.toString() + " doesn't have type args")
    }
}

internal func getAllInstantiatedParentTypes(cur: ClassLikeType, parentTypes: ArrayList<ClassLikeType>, visited: ArrayList<(Type, Type)>): Unit {
    if (parentTypes.contains(cur)) {
        return
    }
    parentTypes.add(cur)
    for (p in cur.getImplementedInterfaceTypes(visited: visited)) {
        getAllInstantiatedParentTypes(p, parentTypes, visited)
    }
    if (cur.hasSuperClassType()) {
        getAllInstantiatedParentTypes(cur.getSuperClassType(), parentTypes, visited)
    }
}

internal func assert(condition: Bool, message: String): Unit {
    if (!condition) {
        throw CHIRException(message)
    }
}

internal func calculateFunctionInstType(f: Function, instantiateTypes: ArrayList<Type>): Type {
    var replaceTable = HashMap<GenericType, Type>()
    var index: Int64 = 0
    if (let Some(parentDef) <- f.declaredParent) {
        let tmpTypeArgs = parentDef.ty.typeArgs
        while (index < tmpTypeArgs.size) {
            let ty = tmpTypeArgs[index]
            if (ty.isGenericRelated()) {
                assert(ty.calculateGeneric2InstTypeMapImpl(instantiateTypes[index], replaceTable), "Failed to calculate generic type to inst type")
            }
            index++
        }
    }
    let funcGenericTypeParams = f.genericTypeParams
    for (i in 0..funcGenericTypeParams.size) {
        let ty = funcGenericTypeParams[i]
        replaceTable.add(ty, instantiateTypes[i + index])
    }
    return getInstType(f.ty, replaceTable)
}

internal func getInstParentCustomTypeOfCallee(v: Value, funcCallCtx: FuncCallContext): ?Type {
    if (!v.isFunction()) {
        return None  // call a lambda
    }
    let f = (v as Function).getOrThrow()
    if (!f.isMemberMethod()) {
        return None  // global function
    }
    var parentDef = f.declaredParent.getOrThrow()
    if (!funcCallCtx._objType.isSome()) {
        return parentDef.ty  // call a member method with implicit `this`
    }
    if (!parentDef.ty.isBuiltinType() && parentDef.isExtend()) {
        parentDef = (parentDef.ty as CustomType).getOrThrow().def
    }
    let derefThisType = funcCallCtx._objType.getOrThrow().stripAllRefs()
    let typeAndDefIsEquivalent = { ty: CustomType, def: CustomTypeDef =>
        /**
         * 1. def equals def, maybe `def` is generic, `type` is instantiated
         * 2. type equals type, maybe `def` is instantiated
         */
        return ty.def == def || ty == def.ty
    }
    if (derefThisType.isCustomType() && typeAndDefIsEquivalent((derefThisType as CustomType).getOrThrow(), parentDef)) {
        /**
         * 1. a function declared in generic custom type def, is called by instantiated custom type
         *  class A<T> {
         *      func foo() {}
         *  }
         *  A<Bool>.foo()  // `thisType` is A<Bool>, `foo`'s parent def is A<T>
         *
         * 2. a function declared in instantiated custom type def, is called by instantiated custom type
         *  class A<T> {
         *      func foo() {}
         *  }
         *  class A_Bool {  // A<T> is instantiated by Bool
         *      func foo_Bool() {}
         *  }
         *  A<Bool>.foo_Bool()  // `thisType` is A<Bool>, `foo`'s parent def is A_Bool
         */
        return derefThisType
    } else if (derefThisType.isBuiltinType() && derefThisType._kind == parentDef.ty._kind) {
        // we should compare type pointer, but CPointer<T> is generic type, so we have to compare type kind
        return derefThisType
    } else {
        /**
         * a function declared in parent def, but called by sub type, then we need to compute instantiated parent type
         * 1. a function declared in generic custom type def, is called by instantiated sub custom type
         *  interface A<T> {
         *      func foo() {}
         *  }
         *  class B<T> <: A<T> {}
         *  B<Bool>.foo()  // `thisType` is B<Bool>, `foo`'s parent def is A<T>, then parent type is A<Bool>
         *
         * 2. a function declared in instantiated custom type def, is called by instantiated sub custom type
         *  interface A<T> {
         *      func foo() {}
         *  }
         *  class B<T> <: A<T> {}
         *  interface A_Bool {
         *      func foo_Bool() {}
         *  }
         *  class B_Bool <: A_Bool {}
         *  B<Bool>.foo_Bool()  // `thisType` is B<Bool>, `foo`'s parent def is A_Bool, then parent type is A<Bool>
         *
         * 3. sub class inherit the same parent class more than once with different instantiated type
         *  interface A<T> {
         *      func foo(a: T) {}
         *  }
         *  class B <: A<Bool> & A<Int64> {}
         *  B().foo(1)  // `thisType` is B<Bool>, `foo`'s parent def is A<T>, then parent type is A<Int64>
         */
        let allParentTypes = if (derefThisType.isBuiltinType()) {
            (derefThisType as BuiltinType).getOrThrow().getSuperTypesRecusively()
        } else {
            (derefThisType as CustomType).getOrThrow().getSuperTypesRecusively()
        }
        var matchedTypes = ArrayList<ClassLikeType>()
        for (parentType in allParentTypes) {
            if (typeAndDefIsEquivalent(parentType, parentDef)) {
                matchedTypes.add(parentType)
            }
        }
        assert(!matchedTypes.isEmpty(), "No matched parent type found")
        return getInstParentType(matchedTypes.toArray(), f, funcCallCtx.args)
    }
}

internal func getInstParentType(candidate: Array<ClassLikeType>, f: Function, args: Array<Value>): ClassLikeType {
    if (candidate.size == 1) {
        return candidate.first.getOrThrow()
    }
    let offset = if (f.isStatic()) { 0 } else { 1 }
    let argTypes = ArrayList<Type>(args.size - offset, { i => args[i + offset].ty })
    let paramTypes = ArrayList<Type>.of(f.funcType.paramTypes)
    if (f.isStatic()) {
        paramTypes.remove(at: 0)
    }
    assert(argTypes.size == paramTypes.size, "Argument type size mismatch, ${argTypes.size} vs ${paramTypes.size}")
    for (p in candidate) {
        let (res, instMap) = p.def.ty.calculateGeneric2InstTypeMap(p)
        assert(res, "Failed to calculate generic 2 inst type map")
        var argTypeMatched = true
        for (i in 0..paramTypes.size) {
            let instType = getInstType(paramTypes[i], instMap)
            if (!paramTypeIsEquivalent(instType, argTypes[i])) {
                argTypeMatched = false
                break
            }
        }
        if (argTypeMatched) {
            return p
        }
    }
    throw CHIRException("No matched parent type found")
}

internal func paramTypeIsEquivalent(paramType: Type, argType: Type): Bool {
    if (paramType == argType) {
        return true
    }
    // `NothingType` is any type's sub type, so it's equivalent to any type
    if (argType.isNothingType()) {
        return true
    }
    if (paramType.isBoxRefTypeOf(argType) || argType.isBoxRefTypeOf(paramType)) {
        return true
    }
    return meetClosureType(argType.stripAllRefs(), paramType.stripAllRefs())
}

internal func meetClosureType(subType: Type, parentType: Type): Bool {
    return subType.isClosureInstBaseType() && parentType.isClosureGenericBaseType() &&
        (subType as ClassLikeType).getOrThrow().classLikeDef.superClass.getOrThrow() == parentType
}