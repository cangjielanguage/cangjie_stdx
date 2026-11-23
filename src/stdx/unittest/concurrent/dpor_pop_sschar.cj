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

/**
 * The POP sleep-set characterization (the POP paper — CAV 2024 —
 * Section 4.3, Algorithm 2): a polynomial-space characterization of
 * the READ SCHEDULES that would revisit an already-explored
 * Mazurkiewicz class (the compatible read schedules from one write:
 * exploring "σ then σ′" and "σ′ then σ" visits one class twice).
 * Without it, POP is optimal except for these duplicate classes.
 *
 * A schedule expression is (i) P ⊳ x — characterizing the contained
 * and conflicting read-x-schedules (Proposition 1 cases (A) and (B))
 * — or (ii) P[φ] ⊳ x — characterizing the inherited ones (case (C)),
 * where P is a P-sequence: the creating window's E2 events with the
 * embedded σ-blocks' events removed but their HEADS kept as markers,
 * and φ is the characterization created for an embedded read-schedule.
 * A sleep set expression augments the schedule expression with: a
 * conflict set C per P event (the encountered events that conflict
 * with it, or happen-after a conflicting event), a set D of
 * encountered inner-schedule heads per bracket, and a set R of
 * previously-encountered read-x-events per ⊳x.
 *
 * ENGINE ADAPTATION (all driver-side — the scheduler and the
 * coordinator are untouched): the characterization is a pure function
 * of the PATH (the recorded execution prefix) and the expressions
 * created along it, so each window REPLAYS its own recording from the
 * root's empty state, injecting (clones of) the task-carried
 * expressions when the replay passes their head events (matched by the
 * (actor, ordinal) segment identity plus the structural-prefix
 * fingerprint — stable across windows while the actor's preceding
 * sync-op structure agrees). Events reference their keys through
 * weak snapshots (the offset layer, dporWeakMatchesStrong); the
 * happens-before checks resolve references against the current
 * window's position map and hb relation. A block at a fresh position
 * cuts the window's race processing (the tail explored a duplicate
 * class) and pushes one sibling task with the next candidate
 * continuation at the blocked decision.
 */

/** One event reference inside a sleep-set expression: the (actor,
 * ordinal) segment identity plus the event's sync-key notes in weak
 * snapshot form (the cross-window key identity), the actor's
 * structural-prefix fingerprint at the event (see [[dporSsHistFp]]),
 * and... the fingerprint alone distinguishes the ordinal shifts that
 * data-dependent control flow (a retrying RMW) creates: the (actor,
 * ordinal) identity is only stable across windows while the actor's
 * preceding sync-op structure agrees. */
internal struct DporSsRef {
    internal DporSsRef(
        internal let actor!: Int64,
        internal let ordinal!: Int64,
        internal let histFp!: UInt64,
        internal let keyNotes!: Array<DporWeakKeyNote>
    ) {}
}

// Fingerprint mixing constants of dporSsHistFps. Arbitrary odd
// multipliers; the only requirements are that they differ and that the
// mixing wraps (the function is @OverflowWrapping).
internal const SSCHAR_FP_BASE: UInt64 = 1315423911u64 // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
internal const SSCHAR_FP_STEP: UInt64 = 1000003u64 // cjlint-ignore !G.VAR.02 module-level named constant: documented once and shared by the fingerprint mixing below; inlining it into a function scope would hide the tunable
// Stride between sync-note kind codes in the mixed value (1–2 and 4–5
// stay apart).
internal const SSCHAR_KIND_STRIDE: UInt64 = 65537u64 // cjlint-ignore !G.VAR.02 module-level named constant: documented once and shared by the fingerprint mixing below; inlining it into a function scope would hide the tunable
// The synthetic key fingerprint standing in for a keyless note: 2^62 —
// out of the range of any real in-object offset, so a keyless note can
// never collide with a keyed one.
internal const SSCHAR_NO_OFFSET_SENTINEL: UInt64 = 4611686018427387904u64 // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics

