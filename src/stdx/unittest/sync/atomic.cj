/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

internal package stdx.unittest.sync

import std.sync.AtomicBool as SyncAtomicBool
import std.sync.AtomicInt16 as SyncAtomicInt16
import std.sync.AtomicInt32 as SyncAtomicInt32
import std.sync.AtomicInt64 as SyncAtomicInt64
import std.sync.AtomicInt8 as SyncAtomicInt8
import std.sync.AtomicOptionReference as SyncAtomicOptionReference
import std.sync.AtomicReference as SyncAtomicReference
import std.sync.AtomicUInt16 as SyncAtomicUInt16
import std.sync.AtomicUInt32 as SyncAtomicUInt32
import std.sync.AtomicUInt64 as SyncAtomicUInt64
import std.sync.AtomicUInt8 as SyncAtomicUInt8
import stdx.unittest.concurrent.PctSyncKey
import stdx.unittest.concurrent.pctGridDispatchRw
import stdx.unittest.concurrent.pctNextSyncKeyId

/**
 * PCT-instrumented atomics: identical semantics to their `std.sync`
 * counterparts, plus a grid dispatch after every operation. The dispatch
 * lives in this (precompiled) body, so the grid point exists at every
 * optimization level — it does not depend on cross-module inlining.
 *
 * Only the current (non-deprecated) API surface is mirrored; the
 * memory-order overloads are omitted (use the modern forms under
 * `--cj-pct`).
 */

public class AtomicInt8 <: PctSyncKey {
    private let inner: SyncAtomicInt8
    private let pctKey: Int64 = pctNextSyncKeyId()

    public init(val: Int8) {
        inner = SyncAtomicInt8(val)
    }

    public prop syncKeyId: Int64 {
        get() {
            pctKey
        }
    }

    public func load(): Int8 {
        let r = inner.load()
        pctGridDispatchRw(this, false)
        return r
    }

    public func store(val: Int8): Unit {
        inner.store(val)
        pctGridDispatchRw(this, true)
    }

