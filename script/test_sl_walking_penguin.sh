#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "${BASH_SOURCE[0]%/*}/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-sl-walking-penguin"
mkdir -p "$BUILD_ROOT"

xcrun swiftc -parse-as-library -swift-version 6 -Xfrontend -strict-concurrency=complete -module-cache-path "$BUILD_ROOT/module-cache" "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" "$PROJECT_ROOT/SM64Modern/SLWalkingPenguinBehavior.swift" "$PROJECT_ROOT/tests/sm64_modern_sl_walking_penguin_smoke.swift" -o "$BUILD_ROOT/sm64-modern-sl-walking-penguin-smoke"
SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-sl-walking-penguin-smoke)"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang -std=c11 -ffp-contract=off -I"$PROJECT_ROOT/include" "$PROJECT_ROOT/tests/sm64_modern_sl_walking_penguin_contract.c" -o "$BUILD_ROOT/sm64-modern-sl-walking-penguin-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-sl-walking-penguin-contract)"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^slWalkingPenguinFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^slWalkingPenguinFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C SL walking penguin fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "SM64 Modern SL walking penguin C contract matched"
