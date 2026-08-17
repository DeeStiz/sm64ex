#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-pause-migration-smoke"
mkdir -p "$BUILD_ROOT"

xcrun clang -std=c11 -Wall -Wextra -Werror \
  -I"$PROJECT_ROOT/include" \
  -I"$PROJECT_ROOT/src" \
  -c "$PROJECT_ROOT/src/pc/sm64_modern_pause_migration.c" \
  -o "$BUILD_ROOT/sm64_modern_pause_migration.o"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -import-objc-header "$PROJECT_ROOT/SM64Modern/SM64Modern-Bridging-Header.h" \
  -I"$PROJECT_ROOT/include" \
  -I"$PROJECT_ROOT/src" \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/PauseMenu.swift" \
  "$PROJECT_ROOT/SM64Modern/PauseMenuMigration.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_pause_migration_smoke.swift" \
  "$BUILD_ROOT/sm64_modern_pause_migration.o" \
  -o "$BUILD_ROOT/sm64-modern-pause-migration-smoke"
SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-pause-migration-smoke)"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang -std=c11 -Wall -Wextra -Werror \
  -I"$PROJECT_ROOT/include" \
  -I"$PROJECT_ROOT/src" \
  "$PROJECT_ROOT/src/pc/sm64_modern_pause_migration.c" \
  "$PROJECT_ROOT/tests/sm64_modern_pause_migration_smoke.c" \
  -o "$BUILD_ROOT/sm64-modern-pause-migration-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-pause-migration-contract)"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^pauseMenuMigrationFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^pauseMenuMigrationFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C pause menu migration fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "SM64 Modern pause menu migration C↔Swift contract matched"
