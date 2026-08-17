#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-dialog-smoke"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/Dialog.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_dialog_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-dialog-smoke"
SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-dialog-smoke)"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang -std=c11 -Wall -Wextra -Werror \
  "$PROJECT_ROOT/tests/sm64_modern_dialog_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-dialog-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-dialog-contract)"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^dialogFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^dialogFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C dialog fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "SM64 Modern dialog C↔Swift contract matched"

