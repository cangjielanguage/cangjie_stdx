/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.chir

import std.deriving.*
import stdx.chir.toStringMacro.*

@Derive[Equatable]
@CHIREnumToString
internal enum ValueKind {
    | Invalid
    | GlobalVar
    | LocalVar
    | Parameter
    | Func
    | Block
    | BlockGroup
    | Literal
}

@Derive[Equatable]
@CHIREnumToString
internal enum FuncKind {
    | Default
    | Getter
    | Setter
    | Lambda
    | ClassConstructor
    | PrimaryClassConstructor
    | StructConstructor
    | PrimaryStructConstructor
    | GlobalVarInit
    | Finalizer
    | MainEntry
    | AnnoFactoryFunc
    | MacroFunc
    | DefaultParameterFunc
    | InstanceVarInit
}

@Derive[Equatable]
@CHIREnumToString
internal enum LiteralKind {
    | BoolLit
    | RuneLit
    | IntLit
    | FloatLit
    | StringLit
    | UnitLit
    | NullLit
}

sealed abstract class Value <: Base & ToString & Hashable & Equatable<Value> {
    internal var _hashCode: Int64 = 0
    internal var _identifier: String
    internal var _kind: ValueKind
    internal var _type: Type
    internal var _users = ArrayList<Expression>()

    /**
     * Gets the `identifier` property.
     * @type { String }
     */
    public prop identifier: String {
        get() {
            return _identifier
        }
    }

    /**
     * Gets the `identifierWithoutPrefix` property.
     * @type { String }
     */
    public prop identifierWithoutPrefix: String {
        get() {
            var s = _identifier
            if (s.startsWith(GLOBAL_SYMBOL_PREFIX)) {
                s = s.removePrefix(GLOBAL_SYMBOL_PREFIX)
            } else if (s.startsWith(BLOCK_PREFIX)) {
                s = s.removePrefix(BLOCK_PREFIX)
            } else if (s.startsWith(LOCAL_VAR_PREFIX)) {
                s = s.removePrefix(LOCAL_VAR_PREFIX)
            }
            return s
        }
    }

    /**
     * Gets the `ty` property.
     * @type { Type }
     */
    public mut prop ty: Type {
        get() {
            return _type
        }
        set(v) {
            _type = v
        }
    }

    /**
     * Gets the `users` property.
     * @type { Array<Expression> }
     */
    public prop users: Array<Expression> {
        get() {
            return _users.toArray()
        }
    }

    internal init(kind: ValueKind, identifier: String) {
        this._kind = kind
        this._type = InvalidType.get()
        this._identifier = identifier
    }

    internal init(kind: ValueKind, ty: Type, identifier: String) {
        this._kind = kind
        this._type = ty
        this._identifier = identifier
    }

    /**
     * Performs the public behavior of `dump`.
     * @return The `Unit` result.
     */
    public func dump(): Unit {
        println(toString())
    }

    /**
     * Performs the public behavior of `hashCode`.
     * @return The `Int64` result.
     */
    public func hashCode(): Int64 {
        return _hashCode
    }

    /**
     * Performs the public behavior of `isBlock`.
     * @return The `Bool` result.
     */
    public func isBlock(): Bool {
        return _kind == ValueKind.Block
    }

    /**
     * Performs the public behavior of `isBlockGroup`.
     * @return The `Bool` result.
     */
    public func isBlockGroup(): Bool {
        return _kind == ValueKind.BlockGroup
    }

    /**
     * Performs the public behavior of `isFunction`.
     * @return The `Bool` result.
     */
    public func isFunction(): Bool {
        return _kind == ValueKind.Func
    }

    /**
     * Performs the public behavior of `isGlobalVar`.
     * @return The `Bool` result.
     */
    public func isGlobalVar(): Bool {
        return _kind == ValueKind.GlobalVar
    }

    /**
     * Performs the public behavior of `isLiteral`.
     * @return The `Bool` result.
     */
    public func isLiteral(): Bool {
        return _kind == ValueKind.Literal
    }

    /**
     * Performs the public behavior of `isLocalVar`.
     * @return The `Bool` result.
     */
    public func isLocalVar(): Bool {
        return _kind == ValueKind.LocalVar
    }

    /**
     * Performs the public behavior of `isParameter`.
     * @return The `Bool` result.
     */
    public func isParameter(): Bool {
        return _kind == ValueKind.Parameter
    }

    protected open func calculateHashCode(): Int64

    internal func isInvalid(): Bool {
        return _kind == ValueKind.Invalid
    }

    /**
     * Performs the public behavior of `func`.
     * @param other The `other` parameter.
     * @return The `Bool` result.
     */
    public operator func==(other: Value): Bool {
        return refEq(this, other)
    }
}

/**
 * Public definition of Block.
 */
public class Block <: Value & Equatable<Block> {
    internal var _exceptions: ?ArrayList<ClassLikeType> = None
    internal var _exprs = ArrayList<Expression>()
    internal var _owner: BlockGroup
    internal var _predecessors = ArrayList<Block>()

