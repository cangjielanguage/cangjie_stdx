/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

import std.sync.AtomicInt64

/**
 * The compiler/wrapper ABI layer of the PCT scheduler.
 *
 * Everything in this file is the stable entry surface for code compiled with
 * `--cj-pct` and for the `stdx.unittest.sync` wrappers: the package-level
 * active-iteration reference plus the dispatch functions the compiler emits
 * calls to (and the wrappers call directly). All of them absorb into the
 * active coordinator and are no-ops in binaries where no scenario is
 * running. The dispatch functions perform no policy of their own — they
 * exist to route, so that the coordinator (pct_coordinator.cj) owns all
 * filtering and all decisions.
 *
 * Visibility mirrors the audience: `pctMarkInstrumented` is public (the
 * compiler implicitly imports it into every `--cj-pct` compilation), the
 * mirror seam and the sleep-reroute twins are protected (module-internal
 * infrastructure: the stdx.unittest.sync wrappers and the link-time
 * reroute targets), and the package-internal entries are the engine's
 * own (the active-iteration reference and its setter, the sync-key
 * counter, the future-wait gate).
 *
 * Every entry that can fire from INSIDE an actor operation brackets its
 * coordinator traffic with mtrace suppression (suppressBegin/end): the
 * coordinator and scheduler run on the calling actor's thread, and their
 * own field traffic would otherwise be recorded into the very segment the
 * decision closes — the DPOR race reporter would see the framework racing
 * with itself. The brackets are inert no-ops (no mtrace runtime exists —
 * see mtrace_ffi.cj).
 *
 * This package is precompiled WITHOUT `--cj-pct`, so the framework's own
 * synchronization never re-enters the dispatch — instrumentation applies
 * only to user-binary code (the compilation-boundary invariant the
 * coordinator's lock discipline relies on).
 */

// The active PCT iteration (set after a successful activate(); the
// dispatch entry points route through this reference).
// Internal (not private): the window lifecycle sets it and the entries in
// this file read it, across files.
internal var pctActiveCoord: ?PctCoordinator = None // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics

// Set by the compiler-emitted marker call at the entry of every --cj-pct
// executable (before user code runs); consulted by activate().
internal var pctInstrumentedBinary = false // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics

/**
 * Compiler-emitted marker: this binary was compiled with `--cj-pct`.
 * Called once at the executable entry; reserved for the compiler and the
 * unittest infrastructure; not a general-purpose API.
 */
public func pctMarkInstrumented(): Unit {
    pctInstrumentedBinary = true
}

// The process-wide sync-key ID source: a monotonically increasing
// counter, NEVER reset (absolute IDs stay globally unique for the
// process lifetime — no window can ever confuse a reused object with a
// fresh one, so even the cross-window snapshot layer is collision-free).
// Drawn once per `stdx.unittest.sync` wrapper construction; the DPOR
// driver snapshots the counter around each schedule's setup to derive
// window-stable logical key identities (the offset model — see
// [[PctSyncKey]] and DporScheduler's key classification).
internal let PCT_SYNC_KEY_ID_COUNTER = AtomicInt64(0) // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics

/**
 * A logical identity for sync objects, implemented by every
 * `stdx.unittest.sync` wrapper (the DPOR note keys): each wrapper draws a
 * process-unique ID from [[pctNextSyncKeyId]] at construction. The DPOR
 * snapshot layer (sleep sets, the reopen coverage check) uses the ID's
 * window-relative offset to give fresh-state-per-schedule scenarios —
 * the stateless integration contract — stable cross-schedule key
 * identity: the k-th state-phase sync object of one schedule is the
 * same logical object as the k-th of any other. Everything within a
 * single window (the race scan, the wait-for graph, the gate flips)
 * keeps exact object identity; the ID is only consulted by the
 * cross-window machinery. Keys without an ID (futures, raw `std.sync`
 * objects from uninstrumented compilation units) match by identity
 * alone. Reserved for the unittest infrastructure; not a general-purpose
 * API.
 */
protected interface PctSyncKey {
    /** The object's process-unique sync-key ID (drawn at construction). */
    prop syncKeyId: Int64
}

/**
 * Draw the next sync-key ID (called by the `stdx.unittest.sync` wrapper
 * constructors). Reserved for the unittest infrastructure; not a
 * general-purpose API.
 */
