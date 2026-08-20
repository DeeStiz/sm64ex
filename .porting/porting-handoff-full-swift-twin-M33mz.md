# SM64 Modern Full Swift Twin — M33mz Handoff

M33mz adds `bhvToxBox` as a Swift 6 value/owner route through the existing
collision lane. The reducer preserves direction-table admission, timer-20
wait actions, eight-frame forward/side movement cadence, vertical sine
transform, pitch/roll rotation, move-sound and shake edges, and unconditional
collision-model loading. The owner bridge carries only copied action/timer/
transform values and retains the C route as the fallback authority.

## Evidence

- Focused C↔Swift contract: `./script/test_tox_box.sh`
  (`0x94a72bac32bcb54b`).
- Aggregate dispatch smoke: `./script/test_behavior_dispatch_bridge.sh`,
  including action selection and collision output.
- Manifest: `./script/test_behavior_manifest.sh`; `534` rows, `472`
  Swift-owned, `62` explicit C adapters, fingerprint
  `0x588c2e8f5b914266`.
- Runtime/live route gates: `./script/test_engine_runtime.sh` and
  `./script/test_live_route_oracle.sh full`.
- `xcodegen generate --spec project.yml`, Metal 4 source contract, shell
  syntax, and `git diff --check` pass.
- Complete verifier: `/tmp/sm64-modern-m33mz-full-verify.log`, with
  `verify_exit=0`, `** BUILD SUCCEEDED **`, Apple M5 Max `api=Metal4` frame
  one, `engine_thread_finished status=0`, and `application_stopped`.

## Open gates

Tox Box action-table coverage remains bounded until every direction-table and
course placement is executed by route shards. The remaining 62 C adapters,
7,419 route shards, sanitizer runs, full Swift authority promotion, complete
Metal 4 visual/performance/thermal/device evidence, release/notarization, and
human acceptance remain open. The pasted crash remains an
AppKit/LaunchServices `NSApplication` registration abort at `AppMain.swift:7`,
separate from the successful host verifier path.

## Next action

Continue the source-order adapter ledger with the next compact family; repeat
focused C parity, dispatch/manifest, runtime/live, strict Swift 6, Metal 4,
and retained full-verifier gates before advancing the goal.
