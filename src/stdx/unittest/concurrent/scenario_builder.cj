/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

import std.collection.ArrayList

/**
 * Fluent builder for a `ConcurrentScenario<S>`.
 *
 * A `ScenarioBuilder` is obtained from one of the `scenario(...)` entry points
 * (which pre-seed a `Unit` state factory); typed scenarios transition from it
 * via `.withState(factory)`. Each fluent method mutates the builder in place
 * and returns the same builder (`this`) for chaining; the only method that
 * does not return the builder is `withState<S2>(...)`, which transitions to a
 * typed `ScenarioBuilder<S2>` (because Cangjie does not allow mutating a
 * class's type parameter in place), and `build()`, which finalises the
 * scenario.
 *
 * A minimal valid scenario requires at least one actor (added via `actor`
 * or `actorWithOps`) and a state factory (registered
 * automatically by `scenario(...)`, or explicitly via `.withState(factory)` /
 * `.reset { => ... }`). `build()` throws `IllegalArgumentException` if either
 * is missing.
 *
 * @param S per-iteration state type; `Unit` for capture-based scenarios built
 *          via the `scenario(...)` entry points
 */
public class ScenarioBuilder<S> {
    private var _name: String = "unnamed_scenario"
    private var _iterations: Int64 = 1
    private var _stateFactory: ?() -> S = None
    // True iff the user explicitly called .withState(...) (the typed
    // transition from a Unit builder). Used by build() to decide whether to
    // construct the auto ConsistencyValidator: simple scenarios that only use
    // .reset { => var = ... } should preserve the original behavior of building
    // the validator iff _resetBlock is Some, while typed scenarios always build
    // it (each permutation-DFS restart gets a fresh isolated state instance).
    private var _stateFactoryExplicit: Bool = false
    // Tri-state: None = auto (parallel iff withState was used), Some(true)/Some(false)
    // = explicit user override. See parallelIterations(...) below.
    private var _parallelIterations: ?Bool = None
    // PCT mode configuration: opt-in; Stress stays the default.
    private var _testMode: TestMode = Stress
    private var _pcpBudget: Int64 = 2
    private var _pcpFireProb: Float64 = 0.05
    private var _starvationThreshold: UInt64 = 10_000u64
    private var _switchBound: Int64 = -1
    // DPOR sleep-set characterization mode: on (default — prunes
    // already-explored Mazurkiewicz classes) or off (no sleep-set
    // pruning — complete and sound, exploring the duplicate classes of
    // compatible read schedules). See DporSleepCharMode.
    private var _sleepCharMode: DporSleepCharMode = Char
    // DPOR starvation-recovery policy: ThrowObstruction (default) or
    // YieldFairly. See ObstructionPolicy / ObstructionDetectedException.
    private var _obstructionPolicy: ObstructionPolicy = ThrowObstruction
    private var _replaySchedule: ?PCTSchedule = None
    private var _pctSeed: ?UInt64 = None
    // _resetBlock, _actors, _afterBlock, _verifyBlock are intentionally left without
    // `private` so that the simple `extend ScenarioBuilder<Unit>` block below can
    // manipulate them when S = Unit (Cangjie extensions cannot access private members).
    var _resetBlock: ?() -> Unit = None
    let _actors: ArrayList<Actor<S>> = ArrayList<Actor<S>>()
    var _afterBlock: ?(S) -> Unit = None
    var _verifyBlock: ?(S) -> Bool = None
    private var _consistencyModel: ConsistencyModel = SequentialConsistency
    private var _explicitValidator: ?ConsistencyValidator = None

    /** Construct an unnamed builder (`"unnamed_scenario"`); name the scenario
     *  via the `scenario(name)` entry point instead. */
    internal init() {}

    /** Construct a builder pre-seeded with the given scenario `name`. */
    internal init(name: String) {
        _name = name
    }

    /**
     * Set the number of iterations the scenario will be executed for.
     *
     * Iteration 0 always runs first sequentially (to calibrate the Gaussian
     * backoff sigma); subsequent iterations run either sequentially or in
     * parallel depending on the `parallelIterations` flag. As soon as an
     * iteration fails, no further iterations are dispatched (early-exit).
     *
     * @param n iteration count, must be `>= 1`
     * @return this builder, for fluent chaining
     * @throws IllegalArgumentException if `n < 1`
     */
    public func iterations(n: Int64): ScenarioBuilder<S> {
        if (n < 1) {
            throw IllegalArgumentException("Iteration count must be at least 1")
        }
        if (_replaySchedule.isSome()) {
            throw IllegalArgumentException(
                "A replay schedule runs exactly one iteration; do not combine replaySchedule(...) with iterations(n > 1)"
            )
        }
        _iterations = n
        this
    }

