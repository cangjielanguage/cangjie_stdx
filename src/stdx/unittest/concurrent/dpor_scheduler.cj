/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

import std.collection.ArrayList
import std.ref.CleanupPolicy
import std.ref.WeakRef

/**
 * One guide entry: the driver's forced decision at a decision index
 * (the POP driver — dpor_pop.cj — builds guides from its task stack of
 * recorded windows). `Keep` orders the holder to keep the token (a
 * valid entry only at op-boundary/grid decisions); `Grant` moves the
 * token to the actor; `Strand` orders the -1 pick — the token releases
 * and nobody is granted (a valid entry only at transfer decisions,
 * where the coordinator's quiescence path then fires the earliest
 * virtual timer or the drain push, reproducing the recorded wake
 * mechanism). An entry naming a target that is not enabled at its site
 * is a structural divergence after a modified prefix — the rest of the
 * guide is abandoned and the fresh policy takes over (the POP driver
 * counts the window diverged and drops the branch).
 */
internal enum DporGuideEntry {
    | Keep
    | Grant(Int64)
    | Strand
}

/**
 * One recorded decision of a DPOR window run: the global decision index
 * (the guide key), the PCT event kind it recorded, the deciding actor,
 * the pick's outcome (-1 = keep/strand/park-handoff-to-nobody), the
 * enabled snapshot ({from} ∪ gated — the alternative grant targets that
 * existed at this point; the race scan reads it to decide whether a
 * racing actor could have been scheduled earlier).
 *
 * `chosen` records the PICK's return; a quiescence virtual-timer fire
 * (the base's fireTimer after a -1 pick at a park/exit) grants its
 * waiter without a pick — the recorded schedule's event stream carries
 * the true grant there.
 */
internal struct DporDecisionData {
    internal DporDecisionData(
        internal let index!: Int64,
        internal let kind!: PctEventKind,
        internal let from!: Int64,
        internal let chosen!: Int64,
        internal let enabled!: Array<Int64>
    ) {}
}

/**
 * One noted sync touch: the key plus HOW the segment touched it (the
 * dependency oracle lets two `AtomicRead` notes of the same key commute;
 * the race reporter pairs Release-notes with later Acquire-notes of the
 * same key into happens-before edges — see PctSyncNoteKind).
 *
 * `offsetValid` marks a STATE-PHASE key — one whose sync-key ID
 * ([[PctSyncKey]]) was drawn between the window's base (before the
 * schedule's state factory) and its state boundary (after the ops
 * composition) — carrying the window-relative offset `id - base`. The
 * k-th state-phase key of one schedule is the same logical object as
 * the k-th of any other (the stateless integration contract), so the
 * cross-window snapshot layer matches such keys by offset equality.
 * Everything else (mid-window creations, objects predating the window,
 * id-less keys like futures) has `offsetValid == false` and matches by
 * object identity alone (the conservative pre-offset semantics).
 */
internal struct DporKeyNote {
    internal DporKeyNote(
        internal let key!: Object,
        internal let kind!: PctSyncNoteKind,
        internal let offsetValid!: Bool,
        internal let offset!: Int64
    ) {}
}

/**
 * The snapshot form of a key note (what the sleep-characterization
 * references retain — dpor_pop_sschar.cj): the key is held through a
 * `WeakRef` (EAGER cleanup), so the driver never strongly retains a
 * window's sync objects — a decayed referent simply cannot
 * identity-match anything anymore. The logical offset (see
 * [[DporKeyNote]]) survives the referent's death and keeps matching.
 */
internal struct DporWeakKeyNote {
    internal DporWeakKeyNote(
        internal let key!: WeakRef<Object>,
        internal let offsetValid!: Bool,
        internal let offset!: Int64,
        internal let kind!: PctSyncNoteKind
    ) {}
}

