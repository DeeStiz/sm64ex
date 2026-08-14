#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-mario-ground-speed-smoke"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioGroundSpeed.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_ground_speed_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-mario-ground-speed-smoke"
SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-mario-ground-speed-smoke)"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang -std=c11 \
  "$PROJECT_ROOT/tests/sm64_modern_mario_ground_speed_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-mario-ground-speed-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-mario-ground-speed-contract)"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^marioGroundSpeedFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^marioGroundSpeedFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C Mario ground-speed fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "SM64 Modern Mario ground-speed C contract matched"