    /**
     * Select the execution mode: `Stress` (default, Gaussian-backoff
     * probabilistic), `PCT` (runtime-controlled probabilistic concurrency
     * testing with recordable, replayable schedules), or `DPOR`
     * (deterministic dynamic partial order reduction with sleep sets — the
     * model checker).
     *
     * In PCT mode at most one actor executes at a time (a token protocol);
     * iterations run strictly sequentially regardless of
     * `parallelIterations`; each iteration draws a fresh random seed and
     * records its schedule into the per-iteration result
     * (`ScenarioResult.pctSchedule`).
     *
     * In DPOR mode the same token protocol runs under the dependency
     * explorer: every synchronizing dependency between segments of
     * different actors is explored in both orders and sleep sets prune
     * provably equivalent siblings — no randomness, no seed. Each explored
     * schedule is one full reset/state/verify cycle (a failing verify,
     * consistency verdict, deadlock, or actor exception stops the
     * exploration and surfaces with the failing schedule); `iterations(n)`
     * is the schedule budget. The exploration report (schedules explored,
     * exhaustion, deadlock verdict) surfaces through
     * `ScenarioResult.dporReport`. Requires `--cj-pct`
     * like PCT; the PCT schedule-exploration knobs (`.pctSeed`,
     * `.replaySchedule`) are rejected at `build()` time in DPOR, while
     * `.priorityChangePoints` is a no-op in DPOR and
     * `.starvationThreshold`
     * and `.switchBound` apply to both modes (the latter as the guided
     * switch bound — see `switchBound`). The DPOR-only
     * `.sleepCharMode` and `.obstructionPolicy` are ignored in PCT (at
     * the starvation point PCT always fair-yields — see
     * `obstructionPolicy`).
     *
     * @param m execution mode
     * @return this builder, for fluent chaining
     */
    public func mode(m: TestMode): ScenarioBuilder<S> {
        _testMode = m
        this
    }

    /**
     * Set the PCT priority-change-point budget `k`.
     *
     * PCT theory guarantees that any bug requiring at most `k` scheduling
     * switches is found within a polynomial number of runs; empirical studies
     * show most real concurrency bugs need `k <= 3`.
     *
     * @param k number of priority change points, must be `>= 0`
     * @return this builder, for fluent chaining
     * @throws IllegalArgumentException if `k < 0`
     */
    public func priorityChangePoints(k: Int64): ScenarioBuilder<S> {
        if (k < 0) {
            throw IllegalArgumentException("Priority change point budget must be >= 0")
        }
        _pcpBudget = k
        this
    }

    /**
     * Set the probability that a priority-change point fires at each PCT
     * scheduling decision (while budget remains). The default of `0.05`
     * spreads a small budget across short scenarios well.
     *
     * @param p fire probability in `[0.0, 1.0]`
     * @return this builder, for fluent chaining
     * @throws IllegalArgumentException if `p` is outside `[0.0, 1.0]`
     */
    internal func pcpFireProbability(p: Float64): ScenarioBuilder<S> {
        if (p < 0.0 || p > 1.0) {
            throw IllegalArgumentException("PCP fire probability must be within [0.0, 1.0]")
        }
        _pcpFireProb = p
        this
    }

    /**
     * Set the grid-starvation threshold: how many consecutive grid checks
     * the token holder may make without reaching an operation boundary
     * before the iteration switches to fair scheduling (grid points become
     * voluntary yields). This rescues operations that are not obstruction
     * free — ones that wait for a frozen peer to complete a started
     * operation (e.g. a spin on an in-flight producer slot) — which would
     * otherwise livelock once the switch budget is spent. Raise it for
     * legitimately long atomic-heavy operations; the trigger is
     * event-based (no clocks), so replays reproduce it exactly.
     *
     * @param n consecutive grid-check threshold, must be `>= 1`
     * @return this builder, for fluent chaining
     * @throws IllegalArgumentException if `n < 1`
     */
    public func starvationThreshold(n: UInt64): ScenarioBuilder<S> {
        if (n < 1u64) {
            throw IllegalArgumentException("Starvation threshold must be >= 1")
        }
        _starvationThreshold = n
        this
    }