protected func pctNextSyncKeyId(): Int64 {
    return PCT_SYNC_KEY_ID_COUNTER.fetchAdd(1)
}

/** The counter's current value (the DPOR driver's base and
 * state-boundary snapshots around each schedule's setup). */
internal func pctSyncKeyCounterNow(): Int64 {
    return PCT_SYNC_KEY_ID_COUNTER.load()
}

/**
 * PCT sync wrap entry around the `stdx.unittest.sync` wrappers' fallback
 * and deliberately-unmediated parks (the acquire/condition fallbacks,
 * MultiConditionMonitor.wait, waitUntil's polling loop): called
 * immediately before the real runtime park, `pctSyncExit` immediately
 * after. For a registered actor the enter records the Block + token
 * transfer and the exit is the unblock; non-actor tids and no-scenario
 * callers are absorbed. Reserved for the unittest infrastructure; not a
 * general-purpose API.
 */
protected func pctSyncEnter(): Unit {
    if (let Some(coord) <- pctActiveCoord) {
        suppressBegin()
        try {
            coord.onSyncEnter(Thread.currentThread.id)
        } finally {
            suppressEnd()
        }
    }
}

/**
 * PCT sync wrap exit: the counterpart of `pctSyncEnter` around the
 * `stdx.unittest.sync` wrappers' fallback and deliberately-unmediated
 * parks (the acquire/condition fallbacks, MultiConditionMonitor.wait,
 * waitUntil's polling loop). For a registered actor whose real park was
 * recorded as a Block this is the unblock (re-gate or token claim);
 * non-actor tids and no-scenario callers are absorbed. Reserved for
 * the unittest infrastructure; not a general-purpose API.
 */
protected func pctSyncExit(): Unit {
    if (let Some(coord) <- pctActiveCoord) {
        suppressBegin()
        try {
            coord.onSyncExit(Thread.currentThread.id)
        } finally {
            suppressEnd()
        }
    }
}

/**
 * Whether the calling thread is a registered actor of the active
 * iteration: used by the `stdx.unittest.sync` wrappers to pick the
 * std-delegating vs mediated path of an operation (a non-actor caller
 * gets the exact std semantics — its parks are none of the schedule's
 * business). Absorbed (false) without an active coordinator. Reserved
 * for the unittest infrastructure; not a general-purpose API.
 */
protected func pctCurrentIsActor(): Bool {
    if (let Some(coord) <- pctActiveCoord) {
        suppressBegin()
        try {
            return coord.isRegisteredActorTid(Thread.currentThread.id)
        } finally {
            suppressEnd()
        }
    }
    return false
}

/**
 * Mediated contended acquire (the mediated acquire protocol), called by
 * the `stdx.unittest.sync`
 * wrappers (Mutex.lock, Semaphore.acquire, the ReadWriteLock views): park
 * on the coordinator gate keyed by the wrapper object until the releaser's
 * flip and a token grant, then retry the probe (`probe` must be the same
 * non-blocking try operation the wrapper probed with). The probe runs
 * under the coordinator lock, so an uncontended acquire is taken silently
 * there (no events — and the hold is tracked for the cycle abort's
 * wait-for graph; `semantics` classifies how the key's holders block
 * waiters, see PctAcquireSemantics). Returns true when the acquire was
 * fully handled
 * (the caller now holds the primitive); false when the caller must fall
 * back to the plain bracketed runtime park (non-actor thread, or no
 * active coordinator). Reserved for the unittest infrastructure; not a
 * general-purpose API.
 */
protected func pctMedAcquire(key: Object, probe: () -> Bool, semantics: PctAcquireSemantics): Bool {
    if (let Some(coord) <- pctActiveCoord) {
        suppressBegin()
        try {
            return coord.medAcquire(key, probe, semantics)
        } finally {
            suppressEnd()
        }
    }
    return false
}

/**
 * Mediated mutex unlock (the mediated acquire protocol), called by the
 * `stdx.unittest.sync` Mutex wrapper AFTER `inner.unlock()`: flips
 * mediated waiters on the mutex and, for an actor releaser, is the yield
 * point of locked decision
 * 1 (the releaser parks; the pick grants the token among the flipped
 * waiters and the releaser alike). Unlocks without waiters stay silent.
 * Reserved for the unittest infrastructure; not a general-purpose API.
 */
