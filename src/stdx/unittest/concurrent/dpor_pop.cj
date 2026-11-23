/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

import std.collection.ArrayList
import std.collection.HashMap
import std.collection.HashSet

/**
 * The POP exploration core: a sequence-based OPTIMAL dynamic partial
 * order reduction — one explored window per Mazurkiewicz class of the
 * sync-key partial order, up to the duplicate classes the post-hoc
 * block-detection windows still explore, with polynomial bookkeeping
 * (Abdulla, Atig, Das, Jonsson, Sagonas, "Parsimonious Optimal
 * Dynamic Partial Order Reduction", CAV 2024).
 *
 * POP in engine terms: one closed segment = one POP event; a RACE is a
 * dependent, different-actor, happens-before-ADJACENT segment pair (Def
 * 5); reversing a race (e, e′) of a recorded window E = E1·e·E2 means
 * re-executing E1, then the SCHEDULE σ = e′↓E2 (the events of E2 that
 * happen-before e′, in recorded order, with e′ as the schedule head —
 * Def 4), then continuing with the default policy. The parsimony
 * conditions (Defs 6-7) drop races whose reversal would revisit an
 * already-explored execution — e must not be inside an embedded
 * schedule, and e′ must be FRESH (a schedule head itself, with every
 * schedule head between e and e′ hb-preceding it).
 *
 * Driver shape: POP's recursive Explore(E) made iterative over a task
 * stack. One window materializes a whole continuation
 * chain: the task's pinned prefix (its guide) realizes the node
 * E1·σ, and the fresh tail is the node's line-13 continuation chain —
 * so races are detected BATCHED, post-run, for every position from the
 * node's last event (the σ head) through the end of the recorded
 * window. Subtrees share no state, so batching constructs exactly the
 * σ's the eager recursion would, in fewer window executions.
 *
 * Prefix realization: the decision↔segment mapping is linear —
 * decision 0 is the initial release (closing nothing) and every
 * decision k ≥ 1 closes segment k-1, so segment j starts at decision j's
 * pick. A task's guide therefore has exactly one entry per node
 * segment: entry k pins decision k. Entries are Keep (an op-boundary
 * keep), Grant (a token move), or Strand (the ordered -1 transfer pick
 * — the quiescence wake path: virtual-timer fire, then drain push),
 * chosen per the recorded window so the prefix replays faithfully.
 *
 * The sleep-set characterization (dpor_pop_sschar.cj) is on by
 * default: line-7 checks skip reversal children whose σ would complete
 * a sleeping read schedule (no window wasted), and a fresh-position
 * block (Algorithm 1 line 13, detected post-hoc by the driver's
 * replay) cuts the duplicate tail's race processing and pushes one
 * sibling per blocked continuation candidate
 * (DporWindowConfig.sleepCharMode = Off disables the
 * characterization: complete and sound, exploring the duplicate
 * classes of compatible read schedules). The remaining duplicate
 * cost: each blocked continuation still runs to window completion
 * (the complete-and-discard fallback — one wasted window per blocked
 * candidate, no runtime abort machinery).
 */

/**
 * One task of the DFS stack: a POP node E1·σ realized as a pinned
 * decision prefix, plus the schedule markings of its prefix positions
 * (which events of the node are inside an embedded schedule —
 * `marks` — and which are schedule HEADS — `heads`; the parsimony
 * conditions are lookups over these), the sleep-set characterizations
 * created along the path, and the continuation-chain state.
 *
 * `guide` has exactly `guide.size` entries pinning decisions
 * 0..guide.size-1, reproducing the node's first `guide.size` segments
 * (the guide's length IS the node's event count: E1's segments plus
 * σ's); the fresh tail starts at decision `guide.size`, which closes
 * the schedule head. Everything past the prefix is unmarked.
 *
 * `schedExprs`: the schedule-expression sets created for
 * the σ-blocks along the path (pristine — never mutated; a window's
 * replay injects clones when it passes the anchored head event). A
 * block's characterization dies with the path: entries whose heads a
 * later reversal dropped never inject.
 *
 * `checkFrom`: the first prefix position whose sleep-set block check
 * applies. A reversal child's whole prefix is pre-vetted (E1 by the
 * ancestor windows, σ by the line-7 check at construction), so it
 * checks from `guide.size`; a BLOCKED-CONTINUATION sibling pins its
 * candidate segment unvetted, so it checks from the blocked position.
 *
 * `excluded`: the tried-and-blocked continuation candidates at this
 * task's chain decision (`excludedAt` — the blocked segment's start
 * decision): each blocked sibling excludes its own blocked actor and
 * inherits the exclusions, so the candidate chain monotonically
 * exhausts the enabled set (the termination argument: POP's line-13
 * "try the next unblocked enabled event", post-hoc). The list applies
 * only at exactly that decision: a block landing at a different
 * decision starts a fresh chain there, because an actor never
 * tried-and-blocked at the new decision must stay a candidate (skipping
 * it would silently drop its continuation classes).
 */
internal class DporPopTask {
    internal let guide: Array<DporGuideEntry>
    internal let marks: Array<Bool>
    internal let heads: Array<Bool>
    internal let schedExprs: ArrayList<DporSsEntry> = ArrayList<DporSsEntry>()
    internal let checkFrom: Int64
    internal let excluded: ArrayList<Int64> = ArrayList<Int64>()
    /** The chain decision the exclusions were established at (the
     * blocked segment's start decision); -1 when the list is empty.
     * The list may only filter candidates at exactly this decision. */
    internal let excludedAt: Int64

    internal init(guide!: Array<DporGuideEntry>, marks!: Array<Bool>, heads!: Array<Bool>,
        checkFrom!: Int64 = -1, excludedAt!: Int64 = -1) {
        this.guide = guide
        this.marks = marks
        this.heads = heads
        if (checkFrom >= 0) {
            this.checkFrom = checkFrom
        } else {
            this.checkFrom = Int64(guide.size)
        }
        this.excludedAt = excludedAt
    }

    /** The exploration root: node ⟨⟩ — an all-fresh default run. */
    internal static func root(): DporPopTask {
        return DporPopTask(
            guide: [],
            marks: [],
            heads: [])
    }
}

/** One collected parsimonious race (the earlier and the second event
 * positions of the recorded window). */
internal struct DporPopRace {
    internal DporPopRace(
        internal let p!: Int64,
        internal let q!: Int64
    ) {}
}

/**
 * The per-window analysis context: the happens-before relation over the
 * window's segments, restricted to NOTABLE segments (those carrying at
 * least one sync-key note or a spawn-edge endpoint — the only segments
 * that can bound, witness or be bounded by an hb edge; note-less
 * segments are program-order-transparent and never adjacency
 * witnesses: their only non-po incidence is spawn endpoints, which are
 * notable by definition, and any hb path through them collapses to a
 * direct same-actor edge).
 *
 * hb edges: same-actor pairs (program order), DEPENDENT note pairs
 * (`dporNotesDependent`, at least one write-class touch — POP's
 * same-variable/at-least-one-write rule), and spawn edges (the
 * spawner's in-progress segment into the child's first segment). All
 * edges are forward in recorded order, so hb ⊆ recorded order and the
 * transitive closure stays triangular.
 */
