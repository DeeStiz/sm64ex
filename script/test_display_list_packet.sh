#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-display-list-packet-smoke"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/DisplayListPacket.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_display_list_packet_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-display-list-packet-smoke"

xcrun clang -std=c11 -Wall -Wextra -Werror \
  "$PROJECT_ROOT/tests/sm64_modern_display_list_packet_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-display-list-packet-contract"

SWIFT_OUTPUT="$("$BUILD_ROOT/sm64-modern-display-list-packet-smoke")"
C_OUTPUT="$("$BUILD_ROOT/sm64-modern-display-list-packet-contract")"
printf '%s\n' "$SWIFT_OUTPUT"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^displayListPacketFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^displayListPacketFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C display-list packet fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "SM64 Modern display-list packet C↔Swift contract matched"
