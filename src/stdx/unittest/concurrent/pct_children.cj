/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source code is part of the Cangjie project, licensed under Apache-2.0,
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

/**
 * PCT spawn ABI stubs (--cj-pct): kept for link compatibility with
 * objects built by older compilers; unconditionally no-op. The compiler
 * emits no spawn interception today — user-invoked spawns run as
 * unmanaged threads, invisible to the scheduler (see the README,
 * "User-spawned threads"); the coordinator-side halves of that
 * interception protocol are retained in the engine but unreachable
 * (no producer).
 *
 * Reserved for the compiler and the unittest infrastructure; not a
 * general-purpose API.
 */

/**
 * Spawn-site bracket entry, kept for ABI compatibility with objects
 * from older compilers; unconditionally a no-op.
 *
 * Reserved for the compiler and the unittest infrastructure; not a
 * general-purpose API.
 */
internal func pctSpawnSiteBefore(o: Object): Unit {
}

/**
 * Spawn-site bracket exit, kept for ABI compatibility with objects
 * from older compilers; unconditionally a no-op.
 *
 * Reserved for the compiler and the unittest infrastructure; not a
 * general-purpose API.
 */
internal func pctSpawnSiteAfter(): Unit {
}

