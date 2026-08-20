# SM64 Modern Full Swift Twin — M33gb Handoff

## Scope

M33gb migrates `bhvOpenableGrill` and `bhvOpenableCageDoor` as a Swift 6
parent/child environment route. The owner preserves the two authored
half-width variants, floor-switch discovery and action-2 admission, cage-open
sound/jingle intents, generation-safe child allocation, child direction/yaw
setup, 64-frame cage travel, and collision-load ownership.

## Evidence

- Focused Swift/C openable-grill fingerprint: `0xb2e5b527958d6d7c` from
  `script/test_openable_grill.sh`.
- Behavior manifest: `0x95a07155c113c1a4`, 534 rows, 280 Swift value/owner
  routes, 254 explicit C adapters.
- Dispatch smoke verifies both identities, two child allocations, floor-switch
  gating, open sound/jingle signaling, child activation, and yaw travel.
- `script/test_behavior_manifest.sh`, `script/test_behavior_dispatch_bridge.sh`,
  `script/test_engine_runtime.sh`, and `script/test_live_route_oracle.sh` pass.
- Route-shard replay, timebase audit, Metal 4 source contract, `zsh -n`, and
  `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33gb-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and
visual/audio/controller/human parity acceptance remain open. The host
LaunchServices database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared`, before `AppDelegate`/engine startup.

## Next

Continue the remaining door, hidden-object, environment, and frontend families
while retaining the value/owner/C-oracle/dispatch/manifest/live-trace/
strict-build/Metal-contract evidence loop.