protected func pctMedUnlock(key: Object): Unit {
    if (let Some(coord) <- pctActiveCoord) {
        suppressBegin()
        try {
            coord.medRelease(key, Unlock)
        } finally {
            suppressEnd()
        }
    }
}

/**
 * Mediated semaphore release (the mediated acquire protocol), called by
 * the `stdx.unittest.sync`
 * Semaphore wrapper AFTER `inner.release()`: see
 * `pctMedUnlock`. Reserved for the unittest infrastructure; not a
 * general-purpose API.
 */
protected func pctMedRelease(key: Object): Unit {
    if (let Some(coord) <- pctActiveCoord) {
        suppressBegin()
        try {
            coord.medRelease(key, PctEventKind.Release)
        } finally {
            suppressEnd()
        }
    }
}

/**
 * Mediated condition wait (the mediated condition-wait protocol), called
 * by the `stdx.unittest.sync`
 * wrappers (Monitor.wait, PctCondition.wait), timed or untimed:
 * `release` drops the inner lock, the caller parks keyed by `condKey`
 * until a notify-side flip and a token grant — or, for a finite
 * `timeout`, until the virtual clock fires its timer (the Timer event;
 * never a wall-clock wake) — then re-acquires via the mediated acquire
 * protocol (`probe` must be the owner lock's non-blocking try operation;
 * a contended re-acquire parks keyed by `lockKey` — the two-stage Mesa
 * re-wait; the timed-out path re-acquires the same way, Mesa semantics).
 * Returns Some(true) when the wait completed by a notify, Some(false)
 * when it timed out (the lock is re-held in both cases), and None when
 * the caller must fall back to the plain bracketed runtime wait.
 * Reserved for the unittest infrastructure; not a general-purpose API.
 */
protected func pctCondWait(condKey: Object, lockKey: Object, release: () -> Unit, probe: () -> Bool,
    timeout!: Duration = Duration.Max): ?Bool {
    if (let Some(coord) <- pctActiveCoord) {
        suppressBegin()
        try {
            return coord.medCondWait(condKey, lockKey, release, probe, timeout: timeout)
        } finally {
            suppressEnd()
        }
    }
    return None
}

/**
 * A PCT actor's virtual sleep: the compiler reroutes the SLEEP intrinsic
 * in `--cj-pct`-compiled code here (passing the sleep's nanoseconds).
 * With an active coordinator and a PCT-actor caller the sleep is fully
 * simulated — arm a virtual timer, park on the coordinator gate, return
 * when the clock fires — so sleep expiry is a deterministic scheduling
 * decision (the Timer event). Everything else (no scenario, non-actor
 * thread) takes the real sleep: unmanaged time is none of the schedule's
 * business. Reserved for the compiler and the unittest infrastructure;
 * not a general-purpose API.
 */
protected func pctSleep(nanos: Int64): Unit {
    if (let Some(coord) <- pctActiveCoord) {
        suppressBegin()
        var mediated = false
        try {
            mediated = coord.medSleep(nanos)
        } finally {
            suppressEnd()
        }
        if (mediated) {
            return
        }
    }
    if (nanos == Int64.Max) {
        sleep(Duration.Max)
        return
    }
    sleep(Duration.nanosecond * nanos)
}

/**
 * The sleep reroute's call-target twin of `pctSleep`: same signature as
 * std.core's `sleep`, so the compiler can redirect `--cj-pct`-compiled
 * calls to that symbol here wholesale (codegen swaps the call target by
 * mangled name — the @Frozen body never inlines into flag modules, so
 * the SLEEP-intrinsic reroute alone would never fire). Duration in,
 * identical saturation to std.core sleep (`pctDurationNanos`), then the
 * same mediated-or-real treatment as `pctSleep`. Reserved for the
 * compiler and the unittest infrastructure; not a general-purpose API.
 */
protected func pctSleepDur(dur: Duration): Unit {
    pctSleep(pctDurationNanos(dur))
}

