#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-camera-cup-smoke"
mkdir -p "$BUILD_ROOT"

xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" \
  "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/CameraPrimitives.swift" \
  "$PROJECT_ROOT/SM64Modern/CameraGeometry.swift" \
  "$PROJECT_ROOT/SM64Modern/CameraCUp.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_camera_cup_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-camera-cup-smoke"
SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-camera-cup-smoke)"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang -std=c11 "$PROJECT_ROOT/tests/sm64_modern_camera_cup_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-camera-cup-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-camera-cup-contract)"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^cameraCUpFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^cameraCUpFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C camera C-up fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "SM64 Modern camera C-up C contract matched"
