/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.chir

import std.collection.*

/**
 * Public enum definition of InsertPosition.
 */
public enum InsertPosition {
    | AtEnd(Block)
    | AtStart(Block)
    | Before(Expression)
    | After(Expression)
    | ...
}

/**
 * Public definition of CHIRBuilder.
 */
public class CHIRBuilder {
    private var _insertPoint: Int64
    private var _parent: Block

    /**
     * Performs the public behavior of `func`.
     * @param parent The `parent` parameter.
     */
    public init(parent: Block) {
        this._parent = parent
        _insertPoint = parent._exprs.size
    }

    /**
     * Performs the public behavior of `func`.
     * @param position The `position` parameter.
     */
    public init(position: InsertPosition) {
        match (position) {
            case AtEnd(block) =>
                this._parent = block
                this._insertPoint = block._exprs.size
            case AtStart(block) =>
                this._parent = block
                this._insertPoint = 0
            case Before(expr) =>
                this._parent = expr.owner
                let index = expr.owner._exprs.indexOf(expr)
                if (index == -1) {
                    throw CHIRException("CHIRBuilder: ${expr.toString()} not found in block: ${expr.owner.toString()}")
                }
                this._insertPoint = index
            case After(expr) =>
                this._parent = expr.owner
                let index = expr.owner._exprs.indexOf(expr)
                if (index == -1) {
                    throw CHIRException("CHIRBuilder: ${expr.toString()} not found in block: ${expr.owner.toString()}")
                }
                this._insertPoint = index + 1
            case _ =>
                throw CHIRException("CHIRBuilder: Unknown position")
        }
    }

