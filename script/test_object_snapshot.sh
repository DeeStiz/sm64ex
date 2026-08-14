#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-object-snapshot-smoke"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectSnapshot.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_object_snapshot_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-object-snapshot-smoke"

SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-object-snapshot-smoke)"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang \
  -std=c11 \
  -DNON_MATCHING=1 \
  -DAVOID_UB=1 \
  -I"$PROJECT_ROOT/include" \
  -I"$PROJECT_ROOT/src" \
  -I"$PROJECT_ROOT" \
  "$PROJECT_ROOT/tests/sm64_modern_object_snapshot_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-object-snapshot-contract"

C_OUTPUT="$($BUILD_ROOT/sm64-modern-object-snapshot-contract)"
printf '%s\n' "$C_OUTPUT"
if [[ "$SWIFT_OUTPUT" != *"$(printf '%s\n' "$C_OUTPUT" | sed -n '1p')"* \
   || "$SWIFT_OUTPUT" != *"$(printf '%s\n' "$C_OUTPUT" | sed -n '2p')"* \
   || "$SWIFT_OUTPUT" != *"$(printf '%s\n' "$C_OUTPUT" | sed -n '3p')"* ]]; then
  echo "Swift/C object snapshot fingerprint mismatch" >&2
  exit 1
fi

printf '%s\n' "SM64 Modern object snapshot C contract matched"
