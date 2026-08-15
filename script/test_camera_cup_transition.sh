#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-camera-cup-transition-smoke"
mkdir -p "$BUILD_ROOT"
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" \
  "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/CameraCUpTransition.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_camera_cup_transition_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-camera-cup-transition-smoke"
SWIFT_OUTPUT="$("$BUILD_ROOT/sm64-modern-camera-cup-transition-smoke")"
xcrun clang -std=c11 "$PROJECT_ROOT/tests/sm64_modern_camera_cup_transition_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-camera-cup-transition-contract"
C_OUTPUT="$("$BUILD_ROOT/sm64-modern-camera-cup-transition-contract")"
SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^cameraCUpTransitionFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^cameraCUpTransitionFingerprint=//p')"
if [[ -z "$SWIFT_FINGERPRINT" || "$SWIFT_FINGERPRINT" != "$C_FINGERPRINT" ]]; then
  echo "Swift/C camera C-up transition fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
fi
printf '%s\n' "$SWIFT_OUTPUT"
printf '%s\n' "$C_OUTPUT"
printf '%s\n' "SM64 Modern camera C-up transition C contract matched"
