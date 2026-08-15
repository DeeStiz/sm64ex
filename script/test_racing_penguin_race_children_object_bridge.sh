#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-racing-penguin-race-children-object-bridge"
mkdir -p "$BUILD_ROOT"

xcrun swiftc -parse-as-library -swift-version 6 -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" \
  "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/MemoryArena.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectTransform.swift" \
  "$PROJECT_ROOT/SM64Modern/EngineState.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectScheduler.swift" \
  "$PROJECT_ROOT/SM64Modern/RacingPenguinBehavior.swift" \
  "$PROJECT_ROOT/SM64Modern/RacingPenguinRaceChildren.swift" \
  "$PROJECT_ROOT/SM64Modern/RacingPenguinObjectBridge.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_racing_penguin_race_children_object_bridge_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-racing-penguin-race-children-object-bridge-smoke"
SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-racing-penguin-race-children-object-bridge-smoke)"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang -std=c11 -ffp-contract=off \
  "$PROJECT_ROOT/tests/sm64_modern_racing_penguin_race_children_object_bridge_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-racing-penguin-race-children-object-bridge-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-racing-penguin-race-children-object-bridge-contract)"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^racingPenguinRaceChildrenObjectBridgeFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^racingPenguinRaceChildrenObjectBridgeFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C racing penguin race-children object bridge fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "SM64 Modern racing penguin race-children object bridge C contract matched"
