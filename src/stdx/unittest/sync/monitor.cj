/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

internal package stdx.unittest.sync

import std.sync.ConditionID
import std.sync.Lock
import std.sync.Monitor as SyncMonitor
import std.sync.MultiConditionMonitor as SyncMultiConditionMonitor
import std.sync.ReentrantMutex as SyncReentrantMutex
import stdx.unittest.concurrent.PctAcquireSemantics
import stdx.unittest.concurrent.PctSyncKey
import stdx.unittest.concurrent.pctCondWait
import stdx.unittest.concurrent.pctGridDispatchRw
import stdx.unittest.concurrent.pctMedAcquire
import stdx.unittest.concurrent.pctMedNotify
import stdx.unittest.concurrent.pctMedNotifyAll
import stdx.unittest.concurrent.pctMedUnlock
import stdx.unittest.concurrent.pctNextSyncKeyId
import stdx.unittest.concurrent.pctSyncEnter
import stdx.unittest.concurrent.pctSyncExit

/** Identity for a Monitor's implicit condition queue (the mediated
 * condition-wait protocol); carries a PCT sync-key ID (see PctSyncKey)
 * so the DPOR snapshot layer matches the queue across schedules by
 * logical identity. */
private class CondKey <: PctSyncKey {
    private let pctKey: Int64 = pctNextSyncKeyId()

    public prop syncKeyId: Int64 {
        get() {
            pctKey
        }
    }
}

/**
 * PCT-instrumented `ReentrantMutex` (deprecated, like its std.sync
 * counterpart): the `tryLock` probe keeps uncontended (including
 * same-thread reentrant) acquisitions invisible; contended acquisitions
 * by a PCT actor are mediated (park keyed by this wrapper until the
 * releaser's flip and a grant), other threads take the runtime park
 * directly, untracked. `unlock` is the yield point when waiters exist.
 * The public `tryLock` dispatches its outcome through the classified
 * grid check (success = write-class — the primitive's state changed;
 * failure = read-class — a pure state observation).
 */
@Deprecated[message: "Use `public class Mutex` instead."]
public class ReentrantMutex <: Lock & PctSyncKey {
    private let inner: SyncReentrantMutex
    private let pctKey: Int64 = pctNextSyncKeyId()

    public init() {
        inner = SyncReentrantMutex()
    }

    public prop syncKeyId: Int64 {
        get() {
            pctKey
        }
    }

    public func lock(): Unit {
        if (!pctMedAcquire(this, { => inner.tryLock() }, PctAcquireSemantics.Exclusive)) {
            pctSyncEnter()
            inner.lock()
            pctSyncExit()
        }
    }

    public func tryLock(): Bool {
        let ok = inner.tryLock()
        pctGridDispatchRw(this, ok)
        return ok
    }

    public func unlock(): Unit {
        inner.unlock()
        pctMedUnlock(this)
    }
}

/**
 * PCT-instrumented `Monitor`: locking is mediated like `Mutex`
 * (lock-waiters park keyed by this wrapper). The single condition queue
 * gets its own key (a `CondKey`), so `unlock` only flips lock-waiters and
 * `notify`/`notifyAll` only flip condition waiters. An actor's `wait` —
 * timed or not — is the mediated Mesa protocol: release (one level —
 * condition waits are a lock-depth-one protocol), park keyed by the
 * condition, then re-acquire through the mediated acquire loop (a
 * second, lock-keyed `Wait` when contended). A timed wait arms a
 * virtual clock deadline at park entry: expiry fires at quiescence as a
 * deterministic `Timer` event granting the parked actor directly (the
 * wait returns `false` with the lock re-held); a non-positive timeout
 * is rejected up front (std's `IllegalArgumentException`, before any
 * dispatch). The public `tryLock` dispatches its outcome through the
 * classified grid check (success = write-class, failure = read-class).
 * Non-actor threads take the runtime park directly, untracked.
 */
public class Monitor <: Lock & PctSyncKey {
    private let inner: SyncMonitor
    private let pctKey: Int64 = pctNextSyncKeyId()
    private let condKey = CondKey()

