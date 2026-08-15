#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-ttc-moving-bar"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/TTCMovingBarBehavior.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_ttc_moving_bar_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-ttc-moving-bar-smoke"
SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-ttc-moving-bar-smoke)"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang -std=c11 -ffp-contract=off \
  "$PROJECT_ROOT/tests/sm64_modern_ttc_moving_bar_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-ttc-moving-bar-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-ttc-moving-bar-contract)"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^ttcMovingBarFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^ttcMovingBarFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C TTC moving bar fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "SM64 Modern TTC moving bar C contract matched"
