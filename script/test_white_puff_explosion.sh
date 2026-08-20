#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-white-puff-explosion"
mkdir -p "$BUILD_ROOT/module-cache"
xcrun swiftc -parse-as-library -swift-version 6 -Xfrontend -strict-concurrency=complete -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/WhitePuffExplosionBehavior.swift" "$PROJECT_ROOT/tests/sm64_modern_white_puff_explosion_smoke.swift" -o "$BUILD_ROOT/smoke"
swift_output="$($BUILD_ROOT/smoke)"; printf '%s\n' "$swift_output"
xcrun clang -std=c11 "$PROJECT_ROOT/tests/sm64_modern_white_puff_explosion_contract.c" -o "$BUILD_ROOT/contract"
c_output="$($BUILD_ROOT/contract)"; printf '%s\n' "$c_output"
swift_fingerprint="$(printf '%s\n' "$swift_output" | sed -n 's/^whitePuffExplosionFingerprint=//p')"
c_fingerprint="$(printf '%s\n' "$c_output" | sed -n 's/^whitePuffExplosionFingerprint=//p')"
[[ -n "$swift_fingerprint" && "$swift_fingerprint" == "$c_fingerprint" ]] || { echo "Swift/C white puff explosion fingerprint mismatch: Swift=$swift_fingerprint C=$c_fingerprint" >&2; exit 1; }
printf '%s\n' "Swift/C white puff explosion contract matched"
