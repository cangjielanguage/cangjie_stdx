/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source code is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

import std.collection.ArrayList
import std.collection.HashMap

/**
 * The per-exploration mtrace collector: the bridge between the per-thread
 * event buffers and the DPOR segments.
 *
 * One collector serves every window of one DPOR exploration: the
 * GC-move translation map MUST persist across windows — objects that
 * survive between schedules (the scenario's state, the sync primitives)
 * keep moving, and the canonical (never-moved) address is the join key
 * the race reporter correlates segment accesses by.
 *
 * `collectSegment` runs at every decision point, on the deciding actor's
 * thread, under the engine lock and inside a suppressed region: the
 * global GC stream is folded into the translation map first (a move chain
 * a -> b -> c collapses to the single entry c -> a at write time, so the
 * lookup is one hop per chain), then the thread's own events drain and
 * every access address is canonicalized through the map. The returned
 * array is the closing segment's memory traffic — exactly the accesses
 * of the user code that ran inside the segment (the suppression brackets
 * keep the framework's own traffic out of the buffers). Without an
 * mtrace runtime everything here is a no-op and segments carry no
 * accesses; the race reporter (dpor_race_pair.cj) then simply has nothing to
 * analyze.
 */
internal class DporTraceCollector {
    // moved-to -> canonical (pre-move) address; grows monotonically over
    // the whole exploration (moves are never un-done; a stale entry for a
    // recycled address is impossible while the allocation lives, and dead
    // addresses never collide with fresh ones under the moving GC).
    private let moveMap = HashMap<UInt64, UInt64>()

    /** The canonical address of `addr` (one hop per collapsed chain). */
    internal func translate(addr: UInt64): UInt64 {
        var a = addr
        while (moveMap.contains(a)) {
            a = moveMap.get(a).getOrThrow() // cjlint-ignore !G.ERR.03 invariant-guarded extraction: a preceding isNone()/contains() gate (or the ScenarioBuilder contract, see comment) guarantees Some here; None would be a framework bug where throwing is the intended behavior
        }
        return a
    }

    /**
     * Drain the GC stream and this thread's events; canonicalize access
     * addresses. Returns the closing segment's events (empty without an
     * mtrace runtime).
     */
    internal func collectSegment(): Array<MtraceEvent> {
        if (!isInitialized()) {
            return []
        }
        // Fold GC moves first: MOVE carries to = pc, from = addr.
        while (true) {
            let moves = drainGc()
            if (moves.size == 0) {
                break
            }
            for (m in moves) {
                if (m.kind == MtraceKind.MOVE) {
                    moveMap.add(m.pc, translate(m.addr))
                }
            }
        }
        // Own events: canonicalize access addresses (ALLOC/SPAWN/markers
        // carry identities, not heap addresses — no translation).
        let evs = drainOwn()
        if (evs.size == 0) {
            return []
        }
        let out = ArrayList<MtraceEvent>()
        for (e in evs) {
            if (e.kind == MtraceKind.READ || e.kind == MtraceKind.WRITE ||
                e.kind == MtraceKind.RANGE_READ || e.kind == MtraceKind.RANGE_WRITE) {
                out.add(MtraceEvent(pc: e.pc, addr: translate(e.addr), size: e.size, kind: e.kind, fs: e.fs))
            } else {
                out.add(e)
            }
        }
        return out.toArray()
    }
}
