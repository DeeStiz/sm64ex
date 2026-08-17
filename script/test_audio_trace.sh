#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-audio-trace-smoke"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/Audio.swift" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/AudioSequence.swift" \
  "$PROJECT_ROOT/SM64Modern/AudioPools.swift" \
  "$PROJECT_ROOT/SM64Modern/AudioResidency.swift" \
  "$PROJECT_ROOT/SM64Modern/AudioTrace.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_audio_trace_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-audio-trace-smoke"
SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-audio-trace-smoke)"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang -std=c11 -Wall -Wextra -Werror \
  "$PROJECT_ROOT/tests/sm64_modern_audio_trace_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-audio-trace-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-audio-trace-contract)"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^audioTraceFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^audioTraceFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C audio-trace fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "SM64 Modern audio trace C↔Swift contract matched"
