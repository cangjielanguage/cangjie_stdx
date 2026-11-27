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
public open class ReentrantMutex <: Lock & PctSyncKey {
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

    // The lock-bearing methods are open so the Monitor subclasses can
    // route them to their own combined lock+condition primitives: std's
    // Monitor is one native object, the mirror composes std primitives
    // (see Monitor's class comment), and the overriding keeps every
    // acquisition on the primitive that owns the condition queue.
    public open func lock(): Unit {
        if (!pctMedAcquire(this, { => inner.tryLock() }, PctAcquireSemantics.Exclusive)) {
            pctSyncEnter()
            inner.lock()
            pctSyncExit()
        }
    }

    public open func tryLock(): Bool {
        let ok = inner.tryLock()
        pctGridDispatchRw(this, ok)
        return ok
    }

    public open func unlock(): Unit {
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
public class Monitor <: ReentrantMutex {
    // std's Monitor is one native object — the reentrant lock and the
    // condition queue share state — while the mirror composes std
    // primitives. This instance therefore routes every lock-bearing
    // method to its own combined primitive (a SyncMonitor: lock and
    // condition in one); the ReentrantMutex primitive constructed by
    // super() is vestigial here, never used for locking. The subclassing
    // itself mirrors std's hierarchy (Monitor <: ReentrantMutex), so
    // `is`/`as` checks behave identically with and without --cj-pct.
    private let mInner: SyncMonitor
    private let condKey = CondKey()

    public init() {
        super()
        mInner = SyncMonitor()
    }

    public override func lock(): Unit {
        if (!pctMedAcquire(this, { => mInner.tryLock() }, PctAcquireSemantics.Exclusive)) {
            pctSyncEnter()
            mInner.lock()
            pctSyncExit()
        }
    }

    public override func tryLock(): Bool {
        let ok = mInner.tryLock()
        pctGridDispatchRw(this, ok)
        return ok
    }

    public override func unlock(): Unit {
        mInner.unlock()
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
        match (pctCondWait(condKey, this, { => mInner.unlock() }, { => mInner.tryLock() }, timeout: timeout)) {
            case None =>
                // Non-actor thread (or no scenario): the real timed wait.
                if (timeout == Duration.Max) {
                    pctSyncEnter()
                    mInner.wait()
                    pctSyncExit()
                    return true
                }
                pctSyncEnter()
                let r = mInner.wait(timeout: timeout)
                pctSyncExit()
                return r
            // An actor's wait, handled: Some(true) = notified, Some(false)
            // = the virtual deadline passed (the Timer event). The lock is
            // re-held either way (Mesa).
            case Some(notified) => return notified
        }
    }

    public func notify(): Unit {
        mInner.notify()
        pctMedNotify(condKey)
    }

    public func notifyAll(): Unit {
        mInner.notifyAll()
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
public class MultiConditionMonitor <: ReentrantMutex {
    // Like Monitor (see its class comment): the lock-bearing methods
    // route to this instance's own combined primitive, and the
    // ReentrantMutex primitive constructed by super() is vestigial; the
    // subclassing mirrors std's hierarchy so `is`/`as` checks behave
    // identically with and without --cj-pct.
    private let mcInner: SyncMultiConditionMonitor

    public init() {
        super()
        mcInner = SyncMultiConditionMonitor()
    }

    public override func lock(): Unit {
        if (!pctMedAcquire(this, { => mcInner.tryLock() }, PctAcquireSemantics.Exclusive)) {
            pctSyncEnter()
            mcInner.lock()
            pctSyncExit()
        }
    }

    public override func tryLock(): Bool {
        let ok = mcInner.tryLock()
        pctGridDispatchRw(this, ok)
        return ok
    }

    public override func unlock(): Unit {
        mcInner.unlock()
        pctMedUnlock(this)
    }

    public func newCondition(): ConditionID {
        mcInner.newCondition()
    }

    public func wait(condID: ConditionID, timeout!: Duration = Duration.Max): Bool {
        pctSyncEnter()
        let r = mcInner.wait(condID, timeout: timeout)
        pctSyncExit()
        return r
    }

    public func notify(condID: ConditionID): Unit {
        mcInner.notify(condID)
    }

    public func notifyAll(condID: ConditionID): Unit {
        mcInner.notifyAll(condID)
    }
}