internal class DporPopHb {
    private let n: Int64
    private let segs: ArrayList<DporSegmentData>
    private let notableArr: Array<Bool>
    private let nidx: Array<Int64>
    private let nposArr: ArrayList<Int64>
    // The happens-before closure over the notable segments as BITSET
    // rows (row tp: bit tq set iff tp →hb tq) plus the transposed
    // columns (col tq: bit tp set iff tp →hb tq). Every edge points
    // forward in the recorded order (program order, recorded-order
    // dependence, spawn), so descending-position propagation computes
    // the closure in one linear pass over the direct edges, and a bit
    // AND answers adjacency. The bitset form matters for fair-mode
    // spin-storm windows: the starvation threshold caps an obstructed
    // spin at ~10k grid polls, each closing a notable segment — this
    // form is O(m²/64) words and near-linear time.
    private let hbRows: Array<Array<UInt64>>
    private let hbCols: Array<Array<UInt64>>
    private let words: Int64
    private let nextNotableArr: Array<Int64>

    internal init(data: DporRunData) { // cjlint-ignore !G.FUN.01 single cohesive algorithm block; splitting it would scatter the invariant across helpers without simplifying any step
        n = Int64(data.segments.size)
        segs = data.segments
        notableArr = Array<Bool>(n, { _ => false })
        var j: Int64 = 0
        while (j < n) {
            if (data.segments[j].keyNotes.size > 0) {
                notableArr[j] = true
            }
            j += 1
        }
        // Spawn endpoints (resolved to positions; both endpoints of an
        // edge are notable even when the segments carry no notes — a
        // spawned child's first segment really sits between the spawner
        // and the child's later segments in hb).
        let lastSeen = HashMap<Int64, Int64>() // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        nextNotableArr = Array<Int64>(n, { _ => -1 })
        var e: Int64 = 0
        while (e < Int64(data.spawnEdges.size)) {
            let edge = data.spawnEdges[e]
            let ps = dporFindSegmentPos(data, edge.spawner, edge.spawnerOrdinal)
            let pc = dporFindSegmentPos(data, edge.child, 0)
            if (ps >= 0) {
                notableArr[ps] = true
            }
            if (pc >= 0) {
                notableArr[pc] = true
            }
            e += 1
        }
        // For note-less x: the next notable segment of x's actor after
        // it — x's only hb exit. (Backward scan with the last notable
        // position seen per actor. Runs before the closure loops below:
        // every member must be initialized before member access.)
        j = n - 1
        while (j >= 0) {
            if (notableArr[j]) {
                nextNotableArr[j] = j
                lastSeen.add(segs[j].actor, j)
            } else if (let Some(p) <- lastSeen.get(segs[j].actor)) {
                nextNotableArr[j] = p
            }
            j -= 1
        }
        // Compact the notable positions.
        nidx = Array<Int64>(n, { _ => -1 })
        nposArr = ArrayList<Int64>()
        j = 0
        while (j < n) {
            if (notableArr[j]) {
                nidx[j] = Int64(nposArr.size)
                nposArr.add(j)
            }
            j += 1
        }
        let m = Int64(nposArr.size)
        let wordCount = (m + 63) / 64
        words = wordCount
        hbRows = Array<Array<UInt64>>(m, { _ => Array<UInt64>(wordCount, { _ => 0u64 }) })
        hbCols = Array<Array<UInt64>>(m, { _ => Array<UInt64>(wordCount, { _ => 0u64 }) })
        // The direct edges, as bit sets plus out-lists (the propagation
        // pass below ORs whole rows along the lists).
        let outEdges = ArrayList<ArrayList<Int64>>(m, { _ => ArrayList<Int64>() })
        let addEdge = { tp: Int64, tq: Int64 =>
            hbRows[tp][tq / 64] = hbRows[tp][tq / 64] | (1u64 << (tq % 64))
            outEdges[tp].add(tq)
        }
        // Program order: CONSECUTIVE notable segments of one actor —
        // program order is transitive, so the chain's closure (the
        // propagation below) covers every same-actor pair.
        let lastOf = HashMap<Int64, Int64>() // actor -> notable index // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        var t: Int64 = 0
        while (t < m) {
            let a = segs[nposArr[t]].actor
            match (lastOf.get(a)) {
                case Some(prev) => addEdge(prev, t)
                case None => ()
            }
            lastOf.add(a, t)
            t += 1
        }
        // Dependence: dependent note pairs in recorded order (same-actor
        // pairs are covered by program order). Enumerated per ORDERED
        // actor pair over per-actor notable-index lists: only cross-actor
        // pairs can be dependent, and a fair-mode spin-storm window's
        // ~10k same-actor spin segments would make an all-pairs scan an
        // O(m²) loop that mostly skips. The dependence oracle
        // (dporNotesDependent, key identity) decides each candidate
        // pair, so the enumeration affects only the cost, never the
        // edge set.
        var actorCount: Int64 = 0
        for (seg in segs) {
            if (seg.actor + 1 > actorCount) {
                actorCount = seg.actor + 1
            }
        }
        let byActorIdx = ArrayList<ArrayList<Int64>>(actorCount, { _ => ArrayList<Int64>() })
        t = 0
        while (t < m) {
            byActorIdx[segs[nposArr[t]].actor].add(t)
            t += 1
        }
        var aa: Int64 = 0
        while (aa < actorCount) { // cjlint-ignore !G.FUN.01 nesting mirrors the linear match>for>if structure of the validation/exploration algorithm; each level performs one distinct step with an early exit, so flattening would obscure the flow
            var bb: Int64 = 0
            while (bb < actorCount) {
                if (aa != bb) {
                    for (ta in byActorIdx[aa]) {
                        for (tb in byActorIdx[bb]) {
                            if (ta < tb && dporNotesDependent(
                                    segs[nposArr[ta]].keyNotes, segs[nposArr[tb]].keyNotes)) {
                                addEdge(ta, tb)
                            }
                        }
                    }
                }
                bb += 1
            }
            aa += 1
        }
        // Spawn edges.
        e = 0
        while (e < Int64(data.spawnEdges.size)) {
            let edge = data.spawnEdges[e]
            let ps = dporFindSegmentPos(data, edge.spawner, edge.spawnerOrdinal)
            let pc = dporFindSegmentPos(data, edge.child, 0)
            if (ps >= 0 && pc >= 0) {
                addEdge(nidx[ps], nidx[pc])
            }
            e += 1
        }
        // The transitive closure: process the notable indices in
        // DESCENDING order — every edge points to a higher index, so
        // each out-neighbor's row is already final; OR it in.
        var tp: Int64 = m - 1
        while (tp >= 0) {
            for (b in outEdges[tp]) {
                var w: Int64 = 0
                while (w < words) {
                    if (hbRows[b][w] != 0u64) {
                        hbRows[tp][w] = hbRows[tp][w] | hbRows[b][w]
                    }
                    w += 1
                }
            }
            tp -= 1
        }
        // The transpose (adjacency's AND needs the column form).
        tp = 0
        while (tp < m) {
            var w: Int64 = 0
            while (w < words) {
                var bits = hbRows[tp][w]
                var base: Int64 = w * 64 // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
                while (bits != 0u64) {
                    if ((bits & 1u64) == 1u64) {
                        let tq = base
                        hbCols[tq][tp / 64] = hbCols[tq][tp / 64] | (1u64 << (tp % 64))
                    }
                    bits = bits >> 1u64
                    base += 1
                }
                w += 1
            }
            tp += 1
        }
    }

