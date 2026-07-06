/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

// The purpose of this subpackage is so that when cjpm calls `cjc` to build the
// parent package `stdx.effect`, the flag `--no-sub-pkg` is not used
// (because this here is a subpackage).
// This is necessary because private items in packages without subpackages are
// not exposed through symbols in the build artifacts. That is a problem because
// using `stdx.effect` requires the compiler to desugar the "effects" syntax into
// expressions which involve the private items defined in `stdx.effect`.
// (but end users must not be able to use these private items themselves directly)

// If `stdx.effect` were to move to `std.effect` in the future, then this workaround
// would no longer be necessary as it would be distributed as part of the SDK where
// the build system has direct control over the `cjc` commands to build the relevant
// artifacts.

package stdx.effect.unused
