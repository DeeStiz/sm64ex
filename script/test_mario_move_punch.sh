#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-mario-move-punch-smoke"
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
  "$PROJECT_ROOT/SM64Modern/MarioGroundStep.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioSlope.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioSlopeDeceleration.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioPunchSequence.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioMovePunchAction.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_move_punch_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-mario-move-punch-smoke"
SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-mario-move-punch-smoke)"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang -std=c11 \
  "$PROJECT_ROOT/tests/sm64_modern_mario_move_punch_contract.c" \
  -lm \
  -o "$BUILD_ROOT/sm64-modern-mario-move-punch-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-mario-move-punch-contract)"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^marioMovePunchFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^marioMovePunchFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C Mario move-punch fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "SM64 Modern Mario move-punch C contract matched"
