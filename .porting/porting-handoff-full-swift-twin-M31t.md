# M31t Handoff — Swift Boss-Fight Camera Geometry Seam

## State

M31t is complete locally. Boss-fight camera mode 11 now has a Swift
owner-thread evaluator path when Swift camera authority is active. The C
adapter remains responsible for mutable game-object and surface queries and
legacy side effects.

## Implementation

- `SM64Modern/CameraBoss.swift` owns the value-only boss-camera kernel.
- `SM64Modern/CameraModeCallbacks.swift` marks mode 11 implemented and maps
  the boss snapshot into the kernel.
- `SM64Modern/CameraMigration.swift` validates/maps boss fields and reserved
  fences.
- `include/sm64_modern.h` carries second-focus, distance, floor, held-state,
  yaw, angular-velocity, and height-override fields with explicit flags.
- `src/game/camera.c` snapshots object/floor facts, preserves C-button and
  environmental-shake effects, updates Lakitu zoom, and routes the callback.
- `SM64Modern.xcodeproj/project.pbxproj` includes the new Swift source.

## Evidence

- `./script/test_camera_primitives.sh` — pass,
  `cameraPrimitivesFingerprint=0xe71dca12bbf8bb32`.
- `./script/test_camera_geometry.sh` — pass,
  `cameraGeometryFingerprint=0x9bc38f9c51aae152`.
- `./script/test_camera_mode_callbacks.sh` — pass,
  `cameraModeCallbacksFingerprint=0x59e776a4ca33b198`; Swift/C contract
  matched, including fixed and boss value cases.
- `./script/test_camera_migration.sh` — pass,
  `cameraMigrationFingerprint=0x9e3779b97f4a7d11`.
- `./script/test_camera_mode_state.sh` — pass,
  `cameraModeStateFingerprint=0x80ec629967e739dc`.
- `./script/test_engine_runtime.sh` — pass.
- `make -j2 abi-smoke` — pass; native C core rebuilt with the boss callback
  ABI.
- Swift 6/macOS 27 Debug build — pass:
  `/tmp/sm64-modern-camera-boss-build.log`.
- Signed Apple M5 Max launch — pass:
  `/tmp/sm64-modern-m31t-live.log`; Metal 4 device ready, frame one
  presented, 360 fixed steps, zero scheduler/audio drops, status-0 shutdown.

## Boundary

The automated startup route does not enter a boss-fight camera mode, so the
live log proves startup/render/scheduler/shutdown only. It does not prove boss
camera visual parity, camera feel, controller behavior, or human acceptance.
C still owns object and floor queries, C-button/environmental-shake effects,
Lakitu zoom state mutation, pointer-based presentation, and remaining camera
families/cutscene traversal.

## Next

Continue the camera family with parallel-tracking, spiral-stairs, water/no-op,
and cutscene clock/spline seams. Then qualify all camera modes through route
shards before making frontend, audio, or rendering authority claims.
