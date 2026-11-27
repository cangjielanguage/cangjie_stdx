/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

import std.sync.AtomicInt64
import std.sync.Mutex

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
 * own (the active-iteration reference and its installer, the sync-key
 * counter, the future-wait gate).
 *
 * Every entry that can fire from INSIDE an actor operation routes
 * through pctRoute below, which brackets its coordinator traffic with
 * mtrace suppression (suppressBegin/end) and runs it in one engine
 * region (pct_engine_lock.cj): the coordinator and scheduler
 * run on the calling actor's thread, and their own field traffic would
 * otherwise be recorded into the very segment the decision closes — the
 * DPOR race reporter would see the framework racing with itself. The
 * brackets are inert no-ops (no mtrace runtime exists — see
 * mtrace_ffi.cj).
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
 * The dispatch entries' shared route: run one coordinator body in a
 * single engine region (pct_engine_lock.cj) under the mtrace-suppression
 * bracket, with the coordinator's failure policy applied to anything the
 * body throws. The parks inside the body own their drains, so the region
 * composes across them — the whole coordinator method runs as ONE
 * region, entered and released here (this is what makes the coordinator
 * bodies plain assume-locked code).
 *
 * The return distinguishes the recorded failure from everything else:
 * Some(the body's value) on success and for every rethrown
 * classification; None exactly when handleException RECORDED a
 * framework-internal failure (surfaced by buildSchedule) — the caller
 * then applies its degraded value. Engine-control aborts (the wait-for
 * cycle abort, the external-wait rejection, the DPOR obstruction
 * recovery) rethrow through handleException and must be allowed to
 * unwind user code; a wrapped user-closure failure (PctUserClosureError)
 * is unwrapped here, so the actor's operation sees its own exception
 * whatever the region nesting on the way out.
 *
 * The finally pairs every suppressBegin with a suppressEnd on every exit
 * path — an unwound entry must never leave the recorder armed. No
 * active-coordinator or actor filtering happens here: the entries own
 * their absorb policy (see pctActiveCoordForActor). Reserved for the
 * unittest infrastructure; not a general-purpose API.
 */
internal func pctRoute<T>(coord: PctCoordinator, body: () -> T): ?T {
    suppressBegin()
    try {
        return Some(pctOnLocked(body))
    } catch (e: PctUserClosureError) {
        // A user closure's own failure (an acquire probe, a condition
        // wait's inner release) reached the dispatch boundary WRAPPED —
        // the brackets wrap it so nested engine regions rethrow it
        // verbatim instead of recording it as a framework failure.
        throw e.inner
    } catch (e: Exception) {
        coord.handleException(e) // rethrows aborts; records the rest
        return None
    } finally {
        suppressEnd()
    }
}

/**
 * The active coordinator iff the calling thread is one of its registered
 * actors — the absorb-family entries' lock-free pre-filter. The grid and
 * the sleep reroute fire for EVERY thread in the process, so a non-actor
 * must absorb before any lock traffic (the engine lock would otherwise
 * be a process-wide serialization point for unrelated threads for the
 * whole window). The own-tid lookup needs no lock by design: a thread's
 * own registration is ordered ahead of its own dispatches (see
 * PctActorTable's single-writer/program-order note), so the answer is
 * correct even while the table grows. This is also pctCurrentIsActor's
 * entire semantics. The release family must NOT use it: a non-actor
 * release is an external event the schedule must observe (the
 * external-release revival). Reserved for the unittest infrastructure;
 * not a general-purpose API.
 */
internal func pctActiveCoordForActor(): ?PctCoordinator {
    if (let Some(coord) <- pctActiveCoord) {
        if (coord.isActorTid(Thread.currentThread.id)) {
            return Some(coord)
        }
    }
    return None
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
    if (let Some(coord) <- pctActiveCoordForActor()) {
        pctRoute(coord, { => coord.onSyncEnter(Thread.currentThread.id) })
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
    if (let Some(coord) <- pctActiveCoordForActor()) {
        pctRoute(coord, { => coord.onSyncExit(Thread.currentThread.id) })
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
    // The lock-free own-tid filter IS this query (see
    // pctActiveCoordForActor) — no lock, no region.
    return pctActiveCoordForActor().isSome()
}

/**
 * Mediated contended acquire (the mediated acquire protocol), called by
 * the `stdx.unittest.sync`
 * wrappers (Mutex.lock, Semaphore.acquire, the ReadWriteLock views): park
 * on the coordinator gate keyed by the wrapper object until the releaser's
 * flip and a token grant, then retry the probe (`probe` must be the same
 * non-blocking try operation the wrapper probed with). The probe runs
 * inside the engine region, so an uncontended acquire is taken silently
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
    if (let Some(coord) <- pctActiveCoordForActor()) {
        return pctRoute(coord, { => coord.medAcquire(key, probe, semantics) }) ?? false
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
    // No actor filter: a non-actor release is an external event the
    // schedule must observe (the external-release revival).
    if (let Some(coord) <- pctActiveCoord) {
        pctRoute(coord, { => coord.medRelease(key, Unlock) })
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
    // No actor filter (see pctMedUnlock): non-actor releases revive.
    if (let Some(coord) <- pctActiveCoord) {
        pctRoute(coord, { => coord.medRelease(key, PctEventKind.Release) })
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
    if (let Some(coord) <- pctActiveCoordForActor()) {
        return pctRoute(coord, { =>
            coord.medCondWait(condKey, lockKey, release, probe, timeout: timeout)
        }) ?? None
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
    // The route returns the mediated verdict; an unhandled sleep (no
    // scenario, a non-actor thread) falls through to the real one.
    var mediated = false
    if (let Some(coord) <- pctActiveCoordForActor()) {
        mediated = pctRoute(coord, { => coord.medSleep(nanos) }) ?? false
    }
    if (mediated) {
        return
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
    if (let Some(coord) <- pctActiveCoordForActor()) {
        return pctRoute(coord, { =>
            coord.futureGate(Thread.currentThread.id, f, timeout)
        }) ?? timeout
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
    // Past the Int64-nanosecond range (~292 years) toNanoseconds()
    // throws ArithmeticException; the contract above promises saturation
    // instead (std's own monitors clamp the same overflow through their
    // MAX_TIMEOUT_NS bound), so an over-range duration becomes an
    // effectively untimed deadline in the virtual clock.
    try {
        return d.toNanoseconds()
    } catch (_: ArithmeticException) {
        return Int64.Max
    }
}

/**
 * Mediated condition notify (the mediated condition-wait protocol),
 * called by the wrappers AFTER `inner.notify()`: flips a single mediated
 * waiter on the condition (a notify without waiters stays silent) and,
 * for an actor notifier, is the yield point (a `Notify` event).
 * Reserved for the unittest infrastructure; not a general-purpose API.
 */
protected func pctMedNotify(condKey: Object): Unit {
    // No actor filter: a non-actor notify flips waiters like a release.
    if (let Some(coord) <- pctActiveCoord) {
        pctRoute(coord, { => coord.medRelease(condKey, Notify, maxFlips: 1) })
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
    // No actor filter (see pctMedNotify).
    if (let Some(coord) <- pctActiveCoord) {
        pctRoute(coord, { => coord.medRelease(condKey, NotifyAll) })
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
    // The hot path: the grid fires for every atomic operation of every
    // thread in the process, so the non-actor absorb must be lock-free
    // (pctActiveCoordForActor).
    if (let Some(coord) <- pctActiveCoordForActor()) {
        pctRoute(coord, { => coord.onGridPointRw(key, write) })
    }
}

// The window-exclusivity guard: installs and clears of the active-iteration
// reference serialize on this mutex, closing activate()'s check-then-act
// race (two concurrent scenario runs can both observe `pctActiveCoord ==
// None` between their activate checks and their installs; the second
// install would then silently overwrite the first — the first window's
// dispatches get tid-filtered into absorption and it can end as a
// near-empty "passing" schedule). Private to this file: the install/clear
// entry below is the only writer, and the dispatch entries only read.
private let pctIterationGuard = Mutex()

/**
 * Install (or clear) the active iteration atomically under the iteration
 * guard. An install (`coord` is `Some`) that finds another iteration still
 * active fails with -3 instead of overwriting it; the clear (`None`)
 * always succeeds — and is issued only by the window whose install
 * succeeded (runWindowInternal's `installed` flag), so a failed install
 * never wipes the winner's reference. The plain reference remains the
 * dispatch hot path's read (benign: actor-thread reads are ordered by
 * the spawn/join edges around the window, and non-actor threads are
 * absorbed either way), but every WRITE goes through here, so
 * overlapping windows can no longer corrupt each other. Reserved for
 * the unittest infrastructure; not a general-purpose API.
 */
internal func pctInstallCurrentIteration(coord: ?PctCoordinator): Int32 {
    pctIterationGuard.lock()
    try {
        match (coord) {
            case Some(_) =>
                if (pctActiveCoord.isSome()) {
                    return -3
                }
                pctActiveCoord = coord
            case None =>
                pctActiveCoord = None
        }
        return 0
    } finally {
        pctIterationGuard.unlock()
    }
}

/**
 * Test support (same-module tests only — re-exposed by the
 * stdx.concurrent_test_util bridge): inject a framework-internal
 * failure into the active iteration through one engine
 * region. The region wrapper must record it, release the lock, and the
 * iteration must fail loudly at buildSchedule — the regression anchor
 * for the lock-leak fix (an internal exception escaping a held
 * engine lock used to strand every later entry, the drain and the
 * schedule build on a mutex nobody would ever release). Returns false
 * when no iteration is active. Reserved for the unittest
 * infrastructure; not a general-purpose API.
 */
protected func pctInjectProtocolFailureForTest(message: String): Bool {
    // No actor filter: the test injects from the main thread (a
    // non-actor), deliberately. The body throws; the route's catch
    // records it (handleException) and returns None, which this entry
    // discards — the contract is "true = a coordinator was active".
    if (let Some(coord) <- pctActiveCoord) {
        pctRoute(coord, { => coord.debugInjectProtocolFailure(message) })
        return true
    }
    return false
}
