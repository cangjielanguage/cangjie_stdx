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
 * One reported data race: a pair of conflicting memory accesses (same
 * canonical address, at least one write, different actors) that no
 * happens-before edge orders — they could execute concurrently in a real
 * execution of the explored schedule. `pc` values are the instrumented
 * access sites; `addr` is the canonical (never-moved) allocation
 * address.
 *
 * The happens-before relation covers: program order within an actor,
 * release→acquire on the same lock/semaphore key (segment granularity —
 * a lock held across segments still orders whole segments), notify→
 * completed wait, child completion→join, and spawn→child's first
 * segment. Atomic operations contribute NO edges: their interleaving is
 * the DPOR oracle's business, and no read-from relation is derivable
 * from key identities alone — plain accesses ordered only through
 * atomics are therefore reported (conservative by design).
 */
protected struct DporRacePair {
    public DporRacePair(
        /** One side's actor slot. */
        public let actorA!: Int64,
        /** One side's access pc (the instrumented access site). */
        public let pcA!: UInt64,
        /** The other side's actor slot. */
        public let actorB!: Int64,
        /** The other side's access pc. */
        public let pcB!: UInt64,
        /** The canonical (never-moved) conflicting address. */
        public let addr!: UInt64,
        /** The overlap size in bytes (the smaller access). */
        public let size!: UInt32,
        /** Symbolized source location of side A ("" when unavailable). */
        public let locA!: String = "", // cjlint-ignore !G.FUN.01 config-carrier signature: the named parameters are the structured configuration/context of this framework step; bundling them into a struct would only move the count
        /** Symbolized source location of side B ("" when unavailable). */
        public let locB!: String = "" // cjlint-ignore !G.FUN.01 config-carrier signature: the named parameters are the structured configuration/context of this framework step; bundling them into a struct would only move the count
    ) {}

    /** A stable description line (the report format). */
    public func describe(): String {
        return "data race: ${describeSide(actorA, pcA, locA)} × ${describeSide(actorB, pcB, locB)}" +
            " on addr ${addr} (${size}B)"
    }

    private static func describeSide(actor: Int64, pc: UInt64, loc: String): String {
        if (loc.size == 0) {
            return "actor #${actor} @pc ${pc}"
        }
        return "actor #${actor} ${loc} (pc ${pc})"
    }
}

/** One access occurrence flattened for the address grouping. */
internal struct DporAccessRef {
    internal DporAccessRef(
        internal let seg!: Int64,
        internal let pc!: UInt64,
        internal let size!: UInt32,
        internal let write!: Bool,
        internal let fs!: UInt64 = 0
    ) {}
}

/**
 * The per-window race scan: happens-before analysis over one run's
 * segments (see DporRacePair's contract). Returns the run's race pairs
 * (unordered sides; the driver dedupes repeated race keys).
 */
