# SM64 Modern Full Swift Twin — M33gi Handoff

## Scope

M33gi adds value-owned static collision-load modes for `bhvTower`,
`bhvBulletBillCannon`, `bhvLllHexagonalMesh`, `bhvHiddenStaircaseStep`,
`bhvPillarBase`, `bhvInSunkenShip`, and `bhvInSunkenShip2`. The owner keeps
surface-list admission, authored collision identities/distances, drawing
distance, room scope, the sunken-ship rotation helper, and registration of
collision surface IDs in the Swift engine state.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` passes with
  `behaviorDispatchBridgeFingerprint=0x681ceb2358bf2e21`, including surface,
  collision-distance, drawing-distance, rotation, and platform-owner asserts.
- `script/test_behavior_manifest.sh` passes with
  `behaviorManifestFingerprint=0xbd8a849d5c4a5bbb`, 534 rows, 361 Swift
  value/owner routes, and 173 explicit C adapters.
- `script/test_metal4_contract.sh`, engine runtime, live-route oracle,
  route-shard replay, timebase audit, and `git diff --check` pass.
- Regenerated strict Swift 6 Xcode Debug build passes with `** BUILD SUCCEEDED **`
  at `build/sm64-modern-m33gi-xcode`.

## Open gates

The full verifier was rerun through M33hg and reaches `BUILD SUCCEEDED` before
the host-only LaunchServices failure. It should be rerun after M33gi. Full
7,419-row qualification, zero-unmigrated-adapter closure, native runtime
promotion, physical-device rendering, GPU validation/capture, performance/
thermal evidence, release signing/notarization, and visual/audio/controller/
human parity acceptance remain open. The host LaunchServices database still
returns `kLSNoExecutableErr (-10827)` for the built app before AppKit/engine
startup.

## Next

Continue collision/global/environment migration with formation spawners,
water-cannon/cannon routes, dynamic platform actors, and gameplay actors. Keep
the value → owner → C oracle → dispatch → manifest → live trace evidence chain
and rerun the full verifier before promoting any route family.
