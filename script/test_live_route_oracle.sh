#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-live-route-oracle"
MODE="${1:-full}"
case "$MODE" in
  full|input-only) ;;
  *)
    echo "usage: $0 [full|input-only]" >&2
    exit 2
    ;;
esac
mkdir -p "$BUILD_ROOT"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/EngineAuthority.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/MemoryArena.swift" \
  "$PROJECT_ROOT/SM64Modern/EngineState.swift" \
  "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" \
  "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectTransform.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectScheduler.swift" \
  "$PROJECT_ROOT/SM64Modern/ProgressionState.swift" \
  "$PROJECT_ROOT/SM64Modern/ProgressionActors.swift" \
  "$PROJECT_ROOT/SM64Modern/SaveFileCodec.swift" \
  "$PROJECT_ROOT/SM64Modern/CoinScoreAges.swift" \
  "$PROJECT_ROOT/SM64Modern/ProgressionPersistence.swift" \
  "$PROJECT_ROOT/SM64Modern/ProgressionRuntime.swift" \
  "$PROJECT_ROOT/SM64Modern/InputCore.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioInputCore.swift" \
  "$PROJECT_ROOT/SM64Modern/SurfacePartition.swift" \
  "$PROJECT_ROOT/SM64Modern/SurfaceCollision.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioGeometryInput.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioState.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioAction.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioActionCancels.swift" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/ChainChompRelease.swift" \
  "$PROJECT_ROOT/SM64Modern/ChainChompReleaseObjectBridge.swift" \
  "$PROJECT_ROOT/SM64Modern/OwnerThreadEffectRouter.swift" \
  "$PROJECT_ROOT/SM64Modern/Respawner.swift" \
  "$PROJECT_ROOT/SM64Modern/RespawnerObjectBridge.swift" \
  "$PROJECT_ROOT/SM64Modern/DecorativePendulumBehavior.swift" \
  "$PROJECT_ROOT/SM64Modern/DecorativePendulumObjectBridge.swift" \
  "$PROJECT_ROOT/SM64Modern/BehaviorDispatchBridge.swift" \
  "$PROJECT_ROOT/SM64Modern/AmpEnemy.swift" \
  "$PROJECT_ROOT/SM64Modern/AmpObjectBridge.swift" \
  "$PROJECT_ROOT/SM64Modern/BooEnemy.swift" \
  "$PROJECT_ROOT/SM64Modern/BooObjectBridge.swift" \
  "$PROJECT_ROOT/SM64Modern/EngineRuntime.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_live_route_oracle_smoke.swift" \
  -o "$BUILD_ROOT/sm64-modern-live-route-oracle-smoke"
xcrun --sdk macosx clang \
  -std=c11 \
  -Wall \
  -Wextra \
  -Werror \
  -mmacosx-version-min=27.0 \
  -I"$PROJECT_ROOT/include" \
  "$PROJECT_ROOT/src/pc/sm64_modern_oracle_trace.c" \
  "$PROJECT_ROOT/tests/sm64_modern_live_route_oracle_contract.c" \
  -o "$BUILD_ROOT/sm64-modern-live-route-oracle-contract"

TRACE_PATH="$BUILD_ROOT/$MODE.trace"
SWIFT_ARGS=("$TRACE_PATH")
C_ARGS=("$TRACE_PATH")
if [[ "$MODE" == "input-only" ]]; then
  SWIFT_ARGS+=(--input-only)
  C_ARGS+=(--input-only)
fi
"$BUILD_ROOT/sm64-modern-live-route-oracle-smoke" "${SWIFT_ARGS[@]}" | tee "$BUILD_ROOT/$MODE-swift-output.log"
"$BUILD_ROOT/sm64-modern-live-route-oracle-contract" "${C_ARGS[@]}"
if [[ "$MODE" == "full" ]]; then
  "$BUILD_ROOT/sm64-modern-live-route-oracle-contract" "$TRACE_PATH" --tamper
  printf 'SM64 Modern live route oracle smoke passed mode=full c_swift_replay=1 first_divergence=3\n'
else
  printf 'SM64 Modern live route oracle smoke passed mode=input-only c_swift_replay=1 records=1\n'
fi