    public init() {
        inner = SyncMonitor()
    }

    public prop syncKeyId: Int64 {
        get() {
            pctKey
        }
    }

    public func lock(): Unit {
        if (!pctMedAcquire(this, { => inner.tryLock() }, PctAcquireSemantics.Exclusive)) {
            pctSyncEnter()
            inner.lock()
            pctSyncExit()
        }
    }

    public func tryLock(): Bool {
        let ok = inner.tryLock()
        pctGridDispatchRw(this, ok)
        return ok
    }

    public func unlock(): Unit {
        inner.unlock()
        pctMedUnlock(this)
    }

    /**
     * Wait until notified, releasing the monitor lock while blocked
     * (std.sync `Monitor.wait` semantics, mediated under PCT). Returns
     * whether the wait ended with a notify.
     *
     * @throws IllegalArgumentException if `timeout` is less than or equal
     * to `Duration.Zero`.
     */
    public func wait(timeout!: Duration = Duration.Max): Bool {
        // A non-positive timeout is rejected up front, before any
        // dispatch (std's IllegalArgumentException); Duration.Max (the
        // default) passes naturally.
        if (timeout <= Duration.Zero) {
            throw IllegalArgumentException("Timeout cannot be less than or equal to `Duration.Zero`.")
        }
        match (pctCondWait(condKey, this, { => inner.unlock() }, { => inner.tryLock() }, timeout: timeout)) {
            case None =>
                // Non-actor thread (or no scenario): the real timed wait.
                if (timeout == Duration.Max) {
                    pctSyncEnter()
                    inner.wait()
                    pctSyncExit()
                    return true
                }
                pctSyncEnter()
                let r = inner.wait(timeout: timeout)
                pctSyncExit()
                return r
            // An actor's wait, handled: Some(true) = notified, Some(false)
            // = the virtual deadline passed (the Timer event). The lock is
            // re-held either way (Mesa).
            case Some(notified) => return notified
        }
    }

    public func notify(): Unit {
        inner.notify()
        pctMedNotify(condKey)
    }

    public func notifyAll(): Unit {
        inner.notifyAll()
        pctMedNotifyAll(condKey)
    }
}

/**
 * PCT-instrumented `MultiConditionMonitor` (deprecated, like its std.sync
 * counterpart): locking is mediated like `Mutex`. The per-condition
 * waits and notifies keep the bracketed runtime path: `ConditionID` is
 * opaque outside std.sync (no per-condition key object), and conflating
 * the queues could drop notifications; the deprecated class trades
 * mediation for exact std semantics there. The public `tryLock`
 * dispatches its outcome through the classified grid check (success =
 * write-class, failure = read-class).
 */
@Deprecated[message: "Use `public class Mutex` instead."]
public class MultiConditionMonitor <: Lock & PctSyncKey {
    private let inner: SyncMultiConditionMonitor
    private let pctKey: Int64 = pctNextSyncKeyId()

    public init() {
        inner = SyncMultiConditionMonitor()
    }

    public prop syncKeyId: Int64 {
        get() {
            pctKey
        }
    }

    public func lock(): Unit {
        if (!pctMedAcquire(this, { => inner.tryLock() }, PctAcquireSemantics.Exclusive)) {
            pctSyncEnter()
            inner.lock()
            pctSyncExit()
        }
    }

    public func tryLock(): Bool {
        let ok = inner.tryLock()
        pctGridDispatchRw(this, ok)
        return ok
    }

    public func unlock(): Unit {
        inner.unlock()
        pctMedUnlock(this)
    }

    public func newCondition(): ConditionID {
        inner.newCondition()
    }

    public func wait(condID: ConditionID, timeout!: Duration = Duration.Max): Bool {
        pctSyncEnter()
        let r = inner.wait(condID, timeout: timeout)
        pctSyncExit()
        return r
    }

    public func notify(condID: ConditionID): Unit {
        inner.notify(condID)
    }

    public func notifyAll(condID: ConditionID): Unit {
        inner.notifyAll(condID)
    }
}
