# SM64 Modern Full Swift Twin — M33gk Handoff

## Scope

M33gk migrates `bhvAnimatesOnFloorSwitchPress` as a Swift 6 value/owner child
route. The owner preserves the parent action-2 admission, toggle and
retrigger behavior, authored 250/200/200-frame variant durations, remaining
timer and fast/slow sound cadence, animation/model frame progression,
collision-load intent, parent linkage, and generation-safe removal.

## Evidence

- Focused Swift/C animated-floor-switch fingerprint:
  `0xd3d13ed14b76d885` from `script/test_animated_floor_switch.sh`.
- Dispatch smoke fingerprint: `0x681ceb2358bf2e21`; the floor-switch parent
  spawns and advances the animated child through the production dispatch bridge.
- Behavior manifest: `0xc994933ec600a82c`, 534 rows, 297 Swift value/owner
  routes, and 237 explicit C adapters.
- `script/test_behavior_coverage.sh` passes with 57 opcode classes and 547
  native callbacks inventoried.
- `script/test_engine_runtime.sh` produces a passing engine-runtime smoke;
  its rebuilt executable reports `SM64 Modern engine runtime smoke passed`.
- `script/test_live_route_oracle.sh` produces a full eight-record Swift trace
  and C replay/tamper gate; the retained full trace reports exact C/Swift
  replay with first divergence only on the deliberate mutation.
- Route-shard replay, timebase audit, Metal 4 source contract, shell syntax,
  and `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33gk-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and
visual/audio/controller/human parity acceptance remain open. The host
LaunchServices database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared` before `AppDelegate`/engine startup, so it is not
counted as game or Metal runtime evidence.

## Next

Continue the compact environment and hidden-object families with the same
Swift value/owner, independent C oracle, dispatch, manifest, live-trace,
strict-build, Metal-contract, and hygiene loop. Prefer the next bounded
family whose source behavior can be represented without introducing a new
pointer-backed authority boundary; keep full-game shard and native GUI gates
separate until the host LaunchServices boundary is repaired.
