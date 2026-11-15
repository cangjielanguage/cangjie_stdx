# Copyright © 2026 Huawei Technologies Co., Ltd. All Rights Reserved.
# This source file is part of the Cangjie project, licensed under Apache-2.0
# with Runtime Library Exception.
#
# See https://cangjie-lang.cn/pages/LICENSE for license information.

# The PCT-instrumented mirror of std.sync. An internal package: the only
# sanctioned entry path is the compiler's `--cj-pct` import remap (a
# hand-written import is rejected by the accessibility gate). The
# wrappers compose the real std.sync primitives and dispatch each
# operation to the active PCT coordinator through the hooks in
# stdx.unittest.concurrent (pct_dispatch.cj).
set(UNITTEST_SYNC_SRCS
    atomic.cj
    monitor.cj
    mutex.cj
    read_write_lock.cj
    reexport.cj
    semaphore.cj
    CACHE INTERNAL "")
