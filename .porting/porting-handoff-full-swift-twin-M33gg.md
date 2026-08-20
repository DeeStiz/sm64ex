# SM64 Modern Full Swift Twin — M33gg Handoff

## Scope

M33gg migrates `bhvMovingYellowCoin` and `bhvMovingBlueCoin` as a shared
Swift 6 physics/interaction route. The owner preserves yellow/blue coin
values, gravity/friction/buoyancy setup, yellow tangibility delay and
301-frame action transition, blue 1,500-unit movement admission, grounded
forward-speed acceleration/cap, airborne damping, coin-drop sound gating,
flicker/death fences, and interaction sparkle retirement.

## Evidence

- Focused Swift/C moving-coin fingerprint: `0x5fad4e584bf56f1f` from
  `script/test_moving_coin.sh`.
- Behavior manifest: `0x626fe55eb8d2c425`, 534 rows, 289 Swift value/owner
  routes, 245 explicit C adapters.
- Dispatch smoke verifies both identities, yellow tangibility/sound, blue
  radius admission, and owner routing.
- `script/test_behavior_manifest.sh`, `script/test_behavior_dispatch_bridge.sh`,
  `script/test_engine_runtime.sh`, and `script/test_live_route_oracle.sh` pass.
- Route-shard replay, timebase audit, Metal 4 source contract, `zsh -n`, and
  `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33gg-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and
visual/audio/controller/human parity acceptance remain open. The host
LaunchServices database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared`, before `AppDelegate`/engine startup.

## Next

Continue the remaining water-level, hidden-switch, environment, and frontend
families while retaining the value/owner/C-oracle/dispatch/manifest/live-trace/
strict-build/Metal-contract evidence loop.
