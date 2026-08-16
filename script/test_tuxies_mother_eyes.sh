#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-tuxies-mother-eyes"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/TuxiesMotherEyes.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_tuxies_mother_eyes_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-tuxies-mother-eyes-smoke"
SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-tuxies-mother-eyes-smoke)"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang -std=c11 \
  "$PROJECT_ROOT/tests/sm64_modern_tuxies_mother_eyes_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-tuxies-mother-eyes-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-tuxies-mother-eyes-contract)"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^tuxiesMotherEyesFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^tuxiesMotherEyesFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C Tuxie's mother eyes fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "SM64 Modern Tuxie's mother eyes C contract matched"