    public func swap(val: Int8): Int8 {
        let r = inner.swap(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func compareAndSwap(old: Int8, new: Int8): Bool {
        let r = inner.compareAndSwap(old, new)
        pctGridDispatchRw(this, r)
        return r
    }

    public func fetchAdd(val: Int8): Int8 {
        let r = inner.fetchAdd(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchSub(val: Int8): Int8 {
        let r = inner.fetchSub(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchAnd(val: Int8): Int8 {
        let r = inner.fetchAnd(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchOr(val: Int8): Int8 {
        let r = inner.fetchOr(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchXor(val: Int8): Int8 {
        let r = inner.fetchXor(val)
        pctGridDispatchRw(this, true)
        return r
    }
}

public class AtomicInt16 <: PctSyncKey {
    private let inner: SyncAtomicInt16
    private let pctKey: Int64 = pctNextSyncKeyId()

    public init(val: Int16) {
        inner = SyncAtomicInt16(val)
    }

    public prop syncKeyId: Int64 {
        get() {
            pctKey
        }
    }

    public func load(): Int16 {
        let r = inner.load()
        pctGridDispatchRw(this, false)
        return r
    }

    public func store(val: Int16): Unit {
        inner.store(val)
        pctGridDispatchRw(this, true)
    }

    public func swap(val: Int16): Int16 {
        let r = inner.swap(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func compareAndSwap(old: Int16, new: Int16): Bool {
        let r = inner.compareAndSwap(old, new)
        pctGridDispatchRw(this, r)
        return r
    }

    public func fetchAdd(val: Int16): Int16 {
        let r = inner.fetchAdd(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchSub(val: Int16): Int16 {
        let r = inner.fetchSub(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchAnd(val: Int16): Int16 {
        let r = inner.fetchAnd(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchOr(val: Int16): Int16 {
        let r = inner.fetchOr(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchXor(val: Int16): Int16 {
        let r = inner.fetchXor(val)
        pctGridDispatchRw(this, true)
        return r
    }
}

public class AtomicInt32 <: PctSyncKey {
    private let inner: SyncAtomicInt32
    private let pctKey: Int64 = pctNextSyncKeyId()

    public init(val: Int32) {
        inner = SyncAtomicInt32(val)
    }

    public prop syncKeyId: Int64 {
        get() {
            pctKey
        }
    }

    public func load(): Int32 {
        let r = inner.load()
        pctGridDispatchRw(this, false)
        return r
    }

    public func store(val: Int32): Unit {
        inner.store(val)
        pctGridDispatchRw(this, true)
    }

    public func swap(val: Int32): Int32 {
        let r = inner.swap(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func compareAndSwap(old: Int32, new: Int32): Bool {
        let r = inner.compareAndSwap(old, new)
        pctGridDispatchRw(this, r)
        return r
    }

    public func fetchAdd(val: Int32): Int32 {
        let r = inner.fetchAdd(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchSub(val: Int32): Int32 {
        let r = inner.fetchSub(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchAnd(val: Int32): Int32 {
        let r = inner.fetchAnd(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchOr(val: Int32): Int32 {
        let r = inner.fetchOr(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchXor(val: Int32): Int32 {
        let r = inner.fetchXor(val)
        pctGridDispatchRw(this, true)
        return r
    }
}

public class AtomicInt64 <: PctSyncKey {
    private let inner: SyncAtomicInt64
    private let pctKey: Int64 = pctNextSyncKeyId()

    public init(val: Int64) {
        inner = SyncAtomicInt64(val)
    }

    public prop syncKeyId: Int64 {
        get() {
            pctKey
        }
    }

    public func load(): Int64 {
        let r = inner.load()
        pctGridDispatchRw(this, false)
        return r
    }

    public func store(val: Int64): Unit {
        inner.store(val)
        pctGridDispatchRw(this, true)
    }

    public func swap(val: Int64): Int64 {
        let r = inner.swap(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func compareAndSwap(old: Int64, new: Int64): Bool {
        let r = inner.compareAndSwap(old, new)
        pctGridDispatchRw(this, r)
        return r
    }

    public func fetchAdd(val: Int64): Int64 {
        let r = inner.fetchAdd(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchSub(val: Int64): Int64 {
        let r = inner.fetchSub(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchAnd(val: Int64): Int64 {
        let r = inner.fetchAnd(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchOr(val: Int64): Int64 {
        let r = inner.fetchOr(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchXor(val: Int64): Int64 {
        let r = inner.fetchXor(val)
        pctGridDispatchRw(this, true)
        return r
    }
}

public class AtomicUInt8 <: PctSyncKey {
    private let inner: SyncAtomicUInt8
    private let pctKey: Int64 = pctNextSyncKeyId()

    public init(val: UInt8) {
        inner = SyncAtomicUInt8(val)
    }

    public prop syncKeyId: Int64 {
        get() {
            pctKey
        }
    }

    public func load(): UInt8 {
        let r = inner.load()
        pctGridDispatchRw(this, false)
        return r
    }

    public func store(val: UInt8): Unit {
        inner.store(val)
        pctGridDispatchRw(this, true)
    }

    public func swap(val: UInt8): UInt8 {
        let r = inner.swap(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func compareAndSwap(old: UInt8, new: UInt8): Bool {
        let r = inner.compareAndSwap(old, new)
        pctGridDispatchRw(this, r)
        return r
    }

    public func fetchAdd(val: UInt8): UInt8 {
        let r = inner.fetchAdd(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchSub(val: UInt8): UInt8 {
        let r = inner.fetchSub(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchAnd(val: UInt8): UInt8 {
        let r = inner.fetchAnd(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchOr(val: UInt8): UInt8 {
        let r = inner.fetchOr(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchXor(val: UInt8): UInt8 {
        let r = inner.fetchXor(val)
        pctGridDispatchRw(this, true)
        return r
    }
}

public class AtomicUInt16 <: PctSyncKey {
    private let inner: SyncAtomicUInt16
    private let pctKey: Int64 = pctNextSyncKeyId()

    public init(val: UInt16) {
        inner = SyncAtomicUInt16(val)
    }

    public prop syncKeyId: Int64 {
        get() {
            pctKey
        }
    }

    public func load(): UInt16 {
        let r = inner.load()
        pctGridDispatchRw(this, false)
        return r
    }

    public func store(val: UInt16): Unit {
        inner.store(val)
        pctGridDispatchRw(this, true)
    }

    public func swap(val: UInt16): UInt16 {
        let r = inner.swap(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func compareAndSwap(old: UInt16, new: UInt16): Bool {
        let r = inner.compareAndSwap(old, new)
        pctGridDispatchRw(this, r)
        return r
    }

    public func fetchAdd(val: UInt16): UInt16 {
        let r = inner.fetchAdd(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchSub(val: UInt16): UInt16 {
        let r = inner.fetchSub(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchAnd(val: UInt16): UInt16 {
        let r = inner.fetchAnd(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchOr(val: UInt16): UInt16 {
        let r = inner.fetchOr(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchXor(val: UInt16): UInt16 {
        let r = inner.fetchXor(val)
        pctGridDispatchRw(this, true)
        return r
    }
}

public class AtomicUInt32 <: PctSyncKey {
    private let inner: SyncAtomicUInt32
    private let pctKey: Int64 = pctNextSyncKeyId()

    public init(val: UInt32) {
        inner = SyncAtomicUInt32(val)
    }

    public prop syncKeyId: Int64 {
        get() {
            pctKey
        }
    }

    public func load(): UInt32 {
        let r = inner.load()
        pctGridDispatchRw(this, false)
        return r
    }

    public func store(val: UInt32): Unit {
        inner.store(val)
        pctGridDispatchRw(this, true)
    }

    public func swap(val: UInt32): UInt32 {
        let r = inner.swap(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func compareAndSwap(old: UInt32, new: UInt32): Bool {
        let r = inner.compareAndSwap(old, new)
        pctGridDispatchRw(this, r)
        return r
    }

    public func fetchAdd(val: UInt32): UInt32 {
        let r = inner.fetchAdd(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchSub(val: UInt32): UInt32 {
        let r = inner.fetchSub(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchAnd(val: UInt32): UInt32 {
        let r = inner.fetchAnd(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchOr(val: UInt32): UInt32 {
        let r = inner.fetchOr(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchXor(val: UInt32): UInt32 {
        let r = inner.fetchXor(val)
        pctGridDispatchRw(this, true)
        return r
    }
}

public class AtomicUInt64 <: PctSyncKey {
    private let inner: SyncAtomicUInt64
    private let pctKey: Int64 = pctNextSyncKeyId()

    public init(val: UInt64) {
        inner = SyncAtomicUInt64(val)
    }

    public prop syncKeyId: Int64 {
        get() {
            pctKey
        }
    }

    public func load(): UInt64 {
        let r = inner.load()
        pctGridDispatchRw(this, false)
        return r
    }

    public func store(val: UInt64): Unit {
        inner.store(val)
        pctGridDispatchRw(this, true)
    }

    public func swap(val: UInt64): UInt64 {
        let r = inner.swap(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func compareAndSwap(old: UInt64, new: UInt64): Bool {
        let r = inner.compareAndSwap(old, new)
        pctGridDispatchRw(this, r)
        return r
    }

    public func fetchAdd(val: UInt64): UInt64 {
        let r = inner.fetchAdd(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchSub(val: UInt64): UInt64 {
        let r = inner.fetchSub(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchAnd(val: UInt64): UInt64 {
        let r = inner.fetchAnd(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchOr(val: UInt64): UInt64 {
        let r = inner.fetchOr(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func fetchXor(val: UInt64): UInt64 {
        let r = inner.fetchXor(val)
        pctGridDispatchRw(this, true)
        return r
    }
}

public class AtomicBool <: PctSyncKey {
    private let inner: SyncAtomicBool
    private let pctKey: Int64 = pctNextSyncKeyId()

    public init(val: Bool) {
        inner = SyncAtomicBool(val)
    }

    public prop syncKeyId: Int64 {
        get() {
            pctKey
        }
    }

    public func load(): Bool {
        let r = inner.load()
        pctGridDispatchRw(this, false)
        return r
    }

    public func store(val: Bool): Unit {
        inner.store(val)
        pctGridDispatchRw(this, true)
    }

    public func swap(val: Bool): Bool {
        let r = inner.swap(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func compareAndSwap(old: Bool, new: Bool): Bool {
        let r = inner.compareAndSwap(old, new)
        pctGridDispatchRw(this, r)
        return r
    }
}

public class AtomicReference<T> <: PctSyncKey where T <: Object {
    private let inner: SyncAtomicReference<T>
    private let pctKey: Int64 = pctNextSyncKeyId()

    public init(val: T) {
        inner = SyncAtomicReference<T>(val)
    }

    public prop syncKeyId: Int64 {
        get() {
            pctKey
        }
    }

    public func load(): T {
        let r = inner.load()
        pctGridDispatchRw(this, false)
        return r
    }

    public func store(val: T): Unit {
        inner.store(val)
        pctGridDispatchRw(this, true)
    }

    public func swap(val: T): T {
        let r = inner.swap(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func compareAndSwap(old: T, new: T): Bool {
        let r = inner.compareAndSwap(old, new)
        pctGridDispatchRw(this, r)
        return r
    }
}

public class AtomicOptionReference<T> <: PctSyncKey where T <: Object {
    private let inner: SyncAtomicOptionReference<T>
    private let pctKey: Int64 = pctNextSyncKeyId()

    public init() {
        inner = SyncAtomicOptionReference<T>()
    }

    public init(val: Option<T>) {
        inner = SyncAtomicOptionReference<T>(val)
    }

    public prop syncKeyId: Int64 {
        get() {
            pctKey
        }
    }

    public func load(): Option<T> {
        let r = inner.load()
        pctGridDispatchRw(this, false)
        return r
    }

    public func store(val: Option<T>): Unit {
        inner.store(val)
        pctGridDispatchRw(this, true)
    }

    public func swap(val: Option<T>): Option<T> {
        let r = inner.swap(val)
        pctGridDispatchRw(this, true)
        return r
    }

    public func compareAndSwap(old: Option<T>, new: Option<T>): Bool {
        let r = inner.compareAndSwap(old, new)
        pctGridDispatchRw(this, r)
        return r
    }
}
