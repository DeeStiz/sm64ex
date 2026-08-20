# SM64 Modern Full Swift Twin — M33cq Handoff

Date: 2026-08-18

## Completed slice

M33cq adds the shared `WaterSplashBehavior` and generation-safe owner route
for `bhvBubbleSplash` and `bhvWaterDropletSplash` (dispatch route 96). Swift
owns surface-height/scale initialization and the six-frame animation lifetime.
The already-migrated object-bubble and water-droplet parents now attach their
spawned children to the shared owner bridge instead of leaving them as
unregistered C-only records.

## Validation

- `script/test_water_splash.sh` passes with matching Swift/C fingerprint
  `0x13f1cb3de4660b22`.
- `script/test_behavior_dispatch_bridge.sh` verifies both direct child routes
  and parent-spawned child attachment with the existing dispatch fingerprint
  `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0xd3d568514234937a`, 534 rows, 153 Swift value/owner routes, and 381
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

381 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining compact water/environment/hazard family, then migrate
collision-heavy routes and shared collision-world owners.
