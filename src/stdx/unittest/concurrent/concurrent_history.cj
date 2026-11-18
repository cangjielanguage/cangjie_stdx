/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

import std.collection.ArrayList
import std.collection.HashMap

protected class ConcurrentHistory {
    private let actorInvocations: HashMap<Int64, ArrayList<OperationInvocation>> = HashMap<Int64, ArrayList<OperationInvocation>>()

    protected ConcurrentHistory() {}

    protected func recordActorInvocations(
        actorId: Int64,
        invocations: ArrayList<OperationInvocation>
    ): Unit {
        if (!actorInvocations.contains(actorId)) {
            actorInvocations[actorId] = ArrayList<OperationInvocation>()
        }
        for (inv in invocations) {
            actorInvocations[actorId].add(inv)
        }
    }
    
    func groupByActor(): HashMap<Int64, ArrayList<OperationInvocation>> {
        actorInvocations
    }
    
    func getActorInvocations(actorId: Int64): ?ArrayList<OperationInvocation> {
        actorInvocations[actorId]
    }
    
    func getInvocation(actorId: Int64, index: Int64): ?OperationInvocation {
        match (actorInvocations.get(actorId)) {
            case Some(ops) =>
                ops.get(index)
            case None => None
        }
    }

    prop actorCount: Int64 {
        get() { actorInvocations.size }
    }
}