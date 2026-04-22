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
internal enum LinkType <: ToString {
    External
    | Internal
    | WeakOdr
    | LinkonceOdr
    | ExternalWeak

    public func toString(): String {
        match (this) {
            case External => "external"
            case Internal => "internal"
            case WeakOdr => "weak_odr"
            case LinkonceOdr => "linkonce_odr"
            case ExternalWeak => "external_weak"
        }
    }
}

internal interface CHIRAnnoBase <: ToString {
}

internal interface CHIRAnno<T> <: CHIRAnnoBase {
    static func create(value: T): CHIRAnno<T>

    static func defaultValue(): T

    func get(): T

    func set(value: T): Unit
}

internal class IsAutoEnvClass <: CHIRAnno<Bool> {
    private var v: Bool

    internal init(value: Bool) {
        this.v = value
    }

    static public func create(value: Bool): CHIRAnno<Bool> {
        return IsAutoEnvClass(value)
    }

    static public func defaultValue(): Bool {
        return false
    }

    public func get(): Bool {
        return v
    }

    public func set(value: Bool): Unit {
        this.v = value
    }

    public func toString(): String {
        return "IsAutoEnvClass: " + v.toString()
    }
}

internal class GenerateFromForIn <: CHIRAnno<Bool> {
    private var v: Bool

    internal init(value: Bool) {
        this.v = value
    }

    static public func create(value: Bool): CHIRAnno<Bool> {
        return GenerateFromForIn(value)
    }

    static public func defaultValue(): Bool {
        return false
    }

    public func get(): Bool {
        return v
    }

    public func set(value: Bool): Unit {
        this.v = value
    }

    public func toString(): String {
        return "generated-from-forin"
    }
}

internal class AnnoFactoryInfo <: CHIRAnno<ArrayList<GlobalVar>> {
    private var v: ArrayList<GlobalVar>

    internal init(value: ArrayList<GlobalVar>) {
        this.v = value
    }

    static public func create(value: ArrayList<GlobalVar>): CHIRAnno<ArrayList<GlobalVar>> {
        return AnnoFactoryInfo(value)
    }

    static public func defaultValue(): ArrayList<GlobalVar> {
        return ArrayList<GlobalVar>()
    }

    public func get(): ArrayList<GlobalVar> {
        return v
    }

    public func set(value: ArrayList<GlobalVar>): Unit {
        this.v = value
    }

    public func toString(): String {
        return "annoGVs: " + valueIdVecToString("[", v, "]", false)
    }
}

internal class NeedCheckArrayBound <: CHIRAnno<Bool> {
    private var v: Bool

    internal init(value: Bool) {
        this.v = value
    }

    static public func create(value: Bool): CHIRAnno<Bool> {
        return NeedCheckArrayBound(value)
    }

    static public func defaultValue(): Bool {
        return false
    }

    public func get(): Bool {
        return v
    }

    public func set(value: Bool): Unit {
        this.v = value
    }

    public func toString(): String {
        return "checkArrayBound: " + v.toString()
    }
}

internal class NeedCheckCast <: CHIRAnno<Bool> {
    private var v: Bool

    internal init(value: Bool) {
        this.v = value
    }

    static public func create(value: Bool): CHIRAnno<Bool> {
        return NeedCheckCast(value)
    }

    static public func defaultValue(): Bool {
        return false
    }

    public func get(): Bool {
        return v
    }

    public func set(value: Bool): Unit {
        this.v = value
    }

    public func toString(): String {
        return "checkTypeCast: " + v.toString()
    }
}

internal class DebugLocationInfoForWarning <: CHIRAnno<DebugLocation> {
    private var v: DebugLocation

    internal init(value: DebugLocation) {
        this.v = value
    }

    static public func create(value: DebugLocation): CHIRAnno<DebugLocation> {
        return DebugLocationInfoForWarning(value)
    }

    static public func defaultValue(): DebugLocation {
        return DebugLocation.invalid()
    }

    public func get(): DebugLocation {
        return v
    }

    public func set(value: DebugLocation): Unit {
        this.v = value
    }

    public func toString(): String {
        return "warning loc: " + v.toString()
    }
}

internal class LinkTypeInfo <: CHIRAnno<LinkType> {
    private var v: LinkType

    internal init(value: LinkType) {
        this.v = value
    }

    static public func create(value: LinkType): CHIRAnno<LinkType> {
        return LinkTypeInfo(value)
    }

    static public func defaultValue(): LinkType {
        return LinkType.External
    }

    public func get(): LinkType {
        return v
    }

    public func set(value: LinkType): Unit {
        this.v = value
    }

    public func toString(): String {
        return "linkType: " + v.toString()
    }
}

internal class WrappedRawMethod <: CHIRAnno<Option<Function>> {
    private var v: ?Function

    internal init(value: ?Function) {
        this.v = value
    }

