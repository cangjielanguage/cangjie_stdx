/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 *  * This source file is part of the Cangjie project, licensed under Apache-2.0
 *  * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

import std.collection.ArrayList
import std.collection.HashSet
import std.sync.AtomicInt64
import std.sync.AtomicOptionReference

/** The Serializability operation-count limit: histories with more
 *  operations than this are rejected by the validation guard instead of
 *  entering the permutation DFS (the model's search is factorial in the
 *  operation count). */
internal const SERIALIZABILITY_OP_LIMIT: Int64 = 10 // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics

// Per-call state for one ConsistencyValidator.validate() invocation.
//
// A single validate() call drives a single-threaded pruning-tree DFS, so the
// statistics and dead-end tracking below are not accessed concurrently and need
// not be atomic. They are kept out of the ConsistencyValidator instance so that
// parallel validate() calls (from parallel iteration execution) do not race on
// shared instance fields. The only state that is shared across calls is the
// memoisation tree (cachedTreeRoot/cachedTreeSize and the PermutationNode
// children/cachedResult fields), which is already lock-free (ConcurrentHashMap +
// AtomicOptionReference).
private class DfsContext {
    var operationChecks: Int64 = 0
    var cacheChecks: Int64 = 0
    var prunedBranches: Int64 = 0
    var foundPermutation: ?ArrayList<Int64> = None
    var deepestDeadEndDepth: Int64 = -1
    var deepestDeadEndPrefix: ArrayList<Int64> = ArrayList<Int64>()
    var deepestDeadEndMismatches: ArrayList<MismatchInfo> = ArrayList<MismatchInfo>()
}

protected class ConsistencyValidator {
    protected ConsistencyValidator(
        let consistencyModel!: ConsistencyModel,
        private let createFreshInstance!: () -> Any,
        private let reExecuteOperation!: (Any, OperationInvocation) -> EquatableObj
    ) {}

    // Cross-call memoisation tree. Under parallel iteration execution, multiple
    // validate() calls explore this tree concurrently; both fields are atomic
    // and the PermutationNode internals are lock-free, so no extra
    // synchronisation is required here.
    private let cachedTreeRoot: AtomicOptionReference<PermutationNode> = AtomicOptionReference<PermutationNode>()
    private let cachedTreeSize: AtomicInt64 = AtomicInt64(-1)

    protected func validate(history: ConcurrentHistory): ConsistencyValidationResult { // cjlint-ignore !G.FUN.01 single cohesive algorithm block; splitting it would scatter the invariant across helpers without simplifying any step
        let ctx = DfsContext()

        let po = computePartialOrder(history, consistencyModel)

        if (let Serializability <- consistencyModel && po.size > SERIALIZABILITY_OP_LIMIT) {
            // factorial(20) is the largest count that fits Int64; render
            // the exact permutation count only there, so the guard's own
            // error path never throws an arithmetic overflow instead of
            // the intended validation error.
            let permutationText = if (po.size <= 20) {
                "${factorial(po.size)} permutations"
            } else {
                "more than ${Int64.Max} permutations"
            }
            return ConsistencyValidationResult(
                consistencyModel: consistencyModel,
                matchingPermutation: None,
                operationChecks: 0,
                prunedBranches: 0,
                cacheHits: 0,
                history: history,
                partialOrder: po,
                exception: Some(IllegalArgumentException(
                    "Serializability check requires exhaustive search of all n! permutations. " +
                    "Current scenario has ${po.size} operations (${permutationText}), " +
                    "which exceeds the practical limit of ${SERIALIZABILITY_OP_LIMIT}. " +
                    "Consider using SequentialConsistency or Linearizability instead, " +
                    "or reduce the number of operations."
                ))
            )
        }

        // Best-effort reuse of the cross-call memoisation tree. If the cached
        // tree's size matches, reuse it; otherwise install a fresh root via CAS
        // (losing the CAS just means another concurrent call installed its own
        // root and we proceed with a local root for this call — correctness is
        // unaffected, only memoisation sharing is best-effort).
        var treeRoot: PermutationNode
        let existingRoot = cachedTreeRoot.load()
        let existingSize = cachedTreeSize.load()
        if (let Some(root) <- existingRoot && existingSize == po.size) {
            treeRoot = root
        } else {
            treeRoot = PermutationNode(operation: None, depth: 0)
            if (cachedTreeRoot.compareAndSwap(existingRoot, Some(treeRoot))) {
                cachedTreeSize.store(po.size)
            }
        }

        let placed = HashSet<Int64>()
        let prefixOps = ArrayList<Int64>()
        pruningTreeDFSRecursive(ctx, treeRoot, po, history, placed, prefixOps, None, 0)

        ConsistencyValidationResult(
            consistencyModel: consistencyModel,
            matchingPermutation: ctx.foundPermutation,
            operationChecks: ctx.operationChecks,
            prunedBranches: ctx.prunedBranches,
            cacheHits: ctx.cacheChecks,
            history: history,
            partialOrder: po,
            deadEndPrefix: ctx.deepestDeadEndPrefix.toArray(),
            deadEndMismatches: ctx.deepestDeadEndMismatches.toArray()
        )
    }

