/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

internal package stdx.unittest.sync

import std.sync.Condition
import std.sync.Lock
import std.sync.ReadWriteLock as SyncReadWriteLock
import std.sync.UniqueLock
import stdx.unittest.concurrent.PctAcquireSemantics
import stdx.unittest.concurrent.PctSyncKey
import stdx.unittest.concurrent.pctGridDispatchRw
import stdx.unittest.concurrent.pctMedAcquire
import stdx.unittest.concurrent.pctMedUnlock
import stdx.unittest.concurrent.pctNextSyncKeyId
import stdx.unittest.concurrent.pctSyncEnter
import stdx.unittest.concurrent.pctSyncExit

/**
 * The shared mediated-traffic key of a ReadWriteLock's two views:
 * one object per wrapper carrying a PCT sync-key ID (see PctSyncKey), so
 * the DPOR snapshot layer matches the lock's traffic across schedules
 * by logical identity.
 */
private class PctRwLockKey <: PctSyncKey {
    private let pctKey: Int64 = pctNextSyncKeyId()

    public prop syncKeyId: Int64 {
        get() {
            pctKey
        }
    }
}

/**
 * PCT-instrumented `ReadWriteLock`: both lock views key their mediated
 * traffic on one shared key, so any read or write
 * `unlock` flips every lock waiter — their retry probes sort read/write
 * eligibility (a reader proceeds when no writer holds; a writer when
 * nobody holds). Conditions obtained from the write lock mediate their
 * waits with the write lock's release/re-acquire (the mediated
 * condition-wait protocol). The
 * views' `tryLock`s dispatch their outcomes through the classified grid
 * check on the same shared key (success = write-class, failure =
 * read-class). Non-actor threads take the runtime park directly,
 * untracked.
 */
public class ReadWriteLock {
    private let inner: SyncReadWriteLock
    private let lockKey: PctRwLockKey
    private let readView: ReadLockView
    private let writeView: WriteLockView

    public init(fair!: Bool = false) {
        inner = SyncReadWriteLock(fair: fair)
        lockKey = PctRwLockKey()
        readView = ReadLockView(inner.readLock, lockKey)
        writeView = WriteLockView(inner.writeLock, lockKey)
    }

    public prop readLock: Lock {
        get() { // cjlint-ignore !G.ITF.04 std.sync API-compatibility mirror: this signature mirrors the corresponding std.sync API (interface-typed by design); the compiler remaps std.sync imports onto this package
            readView
        }
    }

    public prop writeLock: UniqueLock {
        get() { // cjlint-ignore !G.ITF.04 std.sync API-compatibility mirror: this signature mirrors the corresponding std.sync API (interface-typed by design); the compiler remaps std.sync imports onto this package
            writeView
        }
    }

    public func isFair(): Bool {
        inner.isFair()
    }
}

class ReadLockView <: Lock {
    ReadLockView(private let inner: Lock, private let key: Object) {} // cjlint-ignore !G.ITF.04 std.sync API-compatibility mirror: this signature mirrors the corresponding std.sync API (interface-typed by design); the compiler remaps std.sync imports onto this package

    public func lock(): Unit {
        if (!pctMedAcquire(key, { => inner.tryLock() }, PctAcquireSemantics.AllHolders)) {
            pctSyncEnter()
            inner.lock()
            pctSyncExit()
        }
    }

    public func tryLock(): Bool {
        let ok = inner.tryLock()
        pctGridDispatchRw(key, ok)
        return ok
    }

    public func unlock(): Unit {
        inner.unlock()
        pctMedUnlock(key)
    }
}

class WriteLockView <: UniqueLock {
    WriteLockView(private let inner: UniqueLock, private let key: Object) {} // cjlint-ignore !G.ITF.04 std.sync API-compatibility mirror: this signature mirrors the corresponding std.sync API (interface-typed by design); the compiler remaps std.sync imports onto this package

    public func lock(): Unit {
        if (!pctMedAcquire(key, { => inner.tryLock() }, PctAcquireSemantics.AllHolders)) {
            pctSyncEnter()
            inner.lock()
            pctSyncExit()
        }
    }

    public func tryLock(): Bool {
        let ok = inner.tryLock()
        pctGridDispatchRw(key, ok)
        return ok
    }

    public func unlock(): Unit {
        inner.unlock()
        pctMedUnlock(key)
    }

    public func condition(): Condition { // cjlint-ignore !G.ITF.04 std.sync API-compatibility mirror: this signature mirrors the corresponding std.sync API (interface-typed by design); the compiler remaps std.sync imports onto this package
        PctCondition(inner.condition(), key, { => inner.unlock() }, { => inner.tryLock() })
    }
}
