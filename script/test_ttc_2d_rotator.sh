#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-ttc-2d-rotator"
mkdir -p "$BUILD_ROOT"
xcrun swiftc -parse-as-library -swift-version 6 -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/TTC2DRotatorBehavior.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_ttc_2d_rotator_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-ttc-2d-rotator-smoke"
SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-ttc-2d-rotator-smoke)"; printf '%s\n' "$SWIFT_OUTPUT"
xcrun clang -std=c11 -ffp-contract=off \
  "$PROJECT_ROOT/tests/sm64_modern_ttc_2d_rotator_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-ttc-2d-rotator-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-ttc-2d-rotator-contract)"; printf '%s\n' "$C_OUTPUT"
SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^ttc2DRotatorFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^ttc2DRotatorFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]]
printf '%s\n' 'SM64 Modern TTC 2D rotator C contract matched'
