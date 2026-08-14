#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/oracle-trace-smoke"
OUTPUT="$BUILD_ROOT/sm64-modern-oracle-trace-smoke"

mkdir -p "$BUILD_ROOT"
xcrun --sdk macosx clang \
  -std=c11 \
  -Wall \
  -Wextra \
  -Werror \
  -mmacosx-version-min=27.0 \
  -I"$PROJECT_ROOT/include" \
  "$PROJECT_ROOT/src/pc/sm64_modern_oracle_trace.c" \
  "$PROJECT_ROOT/tests/sm64_modern_oracle_trace_smoke.c" \
  -o "$OUTPUT"
"$OUTPUT" "$BUILD_ROOT/c-produced.trace"