/**
 * One recorded segment: an actor's execution between consecutive
 * decision points, closing at `decisionIndex` (the invariant: the
 * decision that started it is decisionIndex - 1 — a grant to the actor
 * or the actor's own keep). `keyNotes` are the synchronizing keys the
 * coordinator noted for the segment, with their kinds (the terminal
 * atomic/lock/condition/future identity — see
 * PctBaseScheduler.noteSync); two segments of different actors are
 * DEPENDENT iff they share a key that at least one side touched with a
 * non-read note (the sync partial order the driver reduces over —
 * `dporNotesDependent`). `accesses` is the segment's mtrace memory
 * traffic (canonical addresses; empty without an mtrace runtime).
 */
internal struct DporSegmentData {
    internal DporSegmentData(
        internal let actor!: Int64,
        internal let ordinal!: Int64,
        internal let keyNotes!: Array<DporKeyNote>,
        internal let decisionIndex!: Int64,
        internal let accesses!: Array<MtraceEvent>
    ) {}
}

/** A spawn happens-before edge: the spawner's in-progress segment (the
 * one containing the spawn site) into the child's first segment. */
internal struct DporSpawnEdge {
    internal DporSpawnEdge(
        internal let spawner!: Int64,
        internal let spawnerOrdinal!: Int64,
        internal let child!: Int64
    ) {}
}

/**
 * One recorded obstruction (the ThrowObstruction branch of the
 * starvation recovery): the obstructed actor, the completed decision
 * whose keep triggered the streak (the rescue child replaces that
 * decision's guide entry with a Grant — the mid-spin handoff), and the
 * gated peers at the moment (the rescue candidates — each becomes a
 * child).
 */
internal struct DporObstructionData {
    internal DporObstructionData(
        internal let actor!: Int64,
        internal let decisionIndex!: Int64,
        internal let peers!: Array<Int64>
    ) {}
}

/**
 * The collected exploration data of one DPOR window run: the decision
 * sequence, the segment sequence, and the guide-abandonment diagnostics.
 * The driver consumes this after the window closes.
 */
internal class DporRunData {
    internal let decisions = ArrayList<DporDecisionData>()
    internal let segments = ArrayList<DporSegmentData>()
    internal let spawnEdges = ArrayList<DporSpawnEdge>()
    internal let obstructions = ArrayList<DporObstructionData>()
    internal var guideAbandoned: Bool = false
    internal var guideAbandonedAt: Int64 = -1
}

/**
 * The DPOR scheduling policy (the sibling of PctScheduler behind
 * PctBaseScheduler): guide-driven decisions with deterministic
 * defaults, plus the segment/decision bookkeeping the driver reduces
 * over.
 *
 * Decision policy:
 *  - While a guide entry exists at the current decision index, it is
 *    consumed and applied (validated against the live gated set — the
 *    releaser itself is a valid unlock/notify target because the
 *    coordinator gates it before the transfer; naturally rejected for
 *    parks/exits, where the decider is not Gated).
 *  - Past the guide (or after abandonment), the DEFAULT policy is
 *    obstruction-free solo execution: keep the token at op boundaries
 *    and grid points; at a token release (park/unlock/exit) grant the
 *    LOWEST-SLOT gated actor. The driver adds every interesting
 *    preemption through guide entries — the default never preempts.
 *
 * LOCK CONTRACT: like the base — every method runs under the
 * coordinator's lock.
 */
internal class DporScheduler <: PctBaseScheduler {
    private let guide: Array<DporGuideEntry>
    private var guidePos: Int64 = 0
    private let data = DporRunData()
    // The exploration-wide mtrace collector (translation map persists
    // across windows; collectSegment drains the closing segment's events).
    private let collector: ?DporTraceCollector
    // The window's sync-key ID bracket (see DporKeyNote): IDs drawn in
    // [keyBase, keyBoundary) belong to the schedule's state phase and
    // carry the window-relative offset (cross-window logical identity);
    // everything else matches by object identity alone.
    private let keyBase: Int64
    private let keyBoundary: Int64
    // Per-actor bookkeeping (lazily grown to the live slot count):
    // the sync notes taken for the actor's closing segment (key + kind
    // — the dependency oracle's input), and the actor's
    // segment ordinal counter.
    private let pendingNotes: ArrayList<ArrayList<DporKeyNote>> = ArrayList<ArrayList<DporKeyNote>>()
    private let segmentOrdinals: ArrayList<Int64> = ArrayList<Int64>()
    // The decision record being completed (onDecisionEnter opens it, the
    // pick hook closes it with the chosen value).
    private var pendingDecision: ?DporDecisionData = None