    /**
     * Gets the `exceptions` property.
     * @type { Array<ClassLikeType> }
     */
    public mut prop exceptions: Array<ClassLikeType> {
        get() {
            return _exceptions.getOrThrow().toArray()
        }
        set(value) {
            _exceptions = ArrayList<ClassLikeType>.of(value)
        }
    }

    /**
     * Gets the `exprs` property.
     * @type { Array<Expression> }
     */
    public prop exprs: Array<Expression> {
        get() {
            return _exprs.toArray()
        }
    }

    /**
     * Gets the `isLandingPadBlock` property.
     * @type { Bool }
     */
    public prop isLandingPadBlock: Bool {
        get() {
            return _exceptions.isSome()
        }
    }

    /**
     * Gets the `owner` property.
     * @type { BlockGroup }
     */
    public prop owner: BlockGroup {
        get() {
            return _owner
        }
    }

    /**
     * Gets the `predecessors` property.
     * @type { Array<Block> }
     */
    public prop predecessors: Array<Block> {
        get() {
            return _predecessors.toArray()
        }
    }

    /**
     * Gets the `topLevelFunc` property.
     * @type { Function }
     */
    public prop topLevelFunc: Function {
        get() {
            return _owner.topLevelFunc
        }
    }

    internal init(identifier: String, owner: BlockGroup) {
        super(ValueKind.Block, identifier)
        this._owner = owner
        this._hashCode = calculateHashCode()
    }

    /**
     * Performs the public behavior of `appendExpr`.
     * @param expr The `expr` parameter.
     * @return The `Unit` result.
     */
    public func appendExpr(expr: Expression): Unit {
        _exprs.add(expr)
        expr._owner = this
        updateLocalVarIdAndHashCode(expr._result)
    }

    /**
     * Performs the public behavior of `destroySelf`.
     * @return The `Unit` result.
     */
    public func destroySelf(): Unit {
        for (expr in _exprs) {
            expr.destroySelf()
        }
        _predecessors.clear()
        _exceptions = None
        _owner._blocks.removeIf({ bb => bb == this })
        _kind = ValueKind.Invalid
    }

    /**
     * Performs the public behavior of `insertExpr`.
     * @param expr The `expr` parameter.
     * @param at The `at` parameter.
     * @return The `Unit` result.
     */
    public func insertExpr(expr: Expression, at: Int64): Unit {
        if (at < 0) {
            throw CHIRException("Invalid insert position: ${at}")
        }
        if (at >= _exprs.size) {
            _exprs.add(expr)
        } else {
            _exprs.add(expr, at: at)
        }
        expr._owner = this
        updateLocalVarIdAndHashCode(expr._result)
    }

    /**
     * Performs the public behavior of `toString`.
     * @return The `String` result.
     */
    public func toString(): String {
        return blockToString(this, 0)
    }

    protected override func calculateHashCode(): Int64 {
        return (_owner.topLevelFunc.identifier + "_BG" + _owner.identifier + "_B" + identifier).hashCode()
    }

    /**
     * Performs the public behavior of `func`.
     * @param other The `other` parameter.
     * @return The `Bool` result.
     */
    public operator func==(other: Block): Bool {
        return refEq(this, other)
    }
}

/**
 * Public definition of BlockGroup.
 */
public class BlockGroup <: Value & Equatable<BlockGroup> {
    internal var _blocks = ArrayList<Block>()
    // owner is lambda(LocalVar) or global function(Function)
    internal var _entryBlock: ?Block = None
    internal var _owner: Value

    /**
     * Gets the `blocks` property.
     * @type { Array<Block> }
     */
    public prop blocks: Array<Block> {
        get() {
            return _blocks.toArray()
        }
    }

    /**
     * Gets the `entryBlock` property.
     * @type { Block }
     */
    public prop entryBlock: Block {
        get() {
            if (let Some(b) <- _entryBlock) {
                return b
            } else {
                throw CHIRException("Entry block is not set")
            }
        }
    }

    /**
     * Gets the `owner` property.
     * @type { Value }
     */
    public prop owner: Value {
        get() {
            return _owner
        }
    }

    /**
     * Gets the `topLevelFunc` property.
     * @type { Function }
     */
    public prop topLevelFunc: Function {
        get() {
            if (let Some(f) <- (_owner as Function)) {
                return f
            } else if (let Some(lv) <- (_owner as LocalVar)) {
                return lv.topLevelFunc
            } else {
                throw CHIRException("Invalid owner: ${_owner.toString()}")
            }
        }
    }

    internal init(identifier: String, owner: Value) {
        super(ValueKind.BlockGroup, identifier)
        this._owner = owner
        this._hashCode = calculateHashCode()
    }

    /**
     * Performs the public behavior of `appendBlock`.
     * @return The `Block` result.
     */
    public func appendBlock(): Block {
        let identifier = BLOCK_PREFIX + topLevelFunc.generateBlockId().toString()
        let bb = Block(identifier, this)
        _blocks.add(bb)
        return bb
    }

