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
 * This file defines the Actor class and provide method to submit a closure to it.
 *
 */

package stdx.actors

public class SequentialDispatcher {
    let mailbox: Mailbox
    let threadHandle: Future<Unit>

    public init(enableReceiverPriority!: Bool = false) {
        this.mailbox = if (enableReceiverPriority) {
            BoundedPriorityMailbox()
        } else {
            BoundedMailbox()
        }
        this.threadHandle = startActorLoop(mailbox)
    }

    static func startActorLoop<M>(mailbox: M): Future<Unit> where M <: Mailbox {
        spawn {
            while (true) {
                if (Thread.currentThread.hasPendingCancellation) {
                    return
                }

                let f = match (mailbox.remove(timeout: Duration.second)) {
                    case Some((_, f)) =>
                        f
                    case None => continue
                }

                try {
                    f()
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }

    public func post<T>(f: () -> T, priority!: Int64 = 5): ActorFuture<T> {
        let fut = ActorFuture<T>(f)
        mailbox.add((this, fut.execute), priority)
        return fut
    }

    ~init() {
        threadHandle.cancel()
    }
}
