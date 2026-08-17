# Full Swift Twin — M31r Handoff

## Outcome

The camera FOV graph callback now evaluates through Swift on the engine
owner thread. The fixed-width ABI carries the selected FOV function, current
FOV/shake state, sleeping state, and fixed/cutscene context. Swift applies the
existing value kernel and returns the updated state plus presented FOV. C
continues to own the `GraphNodePerspective` pointer, the legacy sleeping flag,
and the exact unused-cutscene reset side effect.

## Owned changes

- `include/sm64_modern.h` adds FOV input/output POD and the optional camera
  FOV callback.
- `src/pc/sm64_modern_camera_migration.c` validates and dispatches finite FOV
  state through the owner-thread migration service.
- `SM64Modern/CameraMigration.swift` maps the callback to
  `SM64CameraFOV.update` and returns the canonical presentation value.
- `src/game/camera.c` snapshots FOV state from `geo_camera_fov`, installs Swift
  state, and preserves C-only perspective/sleeping compatibility.
- `tests/sm64_modern_camera_migration_smoke.c` adds an independent ABI FOV
  callback check.

## Validation evidence

- `./script/test_camera_cutscene_fov.sh` —
  `cameraCutsceneFOVFingerprint=0x0fa052c32482bd3a`; Swift/C contract match.
- `./script/test_camera_migration.sh` —
  `cameraMigrationFingerprint=0x9e3779b97f4a7d11`, including the FOV callback.
- Camera geometry, callback, mode-state, runtime, and `make -j2 abi-smoke`
  gates pass.
- Regenerated Swift 6/macOS 27 Debug build succeeds in
  `/tmp/sm64-modern-camera-fov-build.log`.
- Signed Apple M5 Max launch `/tmp/sm64-modern-m31r-live.log` reports
  `swift_camera_fov mode=2`, Metal 4 frame one, 360 fixed steps, zero
  scheduler/audio drops, `engine_thread_finished status=0`, and clean app
  shutdown.

## Boundary and next work

This closes the FOV/shake value route only. It does not prove screenshot or
visual parity, cutscene timing, physical camera feel, or human acceptance.
Continue with the remaining stateful camera families (parallel/fixed/boss/
spiral/water and cutscene graph), then promote audio, frontend, and rendering
authority before full route-shard execution and production gates.