    /**
     * Performs the public behavior of `destroySelf`.
     * @return The `Unit` result.
     */
    public func destroySelf(): Unit {
        for (block in _blocks) {
            block.destroySelf()
        }
        _blocks.clear()
        _entryBlock = None
        if (let Some(f) <- (_owner as Function)) {
            f._body = None
        } else if (let Some(lv) <- (_owner as LocalVar)) {
            lv.expr._blockGroups.removeIf({ bg => bg == this })
        } else {
            throw CHIRException("Invalid owner: ${_owner.toString()}")
        }
        _kind = ValueKind.Invalid
    }

    /**
     * Performs the public behavior of `setEntryBlock`.
     * @param block The `block` parameter.
     * @return The `Unit` result.
     */
    public func setEntryBlock(block: Block): Unit {
        if (!_blocks.contains(block)) {
            throw CHIRException("Entry block must push into BlockGroup first")
        }
        _entryBlock = block
    }

    /**
     * Performs the public behavior of `toString`.
     * @return The `String` result.
     */
    public func toString(): String {
        return blockGroupToString(this, 0)
    }

    protected override func calculateHashCode(): Int64 {
        return (topLevelFunc.identifier + "_BG" + identifier).hashCode()
    }

    /**
     * Performs the public behavior of `func`.
     * @param other The `other` parameter.
     * @return The `Bool` result.
     */
    public operator func==(other: BlockGroup): Bool {
        return refEq(this, other)
    }
}

sealed abstract class GlobalValue <: Value & Equatable<GlobalValue> {
    internal var _annoInfo: AnnoInfo = AnnoInfo()
    internal var _declaredParent: ?CustomTypeDef = None
    internal let _packageName: String
    internal var _rawMangledName: String = ""
    internal let _srcCodeName: String

    /**
     * Gets the `annotations` property.
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
     * Gets the `declaredParent` property.
     * @type { ?CustomTypeDef }
     */
    public prop declaredParent: ?CustomTypeDef {
        get() {
            return _declaredParent
        }
    }

    /**
     * Gets the `packageName` property.
     * @type { String }
     */
    public prop packageName: String {
        get() {
            return _packageName
        }
    }

    /**
     * Gets the `srcCodeName` property.
     * @type { String }
     */
    public prop srcCodeName: String {
        get() {
            return _srcCodeName
        }
    }

    internal init(kind: ValueKind, ty: Type, identifier: String, srcName: String, pkgName: String) {
        super(kind, ty, identifier)
        this._srcCodeName = srcName
        this._packageName = pkgName
    }

    /**
     * Performs the public behavior of `isCompilerAdd`.
     * @return The `Bool` result.
     */
    public func isCompilerAdd(): Bool {
        return _attributes.testAttr(Attribute.CompilerAdd)
    }

    /**
     * Performs the public behavior of `isConst`.
     * @return The `Bool` result.
     */
    public func isConst(): Bool {
        return _attributes.testAttr(Attribute.Const)
    }

    /**
     * Performs the public behavior of `isExternalLinkage`.
     * @return The `Bool` result.
     */
    public func isExternalLinkage(): Bool {
        return getAnno<LinkTypeInfo, LinkType>() == LinkType.External
    }

    /**
     * Performs the public behavior of `isForeign`.
     * @return The `Bool` result.
     */
    public func isForeign(): Bool {
        return _attributes.testAttr(Attribute.Foreign)
    }

    /**
     * Performs the public behavior of `isImported`.
     * @return The `Bool` result.
     */
    public func isImported(): Bool {
        return _attributes.testAttr(Attribute.Imported)
    }

    /**
     * Performs the public behavior of `isInternal`.
     * @return The `Bool` result.
     */
    public func isInternal(): Bool {
        return _attributes.testAttr(Attribute.Internal)
    }

    /**
     * Performs the public behavior of `isPrivate`.
     * @return The `Bool` result.
     */
    public func isPrivate(): Bool {
        return _attributes.testAttr(Attribute.Private)
    }

    /**
     * Performs the public behavior of `isProtected`.
     * @return The `Bool` result.
     */
    public func isProtected(): Bool {
        return _attributes.testAttr(Attribute.Protected)
    }

    /**
     * Performs the public behavior of `isPublic`.
     * @return The `Bool` result.
     */
    public func isPublic(): Bool {
        return _attributes.testAttr(Attribute.Public)
    }

    /**
     * Performs the public behavior of `isStatic`.
     * @return The `Bool` result.
     */
    public func isStatic(): Bool {
        return _attributes.testAttr(Attribute.Static)
    }

    /**
     * Performs the public behavior of `setConst`.
     * @param enable The `enable` parameter.
     * @return The `Unit` result.
     */
    public func setConst(enable: Bool): Unit {
        _attributes.setAttr(Attribute.Const, enable)
    }

    /**
     * Performs the public behavior of `setInternal`.
     * @return The `Unit` result.
     */
    public func setInternal(): Unit {
        _attributes.setInternal()
    }

    /**
     * Performs the public behavior of `setPrivate`.
     * @return The `Unit` result.
     */
    public func setPrivate(): Unit {
        _attributes.setPrivate()
    }