    internal init(guide!: Array<DporGuideEntry>,
        collector!: ?DporTraceCollector, starvationThreshold!: UInt64,
        obstructionPolicy!: ObstructionPolicy, keyBase!: Int64,
        keyBoundary!: Int64, table!: PctActorTable) {
        super(starvationThreshold: starvationThreshold, obstructionPolicy: obstructionPolicy, table: table)
        this.guide = guide
        this.collector = collector
        this.keyBase = keyBase
        this.keyBoundary = keyBoundary
    }

    /** The run's collected data (the driver reads it after the window). */
    internal func runData(): DporRunData {
        return data
    }

    /** Record the obstruction for the driver's rescue branches: the
     * last completed decision is the grid keep whose streak fired —
     * the rescue child replaces its guide entry with Grant(peer), so
     * the re-run transfers the token at the exact grid check instead
     * of truncating the operation. */
    protected override func onObstructionDetected(me: Int64, gatedPeers: Array<Int64>): Unit {
        data.obstructions.add(DporObstructionData(
            actor: me,
            decisionIndex: Int64(data.decisions.size) - 1,
            peers: gatedPeers))
    }

    // ------------------------------------------------------------------
    // Policy hooks.
    // ------------------------------------------------------------------

    protected override func onSyncKey(me: Int64, key: Object, kind: PctSyncNoteKind): Unit {
        ensureActorState(me)
        pendingNotes[me].add(dporClassifyKeyNote(key, kind))
    }

    /** Classify a noted key into the snapshot layer's logical-identity
     * model: a key whose sync-key ID was drawn in [keyBase, keyBoundary)
     * is STATE-PHASE — created by this schedule's deterministic setup
     * (state factory + ops composition), so its window-relative offset
     * denotes the same logical object in every schedule (the stateless
     * contract) and it matches across windows by offset equality.
     * Everything else — mid-window creations (schedule-dependent
     * allocation order), objects predating the window (reused state),
     * id-less keys (futures, raw std.sync objects) — keeps the exact
     * object-identity semantics. The single-active-window invariant (the
     * token protocol serializes wrapper creation) makes the
     * classification a deterministic function of the schedule, so
     * exploration determinism is preserved. */
    private func dporClassifyKeyNote(key: Object, kind: PctSyncNoteKind): DporKeyNote {
        var offsetValid = false
        var offset = Int64(0)
        if (let Some(sk) <- (key as PctSyncKey)) {
            let id = sk.syncKeyId
            if (id >= keyBase && id < keyBoundary) {
                offsetValid = true
                offset = id - keyBase
            }
        }
        return DporKeyNote(key: key, kind: kind, offsetValid: offsetValid, offset: offset)
    }

    /** The spawn happens-before edge: the spawner's in-progress segment
     * (its next ordinal — the segment containing the spawn site) into
     * the child's first segment. Initial actors (spawner -1) have no
     * edge: no actor's recorded accesses precede their spawn. */
    protected override func onChildRegistered(child: Int64, spawner: Int64): Unit {
        if (spawner >= 0) {
            ensureActorState(spawner)
            data.spawnEdges.add(DporSpawnEdge(
                spawner: spawner,
                spawnerOrdinal: segmentOrdinals[spawner],
                child: child))
        }
    }

