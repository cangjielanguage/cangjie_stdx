/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

import std.time.DateTime
import std.collection.ArrayList

/**
 * A built, immutable concurrent scenario ready to be executed.
 *
 * A `ConcurrentScenario<S>` is produced by `ScenarioBuilder.build()`. It bundles
 * together everything the runner needs to execute the scenario `iterations`
 * times under the chosen `consistencyModel`: the per-iteration `stateFactory`,
 * the list of `actors` (each a sequence of operation lambdas), the optional
 * `resetBlock` / `afterBlock` / `verifyBlock`, and the consistency validator
 * (auto-built or explicit).
 *
 * Call `run()` to execute the scenario and obtain a `ScenarioResult`.
 *
 * @param S per-iteration state type; `Unit` for capture-based scenarios built
 *          via the `scenario(...)` entry points
 */
public class ConcurrentScenario<S> {
    protected ConcurrentScenario(
        protected let name!: String,
        protected let threadCount!: Int64,
        protected let iterations!: Int64,
        protected let resetBlock!: ?() -> Unit,
        protected let stateFactory!: ?() -> S,
        protected let actors!: Array<Actor<S>>,
        protected let afterBlock!: ?(S) -> Unit,
        protected let verifyBlock!: ?(S) -> Bool,
        protected let consistencyValidator!: ?ConsistencyValidator = None, // cjlint-ignore !G.FUN.01 config-carrier primary constructor: these named parameters are the ScenarioBuilder's scenario-configuration knobs (each defaulted); reducing or splitting them would fragment the DSL API that the 45-test suite exercises
        protected let consistencyModel!: ConsistencyModel = SequentialConsistency, // cjlint-ignore !G.FUN.01 config-carrier primary constructor: these named parameters are the ScenarioBuilder's scenario-configuration knobs (each defaulted); reducing or splitting them would fragment the DSL API that the 45-test suite exercises
        protected let parallelIterations!: Bool = false, // cjlint-ignore !G.FUN.01 config-carrier primary constructor: these named parameters are the ScenarioBuilder's scenario-configuration knobs (each defaulted); reducing or splitting them would fragment the DSL API that the 45-test suite exercises
        protected let testMode!: TestMode = Stress, // cjlint-ignore !G.FUN.01 config-carrier primary constructor: these named parameters are the ScenarioBuilder's scenario-configuration knobs (each defaulted); reducing or splitting them would fragment the DSL API that the 45-test suite exercises
        protected let pcpBudget!: Int64 = 2, // cjlint-ignore !G.FUN.01 config-carrier primary constructor: these named parameters are the ScenarioBuilder's scenario-configuration knobs (each defaulted); reducing or splitting them would fragment the DSL API that the 45-test suite exercises
        protected let pcpFireProb!: Float64 = 0.05, // cjlint-ignore !G.FUN.01 config-carrier primary constructor: these named parameters are the ScenarioBuilder's scenario-configuration knobs (each defaulted); reducing or splitting them would fragment the DSL API that the 45-test suite exercises
        protected let starvationThreshold!: UInt64 = 10_000u64, // cjlint-ignore !G.FUN.01 config-carrier primary constructor: these named parameters are the ScenarioBuilder's scenario-configuration knobs (each defaulted); reducing or splitting them would fragment the DSL API that the 45-test suite exercises
        // Per-schedule voluntary-switch bound (PCT preemptions / DPOR
        // guided switches); -1 = unbounded. See ScenarioBuilder.switchBound.
        protected let switchBound!: Int64 = -1, // cjlint-ignore !G.FUN.01 config-carrier primary constructor: these named parameters are the ScenarioBuilder's scenario-configuration knobs (each defaulted); reducing or splitting them would fragment the DSL API that the 45-test suite exercises
        // DPOR sleep-set characterization mode: on (default) or off
        // (no sleep-set pruning). See ScenarioBuilder.sleepCharMode.
        protected let sleepCharMode!: DporSleepCharMode = Char, // cjlint-ignore !G.FUN.01 config-carrier primary constructor: these named parameters are the ScenarioBuilder's scenario-configuration knobs (each defaulted); reducing or splitting them would fragment the DSL API that the 45-test suite exercises
        // DPOR starvation-recovery policy: ThrowObstruction (the default —
        // the obstructed operation ends as a per-op bounded wait; PCT
        // always fair-yields regardless of this field). See
        // ScenarioBuilder.obstructionPolicy.
        protected let obstructionPolicy!: ObstructionPolicy = ThrowObstruction, // cjlint-ignore !G.FUN.01 config-carrier primary constructor: these named parameters are the ScenarioBuilder's scenario-configuration knobs (each defaulted); reducing or splitting them would fragment the DSL API that the 45-test suite exercises
        protected let replaySchedule!: ?PCTSchedule = None, // cjlint-ignore !G.FUN.01 config-carrier primary constructor: these named parameters are the ScenarioBuilder's scenario-configuration knobs (each defaulted); reducing or splitting them would fragment the DSL API that the 45-test suite exercises
        // Fixed PCT seed: overrides the runner's per-iteration draw so a
        // single iteration is reproducible by seed alone (the seed printed
        // on failure and recorded in `PCTSchedule.seed`). Forces a
        // one-iteration scenario (see `ScenarioBuilder.pctSeed`).
        protected let pctSeed!: ?UInt64 = None // cjlint-ignore !G.FUN.01 config-carrier primary constructor: these named parameters are the ScenarioBuilder's scenario-configuration knobs (each defaulted); reducing or splitting them would fragment the DSL API that the 45-test suite exercises
    ) {}

