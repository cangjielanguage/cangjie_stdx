/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

import std.collection.ArrayList

/**
 * mtrace (memory-access tracing) reader API — inert stubs. The mtrace
 * runtime does not exist: these always report not-initialized /
 * recording-off / empty buffers / nothing drainable or symbolizable, so
 * the engine-side consumers (dpor_trace.cj, dpor_race_pair.cj) run
 * permanently in their "no mtrace runtime" mode and never report races.
 */

/** Event kinds (must match MtraceKind in MtraceEvent.h). */
internal class MtraceKind {
    public static let READ: UInt32 = 0
    public static let WRITE: UInt32 = 1
    public static let RANGE_READ: UInt32 = 2
    public static let RANGE_WRITE: UInt32 = 3
    public static let ALLOC: UInt32 = 4
    public static let SPAWN: UInt32 = 5
    public static let MOVE: UInt32 = 6
    public static let GC_BEGIN: UInt32 = 7
    public static let GC_END: UInt32 = 8
}

/**
 * A recorded memory-access event (32 bytes, C-compatible layout).
 * Field reuse by kind (see MtraceEvent.h):
 *   READ/WRITE/RANGE_READ/RANGE_WRITE/ALLOC: pc = access/alloc site, addr = accessed/allocated address, size = bytes
 *   MOVE:   pc = destination (to), addr = source (from), size = bytes
 *   SPAWN:  pc = caller pc, addr = child mtrace tid
 *   GC_BEGIN/GC_END: pc = 0, addr = 0
 * fs carries the start pc of the function containing the access site for
 * READ/WRITE/RANGE_* events (0 otherwise): together with pc it is the
 * input [[symbolizePc]] uses to map the access back to a source
 * location.
 */
@C
internal struct MtraceEvent {
    public MtraceEvent(let pc!: UInt64 = 0, let addr!: UInt64 = 0, let size!: UInt32 = 0,
        let kind!: UInt32 = 0, let fs!: UInt64 = 0) {}
}

// Inert stubs; see the file header.
func cjMtraceIsInitialized(): Bool {
    return false
}

func cjMtraceSetEnabled(enabled: Bool): Unit {
    return
}

func cjMtraceSuppressBegin(): Unit {
    return
}

func cjMtraceSuppressEnd(): Unit {
    return
}

func cjMtraceThreadId(): UInt32 {
    return 0u32
}

func cjMtraceOwnSealedCount(): UInt64 {
    return 0u64
}

func cjMtraceOwnDrain(out: CPointer<MtraceEvent>, maxCount: UInt64): UInt64 {
    return 0u64
}

func cjMtraceGcDrain(out: CPointer<MtraceEvent>, maxCount: UInt64): UInt64 {
    return 0u64
}

func cjMtraceDroppedCount(): UInt64 {
    return 0u64
}

func cjMtraceResetAll(): Unit {
    return
}

func cjMtraceSymbolizePc(ip: UInt64, fs: UInt64, buf: CPointer<UInt8>, bufLen: UInt32): UInt32 {
    return 0u32
}

/**
 * Best-effort source location of a recorded access site — "in <function> at
 * <file>[:<line>]" with whichever parts resolve (`fs` is the event's
 * recorded containing-function start pc). Inert stub: nothing ever
 * resolves, so this always returns the empty string; callers fall back to
 * the raw pc.
 */
internal func symbolizePc(ip: UInt64, fs: UInt64): String {
    unsafe {
        let cap = Int64(256)
        let buf = Array<UInt8>(cap, {_ => 0})
        let handle = acquireArrayRawData<UInt8>(buf)
        let n = cjMtraceSymbolizePc(ip, fs, handle.pointer, UInt32(cap))
        releaseArrayRawData<UInt8>(handle)
        if (n == UInt32(0)) {
            return ""
        }
        return String.fromUtf8(buf[0..Int64(n)])
    }
}

/**
 * Whether the mtrace sink has been initialized (main cjthread attached).
 * Inert stub: always returns false.
 */
internal func isInitialized(): Bool {
    unsafe { return cjMtraceIsInitialized() }
}

/**
 * Enable or disable recording. Inert stub: no recording exists, so the
 * request is ignored.
 */
internal func setEnabled(enabled: Bool): Unit {
    unsafe { cjMtraceSetEnabled(enabled) }
}

/**
 * Per-thread recording suppression (depth-counted; pair with
 * [[suppressEnd]] in a try/finally). The model checker brackets its own
 * framework code (scheduler, coordinator, window driver) so that only
 * actor-operation accesses land in the buffers — the recorded stream of a
 * segment is then exactly the memory traffic of the user code that ran
 * inside it. Inert stub: always a no-op.
 */
internal func suppressBegin(): Unit {
    unsafe { cjMtraceSuppressBegin() }
}

/** The [[suppressBegin]] counterpart (see it for the contract). */
internal func suppressEnd(): Unit {
    unsafe { cjMtraceSuppressEnd() }
}

/** The current green thread's mtrace tid. Inert stub: always 0. */
internal func threadId(): UInt32 {
    unsafe { return cjMtraceThreadId() }
}

/** Number of sealed-but-undrained events in the current thread's buffer.
 * Inert stub: always 0. */
internal func ownSealedCount(): UInt64 {
    unsafe { return cjMtraceOwnSealedCount() }
}

/** Total dropped events (overflow / over-cap) across all threads + GC
 * stream. Inert stub: always 0. */
internal func droppedCount(): UInt64 {
    unsafe { return cjMtraceDroppedCount() }
}

/** Reset all buffers (between test iterations). Inert stub: there are
 * no buffers to reset. */
internal func resetAll(): Unit {
    unsafe { cjMtraceResetAll() }
}

/**
 * Drain up to [[ownSealedCount]] events from the current thread's buffer into a
 * new Array, in time order (oldest first). The drained chunks are recycled.
 * Inert stub: always returns an empty array.
 */
internal func drainOwn(): Array<MtraceEvent> {
    unsafe {
        let count = cjMtraceOwnSealedCount()
        if (count == UInt64(0)) {
            return Array<MtraceEvent>()
        }
        let buf = Array<MtraceEvent>(Int64(count), { _ => MtraceEvent() })
        let handle = acquireArrayRawData<MtraceEvent>(buf)
        let n = cjMtraceOwnDrain(handle.pointer, count)
        releaseArrayRawData<MtraceEvent>(handle)
        if (n < count) {
            return buf[0..Int64(n)]
        }
        return buf
    }
}

/**
 * Drain up to maxCount events from the global GC stream (MOVE / GC_BEGIN / GC_END).
 * Inert stub: always returns an empty array.
 */
internal func drainGc(): Array<MtraceEvent> {
    unsafe {
        let maxCount = UInt64(1024)
        let buf = Array<MtraceEvent>(Int64(maxCount), { _ => MtraceEvent() })
        let handle = acquireArrayRawData<MtraceEvent>(buf)
        let n = cjMtraceGcDrain(handle.pointer, maxCount)
        releaseArrayRawData<MtraceEvent>(handle)
        return buf[0..Int64(n)]
    }
}
