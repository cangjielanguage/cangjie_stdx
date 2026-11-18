/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

internal package stdx.unittest.sync

import std.sync.Condition
import std.sync.Mutex as SyncMutex
import std.sync.UniqueLock
import std.time.MonoTime
import stdx.unittest.concurrent.PctAcquireSemantics
import stdx.unittest.concurrent.PctSyncKey
import stdx.unittest.concurrent.pctCondWait
import stdx.unittest.concurrent.pctCurrentIsActor
import stdx.unittest.concurrent.pctGridDispatchRw
import stdx.unittest.concurrent.pctMedAcquire
import stdx.unittest.concurrent.pctMedNotify
import stdx.unittest.concurrent.pctMedNotifyAll
import stdx.unittest.concurrent.pctMedUnlock
import stdx.unittest.concurrent.pctNextSyncKeyId
import stdx.unittest.concurrent.pctSyncEnter
import stdx.unittest.concurrent.pctSyncExit

/**
 * PCT-instrumented `Mutex`: identical semantics to `std.sync.Mutex`, plus
 * scheduling-decision dispatch for PCT. Under the hood this is a
 * composition wrapper: the real lock runs inside precompiled (uninstrumented)
 * std code, so exactly one dispatch brackets the operation.
 *
 * Uncontended acquisitions stay event-invisible: the coordinator probes
 * with the same non-blocking `tryLock` under its own lock and takes the
 * primitive silently there (while recording the hold for the
 * wait-for graph — cycle detection needs actor acquisitions visible).
 * Contended acquisitions by a PCT actor are mediated: the acquirer
 * parks on its coordinator gate keyed by this mutex (a `Wait` event), the
 * holder's `unlock` flips it (an `Unlock` yield-point event, logged only
 * when waiters exist), and the granted waiter retries `tryLock` — for
 * actor-only traffic the wake is a pure scheduling decision that cannot
 * race the schedule. Non-actor threads take the runtime park directly,
 * untracked (the documented detection limitation).
 *
 * Used implicitly: compiling with `--cj-pct` redirects `std.sync` imports
 * to this package (see the compiler's import remap and
 * `stdx.unittest.concurrent`'s PCT coordinator).
 *
 * The public `tryLock` dispatches its outcome through the classified
 * grid check (success = write-class — the primitive's state changed;
 * failure = read-class — a pure state observation), so a probe of
 * contended state participates in the dependency bookkeeping.
 */
public class Mutex <: UniqueLock & PctSyncKey {
    private let inner: SyncMutex
    private let pctKey: Int64 = pctNextSyncKeyId()

    public init() {
        inner = SyncMutex()
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

    public func condition(): Condition { // cjlint-ignore !G.ITF.04 std.sync API-compatibility mirror: this signature mirrors the corresponding std.sync API (interface-typed by design); the compiler remaps std.sync imports onto this package
        PctCondition(inner.condition(), this, { => inner.unlock() }, { => inner.tryLock() })
    }
}

/**
 * PCT-instrumented `Condition` (a wait queue associated with a lock).
 *
 * `wait` — timed or not — by a PCT actor is mediated: the caller
 * releases the owner lock, parks on its coordinator gate keyed by this
 * condition (a `Wait` event subsuming the inner release), and — after
 * the notify-side flip and a grant — re-acquires the owner lock through
 * the mediated acquire protocol (a second, lock-keyed `Wait` when
 * contended: the two-stage Mesa re-wait). A timed wait additionally
 * arms a virtual clock deadline at park entry: expiry fires at
 * quiescence as a deterministic `Timer` event that grants the parked
 * actor directly (the wait then returns `false` with the lock re-held —
 * Mesa holds on the timeout path), so timed parks are fully replayable
 * — no `Block`/`Deadlock` + `Resume` external recovery is involved.
 * A timed wait with a non-positive timeout is rejected up front
 * (std's `IllegalArgumentException`, before any dispatch).
 * `notify`/`notifyAll` flip condition waiters (one / all) and are yield
 * points (`Notify`/`NotifyAll` events, logged only when waiters exist).
 * Non-actor threads take the runtime park directly, untracked (their
 * real timeouts are none of the schedule's business).
 * `waitUntil` checks the lock-held status before the first predicate
 * evaluation (std's rule: an unheld caller gets the
 * `IllegalSynchronizationStateException` without running the
 * predicate). Non-actor callers delegate to the underlying std
 * condition entirely; a PCT actor passes the status check through a
 * raw `inner.notify()` — side-effect-free for a correct caller with no
 * raw inner waiters — and then replicates the std loop structure so
 * that every internal park (not the whole loop) is a scheduling
 * decision: the predicate runs while the caller holds the PCT token,
 * so grid points inside it stay valid. The deadline-carrying
 * `waitUntil(pred, timeout)` overload is the one deliberate residual:
 * its budget spans multiple internal parks and predicate runs, so it
 * stays on the real clock (`MonoTime`) for actors too — inside a
 * scenario it burns wall time by design.
 *
 * Condition waits are a lock-depth-one protocol (like the underlying
 * runtime wait): wait with the owner lock held exactly once.
 */
public class PctCondition <: Condition {
    private let inner: Condition
    private let lockKey: Object
    private let releaseInner: () -> Unit
    private let probeInner: () -> Bool
    private let pctKey: Int64 = pctNextSyncKeyId()

