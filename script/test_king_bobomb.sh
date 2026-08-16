#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-king-bobomb"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/KingBobombBehavior.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_king_bobomb_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-king-bobomb-smoke"
SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-king-bobomb-smoke)"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang -std=c11 \
  "$PROJECT_ROOT/tests/sm64_modern_king_bobomb_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-king-bobomb-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-king-bobomb-contract)"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^kingBobombFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^kingBobombFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C King Bob-omb fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "SM64 Modern King Bob-omb C contract matched"
