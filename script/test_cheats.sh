#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-cheats-smoke"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/Configuration.swift" \
  "$PROJECT_ROOT/SM64Modern/Cheats.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_cheats_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-cheats-smoke"
SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-cheats-smoke)"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang -std=c11 -Wall -Wextra -Werror \
  "$PROJECT_ROOT/tests/sm64_modern_cheats_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-cheats-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-cheats-contract)"
printf '%s\n' "$C_OUTPUT"

xcrun clang -std=c11 -Wall -Wextra -Werror \
  -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  "$PROJECT_ROOT/src/pc/cheats.c" \
  "$PROJECT_ROOT/src/pc/sm64_modern_cheats.c" \
  "$PROJECT_ROOT/tests/sm64_modern_cheats_abi_smoke.c" \
  -o "$BUILD_ROOT/sm64-modern-cheats-abi-smoke"
"$BUILD_ROOT/sm64-modern-cheats-abi-smoke"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^cheatFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^cheatFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C cheat fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "SM64 Modern cheats C↔Swift contract matched"
