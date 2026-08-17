# M31u Handoff — Swift Spiral-Stairs Camera Geometry Seam

## State

M31u is complete locally. Spiral-stairs camera mode 17 now has a Swift
owner-thread evaluator path under Swift camera authority. The C adapter still
owns the mutable camera graph and the collision query that supplies the
snapshot.

## Implementation

- `SM64Modern/CameraSpiral.swift` owns staircase-relative yaw, placement,
  focus/height approaches, and return-yaw math.
- `SM64Modern/CameraModeCallbacks.swift` marks mode 17 implemented and maps
  the scalar snapshot into the kernel.
- `SM64Modern/CameraMigration.swift` validates/maps spiral fields and reserved
  fences.
- `include/sm64_modern.h` carries the staircase anchor, floor offsets, floor
  snapshot, and explicit floor-presence flag.
- `src/game/camera.c` snapshots the current focus/position and floor query,
  routes the callback, and stores the returned yaw-offset compatibility value.
- `SM64Modern.xcodeproj/project.pbxproj` includes the new Swift source.

## Evidence

- `./script/test_camera_primitives.sh` — pass,
  `cameraPrimitivesFingerprint=0xe71dca12bbf8bb32`.
- `./script/test_camera_geometry.sh` — pass,
  `cameraGeometryFingerprint=0x9bc38f9c51aae152`.
- `./script/test_camera_mode_callbacks.sh` — pass,
  `cameraModeCallbacksFingerprint=0x50e8fd2d5387c4a3`; Swift/C contract
  matched, including fixed, boss, and spiral cases.
- `./script/test_camera_migration.sh` — pass,
  `cameraMigrationFingerprint=0x9e3779b97f4a7d11`.
- `./script/test_camera_mode_state.sh` — pass,
  `cameraModeStateFingerprint=0x80ec629967e739dc`.
- `./script/test_engine_runtime.sh` — pass.
- `make -j2 abi-smoke` — pass; native C core rebuilt with spiral callback ABI.
- Swift 6/macOS 27 Debug build — pass:
  `/tmp/sm64-modern-camera-spiral-build.log`.
- Signed Apple M5 Max launch — pass:
  `/tmp/sm64-modern-m31u-live.log`; Metal 4 device ready, frame one
  presented, 360 fixed steps, zero scheduler/audio drops, status-0 shutdown.

## Boundary

The bounded automated route does not enter spiral-stairs mode, so the live log
proves startup/render/scheduler/shutdown only. It does not prove spiral camera
visual parity, camera feel, controller behavior, or human acceptance. C still
owns floor lookup, C-button behavior, graph pointers, Lakitu presentation,
and all remaining camera families/cutscene traversal.

## Next

Finish the parallel-tracking and water/no-op camera transitions, then expose
cutscene clock/spline state through an owner-thread boundary before moving to
frontend/audio authority and route-shard qualification.