/**
 * The per-position structural-prefix fingerprints of one recording:
 * for each position i, a hash of ACTOR(i)'s preceding segments — each
 * segment contributing its note signature (the sync-op kinds and
 * logical keys in order; note-less segments contribute a separator, so
 * the segment COUNT enters the hash). The (actor, ordinal) segment
 * identity is NOT stable across windows under data-dependent control
 * flow: a retrying RMW (a failed compare-and-swap) adds segments, so
 * one window's (A, 2) is the actor's `get` while another's is the
 * retry load. The prefix fingerprint distinguishes them: the same
 * program point with the same preceding sync-op structure hashes
 * equal, a shifted structure (almost surely) does not. A
 * fingerprint mismatch in a contained-schedule identity check only
 * under-blocks — sound.
 */
@OverflowWrapping
internal func dporSsHistFps(data: DporRunData): Array<UInt64> {
    let n = Int64(data.segments.size)
    let fps = HashMap<Int64, UInt64>() // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
    let out = Array<UInt64>(n, { _ => 0u64 })
    var i: Int64 = 0
    while (i < n) {
        let seg = data.segments[i]
        let base = match (fps.get(seg.actor)) {
            case Some(v) => v
            case None => 0u64
        }
        out[i] = base
        var fp = base * SSCHAR_FP_BASE + 7u64 // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        for (nt in seg.keyNotes) {
            let kindNum: UInt64 = match (nt.kind) {
                case PctSyncNoteKind.Acquire => 1u64
                case PctSyncNoteKind.Release => 2u64
                case PctSyncNoteKind.AtomicRead => 4u64
                case PctSyncNoteKind.AtomicWrite => 5u64
            }
            let keyFp: UInt64 = if (nt.offsetValid) {
                UInt64(nt.offset)
            } else {
                SSCHAR_NO_OFFSET_SENTINEL
            }
            fp = fp * SSCHAR_FP_STEP + kindNum * SSCHAR_KIND_STRIDE + keyFp
        }
        fps.add(seg.actor, fp)
        i += 1
    }
    return out
}

/** Do the reference's weak notes and the event's notes describe the
 * same sync-op signature — pairwise equal kinds and matching keys? */
internal func dporSsNotesMatch(a: Array<DporWeakKeyNote>, b: Array<DporKeyNote>): Bool {
    if (a.size != b.size) {
        return false
    }
    var i: Int64 = 0
    while (i < Int64(a.size)) {
        let wa = a[i] // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        let sb = b[i] // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        if (!(wa.kind == sb.kind)) {
            return false
        }
        if (!dporWeakMatchesStrong(wa, wa.key.value, sb)) {
            return false
        }
        i += 1
    }
    return true
}

/** The result of one sleep-set-expression update: `Indep` (the event
 * touched nothing in the expression's P), `Updated` (it updated the
 * expression), or `Sleep` (the event would complete a sleeping read
 * schedule). */
internal enum DporSsRes <: Equatable<DporSsRes> {
    | Indep
    | Updated
    | Sleep

    public override operator func ==(other: DporSsRes): Bool { // cjlint-ignore !G.OPR.01 parameterless enum: the language requires this manual == to satisfy Equatable<T>; match-based constructor comparison is the only possible implementation
        match ((this, other)) {
            case (Indep, Indep) => true
            case (Updated, Updated) => true
            case (Sleep, Sleep) => true
            case _ => false
        }
    }

}

/** One P-sequence entry: an event of the creating window's E2 (with
 * its accumulating conflict set C), or a schedule-head marker {e} of
 * an embedded σ-block (a bracket in the sequence w0{e1}w1{e2}...). */
internal class DporSsPEntry {
    internal let isHead: Bool
    internal let ref: DporSsRef
    internal let conflicts: ArrayList<DporSsRef> = ArrayList<DporSsRef>()

    internal init(isHead!: Bool, ref!: DporSsRef) {
        this.isHead = isHead
        this.ref = ref
    }

    internal func cloneEntry(): DporSsPEntry {
        let c = DporSsPEntry(isHead: isHead, ref: ref)
        for (x in conflicts) {
            c.conflicts.add(x)
        }
        return c
    }
}

