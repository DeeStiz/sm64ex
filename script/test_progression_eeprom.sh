#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-progression-eeprom-smoke"
mkdir -p "$BUILD_ROOT"

xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" \
  "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/ProgressionState.swift" \
  "$PROJECT_ROOT/SM64Modern/SaveFileCodec.swift" \
  "$PROJECT_ROOT/SM64Modern/CoinScoreAges.swift" \
  "$PROJECT_ROOT/SM64Modern/ProgressionPersistence.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_progression_eeprom_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-progression-eeprom-smoke"

OUTPUT="$($BUILD_ROOT/sm64-modern-progression-eeprom-smoke)"
printf '%s\n' "$OUTPUT"
[[ "$OUTPUT" == progressionEEPROMFingerprint=* ]] || {
  echo "progression EEPROM smoke did not emit a fingerprint" >&2
  exit 1
}

xcrun clang -std=c11 \
  "$PROJECT_ROOT/tests/sm64_modern_progression_eeprom_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-progression-eeprom-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-progression-eeprom-contract)"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$OUTPUT" | sed -n 's/^progressionEEPROMFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^progressionEEPROMFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C progression-EEPROM fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "SM64 Modern progression-EEPROM C contract matched"
