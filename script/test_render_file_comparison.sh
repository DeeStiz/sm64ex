#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-render-file-comparison"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RenderPacketCapture.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_render_file_compare_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-render-file-compare"

xcrun clang -std=c11 -Wall -Wextra -Werror \
  -I"$PROJECT_ROOT/include" \
  "$PROJECT_ROOT/tests/sm64_modern_render_file_trace_fixture.c" \
  -o "$BUILD_ROOT/sm64-modern-render-file-trace-fixture"

TRACE_PATH="$BUILD_ROOT/c-render.trace"
PACKET_PATH="$BUILD_ROOT/swift-render.packet"
rm -f "$TRACE_PATH" "$PACKET_PATH"
"$BUILD_ROOT/sm64-modern-render-file-compare" --write-packet "$PACKET_PATH"
"$BUILD_ROOT/sm64-modern-render-file-trace-fixture" "$TRACE_PATH"
OUTPUT="$($BUILD_ROOT/sm64-modern-render-file-compare "$TRACE_PATH" "$PACKET_PATH")"
printf '%s\n' "$OUTPUT"
grep -Fq 'SM64 Modern file-backed render comparison matched' <<< "$OUTPUT"
grep -Fq 'renderFileCompareRecords=3' <<< "$OUTPUT"
printf '%s\n' 'SM64 Modern file-backed render comparison contract matched'