    /**
     * Set the per-schedule switch bound: the maximum number of
     * *voluntary* token switches (preemptions away from a willing
     * holder) in any single PCT or DPOR schedule. The default is
     * unbounded. Ignored in `Stress` mode.
     *
     * The two modes enforce the same budget at different layers:
     *
     * - `PCT`: bounds the actual preemption switches at operation
     *   boundaries and grid points. `priorityChangePoints(k)` bounds
     *   priority-change *fires*, but a single fired change point can
     *   cascade into several preemptions — this option bounds the
     *   switches themselves (`k = 0` yields fully serial schedules
     *   apart from blocking handoffs). Forced transfers (an actor
     *   parking, waiting, or exiting) and fair-mode anti-starvation
     *   yields never count against the bound, so schedules stay live
     *   and replays reproduce verbatim.
     * - `DPOR`: the explorer never plans a schedule with more guided
     *   switches than the bound; backtrack points that would exceed it
     *   are pruned. This is the depth-bound analogue of the schedule
     *   budget (`iterations(n)` bounds the width) — useful to cap
     *   runaway explorations of long scenarios. A pruned exploration
     *   reports `DporReport.depthPruned == true` (and is not
     *   `exhausted`): raise the bound (or pass -1) for completeness.
     *
     * @param k maximum voluntary switches per schedule, `>= 0` (the
     *        default -1 means unbounded)
     * @return this builder, for fluent chaining
     * @throws IllegalArgumentException if `k < -1`
     */
    public func switchBound(k: Int64): ScenarioBuilder<S> {
        if (k < -1) {
            throw IllegalArgumentException("Switch bound must be >= 0 (or -1 for unbounded)")
        }
        _switchBound = k
        this
    }

    /**
     * Set the DPOR sleep-set characterization mode.
     * `DporSleepCharMode.Char` (the default) turns the sleep-set
     * characterization on: read schedules that would revisit an already
     * explored Mazurkiewicz class are pruned, at the cost of the
     * characterization's outcome-soundness assumptions (an SUT whose
     * outcome-carrying data flow is not captured by the scheduler's
     * dependency model — e.g. plain-memory traffic guarded by atomics —
     * can conflate distinct outcomes). `DporSleepCharMode.Off` turns it
     * off: no sleep-set pruning — complete and sound, exploring the
     * duplicate classes of compatible read schedules. Ignored outside
     * `DPOR` mode.
     *
     * This is the scenario-level knob for the DPOR driver's sleep-set
     * characterization mode (see `DporWindowConfig.sleepCharMode`).
     *
     * @param m the sleep-set characterization mode
     * @return this builder, for fluent chaining
     */
    public func sleepCharMode(m: DporSleepCharMode): ScenarioBuilder<S> {
        _sleepCharMode = m
        this
    }

    /**
     * Set the DPOR starvation-recovery policy — what happens when the
     * scheduler detects an operation obstructed by the guided ordering
     * (an unbroken grid-poll run waiting for a peer the guide never
     * grants):
     * - `ObstructionPolicy.ThrowObstruction` (the default) — the
     *   operation ends with `ObstructionDetectedException`: it unwinds to
     *   the per-op capture and becomes the operation's recorded result, a
     *   per-operation bounded wait. No token is transferred and no
     *   schedule event is added, so the schedule stays a pure function
     *   of the guide (the fair yield is a guide-foreign event — one that
     *   would corrupt the sleep-set characterization's already-explored
     *   bookkeeping).
     * - `ObstructionPolicy.YieldFairly`: the iteration switches to fair
     *   scheduling and the grid point becomes a voluntary yield
     *   (liveness over schedule purity).
     *
     * PCT mode always fair-yields at this point regardless of this knob
     * (its liveness mechanism; the PCT scheduler is always built with
     * `YieldFairly`). Ignored outside `DPOR` mode.
     *
     * This is the scenario-level knob for the DPOR driver's
     * starvation-recovery policy (see `DporWindowConfig.obstructionPolicy`).
     *
     * @param p the obstruction policy
     * @return this builder, for fluent chaining
     */
    public func obstructionPolicy(p: ObstructionPolicy): ScenarioBuilder<S> {
        _obstructionPolicy = p
        this
    }

    /**
     * Replay a previously recorded PCT schedule instead of exploring a fresh
     * one.
     *
     * The scenario must run exactly one iteration (enforced by this method);
     * the recorded interleaving is reproduced bit-for-bit given the same
     * binary. Schedules containing deadlock-recovery (`Resume`) events are
     * rejected when the replay is loaded.
     *
     * Typical usage: capture the schedule of a failing run from
     * `ScenarioResult.pctSchedule` and re-run the same scenario with it.
     *
     * PCT-only: `build()` throws `IllegalArgumentException` when the
     * scenario's mode is not `PCT` (a replay pins one schedule, which would
     * silently cap DPOR's schedule budget or Stress's repetition budget to
     * a single run).
     *
     * @param s schedule recorded by a previous PCT-mode run
     * @return this builder, for fluent chaining
     * @throws IllegalArgumentException at `build()` time when the mode is
     *         not `PCT`
     */
    public func replaySchedule(s: PCTSchedule): ScenarioBuilder<S> {
        _replaySchedule = Some(s)
        _iterations = 1
        this
    }

