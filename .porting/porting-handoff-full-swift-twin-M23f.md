# SM64 Modern Full Swift Twin — M23f Handoff

## Scope

M23f adds normalized-image mutation replay to
`SM64OwnerThreadEEPROMAdapter`. `apply` repairs every save/menu pair before an
admitted mutation, runs the Swift value kernel for flags, stars, cannons,
lost-cap position/relocation, or sound mode, preserves shared menu ages and
filler, writes both copies atomically, and returns a fail-closed error for an
invalid mutation such as moving a cap that is not on the ground. Paused
legacy-domain calls return unchanged values with `didMutate == false`.

`SM64ProgressionRuntime` now has a normalized-adapter `commitIfNeeded`
overload, and its menu snapshot retains filler bytes across load/commit. M23a
through M23e remain active. This is a complete normalized mutation/replay
boundary, but the C migration callback still reports post-mutation snapshots
as a shadow stream; it has not yet switched production save authority to the
Swift adapter.

## Evidence

- `script/test_normalized_save_mutation_replay.sh` — Swift/C replay
  fingerprint `0x12990736c21cd899`; every encoded mutation step, paused no-op,
  invalid branch, menu filler, primary/backup equality, and normalized runtime
  commit agrees.
- `script/test_progression_save_mutation_runtime.sh` — M23e runtime admission
  fingerprint `0x837f4055094f2508` remains green.
- `script/test_save_file_mutator.sh` — M23d value fingerprint
  `0x1aa5cef94856d8be` remains green.
- `script/test_progression_mutations.sh` — M23c fingerprint
  `0x33186d5894562d7b` remains green.
- `script/test_progression_eeprom.sh` — M23a fingerprint
  `0x3fac91b6c0a1f3cd` remains green.
- `script/test_progression_persistence.sh` — route fingerprint
  `0x40957bb3fcb92681` remains green.
- `xcodegen generate` plus isolated Swift 6 Debug `xcodebuild` —
  `/tmp/sm64-modern-m23f-build.log`, `BUILD SUCCEEDED`.
- Complete shebang-aware matrix —
  `/tmp/sm64-modern-m23f-final-matrix.log`, `runs=211 failures=0`.
- `rg -n '@unchecked[[:space:]]+Sendable' SM64Modern` — no matches.
- `git diff --check` — clean for the M23f patch.

## Remaining work

1. Translate the C migration event callback from post-mutation shadow reads to
   Swift-owned normalized mutation operations with explicit source/destination
   and restart-selector contracts.
2. Add persistent bidirectional C-to-Swift-to-C and Swift-to-C-to-Swift replay
   files for every save operation and corruption/recovery path.
3. Continue M22 behavior coverage: 453 reachable behavior rows remain
   explicit C adapters after M22bc.
4. Continue M24–M35 configuration, HUD/front-end, audio, rendering,
   whole-engine authority, parity shards, Metal 4 production, distribution,
   and physical/visual/human acceptance.

## Next command

Begin M23g by specifying the migration callback's mutation payload and
restart-selector contract. Keep the normalized adapter as the only durable
Swift write boundary, retain independent C replay, regenerate the project
after source changes, rerun the 211-script matrix, and preserve unrelated
native gameplay/menu edits.
