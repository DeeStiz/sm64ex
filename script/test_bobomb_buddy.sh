#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-bobomb-buddy"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/BobombBuddyBehavior.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_bobomb_buddy_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-bobomb-buddy-smoke"
SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-bobomb-buddy-smoke)"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang -std=c11 \
  "$PROJECT_ROOT/tests/sm64_modern_bobomb_buddy_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-bobomb-buddy-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-bobomb-buddy-contract)"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^bobombBuddyFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^bobombBuddyFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C Bob-omb Buddy fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "SM64 Modern Bob-omb Buddy C contract matched"
