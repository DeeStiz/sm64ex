#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-sl-walking-penguin-movement"
mkdir -p "$BUILD_ROOT"

xcrun swiftc -parse-as-library -swift-version 6 -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" \
  "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/SLWalkingPenguinMovement.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_sl_walking_penguin_movement_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-sl-walking-penguin-movement-smoke"
SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-sl-walking-penguin-movement-smoke)"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang -std=c11 -ffp-contract=off \
  "$PROJECT_ROOT/tests/sm64_modern_sl_walking_penguin_movement_contract.c" \
  -I"$PROJECT_ROOT/include" -lm -o "$BUILD_ROOT/sm64-modern-sl-walking-penguin-movement-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-sl-walking-penguin-movement-contract)"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^slWalkingPenguinMovementFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^slWalkingPenguinMovementFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C SL walking penguin movement fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "SM64 Modern SL walking penguin movement C contract matched"