    /**
     * Performs the public behavior of `setProtected`.
     * @return The `Unit` result.
     */
    public func setProtected(): Unit {
        _attributes.setProtected()
    }

    /**
     * Performs the public behavior of `setPublic`.
     * @return The `Unit` result.
     */
    public func setPublic(): Unit {
        _attributes.setPublic()
    }

    /**
     * Performs the public behavior of `setStatic`.
     * @param enable The `enable` parameter.
     * @return The `Unit` result.
     */
    public func setStatic(enable: Bool): Unit {
        _attributes.setAttr(Attribute.Static, enable)
    }

    protected override func calculateHashCode(): Int64 {
        return identifier.hashCode()
    }

    internal func globalValueToString(): String {
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
        if (_declaredParent.isSome()) {
            comment.add("declaredParent: " + _declaredParent.getOrThrow().identifier)
        }
        if (comment.isEmpty()) {
            return ""
        }
        return String.join(comment.toArray(), delimiter: ", ")
    }

    /**
     * Performs the public behavior of `func`.
     * @param other The `other` parameter.
     * @return The `Bool` result.
     */
    public operator func==(other: GlobalValue): Bool {
        return refEq(this, other)
    }
}

/**
 * Public definition of GlobalVar.
 */
public class GlobalVar <: GlobalValue & Equatable<GlobalVar> {
    internal var _initializer: ?Value = None

    /**
     * Gets the `initializer` property.
     * @type { ?Value }
     */
    public prop initializer: ?Value {
        get() {
            return _initializer
        }
    }

    internal init(ty: Type, identifier: String, srcName: String, pkgName: String) {
        super(ValueKind.GlobalVar, ty, identifier, srcName, pkgName)
        this._hashCode = calculateHashCode()
    }

    /**
     * Performs the public behavior of `isReadOnly`.
     * @return The `Bool` result.
     */
    public func isReadOnly(): Bool {
        return _attributes.testAttr(Attribute.ReadOnly)
    }

    /**
     * Performs the public behavior of `isSrcCodeImported`.
     * @return The `Bool` result.
     */
    public func isSrcCodeImported(): Bool {
        return isImported() && !_initializer.isNone()
    }

    /**
     * Performs the public behavior of `setInitializer`.
     * @param initializer The `initializer` parameter.
     * @return The `Unit` result.
     */
    public func setInitializer(initializer: Value): Unit {
        _initializer = initializer
    }

    /**
     * Performs the public behavior of `setReadOnly`.
     * @param enable The `enable` parameter.
     * @return The `Unit` result.
     */
    public func setReadOnly(enable: Bool): Unit {
        _attributes.setAttr(Attribute.ReadOnly, enable)
    }

    /**
     * Performs the public behavior of `toString`.
     * @return The `String` result.
     */
    public func toString(): String {
        let result = StringBuilder()
        if (let str <- _annoInfo.toString() && !str.isEmpty()) {
            result.append(str)
            result.append("\n")
        }
        result.append(_attributes.toString())
        if (isReadOnly()) {
            result.append("let ")
        } else {
            result.append("var ")
        }
        result.append(identifier + ": " + ty.toString())
        if (let Some(v) <- initializer) {
            if (v.isLiteral()) {
                result.append(" = " + v.toString())
            } else {
                // must be init function
                result.append(" = " + v.identifier + "()")
            }
        }
        if (let str <- globalValueToString() && !str.isEmpty()) {
            result.append(" // ")
            result.append(str)
        }
        return result.toString()
    }

    /**
     * Performs the public behavior of `func`.
     * @param other The `other` parameter.
     * @return The `Bool` result.
     */
    public operator func==(other: GlobalVar): Bool {
        return refEq(this, other)
    }
}

/**
 * Public definition of Function.
 */
public class Function <: GlobalValue & Equatable<Function> {
    internal var _blockGroupId: UInt64 = 0
    internal var _blockId: UInt64 = 0
    internal var _body: ?BlockGroup = None
    internal var _funcKind: FuncKind = FuncKind.Default
    internal var _genericDecl: ?Function = None
    internal var _genericTypeParams = ArrayList<GenericType>()
    internal var _isCFFIWrapper: Bool = false
    internal var _isFastNative: Bool = false
    internal var _localId: UInt64 = 0
    internal var _oriLambdaFuncTy: ?Type = None
    internal var _oriLambdaGenericTypeParams: ?ArrayList<GenericType> = None
    internal var _paramDftValHostFunc: ?Function = None
    internal var _parameters = ArrayList<Parameter>()
    internal var _propLocation: DebugLocation = DebugLocation.invalid()
    internal var _retValue: ?LocalVar = None

    /**
     * Gets the `body` property.
     * @type { ?BlockGroup }
     */
    public prop body: ?BlockGroup {
        get() {
            return _body
        }
    }

    /**
     * Gets the `funcSrcCodeType` property.
     * @type { FuncType }
     */
    public prop funcSrcCodeType: FuncType {
        get() {
            if (isInstanceMemberMethod()) {
                let (_, paramTypes) = funcType.paramTypes.splitAt(1)
                return FuncType.get(paramTypes, funcType.returnType)
            } else {
                return funcType
            }
        }
    }

