#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-goomba-enemy-smoke"
mkdir -p "$BUILD_ROOT"

xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/GoombaEnemy.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_goomba_enemy_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-goomba-enemy-smoke"
OUTPUT="$($BUILD_ROOT/sm64-modern-goomba-enemy-smoke)"
printf '%s\n' "$OUTPUT"
[[ "$OUTPUT" == goombaEnemyFingerprint=* ]] || {
  echo "Goomba enemy smoke did not emit a fingerprint" >&2
  exit 1
}

xcrun clang -std=c11 \
  "$PROJECT_ROOT/tests/sm64_modern_goomba_enemy_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-goomba-enemy-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-goomba-enemy-contract)"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$OUTPUT" | sed -n 's/^goombaEnemyFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^goombaEnemyFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C Goomba fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "SM64 Modern Goomba C contract matched"
