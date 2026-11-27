/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

import std.sync.Monitor

/**
 * The dynamic-spawn registrar of one PCT iteration
 * (pct_coordinator.cj owns and drives it): the registration coordination
 * furniture — the registered-actor count and the bounded registration
 * waits for the window's sequential initial-actor spawns. The runner
 * waits on the count after each initial spawn (awaitSpawnCount), which
 * keeps registration order — and with it the recorded Spawn order —
 * equal to the runner's sequential spawn order. The future-identity
 * expectation API (setExpectation/expectation/clearExpectation,
 * awaitRegistration) is the retained half of the spawn-site handshake:
 * it currently has no producer, because the compiler emits no spawn
 * interception (user-invoked spawns run as unmanaged threads and never
 * register).
 *
 * LOCK STRUCTURE: the expectation is written under the engine lock
 * (the coordinator calls setExpectation/clearExpectation there); the
 * bounded waits hold `spawnMonitor` and check their predicate under the
 * engine lock (spawnMonitor -> engine lock — the documented ordering),
 * and the child's notify happens under `spawnMonitor` in a drained
 * section (the engine lock released, see pct_engine_lock.cj), so no wake
 * can be lost and the order is never inverted.
 */
internal class PctSpawnRegistrar {
    // The single outstanding spawn expectation: the future object a
    // spawning thread records before its spawn and presents by the child
    // at registration (the identity match filters strays). Retained
    // handshake state — no producer today. Written under the coordinator
    // lock.
    private var pendingSpawn: ?Object = None
    // The spawning thread's bounded wait for the child's registration.
    // Precompiled std.sync (like everything in this package), so it never
    // re-enters the PCT dispatch.
    private let spawnMonitor = Monitor()
    // Registered dynamic actors (reporting): every actor registers
    // dynamically — the runner's initial actors included — so this
    // counts ALL actors.
    private var spawnedActors: UInt64 = 0

    // Bound for the spawn-site registration wait (thread-start latency;
    // the runner's PCT_REGISTER_TIMEOUT_MS peer).
    internal static let REGISTRATION_TIMEOUT_MS: Int64 = 10000

    /** Record the spawn expectation (the future object), under the
     * engine lock. */
    internal func setExpectation(ident: Object): Unit {
        pendingSpawn = Some(ident)
    }

    /** The outstanding expectation (for the child's identity match). */
    internal func expectation(): ?Object {
        return pendingSpawn
    }

    /** Consume the expectation (the child registered), under the
     * engine lock. */
    internal func clearExpectation(): Unit {
        pendingSpawn = None
    }

    /**
     * The spawner's bounded wait for the child's registration (the
     * spawn-site bracket exit): wait until the expectation is consumed
     * (the child registered and parked). Registration needs no token, so
     * this park cannot deadlock; the bound covers thread-start failures,
     * which the caller surfaces as a protocol failure. The predicate is
     * checked under spawnMonitor and the child's notify (notifyRegistered)
     * also happens under spawnMonitor (after releasing the coordinator
     * lock), so no wake can be lost. Returns false on an unconsumed
     * timeout (a protocol failure).
     */
    internal func awaitRegistration(): Bool {
        spawnMonitor.lock()
        var consumed = pctOnLocked { => pendingSpawn.isNone() }
        if (!consumed) {
            let notified = spawnMonitor.wait(timeout: Duration.millisecond * REGISTRATION_TIMEOUT_MS)
            if (!notified) {
                consumed = pctOnLocked { => pendingSpawn.isNone() }
                if (!consumed) {
                    spawnMonitor.unlock()
                    return false
                }
            }
        }
        spawnMonitor.unlock()
        return true
    }

    /**
     * The runner's bounded wait for the initial actors' registrations:
     * wait until the registered-actor count reaches `count` (the runner
     * waits after each initial spawn, so only that child can move the
     * count). Same monitor discipline as awaitRegistration; returns
     * false on an unmet timeout (a protocol failure).
     */
    internal func awaitSpawnCount(count: Int64): Bool {
        spawnMonitor.lock()
        var ok = pctOnLocked { => Int64(spawnedActors) >= count }
        while (!ok) {
            let notified = spawnMonitor.wait(timeout: Duration.millisecond * REGISTRATION_TIMEOUT_MS)
            ok = pctOnLocked { => Int64(spawnedActors) >= count }
            if (!notified && !ok) {
                spawnMonitor.unlock()
                return false
            }
        }
        spawnMonitor.unlock()
        return true
    }

    /**
     * Release the waiting spawner (the child's registration path, in a
     * drained section with the engine lock released: the spawner's wait
     * must never depend on a token grant, and the notify must never run
     * under the engine lock — the registrar's own waits take the engine
     * lock while holding spawnMonitor).
     */
    internal func notifyRegistered(): Unit {
        spawnMonitor.lock()
        spawnMonitor.notify()
        spawnMonitor.unlock()
    }

    /** One more registered actor (reporting counter). */
    internal func noteRegistered(): Unit {
        spawnedActors += 1u64
    }

    /** How many actors registered (every registration is counted). */
    internal func spawnCount(): UInt64 {
        return spawnedActors
    }
}
