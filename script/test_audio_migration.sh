#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-audio-migration-smoke"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -import-objc-header "$PROJECT_ROOT/SM64Modern/SM64Modern-Bridging-Header.h" \
  -I"$PROJECT_ROOT/include" \
  -I"$PROJECT_ROOT/src" \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/AudioMigration.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_audio_migration_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-audio-migration-smoke"
SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-audio-migration-smoke)"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang -std=c11 -Wall -Wextra -Werror \
  -I"$PROJECT_ROOT/include" \
  -I"$PROJECT_ROOT/src" \
  "$PROJECT_ROOT/src/pc/sm64_modern_audio_migration.c" \
  "$PROJECT_ROOT/tests/sm64_modern_audio_migration_smoke.c" \
  -o "$BUILD_ROOT/sm64-modern-audio-migration-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-audio-migration-contract)"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^audioSequenceMigrationFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^audioSequenceMigrationFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C audio migration fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "SM64 Modern audio sequence migration C↔Swift contract matched"
