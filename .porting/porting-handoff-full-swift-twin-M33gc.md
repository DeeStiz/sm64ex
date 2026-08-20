# SM64 Modern Full Swift Twin — M33gc Handoff

## Scope

M33gc migrates `bhvDoor` and `bhvDoorWarp` as shared Swift 6 surface routes.
The owner preserves the interaction-mask action mapping, wood/iron opening and
closing sound timing, warp-door close timing, camera-event distinction,
room-gated visibility, animation reset, Mario-opened-door time-stop intent,
and action-zero collision ownership.

## Evidence

- Focused Swift/C door fingerprint: `0x38f73900b34f019a` from
  `script/test_door.sh`.
- Behavior manifest: `0x73c3a9af5378685b`, 534 rows, 282 Swift value/owner
  routes, 252 explicit C adapters.
- Dispatch smoke verifies normal/warp identity routing, interaction mapping,
  wood sound/time-stop behavior, warp camera selection, and animation reset.
- `script/test_behavior_manifest.sh`, `script/test_behavior_dispatch_bridge.sh`,
  `script/test_engine_runtime.sh`, and `script/test_live_route_oracle.sh` pass.
- Route-shard replay, timebase audit, Metal 4 source contract, `zsh -n`, and
  `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33gc-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and
visual/audio/controller/human parity acceptance remain open. The host
LaunchServices database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared`, before `AppDelegate`/engine startup.

## Next

Continue the remaining hidden-object, environment, and frontend families while
retaining the value/owner/C-oracle/dispatch/manifest/live-trace/strict-build/
Metal-contract evidence loop.
