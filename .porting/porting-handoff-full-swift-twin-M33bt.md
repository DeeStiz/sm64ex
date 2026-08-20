# SM64 Modern Full Swift Twin — M33bt Handoff

Date: 2026-08-17

## Completed slice

M33bt adds `LllRotatingHexFlameBehavior` and an owner route for the
parent-relative `bhvLllRotatingHexFlame` child, dispatch route 73. Swift owns
canonical parent-relative left/forward transform math, the fixed +100 Y
offset, velocity derivation, and parent-action-3 deletion intent. The owner
bridge owns stable parent linkage, level-list position/velocity mutation, and
end-of-frame deletion.

## Validation

- New `script/test_lll_rotating_hex_flame.sh` Swift/C contract passes with
  fingerprint `0x348f5a90083b5892`.
- `script/test_behavior_dispatch_bridge.sh` exercises parent-relative position,
  shared route identity, and parent-action deletion/unload through route 73.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x5a77afc11815cae9`, 534 rows, 120 Swift value/owner routes, and 414 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, route-shard replay, strict
  regenerated Swift 6 Xcode Debug build, timebase audit, Metal 4 source
  contract, and `git diff --check` pass.

## Open evidence

414 reachable C adapters remain, and the 7,419-shard execution ledger is still
planned rather than fully executed. Native runtime promotion and Metal
validation/capture remain blocked by the host-wide LaunchServices `-10827`
boundary before `NSApplication`/engine startup. Physical visual, thermal,
device-loss, release, and human acceptance remain separate gates.

## Next action

Continue remaining LLL fire-bar/parent and hazard families, then close
collision and presentation consumers.
