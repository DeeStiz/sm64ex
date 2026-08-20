# SM64 Modern Full Swift Twin — M33nc Handoff

M33nc expands the Bowling Ball value/owner family with `bhvPitBowlingBall`.
The pit role preserves gravity/friction/buoyancy setup, flat-floor 28-unit
forward velocity, shared hitbox/visibility, camera-shake, and environment-roll
sound effects. It also carries the TTM/THI spawner and Mr. I blue-coin ledger
closures in the same complete evidence checkpoint.

## Evidence

- Focused Bowling Ball contract: `./script/test_bowling_ball.sh`
  (`0x88570fdd4c786c82`).
- Aggregate dispatch smoke: `./script/test_behavior_dispatch_bridge.sh`,
  covering Bob/TTM/THI spawners and pit effects.
- Manifest: `./script/test_behavior_manifest.sh`; `534` rows, `476`
  Swift-owned, `58` explicit C adapters, fingerprint
  `0xe69be08621cbc0da`.
- Runtime/live route gates: `./script/test_engine_runtime.sh` and
  `./script/test_live_route_oracle.sh full`.
- `xcodegen generate --spec project.yml`, Metal 4 source contract, shell
  syntax, and `git diff --check` pass.
- Complete verifier: `/tmp/sm64-modern-m33nc-full-verify.log`, with
  `verify_exit=0`, `** BUILD SUCCEEDED **`, Apple M5 Max `api=Metal4` frame
  one, `engine_thread_finished status=0`, and `application_stopped`.

## Open gates

The remaining 58 C adapters, 7,419 route shards, sanitizer runs, full Swift
authority promotion, complete Metal 4 visual/performance/thermal/device
evidence, release/notarization, audio/effect parity, and human acceptance
remain open. The pasted crash remains an AppKit/LaunchServices
`NSApplication` registration abort at `AppMain.swift:7`, separate from the
successful host verifier path.

## Next action

Continue the source-order adapter ledger with the next compact family; repeat
focused C parity, dispatch/manifest, runtime/live, strict Swift 6, Metal 4,
and retained full-verifier gates before advancing the goal.
