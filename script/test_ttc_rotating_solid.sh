#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-ttc-rotating-solid"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/TTCRotatingSolidBehavior.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_ttc_rotating_solid_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-ttc-rotating-solid-smoke"
SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-ttc-rotating-solid-smoke)"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang -std=c11 -ffp-contract=off \
  "$PROJECT_ROOT/tests/sm64_modern_ttc_rotating_solid_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-ttc-rotating-solid-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-ttc-rotating-solid-contract)"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^ttcRotatingSolidFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^ttcRotatingSolidFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C TTC rotating-solid fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "SM64 Modern TTC rotating-solid C contract matched"
