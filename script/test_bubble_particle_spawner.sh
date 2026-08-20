#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-bubble-particle-spawner"
mkdir -p "$BUILD_ROOT"

xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/BubbleParticleSpawnerBehavior.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_bubble_particle_spawner_smoke.swift" \
  -o "$BUILD_ROOT/smoke"
S="$($BUILD_ROOT/smoke)"
printf '%s\n' "$S"

xcrun clang -std=c11 "$PROJECT_ROOT/tests/sm64_modern_bubble_particle_spawner_contract.c" \
  -o "$BUILD_ROOT/contract"
C="$($BUILD_ROOT/contract)"
printf '%s\n' "$C"

SF="$(printf '%s\n' "$S" | sed -n 's/^bubbleParticleSpawnerFingerprint=//p')"
CF="$(printf '%s\n' "$C" | sed -n 's/^bubbleParticleSpawnerFingerprint=//p')"
[[ -n "$SF" && "$SF" == "$CF" ]] || {
  echo "Swift/C bubble particle spawner fingerprint mismatch: Swift=$SF C=$CF" >&2
  exit 1
}
printf '%s\n' "Swift/C bubble particle spawner contract matched"
