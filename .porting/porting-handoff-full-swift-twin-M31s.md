# M31s Handoff — Swift Fixed-Camera Geometry Seam

## State

M31s is complete locally. The fixed-camera transition callback (mode 13) now
uses the Swift owner-thread evaluator when Swift camera authority is enabled.
The C adapter remains the compatibility boundary for mutable camera state and
collision queries.

## Implementation

- `SM64Modern/CameraFixed.swift` owns the value-only fixed-camera kernel.
- `SM64Modern/CameraModeCallbacks.swift` marks mode 13 as implemented and
  maps the scalar snapshot into the kernel.
- `SM64Modern/CameraMigration.swift` validates/maps the new fixed fields and
  preserves the reserved-field fence.
- `include/sm64_modern.h` carries fixed anchor, interpolation, floor/ceiling,
  and smooth-movement fields plus explicit presence flags.
- `src/game/camera.c` snapshots source-authored floor/ceiling facts and routes
  `update_fixed_camera` through Swift after C C-button/buzzer side effects.
- `SM64Modern.xcodeproj/project.pbxproj` includes the new Swift source.

## Evidence

- `./script/test_camera_primitives.sh` — pass,
  `cameraPrimitivesFingerprint=0xe71dca12bbf8bb32`.
- `./script/test_camera_geometry.sh` — pass,
  `cameraGeometryFingerprint=0x9bc38f9c51aae152`.
- `./script/test_camera_mode_callbacks.sh` — pass,
  `cameraModeCallbacksFingerprint=0x3be4915380f50c3f`; Swift/C contract
  matched, including the fixed-mode value case.
- `./script/test_camera_migration.sh` — pass,
  `cameraMigrationFingerprint=0x9e3779b97f4a7d11`.
- `./script/test_camera_mode_state.sh` — pass,
  `cameraModeStateFingerprint=0x80ec629967e739dc`.
- `./script/test_engine_runtime.sh` — pass.
- `make -j2 abi-smoke` — pass; native C core rebuilt with the fixed callback
  ABI.
- Swift 6/macOS 27 Debug build — pass:
  `/tmp/sm64-modern-camera-fixed-build.log`.
- Signed Apple M5 Max launch — pass:
  `/tmp/sm64-modern-m31s-live.log`; Metal 4 device ready, frame one
  presented, 360 fixed steps, zero scheduler/audio drops, status-0 shutdown.

## Boundary

The bounded automated route does not enter an authored fixed-camera mode, so
the live log proves startup/render/scheduler/shutdown only. It does not prove
fixed-mode visual parity, camera feel, controller behavior, or human
acceptance. C still owns fixed-mode collision queries, C-button/buzzer
effects, pointer-based graph/Lakitu presentation, and all remaining camera
families plus cutscene traversal.

## Next

Continue M31 camera breadth with parallel-tracking, boss-fight, spiral-stairs,
water/no-op, and cutscene clock/spline boundaries. Then promote frontend,
audio, and rendering authority only with source contracts, deterministic
replays, and live Metal 4 evidence; do not treat this bounded seam as full
camera parity.