    /**
     * Fix the PCT seed for the iteration instead of drawing one at random.
     *
     * The seed fully determines the explored schedule for a given binary, so
     * a fixed-seed run is reproducible by seed alone (the recorded schedule
     * still lands in `ScenarioResult.pctSchedule`). A fixed seed identifies
     * exactly one schedule, so the scenario runs exactly one iteration
     * (enforced by this method, like `replaySchedule`). A failed iteration
     * prints its seed as a one-line reproduction hint; see the README's
     * "Reproduce by seed" for the determinism contract — `replaySchedule`
     * is the guaranteed mechanism.
     *
     * PCT-only: `build()` throws `IllegalArgumentException` when the
     * scenario's mode is not `PCT` (a fixed seed pins one schedule, which
     * would silently cap DPOR's schedule budget or Stress's repetition
     * budget to a single run).
     *
     * @param s the seed recorded in (and replayable from) `PCTSchedule.seed`
     * @return this builder, for fluent chaining
     * @throws IllegalArgumentException at `build()` time when the mode is
     *         not `PCT`
     */
    public func pctSeed(s: UInt64): ScenarioBuilder<S> {
        _pctSeed = Some(s)
        _iterations = 1
        this
    }

    /**
     * Transition this builder to a typed `ScenarioBuilder<S2>` with the given
     * per-iteration state factory.
     *
     * The state type `S2` is inferred from the factory argument. After this
     * call, all state-aware methods (`actor`, `actorWithOps`,
     * `verify`, `after`) accept lambdas that receive the per-iteration state of
     * type `S2`. Each iteration (and each permutation-DFS restart inside the
     * consistency validator) calls `factory` to produce a fresh, isolated SUT
     * instance, so parallel iteration execution is enabled by default.
     *
     * A `.reset { => ... }` block configured before `withState` carries over
     * to the new builder (it is state-type-agnostic: it re-initialises
     * captured shared state and runs before `factory` on every iteration and
     * validator restart). The state-RECEIVING configuration must come after
     * `withState`: `after`/`verify` closures and `sequentialSpec` reference
     * the state type, so a builder that already has them configured cannot
     * be retyped and is rejected instead of silently dropping them.
     *
     * Typical usage:
     * ```
     * scenario("queue_test")
     *     .withState({ => ConcurrentLinkedQueue<Int64>() })
     *     .actor({ q => q.add(1) })
     *     .build()
     * ```
     *
     * @param S2 per-iteration state type, inferred from `factory`
     * @param factory closure that produces a fresh `S2` instance per iteration
     * @return a new `ScenarioBuilder<S2>` carrying over the name, iteration
     *         count, consistency model, and reset block of
     *         this builder
     * @throws IllegalArgumentException if `withState` has already been called
     *         on this builder, if any actors have already been added
     *         (existing `Unit`-typed actors cannot be retyped to `S2`), if
     *         `after`/`verify` blocks are already configured (their closures
     *         receive the previous state type and cannot be retyped), or if
     *         `sequentialSpec` has already been called (its reference
     *         implementation receives the previous state type)
     */
    public func withState<S2>(factory: () -> S2): ScenarioBuilder<S2> {
        if (_stateFactoryExplicit) {
            throw IllegalArgumentException(
                "withState can only be called once on a scenario builder"
            )
        }
        if (_actors.size > 0) {
            throw IllegalArgumentException(
                "withState must be called before adding actors"
            )
        }
        if (_afterBlock.isSome() || _verifyBlock.isSome()) {
            throw IllegalArgumentException(
                "withState must be called before after/verify blocks are configured " +
                "(their closures receive the previous state type)"
            )
        }
        if (_explicitValidator.isSome()) {
            throw IllegalArgumentException(
                "withState must be called before sequentialSpec " +
                "(the spec's operations receive the previous state type)"
            )
        }
        let newBuilder = ScenarioBuilder<S2>(_name)
        newBuilder._iterations = _iterations
        newBuilder._consistencyModel = _consistencyModel
        newBuilder._stateFactory = Some(factory)
        newBuilder._stateFactoryExplicit = true
        newBuilder._parallelIterations = _parallelIterations
        newBuilder._testMode = _testMode
        newBuilder._pcpBudget = _pcpBudget
        newBuilder._pcpFireProb = _pcpFireProb
        newBuilder._starvationThreshold = _starvationThreshold
        newBuilder._switchBound = _switchBound
        newBuilder._sleepCharMode = _sleepCharMode
        newBuilder._obstructionPolicy = _obstructionPolicy
        newBuilder._replaySchedule = _replaySchedule
        newBuilder._pctSeed = _pctSeed
        // The reset block is state-type-agnostic (() -> Unit) and carries
        // over; it also keeps the auto-validator trigger active (build()
        // constructs the validator when a reset block is present).
        newBuilder._resetBlock = _resetBlock
        newBuilder
    }

