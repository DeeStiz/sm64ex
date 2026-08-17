#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-render-trace-adapter-smoke"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RenderPacketCapture.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_render_trace_adapter_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-render-trace-adapter-smoke"

xcrun clang -std=c11 -Wall -Wextra -Werror \
  "$PROJECT_ROOT/tests/sm64_modern_render_trace_adapter_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-render-trace-adapter-contract"

SWIFT_OUTPUT="$("$BUILD_ROOT/sm64-modern-render-trace-adapter-smoke")"
C_OUTPUT="$("$BUILD_ROOT/sm64-modern-render-trace-adapter-contract")"
printf '%s\n' "$SWIFT_OUTPUT"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^renderTraceFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^renderTraceFingerprint=//p')"
SWIFT_DIVERGENCE="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^renderTraceDivergence=//p')"
C_DIVERGENCE="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^renderTraceDivergence=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C render-trace fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
[[ "$SWIFT_DIVERGENCE" == "$C_DIVERGENCE" ]] || {
  echo "Swift/C render-trace divergence mismatch: Swift=$SWIFT_DIVERGENCE C=$C_DIVERGENCE" >&2
  exit 1
}
printf '%s\n' "SM64 Modern render trace adapter C↔Swift contract matched"
