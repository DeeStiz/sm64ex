#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-behavior-dispatch-bridge"
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" \
  "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/MemoryArena.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectTransform.swift" \
  "$PROJECT_ROOT/SM64Modern/EngineState.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectScheduler.swift" \
  "$PROJECT_ROOT/SM64Modern/ChainChompRelease.swift" \
  "$PROJECT_ROOT/SM64Modern/ChainChompReleaseObjectBridge.swift" \
  "$PROJECT_ROOT/SM64Modern/OwnerThreadEffectRouter.swift" \
  "$PROJECT_ROOT/SM64Modern/Respawner.swift" \
  "$PROJECT_ROOT/SM64Modern/RespawnerObjectBridge.swift" \
  "$PROJECT_ROOT/SM64Modern/DecorativePendulumBehavior.swift" \
  "$PROJECT_ROOT/SM64Modern/DecorativePendulumObjectBridge.swift" \
  "$PROJECT_ROOT/SM64Modern/BehaviorDispatchBridge.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_behavior_dispatch_bridge_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-behavior-dispatch-bridge-smoke"
SWIFT_OUTPUT="$($BUILD_ROOT/sm64-modern-behavior-dispatch-bridge-smoke)"
printf '%s\n' "$SWIFT_OUTPUT"

xcrun clang -std=c11 \
  "$PROJECT_ROOT/tests/sm64_modern_behavior_dispatch_bridge_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-behavior-dispatch-bridge-contract"
C_OUTPUT="$($BUILD_ROOT/sm64-modern-behavior-dispatch-bridge-contract)"
printf '%s\n' "$C_OUTPUT"

SWIFT_FINGERPRINT="$(printf '%s\n' "$SWIFT_OUTPUT" | sed -n 's/^behaviorDispatchBridgeFingerprint=//p')"
C_FINGERPRINT="$(printf '%s\n' "$C_OUTPUT" | sed -n 's/^behaviorDispatchBridgeFingerprint=//p')"
[[ -n "$SWIFT_FINGERPRINT" && "$SWIFT_FINGERPRINT" == "$C_FINGERPRINT" ]] || {
  echo "Swift/C behavior dispatch bridge fingerprint mismatch: Swift=$SWIFT_FINGERPRINT C=$C_FINGERPRINT" >&2
  exit 1
}
printf '%s\n' "Swift/C behavior dispatch bridge contract matched"