    // Internal accessor used by the simple scenario(name) / scenario() factories
    // to pre-register the trivial { => () } state factory without setting the
    // "explicit" flag. This preserves the original behavior: simple scenarios
    // that don't call .reset { => ... } don't build an auto ConsistencyValidator
    // (which would otherwise re-execute operations against un-reset shared state
    // and produce spurious consistency failures).
    func defaultStateFactory(factory: () -> S): ScenarioBuilder<S> {
        _stateFactory = Some(factory)
        this
    }

    /**
     * Select the consistency model under which the scenario's recorded history
     * will be validated. Defaults to `SequentialConsistency`.
     *
     * Stronger models (`Linearizability`) admit fewer linearizations and can
     * detect more bugs (e.g. store-buffer effects) at higher per-iteration
     * validation cost; weaker models (`Serializability`) search every
     * permutation and are appropriate for SUTs whose methods are intentionally
     * not sequentially consistent.
     *
     * @param model consistency model to use
     * @return this builder, for fluent chaining
     */
    public func consistencyModel(model: ConsistencyModel): ScenarioBuilder<S> {
        _consistencyModel = model
        this
    }

    /**
     * Add a single-op actor whose body closes over the per-iteration state `S`.
     *
     * The body's return type `T` must satisfy `T <: Equatable<T>` so the
     * framework can compare the observed result against the sequentially
     * re-executed result. The result (or any thrown exception) is captured via
     * `execResultOf`. The actor is given an auto-generated name
     * `"actor_<index>"`.
     *
     * @param T result type of the body
     * @param body closure `(S) -> T` performing the operation
     * @return this builder, for fluent chaining
     */
    public func actor<T>(body: (S) -> T): ScenarioBuilder<S> where T <: Equatable<T> {
        _actors.add(Actor<S>(
            id: _actors.size,
            operations: [{ state: S => execResultOf({ => body(state) }) }],
            operationNames: ["op_0"],
            name: "actor_${_actors.size}"
        ))
        this
    }

    /**
     * Add a single-op actor with an explicit name, whose body closes over the
     * per-iteration state `S`.
     *
     * Same as `actor(body)` but uses the user-supplied `name` (surfaced in
     * mismatch tables and reports) instead of the auto-generated
     * `"actor_<index>"`.
     *
     * @param T result type of the body
     * @param name human-readable actor name
     * @param body closure `(S) -> T` performing the operation
     * @return this builder, for fluent chaining
     */
    public func actor<T>(name: String, body: (S) -> T): ScenarioBuilder<S> where T <: Equatable<T> {
        _actors.add(Actor<S>(
            id: _actors.size,
            operations: [{ state: S => execResultOf({ => body(state) }) }],
            operationNames: ["op_0"],
            name: name
        ))
        this
    }

    /**
     * Add `repeat` copies of a single-op actor, each running the same `body`
     * against the per-iteration state `S`.
     *
     * Equivalent to calling `actor(body)` `repeat` times. Useful for spawning
     * multiple contending actors with the same operation without writing a
     * loop. Each copy is given an auto-generated name `"actor_<index>"`.
     *
     * @param T result type of the body
     * @param repeat number of copies to add, must be `>= 1`
     * @param body closure `(S) -> T` performing the operation
     * @return this builder, for fluent chaining
     * @throws IllegalArgumentException if `repeat < 1`
     */
    public func actor<T>(repeat: Int64, body: (S) -> T): ScenarioBuilder<S> where T <: Equatable<T> {
        if (repeat < 1) {
            throw IllegalArgumentException("Repeat count must be at least 1")
        }
        for (_ in 0..repeat) {
            this.actor(body)
        }
        this
    }

    /**
     * Add a multi-op actor that runs the given operations sequentially in one
     * thread, in listed order.
     *
     * The actor's name is auto-generated (`"actor_<index>"`); each operation's
     * name (set when the `Operation` was constructed) is surfaced individually
     * in mismatch tables. Use this when an actor should perform several
     * distinct operations against the shared state (e.g. `add → peek → add`
     * for a queue).
     *
     * @param ops array of `Operation<S>` to execute in order within one thread
     * @return this builder, for fluent chaining
     */
    public func actorWithOps(ops: Array<Operation<S>>): ScenarioBuilder<S> {
        let wrappedOps = ops.map { op =>
            { state: S => op.executeWrapped(state) }
        }
        let names = ops.map { op => op.name }
        _actors.add(Actor<S>(
            id: _actors.size,
            operations: wrappedOps,
            operationNames: names,
            name: "actor_${_actors.size}"
        ))
        this
    }