    /** Is the position a notable segment? */
    internal func notable(pos: Int64): Bool {
        return notableArr[pos]
    }

    /** The notable positions in ascending order (the scan's candidate
     * source — see recordWindow's Phase 1). */
    internal func notablePositions(): ArrayList<Int64> {
        return nposArr
    }

    /** hb between two notable positions (bitset lookup). */
    internal func hbEdge(a: Int64, b: Int64): Bool {
        let ta = nidx[a]
        let tb = nidx[b]
        return ((hbRows[ta][tb / 64] >> (tb % 64)) & 1u64) == 1u64
    }

    /** hb from any position x (note-less included) to a notable
     * position q, for x < q: a note-less x reaches anything only
     * through its actor's next notable segment; same-actor is program
     * order outright. hb is a subset of the recorded order, so x ≥ q is
     * never hb — the same-actor branch would otherwise claim it (both
     * call sites pass x < q; the guard keeps a mis-resolved reference
     * from turning an order inversion into a false happens-before). */
    internal func hbTo(x: Int64, q: Int64): Bool {
        if (notableArr[x]) {
            let ta = nidx[x]
            let tq = nidx[q]
            return ((hbRows[ta][tq / 64] >> (tq % 64)) & 1u64) == 1u64
        }
        if (segs[x].actor == segs[q].actor) {
            if (x >= q) {
                return false // not program order: hb ⊆ recorded order
            }
            return true // program order: x < q
        }
        let nn = nextNotableArr[x]
        if (nn < 0) {
            return false
        }
        let ta = nidx[nn]
        let tq = nidx[q]
        return ((hbRows[ta][tq / 64] >> (tq % 64)) & 1u64) == 1u64
    }

    /** Are notable p and q hb-ADJACENT (no notable r strictly between
     * with p →hb r →hb q)? Every edge points forward in the recorded
     * order, so row p's set bits are all > p and column q's are all
     * < q: the AND of the row and the column is exactly the set of
     * intermediate witnesses (empty — all-zero words — iff adjacent).
     * Note-less r never witnesses: its only non-po incidence would be
     * a spawn endpoint, and those are notable. */
    internal func adjacent(p: Int64, q: Int64): Bool {
        let tp = nidx[p] // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        let tq = nidx[q] // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        var w: Int64 = 0
        while (w < words) {
            if ((hbRows[tp][w] & hbCols[tq][w]) != 0u64) {
                return false
            }
            w += 1
        }
        return true
    }
}

/** The position of actor's ordinal-th segment in the window (-1 when
 * absent — an aborted spawner's open segment, for instance). */
internal func dporFindSegmentPos(data: DporRunData, actor: Int64, ordinal: Int64): Int64 {
    var j: Int64 = 0
    while (j < Int64(data.segments.size)) {
        let s = data.segments[j]
        if (s.actor == actor && s.ordinal == ordinal) {
            return j
        }
        j += 1
    }
    return -1
}

/** Does the guide entry faithfully realize the recorded decision? (The
 * driver's prefix-replay verification: a window whose pinned decisions
 * do not reproduce the parent's picks diverged.) */
internal func dporGuideMatchesDecision(e: DporGuideEntry, d: DporDecisionData): Bool {
    match (e) {
        case Keep => d.chosen < 0 && d.kind == Switch
        case Strand => d.chosen < 0 && d.kind != Switch
        case Grant(t) => d.chosen == t
    }
}

/** One guide entry rendered for a task signature (see dporTaskSig). */
internal func dporGuideEntryDebugString(e: DporGuideEntry): String {
    match (e) {
        case Keep => "K"
        case Strand => "S"
        case Grant(t) => "G${t}"
    }
}

internal func dporGuideDebugString(entries: Array<DporGuideEntry>): String {
    var s = ""
    for (e in entries) {
        s += dporGuideEntryDebugString(e)
        s += ","
    }
    return s
}

/** The pushed-task signature (S3 duplicate suppression): the pinned
 * replay (guide), the parsimony markings, the vetting point and the
 * sibling exclusions with their chain anchor — everything that shapes
 * the task's own window except the sleep-set expressions (a
 * signature-identical task re-runs the same schedule; see
 * DporPopDriver.pushedSigs). */
internal func dporTaskSig(t: DporPopTask): String {
    var s = dporGuideDebugString(t.guide)
    s += "|"
    for (b in t.marks) {
        if (b) {
            s += "1"
        } else {
            s += "0"
        }
    }
    s += "|"
    for (b in t.heads) {
        if (b) {
            s += "1"
        } else {
            s += "0"
        }
    }
    s += "|"
    s += "${t.checkFrom}"
    s += "|"
    for (x in t.excluded) {
        s += "${x},"
    }
    s += "|"
    s += "${t.excludedAt}"
    return s
}

/**
 * The guide entry that starts a schedule event, given the kind of the
 * decision that closes the previous schedule event (or E1's last
 * segment) and that decider's actor:
 *  - an op-boundary close (Switch) keeps or preempts: same actor →
 *    Keep, other → Grant;
 *  - a release close (Unlock/Release/Notify/NotifyAll) leaves the
 *    releaser Gated and competing: Grant either way;
 *  - a fair-yield close keeps the holder running when the next event
 *    is its own (the ordered -1) or grants the other;
 *  - a park/exit close (Block/Wait/Done/Complete) leaves the decider
 *    ungrantable, so the entry repeats the PARENT's recorded start
 *    mechanism for the target: Grant when the parent's start granted
 *    it (its gating wake happened in E1 or an earlier schedule event
 *    and replays), Strand when the parent's start itself stranded and
 *    the quiescence wake (the virtual-timer fire, then the drain push)
 *    produced it.
 */
internal func dporSigmaEntry(prevCloseKind: PctEventKind, prevActor: Int64,
    targetActor: Int64, parentStart: ?DporDecisionData): DporGuideEntry {
    if (prevCloseKind == Switch) {
        if (prevActor == targetActor) {
            return Keep
        }
        return Grant(targetActor)
    }
    if (prevCloseKind == Unlock || prevCloseKind == PctEventKind.Release ||
        prevCloseKind == Notify || prevCloseKind == NotifyAll) {
        return Grant(targetActor)
    }
    if (prevCloseKind == FairYield) {
        if (prevActor == targetActor) {
            return Strand // the holder keeps running
        }
        return Grant(targetActor)
    }
    // A park or exit close: the decider is not grantable — repeat the
    // PARENT's recorded start mechanism for the target. The same-actor
    // case is NOT special: the waker of a resumed park can be the
    // RACE's own earlier event e (which σ drops — an unrealizable
    // branch under the park model); Grant then fails the runtime's
    // isGated validation and abandons the guide, dropping the branch
    // cleanly instead of hanging the window on a Strand with gated
    // actors (the park-model analogue of POP's spin-read alternatives,
    // which a parked actor cannot realize).
    match (parentStart) {
        case Some(d) =>
            if (d.chosen >= 0) {
                // The parent's start granted the target (a wake in E1
                // or an earlier schedule event flipped it): the grant
                // replays it, and the runtime's isGated check is exactly
                // the realizability filter.
                return Grant(targetActor)
            }
            if (d.kind == Switch) {
                // Proven unreachable for this configuration (the
                // parent's flow would put a same-actor predecessor
                // here); Grant is the safe fallback either way.
                return Grant(targetActor)
            }
        case None => ()
    }
    // The parent's start itself stranded: the quiescence wake (the
    // virtual-timer fire, then the drain push) produced the target.
    return Strand
}

