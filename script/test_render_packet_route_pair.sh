#!/usr/bin/env bash
set -euo pipefail

# Phase 85z owns only the canonical oracle_hook|render_packet route.  The
# native gfx_sm64_modern.c wrappers remain authoritative for schema-4 records;
# Swift independently replays the source-backed MetalSceneRecorder recipe.
# This script never mutates the route manifest or cumulative ledger, and GPU
# capture/pixel evidence is intentionally outside this pair gate.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-render-packet-route-pair"
DEBUG_BUILD="$BUILD_ROOT/native-debug"
ASAN_BUILD="$BUILD_ROOT/native-asan"
RELEASE_BUILD="$BUILD_ROOT/native-release"
TOOL_ROOT="$BUILD_ROOT/tool"
C_OUTPUT="$TOOL_ROOT/sm64-modern-render-packet-route-contract"
ASAN_OUTPUT="$TOOL_ROOT/sm64-modern-render-packet-route-contract-asan"
RELEASE_OUTPUT="$TOOL_ROOT/sm64-modern-render-packet-route-contract-release"
SWIFT_OUTPUT="$TOOL_ROOT/sm64-modern-render-packet-route-swift"
C_TRACE="$BUILD_ROOT/render-packet-c.trace"
ASAN_TRACE="$BUILD_ROOT/render-packet-c-asan.trace"
RELEASE_TRACE="$BUILD_ROOT/render-packet-c-release.trace"
SWIFT_TRACE="$BUILD_ROOT/render-packet-swift.trace"
TAMPERED_TRACE="$BUILD_ROOT/render-packet-swift.tampered.trace"
DEBUG_LOG="$BUILD_ROOT/debug.log"
ASAN_LOG="$BUILD_ROOT/asan.log"
RELEASE_LOG="$BUILD_ROOT/release.log"
SWIFT_LOG="$BUILD_ROOT/swift.log"

mkdir -p "$BUILD_ROOT" "$TOOL_ROOT/module-cache"

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=1 \
  BUILD_DIR_BASE="$DEBUG_BUILD" native-core >/dev/null
test -f "$DEBUG_BUILD/us_pc/libsm64core.a"

clang_contract() {
  local output="$1"
  local archive_root="$2"
  shift 2
  xcrun --sdk macosx clang \
    -std=c11 -Wall -Wextra -Werror \
    -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
    -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
    -I"$archive_root/us_pc" \
    "$PROJECT_ROOT/tests/sm64_modern_render_packet_route_pair_contract.c" \
    "$archive_root/us_pc/libsm64core.a" \
    -o "$output" -lm -lpthread "$@"
}

clang_contract "$C_OUTPUT" "$DEBUG_BUILD"
"$C_OUTPUT" "$C_TRACE" >"$DEBUG_LOG" 2>&1
grep -Fq 'c_render_packet_route_recorded shard=0x149fe4b1ab8a36a5 records=8 ticks=1,2' "$DEBUG_LOG"
grep -Eq 'coverage=0x[0-9a-f]{16} trace_fingerprint=0x[0-9a-f]{16}' "$DEBUG_LOG"
grep -Fq 'render_packet_route_debug oracle_end=0 result_status=0 failures=0 initialize=1 shutdown=1' "$DEBUG_LOG"
test "$(wc -c <"$C_TRACE" | tr -d '[:space:]')" -eq 1096

xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/MetalScene.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_render_packet_route_swift_smoke.swift" \
  -o "$SWIFT_OUTPUT"

{
  "$SWIFT_OUTPUT" write "$SWIFT_TRACE"
  "$SWIFT_OUTPUT" audit "$C_TRACE" "$SWIFT_TRACE"
  "$SWIFT_OUTPUT" tamper "$SWIFT_TRACE" "$TAMPERED_TRACE"
} | tee "$SWIFT_LOG"
grep -Fq 'swift_render_packet_route_recorded shard=0x149fe4b1ab8a36a5 records=8 ticks=1,2 events=draw,frame_begin,frame_end,finish packets=2' "$SWIFT_LOG"
grep -Fq 'render_packet_pairing_audit admitted=1 c_records=8 swift_records=8 blockers= first_divergence=none' "$SWIFT_LOG"
grep -Fq 'render_packet_pairing_tamper_rejected=1' "$SWIFT_LOG"
grep -Fq 'trace_fingerprint=0xbe06aea756ec0b08' "$SWIFT_LOG"

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
  BUILD_DIR_BASE="$ASAN_BUILD" native-core >/dev/null
test -f "$ASAN_BUILD/us_pc/libsm64core.a"
clang_contract "$ASAN_OUTPUT" "$ASAN_BUILD" -fsanitize=address
ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
  "$ASAN_OUTPUT" "$ASAN_TRACE" >"$ASAN_LOG" 2>&1
if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$ASAN_LOG"; then
  echo 'AddressSanitizer emitted a finding despite a zero process status' >&2
  exit 1
fi
cmp -s "$C_TRACE" "$ASAN_TRACE"
printf '%s\n' 'render_packet_route_sanitizer_passed=1 debug_asan_trace_match=1'

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=0 \
  BUILD_DIR_BASE="$RELEASE_BUILD" native-core >/dev/null
test -f "$RELEASE_BUILD/us_pc/libsm64core.a"
clang_contract "$RELEASE_OUTPUT" "$RELEASE_BUILD"
"$RELEASE_OUTPUT" "$RELEASE_TRACE" >"$RELEASE_LOG" 2>&1
grep -Fq 'render_packet_route_debug oracle_end=0 result_status=0 failures=0' "$RELEASE_LOG"
cmp -s "$C_TRACE" "$RELEASE_TRACE"
printf '%s\n' 'render_packet_route_optimized_passed=1 debug_release_trace_match=1'

git -c core.fsmonitor=false diff --check
printf '%s\n' \
  'SM64 Modern render-packet route pair smoke passed exact_pair=1 tamper_rejected=1' \
  'native_render_authority=c_gfx_sm64_modern_wrappers batch_owner=1 records=8 ticks=1,2' \
  'swift_scene_snapshot=MetalSceneRecorder immutable_packet=1 current_texture_tile=1' \
  'c_swift_pair=matched first_divergence=none' \
  'gpu_capture=separate visual_pixels=unverified admission=0 ledger_mutation=0 fixture_only=0'