    /**
     * Provide an explicit sequential reference implementation for the scenario.
     *
     * By default the framework re-executes the *same* operation lambdas that
     * the actors run, against a fresh per-iteration state, to obtain the
     * sequential result that the observed result is compared against
     * (auto-spec). This is convenient but assumes that running the operations
     * sequentially is itself correct — if the user is unsure, they can supply
     * an explicit reference implementation via `sequentialSpec`.
     *
     * `createFresh` produces a fresh instance of the reference state `T` at the
     * start of each permutation-DFS restart; `execute` re-executes a single
     * operation (identified by its `OperationInvocation`) against the reference
     * state and returns the type-erased result. The framework compares the
     * returned `EquatableObj` against the observed result captured during the
     * parallel execution.
     *
     * @param T reference state type
     * @param createFresh closure producing a fresh `T` per DFS restart
     * @param execute closure `(T, OperationInvocation) -> EquatableObj`
     *        re-executing one operation against the reference state
     * @return this builder, for fluent chaining
     */
    public func sequentialSpec<T>(
        createFresh: () -> T,
        execute: (T, OperationInvocation) -> EquatableObj
    ): ScenarioBuilder<S> {
        let create: () -> Any = { => createFresh() }
        let executeAny: (Any, OperationInvocation) -> EquatableObj = { state, inv =>
            if (let Some(typedState) <- (state as T)) {
                execute(typedState, inv)
            } else {
                EqProxy<Unit>(())
            }
        }
        _explicitValidator = Some(ConsistencyValidator(
            consistencyModel: _consistencyModel,
            createFreshInstance: create,
            reExecuteOperation: executeAny
        ))
        this
    }

    /**
     * Register a sequential post-block that runs on the orchestrator thread
     * (T0) after all actor futures are joined, before `verify` and the
     * consistency validator.
     *
     * Use this for teardown / inspection that should happen once per iteration
     * on the main thread (e.g. snapshot the final state, log a metric). The
     * block receives the per-iteration state `S`.
     *
     * @param body closure `(S) -> Unit` to run after the parallel part
     * @return this builder, for fluent chaining
     */
    public func after(body: (S) -> Unit): ScenarioBuilder<S> {
        _afterBlock = Some(body)
        this
    }

    /**
     * Register a post-iteration predicate that runs on the orchestrator thread
     * after `after` and before the consistency validator.
     *
     * If the predicate returns `false`, the iteration is marked as failed. A
     * `false` return on iteration 0 triggers early-exit (no further iterations
     * are dispatched). `verify` is fully orthogonal to consistency validation:
     * a scenario may use `verify` alone, `consistencyModel(...)` alone, or both.
     *
     * @param body closure `(S) -> Bool` returning `true` iff the final state
     *        is acceptable
     * @return this builder, for fluent chaining
     */
    public func verify(body: (S) -> Bool): ScenarioBuilder<S> {
        _verifyBlock = Some(body)
        this
    }

    /**
     * Explicitly enable or disable parallel iteration execution for the
     * scenario being built.
     *
     * When parallel execution is enabled, iteration 0 runs first sequentially
     * (to calibrate backoff timing), then iterations 1..N-1 are dispatched to a
     * bounded pool of workers that complete concurrently; their results are
     * delivered to the callback in completion order (out-of-order relative to
     * iteration index).
     *
     * Default behaviour: parallel execution is enabled automatically when
     * `.withState(factory)` was used (because each iteration then creates its own
     * isolated SUT instance), and disabled otherwise (simple capture-based
     * scenarios share mutable state across iterations). Call this method to
     * override the default.
     *
     * Contract when enabled: the user guarantees that reset/after/verify and
     * actor operation lambdas are safe to run concurrently across iterations —
     * e.g. by using `.withState(factory)` so each iteration receives a fresh
     * isolated SUT instance, or by making the captured SUT internally
     * thread-safe.
     *
     * @param enabled `true` to force-enable parallel iterations, `false` to
     *        force-disable
     * @return this builder, for fluent chaining
     */
    public func parallelIterations(enabled: Bool): ScenarioBuilder<S> {
        _parallelIterations = Some(enabled)
        this
    }

