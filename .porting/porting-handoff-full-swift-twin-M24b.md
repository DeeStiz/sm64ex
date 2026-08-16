# SM64 Modern Full Swift Twin — M24b Handoff

## Scope

M24b makes the M24a configuration schema a real owner-thread runtime boundary.
`EngineHost` loads `sm64-modern-config.txt` after resolving the save directory
and before the C lifecycle starts. UTF-8 failures fail closed; malformed and
out-of-range values recover to documented defaults, repaired legacy text is
written with an atomic replacement, and unknown keys/malformed line numbers are
logged. The lifecycle receives the Swift `fullscreen` and `skip_intro` values;
C remains the compatibility consumer for the rest of the settings.

The progression startup seam is corrected at the same boundary. The C snapshot
normalizer intentionally synthesizes a checksum from fields, so its pre-
lifecycle zeroed buffer must not be treated as durable state. The migration
service now seeds from the durable Swift EEPROM image and waits for C's real
save-load/recovery callbacks to reconcile the shadow. This preserves wiped
coin-score ages on a genuinely empty save and removes the fresh-save
`mutation_payload_replay` parity failure.

## Evidence

- `script/test_configuration_runtime.sh` — Swift 6 strict-concurrency runtime
  smoke, including missing-file defaults, valid-file no-op, atomic recovery,
  second-load cleanliness, unknown/malformed diagnostics, and invalid UTF-8
  fail-closed behavior. Fingerprint: `0x1b0a9226b4babc19`.
- Focused regression sequence — configuration runtime, save replay artifact,
  C-authored artifact round trip, fresh-image replay execution, and engine
  runtime all pass. Existing fingerprints remain `0x0ab6d5b2827a9435`,
  `0xb7120f3045b8cbbb`, and `0x23b4cdd9dd948b53`.
- `script/build_and_run.sh --verify` —
  `/tmp/sm64-modern-m24b-verify-fixed.log`, regenerated native Debug build
  (`BUILD SUCCEEDED`), Apple M5 Max `Metal4` device, display-link ownership,
  lifecycle start, frame 1 presentation, audio/input startup, and clean
  `engine_thread_finished status=0` / `application_stopped`.
- Fresh-save integration — a brand-new save directory
  `/tmp/sm64-modern-m24b-fresh-fixed-28800-7418` launched through the native
  app with `progression_bridge_installed`, `lifecycle_running`, and clean
  `engine_thread_finished status=0` (process 91784; unified-log query).
- Invalid-config integration — `/tmp/sm64-modern-m24b-invalid-save2` was
  launched with `fullscreen maybe`, `master_volume 200`, and an unknown
  `malformed_only` line. The owner thread logged
  `configuration_repaired keys=fullscreen,master_volume malformed_lines=29
  persisted=true`, logged the unknown key, reached `lifecycle_running`, and
  exited with status 0 (process 15450). The persisted file is clean on the
  following read.
- Complete shebang-aware `script/test_*.sh` matrix — `runs=215 failures=0`,
  with per-script logs retained under `/tmp/sm64-modern-m24b-matrix`.
- `xcodegen generate --spec project.yml` keeps the generated Xcode project in
  sync; `rg -n '@unchecked[[:space:]]+Sendable' SM64Modern` is empty; and
  `git diff --check` passes.

## Key decisions

- Configuration file I/O is owner-thread-only and occurs before lifecycle
  callbacks, so no AppKit or mutable configuration state crosses queues.
- Repaired files currently use the legacy C serialization as the durable
  compatibility form. Swift-only product keys are parsed but are not yet
  persisted through a sidecar, so they are intentionally not claimed as live
  authority.
- The restart selector remains immutable for the process. M24b projects only
  lifecycle-safe values and does not add a live authority switch.
- The parity mismatch logger records file/kind/operation and save/menu hashes
  only on a failed payload comparison, preserving a fail-closed status while
  making future migration failures diagnosable.

## Remaining work

1. M24c: add a versioned Swift sidecar or equivalent lossless persistence for
   optional keys, wire UserDefaults/menu authority selection to the existing
   restart-required selector, and make invalid persisted/environment choices
   fail closed with a visible status.
2. M24d: route all nine cheat toggles through a value-only Swift boundary and
   add consumer-by-consumer compatibility evidence without changing C
   behavior outside the selected authority.
3. M22 still has 453 explicit `unmigrated_c_adapter` rows; all require live
   Swift migration or an approved compatibility exception before behavior
   coverage can close.
4. M25–M31 remain open for HUD/front-end, audio sequencing and synthesis,
   display-list translation, Goddard, and whole-engine Swift authority.
   M32 strict-concurrency safety, M33 qualification, and M34 Metal 4
   production gates remain separate milestones; source/build evidence is not
   physical visual, controller/keyboard, audio, thermal, store, or human
   acceptance.

## Next command

Begin M24c on the engine owner thread. Preserve the M24a fingerprints, the
M24b runtime fingerprint and fresh-save fix, the 215-script matrix, generated
project state, and unrelated working-tree edits. Do not claim full Swift
authority until optional settings, restart selection, cheats, all behavior
adapters, and the later physical/release gates are independently evidenced.
