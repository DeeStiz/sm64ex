# SM64 Modern Full Swift Twin — M31z Handoff

## Milestone

M31z — Swift front-end/menu observer seam.

## Outcome

The C input path now emits the exact owner-thread menu edges, activity state,
and selection delta it already samples for the legacy frontend through
`SM64ModernFrontEndMigrationApiV1`. Swift installs an owner-token-checked,
strict Swift 6 observer and replays the title, file-select, course-select,
level-select, demo, gameplay, credits, and ending reducer as value state. C
remains the compatibility authority for live menu globals, save-slot
mutation, transition side effects, text/layout rendering, and screen
presentation. An uninstalled observer is a no-op, so the C selector remains
safe.

## Validation

- `script/test_frontend_migration.sh` — Swift/C contract matched at
  `0x147b4bc7da0386a1`; six input events and three reducer transitions pass,
  including malformed-reserved-field fencing.
- `script/test_front_end.sh` — existing front-end reducer contract passed at
  `0x82b90492a9f11a54`.
- `script/test_front_end_render.sh` — existing front-end render contract
  passed at `0x5a7bf7982d12f694`.
- `script/test_dialog_text_pause.sh` — existing dialog/pause contract passed
  at `0x382a78484379f6f7`.
- `script/test_engine_runtime.sh`, `script/test_camera_migration.sh`, and
  `script/test_audio_migration.sh` — pass.
- `./script/build_native_core.sh Debug` — pass; the native ABI/timebase/
  cadence/oracle smoke set passed and includes
  `sm64_modern_frontend_migration.o`.
- `xcodegen generate && xcodebuild -project SM64Modern.xcodeproj -scheme
  SM64Modern -configuration Debug -sdk macosx build` — `BUILD SUCCEEDED` in
  `/tmp/sm64-modern-m31z-xcodebuild.log`.
- `SM64_MODERN_AUDIO_PROMOTION=1 ./script/build_and_run.sh verify` — pass;
  the verifier includes the new frontend contract and runtime telemetry.
- `git diff --check` — pass before handoff.

## Runtime evidence

`/tmp/sm64-modern-m31z-runtime.log` is a signed Apple M5 Max run. It reports
`frontend_bridge_installed abi=1 authority=swift state_authority=c
render_authority=c`, `swift_frontend_observer screen=0 tick=1`, Metal 4
frame-one presentation, 250 observed input events, observer fingerprint
`9030239786378800966`, `swift_frontend_observer_finished`, and status-0
engine/application shutdown.

This proves an owner-thread input/state observer and normal startup/render/
shutdown. It does not prove authored menu route breadth, save-session parity,
screen/render parity, controller feel, physical controls, visual review,
audible parity, or human acceptance. Swift does not own the live C menu state
or screen presentation yet.

## Files

- `include/sm64_modern.h`
- `src/pc/sm64_modern_frontend_migration.c`
- `src/pc/sm64_modern_frontend_migration.h`
- `SM64Modern/FrontEndMigration.swift`
- `SM64Modern/AppleInputService.swift`
- `SM64Modern/EngineHost.swift`
- `tests/sm64_modern_frontend_migration_smoke.c`
- `tests/sm64_modern_frontend_migration_smoke.swift`
- `script/test_frontend_migration.sh`
- `script/build_and_run.sh`

## Next

M31aa should close the pause/menu value boundary from a clean C menu call site,
or explicitly qualify the frontend observer across title, file, course,
level, pause, dialog, credits, ending, save mutation, and restart shards.
Only after those traces match should any frontend state or render authority
move to Swift; M33 route breadth, M34 physical Metal 4 acceptance, and M35
release/human gates remain open.