/** One sleep-set expression ψ: P ⊳ x^R (`inner == None` — the
 * contained/conflicting read-x-schedules) or P[ψ′]^D ⊳ x^R (the
 * inherited ones, characterized by the inner expression ψ′). Mutated
 * in place by the updates; cloned whenever a pristine copy must be
 * preserved (the task-carried expressions, the replay snapshots). */
internal class DporSsExpr {
    /** P: the E2 events (with conflict sets) and the embedded
     * schedule-head markers, in order. */
    internal let pSeq: ArrayList<DporSsPEntry> = ArrayList<DporSsPEntry>()
    /** x: the variable — the key the characterized schedules' heads
     * read (a weak snapshot). */
    internal let varKey: DporWeakKeyNote
    /** R: the previously encountered read-x events. */
    internal let reads: ArrayList<DporSsRef> = ArrayList<DporSsRef>()
    /** D: the encountered heads of the inner-characterized schedules
     * (the inner expression's read-y event heads). */
    internal let dset: ArrayList<DporSsRef> = ArrayList<DporSsRef>()
    /** ψ′: the inner expression (a clone of an embedded block's
     * characterization), or None for the simple form. */
    internal var inner: ?DporSsExpr = None

    internal init(varKey!: DporWeakKeyNote) {
        this.varKey = varKey
    }

    internal func cloneExpr(): DporSsExpr {
        let c = DporSsExpr(varKey: varKey)
        for (e in pSeq) {
            c.pSeq.add(e.cloneEntry())
        }
        for (r in reads) {
            c.reads.add(r)
        }
        for (d in dset) {
            c.dset.add(d)
        }
        match (inner) {
            case Some(i) => c.inner = Some(i.cloneExpr())
            case None => ()
        }
        return c
    }

    /** Does the expression contain ⊳y (at any nesting depth) for a
     * key y the event writes? (The UpdSeq discard rule: after a write
     * on y, a read-y-schedule can no longer be completed.) */
    internal func discardedBy(e: DporSsEventView): Bool {
        if (e.writesKey(varKey)) {
            return true
        }
        match (inner) {
            case Some(i) => return i.discardedBy(e)
            case None => return false
        }
    }
}

/** One created-expression set, anchored at the head event of the
 * σ-block it was created for (matched by the (actor, ordinal,
 * histFp) segment identity when a window's replay passes that event —
 * the injection point of the clones; the fingerprint conjunct rejects
 * a same-(actor, ordinal) event whose preceding sync-op structure
 * differs — a shifted trajectory's different logical event). The
 * anchored head is always a pinned prefix event of the carrying task,
 * so every descendant window that executes it in the same form injects
 * at the same point of the state evolution. */
internal struct DporSsEntry {
    internal DporSsEntry(
        internal let headActor!: Int64,
        internal let headOrdinal!: Int64,
        internal let headHistFp!: UInt64,
        internal let exprs!: ArrayList<DporSsExpr>
    ) {}
}

/** One recorded event viewed by the sleep-set updates: its window
 * position, its (actor, ordinal) identity plus structural-prefix
 * fingerprint, and its strong key notes (the refs stored into C/R/D
 * sets are weakened snapshots). */
internal struct DporSsEventView {
    internal DporSsEventView(
        internal let pos!: Int64,
        internal let actor!: Int64,
        internal let ordinal!: Int64,
        internal let histFp!: UInt64,
        internal let keyNotes!: Array<DporKeyNote>
    ) {}

    /** The event's weak-snapshot reference form. */
    internal func toRef(): DporSsRef {
        return DporSsRef(actor: actor, ordinal: ordinal, histFp: histFp,
            keyNotes: dporWeakenNotes(keyNotes))
    }

    /** Does the event READ the key (an AtomicRead note matching it)? */
    internal func readsKey(key: DporWeakKeyNote): Bool {
        for (n in keyNotes) {
            if (n.kind == PctSyncNoteKind.AtomicRead &&
                dporWeakMatchesStrong(key, key.key.value, n)) {
                return true
            }
        }
        return false
    }

