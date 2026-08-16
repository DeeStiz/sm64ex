# SM64 Modern Full Swift Twin — M24c Handoff

## Scope

M24c closes the persistence/authority half of the configuration boundary while
leaving live cheat consumers and full Swift engine authority explicitly open.
`SM64ModernConfigurationRuntime` now recognizes a version-independent
`sm64-modern-config.swift.txt` sidecar beside the C-compatible
`sm64-modern-config.txt`. Legacy window/audio/binding/skip-intro values remain
primary; the sidecar restores Swift-only camera, HUD, Discord, language,
legal-ROM, precache, and cheat values after C's `configfile_save` rewrites the
legacy file. Existing modern keys in a primary file seed the sidecar once, and
malformed sidecar values recover through the same fail-closed parser.

`SM64ModernEngineAuthorityStore` now has an injected-`UserDefaults` resolver,
so restart-required authority selection can be tested without mutating the
process-wide defaults domain. The existing AppDelegate selector remains
immutable for the process, persists menu changes, reports restart-required
state, repairs invalid persisted values to Swift, and terminates visibly for an
invalid `SM64_MODERN_ENGINE` environment override.

## Evidence

- `script/test_configuration_runtime.sh` — sidecar creation from a rich modern
  file, preservation of optional values after a simulated C legacy rewrite,
  malformed recovery, missing/valid-file behavior, and invalid UTF-8 fail-closed
  behavior. Fingerprint remains `0x1b0a9226b4babc19`.
- `script/test_engine_authority.sh` — default, persisted C, environment
  override, invalid environment, invalid persisted recovery, injected
  UserDefaults persistence, and restart comparison all pass.
- `xcodegen generate --spec project.yml` plus native Swift 6 Debug build —
  `/tmp/sm64-modern-m24c-build.log`, `BUILD SUCCEEDED`.
- `script/build_and_run.sh --verify` —
  `/tmp/sm64-modern-m24c-verify.log`: Apple M5 Max `Metal4` device,
  display-link and lifecycle startup, frame-one presentation, audio/input
  startup, and clean `engine_thread_finished status=0` /
  `application_stopped`.
- Complete shebang-aware `script/test_*.sh` matrix — `runs=215 failures=0`,
  with per-script logs under `/tmp/sm64-modern-m24c-matrix`.
- `rg -n '@unchecked[[:space:]]+Sendable' SM64Modern` is empty and
  `git diff --check` passes.

## Key decisions

- The sidecar is deliberately separate from the C file. C accepts unknown keys
  while loading but rewrites only its own option table at shutdown; a shared
  file would therefore silently lose Swift-only state.
- The primary file is never overwritten by sidecar legacy fields. This avoids
  replaying stale window/audio/binding changes over a C menu edit.
- Authority selection is a launch contract, not a live engine mutation. A
  persisted value can be repaired; an invalid environment override is a hard
  launch failure with a visible error.
- Sidecar writes use atomic replacement per file. A future transactional
  settings commit should add a generation/checksum across both files before
  claiming crash-consistent multi-file updates.

## Remaining work

1. M24d: expose all nine cheat toggles to live Swift consumers with explicit
   owner-thread/value boundaries, C compatibility behavior, and independent
   enable/disable evidence. Parsing and persistence alone are not cheat
   execution.
2. M22 still has 453 explicit `unmigrated_c_adapter` rows; all require live
   Swift migration or an approved compatibility exception before behavior
   coverage closes.
3. M25–M31 remain open for HUD/front-end, audio sequencing and synthesis,
   display-list translation, Goddard, and whole-engine Swift authority.
   M32–M35 remain separate strict-concurrency, qualification, Metal 4
   production, distribution, physical, thermal, controller/keyboard, audio,
   visual, and human-acceptance gates.

## Next command

Begin M24d on the owner thread: wire parsed cheat state into explicit Swift
consumer seams, prove each toggle against C compatibility behavior, and keep
the launch selector/restart contract unchanged. Preserve all M24a–M24c
fingerprints, the 215-script matrix, generated project state, and unrelated
working-tree edits.