    /**
     * Gets the `funcType` property.
     * @type { FuncType }
     */
    public prop funcType: FuncType {
        get() {
            (_type as FuncType).getOrThrow()
        }
    }

    /**
     * Gets the `genericTypeParams` property.
     * @type { Array<GenericType> }
     */
    public mut prop genericTypeParams: Array<GenericType> {
        get() {
            return _genericTypeParams.toArray()
        }
        set(v) {
            let enableGeneric = if (v.isEmpty()) {
                false
            } else {
                true
            }
            _attributes.setAttr(Attribute.Generic, enableGeneric)
            _genericTypeParams = ArrayList<GenericType>.of(v)
        }
    }

    /**
     * Gets the `parameters` property.
     * @type { Array<Parameter> }
     */
    public prop parameters: Array<Parameter> {
        get() {
            return _parameters.toArray()
        }
    }

    /**
     * Gets the `returnValue` property.
     * @type { ?LocalVar }
     */
    public prop returnValue: ?LocalVar {
        get() {
            return _retValue
        }
    }

    internal init(ty: FuncType, identifier: String, srcName: String, pkgName: String) {
        super(ValueKind.Func, ty, identifier, srcName, pkgName)
        this._hashCode = calculateHashCode()
    }

    /**
     * Performs the public behavior of `initBody`.
     * @return The `Unit` result.
     */
    public func initBody(): Unit {
        let newBody = addBody()
        let bb = newBody.appendBlock()
        newBody.setEntryBlock(bb)
    }

    /**
     * Performs the public behavior of `isAbstract`.
     * @return The `Bool` result.
     */
    public func isAbstract(): Bool {
        // 1. it is not implemented in the current class
        if (_attributes.testAttr(Attribute.Abstract)) {
            return true
        }
        // 2. it is a method in interface
        if (let Some(parent) <- _declaredParent) {
            return parent.isInterface()
        }
        return false
    }

    /**
     * Performs the public behavior of `isDeclaredInCurPackage`.
     * @return The `Bool` result.
     */
    public func isDeclaredInCurPackage(): Bool {
        return !isImported()
    }

    /**
     * Performs the public behavior of `isGeneric`.
     * @return The `Bool` result.
     */
    public func isGeneric(): Bool {
        return _attributes.testAttr(Attribute.Generic)
    }

    /**
     * Performs the public behavior of `isInstanceMemberMethod`.
     * @return The `Bool` result.
     */
    public func isInstanceMemberMethod(): Bool {
        return isMemberMethod() && !isStatic()
    }

    /**
     * Performs the public behavior of `isMemberMethod`.
     * @return The `Bool` result.
     */
    public func isMemberMethod(): Bool {
        return _declaredParent.isSome()
    }

    /**
     * Performs the public behavior of `isOpen`.
     * @return The `Bool` result.
     */
    public func isOpen(): Bool {
        return _attributes.testAttr(Attribute.Virtual) || _attributes.testAttr(Attribute.Abstract)
    }

    /**
     * Performs the public behavior of `isSrcCodeImported`.
     * @return The `Bool` result.
     */
    public func isSrcCodeImported(): Bool {
        return isImported() && _body.isSome()
    }

    /**
     * Performs the public behavior of `isStaticMemberMethod`.
     * @return The `Bool` result.
     */
    public func isStaticMemberMethod(): Bool {
        return isMemberMethod() && isStatic()
    }

    /**
     * Performs the public behavior of `moveBodyTo`.
     * @param other The `other` parameter.
     * @return The `Unit` result.
     */
    public func moveBodyTo(other: Function): Unit {
        if (let Some(oBody) <- other._body) {
            oBody.destroySelf()
        }
        other._body = _body
        this._body = None
        other._parameters = _parameters
        this._parameters.clear()
        other._genericTypeParams = _genericTypeParams
        this._genericTypeParams.clear()
        other._retValue = _retValue
        this._retValue = None
        other._localId = _localId
        this._localId = 0
        other._blockId = _blockId
        this._blockId = 0
        other._blockGroupId = _blockGroupId
        this._blockGroupId = 0
    }

    /**
     * Performs the public behavior of `selfOrParentIsGeneric`.
     * @return The `Bool` result.
     */
    public func selfOrParentIsGeneric(): Bool {
        return isGeneric() || (_declaredParent.isSome() && _declaredParent.getOrThrow().isGeneric())
    }

    /**
     * Performs the public behavior of `setAbstract`.
     * @param enable The `enable` parameter.
     * @return The `Unit` result.
     */
    public func setAbstract(enable: Bool): Unit {
        _attributes.setAttr(Attribute.Abstract, enable)
    }

    /**
     * Performs the public behavior of `setOpen`.
     * @param enable The `enable` parameter.
     * @return The `Unit` result.
     */
    public func setOpen(enable: Bool): Unit {
        _attributes.setAttr(Attribute.Virtual, enable)
    }