    /** Does the event PURELY read the key — read it with an AtomicRead
     * note and NOT touch it with a write-class note (the paper's event
     * model has one access per event: e.T = R means a pure read; a
     * read-modify-write segment — a CAS loop's {load, compareAndSwap}
     * — is T = W on that key and can never head a read-x-schedule or
     * enter an R set). */
    internal func pureReadsKey(key: DporWeakKeyNote): Bool {
        if (!readsKey(key)) {
            return false
        }
        return !writesKey(key)
    }

    /** Does the event WRITE the key (a write-class note matching it
     * — the discard rule's trigger)? */
    internal func writesKey(key: DporWeakKeyNote): Bool {
        for (n in keyNotes) {
            if (!dporNoteIsRead(n.kind) &&
                dporWeakMatchesStrong(key, key.key.value, n)) {
                return true
            }
        }
        return false
    }

    /** Does the event STAND IN CONFLICT with the reference — the ↔
     * relation (Algorithm 2 line 34): DIFFERENT actors accessing the
     * same key with at least one write-class touch. */
    internal func conflictsWith(ref: DporSsRef): Bool {
        return actor != ref.actor && dporNotesDependentW(ref.keyNotes, keyNotes)
    }

    /** Is the event DEPENDENT on the reference — the ▷◁ relation: the
     * same actor (program order) or a shared key with at least one
     * write-class touch. */
    internal func dependsOn(ref: DporSsRef): Bool {
        if (actor == ref.actor) {
            return true
        }
        return dporNotesDependentW(ref.keyNotes, keyNotes)
    }
}

/** The per-window context for the sleep-set updates: the
 * happens-before relation (DporPopHb) and the (actor, ordinal) to
 * (position, structural-prefix fingerprint) map for resolving event
 * references against the current recording. A reference resolves only
 * when the position's fingerprint matches the reference's: the (actor,
 * ordinal) identity is stable across windows only while the actor's
 * preceding sync-op structure agrees (see [[dporSsHistFps]]), so a
 * same-ordinal different-structure resolution is a different logical
 * event and does not resolve.
 */
internal class DporSsCtx {
    private let hb: DporPopHb
    private let refPos: HashMap<String, (Int64, UInt64)>

    internal init(data!: DporRunData, hb!: DporPopHb, histFps!: Array<UInt64>) {
        this.hb = hb
        refPos = HashMap<String, (Int64, UInt64)>()
        var j: Int64 = 0
        while (j < Int64(data.segments.size)) {
            let s = data.segments[j]
            refPos.add("${s.actor}:${s.ordinal}", (j, histFps[j]))
            j += 1
        }
    }

    /** The reference's position in this window (-1 when it did not
     * execute here, or when the same (actor, ordinal) executed with a
     * different structural prefix — a different logical event of a
     * shifted trajectory; either way it cannot happen-before
     * anything). */
    internal func posOf(ref: DporSsRef): Int64 {
        match (refPos.get("${ref.actor}:${ref.ordinal}")) {
            case Some((p, fp)) =>
                if (fp == ref.histFp) {
                    p
                } else {
                    -1
                }
            case None => -1
        }
    }

    /** ref →hb e (the reference executed earlier in this window and
     * happens-before the event's position; a read event is always
     * notable, and DporPopHb.hbTo covers note-less references). A
     * reference resolving at or after the event's position cannot
     * happen-before it: hb is a subset of the recorded order, so a
     * same-actor resolution past the event (an ordinal shift in a
     * replayed window) is not program order — claiming it would
     * over-block and skip a Mazurkiewicz class. */
    internal func hbBefore(ref: DporSsRef, e: DporSsEventView): Bool {
        let p = posOf(ref)
        if (p < 0 || p >= e.pos) {
            return false
        }
        return hb.hbTo(p, e.pos)
    }

