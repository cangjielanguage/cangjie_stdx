/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

/**
 * @file
 *
 * Anchor package of the contract library.
 *
 * cjpm stops scanning a source directory as soon as it contains no '.cj' file, which
 * would hide the stdx.contract.runtime and stdx.contract.macros.* subpackages from a
 * cjpm build. This empty package keeps the directory discoverable; the contract
 * library itself is implemented in the subpackages.
 */
package stdx.contract
