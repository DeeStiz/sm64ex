#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-debug"
NATIVE_BUILD="$BUILD_ROOT/us_pc"
OUTPUT="$BUILD_ROOT/sm64-modern-oracle-lifecycle-record"
TRACE="$BUILD_ROOT/live-schema4.trace"
SAVE_ROOT="$BUILD_ROOT/live-oracle-state"

mkdir -p "$BUILD_ROOT" "$SAVE_ROOT"

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 \
  DEBUG=1 \
  BUILD_DIR_BASE="$BUILD_ROOT" \
  native-core

test -f "$NATIVE_BUILD/libsm64core.a"

xcrun --sdk macosx clang \
  -std=c11 \
  -Wall \
  -Wextra \
  -Werror \
  -I"$PROJECT_ROOT/include" \
  -I"$PROJECT_ROOT/src" \
  -I"$NATIVE_BUILD" \
  "$PROJECT_ROOT/tests/sm64_modern_oracle_lifecycle_record.c" \
  "$NATIVE_BUILD/libsm64core.a" \
  -o "$OUTPUT" \
  -lm \
  -lpthread

LOG="$BUILD_ROOT/live-oracle-lifecycle-record.log"
SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
  "$OUTPUT" "$TRACE" "$SAVE_ROOT" | tee "$LOG"

grep -Eq 'liveOracleRenderRecords=[1-9][0-9]*' "$LOG"

test -s "$TRACE"
printf '%s\n' "SM64 Modern live oracle lifecycle file smoke passed"
