/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

internal package stdx.unittest.sync

// The std.sync vocabulary types, re-exported so that the `--cj-pct`
// import remap keeps them resolvable: under the flag every user
// `import std.sync.X` resolves to this package, and the mirror's own
// signatures use these types (`Mutex <: UniqueLock`, `PctCondition <:
// Condition`, `MultiConditionMonitor.newCondition(): ConditionID`), so
// without the re-exports naming any of them — or catching the misuse
// exception the underlying primitives throw — fails to compile.
//
// The split is deliberate:
//  - re-exported: types with no scheduling-relevant behavior of their
//    own (the interfaces, the condition identifier record, the misuse
//    exception). Re-exporting them cannot bypass instrumentation.
//  - NOT re-exported: behavioral primitives with no mirror — `Barrier`,
//    `SyncCounter`, `Timer`, `CatchupStyle`, `ReadWriteMutexMode`, the
//    deprecated reentrant read-write mutex family
//    (`ReentrantReadWriteMutex`, `ReentrantReadMutex`,
//    `ReentrantWriteMutex`), and the deprecated atomic memory-order
//    vocabulary (`MemoryOrder`, `DefaultMemoryOrder`, which only feeds
//    the memory-order overloads the atomic wrappers omit). Each stays a
//    clear per-use compile error instead of a silent uninstrumented
//    fallback.
public import std.sync.Condition
public import std.sync.ConditionID
public import std.sync.IReentrantMutex
public import std.sync.IllegalSynchronizationStateException
public import std.sync.Lock
public import std.sync.UniqueLock
