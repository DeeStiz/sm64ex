#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-audio-pools-smoke"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/Audio.swift" \
  "$PROJECT_ROOT/SM64Modern/AudioPools.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_audio_pools_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-audio-pools-smoke"
SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-audio-pools-smoke)"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang -std=c11 -Wall -Wextra -Werror \
  "$PROJECT_ROOT/tests/sm64_modern_audio_pools_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-audio-pools-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-audio-pools-contract)"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^audioPoolsFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^audioPoolsFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C audio-pools fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "SM64 Modern audio pools C↔Swift contract matched"
