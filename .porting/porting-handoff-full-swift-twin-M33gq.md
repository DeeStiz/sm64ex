# SM64 Modern Full Swift Twin — M33gq Handoff

## Scope

M33gq migrates `bhvSoundSpawner` and `bhvRockSolid` as Swift 6 owner routes.
The owners preserve the sound spawner's three-frame delay, one-shot sound
edge, 30-frame deactivation window, and unimportant-list lifecycle, plus the
rock-solid surface route's persistent collision-load intent and pruning.

## Evidence

- Focused Swift/C sound/rock fingerprint:
  `0x4361939714f8a64d` from `script/test_sound_rock.sh`.
- Dispatch smoke fingerprint: `0x681ceb2358bf2e21`; it exercises both
  identities through the production behavior bridge.
- Behavior manifest: `0x47574fde9831c28f`, 534 rows, 313 Swift value/owner
  routes, and 221 explicit C adapters.
- `script/test_behavior_coverage.sh` passes with 57 opcode classes and 547
  native callbacks inventoried.
- Engine-runtime and live-route oracle scripts rebuild; the retained full
  trace replays exactly through the C oracle and rejects deliberate tamper.
- Route-shard replay, timebase audit, Metal 4 source contract, shell syntax,
  and `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33gq-xcode` with `** BUILD SUCCEEDED **`.

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

Continue the remaining compact object/environment families while retaining
the complete Swift value → owner → C oracle → dispatch → manifest → live
trace → strict-build evidence loop.
