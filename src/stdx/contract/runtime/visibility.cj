/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.runtime

/**
 * @brief Visibility order used by contract checks.
 *
 * The cases are ordered from the most restrictive to the most permissive: Private,
 * Internal, Protected, Public. Type contracts use this order (through visibility
 * selectors such as `on_public`) to decide which members a type invariant applies to.
 */
public enum ContractVisibility {
    | Private
    | Internal
    | Protected
    | Public

    private func rank(): Int64 {
        match (this) {
            case Private => 0
            case Internal => 1
            case Protected => 2
            case Public => 3
        }
    }

    /**
     * @brief Checks whether this visibility is at least the given minimum.
     *
     * The comparison follows Private <= Internal <= Protected <= Public.
     *
     * @param minimum The minimum visibility to compare against.
     * @return true if this visibility is not more restrictive than minimum, false
     * otherwise.
     */
    public func isAtLeast(minimum: ContractVisibility): Bool {
        rank() >= minimum.rank()
    }
}
