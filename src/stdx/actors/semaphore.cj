/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

/**
 * @file
 *
 * This file defines a semaphore without limit that is specialized for a single consumer.
 *
 */

package stdx.actors

import std.sync.AtomicUInt64
import std.sync.Mutex
import std.sync.Condition
import std.time.DateTime

class SingleConsumerSemaphore {
    private let cnt = AtomicUInt64(0)
    private let mtx = Mutex()
    private let cond: Condition

    init() {
        synchronized(mtx) {
            cond = mtx.condition()
        }
    }

    func signal(): Unit {
        let n = cnt.fetchAdd(1)
        if (n == 0) {
            synchronized(mtx) {
                cond.notifyAll()
            }
        }
    }
    // It might appear that the following sequence would result in a deadlock:
    // Pre-condition: cnt equals 0
    // Consumer calling wait:
    //   1) load cnt to n
    //   2) check if n is equal to 0 returns true
    // Producer calling signal:
    //   3) fetchAdd cnt by 1 and return the new value to n
    //   4) n equals to 0, returns true
    //   5) enter the synchronized block on mtx
    //   6) call notifyAll on the mutex condition variable
    //   7) exit the synchronized block
    // Consumer wait:
    //   8) startTime equals to the current time
    //   9) enter the synchronized block on mtx
    //  10)   to the call of wait on the condition variable
    // However, this is safe because the wait function has a timeout parameter
    // which will eventually break out of the loop.
    func wait(timeout: Duration): Bool {
        let n = cnt.load()
        if (n > 0) {
            cnt.fetchSub(1)
            return true
        }

        let startTime = DateTime.now()
        synchronized(mtx) {
            while (cnt.load() == 0) {
                let timeElapsed = DateTime.now() - startTime
                if (timeElapsed >= timeout) {
                    return false
                }
                cond.wait(timeout: timeout - timeElapsed)
            }
        }
        cnt.fetchSub(1)
        true
    }
}