    /**
     * Finalise the scenario and return an immutable `ConcurrentScenario<S>`.
     *
     * Builds the auto `ConsistencyValidator` only when there is a mechanism to
     * produce a fresh isolated state per permutation-DFS restart (an explicit
     * `withState` factory or a `.reset { => ... }` block); simple capture-based
     * scenarios that use neither deliberately skip validation, matching the
     * original behavior.
     *
     * @return the built, immutable `ConcurrentScenario<S>`
     * @throws IllegalArgumentException if no actors have been added, or if no
     *         state factory is set (the latter cannot happen for builders
     *         returned by `scenario(...)` because they pre-register a default
     *         `{ => () }` factory)
     */
    public func build(): ConcurrentScenario<S> { // cjlint-ignore !G.FUN.01 single cohesive algorithm block; splitting it would scatter the invariant across helpers without simplifying any step
        if (_actors.size == 0) {
            throw IllegalArgumentException("At least one actor is required")
        }
        if (_stateFactory.isNone()) {
            // The simple scenario(name) / scenario() factories pre-register a
            // default { => () } state factory, so reaching here means the user
            // constructed ScenarioBuilder<S>(name) directly without calling
            // withState(...). For typed S, that's a programming error.
            throw IllegalArgumentException(
                "ScenarioBuilder requires a state factory to be set " +
                "(call .withState(factory) before adding actors, or start " +
                "from scenario(name) and add .withState(factory) first)"
            )
        }

        // pctSeed/replaySchedule pin exactly one PCT schedule (both force
        // iterations = 1); in the other modes that forced budget would
        // silently cripple the run — DPOR's schedule budget or Stress's
        // repetition budget — so they are rejected here instead.
        let modeIsPct = match (_testMode) {
            case PCT => true
            case _ => false
        }
        if ((_pctSeed.isSome() || _replaySchedule.isSome()) && !modeIsPct) {
            let modeName = match (_testMode) {
                case Stress => "Stress"
                case DPOR => "DPOR"
                case PCT => "PCT"
            }
            throw IllegalArgumentException(
                "pctSeed/replaySchedule configure PCT schedule exploration and are " +
                "rejected in ${modeName} mode (a fixed seed forces exactly one " +
                "iteration — in DPOR that would cap the whole exploration budget; " +
                "use mode(PCT))"
            )
        }

        let threadCount = _actors.size

        // Build the auto ConsistencyValidator only when there is a mechanism to
        // produce a fresh isolated state per permutation-DFS restart:
        //   - Explicitly registered state factory (typed scenarios), OR
        //   - Simple .reset { => var = ... } block (capture-based scenarios).
        // Simple scenarios that use neither (e.g. .actor { => counter.fetchAdd(1) }
        // without .reset) deliberately skip validation, matching the original
        // behavior — the validator would otherwise re-execute operations against
        // un-reset shared state and produce spurious consistency failures.
        // The NoValidation model is the explicit opt-out that wins over both:
        // no validator is built at all (see ConsistencyModel.NoValidation).
        let shouldBuildAutoValidator = _stateFactoryExplicit || _resetBlock.isSome()
        let finalValidator: ?ConsistencyValidator = if (let NoValidation <- _consistencyModel) {
            None
        } else if (_explicitValidator.isSome()) {
            _explicitValidator
        } else if (shouldBuildAutoValidator) {
        // cjlint-ignore -start !G.VAR.02 the variables below thread state across loop/algorithm iterations (accumulators or framework context); narrowing their scopes would change semantics
            let actorsArray = _actors.toArray()
            let resetBlock = _resetBlock
            let stateFactoryOpt = _stateFactory
            let createFreshAny: () -> Any = { =>
        // cjlint-ignore -end
                if (let Some(reset) <- resetBlock) {
                    reset()
                }
                // stateFactory is guaranteed Some by the check above.
                match (stateFactoryOpt) {
                    case Some(factory) => factory()
                    case None => ()
                }
            }
            let executeAny: (Any, OperationInvocation) -> EquatableObj = { state, inv =>
                if (let Some(s) <- (state as S)) {
                    let actor = actorsArray[inv.actorId]
                    actor.operations[inv.operationIndex](s)
                } else {
                    EqProxy<Unit>(())
                }
            }
            Some(ConsistencyValidator(
                consistencyModel: _consistencyModel,
                createFreshInstance: createFreshAny,
                reExecuteOperation: executeAny
            ))
        } else {
            None
        }

        // Default: parallel execution iff the user opted into the typed
        // per-iteration-state API (.withState). Simple capture-based scenarios
        // default to sequential to preserve the original reset->run->verify
        // per-iteration semantics on shared mutable state.
        let parallelMode = _parallelIterations ?? _stateFactoryExplicit

        ConcurrentScenario<S>(
            name: _name,
            threadCount: threadCount,
            iterations: _iterations,
            resetBlock: _resetBlock,
            stateFactory: _stateFactory,
            actors: _actors.toArray(),
            afterBlock: _afterBlock,
            verifyBlock: _verifyBlock,
            consistencyValidator: finalValidator,
            consistencyModel: _consistencyModel,
            parallelIterations: parallelMode,
            testMode: _testMode,
            pcpBudget: _pcpBudget,
            pcpFireProb: _pcpFireProb,
            starvationThreshold: _starvationThreshold,
            switchBound: _switchBound,
            sleepCharMode: _sleepCharMode,
            obstructionPolicy: _obstructionPolicy,
            replaySchedule: _replaySchedule,
            pctSeed: _pctSeed
        )
    }
}