    /** Do the P-sequence's head markers happen-before e? `upto` < 0
     * means all of them; otherwise only the first `upto` (the heads
     * embedded before the wj where an update stopped — Algorithm 2
     * line 37; lines 18/23 use all). */
    internal func headsHbBefore(psi: DporSsExpr, upto: Int64, e: DporSsEventView): Bool {
        var seen: Int64 = 0 // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        for (entry in psi.pSeq) {
            if (!entry.isHead) {
                continue
            }
            if (upto >= 0 && seen >= upto) {
                break
            }
            seen += 1
            if (!hbBefore(entry.ref, e)) {
                return false
            }
        }
        return true
    }

    /** Does some event of the sequence happen-before e? */
    internal func anyHbBefore(refs: ArrayList<DporSsRef>, e: DporSsEventView): Bool {
        for (r in refs) {
            if (hbBefore(r, e)) {
                return true
            }
        }
        return false
    }

    /** Does some D event that reads a variable OTHER than x
     * happen-before e? (Algorithm 2 line 17 — the inherited-head case
     * (C)1: the D heads read the inner expression's variable, which
     * differs from x.) */
    internal func anyDHbBeforeDiffVar(dset: ArrayList<DporSsRef>,
        x: DporWeakKeyNote, e: DporSsEventView): Bool {
        for (d in dset) {
            if (refReadsKey(d, x)) {
                continue // d.var == x — not the (C)1 case
            }
            if (hbBefore(d, e)) {
                return true
            }
        }
        return false
    }

    /** Does the reference read the key (an AtomicRead snapshot note
     * matching x — the weak-weak match)? */
    private func refReadsKey(ref: DporSsRef, x: DporWeakKeyNote): Bool {
        for (n in ref.keyNotes) {
            if (n.kind == PctSyncNoteKind.AtomicRead && dporSsKeyMatch(x, n)) {
                return true
            }
        }
        return false
    }
}

/** The weak-weak key match: a live referent identity, or equal valid
 * offsets (the cross-window logical identity — the same rule as
 * dporWeakMatchesStrong, between two snapshots). */
internal func dporSsKeyMatch(a: DporWeakKeyNote, b: DporWeakKeyNote): Bool {
    match (a.key.value) {
        case Some(l) =>
            match (b.key.value) {
                case Some(r) =>
                    if (refEq(l, r)) {
                        return true
                    }
                case None => ()
            }
        case None => ()
    }
    return a.offsetValid && b.offsetValid && a.offset == b.offset
}

/**
 * UpdP(e, P, x, R) — Algorithm 2 line 29: update the expression's
 * P-sequence with the event. The scan walks the P's event entries (the
 * head markers only advance the block index): at the first entry el^C
 * that the event conflicts with (e ▷◁ C — it conflicts with something
 * in el's conflict set — or e ↔ el directly), the event joins el's
 * conflict set; at the first entry the event IS (the e = el identity
 * — the path realized the predicted event), the entry is removed (the
 * schedule's prefix is being consumed). Either way the update stopped
 * at block wj; if the event is a read on x that happens-after all the
 * heads e1..ej embedded before wj, and no previously encountered
 * read-x event happens-before it, the event would complete a
 * contained (the removal) or conflicting (the conflict) read-x
 * schedule — Block. Otherwise the event joins R (line 39) and the
 * update continues. No stop at all — Indep (the event touched nothing
 * in P).
 */
internal func dporSsUpdP(e: DporSsEventView, psi: DporSsExpr, ctx: DporSsCtx): DporSsRes {
    var heads: Int64 = 0 // the schedule heads embedded before the stop
    var idx: Int64 = 0
    var stopped = false
    while (idx < Int64(psi.pSeq.size)) {
        let entry = psi.pSeq[idx]
        if (entry.isHead) {
            heads += 1
            idx += 1
            continue
        }
        var hit = e.conflictsWith(entry.ref) // e ↔ el
        if (!hit) {
            // e ▷◁ C_l: the event is dependent (same actor, or a shared
            // key with a write) on something in el's accumulated
            // conflict set.
            for (c in entry.conflicts) {
                if (e.dependsOn(c)) {
                    hit = true
                    break
                }
            }
        }
        if (hit) {
            // e ▷◁ C_l ∨ e ↔ el: the event joins el's conflict set.
            entry.conflicts.add(e.toRef())
            stopped = true
            break
        }
        if (e.actor == entry.ref.actor && e.ordinal == entry.ref.ordinal &&
            e.histFp == entry.ref.histFp && dporSsNotesMatch(entry.ref.keyNotes, e.keyNotes)) {
            // e = el: the path realized the predicted event — the P
            // sequence consumes it. The structural checks (the prefix
            // fingerprint and the note signature) guard the ordinal
            // shifts that data-dependent control flow (a retrying RMW)
            // creates: a shifted (actor, ordinal) is a different event.
            psi.pSeq.remove(at: idx)
            stopped = true
            break
        }
        idx += 1
    }
    if (!stopped) {
        return DporSsRes.Indep
    }
    if (e.pureReadsKey(psi.varKey)) {
        if (ctx.headsHbBefore(psi, heads, e)) {
            if (!ctx.anyHbBefore(psi.reads, e)) {
                return DporSsRes.Sleep
            }
            psi.reads.add(e.toRef())
        }
    }
    return DporSsRes.Updated
}