    /**
     * A decision is being made for `me` (possibly -1: the runner's
     * initial release): drain the closing segment's mtrace events, close
     * `me`'s segment (taking its noted sync keys), snapshot the enabled
     * set, and open the decision record the pick hook completes.
     * Records unconditionally (a loaded PCTSchedule replay drives its
     * decisions through the log; a diverged replay's fresh picks then
     * still find their records — and a pure replay window's records are
     * simply never consumed).
     */
    protected override func onDecisionEnter(me: Int64, kind: PctEventKind, fromGrid: Bool): Unit {
        var accesses = Array<MtraceEvent>() // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        if (me >= 0) {
            if (let Some(c) <- collector) {
                accesses = c.collectSegment()
            }
            closeSegment(me, accesses)
        }
        pendingDecision = Some(DporDecisionData(
            index: Int64(data.decisions.size),
            kind: kind,
            from: me,
            chosen: Int64(-1),
            enabled: enabledSnapshot(me)
        ))
    }

    protected override func pickInitial(): Int64 {
        var to: Int64 = -1
        var stranded = false
        match (consumeGuide()) {
            case Some(Keep) =>
                // The initial release must grant somebody (or strand when
                // nobody is gated — the default pick's -1).
                abandonGuide()
            case Some(Grant(t)) =>
                if (table.isGated(t)) {
                    to = t
                } else {
                    abandonGuide()
                }
            case Some(Strand) =>
                // The ordered -1 (see pickTransferAny): valid only while
                // nobody is grantable.
                if (anyActorGated()) {
                    abandonGuide()
                } else {
                    stranded = true
                }
            case None => ()
        }
        if (to < 0 && !stranded) {
            to = pickLowestGated()
        }
        completeDecision(to)
        return to
    }

    protected override func pickOpBoundary(me: Int64): Int64 {
        var to: Int64 = -1
        match (consumeGuide()) {
            case Some(Keep) => () // the ordered keep
            case Some(Grant(t)) =>
                if (t != me) {
                    // A grant to the holder at its own boundary is a
                    // keep (no unguided preemption either way).
                    if (table.isGated(t)) {
                        to = t
                    } else {
                        abandonGuide()
                    }
                }
            case Some(Strand) => () // the ordered keep (never planned here: -1 is the default)
            case None => ()
        }
        // Default: keep running (no unguided preemption).
        completeDecision(to)
        return to
    }

    protected override func pickTransferAny(me: Int64, kind: PctEventKind): Int64 {
        var to: Int64 = -1
        var stranded = false
        match (consumeGuide()) {
            case Some(Keep) =>
                // A release must move the token (or strand); a Keep here
                // is a structural mismatch.
                abandonGuide()
            case Some(Grant(t)) =>
                // For unlock/notify kinds the releaser is Gated and a
                // valid target (it may win its own yield); for parks and
                // exits it is not Gated, so the same check rejects it.
                if (table.isGated(t)) {
                    to = t
                } else {
                    abandonGuide()
                }
            case Some(Strand) =>
                // The ordered -1: the token releases and nobody is
                // granted; the coordinator's quiescence path (the
                // virtual timer fire, then the drain push) reproduces
                // the recorded wake. VALID ONLY while nobody is
                // grantable — the recorded -1 means exactly that. With
                // a gated actor present, this prefix's state diverged
                // from the recorded one (stranding now would wait for an
                // external wake that never comes): abandon, and the
                // fresh policy grants.
                if (anyActorGated()) {
                    abandonGuide()
                } else {
                    stranded = true
                }
            case None => ()
        }
        if (to < 0 && !stranded) {
            to = pickLowestGated()
        }
        completeDecision(to)
        return to
    }

    protected override func pickFairYield(me: Int64): Int64 {
        var to: Int64 = -1
        match (consumeGuide()) {
            case Some(Keep) => abandonGuide()
            case Some(Grant(t)) =>
                if (t != me && table.isGated(t)) {
                    to = t
                } else {
                    abandonGuide()
                }
            case Some(Strand) =>
                // A recorded -1 is valid only while nobody ELSE is
                // grantable — the transfer pick's divergence rule, three
                // methods up. (The holder itself is Gated at this pick,
                // so the check is a gated PEER, not anyActorGated.)
                // With a gated peer the recording is stale: honoring it
                // keeps the holder spinning through the peer's progress,
                // defeating the fair-mode recovery that exists precisely
                // to break such spins (and the storm replays into future
                // guides, growing without bound) — abandon, and the
                // fresh policy grants. Without a peer the Strand is
                // legitimate: the fresh pick below also returns -1 (the
                // decision is identical either way), but the guide stays
                // ALIVE.
                if (table.hasGatedPeer(me)) {
                    abandonGuide()
                }
            case None => ()
        }
        if (to < 0) {
            // The fair-mode recovery pick: oldest-gated-first (the base's
            // pickOldestGatedOther), NOT the transfer picks' lowest-slot
            // rule — with >= 2 waiters spinning against a parked producer,
            // a slot-ordered pick grants the lowest waiter forever and
            // starves the producer (the multi-waiter livelock); park order
            // reaches the producer first by construction.
            to = pickOldestGatedOther(me)
        }
        completeDecision(to)
        return to
    }

    // ------------------------------------------------------------------
    // Internals.
    // ------------------------------------------------------------------

    private func consumeGuide(): ?DporGuideEntry {
        if (data.guideAbandoned || guidePos >= Int64(guide.size)) {
            return None
        }
        let e = guide[guidePos]
        guidePos += 1
        return Some(e)
    }

    /** Is ANY actor grantable right now? (The Strand entry's validity
     * condition: a recorded -1 transfer pick means nobody was.) */
    private func anyActorGated(): Bool {
        var i: Int64 = 0
        while (i < table.slotCount()) {
            if (table.isGated(i)) {
                return true
            }
            i += 1
        }
        return false
    }

    private func abandonGuide(): Unit {
        if (!data.guideAbandoned) {
            data.guideAbandoned = true
            data.guideAbandonedAt = guidePos - 1 // the entry that failed to apply
        }
    }

    private func completeDecision(chosen: Int64): Unit {
        if (let Some(d) <- pendingDecision) {
            data.decisions.add(DporDecisionData(
                index: d.index, kind: d.kind, from: d.from, chosen: chosen,
                enabled: d.enabled))
            pendingDecision = None
            return
        }
        // Defensive: a pick without a matching enter (cannot happen while
        // the templates open-then-pick in one invocation; kept total).
        data.decisions.add(DporDecisionData(
            index: Int64(data.decisions.size), kind: Switch, from: Int64(-1),
            chosen: chosen, enabled: Array<Int64>()))
    }

    /** Close `me`'s segment: take its noted sync keys (with kinds),
     * bump its ordinal, and record the segment (with its drained
     * memory traffic). */
    private func closeSegment(me: Int64, accesses: Array<MtraceEvent>): Unit {
        ensureActorState(me)
        let keyNotes = takePendingNotes(me)
        let ordinal = segmentOrdinals[me]
        segmentOrdinals[me] = ordinal + 1
        data.segments.add(DporSegmentData(
            actor: me, ordinal: ordinal, keyNotes: keyNotes,
            decisionIndex: Int64(data.decisions.size), accesses: accesses))
    }

    private func ensureActorState(me: Int64): Unit {
        while (Int64(pendingNotes.size) <= me) {
            pendingNotes.add(ArrayList<DporKeyNote>())
            segmentOrdinals.add(0)
        }
    }

    private func takePendingNotes(me: Int64): Array<DporKeyNote> {
        let notes = pendingNotes[me]
        let keyNotes = notes.toArray()
        notes.clear()
        return keyNotes
    }

    /** {me} ∪ gated at the decision (the actors that could run next). */
    private func enabledSnapshot(me: Int64): Array<Int64> {
        let out = ArrayList<Int64>()
        if (me >= 0) {
            out.add(me)
        }
        var i: Int64 = 0
        while (i < table.slotCount()) {
            if (i != me && table.isGated(i)) {
                out.add(i)
            }
            i += 1
        }
        return out.toArray()
    }

    /** The lowest-slot gated actor (the fresh default pick at a token
     * release or the initial release). */
    private func pickLowestGated(): Int64 {
        var i: Int64 = 0
        while (i < table.slotCount()) {
            if (table.isGated(i)) {
                return i
            }
            i += 1
        }
        return -1
    }
}

