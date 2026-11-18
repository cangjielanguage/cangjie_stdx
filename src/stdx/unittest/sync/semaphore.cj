/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

internal package stdx.unittest.sync

import std.sync.Semaphore as SyncSemaphore
import stdx.unittest.concurrent.PctAcquireSemantics
import stdx.unittest.concurrent.PctSyncKey
import stdx.unittest.concurrent.pctGridDispatchRw
import stdx.unittest.concurrent.pctMedAcquire
import stdx.unittest.concurrent.pctMedRelease
import stdx.unittest.concurrent.pctNextSyncKeyId
import stdx.unittest.concurrent.pctSyncEnter
import stdx.unittest.concurrent.pctSyncExit

/**
 * PCT-instrumented `Semaphore`: `acquire` probes through the inner
 * non-blocking `tryAcquire` (atomically acquiring the full amount)
 * under the coordinator's lock, so uncontended acquisitions stay
 * event-invisible (the hold is tracked for the wait-for
 * graph); contended acquisitions by a PCT actor are mediated (a
 * `Wait` event keyed by this semaphore, the releaser's `Release`
 * yield-point flip, a `tryAcquire` retry on grant). Non-actor threads
 * take the runtime park directly, untracked. The public `tryAcquire`
 * and the `count` getter dispatch through the classified grid check
 * (acquisition success = write-class — the state changed; failure and
 * `count` = read-class — pure state observations), so probes of
 * contended state participate in the dependency bookkeeping.
 */
public class Semaphore <: PctSyncKey {
    private let inner: SyncSemaphore
    private let pctKey: Int64 = pctNextSyncKeyId()

    public init(count: Int64) {
        inner = SyncSemaphore(count)
    }

    public prop syncKeyId: Int64 {
        get() {
            pctKey
        }
    }

    public prop count: Int64 {
        get() {
            let c = inner.count
            pctGridDispatchRw(this, false)
            return c
        }
    }

    public func acquire(amount!: Int64 = 1): Unit {
        // The probe must call inner.tryAcquire DIRECTLY: probes run under
        // the coordinator lock inside medAcquire, and the public
        // tryAcquire dispatches a grid point (a coordinator re-entry —
        // self-deadlock).
        if (!pctMedAcquire(this, { => inner.tryAcquire(amount: amount) }, PctAcquireSemantics.AnyReleaser)) {
            pctSyncEnter()
            inner.acquire(amount: amount)
            pctSyncExit()
        }
    }

    public func tryAcquire(amount!: Int64 = 1): Bool {
        let ok = inner.tryAcquire(amount: amount)
        pctGridDispatchRw(this, ok)
        return ok
    }

    public func release(amount!: Int64 = 1): Unit {
        inner.release(amount: amount)
        pctMedRelease(this)
    }
}
