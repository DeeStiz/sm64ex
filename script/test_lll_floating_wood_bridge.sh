#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-lll-floating-wood-bridge"
mkdir -p "$BUILD_ROOT"
xcrun swiftc -parse-as-library -swift-version 6 -Xfrontend -strict-concurrency=complete -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" \
  "$PROJECT_ROOT/SM64Modern/LllWoodPieceBehavior.swift" "$PROJECT_ROOT/SM64Modern/LllFloatingWoodBridgeBehavior.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_lll_floating_wood_bridge_smoke.swift" -o "$BUILD_ROOT/smoke"
S="$($BUILD_ROOT/smoke)"; printf '%s\n' "$S"
xcrun clang -std=c11 -ffp-contract=off "$PROJECT_ROOT/tests/sm64_modern_lll_floating_wood_bridge_contract.c" -o "$BUILD_ROOT/contract"
C="$($BUILD_ROOT/contract)"; printf '%s\n' "$C"
SF="$(printf '%s\n' "$S" | sed -n 's/^lllFloatingWoodBridgeFingerprint=//p')"
CF="$(printf '%s\n' "$C" | sed -n 's/^lllFloatingWoodBridgeFingerprint=//p')"
[[ -n "$SF" && "$SF" == "$CF" ]] || { echo "Swift/C wood bridge fingerprint mismatch: Swift=$SF C=$CF" >&2; exit 1; }
printf '%s\n' "SM64 Modern LLL floating wood bridge C contract matched"