/**
 * UpdSE(e, ψ) — Algorithm 2 lines 12-27. The simple form (ψ =
 * P ⊳ x^R) forwards to UpdP. The nested form (ψ = P[ψ′]^D ⊳ x^R)
 * first runs UpdP on the outer P; on Indep the inherited cases
 * apply: (line 17) the event is a read on x that happens-after some
 * D head reading another variable — an inherited-schedule head
 * (case (C)1): block when it happens-after all the P heads and no
 * R read, else join R; (line 21) the inner update blocking: when the
 * inner's variable equals x, the event joins D and R and may block
 * (case (C)2), else it joins D; otherwise the inner's result is
 * forwarded.
 */
internal func dporSsUpdSE(e: DporSsEventView, psi: DporSsExpr, ctx: DporSsCtx): DporSsRes {
    let r = dporSsUpdP(e, psi, ctx)
    let innerExpr = psi.inner ?? return r
    if (r != DporSsRes.Indep) {
        return r
    }
    // Indep: the outer P untouched — the inherited cases.
    if (e.pureReadsKey(psi.varKey) && ctx.anyDHbBeforeDiffVar(psi.dset, psi.varKey, e)) {
        // Line 17-20: an inherited-schedule head (case (C)1).
        if (!ctx.anyHbBefore(psi.reads, e) && ctx.headsHbBefore(psi, -1, e)) {
            psi.reads.add(e.toRef())
            return DporSsRes.Sleep
        }
        psi.reads.add(e.toRef())
        return DporSsRes.Updated
    }
    let ri = dporSsUpdSE(e, innerExpr, ctx)
    if (ri == DporSsRes.Sleep) {
        if (dporSsKeyMatch(psi.varKey, innerExpr.varKey)) {
            // Line 22-25: the case (C)2 inherited head on the
            // same variable — joins D and R, and may block.
            if (!ctx.anyHbBefore(psi.reads, e) && ctx.headsHbBefore(psi, -1, e)) {
                psi.dset.add(e.toRef())
                psi.reads.add(e.toRef())
                return DporSsRes.Sleep
            }
            psi.dset.add(e.toRef())
            psi.reads.add(e.toRef())
            return DporSsRes.Updated
        }
        // Line 26: a different variable — joins D only.
        psi.dset.add(e.toRef())
        return DporSsRes.Updated
    }
    return ri
}

/**
 * The per-event step of UpdSeq (Algorithm 2 lines 7-11): block if any
 * expression blocks; otherwise update every expression and apply the
 * discard rule (after a write on y, every expression containing ⊳y at
 * any depth is discarded — a read-y-schedule can no longer be
 * completed). The caller stops at the first block at a fresh position
 * (the tail explored a duplicate class); the state is otherwise
 * evolved in place.
 */
internal func dporSsProcessEvent(state: ArrayList<DporSsExpr>,
    e: DporSsEventView, ctx: DporSsCtx): DporSsRes {
    for (psi in state) {
        if (dporSsUpdSE(e, psi, ctx) == DporSsRes.Sleep) {
            return DporSsRes.Sleep
        }
    }
    var i: Int64 = 0
    while (i < Int64(state.size)) {
        if (state[i].discardedBy(e)) {
            state.remove(at: i)
        } else {
            i += 1
        }
    }
    return DporSsRes.Updated
}

