#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-water-air-bubble"
mkdir -p "$BUILD_ROOT"
xcrun swiftc -parse-as-library -swift-version 6 -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" \
  "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/WaterAirBubbleBehavior.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_water_air_bubble_smoke.swift" -o "$BUILD_ROOT/smoke"
SWIFT_OUTPUT="$($BUILD_ROOT/smoke)"; printf '%s\n' "$SWIFT_OUTPUT"
xcrun clang -std=c11 -ffp-contract=off "$PROJECT_ROOT/tests/sm64_modern_water_air_bubble_contract.c" -lm -o "$BUILD_ROOT/contract"
C_OUTPUT="$($BUILD_ROOT/contract)"; printf '%s\n' "$C_OUTPUT"
SF="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^waterAirBubbleFingerprint=//p')"
CF="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^waterAirBubbleFingerprint=//p')"
[[ -n "$SF" && "$SF" == "$CF" ]] || { echo "Swift/C water-air bubble fingerprint mismatch: Swift=$SF C=$CF" >&2; exit 1; }
printf '%s\n' "Swift/C water-air bubble contract matched"
