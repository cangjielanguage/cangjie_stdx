/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

import std.sync.Mutex

/**
 * The engine-global serialization primitive: one lock for the whole PCT/DPOR
 * engine — the coordinator's protocol state, the actor table (whose arrays
 * grow under this lock), the scheduler (its RNG and event log are
 * single-threaded by construction BECAUSE everything runs under this lock),
 * the spawn registrar's state, and the schedule snapshot. ABI dispatches,
 * the runner's lifecycle entries and the registrar's predicate checks all
 * serialize here; a global lock is equivalent to a per-coordinator one
 * because only one window is ever active (pctInstallCurrentIteration
 * guards the install) and stragglers from a finished window absorb by
 * their tid.
 *
 * Regions nest by pass-through, not by counting: [[pctOnLocked]] checks a
 * per-thread in-region marker FIRST and skips the acquisition entirely when
 * the calling thread is already inside a region, so a nested region never
 * adds a hold — the per-thread hold count is always 0 or 1, which is what
 * makes the marker a Bool instead of a depth counter. (std.sync.Mutex is
 * reentrant, but this design never exercises that: the marker is consulted
 * before `lock()`, never after.)
 *
 * Blocking waits run in drain sections ([[pctWithTemporarilyUnlocked]]):
 * the marker drops together with the lock and both are restored after the
 * wait — a parked thread must never leave a stale in-region marker, or a
 * concurrent entry would misclassify itself as nested and run unlocked.
 * The drain is owned by the waits themselves (PctGate.park wraps its
 * blocking wait; the drain monitor and the spawn-registrar notify use the
 * primitive directly), so "never park while holding" is structural rather
 * than a discipline spread across every region body.
 */

/** The engine lock (see the file doc). Touched only by the two functions
 * below — never directly. */
internal let pctEngineLock = Mutex()

/** Per-thread in-region marker: true exactly while the owning thread is
 * inside a pctOnLocked region (and therefore holds pctEngineLock; the
 * drain sections drop the marker with the lock). */
internal let pctEngineInRegion = ThreadLocal<Bool>()

/**
 * Run `f` in one engine region (the engine lock held). A call from a thread
 * already inside a region is a pass-through: the outermost region owns the
 * single hold, so the nested body simply runs — no acquisition, no release,
 * nothing to balance on an exception path. The finally owns the release, so
 * no exception — a framework-internal failure, an engine abort, a user
 * closure's throw — can strand a later entry on a leaked lock (the lock-leak
 * class where an internal failure hung every later dispatch, the drain and
 * the schedule build). Reserved for the unittest infrastructure; not a
 * general-purpose API.
 */
internal func pctOnLocked<T>(f: () -> T): T {
    if (pctEngineInRegion.get() ?? false) {
        return f()
    }
    pctEngineLock.lock()
    pctEngineInRegion.set(Some(true))
    try {
        return f()
    } finally {
        pctEngineInRegion.set(Some(false))
        pctEngineLock.unlock()
    }
}

/**
 * Run `f` with the engine lock fully released — a blocking wait (a gate
 * park's monitor wait, the drain monitor) or a cross-monitor notify that
 * must not happen under the engine lock. The caller must be inside a
 * region; the structural guard below enforces that before any unlock
 * (releasing a lock this thread does not hold is undefined behavior on
 * the platform mutex, not a loud failure — a doc convention alone
 * cannot prevent a future out-of-region call site). The marker is
 * dropped with the lock and restored with it, so the section is
 * invisible to the enclosing region's bookkeeping and an exception out
 * of `f` still leaves the thread in-region with the hold restored.
 * Reserved for the unittest infrastructure; not a general-purpose API.
 */
internal func pctWithTemporarilyUnlocked(f: () -> Unit): Unit {
    if (!(pctEngineInRegion.get() ?? false)) {
        throw Exception("pctWithTemporarilyUnlocked called outside an engine region.")
    }
    pctEngineInRegion.set(Some(false))
    pctEngineLock.unlock()
    try {
        f()
    } finally {
        pctEngineLock.lock()
        pctEngineInRegion.set(Some(true))
    }
}
