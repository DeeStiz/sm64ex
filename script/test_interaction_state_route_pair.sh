#!/usr/bin/env bash
set -euo pipefail

# Phase 85af owns only the canonical oracle_hook|interaction_state row.
# Native Mario interaction state remains authoritative; Swift serializes the
# value-only SM64MarioState boundary. No collision, object, or effect answer
# is synthesized and no route manifest/ledger is mutated here.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-interaction-state-route-pair"
DEBUG_BUILD="$BUILD_ROOT/native-debug"
ASAN_BUILD="$BUILD_ROOT/native-asan"
RELEASE_BUILD="$BUILD_ROOT/native-release"
TOOL_ROOT="$BUILD_ROOT/tool"
C_OUTPUT="$TOOL_ROOT/interaction-state-route-contract"
ASAN_OUTPUT="$TOOL_ROOT/interaction-state-route-contract-asan"
RELEASE_OUTPUT="$TOOL_ROOT/interaction-state-route-contract-release"
SWIFT_OUTPUT="$TOOL_ROOT/interaction-state-route-swift"
C_TRACE="$BUILD_ROOT/interaction-state-c.trace"
ASAN_TRACE="$BUILD_ROOT/interaction-state-c-asan.trace"
RELEASE_TRACE="$BUILD_ROOT/interaction-state-c-release.trace"
SWIFT_TRACE="$BUILD_ROOT/interaction-state-swift.trace"
TAMPERED_TRACE="$BUILD_ROOT/interaction-state-swift.tampered.trace"
SAVE_ROOT="$BUILD_ROOT/save"
ASAN_SAVE_ROOT="$BUILD_ROOT/save-asan"
RELEASE_SAVE_ROOT="$BUILD_ROOT/save-release"
DEBUG_LOG="$BUILD_ROOT/debug.log"
ASAN_LOG="$BUILD_ROOT/asan.log"
RELEASE_LOG="$BUILD_ROOT/release.log"
SWIFT_LOG="$BUILD_ROOT/swift.log"

mkdir -p "$BUILD_ROOT" "$SAVE_ROOT" "$ASAN_SAVE_ROOT" "$RELEASE_SAVE_ROOT" \
  "$TOOL_ROOT/module-cache"

build_native() {
  local build_root="$1"
  shift
  make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 BUILD_DIR_BASE="$build_root" \
    "$@" native-core >/dev/null
  test -f "$build_root/us_pc/libsm64core.a"
}

clang_contract() {
  local output="$1"
  local archive_root="$2"
  shift 2
  xcrun --sdk macosx clang \
    -std=c11 -Wall -Wextra -Werror \
    -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
    -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
    -I"$archive_root/us_pc" \
    "$PROJECT_ROOT/tests/sm64_modern_interaction_state_route_pair_contract.c" \
    "$archive_root/us_pc/libsm64core.a" \
    -o "$output" -lm -lpthread "$@"
}

build_native "$DEBUG_BUILD" DEBUG=1
clang_contract "$C_OUTPUT" "$DEBUG_BUILD"
"$C_OUTPUT" "$C_TRACE" "$SAVE_ROOT" 2>&1 | tee "$DEBUG_LOG"
grep -Fq 'interaction_state_route_init status=0 oracle=0' "$DEBUG_LOG"
grep -Fq 'interaction_state_route_step index=0 status=0 oracle=0 parity=0' "$DEBUG_LOG"
grep -Fq 'interaction_state_route_step index=1 status=0 oracle=0 parity=0' "$DEBUG_LOG"
grep -Eq 'interaction_state_route_debug oracle_end=0 result_status=0 actual=[1-9][0-9]* retained=14 failures=0 ticks=2' "$DEBUG_LOG"
grep -Fq 'c_interaction_state_route_recorded shard=0x3e1cdaca08b21f54' "$DEBUG_LOG"
test "$(wc -c <"$C_TRACE" | tr -d '[:space:]')" -eq $((72 + 14 * 128))

xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" \
  "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" \
  "$PROJECT_ROOT/SM64Modern/InputCore.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/SurfacePartition.swift" \
  "$PROJECT_ROOT/SM64Modern/SurfaceCollision.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioGeometryInput.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioInputCore.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioState.swift" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/InteractionStateMigration.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_interaction_state_route_swift_smoke.swift" \
  -o "$SWIFT_OUTPUT"

{
  "$SWIFT_OUTPUT" write "$SWIFT_TRACE"
  "$SWIFT_OUTPUT" audit "$C_TRACE" "$SWIFT_TRACE"
  "$SWIFT_OUTPUT" tamper "$SWIFT_TRACE" "$TAMPERED_TRACE"
} | tee "$SWIFT_LOG"
grep -Fq 'swift_interaction_state_route_recorded shard=0x3e1cdaca08b21f54 input_seed=0xee187b29391fc62c save_seed=0x7bc40eed25255955 records=14 ticks=2,3 coverage=0x7975fa8afdbc6bcf source_state=SM64MarioState' "$SWIFT_LOG"
grep -Fq 'interaction_state_pairing_audit admitted=1 c_records=14 swift_records=14 blockers= first_divergence=none' "$SWIFT_LOG"
grep -Fq 'interaction_state_pairing_tamper_rejected=1' "$SWIFT_LOG"
cmp -s "$C_TRACE" "$SWIFT_TRACE"

build_native "$ASAN_BUILD" DEBUG=1 SANITIZE=address
clang_contract "$ASAN_OUTPUT" "$ASAN_BUILD" -fsanitize=address
ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
  "$ASAN_OUTPUT" "$ASAN_TRACE" "$ASAN_SAVE_ROOT" >"$ASAN_LOG" 2>&1
if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$ASAN_LOG"; then
  echo 'AddressSanitizer emitted a finding despite a zero process status' >&2
  exit 1
fi
cmp -s "$C_TRACE" "$ASAN_TRACE"
printf '%s\n' 'interaction_state_route_sanitizer_passed=1 debug_asan_trace_match=1'

build_native "$RELEASE_BUILD" DEBUG=0
clang_contract "$RELEASE_OUTPUT" "$RELEASE_BUILD"
"$RELEASE_OUTPUT" "$RELEASE_TRACE" "$RELEASE_SAVE_ROOT" >"$RELEASE_LOG" 2>&1
grep -Eq 'interaction_state_route_debug oracle_end=0 result_status=0 actual=[1-9][0-9]* retained=14 failures=0 ticks=2' "$RELEASE_LOG"
cmp -s "$C_TRACE" "$RELEASE_TRACE"
printf '%s\n' 'interaction_state_route_optimized_passed=1 debug_release_trace_match=1'

git -c core.fsmonitor=false diff --check
printf '%s\n' \
  'SM64 Modern interaction-state route pair smoke passed exact_pair=1 tamper_rejected=1' \
  'native_interaction_domain=4 record_kind=1 ids=200..206 ticks=2,3' \
  'swift_interaction_state=source_backed_value_only owner_thread=1 collision_authority=c' \
  'c_swift_pair=matched first_divergence=none' \
  'admission=0 ledger_mutation=0 fixture_only=0 effects_admitted=0'