/** Is the note class a pure read (commutes with other reads of the key)?
 * Only `AtomicRead` (a load, or a FAILED compare-and-swap) commutes;
 * Acquire/Release lock notes are dependent in both directions (mutual
 * exclusion is an ordering), and `AtomicWrite` is write-class. */
internal func dporNoteIsRead(kind: PctSyncNoteKind): Bool {
    return kind == PctSyncNoteKind.AtomicRead
}

/** Wrap a current run's note into its weak snapshot form. */
internal func dporWeakenNote(y: DporKeyNote): DporWeakKeyNote {
    return DporWeakKeyNote(
        key: WeakRef<Object>(y.key, CleanupPolicy.EAGER),
        offsetValid: y.offsetValid,
        offset: y.offset,
        kind: y.kind)
}

/** Wrap a whole segment's notes into weak snapshot form (the
 * sleep-characterization references' snapshots — dpor_pop_sschar.cj). */
internal func dporWeakenNotes(notes: Array<DporKeyNote>): Array<DporWeakKeyNote> {
    let out = ArrayList<DporWeakKeyNote>()
    for (y in notes) {
        out.add(dporWeakenNote(y))
    }
    return out.toArray()
}

/** The cross-window key-match rule (the snapshot layer): a weak
 * snapshot note `x` (with `xLive` = its referent, if still alive)
 * matches a current run's note `y` iff the referent IS the current key
 * (exact object identity — scenarios that reuse sync objects across
 * schedules), or both carry valid logical offsets and the offsets are
 * EQUAL (fresh-state scenarios: the k-th state-phase key of one
 * schedule is the same logical object as the k-th of another — the
 * stateless integration contract, see PctSyncKey). The two halves never
 * disagree: a reused object predates every window after its own, so it
 * never carries a valid offset, and an offset match between different
 * windows is by construction between different (fresh) objects of the
 * same logical position. */
