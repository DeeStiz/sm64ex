# M31w Handoff — Swift Water-Surface Transition No-Op

## State

M31w is complete locally. The water-surface transition entry (camera mode 8)
now has an explicit Swift value contract. The normal per-frame water-surface
camera remains the mode-3 behind-Mario route, with C retaining water and
collision policy.

## Implementation

- `SM64Modern/CameraWater.swift` owns the finite no-op transition result,
  preserving focus/position and returning the current relative yaw.
- `SM64Modern/CameraModeCallbacks.swift` marks mode 8 implemented and routes
  it through the no-op kernel.
- `src/game/camera.c` routes `nop_update_water_camera` through the Swift
  evaluator, computes the transition yaw from the supplied endpoints, and
  returns a safe C fallback of zero when Swift authority is unavailable.
- `SM64Modern.xcodeproj/project.pbxproj` includes the new Swift source.
- The callback contract smoke covers descriptor parity and no-op preservation.

## Evidence

- `./script/test_camera_primitives.sh` — pass,
  `cameraPrimitivesFingerprint=0xe71dca12bbf8bb32`.
- `./script/test_camera_geometry.sh` — pass,
  `cameraGeometryFingerprint=0x9bc38f9c51aae152`.
- `./script/test_camera_mode_callbacks.sh` — pass,
  `cameraModeCallbacksFingerprint=0x91fabbcd699cb58b`; Swift/C contract
  matched, including the water no-op.
- `./script/test_camera_migration.sh` — pass,
  `cameraMigrationFingerprint=0x9e3779b97f4a7d11`.
- `./script/test_camera_mode_state.sh` — pass,
  `cameraModeStateFingerprint=0x80ec629967e739dc`.
- `./script/test_engine_runtime.sh` — pass.
- `make -j2 abi-smoke` — pass; native C core rebuilt with the water callback
  path.
- Swift 6/macOS 27 Debug build — pass:
  `/tmp/sm64-modern-camera-water-build.log`.
- Signed Apple M5 Max launch — pass:
  `/tmp/sm64-modern-m31w-live.log`; Metal 4 device ready, frame one
  presented, 360 fixed steps, zero scheduler/audio drops, status-0 shutdown.

## Boundary

The bounded automated route does not enter a water-surface transition, so the
live log proves startup/render/scheduler/shutdown only. It does not prove
physical water camera feel, authored water route telemetry, collision parity,
controller behavior, or human acceptance. C still owns per-frame water-level
and floor queries, behind-Mario collision resolution, graph pointers, and
Lakitu presentation.

## Next

Promote the cutscene clock/spline snapshot and shot evaluator through the same
owner-thread boundary, then qualify authored camera route shards before
starting frontend/audio authority cutovers.
