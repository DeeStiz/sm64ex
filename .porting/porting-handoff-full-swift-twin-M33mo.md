# SM64 Modern Full Swift Twin — M33mo Handoff

## Scope

M33mo consolidates `bhvSlidingSnowMound` and `bhvSnowMoundSpawn` into one
Swift owner. It preserves the two-action slide/fall reducer, 118/50-frame
transitions, sink-sound edge, 64/128/192/224/256 spawn cadence, 256 timer
reset, large-child scale, and generation-safe child ownership.

## Evidence

- Shared focused Swift/C Snow Mound contract matches at
  `0x3065533e47dbdaa9`.
- Aggregate dispatch proves both identities, action transitions, cadence, and
  child spawn; behavior manifest, Metal 4 source contract, engine runtime,
  live-route C replay, coverage, 7,419-shard inventory, regenerated strict
  Swift 6 Xcode Debug build, shell syntax, and `git diff --check` pass.
- The full verifier completed with `verify_exit=0` in
  `/tmp/sm64-modern-m33mo-full-verify.log`: the complete matrix/build passed,
  the host launched on Apple M5 Max with Metal 4/BGRA8Unorm and a frame-one
  presentation, and the log records `engine_thread_finished status=0` plus
  `application_stopped`. It also records `audio_service_stopped ...
  underrun=139`; sustained audio/device quality remains open.
- Manifest: 534 rows, 459 Swift-owned, 75 explicit C adapters,
  fingerprint `0x811bcc7ceedc69c2`.

## Open gates

The 7,419 route shards are inventoried but not yet all executed as full
product traces. Whole-engine Swift authority, physical visual/performance/
thermal/device acceptance, release signing/notarization, audio/effect parity,
content/reference screenshot comparison, and human 120-star acceptance remain
open. Host frame-one evidence is not physical display or human acceptance.

## Next

Continue the remaining source-ordered C adapter families. Each slice must add a
pure value reducer, owner bridge, independent C oracle, dispatch identity,
manifest/live-trace coverage, and a focused plus full verifier rerun before it
is counted as Swift-owned.

## Architecture notes

- C remains the compatibility selector and differential oracle; Swift crosses
  only fixed-width value records and never traverses C object pointers.
- Mutable engine and Metal/AppKit state stays on its owning thread; bridge
  records are generation-fenced and transient effects are ordered through the
  owner-thread sink.
- The Metal 4 M34 two-pass rule remains: API/shader validation is separate from
  GPU capture because Apple's capture tooling rejects simultaneous shader
  validation.
- No branches, worktrees, commits, pushes, ROM-derived assets, or release
  artifacts were created by this handoff.