    static public func create(value: ?Function): CHIRAnno<Option<Function>> {
        return WrappedRawMethod(value)
    }

    static public func defaultValue(): ?Function {
        return Option<Function>.None
    }

    public func get(): ?Function {
        return v
    }

    public func set(value: ?Function): Unit {
        this.v = value
    }

    public func toString(): String {
        return "WrappedRawMethod: " + v.getOrThrow().toString()
    }
}

internal enum SkipKind <: ToString {
    NoSkip | SkipDceWarning | SkipForinExit | SkipVic

    public func toString(): String {
        match (this) {
            case NoSkip => ""
            case SkipDceWarning => "skip: dce warning"
            case SkipForinExit => "skip: for-in exit"
            case SkipVic => "skip: vic"
        }
    }
}

internal class SkipCheck <: CHIRAnno<SkipKind> {
    private var v: SkipKind

    internal init(value: SkipKind) {
        this.v = value
    }

    static public func create(value: SkipKind): CHIRAnno<SkipKind> {
        return SkipCheck(value)
    }

    static public func defaultValue(): SkipKind {
        return SkipKind.NoSkip
    }

    public func get(): SkipKind {
        return v
    }

    public func set(value: SkipKind): Unit {
        this.v = value
    }

    public func toString(): String {
        return v.toString()
    }
}

internal class NeverOverflowInfo <: CHIRAnno<Bool> {
    private var v: Bool

    internal init(value: Bool) {
        this.v = value
    }

    static public func create(value: Bool): CHIRAnno<Bool> {
        return NeverOverflowInfo(value)
    }

    static public func defaultValue(): Bool {
        return false
    }

    public func get(): Bool {
        return v
    }

    public func set(value: Bool): Unit {
        this.v = value
    }

    public func toString(): String {
        return "NeverOverflowInfo: " + v.toString()
    }
}

internal class GeneratedFromForIn <: CHIRAnno<Bool> {
    private var v: Bool

    internal init(value: Bool) {
        this.v = value
    }

    static public func create(value: Bool): CHIRAnno<Bool> {
        return GeneratedFromForIn(value)
    }

    static public func defaultValue(): Bool {
        return false
    }

    public func get(): Bool {
        return v
    }

    public func set(value: Bool): Unit {
        this.v = value
    }

    public func toString(): String {
        return "GeneratedFromForIn: " + v.toString()
    }
}

internal class IsCapturedClassInCC <: CHIRAnno<Bool> {
    private var v: Bool

    internal init(value: Bool) {
        this.v = value
    }

    static public func create(value: Bool): CHIRAnno<Bool> {
        return IsCapturedClassInCC(value)
    }

    static public func defaultValue(): Bool {
        return false
    }

    public func get(): Bool {
        return v
    }

    public func set(value: Bool): Unit {
        this.v = value
    }

    public func toString(): String {
        return "IsCapturedClassInCC: " + v.toString()
    }
}

internal class EnumCaseIndex <: CHIRAnno<Option<UInt64>> {
    private var v: ?UInt64

    internal init(value: ?UInt64) {
        this.v = value
    }

    static public func create(value: ?UInt64): CHIRAnno<Option<UInt64>> {
        return EnumCaseIndex(value)
    }

    static public func defaultValue(): ?UInt64 {
        return Option<UInt64>.None
    }

    public func get(): ?UInt64 {
        return v
    }

    public func set(value: ?UInt64): Unit {
        this.v = value
    }

    public func toString(): String {
        return "EnumCaseIndex: " + v.getOrThrow().toString()
    }
}

internal class VirMethodOffset <: CHIRAnno<Option<UInt64>> {
    private var v: ?UInt64

    internal init(value: ?UInt64) {
        this.v = value
    }

    static public func create(value: ?UInt64): CHIRAnno<Option<UInt64>> {
        return VirMethodOffset(value)
    }

    static public func defaultValue(): ?UInt64 {
        return Option<UInt64>.None
    }

    public func get(): ?UInt64 {
        return v
    }

    public func set(value: ?UInt64): Unit {
        this.v = value
    }

    public func toString(): String {
        return "VirMethodOffset: " + v.toString()
    }
}

internal class OverrideSrcFuncType <: CHIRAnno<Option<FuncType>> {
    private var v: ?FuncType

    internal init(value: ?FuncType) {
        this.v = value
    }

    static public func create(value: ?FuncType): CHIRAnno<Option<FuncType>> {
        return OverrideSrcFuncType(value)
    }

    static public func defaultValue(): ?FuncType {
        return Option<FuncType>.None
    }

    public func get(): ?FuncType {
        return v
    }

    public func set(value: ?FuncType): Unit {
        this.v = value
    }

    public func toString(): String {
        return "OverrideSrcFuncType: " + v.getOrThrow().toString()
    }
}