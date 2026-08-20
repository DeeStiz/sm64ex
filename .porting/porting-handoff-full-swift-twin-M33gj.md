# SM64 Modern Full Swift Twin — M33gj Handoff

## Scope

M33gj migrates the shared purple floor-switch route for
`bhvFloorSwitchHardcodedModel`, `bhvFloorSwitchGrills`,
`bhvFloorSwitchAnimatesObject`, and `bhvFloorSwitchHiddenObjects`.
The owner preserves platform/lateral admission, Mario action gating, pressed
scaling, activation sound/rumble, fast/slow ticking, byte-specific
release/wait behavior, unpressed recovery, and collision ownership.

## Evidence

- Focused Swift/C floor-switch fingerprint: `0x908ab416de4408fe` from
  `script/test_floor_switch.sh`.
- Behavior manifest: `0x8fb3aa416c3f5410`, 534 rows, 296 Swift value/owner
  routes, 238 explicit C adapters.
- Dispatch smoke verifies the animated identity, platform admission, and press
  transition.
- `script/test_behavior_manifest.sh`, `script/test_behavior_dispatch_bridge.sh`,
  `script/test_engine_runtime.sh`, and `script/test_live_route_oracle.sh` pass.
- Route-shard replay, timebase audit, Metal 4 source contract, `zsh -n`, and
  `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33gj-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and
visual/audio/controller/human parity acceptance remain open. The host
LaunchServices database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared`, before `AppDelegate`/engine startup.

## Next

Continue the remaining animated floor-switch objects, water/environment, and
frontend families while retaining the value/owner/C-oracle/dispatch/manifest/
live-trace/strict-build/Metal-contract evidence loop.
