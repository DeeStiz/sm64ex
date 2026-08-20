# SM64 Modern Full Swift Twin — M33mw Handoff

M33mw closes two compact ledger gaps. `bhvTrackBall` is now a Swift 6
value/owner route through the existing WF tower-platform dispatch lane. It
mirrors the C child lifetime rule exactly: cast the behavior byte and parent
base-ball index to signed 16-bit values, compute `relativeIndex = byte - base -
1`, retain only indices `1...5`, and mark stale children for deletion. The
existing `bhvScuttlebugSpawn` owner was also added to the manifest so its
already-tested Swift spawner path is counted.

## Evidence

- Focused Track Ball C↔Swift contract: `./script/test_track_ball.sh`
  (`0x7f3cd721bf073d7f`).
- Aggregate dispatch smoke: `./script/test_behavior_dispatch_bridge.sh`,
  including active/stale parent-child track-ball records.
- Manifest: `./script/test_behavior_manifest.sh`; `534` rows, `468`
  Swift-owned, `66` explicit C adapters, fingerprint
  `0x478b49ec28547d0e`.
- Runtime/live route gates: `./script/test_engine_runtime.sh` and
  `./script/test_live_route_oracle.sh full`.
- `xcodegen generate --spec project.yml`, Metal 4 source contract, shell
  syntax, and `git diff --check` pass.
- Complete verifier output is retained at
  `/tmp/sm64-modern-m33mw-full-verify.log`: it reaches `** BUILD SUCCEEDED **`,
  Apple M5 Max `api=Metal4` frame one, `engine_thread_finished status=0`, and
  `application_stopped`. The outer zsh wrapper attempted to assign the
  read-only variable `status` after the inner command completed; the retained
  log/end markers are the authoritative evidence.

## Open gates

Track-ball parent movement remains a bounded child-lifetime contract until
full route-shard replay exercises every platform trajectory. The remaining 66
C adapters, 7,419 route shards, sanitizer runs, full Swift authority
promotion, complete Metal 4 visual/performance/thermal/device evidence,
release/notarization, and human acceptance remain open. The pasted crash is
still an AppKit/LaunchServices `NSApplication` registration abort at
`AppMain.swift:7`, separate from the successful host runs that reach the
window/Metal owner path.

## Next action

Continue the source-order adapter ledger with the next compact behavior family,
then repeat focused C parity, dispatch/manifest, runtime/live, strict Swift 6,
Metal 4, and retained full-verifier evidence before promoting any new route.