    /**
     * Performs the public behavior of `toString`.
     * @return The `String` result.
     */
    public func toString(): String {
        return functionToString(this, 0)
    }

    internal func addBody(): BlockGroup {
        if (_body.isSome()) {
            throw CHIRException("Function body already set")
        }
        let identifier = generateBlockGroupId().toString()
        _body = BlockGroup(identifier, this)
        return _body.getOrThrow()
    }

    internal func appendParameter(ty: Type): Parameter {
        let identifier = LOCAL_VAR_PREFIX + generateLocalId().toString()
        let result = Parameter(ty, identifier, this)
        _parameters.add(result)
        return result
    }

    internal func generateBlockGroupId(): UInt64 {
        let tmp = _blockGroupId
        _blockGroupId++
        return tmp
    }

    internal func generateBlockId(): UInt64 {
        let tmp = _blockId
        _blockId++
        return tmp
    }

    internal func generateLocalId(): UInt64 {
        let tmp = _localId
        _localId++
        return tmp
    }

    /**
     * Performs the public behavior of `func`.
     * @param other The `other` parameter.
     * @return The `Bool` result.
     */
    public operator func==(other: Function): Bool {
        return refEq(this, other)
    }
}

sealed abstract class LiteralValue <: Value & Equatable<LiteralValue> {
    internal let literalKind: LiteralKind

    internal init(ty: Type, literalKind: LiteralKind) {
        super(ValueKind.Literal, ty, String.empty)
        this.literalKind = literalKind
    }

    /**
     * Performs the public behavior of `func`.
     * @param other The `other` parameter.
     * @return The `Bool` result.
     */
    public operator func==(other: LiteralValue): Bool {
        return refEq(this, other)
    }
}

/**
 * Public definition of BoolLiteral.
 */
public class BoolLiteral <: LiteralValue & Equatable<BoolLiteral> {
    private static var CACHE = ArrayList<BoolLiteral>()
    internal let _value: Bool

    /**
     * Gets the `value` property.
     * @type { Bool }
     */
    public prop value: Bool {
        get() {
            return _value
        }
    }

    static init() {
        CACHE.add(BoolLiteral(BoolType.get(), false))
        CACHE.add(BoolLiteral(BoolType.get(), true))
    }

    private init(ty: BoolType, value: Bool) {
        super(ty, LiteralKind.BoolLit)
        this._value = value
        this._hashCode = calculateHashCode()
    }

    /**
     * Performs the public behavior of `get`.
     * @param value The `value` parameter.
     * @return The `BoolLiteral` result.
     */
    public static func get(value: Bool): BoolLiteral {
        if (value) {
            return CACHE[1]
        } else {
            return CACHE[0]
        }
    }

    /**
     * Performs the public behavior of `toString`.
     * @return The `String` result.
     */
    public func toString(): String {
        return value.toString()
    }

    protected override func calculateHashCode(): Int64 {
        return ("BoolLiteral_" + _value.toString()).hashCode()
    }

    /**
     * Performs the public behavior of `func`.
     * @param other The `other` parameter.
     * @return The `Bool` result.
     */
    public operator func==(other: BoolLiteral): Bool {
        return refEq(this, other)
    }
}

/**
 * Public definition of RuneLiteral.
 */
public class RuneLiteral <: LiteralValue & Equatable<RuneLiteral> {
    private static var CACHE = HashMap<Rune, RuneLiteral>()
    internal let _value: Rune

    /**
     * Gets the `value` property.
     * @type { Rune }
     */
    public prop value: Rune {
        get() {
            return _value
        }
    }

    private init(ty: RuneType, value: Rune) {
        super(ty, LiteralKind.RuneLit)
        this._value = value
        this._hashCode = calculateHashCode()
    }

    /**
     * Performs the public behavior of `get`.
     * @param value The `value` parameter.
     * @return The `RuneLiteral` result.
     */
    public static func get(value: Rune): RuneLiteral {
        if (let Some(literal) <- CACHE.get(value)) {
            return literal
        }
        let newLiteral = RuneLiteral(RuneType.get(), value)
        CACHE[value] = newLiteral
        return newLiteral
    }

    /**
     * Performs the public behavior of `toString`.
     * @return The `String` result.
     */
    public func toString(): String {
        return "\'" + value.toString() + "\'"
    }

    protected override func calculateHashCode(): Int64 {
        return ("RuneLiteral_" + _value.toString()).hashCode()
    }

    /**
     * Performs the public behavior of `func`.
     * @param other The `other` parameter.
     * @return The `Bool` result.
     */
    public operator func==(other: RuneLiteral): Bool {
        return refEq(this, other)
    }
}

/**
 * Public definition of IntLiteral.
 */
public class IntLiteral <: LiteralValue & Equatable<IntLiteral> {
    private static var CACHE = HashMap<IntType, HashMap<UInt64, IntLiteral>>()
    internal let _value: UInt64

    /**
     * Gets the `signedValue` property.
     * @type { Int64 }
     */
    public prop signedValue: Int64 {
        get() {
            return Int64(_value)
        }
    }