    init(inner: Condition, lockKey: Object, releaseInner: () -> Unit, probeInner: () -> Bool) { // cjlint-ignore !G.ITF.04 std.sync API-compatibility mirror: this signature mirrors the corresponding std.sync API (interface-typed by design); the compiler remaps std.sync imports onto this package
        this.inner = inner
        this.lockKey = lockKey
        this.releaseInner = releaseInner
        this.probeInner = probeInner
    }

    public prop syncKeyId: Int64 {
        get() {
            pctKey
        }
    }

    public func wait(): Unit {
        match (pctCondWait(this, lockKey, releaseInner, probeInner)) {
            case None =>
                // Non-actor thread (or no scenario): the real wait.
                pctSyncEnter()
                inner.wait()
                pctSyncExit()
            case Some(_) => ()
        }
    }

    /**
     * Wait until notified, releasing this lock while blocked (std.sync
     * `Mutex.wait` semantics, mediated under PCT). Returns whether the
     * wait ended with a notify.
     *
     * @throws IllegalArgumentException if `timeout` is less than or equal
     * to `Duration.Zero`.
     */
    public func wait(timeout!: Duration): Bool {
        // A non-positive timeout is rejected up front, before any
        // dispatch (std's IllegalArgumentException).
        if (timeout <= Duration.Zero) {
            throw IllegalArgumentException("Timeout cannot be less than or equal to `Duration.Zero`.")
        }
        match (pctCondWait(this, lockKey, releaseInner, probeInner, timeout: timeout)) {
            case None =>
                // Non-actor thread (or no scenario): the real timed wait.
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

    public func waitUntil(predicate: () -> Bool): Unit {
        if (!pctCurrentIsActor()) {
            inner.waitUntil(predicate) // exact std semantics (status check first)
            return
        }
        // Actor path: the lock-held status check BEFORE the first
        // predicate evaluation, via std's own probe — a raw inner.notify()
        // throws IllegalSynchronizationStateException for an unheld caller
        // and is side-effect-free for a correct one. NEVER pctMedNotify
        // here: it flips mediated waiters (a schedule event). The raw call
        // reaches only raw inner waiters (non-actor threads of a mixed
        // program); waking one is a Mesa-legal spurious wake.
        inner.notify()
        while (!predicate()) {
            wait()
        }
    }

    /**
     * Wait until `predicate` holds, re-checking it after every notify while
     * holding this lock (std.sync `Mutex.waitUntil` semantics, mediated
     * under PCT).
     *
     * @throws IllegalArgumentException if `timeout` is less than or equal
     * to `Duration.Zero`.
     */
    public func waitUntil(predicate: () -> Bool, timeout!: Duration): Bool {
        if (timeout <= Duration.Zero) {
            throw IllegalArgumentException("Timeout cannot be less than or equal to `Duration.Zero`.")
        }
        if (!pctCurrentIsActor()) {
            return inner.waitUntil(predicate, timeout: timeout)
        }
        // Actor path: the status check before the first predicate
        // evaluation (see the untimed overload).
        inner.notify()
        let startTime = MonoTime.now() // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        var spentTime = Duration.Zero // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        while (!predicate()) {
            if (spentTime >= timeout) {
                return false
            }
            pctSyncEnter()
            let success = inner.wait(timeout: timeout - spentTime)
            pctSyncExit()
            if (!success) {
                return false
            }
            spentTime = MonoTime.now() - startTime
        }
        return true
    }

    public func notify(): Unit {
        inner.notify()
        pctMedNotify(this)
    }

    public func notifyAll(): Unit {
        inner.notifyAll()
        pctMedNotifyAll(this)
    }
}