/**
 * The POP driver: the task-stack DFS over windows.
 *
 * `nextTask` pops the deepest-pending reversal branch; the driver's
 * caller runs the window (the runDporWindowStepped lifecycle) and
 * returns the recorded `DporRunData`, which `recordWindow` reduces:
 * divergence handling (faithful-prefix verification; storm-diverged
 * windows are salvaged as their actual executions), the window's
 * happens-before analysis, then the parsimonious race scan pushing a
 * child task per reversal.
 *
 * A pruned-by-switch-bound child (its pinned guide plans more Grants
 * than the bound) is dropped and counted — `prunedCount() > 0` reports
 * depthPruned, and exhaustion is only reported when nothing was
 * pruned.
 */
internal class DporPopDriver {
    private let stack = ArrayList<DporPopTask>()
    private let switchBound: Int64
    // The sleep-set characterization's kill switch
    // (DporWindowConfig.sleepCharMode): false disables it — complete
    // and sound, exploring the duplicate classes of compatible read
    // schedules.
    private let sleepChar: Bool
    // Diagnostics.
    private var windows: Int64 = 0
    private var racesSeen: Int64 = 0
    private var parsimonious: Int64 = 0
    private var pushed: Int64 = 0
    private var pruned: Int64 = 0
    private var diverged: Int64 = 0
    // Windows whose guide was abandoned mid-run and whose node became
    // the ACTUAL (storm-diverged) execution — the salvage path in
    // recordWindow. Their races are scanned and their children pushed
    // from the recorded data, like any window.
    private var salvaged: Int64 = 0
    // S3 duplicate suppression: a salvaged window re-derives the races
    // of the trajectory it actually ran — which, when its σ derailed
    // at the first entry, is the PARENT's own order — so its pushes
    // can reproduce tasks the tree already ran. Every push
    // registers its task signature; a SALVAGED window's duplicate push
    // is skipped (a faithful window's never is — byte-identical
    // exploration for every scenario that never diverges). The
    // signature pins the replay (guide, markings, vetting point,
    // sibling exclusions) — everything except the sleep-set
    // expressions: a signature-identical task re-runs the same
    // schedule, so its classes are collected; only its reduction could
    // differ, and a reduction of the same data re-derives the same
    // reversal guides.
    private let pushedSigs = HashSet<String>()
    private var dupSkipped: Int64 = 0
    private var maxStack: Int64 = 0
    // Sleep-characterization diagnostics: children skipped by the
    // line-7 check (the reversal itself would complete a sleeping
    // schedule — no window wasted) and windows whose fresh continuation
    // completed a sleeping schedule (the tail explored a duplicate
    // class; its race processing was cut and a sibling pushed).
    private var sleepSkipped: Int64 = 0
    private var sleepBlocked: Int64 = 0
    // Obstruction rescue branches pushed (one child per recorded
    // obstruction × gated peer — the planned peer-grant at the streak
    // point; the throw marked the dead-end branch of the same node).
    private var rescuePushes: Int64 = 0

    internal init(switchBound!: Int64 = -1, sleepChar!: Bool = true) {
        this.switchBound = switchBound
        this.sleepChar = sleepChar
        stack.add(DporPopTask.root())
    }

    /** Children pruned by the switch bound (never run). */
    internal func prunedCount(): Int64 {
        return pruned
    }

    /** Windows dropped as diverged (determinism-contract violations and
     *  structural failures — the diverged sites of recordWindow): a
     *  non-zero count means the exploration is incomplete, so it gates
     *  the report's `exhausted`. */
    internal func divergedCount(): Int64 {
        return diverged
    }

    /** Child reversals skipped by the line-7 sleep check (each would
     *  have completed a sleeping schedule — sound skipping, reported for
     *  exploration diagnostics). */
    internal func sleepSkippedCount(): Int64 {
        return sleepSkipped
    }

    /** A short human-readable state line for reports. */
    internal func statsLine(): String {
        return "schedules=${windows} races=${racesSeen} parsimonious=${parsimonious} " +
            "pushes=${pushed} pruned=${pruned} diverged=${diverged} salvaged=${salvaged} " +
            "dupSkipped=${dupSkipped} maxStack=${maxStack} " +
            "sleepSkipped=${sleepSkipped} sleepBlocked=${sleepBlocked} rescues=${rescuePushes}"
    }

    /** The next task to run, or None when the stack (and so the
     * exploration) is exhausted. */
    internal func nextTask(): ?DporPopTask {
        if (Int64(stack.size) == 0) {
            return None
        }
        let t = stack.remove(at: stack.size - 1)
        return Some(t)
    }

