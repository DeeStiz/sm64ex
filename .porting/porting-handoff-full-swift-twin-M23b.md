# SM64 Modern Full Swift Twin — M23b Handoff

## Scope

M23b adds the pure Swift save-file query surface behind the existing C
compatible codecs. `SM64SaveFileQueries` preserves file-existence checks,
secret-star and course-star indexing, cannon-byte indexing, course and total
star counts, cap-on-ground position gating, course coin-score reads, and the
`save_file_get_max_coin_score` age tie-break and packed result. It is a
read-only `Sendable` value API; no query reaches C globals or persistence I/O.

M23a's atomic recovery repair and legacy 176-byte image upgrade remain the
durable boundary. Save mutators, options, restart-selector parity, and full
bidirectional authority replay are still open.

## Evidence

- `script/test_save_file_queries.sh` — Swift/C query fingerprint
  `0x5562efafd48db61c`; all four slots, secret/course/cannon flags, counts,
  cap gating, and age-based maximum-score tie breaks match.
- `script/test_progression_eeprom.sh` — M23a recovery/upgrade regression
  remains green with Swift/C fingerprint `0x3fac91b6c0a1f3cd`.
- `script/test_progression_persistence.sh` — legacy bundle and progression
  route regression remains green with fingerprint `0x40957bb3fcb92681`.
- `xcodegen generate` followed by isolated Swift 6 Debug `xcodebuild` —
  `/tmp/sm64-modern-m23a-build.log`, `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m23a-final-matrix.log` — all 206 script indices passed
  using each script's declared interpreter.
- Strict-concurrency audit — zero `@unchecked Sendable` declarations in
  `SM64Modern`; `git diff --check` is clean.

## Remaining work

1. Port save mutators with exact source order: erase/copy, flag set/clear,
   star/cannon writes, cap movement/default relocation, sound mode, and
   save-boundary dirty-bit behavior.
2. Add full Swift-to-C-to-Swift and C-to-Swift-to-C save-image replay traces,
   including corruption, backup repair, and restart-required selector choice.
3. Continue M22 behavior coverage: 453 reachable behavior rows remain
   explicit C adapters after M22bc.
4. Continue M24–M35 configuration, HUD/front-end, audio, rendering,
   whole-engine authority, parity shards, Metal 4 production, distribution,
   and human acceptance.

## Next command

Inventory `save_file_erase`, `save_file_copy`, flag/star/cannon writes, cap
relocation, and sound-mode persistence against the current Swift runtime.
Choose one mutation family, add a value reducer and owner-thread persistence
operation, then rerun its independent C contract, progression regressions,
native Swift 6 build, shebang-aware matrix, strict audit, and handoff checks.
