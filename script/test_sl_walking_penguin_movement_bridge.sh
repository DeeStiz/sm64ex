#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-sl-walking-penguin-movement-bridge"
mkdir -p "$BUILD_ROOT"

xcrun swiftc -parse-as-library -swift-version 6 -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" \
  "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/MemoryArena.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectTransform.swift" \
  "$PROJECT_ROOT/SM64Modern/SurfacePartition.swift" \
  "$PROJECT_ROOT/SM64Modern/SurfaceCollision.swift" \
  "$PROJECT_ROOT/SM64Modern/EngineState.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectScheduler.swift" \
  "$PROJECT_ROOT/SM64Modern/SLWalkingPenguinBehavior.swift" \
  "$PROJECT_ROOT/SM64Modern/SLWalkingPenguinCollision.swift" \
  "$PROJECT_ROOT/SM64Modern/SLWalkingPenguinMovement.swift" \
  "$PROJECT_ROOT/SM64Modern/SLWalkingPenguinObjectBridge.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_sl_walking_penguin_movement_bridge_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-sl-walking-penguin-movement-bridge-smoke"
SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-sl-walking-penguin-movement-bridge-smoke)"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang -std=c11 -ffp-contract=off -I"$PROJECT_ROOT/include" \
  "$PROJECT_ROOT/tests/sm64_modern_sl_walking_penguin_movement_bridge_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-sl-walking-penguin-movement-bridge-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-sl-walking-penguin-movement-bridge-contract)"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^slWalkingPenguinMovementBridgeFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^slWalkingPenguinMovementBridgeFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C SL walking penguin movement bridge fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "SM64 Modern SL walking penguin movement bridge C contract matched"
