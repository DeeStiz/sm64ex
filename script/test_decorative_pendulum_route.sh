#!/usr/bin/env bash
set -euo pipefail

bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/sm64-decorative-pendulum-route.XXXXXX")"
PACK_TOOL="$BUILD_ROOT/content-pack"
PACK="$BUILD_ROOT/source-only.cpk"
ROUTE_TOOL="$BUILD_ROOT/route-smoke"
TRACE="$BUILD_ROOT/swift-source-route.trace"

mkdir -p "$BUILD_ROOT/module-cache"
xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/ContentPack.swift" \
  "$PROJECT_ROOT/tools/SM64ContentPackTool.swift" \
  -o "$PACK_TOOL"

"$PACK_TOOL" build \
  --root "$PROJECT_ROOT" \
  --output "$PACK" \
  --source-only \
  >"$BUILD_ROOT/content-pack.log"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/ContentPack.swift" \
  "$PROJECT_ROOT/SM64Modern/ContentPackRuntime.swift" \
  "$PROJECT_ROOT/SM64Modern/BehaviorScript.swift" \
  "$PROJECT_ROOT/SM64Modern/BehaviorScriptVM.swift" \
  "$PROJECT_ROOT/SM64Modern/BehaviorScriptContentRuntime.swift" \
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
  "$PROJECT_ROOT/SM64Modern/SurfacePartition.swift" \
  "$PROJECT_ROOT/SM64Modern/SurfaceCollision.swift" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/DecorativePendulumBehavior.swift" \
  "$PROJECT_ROOT/SM64Modern/DecorativePendulumObjectBridge.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_decorative_pendulum_route_smoke.swift" \
  -o "$ROUTE_TOOL"

"$ROUTE_TOOL" \
  "$PACK" \
  "$PROJECT_ROOT/data/behavior_data.c" \
  "$PROJECT_ROOT/levels/castle_inside/areas/2/collision.inc.c" \
  "$PROJECT_ROOT/levels/castle_inside/areas/2/room.inc.c" \
  "$PROJECT_ROOT/levels/castle_inside/script.c" \
  "$TRACE" \
  40 \
  | tee "$BUILD_ROOT/swift-route.log"

grep -Fq 'source_program_commands=6' "$BUILD_ROOT/swift-route.log"
grep -Fq 'domains=3,6,7,12' "$BUILD_ROOT/swift-route.log"
grep -Fq 'collision_surfaces=' "$BUILD_ROOT/swift-route.log"
[[ -s "$TRACE" ]] || { echo "source-backed Swift trace was not emitted" >&2; exit 1; }

# The central C route still has no source-backed Castle Inside area-2 object
# loader/owner that can emit the same four domains. Keep the capture useful as
# a diagnostic, but fail closed before any C/Swift pairing or promotion.
printf '%s\n' \
  'SM64 Modern decorative pendulum route attempt complete' \
  'source_inputs=behavior_data.c,castle_inside_area2_collision,castle_inside_area2_rooms,castle_inside_script' \
  'swift_source_route_capture=1' \
  'c_live_route=blocked reason=no_native_area2_object_owner_or_schema4_pendulum_emitter' \
  'independent_c_swift_pair=0 exact_bytes=0 replay=0 tamper=0 worker_result=0 merge=0 persistent_rerun_fence=0' \
  'canonical_route_admission=0 promotion=not_attempted ledger_mutation=0 fixture_only=0'

git -c core.fsmonitor=false diff --check
