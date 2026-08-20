# SM64 Modern Full Swift Twin — M33cj Handoff

Date: 2026-08-18

## Completed slice

M33cj adds `AmbientSoundLoopBehavior` and a shared generation-safe owner route
for `bhvBirdsSoundLoop` and `bhvSandSoundLoop` (dispatch route 89). Swift
owns the camera-behind-Mario suppression boundary, bird sound variants, and
moving-sand sound intent. The owner tracks default-list loop objects and emits
one deterministic ambient sound effect per tick.

## Validation

- `script/test_ambient_sound_loop.sh` passes with matching Swift/C fingerprint
  `0x76f14fcfeaac188b`.
- `script/test_behavior_dispatch_bridge.sh` verifies bird variants, camera
  suppression, and sand selection with the existing dispatch fingerprint
  `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x4cec35dde19a015d`, 534 rows, 145 Swift value/owner routes, and 389
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

389 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue remaining compact sound/environment/hazard families, then migrate
collision-heavy routes and shared collision-world owners.
