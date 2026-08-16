# SM64 Modern Full Swift Twin — M23i Handoff

## Scope

M23i makes the M23h save replay artifact executable. Each fixed-width record
now serializes flags, course/star, cap level/area/coordinates, sound mode,
source slot, mutation operation, and recovery decisions, in addition to
before/after save/menu and whole-image hashes. A fresh normalized EEPROM image
replays flags, stars, cap coordinates, one-bad-copy repair, persist, and reload
records; each before/after hash must match. A tampered record is rejected before
any write. Authority and restart metadata remain in the artifact header, and
normal application capture remains opt-in through
`SM64_MODERN_SAVE_REPLAY_ARTIFACT`.

This is still shadow parity. The live app has not yet captured every corruption
branch into a production artifact, and Swift is not yet the production save
authority.

## Evidence

- `script/test_save_replay_artifact.sh` — operand-complete Swift artifact
  fingerprint `0x0ab6d5b2827a9435`; independent C verification and C-authored
  artifact round trip `0xb7120f3045b8cbbb`.
- `script/test_save_replay_execution.sh` — fresh-image corruption/mutation/
  persist/reload replay fingerprint `0x23b4cdd9dd948b53`, exact hash checks,
  and tamper rejection.
- `xcodegen generate` plus Swift 6 Debug `xcodebuild` —
  `/tmp/sm64-modern-m23i-build.log`, `BUILD SUCCEEDED`.
- Complete shebang-aware matrix —
  `/tmp/sm64-modern-m23i-final-matrix.log`, `runs=213 failures=0`.
- `rg -n '@unchecked[[:space:]]+Sendable' SM64Modern` — no matches.
- `git diff --check` — clean for the M23i patch.

## Remaining work

1. Capture every live C corruption, recovery, copy/erase, mutation, reload, and
   commit branch into opt-in artifacts and replay them in both directions.
2. Promote the Swift normalized adapter to production save authority only
   after all four slots, shared menu data, dirty/commit ordering, recovery, and
   restart-selector C compatibility prove byte-identical.
3. Continue M22: 453 reachable behavior rows remain explicit C adapters after
   M22bc.
4. Continue M24–M35: configuration, HUD/front end, audio, rendering, input,
   filesystem/network, platform shell, lifecycle, performance, packaging,
   and physical/visual/human acceptance.

## Next command

Begin M23j with live artifact capture for every C save boundary and a
bidirectional Swift-authority trial behind the restart-required selector.
Preserve the operand-complete artifact schema, normalized adapter, independent
C contract, 213-script matrix, project regeneration, and unrelated working-tree
edits.
