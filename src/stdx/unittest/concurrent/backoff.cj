/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

import std.random.Random
import std.math.abs

protected class BackoffGenerator {
    protected BackoffGenerator( 
        protected let random!: Random = Random(),
        protected var sigma!: Float64 = 1.0,
        protected let maxBackoff!: Int64 = 10000
    ) {}
    
    protected func next(): Int64 {
        let u = random.nextGaussianFloat64(sigma: sigma)
        let value = Int64(abs(u))
        if (value > maxBackoff) {
            return maxBackoff
        }
        value
    }
}