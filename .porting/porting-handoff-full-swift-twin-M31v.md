# M31v Handoff — Swift Parallel-Tracking Stable-Segment Camera Seam

## State

M31v is complete locally. Parallel-tracking camera mode 12 now has a bounded
Swift evaluator path for its stable first segment. The owner-thread C adapter
still owns path-window mutation, transition evolution, collision, and the
mutable camera graph.

## Implementation

- `SM64Modern/CameraParallel.swift` owns midpoint/path-angle rotation,
  distance-threshold correction, zoom placement, transition translation,
  Mario focus, and returned camera yaw.
- `SM64Modern/CameraModeCallbacks.swift` marks mode 12 pure for the stable
  segment and maps the fixed-width snapshot into the kernel.
- `SM64Modern/CameraMigration.swift` validates/maps parallel fields and the
  reserved-word fence.
- `include/sm64_modern.h` carries path endpoints, threshold/zoom/floor/
  transition values, and an explicit stable-segment flag.
- `src/game/camera.c` snapshots the first path only when index zero is stable
  and no path switch is pending, routes the callback, and leaves path-index
  switching on the C fallback.
- `SM64Modern.xcodeproj/project.pbxproj` includes the new Swift source.

## Evidence

- `./script/test_camera_primitives.sh` — pass,
  `cameraPrimitivesFingerprint=0xe71dca12bbf8bb32`.
- `./script/test_camera_geometry.sh` — pass,
  `cameraGeometryFingerprint=0x9bc38f9c51aae152`.
- `./script/test_camera_mode_callbacks.sh` — pass,
  `cameraModeCallbacksFingerprint=0x438d5e36a7302ccc`; Swift/C contract
  matched, including fixed, boss, spiral, and parallel cases.
- `./script/test_camera_migration.sh` — pass,
  `cameraMigrationFingerprint=0x9e3779b97f4a7d11`.
- `./script/test_camera_mode_state.sh` — pass,
  `cameraModeStateFingerprint=0x80ec629967e739dc`.
- `./script/test_engine_runtime.sh` — pass.
- `make -j2 abi-smoke` — pass; native C core rebuilt with the parallel callback
  ABI.
- Swift 6/macOS 27 Debug build — pass:
  `/tmp/sm64-modern-camera-parallel-build.log`.
- Signed Apple M5 Max launch — pass:
  `/tmp/sm64-modern-m31v-live.log`; Metal 4 device ready, frame one
  presented, 360 fixed steps, zero scheduler/audio drops, status-0 shutdown.

## Boundary

The bounded automated route does not enter parallel-tracking mode, so the live
log proves startup/render/scheduler/shutdown only. It does not prove path
switching, authored camera visual parity, camera feel, controller behavior, or
human acceptance. C still owns path-index selection, transition-offset
approach, floor/collision queries, graph pointers, Lakitu presentation, and
all remaining water/cutscene camera work.

## Next

Finish the water/no-op callback boundary, then promote cutscene clock/spline
state and qualify authored camera route shards before moving to frontend/audio
authority and full-game replay breadth.
