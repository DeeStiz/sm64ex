#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-static-checkered-platform"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/StaticCheckeredPlatformBehavior.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_static_checkered_platform_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-static-checkered-platform-smoke"
SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-static-checkered-platform-smoke)"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang -std=c11 -ffp-contract=off \
  "$PROJECT_ROOT/tests/sm64_modern_static_checkered_platform_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-static-checkered-platform-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-static-checkered-platform-contract)"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^staticCheckeredPlatformFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^staticCheckeredPlatformFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C static checkered platform fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "SM64 Modern static checkered platform C contract matched"