    /**
     * Gets the `unsignedValue` property.
     * @type { UInt64 }
     */
    public prop unsignedValue: UInt64 {
        get() {
            return _value
        }
    }

    private init(ty: IntType, value: UInt64) {
        super(ty, LiteralKind.IntLit)
        this._value = value
        this._hashCode = calculateHashCode()
    }

    /**
     * Performs the public behavior of `get`.
     * @param ty The `ty` parameter.
     * @param value The `value` parameter.
     * @return The `IntLiteral` result.
     */
    public static func get(ty: IntType, value: UInt64): IntLiteral {
        if (let Some(intTypes) <- CACHE.get(ty)) {
            if (let Some(literal) <- intTypes.get(value)) {
                return literal
            } else {
                let newLiteral = IntLiteral(ty, value)
                intTypes[value] = newLiteral
                return newLiteral
            }
        }
        let newLiteral = IntLiteral(ty, value)
        CACHE[ty] = HashMap<UInt64, IntLiteral>((value, newLiteral))
        return newLiteral
    }

    /**
     * Performs the public behavior of `isSigned`.
     * @return The `Bool` result.
     */
    public func isSigned(): Bool {
        return (ty as IntType).getOrThrow().isSigned()
    }

    /**
     * Performs the public behavior of `toString`.
     * @return The `String` result.
     */
    public func toString(): String {
        let suffix = if (isSigned()) { "i" } else { "u" }
        return unsignedValue.toString() + suffix
    }

    protected override func calculateHashCode(): Int64 {
        return (ty.toString() + "_" + _value.toString()).hashCode()
    }

    /**
     * Performs the public behavior of `func`.
     * @param other The `other` parameter.
     * @return The `Bool` result.
     */
    public operator func==(other: IntLiteral): Bool {
        return refEq(this, other)
    }
}

/**
 * Public definition of FloatLiteral.
 */
public class FloatLiteral <: LiteralValue & Equatable<FloatLiteral> {
    private static var CACHE = HashMap<FloatType, HashMap<Float64, FloatLiteral>>()
    internal let _value: Float64

    /**
     * Gets the `value` property.
     * @type { Float64 }
     */
    public prop value: Float64 {
        get() {
            return _value
        }
    }

    private init(ty: FloatType, value: Float64) {
        super(ty, LiteralKind.FloatLit)
        this._value = value
        this._hashCode = calculateHashCode()
    }

    /**
     * Performs the public behavior of `get`.
     * @param ty The `ty` parameter.
     * @param value The `value` parameter.
     * @return The `FloatLiteral` result.
     */
    public static func get(ty: FloatType, value: Float64): FloatLiteral {
        if (let Some(floatTypes) <- CACHE.get(ty)) {
            if (let Some(literal) <- floatTypes.get(value)) {
                return literal
            } else {
                let newLiteral = FloatLiteral(ty, value)
                floatTypes[value] = newLiteral
                return newLiteral
            }
        }
        let newLiteral = FloatLiteral(ty, value)
        CACHE[ty] = HashMap<Float64, FloatLiteral>((value, newLiteral))
        return newLiteral
    }

    /**
     * Performs the public behavior of `toString`.
     * @return The `String` result.
     */
    public func toString(): String {
        return value.toString() + "f"
    }

    protected override func calculateHashCode(): Int64 {
        return (ty.toString() + "_" + _value.toString()).hashCode()
    }

    /**
     * Performs the public behavior of `func`.
     * @param other The `other` parameter.
     * @return The `Bool` result.
     */
    public operator func==(other: FloatLiteral): Bool {
        return refEq(this, other)
    }
}

/**
 * Public definition of StringLiteral.
 */
public class StringLiteral <: LiteralValue & Equatable<StringLiteral> {
    private static var CACHE = HashMap<String, StringLiteral>()
    internal let _value: String

    /**
     * Gets the `value` property.
     * @type { String }
     */
    public prop value: String {
        get() {
            return _value
        }
    }

    private init(ty: Type, value: String) {
        super(ty, LiteralKind.StringLit)
        this._value = value
        this._hashCode = calculateHashCode()
    }

    /**
     * Performs the public behavior of `get`.
     * @param ty The `ty` parameter.
     * @param value The `value` parameter.
     * @return The `StringLiteral` result.
     */
    public static func get(ty: Type, value: String): StringLiteral {
        if (let Some(literal) <- CACHE.get(value)) {
            return literal
        }
        let newLiteral = StringLiteral(ty, value)
        CACHE[value] = newLiteral
        return newLiteral
    }

    /**
     * Performs the public behavior of `toString`.
     * @return The `String` result.
     */
    public func toString(): String {
        return "\"" + value + "\""
    }

    protected override func calculateHashCode(): Int64 {
        return (ty.toString() + "_" + _value.toString()).hashCode()
    }

    /**
     * Performs the public behavior of `func`.
     * @param other The `other` parameter.
     * @return The `Bool` result.
     */
    public operator func==(other: StringLiteral): Bool {
        return refEq(this, other)
    }
}