    /**
     * Reduce one completed window: verify the pinned prefix replayed,
     * then scan the parsimonious races of the node and its continuation
     * chain, pushing one child task per reversal.
     *
     * Divergence handling: a window whose guide derailed is SALVAGED,
     * not dropped — the node's data becomes the actual execution. Two
     * derailment shapes reach the same salvage: (1) an entry failed to
     * apply and the guide was abandoned (a storm-diverged run — the
     * pinned σ was unrealizable under the token protocol's liveness
     * rules, and the fair-mode recovery inserted decisions the prefix
     * never had); (2) an entry was consumed at a differently-shaped
     * decision without abandonment (the pick cases that "never planned"
     * an entry — a Strand at an op boundary — silently apply it), and
     * the guide-decision match check catches the first mismatch. In
     * both, the pinned prefix is everything up to the divergence point
     * (verified against the recorded picks — a failure in shape 1's
     * applied prefix is a real determinism-contract violation, counted
     * in `diverged`); everything past it is fresh tail, and the normal
     * scan/push machinery runs over the recorded data unchanged. A
     * misaligned decision log, or a faithful-shape run that ended
     * before the pinned prefix did, is a genuine contract violation —
     * dropped and counted in `diverged`.
     *
     * Races with the second event inside the matched prefix (other than
     * the schedule head) were already processed in the ancestor windows
     * where those events were fresh or heads; the scan therefore starts
     * at the node's last event (faithful windows) or at the divergence
     * point (salvaged windows — the first position whose event was
     * started by a fresh decision; everything below it matched the
     * ancestor's trajectory position-for-position).
     *
     * Salvaged windows deduplicate their pushes (S3, see pushedSigs):
     * the actual execution can be the parent's own order (a σ that
     * derailed at its first entry), whose races re-derive tasks the
     * tree already pushed.
     *
     * Phase order: the races are collected first, then the
     * sleep-set characterization is replayed over the recorded window
     * (from the root's empty state, injecting the task-carried
     * expressions at their anchored heads — the state after each
     * prefix position is a pure function of the path, so no
     * trajectory is carried), then each child is checked (Algorithm 1
     * line 7: a reversal whose σ would complete a sleeping read
     * schedule is skipped) and constructed (MkSchedChar adds the
     * created expressions to the child), and finally a fresh-position
     * block (line 13, post-hoc) cuts the race processing at the
     * blocked position and pushes one sibling with the next candidate
     * continuation there.
     */
    internal func recordWindow(task: DporPopTask, data: DporRunData): Unit { // cjlint-ignore !G.FUN.01 single cohesive algorithm block; splitting it would scatter the invariant across helpers without simplifying any step
        windows += 1
        let L = Int64(task.guide.size)
        let n = Int64(data.segments.size)
        // Data-integrity guard, either path: the decision log must cover
        // every segment. A misaligned log is a recording bug —
        // investigated, never salvaged.
        if (Int64(data.decisions.size) < n) {
            diverged += 1
            return
        }
        // The effective task and prefix length: what the scan and the
        // child construction below may treat as pinned. Faithful
        // windows: the task itself. Salvaged windows: the task clamped
        // to the matched prefix (below).
        var effTask = task
        var effL = L
        var salvagedNow = false
        // The divergence point: the first position whose recorded event
        // the guide did not produce. Either shape below leaves the same
        // invariant: positions [0, at) matched the ancestor's trajectory
        // position-for-position (verified against the recorded picks);
        // positions [at, n) are the actual execution's fresh tail.
        var at: Int64 = -1
        if (data.guideAbandoned) { // cjlint-ignore !G.FUN.01 nesting mirrors the linear match>for>if structure of the validation/exploration algorithm; each level performs one distinct step with an early exit, so flattening would obscure the flow
            // Shape 1 — an entry failed to apply and the guide died: the
            // index of the failed entry (guidePos - 1, written by
            // abandonGuide). The decision at it was made fresh.
            at = data.guideAbandonedAt
            if (at < 0) {
                at = 0
            }
            if (at > L) {
                at = L
            }
            // The applied prefix must still match its entries — the
            // matched-trajectory claim the scan start and the markings'
            // validity rest on. A failure here IS a determinism-contract
            // violation: drop and count it.
            var k: Int64 = 0
            while (k < at) {
                if (!dporGuideMatchesDecision(task.guide[k], data.decisions[k])) {
                    diverged += 1
                    return
                }
                k += 1
            }
        } else {
            // Faithful-shape window: the prefix must cover the run. A
            // window that ended before the pinned prefix did is a
            // structural failure — dropped, never salvaged.
            if (n < L) {
                diverged += 1
                return
            }
            var k: Int64 = 0
            while (k < L) {
                if (!dporGuideMatchesDecision(task.guide[k], data.decisions[k])) {
                    break
                }
                k += 1
            }
            if (k < L) {
                // Shape 2 — a σ derailed WITHOUT abandonment: an entry
                // was consumed at a differently-shaped decision (a
                // Strand planned for a fair-yield, applied at an op
                // boundary; a grant planned for a spin, applied at a
                // park — the "never planned here" pick cases). The
                // guide's tail records the intent, the decisions
                // record the actual: the first mismatch IS the
                // divergence point. Salvage there like shape 1.
                at = k
            }
        }
        if (at >= 0) {
            // The salvage: the node's data becomes the ACTUAL execution.
            // Clamp the task to the matched prefix — guide, markings and
            // the vetting point describe the ancestor's trajectory only
            // up to `at`; past it the recorded events are fresh tail —
            // unmarked, unvetted, never scanned anywhere — so the
            // clamped marks/heads leave them exactly that. The
            // sleep-set expressions ride along unchanged: their anchors
            // are (actor, ordinal)-keyed, so an anchor whose intended
            // position diverged either matches the same logical event
            // in the actual trajectory or never injects.
            salvagedNow = true
            salvaged += 1
            let effGuide = Array<DporGuideEntry>(at, { i => task.guide[i] })
            let effMarks = Array<Bool>(at, { i => task.marks[i] })
            let effHeads = Array<Bool>(at, { i => task.heads[i] })
            // The exclusion chain's anchor survives the clamp only when
            // the chain decision is INSIDE the matched prefix (at >
            // excludedAt): the salvaged trajectory replayed that
            // decision, so the exclusions keep meaning "tried and
            // blocked" there. At or past the divergence point the
            // recorded decisions are a fresh execution, so the anchor
            // is stale — reset it (the copied list then never applies:
            // pushSibling only consults it at the anchor decision).
            var effExcludedAt: Int64 = -1
            if (at > task.excludedAt) {
                effExcludedAt = task.excludedAt
            }
            let eff = DporPopTask(guide: effGuide, marks: effMarks, heads: effHeads,
                checkFrom: min(task.checkFrom, at), excludedAt: effExcludedAt)
            for (entry in task.schedExprs) {
                eff.schedExprs.add(entry)
            }
            for (x in task.excluded) {
                eff.excluded.add(x)
            }
            effTask = eff
            effL = at
        }
        if (n == 0) {
            return // nothing happened (the degenerate initial-strand window)
        }
        let ctx = DporPopHb(data)
        var qStart: Int64 = 0
        if (salvagedNow) {
            // The fresh tail begins AT the divergence point; scan from
            // there. Positions below it matched the ancestor's
            // trajectory position-for-position, so their second-event
            // races were processed in the ancestor windows where those
            // events were fresh or heads.
            qStart = effL
            if (qStart > n - 1) {
                qStart = n - 1
            }
        } else if (effL > 0) {
            qStart = effL - 1 // the node's last event: the schedule head
        }
        // Phase 1: collect the parsimonious races (q descending, p
        // ascending — the child push order). The candidate enumeration
        // is per-actor (the same cross-actor-only rationale as the hb
        // construction's dependence enumeration); the per-actor lists
        // merge back into one global ascending p order.
        let races = ArrayList<DporPopRace>()
        var actorCount: Int64 = 0
        for (seg in data.segments) {
            if (seg.actor + 1 > actorCount) {
                actorCount = seg.actor + 1
            }
        }
        let byActor = ArrayList<ArrayList<Int64>>(actorCount, { _ => ArrayList<Int64>() })
        for (pos in ctx.notablePositions()) {
            byActor[data.segments[pos].actor].add(pos)
        }
        var q: Int64 = n - 1
        while (q >= qStart) { // cjlint-ignore !G.FUN.01 nesting mirrors the linear match>for>if structure of the validation/exploration algorithm; each level performs one distinct step with an early exit, so flattening would obscure the flow
            if (ctx.notable(q)) {
                let qa = data.segments[q].actor // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
                // p ascending over the other actors' lists, merged by
                // cursor (the global ascending order, cross-actor only).
                let cursors = Array<Int64>(actorCount, { _ => 0 }) // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
                while (true) {
                    var best: Int64 = -1
                    var bestPos: Int64 = -1
                    var c: Int64 = 0
                    while (c < actorCount) {
                        if (c != qa) {
                            let list = byActor[c]
                            let cur = cursors[c]
                            if (cur < Int64(list.size)) {
                                let cand = list[cur]
                                if (q > cand && (best < 0 || bestPos > cand)) {
                                    best = c
                                    bestPos = cand
                                }
                            }
                        }
                        c += 1
                    }
                    if (best < 0) {
                        break
                    }
                    cursors[best] += 1
                    let p = bestPos // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
                    if (ctx.hbEdge(p, q)) {
                        // Def 5: the adjacent hb edge must be a
                        // DEPENDENCE edge. For a cross-actor pair,
                        // adjacency forces a direct hb edge, and that
                        // edge can be a SPAWN edge (the spawner's
                        // in-progress segment into the child's first
                        // segment) rather than a dependence edge — a
                        // spawn-only pair is not a race (reversing it
                        // revisits an already-explored class through a
                        // wasted salvaged window). The conjunct is the
                        // same dependence oracle the hb closure used
                        // to add cross-actor dependence edges, so a
                        // pair joined by both a spawn and a dependence
                        // edge still races.
                        if (ctx.adjacent(p, q) && dporNotesDependent(
                                data.segments[p].keyNotes, data.segments[q].keyNotes)) {
                            racesSeen += 1
                            if (parsimonyOk(effTask, ctx, p, q, effL)) {
                                parsimonious += 1
                                races.add(DporPopRace(p: p, q: q))
                            }
                        }
                    }
                }
            }
            q -= 1
        }
        // Phase 2: the sleep-set characterization replay — the state
        // evolution along the recorded window, with snapshots at the
        // collected races' E1 positions and the first fresh block.
        var blockPos: Int64 = -1
        let snaps = HashMap<Int64, ArrayList<DporSsExpr>>()
        // The characterization inputs are window-constant: the
        // fingerprint column and the replay context depend only on the
        // recorded data and the hb relation, so they are built once
        // here and threaded into every push (never rebuilt per push).
        // `None`/empty when the characterization is off (then unused).
        var histFps: Array<UInt64> = []
        var ssCtx: ?DporSsCtx = None
        if (sleepChar) {
            histFps = dporSsHistFps(data)
            let sctx = DporSsCtx(data: data, hb: ctx, histFps: histFps)
            ssCtx = Some(sctx)
            let need = HashMap<Int64, Bool>()
            for (r in races) {
                need.add(r.p, true)
            }
            let state = ArrayList<DporSsExpr>() // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
            snaps.add(0, dporSsCloneState(state)) // SSChar[⟨⟩] = ∅
            var i: Int64 = 0
            while (i < n) {
                let seg = data.segments[i]
                let ev = DporSsEventView(pos: i, actor: seg.actor, // cjlint-ignore !G.VAR.02 single-use binding whose two-line constructor would make the consuming if-condition unreadable if inlined; the live range is already minimal
                    ordinal: seg.ordinal, histFp: histFps[i], keyNotes: seg.keyNotes)
                dporSsInject(effTask, seg, histFps[i], state)
                if (dporSsProcessEvent(state, ev, sctx) == DporSsRes.Sleep && i >= effTask.checkFrom) {
                    blockPos = i
                    break
                }
                if (need.contains(i + 1)) {
                    snaps.add(i + 1, dporSsCloneState(state))
                }
                i += 1
            }
        }
        // Phase 3: the reversal children (the line-7 check first).
        for (r in races) {
            if (blockPos >= 0 && blockPos <= r.q) {
                continue // the duplicate tail's races are not processed
            }
            pushChild(effTask, ctx, data, r.p, r.q, snaps, salvagedNow,
                histFps: histFps, ssCtx: ssCtx)
        }
        // Phase 4: the blocked continuation's sibling.
        if (blockPos >= 0) {
            sleepBlocked += 1
            pushSibling(effTask, data, blockPos, salvagedNow)
        }
        // Phase 5: the obstruction rescue branches — one child
        // per recorded obstruction × gated peer. Only ThrowObstruction
        // windows record obstructions (fair windows resolve walls their
        // way and have none), so fair-mode and obstruction-free
        // explorations are untouched.
        for (ob in data.obstructions) {
            for (peer in ob.peers) {
                pushRescue(effTask, data, ob.decisionIndex, peer, salvagedNow)
            }
        }
    }

