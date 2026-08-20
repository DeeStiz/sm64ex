#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-snowman-bottom"
mkdir -p "$BUILD_ROOT/module-cache"
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" \
  "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" \
  "$PROJECT_ROOT/SM64Modern/MemoryArena.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectTransform.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/EngineState.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectScheduler.swift" \
  "$PROJECT_ROOT/SM64Modern/SnowmanCheckpointBehavior.swift" \
  "$PROJECT_ROOT/SM64Modern/SnowmanCheckpointObjectBridge.swift" \
  "$PROJECT_ROOT/SM64Modern/SnowmanBottomBehavior.swift" \
  "$PROJECT_ROOT/SM64Modern/SnowmanBottomObjectBridge.swift" \
  "$PROJECT_ROOT/SM64Modern/SnowmanBottomRouteOwner.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_snowman_bottom_smoke.swift" \
  -o "$BUILD_ROOT/smoke"
swift_output="$($BUILD_ROOT/smoke)"
printf '%s\n' "$swift_output"
xcrun clang -std=c11 \
  "$PROJECT_ROOT/tests/sm64_modern_snowman_bottom_contract.c" \
  -o "$BUILD_ROOT/contract"
c_output="$($BUILD_ROOT/contract)"
printf '%s\n' "$c_output"
swift_fingerprint="$(printf '%s\n' "$swift_output" | sed -n 's/^snowmanBottomFingerprint=//p')"
c_fingerprint="$(printf '%s\n' "$c_output" | sed -n 's/^snowmanBottomFingerprint=//p')"
[[ -n "$swift_fingerprint" && "$swift_fingerprint" == "$c_fingerprint" ]] || {
  echo "Snowman bottom mismatch Swift=$swift_fingerprint C=$c_fingerprint" >&2
  exit 1
}
grep -Fqx 'SM64 Modern snowman bottom smoke passed' <<<"$swift_output"
grep -Fqx 'SM64 Modern snowman bottom C contract passed' <<<"$c_output"
printf '%s\n' 'Swift/C snowman bottom contract matched'