    /**
     * Execute the scenario for the configured number of iterations and return
     * the aggregated result.
     *
     * Iteration 0 always runs first sequentially (to calibrate the Gaussian
     * backoff sigma from the observed actor duration). Subsequent iterations
     * run either sequentially or in parallel depending on the scenario's
     * `parallelIterations` flag. As soon as an iteration fails (either its
     * `verify` block returns `false` or consistency validation finds the
     * history inconsistent), no further iterations are dispatched and any
     * in-flight results are discarded (early-exit), so a single failing
     * iteration does not force the user to wait through thousands of
     * remaining iterations.
     *
     * The returned `ScenarioResult` carries the per-iteration consistency
     * verdicts, the total wall-clock duration, and a `passed` flag that is
     * `true` iff every executed iteration succeeded.
     *
     * @return aggregated result of all executed iterations
     */
    public func run(): ScenarioResult {
        let executor = ScenarioRunner<S>(this)
        let iterationResults = ArrayList<ScenarioIterationResult>()
        let startTime = DateTime.now()

        // The callback returns false on the first failing iteration, triggering
        // early-exit: no further iterations are dispatched and in-flight results
        // are discarded. This prevents waiting through thousands of iterations
        // after a consistency violation has already been found.
        let callback = { iterResult: ScenarioIterationResult, _: Int64 =>
            iterationResults.add(iterResult)
            iterResult.allSucceeded
        }

        executor.executeIterationsWithCallback(iterations, callback: callback)

        let endTime = DateTime.now()

        ScenarioResult(
            scenarioName: name,
            iterationsExecuted: iterationResults.size,
            iterationResults: iterationResults,
            totalDuration: endTime - startTime
        )
    }
}

/**
 * Entry point of the fluent scenario DSL for stateless, capture-based scenarios.
 *
 * Returns a `ScenarioBuilder<Unit>` whose operations receive `()` (`Unit`) as
 * the state placeholder and ignore it. A default `{ => () }` state factory is
 * pre-registered (without setting the "explicit" flag), so the runner always
 * has a state to pass to operations; simple users can still call
 * `.reset { => var = ... }` to reassign shared mutable state per iteration.
 *
 * To use the typed per-iteration-state API, call `.withState<S>(factory)` on
 * the returned builder — see `ScenarioBuilder.withState`.
 *
 * @param name human-readable scenario name, surfaced in reports and mismatch tables
 * @return a fresh `ScenarioBuilder<Unit>` for fluent chaining
 */
public func scenario(name: String): ScenarioBuilder<Unit> {
    ScenarioBuilder<Unit>(name).defaultStateFactory({ => () })
}

/**
 * Entry point of the fluent scenario DSL for stateless, capture-based scenarios,
 * with an auto-generated scenario name.
 *
 * Equivalent to `scenario(name: String)` but uses the default builder name
 * (`"unnamed_scenario"`) — useful for quick ad-hoc scenarios where the name is
 * not relevant.
 *
 * @return a fresh `ScenarioBuilder<Unit>` for fluent chaining
 */
public func scenario(): ScenarioBuilder<Unit> {
    ScenarioBuilder<Unit>().defaultStateFactory({ => () })
}


protected class Actor<S> {
    protected Actor(
        protected let id!: Int64,
        protected let operations!: Array<(S) -> EquatableObj>,
        protected let operationNames!: Array<String>,
        protected let name!: String
    ) {}
}
