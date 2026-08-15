#!/bin/zsh
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-camera-cup-exit-smoke"
mkdir -p "$BUILD_ROOT"
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" \
  "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/SurfacePartition.swift" \
  "$PROJECT_ROOT/SM64Modern/SurfaceCollision.swift" \
  "$PROJECT_ROOT/SM64Modern/CameraPrimitives.swift" \
  "$PROJECT_ROOT/SM64Modern/CameraModeState.swift" \
  "$PROJECT_ROOT/SM64Modern/CameraGeometry.swift" \
  "$PROJECT_ROOT/SM64Modern/CameraCUp.swift" \
  "$PROJECT_ROOT/SM64Modern/CameraCUpExit.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_camera_cup_exit_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-camera-cup-exit-smoke"
SWIFT_OUTPUT="$("$BUILD_ROOT/sm64-modern-camera-cup-exit-smoke")"
xcrun clang -std=c11 "$PROJECT_ROOT/tests/sm64_modern_camera_cup_exit_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-camera-cup-exit-contract"
C_OUTPUT="$("$BUILD_ROOT/sm64-modern-camera-cup-exit-contract")"
SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^cameraCUpExitFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^cameraCUpExitFingerprint=//p')"
if [[ -z "$SWIFT_FINGERPRINT" || "$SWIFT_FINGERPRINT" != "$C_FINGERPRINT" ]]; then
  echo "Swift/C camera C-up exit fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
fi
printf '%s\n' "$SWIFT_OUTPUT"
printf '%s\n' "$C_OUTPUT"
printf '%s\n' "SM64 Modern camera C-up exit C contract matched"
