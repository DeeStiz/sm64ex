#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-ttc-pit-block"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/TTCPitBlockBehavior.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_ttc_pit_block_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-ttc-pit-block-smoke"
SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-ttc-pit-block-smoke)"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang -std=c11 -ffp-contract=off \
  "$PROJECT_ROOT/tests/sm64_modern_ttc_pit_block_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-ttc-pit-block-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-ttc-pit-block-contract)"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^ttcPitBlockFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^ttcPitBlockFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C TTC pit block fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "SM64 Modern TTC pit block C contract matched"
