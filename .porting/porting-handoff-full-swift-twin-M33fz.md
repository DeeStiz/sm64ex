# SM64 Modern Full Swift Twin — M33fz Handoff

## Scope

M33fz migrates `bhvCapSwitch` and `bhvCapSwitchBase` as a Swift 6
cap-unlock surface/base pair. The owner preserves variant animation and save
flag selection, the 71-unit initialization offset, generation-safe base-child
spawn, Mario-on-platform activation, activation sound, press scaling,
timer-4 mist/triangle/rumble effects, dialog completion, pressed-state scale,
and base collision-load intent.

## Evidence

- Focused Swift/C cap-switch fingerprint: `0x4b9fda77d0cf8565` from
  `script/test_cap_switch.sh`.
- Behavior manifest: `0x2ac67d61263b5895`, 534 rows, 277 Swift value/owner
  routes, 257 explicit C adapters.
- Dispatch smoke verifies both identities, base-child allocation, save-flag
  initialization, Mario activation, press effects, and dialog completion.
- `script/test_behavior_manifest.sh`, `script/test_behavior_dispatch_bridge.sh`,
  `script/test_engine_runtime.sh`, and `script/test_live_route_oracle.sh` pass.
- Route-shard replay, timebase audit, Metal 4 source contract, `zsh -n`, and
  `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33fz-xcode` with `** BUILD SUCCEEDED **`.

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