internal func dporWeakMatchesStrong(x: DporWeakKeyNote, xLive: ?Object, y: DporKeyNote): Bool {
    if (let Some(l) <- xLive) {
        if (refEq(l, y.key)) {
            return true
        }
    }
    return x.offsetValid && y.offsetValid && x.offset == y.offset
}

/**
 * The DPOR dependence oracle over note lists: two segments of different
 * actors are dependent iff they share a key that at least one side
 * touched with a WRITE-CLASS note (a same-key read-read pair commutes —
 * same-location reads are independent). Identity comparison throughout
 * (the coordinator's keys are wrapper objects, compared refEq
 * everywhere else).
 */
internal func dporNotesDependent(a: Array<DporKeyNote>, b: Array<DporKeyNote>): Bool {
    for (x in a) {
        for (y in b) {
            if (!refEq(x.key, y.key)) {
                continue
            }
            if (dporNoteIsRead(x.kind) && dporNoteIsRead(y.kind)) {
                continue // two reads of the same key commute
            }
            return true
        }
    }
    return false
}

/** The dependence oracle against a weak SNAPSHOT (the
 * sleep-characterization references — dpor_pop_sschar.cj): same
 * read/write-class rule as [[dporNotesDependent]], with the
 * cross-window match rule (`dporWeakMatchesStrong`) — a live referent
 * identity match, or equal logical offsets of two state-phase keys.
 * Snapshot notes that are both decayed and offset-less are skipped:
 * they can never match. */
internal func dporNotesDependentW(a: Array<DporWeakKeyNote>, b: Array<DporKeyNote>): Bool {
    for (x in a) {
        let xLive = x.key.value
        if (xLive.isNone() && !x.offsetValid) {
            continue // decayed and offset-less: can never match
        }
        for (y in b) {
            if (!dporWeakMatchesStrong(x, xLive, y)) {
                continue
            }
            if (dporNoteIsRead(x.kind) && dporNoteIsRead(y.kind)) {
                continue // two reads of the same key commute
            }
            return true
        }
    }
    return false
}
