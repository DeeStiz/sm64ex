# SM64 Modern Full Swift Twin — M23e Handoff

## Scope

M23e integrates the pure `SM64SaveFileMutator` value kernel into
`SM64ProgressionRuntime`. The owner-thread runtime now exposes C-order flag,
star, cannon, cap-position, cap-relocation, and sound-mode boundaries. Each
boundary accepts the legacy-domain admission decision, makes a paused call a
strict no-op, marks the appropriate save/menu dirty state after an admitted
call even when bytes are unchanged, and leaves durable replacement to
`commitIfNeeded`. Persisted flag bits also restore the runtime cap-location
enum on load/reload.

M23a recovery/legacy upgrade, M23b queries, M23c owner-thread copy/erase, and
M23d pure value mutation parity remain active. The runtime still uses the
legacy single-bundle adapter for this bounded dirty/commit proof; normalized
EEPROM owner wiring, restart selector authority, and full save replay remain
separate gates.

## Evidence

- `script/test_progression_save_mutation_runtime.sh` — Swift/C runtime
  fingerprint `0x837f4055094f2508`; paused no-op admission, dirty-bit order,
  cap-location propagation, atomic commit clearing, and encoded save/menu
  bytes agree.
- `script/test_progression_runtime.sh` — existing runtime fingerprint
  `0x882867d4029082ed` remains green after the shared source-list update.
- `script/test_save_file_mutator.sh` — M23d value fingerprint
  `0x1aa5cef94856d8be` remains green.
- `script/test_progression_mutations.sh` — M23c owner-thread fingerprint
  `0x33186d5894562d7b` remains green.
- `script/test_progression_eeprom.sh` — M23a fingerprint
  `0x3fac91b6c0a1f3cd` remains green.
- `script/test_progression_persistence.sh` — route fingerprint
  `0x40957bb3fcb92681` remains green.
- `script/test_save_file_queries.sh` — M23b fingerprint
  `0x5562efafd48db61c` remains green.
- `xcodegen generate` plus isolated Swift 6 Debug `xcodebuild` —
  `/tmp/sm64-modern-m23e-build.log`, `BUILD SUCCEEDED`.
- Complete shebang-aware matrix —
  `/tmp/sm64-modern-m23e-final-matrix-rerun.log`, `runs=210 failures=0`.
- `rg -n '@unchecked[[:space:]]+Sendable' SM64Modern` — no matches.
- `git diff --check` — clean for the M23e patch.

## Remaining work

1. Route the production progression migration service and normalized EEPROM
   adapter through these runtime mutation boundaries without bypassing dirty,
   timebase, or owner-thread checks.
2. Add Swift-to-C-to-Swift and C-to-Swift-to-C replay traces for every save
   mutation, restart-required selector, and corruption branch.
3. Continue M22 behavior coverage: 453 reachable behavior rows remain
   explicit C adapters after M22bc.
4. Continue M24–M35 configuration, HUD/front-end, audio, rendering,
   whole-engine authority, parity shards, Metal 4 production, distribution,
   and physical/visual/human acceptance.

## Next command

Begin the next bounded M23 slice by connecting the migration service's C save
events to this runtime/normalized-image boundary. Preserve the independent C
contract, regenerate the project after source changes, rerun the 210-script
matrix, and keep unrelated native gameplay/menu edits out of the commit.