// Simple, stateless API. Available only when S = Unit (i.e. for builders
// returned by scenario(name) / scenario()). The operation lambdas capture
// shared mutable state externally and ignore the (Unit) state placeholder.
extend ScenarioBuilder<Unit> {
    /**
     * Register a reset block that re-initialises the captured shared mutable
     * state before each iteration.
     *
     * Available only when `S = Unit`. Use this for capture-based scenarios
     * where the SUT is shared mutable state closed over by the actor lambdas
     * (e.g. an `AtomicInt64` declared in the test scope) — `reset` is called
     * on the orchestrator thread at the start of every iteration to put the
     * SUT back into a known state. When `reset` is set, the auto
     * `ConsistencyValidator` is built (each permutation-DFS restart invokes
     * `reset` to obtain an isolated SUT).
     *
     * @param body closure `() -> Unit` re-initialising the captured state
     * @return this builder, for fluent chaining
     */
    public func reset(body: () -> Unit): ScenarioBuilder<Unit> {
        _resetBlock = Some(body)
        this
    }

    /**
     * Add a single-op actor whose body captures shared mutable state
     * externally and ignores the `Unit` state placeholder.
     *
     * `Unit`-typed overload of `actor<T>(body: (S) -> T)` for capture-based
     * scenarios. The body's result type `T` must satisfy
     * `T <: Equatable<T>`. The actor is given an auto-generated name
     * `"actor_<index>"`.
     *
     * @param T result type of the body
     * @param body closure `() -> T` performing the operation
     * @return this builder, for fluent chaining
     */
    public func actor<T>(body: () -> T): ScenarioBuilder<Unit> where T <: Equatable<T> {
        _actors.add(Actor<Unit>(
            id: _actors.size,
            operations: [{ _: Unit => execResultOf(body) }],
            operationNames: ["op_0"],
            name: "actor_${_actors.size}"
        ))
        this
    }

    /**
     * Add a single-op actor with an explicit name, whose body captures shared
     * mutable state externally.
     *
     * `Unit`-typed overload of `actor<T>(name, body: (S) -> T)` for
     * capture-based scenarios. Same as `actor(body)` but uses the
     * user-supplied `name`.
     *
     * @param T result type of the body
     * @param name human-readable actor name
     * @param body closure `() -> T` performing the operation
     * @return this builder, for fluent chaining
     */
    public func actor<T>(name: String, body: () -> T): ScenarioBuilder<Unit> where T <: Equatable<T> {
        _actors.add(Actor<Unit>(
            id: _actors.size,
            operations: [{ _: Unit => execResultOf(body) }],
            operationNames: ["op_0"],
            name: name
        ))
        this
    }

    /**
     * Add `repeat` copies of a single-op actor, each running the same
     * `body` that captures shared mutable state externally.
     *
     * `Unit`-typed overload of `actor<T>(repeat, body: (S) -> T)` for
     * capture-based scenarios. Equivalent to calling `actor(body)` `repeat`
     * times.
     *
     * @param T result type of the body
     * @param repeat number of copies to add, must be `>= 1`
     * @param body closure `() -> T` performing the operation
     * @return this builder, for fluent chaining
     * @throws IllegalArgumentException if `repeat < 1`
     */
    public func actor<T>(repeat: Int64, body: () -> T): ScenarioBuilder<Unit> where T <: Equatable<T> {
        if (repeat < 1) {
            throw IllegalArgumentException("Repeat count must be at least 1")
        }
        for (_ in 0..repeat) {
            this.actor(body)
        }
        this
    }

    // Note: actorWithOps is intentionally NOT redefined here. When S = Unit,
    // the generic class's actorWithOps(ops: Array<Operation<S>>) already
    // accepts Operation<Unit> (since S = Unit), and the simple
    // operation<T>(name, body: () -> T) factory returns Operation<Unit>, so
    // the generic class's method is invoked directly with the correct
    // S = Unit binding. Re-declaring it here would produce an illegal shadow
    // of the generic class's method.

    /**
     * Register a sequential post-block that runs on the orchestrator thread
     * after all actor futures are joined.
     *
     * `Unit`-typed overload of `after(body: (S) -> Unit)` for capture-based
     * scenarios — the body takes no arguments and operates on the captured
     * shared mutable state.
     *
     * @param body closure `() -> Unit` to run after the parallel part
     * @return this builder, for fluent chaining
     */
    public func after(body: () -> Unit): ScenarioBuilder<Unit> {
        _afterBlock = Some({ _: Unit => body() })
        this
    }

    /**
     * Register a post-iteration predicate; `false` fails the iteration.
     *
     * `Unit`-typed overload of `verify(body: (S) -> Bool)` for capture-based
     * scenarios — the body takes no arguments and operates on the captured
     * shared mutable state. A `false` return on iteration 0 triggers
     * early-exit.
     *
     * @param body closure `() -> Bool` returning `true` iff the final state
     *        is acceptable
     * @return this builder, for fluent chaining
     */
    public func verify(body: () -> Bool): ScenarioBuilder<Unit> {
        _verifyBlock = Some({ _: Unit => body() })
        this
    }
}
