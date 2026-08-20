# SM64 Modern Full Swift Twin — M33gh Handoff

## Scope

M33gh migrates `bhvWaterLevelDiamond` and `bhvInitializeChangingWaterLevel`
as Swift 6 environment/global routes. The owner preserves diamond
initialization/idle/change/spinning actions, the shared water-changing gate,
target-level approach, trigger/drain sound edges, 0x800 spin, rumble intent,
collision values, and the initializer's region-copy/10-frame sine cadence.

## Evidence

- Focused Swift/C water-level fingerprint: `0x385a79b4fb5775cd` from
  `script/test_water_level.sh`.
- Behavior manifest: `0x7c51e00bd314c000`, 534 rows, 291 Swift value/owner
  routes, 243 explicit C adapters.
- Dispatch smoke verifies both identities, diamond initialization, shared
  change gating, and environment transition admission.
- `script/test_behavior_manifest.sh`, `script/test_behavior_dispatch_bridge.sh`,
  `script/test_engine_runtime.sh`, and `script/test_live_route_oracle.sh` pass.
- Route-shard replay, timebase audit, Metal 4 source contract, `zsh -n`, and
  `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33gh-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and
visual/audio/controller/human parity acceptance remain open. The host
LaunchServices database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared`, before `AppDelegate`/engine startup.

## Next

Continue the remaining water-pillar, hidden-switch, environment, and frontend
families while retaining the value/owner/C-oracle/dispatch/manifest/live-trace/
strict-build/Metal-contract evidence loop.
