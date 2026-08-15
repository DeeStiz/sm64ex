#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-mario-burning-ground-smoke"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" \
  "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/InputCore.swift" \
  "$PROJECT_ROOT/SM64Modern/SurfacePartition.swift" \
  "$PROJECT_ROOT/SM64Modern/SurfaceCollision.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioInputCore.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioGeometryInput.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioState.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioAction.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioSlope.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioGroundStep.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioBurningGroundAction.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_burning_ground_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-mario-burning-ground-smoke"
SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-mario-burning-ground-smoke)"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang -std=c11 \
  "$PROJECT_ROOT/tests/sm64_modern_mario_burning_ground_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-mario-burning-ground-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-mario-burning-ground-contract)"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^marioBurningGroundFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^marioBurningGroundFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C Mario burning-ground fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "SM64 Modern Mario burning-ground C contract matched"
