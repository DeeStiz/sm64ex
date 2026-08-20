#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-squishable-platform"
mkdir -p "$BUILD_ROOT"
xcrun swiftc -parse-as-library -swift-version 6 -Xfrontend -strict-concurrency=complete -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" \
  "$PROJECT_ROOT/SM64Modern/SquishablePlatformBehavior.swift" "$PROJECT_ROOT/tests/sm64_modern_squishable_platform_smoke.swift" -o "$BUILD_ROOT/smoke"
S="$($BUILD_ROOT/smoke)"; printf '%s\n' "$S"
xcrun clang -std=c11 -ffp-contract=off "$PROJECT_ROOT/tests/sm64_modern_squishable_platform_contract.c" -o "$BUILD_ROOT/contract"
C="$($BUILD_ROOT/contract)"; printf '%s\n' "$C"
SF="$(printf '%s\n' "$S" | sed -n 's/^squishablePlatformFingerprint=//p')"
CF="$(printf '%s\n' "$C" | sed -n 's/^squishablePlatformFingerprint=//p')"
[[ -n "$SF" && "$SF" == "$CF" ]] || { echo "Swift/C squishable fingerprint mismatch: Swift=$SF C=$CF" >&2; exit 1; }
printf '%s\n' "SM64 Modern squishable platform C contract matched"
