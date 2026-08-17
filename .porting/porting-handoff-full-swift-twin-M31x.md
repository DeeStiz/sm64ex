# M31x Handoff — Swift Cutscene Clock and Spline Authority Seam

## State

M31x is complete locally. Cutscene spline point evaluation and shot-clock
advancement now run through fixed-width owner-thread callbacks when Swift
camera authority is active. C still owns authored cutscene dispatch and all
side effects.

## Implementation

- `SM64Modern/CameraCutscene.swift` provides the value-only cubic spline and
  cutscene clock kernels.
- `SM64Modern/CameraMigration.swift` exposes Swift 6 owner-thread callbacks
  for four-point spline snapshots and shot/timer snapshots.
- `include/sm64_modern.h` adds fixed-width spline/clock records and optional
  migration function pointers; `src/pc/sm64_modern_camera_migration.c` validates
  and fences both directions.
- `src/game/camera.c` snapshots the current spline segment in
  `move_point_along_spline` and routes `play_cutscene` timer/shot advancement
  through Swift with C fallback when unavailable.
- `tests/sm64_modern_camera_migration_smoke.c` exercises both new callbacks;
  the existing standalone cutscene/FOV contract remains unchanged.

## Evidence

- `./script/test_camera_cutscene_fov.sh` — pass,
  `cameraCutsceneFOVFingerprint=0x0fa052c32482bd3a`.
- `./script/test_camera_migration.sh` — pass; migration smoke exercises the
  spline and clock callback records.
- Camera primitive/geometry/mode/state/runtime smokes — pass.
- `make -j2 abi-smoke` — pass; native C core rebuilt with cutscene routing.
- Swift 6/macOS 27 Debug build — pass:
  `/tmp/sm64-modern-camera-cutscene-build.log`.
- Signed Apple M5 Max launch — pass:
  `/tmp/sm64-modern-m31x-live.log`; Metal 4 device ready, frame one
  presented, 360 fixed steps, zero scheduler/audio drops, status-0 shutdown.

## Boundary

The bounded startup route does not enter an authored cutscene, so the signed
launch proves startup/render/scheduler/shutdown only. It does not prove live
cutscene spline/clock telemetry, authored shot visual parity, object/audio
event ordering, physical camera feel, or human acceptance. C still owns shot
table selection, event callbacks, object/audio effects, cutscene camera graph
pointers, and the human-visible presentation path.

## Next

Use the new seam to qualify authored cutscene route shards and capture
schema-4 camera traces, then close remaining frontend/audio authority before
the M33 full-game replay and physical Metal 4 gates.