    /**
     * The parsimony conditions (POP Defs 6-7) as lookups over the
     * task's schedule markings and the window's hb:
     *  (ii) e (the earlier event) is not inside any embedded schedule;
     *  (iii) e′ is fresh: a marked e′ must be a schedule HEAD (only the
     *       node's head position is marked among processed positions —
     *       true by construction), and every schedule head between e
     *       and e′ must hb-precede e′.
     */
    private func parsimonyOk(task: DporPopTask, ctx: DporPopHb, p: Int64, q: Int64,
        L: Int64): Bool {
        if (p < L && task.marks[p]) {
            return false
        }
        if (q < L && !task.heads[q]) {
            return false
        }
        var r: Int64 = p + 1
        while (r < q) {
            if (r < L && task.heads[r] && !ctx.hbEdge(r, q)) {
                return false
            }
            r += 1
        }
        return true
    }

    /**
     * The E1 guide-prefix synthesis shared by every push: an array of
     * `size` entries (default Keep) whose first `upto` positions replay
     * the recorded decisions — Grant where a decision granted (chosen ≥ 0),
     * Keep where the holder continued through its own op boundary (a
     * Switch close), Strand at every other close (the park/exit strands a
     * guide can abandon on).
     */
    private func dporGuidePrefix(data: DporRunData, size: Int64,
        upto: Int64): Array<DporGuideEntry> {
        let entries = Array<DporGuideEntry>(size, { _ => Keep })
        var kk: Int64 = 0
        while (kk < upto) {
            let d = data.decisions[kk]
            if (d.chosen >= 0) {
                entries[kk] = Grant(d.chosen)
            } else if (d.kind == Switch) {
                entries[kk] = Keep
            } else {
                entries[kk] = Strand
            }
            kk += 1
        }
        return entries
    }

    /** The switch bound (see DporWindowConfig.switchBound): a guide
     *  whose Grant count exceeds the bound is pruned — the bound is
     *  per-schedule, -1 disables it. */
    private func exceedsSwitchBound(entries: Array<DporGuideEntry>): Bool {
        if (switchBound < 0) {
            return false
        }
        var grants: Int64 = 0
        for (e in entries) {
            match (e) {
                case Grant(_) => grants += 1
                case _ => ()
            }
        }
        return grants > switchBound
    }

    /**
     * The shared push tail (S3, see pushedSigs): register the task's
     * signature; a salvaged window's re-derivation of an already-pushed
     * task is skipped when `dedup` is set. Returns false when the
     * duplicate was skipped (the caller must not push); on true the task
     * is on the stack, with `pushed` and the stack high-water mark
     * updated.
     */
    private func pushTask(child: DporPopTask, dedup: Bool): Bool {
        let tsig = dporTaskSig(child)
        if (pushedSigs.contains(tsig)) {
            if (dedup) {
                dupSkipped += 1
                return false
            }
        } else {
            pushedSigs.add(tsig)
        }
        stack.add(child)
        pushed += 1
        if (Int64(stack.size) > maxStack) {
            maxStack = Int64(stack.size)
        }
        return true
    }

