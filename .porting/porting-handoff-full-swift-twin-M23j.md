# SM64 Modern Full Swift Twin — M23j Handoff

## Scope

M23j closes the live progression-boundary shadow seam. Non-mutation C
progression callbacks now load the normalized Swift image, commit the
canonical C snapshot at that owner-thread boundary, and append matching
before/after hashes when `SM64_MODERN_SAVE_REPLAY_ARTIFACT` is enabled. The
explicit `SM64_MODERN_SAVE_AUTHORITY_TRIAL=1` mode emits an owner-thread
diagnostic for that shadow commit without changing the restart-required engine
selector or claiming production save authority.

M23a–M23i remain in force: repaired normalized EEPROM, C-compatible mutators,
exact mutation payloads, authority-tagged operand-complete artifacts, fresh
image replay, corruption repair, persist/reload parity, and tamper rejection.

## Evidence

- `script/test_save_replay_artifact.sh` — operand-complete artifact
  `0x0ab6d5b2827a9435`; C-authored round trip `0xb7120f3045b8cbbb`.
- `script/test_save_replay_execution.sh` — fresh-image replay
  `0x23b4cdd9dd948b53`, corruption repair, mutation/persist/reload hash checks,
  and tamper rejection.
- `xcodegen generate` plus Swift 6 Debug `xcodebuild` —
  `/tmp/sm64-modern-m23j-build.log`, `BUILD SUCCEEDED`.
- Complete shebang-aware matrix —
  `/tmp/sm64-modern-m23j-final-matrix.log`, `runs=213 failures=0`.
- `rg -n '@unchecked[[:space:]]+Sendable' SM64Modern` — no matches.
- `git diff --check` — clean for the M23j patch.

## Remaining work

1. Capture and replay every live C corruption, recovery, copy/erase, mutation,
   reload, and commit branch on physical/runtime save paths in both directions.
2. Promote the Swift normalized adapter to production save authority only
   after all four slots, shared menu data, dirty/commit ordering, recovery, and
   restart-selector C compatibility prove byte-identical.
3. Continue M22: 453 reachable behavior rows remain explicit C adapters after
   M22bc.
4. Begin M24 configuration/cheats and continue M25–M35: HUD/front end, audio,
   rendering, input, filesystem/network, platform shell, lifecycle,
   performance, packaging, and physical/visual/human acceptance.

## Next command

Begin M24a with Swift/C configuration schema, defaults, invalid-value recovery,
and restart-required authority selection. Keep all M23 artifacts and the 213
script matrix green; preserve project regeneration and unrelated working-tree
edits.
