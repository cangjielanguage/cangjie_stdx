/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent


import std.sync.AtomicInt64
import std.time.DateTime

/**
 * A happens-before counter used as a start gate for a scenario's actor
 * threads: `wait`/`waitSpin` block the calling thread until the counter
 * reaches `id`, then advance the counter past `id` (only the thread that
 * observes `counter == id` performs the swap). The scenario runner uses
 * one instance as the actors' simultaneous start signal.
 */
class HBClockCounter {
    let counter: AtomicInt64 = AtomicInt64(0)

    /**
     * Block until the counter reaches `id`, then advance it past `id`.
     *
     * @throws TimeoutException if `id` is not reached within `timeout`.
     */
    public func wait(id: Int64, timeout!: Duration = Duration.second): Unit {
        let startTime = DateTime.now() // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics

        while (counter.load() < id) {
            if (DateTime.now() - startTime > timeout) {
                throw TimeoutException("Timeout while waiting for ${id} to be reached. Current value: ${counter.load()}.")
            }
            sleep(Duration.millisecond * 10) // Sleep briefly to avoid busy waiting
        }
        counter.compareAndSwap(id, id + 1)
    }

    public func waitSpin(id: Int64): Unit {
        while (counter.load() < id) {
            // Busy wait without sleeping to ensure minimal delay and synchronization
        }
        counter.compareAndSwap(id, id + 1)
    }
}
