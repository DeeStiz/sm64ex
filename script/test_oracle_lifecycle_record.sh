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
  -DNON_MATCHING=1 \
  -DAVOID_UB=1 \
  -DVERSION_US \
  -D_LANGUAGE_C \
  -I"$PROJECT_ROOT" \
  -I"$PROJECT_ROOT/include" \
  -I"$PROJECT_ROOT/src" \
  -I"$NATIVE_BUILD" \
  "$PROJECT_ROOT/tests/sm64_modern_oracle_lifecycle_record.c" \
  "$NATIVE_BUILD/libsm64core.a" \
  -o "$OUTPUT" \
  -lm \
  -lpthread

LOG="$BUILD_ROOT/live-oracle-lifecycle-record.log"
if [[ "${SM64_MODERN_AUTOMATED_CASTLE_AREA2:-0}" == "1" ]]; then
  SM64_MODERN_AUTOMATED_CASTLE_AREA2=1 \
    "$OUTPUT" "$TRACE" "$SAVE_ROOT" | tee "$LOG"
else
  SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
    "$OUTPUT" "$TRACE" "$SAVE_ROOT" | tee "$LOG"
fi

if [[ "${SM64_MODERN_PAIRING_ROUTE:-0}" == "1" ]]; then
  grep -Eq 'liveOracleInputRecords=[1-9][0-9]*' "$LOG"
else
  grep -Eq 'liveOracleRenderRecords=[1-9][0-9]*' "$LOG"
fi

test -s "$TRACE"
TRACE_HEADER_HEX="$(od -An -tx1 -N8 "$TRACE" | tr -d '[:space:]')"
test "$TRACE_HEADER_HEX" = "0100000048000000"
printf '%s\n' "SM64 Modern live oracle lifecycle file smoke passed"
