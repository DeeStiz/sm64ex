# Full Swift Twin M31j Handoff

## Scope

M31j promotes the save-persistence domain from a shadow mirror to a real
Swift-owned durable boundary. The C game still consumes its normalized
in-memory `SaveBuffer` for compatibility gameplay, but C no longer reads or
writes the durable EEPROM/text-save image while the Swift authority is active.

## Implementation

- Added an owner-thread persistence-authority flag to the progression migration
  ABI, reset on install/uninstall and explicitly enabled by `EngineHost` after
  the Swift progression service is installed.
- Added a checked little-endian C snapshot writer that validates magic/checksum
  bytes, reconstructs both save backups and both menu backups, and fences
  malformed input before mutating the compatibility buffer.
- Routed Swift-authority load and reload events through the Swift persistence
  adapter. Startup recovery loads all four slots, repairs the Swift image when
  needed, and admits normalized snapshots into C; game-over reload restores the
  selected Swift backup without entering C durable I/O.
- Guarded C EEPROM/text-save writes in `save_file_do_save` and
  `save_main_menu_data`; C still updates its in-memory backup and the Swift
  migration callback commits the canonical Swift image.
- Added explicit telemetry for the disabled C durable boundary and the Swift
  snapshot admission/commit, and made `savePersistence` Swift-owned in the
  fail-closed authority ledger.

## Validation evidence

- `script/test_progression_migration.sh` passes, including persistence flag
  enable/disable/reset behavior.
- `script/test_progression_persistence.sh` passes with the existing independent
  Swift/C recovery fingerprint `0x40957bb3fcb92681`.
- `script/test_engine_runtime.sh` passes under Swift 6 complete strict
  concurrency with save persistence owned by Swift and only audio, camera,
  frontend, and rendering left as C compatibility bridges.
- Regenerated native arm64 Debug build succeeds at
  `/tmp/sm64-modern-m31j-build-2.log`.
- Native Apple M5 Max Metal 4 launch evidence was captured with a fresh save
  root in `/tmp/sm64-modern-m31j-live-save.CNEKJa`: telemetry reports
  `persistence_authority=swift`, startup `operation=5` reports
  `c_durable_io=disabled`, the normalized C snapshot is admitted, a real
  CAMetalLayer presents frame 1, and shutdown ends with audio/Metal drained,
  `engine_thread_finished status=0`, and `application_stopped`.
- `git diff --check` passes for the focused slice.

## Evidence boundary

This closes durable save ownership, not the whole save/gameplay implementation:
C still owns the compatibility `SaveBuffer` mutations and callback path, and
the native probe exercised startup load rather than a human save-menu session.
It does not prove full route-shard coverage, audio/rendering/camera/frontend
authority, visual/audio parity, physical devices, distribution, or human
acceptance.

## Next slice

Promote the next complete product domain only after its owner-thread value
route, live C schema-4 replay, and native integration are proven. The bounded
audio graph is the next strongest candidate, but it must replace the
hardware-facing C PCM path or explicitly remain a promotion envelope until
audible/device evidence exists.
