# SM64 Modern Full Swift Twin — M31y Handoff

## Milestone

M31y — Swift audio sequence/queue observer seam.

## Outcome

The owner-thread C audio boundary now emits fixed-width tick, sequence, queue,
and secondary-sequence events through `SM64ModernAudioMigrationApiV1`. Swift
installs an owner-token-checked observer, replays the six-entry background
queue/player sequence state as value data, rejects malformed events, and
maintains a stable boundary fingerprint. The C sequence player, synthesis,
PCM production, AVAudio service, and audible/device path remain the explicit
compatibility authority.

## Validation

- `script/test_audio_migration.sh` — Swift/C contract matched at
  `0x175790b07cad64f`.
- `script/test_audio_sequence.sh` — existing sequence contract matched at
  `0xae744ed9ffb34142`.
- `script/test_audio_promotion.sh` — existing promotion contract matched at
  `0xad10b198c66b2a49`.
- `script/test_engine_runtime.sh` — pass.
- `script/test_camera_migration.sh` — pass.
- `./script/build_native_core.sh Debug` — pass; native ABI/timebase/cadence/
  oracle smoke set passed.
- `xcodegen generate && xcodebuild -project SM64Modern.xcodeproj -scheme
  SM64Modern -configuration Debug -destination 'platform=macOS' build` —
  pass in `/tmp/sm64-modern-audio-migration-build.log`.
- `git diff --check` — pass.

## Runtime evidence

`/tmp/sm64-modern-m31y-runtime.log` is a signed Apple M5 Max run. It reports
Metal 4 device/frame-one presentation, `audio_sequence_bridge_installed
authority=swift pcm_authority=c`, the first Swift observer event, 140 observed
events over 132 ticks, queue size 2, observer fingerprint
`16486630640083679715`, and status-0/application-stopped shutdown.

This run does not prove audible parity, physical listening, controller feel,
visual parity, or human acceptance. It also does not claim Swift ownership of
PCM synthesis or AVAudio hardware delivery.

## Files

- `include/sm64_modern.h`
- `src/pc/sm64_modern_audio_migration.c`
- `src/pc/sm64_modern_audio_migration.h`
- `src/pc/sm64_modern_gameplay_parity.c`
- `src/pc/sm64_modern_gameplay_parity.h`
- `SM64Modern/AudioMigration.swift`
- `SM64Modern/EngineHost.swift`
- `tests/sm64_modern_audio_migration_smoke.c`
- `tests/sm64_modern_audio_migration_smoke.swift`
- `script/test_audio_migration.sh`
- `script/build_and_run.sh`

## Next milestone

M31z should close the frontend/menu ownership boundary. Keep audio as an
explicit C/device bridge until a later slice can replace sequence-player
mutation and PCM production with matched Swift synthesis and an audible
physical-device gate.