/** Clone a state (a fresh set of cloned expressions). */
internal func dporSsCloneState(state: ArrayList<DporSsExpr>): ArrayList<DporSsExpr> {
    let out = ArrayList<DporSsExpr>()
    for (psi in state) {
        out.add(psi.cloneExpr())
    }
    return out
}

/**
 * Inject the task-carried expressions anchored at the event into the
 * state (cloned — the task's pristine copies are never mutated): the
 * expression set created for the σ-block whose head the event just
 * realized enters the state right after that head's update, exactly
 * where the creating child-construction stored it. The head match is
 * the full (actor, ordinal, histFp) identity: entries whose heads
 * never execute in this window (blocks dropped by a later reversal)
 * never inject, and neither do entries whose head (actor, ordinal)
 * resolved on a different structural prefix (a shifted trajectory —
 * data-dependent control flow changed the actor's op structure, so
 * the same ordinal is a different logical event). Both misses only
 * under-block — sound.
 */
internal func dporSsInject(task: DporPopTask, seg: DporSegmentData,
    segHistFp: UInt64, state: ArrayList<DporSsExpr>): Unit {
    for (entry in task.schedExprs) {
        if (entry.headActor == seg.actor && entry.headOrdinal == seg.ordinal &&
            entry.headHistFp == segHistFp) {
            for (psi in entry.exprs) {
                state.add(psi.cloneExpr())
            }
        }
    }
}

/**
 * MkSchedChar(σ, E1, e, E2) — Algorithm 2 line 1, driver-side over the
 * RECORDED window of the race (p, q) (e at position p, the head e′ at
 * position q; E2 = positions p+1..q). The E2 decomposition: the
 * embedded marked σ-blocks (σ1..σm with their heads — the marked runs
 * within (p, q), each ending at its marked head) and the runs between
 * them, from which the NEW σ's own events (`sig` — the hb-predecessors
 * of e′ and e′ itself) are also removed: the P-sequence is E2's events
 * minus every σ member — the new one's and the embedded blocks' — with
 * the embedded blocks' heads kept as markers (wj′ = wj\σ). Returns the
 * schedule expressions — one set per key x the head READS that e WRITES
 * (typically one): the simple form Pm ⊳ x (the contained and conflicting
 * schedules) and one nested form Pi-1[φi] ⊳ x per embedded READ-schedule
 * σi per characterization φi created for it (the inherited schedules —
 * case (C), where the branch point Pi-1 is the P-sequence up to the σi
 * block's marker).
 */
