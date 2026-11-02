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
 * This file introduces JsonException class.
 */
package stdx.encoding.json


/**
 * JsonException class.
 */
public class JsonException <: Exception {
    /**
     * Create a new JsonException instance.
     *
     * @since 0.17.4
     */
    public init() {
        super()
    }

    /**
     * Create a new JsonException instance.
     * Construction with parameters.
     *
     * @param message exception message.
     *
     * @since 0.17.4
     */
    public init(message: String) {
        super(message)
    }

    /**
     * Get class name.
     *
     * @return class name.
     *
     * @since 0.17.4
     */
    protected override func getClassName(): String {
        return "JsonException"
    }
}