    private func pruningTreeDFSRecursive( // cjlint-ignore !G.FUN.01 single cohesive algorithm block; splitting it would scatter the invariant across helpers without simplifying any step
        ctx: DfsContext,
        node: PermutationNode,
        po: PartialOrder,
        hist: ConcurrentHistory,
        placed: HashSet<Int64>,
        prefixOps: ArrayList<Int64>,
        state: ?Any,
        depth: Int64
    ): Bool {
        let available = po.getAvailableOperations(placed)

        if (available.size == 0) {
            if (prefixOps.size > 0) {
                ctx.foundPermutation = copyPermutation(prefixOps)
                return true
            }
            return false
        }
        var currentState: ?Any = state // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        let localMismatches = ArrayList<MismatchInfo>()
        for (opId in available) {
            let child = node.ensureChild(opId)

            let actorId = opId / 1000
            let opIndex = opId % 1000
            let inv = hist.getInvocation(actorId, opIndex) ?? return false

            var recurseState: ?Any = None
            var isMatch = false
            var consumedState = false
            var seqResult: ?EquatableObj = None

            // Lock-free compute-once over the shared cachedResult. A successful
            // CAS counts as a fresh operation check; a lost CAS means another
            // concurrent validate() computed the equivalent (idempotent) result
            // first and is counted as a cache hit.
            let cachedOpt = child.cachedResult.load()
            if (let Some(cachedRes) <- cachedOpt) {
                seqResult = Some(cachedRes)
                isMatch = cachedRes.eq(inv.result)
                ctx.cacheChecks += 1
            } else {
                let builtState = currentState.getOrDefault {
                    let s = createFreshInstance()
                    for (prefixOpId in prefixOps) {
                        let prefixInv = hist.getInvocation(prefixOpId / 1000, prefixOpId % 1000) ?? return false
                        reExecuteOperation(s, prefixInv)
                    }
                    s
                }

                let computedResult = reExecuteOperation(builtState, inv)
                if (child.cachedResult.compareAndSwap(None, Some(computedResult))) {
                    ctx.operationChecks += 1
                } else {
                    // Lost the race; the cached value is equivalent because
                    // re-execution is idempotent for a given prefix.
                    ctx.cacheChecks += 1
                }
                seqResult = Some(computedResult)
                isMatch = computedResult.eq(inv.result)
                recurseState = Some(builtState)
                consumedState = true
            }

            if (!isMatch) {
                if (let Some(expected) <- seqResult) {
                    localMismatches.add(MismatchInfo(operation: inv, expectedResult: expected))
                }
                ctx.prunedBranches += 1
                if (consumedState) { currentState = None }
                continue
            }

            placed.add(opId)
            prefixOps.add(opId)
            if (pruningTreeDFSRecursive(ctx, child, po, hist, placed, prefixOps, recurseState, depth + 1)) {
                return true
            }
            if (consumedState) { currentState = None }
            placed.remove(opId)
            prefixOps.remove(at: prefixOps.size - 1)
        }

        if (available.size > 0 && localMismatches.size == available.size) {
            if (depth > ctx.deepestDeadEndDepth) {
                ctx.deepestDeadEndDepth = depth
                ctx.deepestDeadEndPrefix = copyPermutation(prefixOps)
                ctx.deepestDeadEndMismatches = ArrayList<MismatchInfo>()
                for (m in localMismatches) {
                    ctx.deepestDeadEndMismatches.add(m)
                }
            }
        }

        return false
    }

    private func copyPermutation(permutation: ArrayList<Int64>): ArrayList<Int64> {
        let copy = ArrayList<Int64>()
        for (opId in permutation) {
            copy.add(opId)
        }
        copy
    }

    private func factorial(n: Int64): Int64 {
        if (n <= 1) { return 1 }
        var result: Int64 = 1
        for (i in 2..n + 1) {
            result *= i
        }
        result
    }
}
