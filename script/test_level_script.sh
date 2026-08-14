#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-level-script-smoke"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/LevelScript.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_level_script_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-level-script-smoke"

SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-level-script-smoke)"
printf '%s\n' "$SWIFT_OUTPUT"
SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^levelScriptFingerprint=//p')"

xcrun clang \
  -std=c11 \
  "$PROJECT_ROOT/tests/sm64_modern_level_script_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-level-script-contract"
C_FINGERPRINT="$($BUILD_ROOT/sm64-modern-level-script-contract | sed -n 's/^levelScriptFingerprint=//p')"
if [[ -z "$SWIFT_FINGERPRINT" || "$SWIFT_FINGERPRINT" != "$C_FINGERPRINT" ]]; then
  echo "Swift/C level-script fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
fi

printf '%s\n' "SM64 Modern level-script C contract matched"