internal func dporSsMkSchedChar(data: DporRunData, task: DporPopTask, // cjlint-ignore !G.FUN.01 single cohesive algorithm block; splitting it would scatter the invariant across helpers without simplifying any step
    histFps: Array<UInt64>, p: Int64, q: Int64, e: DporSsEventView, head: DporSsEventView,
    sig: ArrayList<Int64>): ArrayList<DporSsExpr> {
    let out = ArrayList<DporSsExpr>()
    // The ∝ order's variables x: each key the head PURELY READS that e
    // WRITES (the characterized races are eW ≲ eR — a write→read race on
    // x; Algorithm 1 line 9 gates the characterization on e′.T = R, and
    // the paper's setup E = E1·eW·w·eR has eW writing x — a segment that
    // also writes x — a CAS's {load, compareAndSwap} — is T = W and
    // heads no read-x-schedule).
    let mL = Int64(task.marks.size) // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
    for (hn in head.keyNotes) { // cjlint-ignore !G.FUN.01 nesting mirrors the linear match>for>if structure of the validation/exploration algorithm; each level performs one distinct step with an early exit, so flattening would obscure the flow
        if (!(hn.kind == PctSyncNoteKind.AtomicRead)) {
            continue
        }
        if (head.writesKey(dporWeakenNote(hn))) {
            continue // the head writes x too — not a pure read (T = W)
        }
        var eWrites = false
        for (en in e.keyNotes) {
            if (!dporNoteIsRead(en.kind) && refEq(en.key, hn.key)) {
                eWrites = true
                break
            }
        }
        if (!eWrites) {
            continue
        }
        // The E2 decomposition: the runs of positions p+1..q-1.
        // marked runs: the embedded σ-blocks (the head at each run's end);
        // the w-runs are the unmarked positions between them. Build the
        // flat P-entry list (the E2 events with the blocks' events removed
        // but their heads kept as markers, at their block positions) and,
        // per embedded block, the P-entry index its branch point truncates
        // to (the Pi-1 length = the entries before the block's marker).
        let flat = ArrayList<DporSsPEntry>()
        let blocks = ArrayList<(Int64, Int64)>() // (piLen, headPos) per embedded block
        var k: Int64 = p + 1
        while (k < q) {
            if (k < mL && task.marks[k]) {
                var runEnd = k
                while (runEnd + 1 < q && runEnd + 1 < mL && task.marks[runEnd + 1]) {
                    runEnd += 1
                }
                blocks.add((Int64(flat.size), runEnd))
                // The block's events are REMOVED from the P; its head stays
                // as a marker {e_i} at the block's position.
                let headSeg = data.segments[runEnd]
                flat.add(DporSsPEntry(isHead: true, ref: DporSsRef(
                    actor: headSeg.actor, ordinal: headSeg.ordinal,
                    histFp: histFps[runEnd],
                    keyNotes: dporWeakenNotes(headSeg.keyNotes))))
                k = runEnd + 1
            } else {
                // The NEW σ's own events (the hb-predecessors of the head)
                // are removed from the P as well (wj' = wj\σ): they re-run
                // inside the child's pinned schedule, not around it.
                var inSig = false
                var si: Int64 = 0
                while (si < Int64(sig.size)) {
                    if (sig[si] == k) {
                        inSig = true
                    }
                    si += 1
                }
                if (!inSig) {
                    let seg = data.segments[k]
                    flat.add(DporSsPEntry(isHead: false, ref: DporSsRef(
                        actor: seg.actor, ordinal: seg.ordinal,
                        histFp: histFps[k],
                        keyNotes: dporWeakenNotes(seg.keyNotes))))
                }
                k += 1
            }
        }
        // The simple form Pm ⊳ x (the full flat list — possibly empty: an
        // empty P is inert for contained/conflicting schedules but still
        // tracks the variable through the discard rule).
        let simple = DporSsExpr(varKey: dporWeakenNote(hn)) // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        for (entry in flat) {
            simple.pSeq.add(entry.cloneEntry())
        }
        out.add(simple)
        // The nested forms Pi-1[φi] ⊳ x per embedded read-schedule σi per
        // characterization φi created for it. σi is a read-schedule iff
        // its head was characterized (the entries anchored at the head
        // exist only if the head purely read their variable when the
        // characterization was created).
        var bi: Int64 = 0
        while (bi < Int64(blocks.size)) {
            let (piLen, headPos) = blocks[bi] // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
            let headSeg = data.segments[headPos] // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
            var f: Int64 = 0
            while (f < Int64(task.schedExprs.size)) {
                let entry = task.schedExprs[f]
                // The full (actor, ordinal, histFp) head identity, like
                // dporSsInject: a shifted trajectory can realize the same
                // (actor, ordinal) as a different structural event, and a
                // binary match would attach the wrong φ to the nested
                // characterization — silently skipping exploration.
                if (entry.headActor == headSeg.actor && entry.headOrdinal == headSeg.ordinal &&
                    entry.headHistFp == histFps[headPos]) {
                    for (phi in entry.exprs) {
                        let nested = DporSsExpr(varKey: dporWeakenNote(hn))
                        var fi: Int64 = 0
                        while (fi < piLen) {
                            nested.pSeq.add(flat[fi].cloneEntry())
                            fi += 1
                        }
                        nested.inner = Some(phi.cloneExpr())
                        out.add(nested)
                    }
                }
                f += 1
            }
            bi += 1
        }
    }
    return out
}
