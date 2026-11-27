/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 *  * This source file is part of the Cangjie project, licensed under Apache-2.0
 *  * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

import std.sync.AtomicOptionReference

// Immutable snapshot of a node's children, published atomically via the
// copy-on-write pattern in PermutationNode.ensureChild. Wrapped in a class
// (rather than using Array directly) because AtomicOptionReference requires
// T <: Object and Array is a struct in Cangjie.
class ChildSnapshot {
    let items: Array<PermutationNode>
    init(items: Array<PermutationNode>) { this.items = items }
}

// Node of the cross-iteration memoisation tree shared by ConsistencyValidator.
//
// The tree is reused across validate() calls (and, under parallel iteration
// execution, across concurrent validate() calls) to cache the sequential
// re-execution result of an operation applied to a given prefix of operations.
//
// Child storage uses a copy-on-write snapshot (AtomicOptionReference to a
// ChildSnapshot) rather than a ConcurrentHashMap. This is better for this use
// case because:
//   - Children-per-node is tiny (1-8, bounded by the number of available
//     operations at that DFS depth). Linear scan of a small contiguous array
//     is faster than hashing (no hashCode() call, better cache locality).
//   - The access pattern is extremely read-heavy: the tree grows monotonically
//     (children are never removed) and after warmup ensureChild becomes
//     effectively read-only. CopyOnWrite gives lock-free zero-contention reads.
//   - Per-node memory is zero for empty nodes (AtomicOptionReference starts as
//     None — no child array allocated until the first child is added) vs a
//     full ConcurrentHashMap instance (~200+ bytes) per node.
//   - Writes are rare and copying 1-8 pointers + one CAS is cheaper than a
//     ConcurrentHashMap insert.
protected class PermutationNode {
    public PermutationNode(
        public let operation!: ?Int64,
        public let depth!: Int64
    ) {}

    private let children: AtomicOptionReference<ChildSnapshot> = AtomicOptionReference<ChildSnapshot>()

    protected let cachedResult: AtomicOptionReference<EquatableObj> = AtomicOptionReference<EquatableObj>()

    // Get-or-insert: returns the existing child for opId if present, otherwise
    // creates one by publishing a new ChildSnapshot (old items + new entry
    // appended) via CAS. Concurrent calls from parallel validate() invocations
    // are safe:
    //   - Readers load the Option<ChildSnapshot> (atomic) and scan a snapshot
    //     that is never mutated after publication — no partial-state visibility.
    //   - Writers construct the new snapshot fully before the CAS, so readers
    //     never see unwritten slots. If two writers race, the CAS loser
    //     retries and finds the winner's entry (for the same opId) or appends
    //     after it (for a different opId). No duplicates, no gaps.
    /**
     * Return the child node for `opId`, creating it (and publishing the
     * grown snapshot) if absent; concurrent callers retry via CAS.
     *
     * @throws Exception on an internal invariant break (unreachable in
     * correct usage).
     */
    public func ensureChild(opId: Int64): PermutationNode {
        while (true) {
            let currentOpt = children.load()
            // Fast path: scan the current snapshot for an existing child.
            if (let Some(snapshot) <- currentOpt) {
                let child = snapshot.items.iterator().filter{ it => it.operation == Some(opId) }.next()
                if (let Some(child) <- child) {
                    return child
                }
            }
            // Not found — build a new snapshot with the candidate appended.
            let candidate = PermutationNode(operation: Some(opId), depth: depth + 1)
            let newSnapshot = match (currentOpt) { // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
                case Some(snapshot) =>
                    let oldItems = snapshot.items
                    let newArr = Array<PermutationNode>(oldItems.size + 1, repeat: candidate)
                    for (i in 0..oldItems.size) {
                        newArr[i] = oldItems[i]
                    }
                    ChildSnapshot(newArr)
                case None =>
                    ChildSnapshot(Array<PermutationNode>(1, repeat: candidate))
            }
            // CAS to publish. If another thread published a different snapshot
            // in the meantime, CAS fails and we retry (the re-scan will find
            // their entry if it was for the same opId).
            if (children.compareAndSwap(currentOpt, Some(newSnapshot))) {
                return candidate
            }
        }
        throw Exception("unreachable: while(true) never exits")
    }
}
