#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-deterministic-primitives-smoke"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" \
  "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_deterministic_primitives_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-deterministic-primitives-smoke"

SWIFT_OUTPUT="$("$BUILD_ROOT/sm64-modern-deterministic-primitives-smoke")"
printf '%s\n' "$SWIFT_OUTPUT"
SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/.*trigFingerprint=//p')"
if [[ -z "$SWIFT_FINGERPRINT" ]]; then
  echo "Swift trig fingerprint was not emitted" >&2
  exit 1
fi

xcrun clang \
  -std=c11 \
  -DAVOID_UB=1 \
  -I"$PROJECT_ROOT/include" \
  "$PROJECT_ROOT/tests/sm64_modern_trig_table_fingerprint.c" \
  -o "$BUILD_ROOT/sm64-modern-trig-table-fingerprint"
C_FINGERPRINT="$("$BUILD_ROOT/sm64-modern-trig-table-fingerprint")"
if [[ "$SWIFT_FINGERPRINT" != "$C_FINGERPRINT" ]]; then
  echo "Swift/C trig table fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
fi