    /**
     * Performs the public behavior of `createAllocate`.
     * @param ty The `ty` parameter.
     * @return The `Allocate` result.
     */
    public func createAllocate(ty: Type): Allocate {
        let expr = Allocate.create(ty)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createApply`.
     * @param callee The `callee` parameter.
     * @param funcCallCtx The `funcCallCtx` parameter.
     * @return The `Apply` result.
     */
    public func createApply(callee: Value, funcCallCtx: FuncCallContext): Apply {
        let expr = Apply.create(callee, funcCallCtx)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createBinaryAdd`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @param overflow The `overflow` parameter.
     * @return The `BinaryExpression` result.
     */
    public func createBinaryAdd(leftOp: Value, rightOp: Value, overflow: OverflowStrategy): BinaryExpression {
        let expr = BinaryExpression.create(BinaryExprKind.Add, leftOp, rightOp)
        expr.overflow = overflow
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createBinaryAnd`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @return The `BinaryExpression` result.
     */
    public func createBinaryAnd(leftOp: Value, rightOp: Value): BinaryExpression {
        let expr = BinaryExpression.create(BinaryExprKind.And, leftOp, rightOp)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createBinaryBitAnd`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @return The `BinaryExpression` result.
     */
    public func createBinaryBitAnd(leftOp: Value, rightOp: Value): BinaryExpression {
        let expr = BinaryExpression.create(BinaryExprKind.BitAnd, leftOp, rightOp)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createBinaryBitOr`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @return The `BinaryExpression` result.
     */
    public func createBinaryBitOr(leftOp: Value, rightOp: Value): BinaryExpression {
        let expr = BinaryExpression.create(BinaryExprKind.BitOr, leftOp, rightOp)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createBinaryBitXor`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @return The `BinaryExpression` result.
     */
    public func createBinaryBitXor(leftOp: Value, rightOp: Value): BinaryExpression {
        let expr = BinaryExpression.create(BinaryExprKind.BitXor, leftOp, rightOp)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createBinaryDiv`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @param overflow The `overflow` parameter.
     * @return The `BinaryExpression` result.
     */
    public func createBinaryDiv(leftOp: Value, rightOp: Value, overflow: OverflowStrategy): BinaryExpression {
        let expr = BinaryExpression.create(BinaryExprKind.Div, leftOp, rightOp)
        expr.overflow = overflow
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createBinaryEqual`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @return The `BinaryExpression` result.
     */
    public func createBinaryEqual(leftOp: Value, rightOp: Value): BinaryExpression {
        let expr = BinaryExpression.create(BinaryExprKind.Equal, leftOp, rightOp)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createBinaryExp`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @param overflow The `overflow` parameter.
     * @return The `BinaryExpression` result.
     */
    public func createBinaryExp(leftOp: Value, rightOp: Value, overflow: OverflowStrategy): BinaryExpression {
        let expr = BinaryExpression.create(BinaryExprKind.Exp, leftOp, rightOp)
        expr.overflow = overflow
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createBinaryGreaterThan`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @return The `BinaryExpression` result.
     */
    public func createBinaryGreaterThan(leftOp: Value, rightOp: Value): BinaryExpression {
        let expr = BinaryExpression.create(BinaryExprKind.GT, leftOp, rightOp)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createBinaryGreaterThanOrEqual`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @return The `BinaryExpression` result.
     */
    public func createBinaryGreaterThanOrEqual(leftOp: Value, rightOp: Value): BinaryExpression {
        let expr = BinaryExpression.create(BinaryExprKind.GE, leftOp, rightOp)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createBinaryLShift`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @param overflow The `overflow` parameter.
     * @return The `BinaryExpression` result.
     */
    public func createBinaryLShift(leftOp: Value, rightOp: Value, overflow: OverflowStrategy): BinaryExpression {
        let expr = BinaryExpression.create(BinaryExprKind.LShift, leftOp, rightOp)
        expr.overflow = overflow
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createBinaryLessThan`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @return The `BinaryExpression` result.
     */
    public func createBinaryLessThan(leftOp: Value, rightOp: Value): BinaryExpression {
        let expr = BinaryExpression.create(BinaryExprKind.LT, leftOp, rightOp)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createBinaryLessThanOrEqual`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @return The `BinaryExpression` result.
     */
    public func createBinaryLessThanOrEqual(leftOp: Value, rightOp: Value): BinaryExpression {
        let expr = BinaryExpression.create(BinaryExprKind.LE, leftOp, rightOp)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createBinaryMod`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @param overflow The `overflow` parameter.
     * @return The `BinaryExpression` result.
     */
    public func createBinaryMod(leftOp: Value, rightOp: Value, overflow: OverflowStrategy): BinaryExpression {
        let expr = BinaryExpression.create(BinaryExprKind.Mod, leftOp, rightOp)
        expr.overflow = overflow
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createBinaryMul`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @param overflow The `overflow` parameter.
     * @return The `BinaryExpression` result.
     */
    public func createBinaryMul(leftOp: Value, rightOp: Value, overflow: OverflowStrategy): BinaryExpression {
        let expr = BinaryExpression.create(BinaryExprKind.Mul, leftOp, rightOp)
        expr.overflow = overflow
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createBinaryNotEqual`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @return The `BinaryExpression` result.
     */
    public func createBinaryNotEqual(leftOp: Value, rightOp: Value): BinaryExpression {
        let expr = BinaryExpression.create(BinaryExprKind.NotEqual, leftOp, rightOp)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createBinaryOr`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @return The `BinaryExpression` result.
     */
    public func createBinaryOr(leftOp: Value, rightOp: Value): BinaryExpression {
        let expr = BinaryExpression.create(BinaryExprKind.Or, leftOp, rightOp)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createBinaryRShift`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @param overflow The `overflow` parameter.
     * @return The `BinaryExpression` result.
     */
    public func createBinaryRShift(leftOp: Value, rightOp: Value, overflow: OverflowStrategy): BinaryExpression {
        let expr = BinaryExpression.create(BinaryExprKind.RShift, leftOp, rightOp)
        expr.overflow = overflow
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createBinarySub`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @param overflow The `overflow` parameter.
     * @return The `BinaryExpression` result.
     */
    public func createBinarySub(leftOp: Value, rightOp: Value, overflow: OverflowStrategy): BinaryExpression {
        let expr = BinaryExpression.create(BinaryExprKind.Sub, leftOp, rightOp)
        expr.overflow = overflow
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createBox`.
     * @param srcVal The `srcVal` parameter.
     * @param dstTy The `dstTy` parameter.
     * @return The `Box` result.
     */
    public func createBox(srcVal: Value, dstTy: Type): Box {
        let expr = Box.create(srcVal, dstTy)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createBranch`.
     * @param condition The `condition` parameter.
     * @param trueTarget The `trueTarget` parameter.
     * @param falseTarget The `falseTarget` parameter.
     * @return The `Branch` result.
     */
    public func createBranch(condition: Value, trueTarget: Block, falseTarget: Block): Branch {
        let expr = Branch.create(condition, trueTarget, falseTarget)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createConstant`.
     * @param val The `val` parameter.
     * @return The `Constant` result.
     */
    public func createConstant(val: LiteralValue): Constant {
        let expr = Constant.create(val)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createDebug`.
     * @param location The `location` parameter.
     * @param srcCodeName The `srcCodeName` parameter.
     * @return The `Debug` result.
     */
    public func createDebug(location: Value, srcCodeName: String): Debug {
        let expr = Debug.create(location, srcCodeName)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createExit`.
     * @return The `Exit` result.
     */
    public func createExit(): Exit {
        let expr = Exit.create()
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createField`.
     * @param val The `val` parameter.
     * @param path The `path` parameter.
     * @return The `Field` result.
     */
    public func createField(val: Value, path: ArrayList<UInt64>): Field {
        let expr = Field.create(val, path)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createFieldByName`.
     * @param val The `val` parameter.
     * @param fieldNames The `fieldNames` parameter.
     * @return The `FieldByName` result.
     */
    public func createFieldByName(val: Value, fieldNames: ArrayList<String>): FieldByName {
        let expr = FieldByName.create(val, fieldNames)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createGetElementByName`.
     * @param location The `location` parameter.
     * @param fieldNames The `fieldNames` parameter.
     * @return The `GetElementByName` result.
     */
    public func createGetElementByName(location: Value, fieldNames: ArrayList<String>): GetElementByName {
        let expr = GetElementByName.create(location, fieldNames)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createGetException`.
     * @param retTy The `retTy` parameter.
     * @return The `GetException` result.
     */
    public func createGetException(retTy: Type): GetException {
        let expr = GetException.create(retTy)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createGetInstantiateValue`.
     * @param val The `val` parameter.
     * @param instantiateTypes The `instantiateTypes` parameter.
     * @return The `GetInstantiateValue` result.
     */
    public func createGetInstantiateValue(val: Function, instantiateTypes: ArrayList<Type>): GetInstantiateValue {
        let expr = GetInstantiateValue.create(val, instantiateTypes)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createGetRTTI`.
     * @param val The `val` parameter.
     * @return The `GetRTTI` result.
     */
    public func createGetRTTI(val: Value): GetRTTI {
        let expr = GetRTTI.create(val)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createGetRTTIStatic`.
     * @param rttiType The `rttiType` parameter.
     * @return The `GetRTTIStatic` result.
     */
    public func createGetRTTIStatic(rttiType: Type): GetRTTIStatic {
        let expr = GetRTTIStatic.create(rttiType)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createGoTo`.
     * @param target The `target` parameter.
     * @return The `GoTo` result.
     */
    public func createGoTo(target: Block): GoTo {
        let expr = GoTo.create(target)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createInstanceOf`.
     * @param srcVal The `srcVal` parameter.
     * @param targetTy The `targetTy` parameter.
     * @return The `InstanceOf` result.
     */
    public func createInstanceOf(srcVal: Value, targetTy: Type): InstanceOf {
        let expr = InstanceOf.create(srcVal, targetTy)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createInvoke`.
     * @param retTy The `retTy` parameter.
     * @param callContext The `callContext` parameter.
     * @return The `Invoke` result.
     */
    public func createInvoke(retTy: Type, callContext: InvokeCallContext): Invoke {
        let expr = Invoke.create(retTy, callContext)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createLambda`.
     * @param ty The `ty` parameter.
     * @param mangledName The `mangledName` parameter.
     * @param srcName The `srcName` parameter.
     * @param genericTypeParams The `genericTypeParams` parameter.
     * @return The `Lambda` result.
     */
    public func createLambda(ty: FuncType, mangledName: String, srcName: String, genericTypeParams!: Array<GenericType> = Array<GenericType>()): Lambda {
        // 1. create lambda expression
        let expr = Lambda.create(ty, mangledName, srcName, ArrayList<GenericType>.of(genericTypeParams))
        insertAndAdvance(expr)

        // 2. init parameters
        expr.initParameters()

        // 3. init body
        expr.initBody()

        return expr
    }

    /**
     * Performs the public behavior of `createLoad`.
     * @param location The `location` parameter.
     * @return The `Load` result.
     */
    public func createLoad(location: Value): Load {
        let expr = Load.create(location)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createMultiBranch`.
     * @param condition The `condition` parameter.
     * @param defaultBlock The `defaultBlock` parameter.
     * @param targets The `targets` parameter.
     * @param caseValues The `caseValues` parameter.
     * @return The `MultiBranch` result.
     */
    public func createMultiBranch(condition: Value, defaultBlock: Block, targets: ArrayList<Block>, caseValues: ArrayList<UInt64>): MultiBranch {
        let expr = MultiBranch.create(condition, defaultBlock, targets, caseValues)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createNumericCast`.
     * @param srcVal The `srcVal` parameter.
     * @param dstTy The `dstTy` parameter.
     * @param overflow The `overflow` parameter.
     * @return The `NumericCast` result.
     */
    public func createNumericCast(srcVal: Value, dstTy: Type, overflow: OverflowStrategy): NumericCast {
        let expr = NumericCast.create(srcVal, dstTy, overflow)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createRaiseException`.
     * @param value The `value` parameter.
     * @return The `RaiseException` result.
     */
    public func createRaiseException(value: Value): RaiseException {
        let expr = RaiseException.create(value)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createRaiseException`.
     * @param value The `value` parameter.
     * @param successor The `successor` parameter.
     * @return The `RaiseException` result.
     */
    public func createRaiseException(value: Value, successor: Block): RaiseException {
        let expr = RaiseException.create(value, successor)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createRawArrayAllocate`.
     * @param elementType The `elementType` parameter.
     * @param size The `size` parameter.
     * @return The `RawArrayAllocate` result.
     */
    public func createRawArrayAllocate(elementType: Type, size: Value): RawArrayAllocate {
        let expr = RawArrayAllocate.create(elementType, size)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createRawArrayInitByValue`.
     * @param memory The `memory` parameter.
     * @param size The `size` parameter.
     * @param initVal The `initVal` parameter.
     * @return The `RawArrayInitByValue` result.
     */
    public func createRawArrayInitByValue(memory: Value, size: Value, initVal: Value): RawArrayInitByValue {
        let expr = RawArrayInitByValue.create(memory, size, initVal)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createRawArrayLiteralInit`.
     * @param memory The `memory` parameter.
     * @param elements The `elements` parameter.
     * @return The `RawArrayLiteralInit` result.
     */
    public func createRawArrayLiteralInit(memory: Value, elements: ArrayList<Value>): RawArrayLiteralInit {
        let expr = RawArrayLiteralInit.create(memory, elements)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createSpawn`.
     * @param retTy The `retTy` parameter.
     * @param val The `val` parameter.
     * @return The `Spawn` result.
     */
    public func createSpawn(retTy: Type, val: Value): Spawn {
        let expr = Spawn.create(retTy, val)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createSpawn`.
     * @param retTy The `retTy` parameter.
     * @param val The `val` parameter.
     * @param arg The `arg` parameter.
     * @return The `Spawn` result.
     */
    public func createSpawn(retTy: Type, val: Value, arg: Value): Spawn {
        let expr = Spawn.create(retTy, val, arg)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createStaticCast`.
     * @param srcVal The `srcVal` parameter.
     * @param dstTy The `dstTy` parameter.
     * @return The `StaticCast` result.
     */
    public func createStaticCast(srcVal: Value, dstTy: Type): StaticCast {
        let expr = StaticCast.create(srcVal, dstTy)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createStore`.
     * @param val The `val` parameter.
     * @param location The `location` parameter.
     * @return The `Store` result.
     */
    public func createStore(val: Value, location: Value): Store {
        let expr = Store.create(val, location)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createStoreElementByName`.
     * @param val The `val` parameter.
     * @param location The `location` parameter.
     * @param fieldNames The `fieldNames` parameter.
     * @return The `StoreElementByName` result.
     */
    public func createStoreElementByName(val: Value, location: Value, fieldNames: ArrayList<String>): StoreElementByName {
        let expr = StoreElementByName.create(val, location, fieldNames)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createTryAllocate`.
     * @param ty The `ty` parameter.
     * @param normal The `normal` parameter.
     * @param err The `err` parameter.
     * @return The `TryAllocate` result.
     */
    public func createTryAllocate(ty: Type, normal: Block, err: Block): TryAllocate {
        let expr = TryAllocate.create(ty, normal, err)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createTryApply`.
     * @param callee The `callee` parameter.
     * @param funcCallCtx The `funcCallCtx` parameter.
     * @param normal The `normal` parameter.
     * @param err The `err` parameter.
     * @return The `TryApply` result.
     */
    public func createTryApply(callee: Value, funcCallCtx: FuncCallContext, normal: Block, err: Block): TryApply {
        let expr = TryApply.create(callee, funcCallCtx, normal, err)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createTryBinaryAdd`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @param normal The `normal` parameter.
     * @param err The `err` parameter.
     * @return The `TryBinaryExpression` result.
     */
    public func createTryBinaryAdd(leftOp: Value, rightOp: Value, normal: Block, err: Block): TryBinaryExpression {
        let expr = TryBinaryExpression.create(BinaryExprKind.Add, leftOp, rightOp, normal, err)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createTryBinaryDiv`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @param overflow The `overflow` parameter.
     * @param normal The `normal` parameter.
     * @param err The `err` parameter.
     * @return The `TryBinaryExpression` result.
     */
    public func createTryBinaryDiv(leftOp: Value, rightOp: Value, overflow: OverflowStrategy, normal: Block, err: Block): TryBinaryExpression {
        let expr = TryBinaryExpression.create(BinaryExprKind.Div, leftOp, rightOp, normal, err)
        expr.overflow = overflow
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createTryBinaryExp`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @param normal The `normal` parameter.
     * @param err The `err` parameter.
     * @return The `TryBinaryExpression` result.
     */
    public func createTryBinaryExp(leftOp: Value, rightOp: Value, normal: Block, err: Block): TryBinaryExpression {
        let expr = TryBinaryExpression.create(BinaryExprKind.Exp, leftOp, rightOp, normal, err)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createTryBinaryLShift`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @param normal The `normal` parameter.
     * @param err The `err` parameter.
     * @return The `TryBinaryExpression` result.
     */
    public func createTryBinaryLShift(leftOp: Value, rightOp: Value, normal: Block, err: Block): TryBinaryExpression {
        let expr = TryBinaryExpression.create(BinaryExprKind.LShift, leftOp, rightOp, normal, err)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createTryBinaryMod`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @param normal The `normal` parameter.
     * @param err The `err` parameter.
     * @return The `TryBinaryExpression` result.
     */
    public func createTryBinaryMod(leftOp: Value, rightOp: Value, normal: Block, err: Block): TryBinaryExpression {
        let expr = TryBinaryExpression.create(BinaryExprKind.Mod, leftOp, rightOp, normal, err)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createTryBinaryMul`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @param normal The `normal` parameter.
     * @param err The `err` parameter.
     * @return The `TryBinaryExpression` result.
     */
    public func createTryBinaryMul(leftOp: Value, rightOp: Value, normal: Block, err: Block): TryBinaryExpression {
        let expr = TryBinaryExpression.create(BinaryExprKind.Mul, leftOp, rightOp, normal, err)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createTryBinaryRShift`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @param normal The `normal` parameter.
     * @param err The `err` parameter.
     * @return The `TryBinaryExpression` result.
     */
    public func createTryBinaryRShift(leftOp: Value, rightOp: Value, normal: Block, err: Block): TryBinaryExpression {
        let expr = TryBinaryExpression.create(BinaryExprKind.RShift, leftOp, rightOp, normal, err)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createTryBinarySub`.
     * @param leftOp The `leftOp` parameter.
     * @param rightOp The `rightOp` parameter.
     * @param normal The `normal` parameter.
     * @param err The `err` parameter.
     * @return The `TryBinaryExpression` result.
     */
    public func createTryBinarySub(leftOp: Value, rightOp: Value, normal: Block, err: Block): TryBinaryExpression {
        let expr = TryBinaryExpression.create(BinaryExprKind.Sub, leftOp, rightOp, normal, err)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createTryInvoke`.
     * @param retTy The `retTy` parameter.
     * @param callContext The `callContext` parameter.
     * @param normal The `normal` parameter.
     * @param err The `err` parameter.
     * @return The `TryInvoke` result.
     */
    public func createTryInvoke(retTy: Type, callContext: InvokeCallContext, normal: Block, err: Block): TryInvoke {
        let expr = TryInvoke.create(retTy, callContext, normal, err)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createTryNumericCast`.
     * @param srcVal The `srcVal` parameter.
     * @param dstTy The `dstTy` parameter.
     * @param normal The `normal` parameter.
     * @param err The `err` parameter.
     * @return The `TryNumericCast` result.
     */
    public func createTryNumericCast(srcVal: Value, dstTy: Type, normal: Block, err: Block): TryNumericCast {
        let expr = TryNumericCast.create(srcVal, dstTy, normal, err)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createTryRawArrayAllocate`.
     * @param elementType The `elementType` parameter.
     * @param size The `size` parameter.
     * @param normal The `normal` parameter.
     * @param err The `err` parameter.
     * @return The `TryRawArrayAllocate` result.
     */
    public func createTryRawArrayAllocate(elementType: Type, size: Value, normal: Block, err: Block): TryRawArrayAllocate {
        let expr = TryRawArrayAllocate.create(elementType, size, normal, err)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createTrySpawn`.
     * @param retTy The `retTy` parameter.
     * @param val The `val` parameter.
     * @param normal The `normal` parameter.
     * @param err The `err` parameter.
     * @return The `TrySpawn` result.
     */
    public func createTrySpawn(retTy: Type, val: Value, normal: Block, err: Block): TrySpawn {
        let expr = TrySpawn.create(retTy, val, normal, err)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createTrySpawn`.
     * @param retTy The `retTy` parameter.
     * @param val The `val` parameter.
     * @param arg The `arg` parameter.
     * @param normal The `normal` parameter.
     * @param err The `err` parameter.
     * @return The `TrySpawn` result.
     */
    public func createTrySpawn(retTy: Type, val: Value, arg: Value, normal: Block, err: Block): TrySpawn {
        let expr = TrySpawn.create(retTy, val, arg, normal, err)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createTryUnaryNeg`.
     * @param op The `op` parameter.
     * @param normal The `normal` parameter.
     * @param err The `err` parameter.
     * @return The `TryUnaryExpression` result.
     */
    public func createTryUnaryNeg(op: Value, normal: Block, err: Block): TryUnaryExpression {
        let expr = TryUnaryExpression.create(op, normal, err)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createTuple`.
     * @param elements The `elements` parameter.
     * @return The `Tuple` result.
     */
    public func createTuple(elements: Array<Value>): Tuple {
        let expr = Tuple.create(ArrayList<Value>.of(elements))
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createUnaryBitNot`.
     * @param op The `op` parameter.
     * @return The `UnaryExpression` result.
     */
    public func createUnaryBitNot(op: Value): UnaryExpression {
        let expr = UnaryExpression.create(UnaryExprKind.BitNot, op)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createUnaryNeg`.
     * @param op The `op` parameter.
     * @param overflow The `overflow` parameter.
     * @return The `UnaryExpression` result.
     */
    public func createUnaryNeg(op: Value, overflow: OverflowStrategy): UnaryExpression {
        let expr = UnaryExpression.create(UnaryExprKind.Neg, op)
        expr.overflow = overflow
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createUnaryNot`.
     * @param op The `op` parameter.
     * @return The `UnaryExpression` result.
     */
    public func createUnaryNot(op: Value): UnaryExpression {
        let expr = UnaryExpression.create(UnaryExprKind.Not, op)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createUnboxToRef`.
     * @param srcVal The `srcVal` parameter.
     * @param dstTy The `dstTy` parameter.
     * @return The `UnboxToRef` result.
     */
    public func createUnboxToRef(srcVal: Value, dstTy: Type): UnboxToRef {
        let expr = UnboxToRef.create(srcVal, dstTy)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createUnboxToValue`.
     * @param srcVal The `srcVal` parameter.
     * @param dstTy The `dstTy` parameter.
     * @return The `UnboxToValue` result.
     */
    public func createUnboxToValue(srcVal: Value, dstTy: Type): UnboxToValue {
        let expr = UnboxToValue.create(srcVal, dstTy)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createVArray`.
     * @param elements The `elements` parameter.
     * @return The `VArrayExpr` result.
     */
    public func createVArray(elements: ArrayList<Value>): VArrayExpr {
        let expr = VArrayExpr.create(elements)
        insertAndAdvance(expr)
        return expr
    }

    /**
     * Performs the public behavior of `createVArrayBuilder`.
     * @param retTy The `retTy` parameter.
     * @param size The `size` parameter.
     * @param initVal The `initVal` parameter.
     * @param initFunc The `initFunc` parameter.
     * @return The `VArrayBuilder` result.
     */
    public func createVArrayBuilder(retTy: Type, size: Value, initVal: Value, initFunc: Value): VArrayBuilder {
        let expr = VArrayBuilder.create(retTy, size, initVal, initFunc)
        insertAndAdvance(expr)
        return expr
    }

    internal func createIntrinsic(retTy: Type, kind: IntrinsicKind, funcCallCtx: FuncCallContext): Intrinsic {
        let expr = Intrinsic.create(retTy, kind, funcCallCtx)
        insertAndAdvance(expr)
        return expr
    }

    internal func createTryIntrinsic(retTy: Type, kind: IntrinsicKind, funcCallCtx: FuncCallContext, normal: Block, err: Block): TryIntrinsic {
        let expr = TryIntrinsic.create(retTy, kind, funcCallCtx, normal, err)
        insertAndAdvance(expr)
        return expr
    }

    private func insertAndAdvance(expr: Expression): Unit {
        _parent.insertExpr(expr, _insertPoint)
        _insertPoint++
    }
}

extend ArrayList<Expression> {
    internal func indexOf(item: Expression): Int64 {
        for (i in 0..size) {
            if (this[i] == item) {
                return i
            }
        }
        return -1
    }
}
