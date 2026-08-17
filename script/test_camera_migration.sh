#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-camera-migration-smoke"
mkdir -p "$BUILD_ROOT"

xcrun clang -std=c11 -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  "$PROJECT_ROOT/tests/sm64_modern_camera_migration_smoke.c" \
  "$PROJECT_ROOT/src/pc/sm64_modern_camera_migration.c" \
  -o "$BUILD_ROOT/sm64-modern-camera-migration-smoke"

OUTPUT="$($BUILD_ROOT/sm64-modern-camera-migration-smoke)"
printf '%s\n' "$OUTPUT"
[[ "$OUTPUT" == cameraMigrationFingerprint=* ]] || {
  echo "camera migration smoke did not emit a fingerprint" >&2
  exit 1
}
