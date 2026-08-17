#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-render-packet-capture-smoke"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/RenderPacketCapture.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_render_packet_capture_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-render-packet-capture-smoke"

xcrun clang -std=c11 -Wall -Wextra -Werror \
  "$PROJECT_ROOT/tests/sm64_modern_render_packet_capture_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-render-packet-capture-contract"

SWIFT_OUTPUT="$("$BUILD_ROOT/sm64-modern-render-packet-capture-smoke")"
C_OUTPUT="$("$BUILD_ROOT/sm64-modern-render-packet-capture-contract")"
printf '%s\n' "$SWIFT_OUTPUT"
printf '%s\n' "$C_OUTPUT"

SWIFT_FRAME="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^renderFrameFingerprint=//p')"
C_FRAME="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^renderFrameFingerprint=//p')"
SWIFT_FINISH="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^renderFinishFingerprint=//p')"
C_FINISH="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^renderFinishFingerprint=//p')"
[[ -n "$SWIFT_FRAME" && "$SWIFT_FRAME" == "$C_FRAME" ]] || {
  echo "Swift/C render frame fingerprint mismatch: Swift=$SWIFT_FRAME C=$C_FRAME" >&2
  exit 1
}
[[ -n "$SWIFT_FINISH" && "$SWIFT_FINISH" == "$C_FINISH" ]] || {
  echo "Swift/C render finish fingerprint mismatch: Swift=$SWIFT_FINISH C=$C_FINISH" >&2
  exit 1
}
printf '%s\n' "SM64 Modern render packet capture C↔Swift contract matched"
