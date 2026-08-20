# SM64 Modern Full Swift Twin — M33gt Handoff

## Scope

M33gt migrates `bhvCastleFloorTrap` and `bhvFloorTrapInCastle` through one
Swift 6 parent/child mechanical owner. It preserves trap open/close/rotate
actions, angle-velocity changes, open sound edge, child roll propagation,
Mario platform turn handoff, interaction reset, and surface collision
ownership.

## Evidence

- Focused Swift/C castle-floor-trap fingerprint:
  `0x3489058a8683fdcc` from `script/test_castle_floor_trap.sh`.
- Dispatch smoke fingerprint: `0x681ceb2358bf2e21`; it exercises the parent
  and generated child identities through the production bridge.
- Behavior manifest: `0x8c9f983fb771b6cb`, 534 rows, 321 Swift value/owner
  routes, and 213 explicit C adapters.
- `script/test_behavior_coverage.sh` passes with 57 opcode classes and 547
  native callbacks inventoried.
- Engine-runtime and live-route oracle scripts rebuild; the retained full
  trace replays exactly through the C oracle and rejects deliberate tamper.
- Route-shard replay, timebase audit, Metal 4 source contract, shell syntax,
  and `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33gt-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and
visual/audio/controller/human parity acceptance remain open. The host
LaunchServices database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared` before `AppDelegate`/engine startup, so it is not
counted as game or Metal runtime evidence.

## Next

Continue the remaining compact mechanical/object families while retaining the
full Swift value → owner → C oracle → dispatch → manifest → live trace →
strict-build evidence loop.