/**
 * Public definition of UnitLiteral.
 */
public class UnitLiteral <: LiteralValue & Equatable<UnitLiteral> {
    private static let unitLit = UnitLiteral(UnitType.get())

    private init(ty: UnitType) {
        super(ty, LiteralKind.UnitLit)
        this._hashCode = calculateHashCode()
    }

    /**
     * Performs the public behavior of `get`.
     * @return The `UnitLiteral` result.
     */
    public static func get(): UnitLiteral {
        return unitLit
    }

    /**
     * Performs the public behavior of `toString`.
     * @return The `String` result.
     */
    public func toString(): String {
        return "Unit"
    }

    protected override func calculateHashCode(): Int64 {
        return ty.toString().hashCode()
    }

    /**
     * Performs the public behavior of `func`.
     * @param other The `other` parameter.
     * @return The `Bool` result.
     */
    public operator func==(other: UnitLiteral): Bool {
        return refEq(this, other)
    }
}

/**
 * Public definition of NullLiteral.
 */
public class NullLiteral <: LiteralValue & Equatable<NullLiteral> {
    private static var CACHE = HashMap<Type, NullLiteral>()

    private init(ty: Type) {
        super(ty, LiteralKind.NullLit)
        this._hashCode = calculateHashCode()
    }

    /**
     * Performs the public behavior of `get`.
     * @param ty The `ty` parameter.
     * @return The `NullLiteral` result.
     */
    public static func get(ty: Type): NullLiteral {
        if (let Some(literal) <- CACHE.get(ty)) {
            return literal
        }
        let newLiteral = NullLiteral(ty)
        CACHE[ty] = newLiteral
        return newLiteral
    }

    /**
     * Performs the public behavior of `toString`.
     * @return The `String` result.
     */
    public func toString(): String {
        return "Null"
    }

    protected override func calculateHashCode(): Int64 {
        return ty.toString().hashCode()
    }

    /**
     * Performs the public behavior of `func`.
     * @param other The `other` parameter.
     * @return The `Bool` result.
     */
    public operator func==(other: NullLiteral): Bool {
        return refEq(this, other)
    }
}

/**
 * Public definition of LocalVar.
 */
public class LocalVar <: Value & Equatable<LocalVar> {
    internal var _expr: ?Expression = None
    internal var _isRetValue = false

    /**
     * Gets the `expr` property.
     * @type { Expression }
     */
    public prop expr: Expression {
        get() {
            if (let Some(e) <- _expr) {
                return e
            } else {
                throw CHIRException("Expression is not set")
            }
        }
    }

    /**
     * Gets the `topLevelFunc` property.
     * @type { Function }
     */
    public prop topLevelFunc: Function {
        get() {
            return expr.topLevelFunc
        }
    }

    internal init(ty: Type) {
        super(ValueKind.LocalVar, ty, String.empty)
        this._hashCode = 0
    }

    /**
     * Performs the public behavior of `toString`.
     * @return The `String` result.
     */
    public func toString(): String {
        return expr.toString()
    }

    protected override func calculateHashCode(): Int64 {
        return (topLevelFunc.identifier + "_LV" + identifier).hashCode()
    }

    /**
     * Performs the public behavior of `func`.
     * @param other The `other` parameter.
     * @return The `Bool` result.
     */
    public operator func==(other: LocalVar): Bool {
        return refEq(this, other)
    }
}

/**
 * Public definition of Parameter.
 */
public class Parameter <: Value & Equatable<Parameter> {
    internal var _annoInfo: AnnoInfo = AnnoInfo()
    internal var _owner: Value

    /**
     * Gets the `annotations` property.
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
     * Gets the `topLevelFunc` property.
     * @type { Function }
     */
    public prop topLevelFunc: Function {
        get() {
            if (let Some(f) <- (_owner as Function)) {
                return f
            } else if (let Some(lv) <- (_owner as LocalVar)) {
                return lv.topLevelFunc
            } else {
                throw CHIRException("Invalid owner: ${_owner.toString()}")
            }
        }
    }

    internal init(ty: Type, identifier: String, owner: Function) {
        super(ValueKind.Parameter, ty, identifier)
        this._owner = owner
        this._hashCode = calculateHashCode()
        _attributes.setAttr(Attribute.ReadOnly, true)
    }

    internal init(ty: Type, identifier: String, owner: Lambda) {
        super(ValueKind.Parameter, ty, identifier)
        this._owner = owner.result
        this._hashCode = calculateHashCode()
        _attributes.setAttr(Attribute.ReadOnly, true)
    }

    /**
     * Performs the public behavior of `toString`.
     * @return The `String` result.
     */
    public func toString(): String {
        return parameterToString(this, 0)
    }

    protected override func calculateHashCode(): Int64 {
        return (topLevelFunc.identifier + "_P" + identifier).hashCode()
    }

    /**
     * Performs the public behavior of `func`.
     * @param other The `other` parameter.
     * @return The `Bool` result.
     */
    public operator func==(other: Parameter): Bool {
        return refEq(this, other)
    }
}
