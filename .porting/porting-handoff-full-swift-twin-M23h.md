# SM64 Modern Full Swift Twin — M23h Handoff

## Scope

M23h closes the restart-selector metadata and durable save-replay artifact
boundary without switching production save authority. `SM64SaveReplayArtifact`
is a fixed-width, little-endian file with canonical header, record, and
artifact hashes. Its header records Swift/C authority and restart metadata;
records carry C-to-Swift or Swift-to-C direction, operation, slot and mutation
operands, recovery decisions, before/after save/menu hashes, and whole-image
hashes. The migration service appends initialize, mutation, persist, load,
reload, and recovery boundaries only when
`SM64_MODERN_SAVE_REPLAY_ARTIFACT` is explicitly set, avoiding normal-play
per-frame filesystem writes. The selector now exposes a tested restart
decision seam, and the artifact can be verified by C and read back by Swift.

This remains shadow parity. Persisted artifacts are not yet replayed through
every live corruption branch, and Swift is not yet the production save
authority.

## Evidence

- `script/test_save_replay_artifact.sh` — Swift artifact fingerprint
  `0x4a47663d9439c6cc`; independent C verification and C-authored artifact
  round trip `0xb07a9ba133b53d34`.
- `script/test_engine_authority.sh` — selector precedence, invalid-value
  handling, and restart-required decision contract.
- `xcodegen generate` plus Swift 6 Debug `xcodebuild` —
  `/tmp/sm64-modern-m23h-build.log`, `BUILD SUCCEEDED`.
- Complete shebang-aware matrix —
  `/tmp/sm64-modern-m23h-final-matrix.log`, `runs=212 failures=0`.
- `rg -n '@unchecked[[:space:]]+Sendable' SM64Modern` — no matches.
- `git diff --check` — clean for the M23h patch.

## Remaining work

1. Replay persisted artifacts through every live C corruption, recovery,
   mutation, copy/erase, reload, and commit branch in both directions, with
   terminal tamper and truncation rejection.
2. Promote the Swift normalized adapter to production save authority only
   after dirty/commit ordering, all four slots, shared menu data, recovery, and
   restart-selector C compatibility prove byte-identical.
3. Continue M22: 453 reachable behavior rows remain explicit C adapters after
   M22bc.
4. Continue M24–M35: configuration, HUD/front end, audio, rendering, input,
   filesystem/network, platform shell, lifecycle, performance, packaging,
   and physical/visual/human acceptance.

## Next command

Begin M23i with persisted-artifact replay across corruption/recovery and
bidirectional Swift↔C commit verification. Keep the opt-in artifact path,
normalized adapter, independent C contract, 212-script matrix, project
regeneration, and unrelated working-tree edits intact.
