# SM64 Modern Full Swift Twin — M22i Handoff

## Scope

M22i makes `SM64BehaviorDispatchBridge` the default object callback for
`SM64ModernSwiftEngineContext.step()`. The context now retains the dispatch
receipt for each tick, resets route registrations on initialization and
shutdown, and exposes the same shared route path to the live-route oracle and
promotion builds. Unknown behavior identities remain explicit
`unmigrated` events; no C-shaped fallback is implied.

This closes engine-context dispatch authority for the two proven routes only.
It does not close whole-engine behavior breadth, C adapter removal, real
audio/render/collision consumers, or whole-game parity.

## Evidence

- `script/test_engine_runtime.sh` — context lifecycle and default dispatcher
  callback contract pass; unknown actor and decorative pendulum events are
  retained in the dispatch receipt.
- `script/test_live_route_oracle.sh` and
  `script/test_live_route_promotion.sh` — schema-4 C/Swift replay and
  fail-closed live shard promotion pass after compiling the dispatcher
  dependency set.
- `script/test_behavior_dispatch_bridge.sh` — mixed-route Swift/C fingerprint
  `0x9445d688831ca6c7` remains stable.
- `/tmp/sm64-modern-m22i-build.log` — regenerated native Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22i-final-matrix.log` — complete matrix,
  `runs=206 failures=0`.
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Register every already-proven Swift owner bridge in the shared dispatch
   table and migrate level-spawn attachment through behavior identity.
2. Migrate the remaining 461 reachable adapters, or record an explicitly
   approved compatibility exception for each one.
3. Add real audio, camera, collision, renderer, progression, and save
   consumers, then compare complete C-vs-Swift object/effect/render traces.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict concurrency, replay,
   Metal 4 production, device, performance, visual, and human acceptance.

## Next command

Register the next exact Swift owner identity in `SM64BehaviorDispatchBridge`,
attach it through the engine context, add an independent C ordering/receipt
fixture, and rerun the native build plus complete 206-script matrix before
promoting the next local milestone.