    /**
     * Reverse one parsimonious race (e, e′) = (p, q): build σ = e′↓E2
     * (the hb-predecessors of e′ after e, plus e′), synthesize the
     * child's pinned guide (E1's recorded picks, then one entry per σ
     * event), run the line-7 check (UpdSeq(σ, SSChar[E1]) — a reversal
     * whose σ would complete a sleeping read schedule is skipped: the
     * child never runs), create the schedule expressions for σ
     * (MkSchedChar — they ride with the child), mark the child's
     * prefix (E1 inherits the markings; the σ block is in-schedule
     * with e′ as the head), and push it — unless the guide exceeds
     * the switch bound (counted as pruned).
     */
    private func pushChild(task: DporPopTask, ctx: DporPopHb, data: DporRunData, // cjlint-ignore !G.FUN.01 single cohesive algorithm block; splitting it would scatter the invariant across helpers without simplifying any step
        p: Int64, q: Int64, snaps: HashMap<Int64, ArrayList<DporSsExpr>>,
        dedup: Bool, histFps!: ?Array<UInt64> = None, // cjlint-ignore !G.FUN.01 config-carrier signature: the named parameters are the structured configuration/context of this framework step; bundling them into a struct would only move the count
        ssCtx!: ?DporSsCtx = None): Unit { // cjlint-ignore !G.FUN.01 config-carrier signature: the named parameters are the structured configuration/context of this framework step; bundling them into a struct would only move the count
        // σ = the hb-predecessors of e′ within E2 (recorded order), then e′.
        let sig = ArrayList<Int64>()
        var x: Int64 = p + 1
        while (x < q) {
            if (ctx.hbTo(x, q)) {
                sig.add(x)
            }
            x += 1
        }
        sig.add(q)
        let m = Int64(sig.size)
        let lc = p + m
        // The line-7 check: UpdSeq(σ, SSChar[E1]).
        let newEntries = ArrayList<DporSsEntry>()
        if (sleepChar) {
            var work = ArrayList<DporSsExpr>()
            match (snaps.get(p)) {
                case Some(base) => work = dporSsCloneState(base)
                case None => ()
            }
            // The window-constant characterization inputs threaded from
            // recordWindow (Phase 2) — the caller computed them once
            // for the whole window; both are Some here exactly when
            // sleepChar is on.
            let hf = histFps.getOrThrow() // cjlint-ignore !G.ERR.03 invariant-guarded extraction: Some is guaranteed here by construction (see the preceding gate); None would be a framework bug where throwing is the intended behavior
        // cjlint-ignore -start !G.VAR.02 the variables below thread state across loop/algorithm iterations (accumulators or framework context); narrowing their scopes would change semantics
            let sctx = ssCtx.getOrThrow() // cjlint-ignore !G.ERR.03 invariant-guarded extraction: Some is guaranteed here by construction (see the preceding gate); None would be a framework bug where throwing is the intended behavior
        // cjlint-ignore -end
            var blocked = false
            var si: Int64 = 0
            while (si < m) {
                let pos = sig[si]
                let seg = data.segments[pos]
                let ev = DporSsEventView(pos: pos, actor: seg.actor, // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
                    ordinal: seg.ordinal, histFp: hf[pos], keyNotes: seg.keyNotes)
                if (dporSsProcessEvent(work, ev, sctx) == DporSsRes.Sleep) {
                    blocked = true
                    break
                }
                dporSsInject(task, seg, hf[pos], work)
                si += 1
            }
            if (blocked) {
                sleepSkipped += 1
                return
            }
            // MkSchedChar(σ, E1, e, E2): the schedule expressions for
            // σ, riding with the child (injected when the child's
            // replay passes its head event).
            let eSeg = data.segments[p]
            let headSeg = data.segments[q]
            let eEv = DporSsEventView(pos: p, actor: eSeg.actor,
                ordinal: eSeg.ordinal, histFp: hf[p], keyNotes: eSeg.keyNotes)
            let headEv = DporSsEventView(pos: q, actor: headSeg.actor,
                ordinal: headSeg.ordinal, histFp: hf[q], keyNotes: headSeg.keyNotes)
            let newExprs = dporSsMkSchedChar(data, task, hf, p, q, eEv, headEv, sig)
            if (Int64(newExprs.size) > 0) {
                newEntries.add(DporSsEntry(headActor: headSeg.actor,
                    headOrdinal: headSeg.ordinal, headHistFp: hf[q], exprs: newExprs))
            }
        }
        // E1: the recorded picks up to the decision that started e
        // (decision p — the one whose pick started segment p).
        let entries = dporGuidePrefix(data, lc, p)
        // The σ block: entry p + i starts schedule event i (consumed at
        // the child's decision p + i, which closes the previous event).
        var i: Int64 = 0
        while (i < m) {
            let target = data.segments[sig[i]].actor
            if (p + i == 0) {
                entries[0] = Grant(target) // the initial release
            } else {
                var prevSegPos: Int64 = p - 1
                var prevCloseDec = data.decisions[p] // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
                if (i > 0) {
                    prevSegPos = sig[i - 1]
                    prevCloseDec = data.decisions[sig[i - 1] + 1]
                }
                let prevActor = data.segments[prevSegPos].actor
                var startDec: ?DporDecisionData = None // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
                if (sig[i] < Int64(data.decisions.size)) {
                    startDec = Some(data.decisions[sig[i]])
                }
                entries[p + i] = dporSigmaEntry(prevCloseDec.kind, prevActor, target, startDec)
            }
            i += 1
        }
        // The switch bound: the guide's Grant count is the pinned
        // prefix's voluntary-switch count.
        if (exceedsSwitchBound(entries)) {
            pruned += 1
            return
        }
        // Markings: E1 inherits the task's (positions past the task's
        // own prefix are unmarked — they were fresh tail events); the σ
        // block is in-schedule, e′ its head.
        let marks = Array<Bool>(lc, { _ => false })
        let heads = Array<Bool>(lc, { _ => false })
        var j: Int64 = 0
        while (j < p) {
            if (j < Int64(task.marks.size)) {
                marks[j] = task.marks[j]
                heads[j] = task.heads[j]
            }
            j += 1
        }
        var w: Int64 = p
        while (w < lc) {
            marks[w] = true
            w += 1
        }
        heads[lc - 1] = true
        let child = DporPopTask(guide: entries, marks: marks, heads: heads)
        // The sleep-set characterizations: the path's expressions (all
        // the task's entries — the ones whose anchored heads a later
        // reversal dropped never inject) plus σ's own.
        for (entry in task.schedExprs) {
            child.schedExprs.add(entry)
        }
        for (entry in newEntries) {
            child.schedExprs.add(entry)
        }
        // S3: register the signature; a salvaged window's re-derivation
        // of an already-pushed task is skipped (see pushedSigs).
        if (!pushTask(child, dedup)) {
            return
        }
    }

