# Copyright © 2026 Huawei Technologies Co., Ltd. All Rights Reserved.
# This source file is part of the Cangjie project, licensed under Apache-2.0
# with Runtime Library Exception.
#
# See https://cangjie-lang.cn/pages/LICENSE for license information.

# The concurrent scenario DSL and the PCT/DPOR model-checking engine
# (coordinator, dispatchers, schedulers, window API) live together in
# this package; the PCT-instrumented std.sync mirror lives in the
# sibling package stdx.unittest.sync (see ../sync). Under `--cj-pct`
# the compiler remaps user imports of std.sync onto the mirror and
# implicitly imports this package's pctMarkInstrumented.
set(UNITTEST_CONCURRENT_SRCS
    backoff.cj
    concurrent_history.cj
    consistency_model.cj
    consistency_validation_result.cj
    consistency_validator.cj
    dpor_report.cj
    dpor_pop.cj
    dpor_pop_sschar.cj
    dpor_race_pair.cj
    dpor_scheduler.cj
    dpor_trace.cj
    hbclock.cj
    mtrace_ffi.cj
    obstruction_detected_exception.cj
    operation.cj
    partial_order.cj
    pct_actor_table.cj
    pct_children.cj
    pct_clock.cj
    pct_coordinator.cj
    pct_dispatch.cj
    pct_engine_lock.cj
    pct_schedule.cj
    pct_schedule_log.cj
    pct_scheduler_base.cj
    pct_scheduler.cj
    pct_spawn_registrar.cj
    pct_wait_graph.cj
    pct_window.cj
    permutation_node.cj
    pretty_table.cj
    scenario_builder.cj
    concurrent_scenario.cj
    scenario_result.cj
    scenario_runner.cj
    equatable_obj.cj
    CACHE INTERNAL "")