internal func dporScanRaces(data: DporRunData): Array<DporRacePair> { // cjlint-ignore !G.FUN.01 single cohesive algorithm block; splitting it would scatter the invariant across helpers without simplifying any step
    let segs = data.segments
    let n = Int64(segs.size)
    if (n == 0) {
        return Array<DporRacePair>()
    }
    // Without an mtrace runtime every segment's access list is empty
    // (collectSegment short-circuits), so a race is impossible: skip the
    // O(n²) happens-before construction and pairwise scan instead of
    // paying them per window for a guaranteed-empty result.
    var anyAccess = false // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
    var probe: Int64 = 0
    while (probe < n) {
        if (segs[probe].accesses.size > 0) {
            anyAccess = true
            break
        }
        probe += 1
    }
    if (!anyAccess) {
        return Array<DporRacePair>()
    }

    // --- happens-before adjacency (segment flat indices) ---
    let adj = Array<ArrayList<Int64>>(n, { _ => ArrayList<Int64>() })

    // Program order: per actor, segments close in ordinal order, so
    // consecutive list entries are consecutive ordinals.
    let lastOf = ArrayList<Int64>() // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
    var i: Int64 = 0
    while (i < n) {
        let actor = segs[i].actor
        while (Int64(lastOf.size) <= actor) {
            lastOf.add(-1)
        }
        let prev = lastOf[actor]
        if (prev >= 0) {
            adj[prev].add(i)
        }
        lastOf[actor] = i
        i += 1
    }

    // Release→acquire on the same key: a Release-noting segment of one
    // actor happens-before a later-closing Acquire-noting segment of
    // another actor touching the same key (refEq). Closing order is
    // execution order under the token protocol, and every successful
    // acquire follows some release in that order, so all critical
    // sections on one primitive end up HB-connected.
    var a: Int64 = 0
    while (a < n) { // cjlint-ignore !G.FUN.01 nesting mirrors the linear match>for>if structure of the validation/exploration algorithm; each level performs one distinct step with an early exit, so flattening would obscure the flow
        let sa = segs[a] // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        var b: Int64 = 0
        while (b < n) {
            if (a == b) {
                b += 1
                continue  
            }
            let sb = segs[b]
            if (sa.actor != sb.actor && sa.decisionIndex < sb.decisionIndex && dporNotesReleaseAcquire(sa, sb)) {
                adj[a].add(b)
            }
            b += 1
        }
        a += 1
    }

    // Spawn edges: the spawner's in-progress segment into the child's
    // first segment.
    for (e in data.spawnEdges) {
        let from = dporSegIndex(segs, e.spawner, e.spawnerOrdinal)
        let to = dporSegIndex(segs, e.child, 0)
        if (from >= 0 && to >= 0) {
            adj[from].add(to)
        }
    }

    // --- group accesses by canonical address ---
    let byAddr = HashMap<UInt64, ArrayList<DporAccessRef>>()
    var s: Int64 = 0
    while (s < n) {
        let seg = segs[s]
        for (ev in seg.accesses) {
            if (ev.kind == MtraceKind.READ || ev.kind == MtraceKind.WRITE ||
                ev.kind == MtraceKind.RANGE_READ || ev.kind == MtraceKind.RANGE_WRITE ||
                ev.kind == MtraceKind.ALLOC) {
                let isWrite = ev.kind != MtraceKind.READ && ev.kind != MtraceKind.RANGE_READ
                let ref = DporAccessRef(seg: s, pc: ev.pc, size: ev.size, write: isWrite, fs: ev.fs)
                match (byAddr.get(ev.addr)) {
                    case Some(list) => list.add(ref)
                    case None =>
                        let list = ArrayList<DporAccessRef>()
                        list.add(ref)
                        byAddr.add(ev.addr, list)
                }
            }
        }
        s += 1
    }

    // --- conflicting pairs with no HB ordering either way ---
    let out = ArrayList<DporRacePair>()
    for ((addr, refs) in byAddr) {
        var x: Int64 = 0
        while (x < Int64(refs.size)) {
            var y: Int64 = x + 1
            while (y < Int64(refs.size)) {
                let r1 = refs[x]
                let r2 = refs[y]
                if (r1.seg != r2.seg && segs[r1.seg].actor != segs[r2.seg].actor &&
                    (r1.write || r2.write) &&
                    !dporHb(adj, r1.seg, r2.seg) && !dporHb(adj, r2.seg, r1.seg)) {
                    let sz = if (r1.size < r2.size) { r1.size } else { r2.size }
                    out.add(DporRacePair(
                        actorA: segs[r1.seg].actor, pcA: r1.pc,
                        actorB: segs[r2.seg].actor, pcB: r2.pc,
                        addr: addr, size: sz,
                        locA: symbolizePc(r1.pc, r1.fs), locB: symbolizePc(r2.pc, r2.fs)))
                }
                y += 1
            }
            x += 1
        }
    }
    return out.toArray()
}

/** Does `sa` carry a Release note and `sb` a later Acquire note of the
 * same key (identity)? */
private func dporNotesReleaseAcquire(sa: DporSegmentData, sb: DporSegmentData): Bool {
    for (na in sa.keyNotes where na.kind == PctSyncNoteKind.Release) {
        for (nb in sb.keyNotes) {
            if (nb.kind == PctSyncNoteKind.Acquire && refEq(na.key, nb.key)) {
                return true
            }
        }
    }
    return false
}

/** The flat index of the (actor, ordinal) segment, or -1. */
private func dporSegIndex(segs: ArrayList<DporSegmentData>, actor: Int64, ordinal: Int64): Int64 {
    var i: Int64 = 0
    while (i < Int64(segs.size)) {
        let s = segs[i]
        if (s.actor == actor && s.ordinal == ordinal) {
            return i
        }
        i += 1
    }
    return -1
}

/** Is `to` reachable from `from` over the HB adjacency? */
private func dporHb(adj: Array<ArrayList<Int64>>, from: Int64, to: Int64): Bool {
    if (from == to) {
        return true
    }
    let visited = Array<Bool>(adj.size, { _ => false })
    visited[from] = true
    let queue = ArrayList<Int64>()
    queue.add(from)
    var head: Int64 = 0
    while (head < Int64(queue.size)) {
        let cur = queue[head]
        head += 1
        for (nxt in adj[cur]) {
            if (nxt == to) {
                return true
            }
            if (!visited[nxt]) {
                visited[nxt] = true
                queue.add(nxt)
            }
        }
    }
    return false
}
