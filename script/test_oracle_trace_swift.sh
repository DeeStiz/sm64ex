#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/oracle-trace-swift-smoke"
OUTPUT="$BUILD_ROOT/sm64-modern-oracle-trace-swift-smoke"

mkdir -p "$BUILD_ROOT/module-cache"
xcrun swiftc \
  -parse-as-library \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_oracle_trace_swift_smoke.swift" \
  -o "$OUTPUT"
if [[ -f "$PROJECT_ROOT/build/oracle-trace-smoke/c-produced.trace" ]]; then
  "$OUTPUT" "$PROJECT_ROOT/build/oracle-trace-smoke/c-produced.trace"
else
  "$OUTPUT"
fi
