# SM64 Modern Full Swift Twin — M33mv Handoff

M33mv adds `bhvUnlockDoorStar` as a Swift 6 value/owner path. The reducer
preserves the C rise/wait/particle/done state machine: yaw velocity ramps by
`0x60` to `0x2400`, the star rises by `3.4` units per frame, scale grows from
`0.5`, the final wait emits the menu-star sound and hides the object, the
particle phase lasts through the authored timer edge, and deletion remains
the post-sound `== 50` edge. The object bridge publishes only fixed-width
copied state through the shared spawned-star dispatch lane and retains
generation-safe registration/pruning.

## Evidence

- Focused C↔Swift contract: `./script/test_unlock_door_star.sh`
  (`0xa818fe2cbab2403f`).
- Aggregate dispatch smoke and C contract: `./script/test_behavior_dispatch_bridge.sh`.
- Coverage manifest: `./script/test_behavior_manifest.sh`;
  `534` rows, `466` Swift-owned, `68` explicit C adapters,
  fingerprint `0x1c009f71986f30d4`.
- Strict runtime/live route gates: `./script/test_engine_runtime.sh` and
  `./script/test_live_route_oracle.sh full`.
- Regenerated project: `xcodegen generate --spec project.yml`.
- Metal 4 source contract: `./script/test_metal4_contract.sh`.
- Complete `./script/build_and_run.sh --verify` run on 2026-08-19 cleared the
  registered matrix, regenerated Swift 6 Debug build, Apple M5 Max Metal 4
  frame-one host launch, and clean `engine_thread_finished status=0` /
  `application_stopped` shutdown. The run also exercised the focused route and
  new manifest fingerprint.

## Files

- `SM64Modern/UnlockDoorStarBehavior.swift`
- `SM64Modern/UnlockDoorStarObjectBridge.swift`
- `tests/sm64_modern_unlock_door_star_smoke.swift`
- `tests/sm64_modern_unlock_door_star_contract.c`
- `script/test_unlock_door_star.sh`
- shared dispatch, manifest, aggregate smoke, runtime/live source lists, and
  `script/build_and_run.sh` registration.

## Open gates

The sparkle child geometry/audio effect promotion is still represented as an
immutable effect intent, not a complete Swift particle/audio authority. The
remaining 68 C adapter rows, all 7,419 route shards, sanitizer runs, complete
Metal 4 visual/performance/thermal/device evidence, release/notarization, and
human acceptance remain open. The prior crash log is an AppKit/LaunchServices
abort during `NSApplication` registration (`AppMain.swift:7`), not a behavior
route fault; host runs that reach the normal window/Metal path are separate
runtime evidence and do not erase that environment-specific launch failure.

## Next action

Continue the source-order adapter ledger with the next compact reachable C
family, keeping the per-slice contract/dispatch/manifest/runtime/live/strict
build loop and updating this goal only after the gates above pass.
