#!/usr/bin/env bash
set -euo pipefail

# Run the real C owner lifecycle for the generated Mario-state route. This
# deliberately proves only the native side; Swift pairing and route admission
# remain independent gates until a source-backed Swift trace matches these
# bytes.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-mario-state-route-pair"
NATIVE_BUILD="$PROJECT_ROOT/build/sm64-modern-debug/us_pc"
OUTPUT="$BUILD_ROOT/sm64-modern-mario-state-route-contract"
TRACE="$BUILD_ROOT/mario-state-c.trace"
SWIFT_OUTPUT="$BUILD_ROOT/sm64-modern-mario-state-route-swift"
SWIFT_TRACE="$BUILD_ROOT/mario-state-swift.trace"
SWIFT_TAMPERED_TRACE="$BUILD_ROOT/mario-state-swift.tampered.trace"
SAVE_ROOT="$BUILD_ROOT/save"
LOG="$BUILD_ROOT/native.log"

mkdir -p "$BUILD_ROOT" "$SAVE_ROOT"

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 \
  DEBUG=1 \
  BUILD_DIR_BASE="$PROJECT_ROOT/build/sm64-modern-debug" \
  native-core >/dev/null
test -f "$NATIVE_BUILD/libsm64core.a"

xcrun --sdk macosx clang \
  -std=c11 \
  -Wall \
  -Wextra \
  -Werror \
  -DNON_MATCHING=1 \
  -DAVOID_UB=1 \
  -mmacosx-version-min=27.0 \
  -I"$PROJECT_ROOT" \
  -I"$PROJECT_ROOT/include" \
  -I"$PROJECT_ROOT/src" \
  -I"$NATIVE_BUILD" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_state_route_pair_contract.c" \
  "$NATIVE_BUILD/libsm64core.a" \
  -o "$OUTPUT" \
  -lm \
  -lpthread

"$OUTPUT" "$TRACE" "$SAVE_ROOT" 2>&1 | tee "$LOG"
grep -Fq 'mario_state_route_init status=0 oracle=0' "$LOG"
grep -Fq 'mario_state_route_step index=0 status=0 oracle=0 parity=0' "$LOG"
grep -Fq 'mario_state_route_step index=1 status=0 oracle=0 parity=0' "$LOG"
grep -Fq 'mario_state_route_debug oracle_end=0 result_status=0' "$LOG"
grep -Eq 'c_mario_state_route_recorded .* records=38 ticks=3 .* coverage=0x[0-9a-f]{16}' "$LOG"
test -s "$TRACE"

# The C owner emits the fixed schema-4 header and 38 complete domain-2/state
# records (19 inventory IDs across two gameplay ticks).
TRACE_HEADER_HEX="$(od -An -tx1 -N8 "$TRACE" | tr -d '[:space:]')"
test "$TRACE_HEADER_HEX" = "0100000048000000"
TRACE_BYTES="$(wc -c < "$TRACE" | tr -d '[:space:]')"
test "$TRACE_BYTES" -eq $((72 + 38 * 128))

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" \
  "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" \
  "$PROJECT_ROOT/SM64Modern/InputCore.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/SurfacePartition.swift" \
  "$PROJECT_ROOT/SM64Modern/SurfaceCollision.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioGeometryInput.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioGroundStep.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioAirStep.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioInputCore.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioState.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioAction.swift" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_state_route_swift_smoke.swift" \
  -o "$SWIFT_OUTPUT"

SWIFT_LOG="$BUILD_ROOT/swift.log"
{
  "$SWIFT_OUTPUT" write "$SWIFT_TRACE"
  "$SWIFT_OUTPUT" audit "$TRACE" "$SWIFT_TRACE"
  "$SWIFT_OUTPUT" tamper "$SWIFT_TRACE" "$SWIFT_TAMPERED_TRACE"
} | tee "$SWIFT_LOG"
grep -Fq 'swift_mario_state_route_recorded' "$SWIFT_LOG"
grep -Fq 'records=38 ticks=2,3 coverage=0x67446c5f2e231b25' "$SWIFT_LOG"
grep -Fq 'mario_state_pairing_audit admitted=1 c_records=38 swift_records=38 blockers= first_divergence=none' "$SWIFT_LOG"
grep -Fq 'mario_state_pairing_tamper_rejected=1' "$SWIFT_LOG"

git -c core.fsmonitor=false diff --check
printf '%s\n' \
  'SM64 Modern Mario-state native route repair smoke passed' \
  'native_initialization_tick=1 status4_poisoning=0' \
  'domain2_state_records=38 ids=100..118 ticks=2,3 sequence=canonical' \
  'coverage_finalized=1 swift_trace=38_records swift_pairing=exact_bytes tamper_rejected=1 ledger_mutation=0'
