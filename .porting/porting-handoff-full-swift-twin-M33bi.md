# SM64 Modern Full Swift Twin — M33bi Handoff

Date: 2026-08-17

## Completed slice

M33bi creates `WfSolidTowerPlatformBehavior` and migrates the parent-owned
`bhvWfSolidTowerPlatform` child through `WfSolidTowerPlatformObjectBridge`,
dispatch route 63. Swift owns the parent-action deletion predicate. The owner
bridge owns stable parent linkage, end-of-frame deactivation/unload, and
generation-safe cleanup without adding a child scheduler.

## Validation

- New `script/test_wf_solid_tower_platform.sh` Swift/C contract passes with
  fingerprint `0xa803617659589552`.
- `script/test_behavior_dispatch_bridge.sh` exercises parent action 3,
  deletion intent, route ordering, and child unload through route 63.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0xe0d6bc958d032a68`, 534 rows, 106 Swift value/owner routes, and 428 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, strict regenerated Swift 6 Xcode
  Debug build, timebase audit, Metal 4 source contract, and `git diff --check`
  pass.

## Open evidence

428 reachable C adapters remain, and the 7,419-shard execution ledger is still
planned rather than fully executed. Native runtime promotion and Metal
validation/capture remain blocked by the host-wide LaunchServices `-10827`
boundary before `NSApplication`/engine startup. Physical visual, thermal,
device-loss, release, and human acceptance remain separate gates.

## Next action

Continue parent/child tower and platform families, then close multi-child
collision/presentation consumers and whole-engine authority.