    /**
     * The obstruction rescue branch: the throw at the starvation
     * point marks the DEAD-END branch of the node; this pushes its
     * sibling — the peer grant at the exact grid check, PLANNED like
     * any child (guide-pinned, replayable, switch-bounded, deduped),
     * never a fair-mode foreign event. One child per recorded
     * obstruction × gated peer: the recorded picks up to (excluding)
     * the obstruction decision, then Grant(peer) — the re-run
     * transfers the token at that grid check instead of truncating the
     * operation, modeling the wall-resolved completion (a peer on
     * another core making the spinner's wait succeed) that the race
     * machinery cannot derive on its own (the source-race position is
     * pinned at the burn end by the interleaving-dependent spin). No
     * sleep-set line-7 check: the rescue explores territory the
     * characterization has not vetted, and skipping the check costs at
     * most redundancy, never completeness.
     */
    private func pushRescue(task: DporPopTask, data: DporRunData,
        decisionIndex: Int64, peer: Int64, dedup: Bool): Unit {
        let lc = decisionIndex + 1
        // E1: the recorded picks before the obstruction decision.
        let entries = dporGuidePrefix(data, lc, decisionIndex)
        entries[decisionIndex] = Grant(peer)
        // The switch bound: like any child, the guide's Grant count is
        // the pinned prefix's voluntary-switch count.
        if (exceedsSwitchBound(entries)) {
            pruned += 1
            return
        }
        // Markings: the prefix inherits; the rescue position is marked
        // (a backtrack point is installed there — races with p at it are
        // skipped, the parsimony's condition (ii)). It is NOT a head:
        // heads gate parsimonyOk's hbEdge(r, q) lookup, which requires
        // the position to be a notable segment (the nidx invariant);
        // the rescue position is a decision index whose segment in the
        // child's own data may be note-less — marking it a head would
        // index nidx[-1]. Conservative and safe: races with q at the
        // rescue position are simply not collected.
        let marks = Array<Bool>(lc, { _ => false })
        let heads = Array<Bool>(lc, { _ => false })
        var j: Int64 = 0
        while (j < decisionIndex) {
            if (j < Int64(task.marks.size)) {
                marks[j] = task.marks[j]
                heads[j] = task.heads[j]
            }
            j += 1
        }
        marks[decisionIndex] = true
        let child = DporPopTask(guide: entries, marks: marks, heads: heads) // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        for (entry in task.schedExprs) {
            child.schedExprs.add(entry)
        }
        // S3: the same duplicate suppression as any push.
        if (!pushTask(child, dedup)) {
            return
        }
        rescuePushes += 1
    }

    /**
     * The blocked continuation's sibling (Algorithm 1 line 13,
     * post-hoc): the default continuation's segment at `blockPos`
     * would complete a sleeping read schedule, so the node needs a
     * DIFFERENT continuation — pin the recorded prefix up to the
     * blocked decision (its position: segment j starts at decision j)
     * and grant the next candidate actor (the enabled set at that
     * decision, in slot order, skipping the tried-and-blocked ones).
     * The sibling's pinned last segment (the candidate's) was never
     * vetted: its checkFrom is the blocked position, so its own replay
     * re-checks it. No candidate remains — the node is complete
     * (POP's line-13 "∃e ..." fails: every continuation completes a
     * sleeping schedule; the reversal children cover its classes).
     *
     * The exclusions anchor at the blocked decision: the sibling
     * inherits the chain's list only when the block lands at the SAME
     * decision the list was established at (the chain monotonically
     * exhausting THAT decision's enabled set); a block at a different
     * decision starts a fresh chain there, because an inherited actor
     * was never tried-and-blocked at the new decision and skipping it
     * would silently drop its continuation classes.
     */
    private func pushSibling(task: DporPopTask, data: DporRunData, blockPos: Int64, // cjlint-ignore !G.FUN.01 single cohesive algorithm block; splitting it would scatter the invariant across helpers without simplifying any step
        dedup: Bool): Unit {
        let d = blockPos // the blocked segment's start decision
        let dec = data.decisions[d]
        // The blocked segment's start mechanism must be redirectable: a
        // recorded grant (chosen ≥ 0 — a gated actor won the pick), a
        // holder continue (Switch/FairYield with chosen < 0 — the holder
        // kept running). A park/exit close with chosen < 0 is the
        // quiescence strand: the virtual-timer wake — not a pin-able
        // decision — produced the blocked segment, so no alternative
        // continuation exists at this node (the paper's enabled set is
        // empty here; skip, losing only optimality).
        if (dec.chosen < 0 && !(dec.kind == PctEventKind.Switch) &&
            !(dec.kind == PctEventKind.FairYield)) {
            return
        }
        let blockedActor = data.segments[blockPos].actor // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        // The decision's own actor (from) is grantable only where the
        // runtime can grant it: at its own op boundary (the Keep entry —
        // a Switch close) or after a release (it stays Gated); not at a
        // fair yield or a park/exit close (it is running/parked, not
        // Gated — the runtime's isGated check would abandon the guide).
        let meGrantable = dec.kind == PctEventKind.Switch || // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
            dec.kind == PctEventKind.Unlock || dec.kind == PctEventKind.Release ||
            dec.kind == PctEventKind.Notify || dec.kind == PctEventKind.NotifyAll
        let enabled = dec.enabled
        // The inherited exclusions apply only at the decision where they
        // were established (the chain anchor): an actor blocked at an
        // earlier chain decision was never tried at THIS one.
        let inheritExclusions = task.excludedAt == d
        var cand: Int64 = -1
        var ei: Int64 = 0
        while (ei < Int64(enabled.size)) {
            let a = enabled[ei]
            var tried = false
            if (a == blockedActor) {
                tried = true
            }
            if (a == dec.from && !meGrantable) {
                tried = true
            }
            if (inheritExclusions) {
                tried ||= task.excluded.contains(a)
            }
            if (a >= 0 && !tried) {
                cand = a
                break
            }
            ei += 1
        }
        if (cand < 0) {
            return // every candidate completes a sleeping schedule
        }
        // The guide: the recorded decisions 0..d-1 (the same E1
        // synthesis) + the candidate grant at the blocked decision.
        let entries = dporGuidePrefix(data, d + 1, d)
        // The candidate's start entry at the blocked decision: the same
        // mechanism synthesis the σ-blocks use (dporSigmaEntry — a Keep
        // at the holder's own op boundary, a Grant otherwise; the
        // recorded wake strand at a quiescence close is excluded above).
        if (d == 0) {
            entries[0] = Grant(cand) // the initial release must grant
        } else {
            entries[d] = dporSigmaEntry(dec.kind, data.segments[d - 1].actor, cand, Some(dec))
        }
        if (exceedsSwitchBound(entries)) {
            pruned += 1
            return
        }
        let L = Int64(task.guide.size) // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        let marks = Array<Bool>(d + 1, { _ => false })
        let heads = Array<Bool>(d + 1, { _ => false })
        var j: Int64 = 0
        while (j < d + 1) {
            if (j < L) {
                marks[j] = task.marks[j]
                heads[j] = task.heads[j]
            }
            j += 1
        }
        let sib = DporPopTask(guide: entries, marks: marks, heads: heads, checkFrom: d,
            excludedAt: d)
        for (entry in task.schedExprs) {
            sib.schedExprs.add(entry)
        }
        if (inheritExclusions) {
            for (x in task.excluded) {
                sib.excluded.add(x)
            }
        }
        sib.excluded.add(blockedActor)
        // S3: register the signature; a salvaged window's re-derivation
        // of an already-pushed sibling is skipped (see pushedSigs).
        if (!pushTask(sib, dedup)) {
            return
        }
    }
}