/**
 * The future-wait mediation gate — the single pre-intrinsic entry of the
 * mediated future wait (the gate has no exit; this call is the only
 * coordinator touchpoint): carries the future object and the wait's
 * timeout (Int64 nanoseconds; Int64.Max — `Future.get()`). A wait whose
 * future has a live registered child owner is mediated — the caller
 * parks on its coordinator gate right here (a finite timeout arms a
 * virtual timer; the expiry is the Timer event, a deterministic
 * decision) and the return value is the budget the wrapped intrinsic
 * may still consume: 1ns when the park ended by a fired timer, the full
 * timeout otherwise (the future is complete by construction). A future
 * with no live registered owner is REJECTED: `PctExternalWaitError` is
 * thrown (and the failure recorded for the report) — such a join has no
 * flip source and could never be mediated. Non-actors and no-scenario
 * callers pass the timeout through unchanged. A retained engine-side
 * entry, currently unreachable: the compiler emits no future-wait gate.
 * Reserved for the compiler and the unittest infrastructure; not a
 * general-purpose API.
 */
internal func pctFutureGate(f: Object, timeout: Int64): Int64 {
    if (let Some(coord) <- pctActiveCoord) {
        suppressBegin()
        try {
            return coord.futureGate(Thread.currentThread.id, f, timeout)
        } finally {
            suppressEnd()
        }
    }
    return timeout
}

/** Duration -> logical nanoseconds, with the sentinels preserved:
 * `Duration.Max` maps to Int64.Max (untimed), anything at or below zero
 * maps to 0 (the deadline has passed — fires at the next quiescence),
 * and out-of-range values saturate rather than throw. */
internal func pctDurationNanos(d: Duration): Int64 {
    if (d == Duration.Max) {
        return Int64.Max
    }
    if (d <= Duration.Zero) {
        return 0
    }
    return d.toNanoseconds()
}

/**
 * Mediated condition notify (the mediated condition-wait protocol),
 * called by the wrappers AFTER `inner.notify()`: flips a single mediated
 * waiter on the condition (a notify without waiters stays silent) and,
 * for an actor notifier, is the yield point (a `Notify` event).
 * Reserved for the unittest infrastructure; not a general-purpose API.
 */
protected func pctMedNotify(condKey: Object): Unit {
    if (let Some(coord) <- pctActiveCoord) {
        suppressBegin()
        try {
            coord.medRelease(condKey, Notify, maxFlips: 1)
        } finally {
            suppressEnd()
        }
    }
}

/**
 * Mediated condition notifyAll (the mediated condition-wait protocol),
 * called by the wrappers AFTER
 * `inner.notifyAll()`: flips every mediated waiter on the condition (one
 * yield decision covers the batch; a `NotifyAll` event). Reserved for the
 * unittest infrastructure; not a general-purpose API.
 */
protected func pctMedNotifyAll(condKey: Object): Unit {
    if (let Some(coord) <- pctActiveCoord) {
        suppressBegin()
        try {
            coord.medRelease(condKey, NotifyAll)
        } finally {
            suppressEnd()
        }
    }
}

/**
 * Classified grid check: called by the `stdx.unittest.sync` atomic
 * wrappers after every atomic operation in `--cj-pct`-compiled code
 * (the wrappers pass the atomic object as the sync key — the identity
 * of the just-completed operation for the scheduler's dependency
 * bookkeeping; PCT ignores it), carrying the
 * operation's access class: `write == false` for pure reads (loads,
 * failed compare-and-swaps), `true` for writes (stores, swaps,
 * read-modify-writes, successful compare-and-swaps). The DPOR oracle
 * lets two reads of the same key commute; PCT ignores the class.
 * Absorbs into the active coordinator (which reads the caller's thread
 * id and performs all filtering itself), and is a cheap no-op in
 * binaries where no scenario is running. Reserved for the compiler and
 * the unittest infrastructure; not a general-purpose API.
 */
protected func pctGridDispatchRw(key: Object, write: Bool): Unit {
    if (let Some(coord) <- pctActiveCoord) {
        suppressBegin()
        try {
            coord.onGridPointRw(key, write)
        } finally {
            suppressEnd()
        }
    }
}

/** Set the active iteration (after a successful activate()). */
internal func pctSetCurrentIteration(coord: ?PctCoordinator): Unit {
    pctActiveCoord = coord
}
