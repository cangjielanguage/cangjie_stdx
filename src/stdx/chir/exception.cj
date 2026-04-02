/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.chir

/**
 * Public definition of CHIRException.
 */
public class CHIRException <: Exception {
    /**
     * Performs the public behavior of `func`.
     */
    public init() {
        super()
    }

    /**
     * Performs the public behavior of `func`.
     * @param message The `message` parameter.
     */
    public init(message: String) {
        super(message)
    }

    protected override func getClassName(): String {
        return "CHIRException"
    }
}
