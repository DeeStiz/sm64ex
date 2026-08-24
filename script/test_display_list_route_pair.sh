#!/usr/bin/env bash
set -euo pipefail

# Phase 85az owns one source-authored display-list leaf.  The native owner
# seam is called from geo_append_display_list() for the real wooden-door parent
# and copies only normalized fixed-width values.  This script never mutates
# the route manifest, canonical ledger, or public documentation.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="${SM64_DISPLAY_LIST_ROUTE_BUILD_ROOT:-$PROJECT_ROOT/build/sm64-modern-display-list-route}"
DEBUG_BUILD="$BUILD_ROOT/native-debug"
ASAN_BUILD="$BUILD_ROOT/native-asan"
RELEASE_BUILD="$BUILD_ROOT/native-release"
TOOL_ROOT="$BUILD_ROOT/tool"
RUN_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
mkdir -p "$TOOL_ROOT/module-cache"

clang_contract() {
    local output="$1"
    local archive_root="$2"
    shift 2
    xcrun --sdk macosx clang \
        -std=c11 -Wall -Wextra -Werror \
        -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
        -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
        -I"$archive_root/us_pc" \
        "$PROJECT_ROOT/tests/sm64_modern_display_list_route_pair_contract.c" \
        "$archive_root/us_pc/libsm64core.a" \
        -o "$output" -lm -lpthread "$@"
}

make -C "$PROJECT_ROOT" \
    SM64_MODERN_NATIVE=1 DEBUG=1 \
    BUILD_DIR_BASE="$DEBUG_BUILD" native-core >/dev/null
test -f "$DEBUG_BUILD/us_pc/libsm64core.a"

C_OUTPUT="$TOOL_ROOT/sm64-modern-display-list-route-contract"
clang_contract "$C_OUTPUT" "$DEBUG_BUILD"
C_TRACE="$RUN_ROOT/display-list-c.trace"
C_PACKET="$RUN_ROOT/display-list-c.packet"
C_LOG="$RUN_ROOT/debug.log"
"$C_OUTPUT" "$C_TRACE" "$C_PACKET" >"$C_LOG" 2>&1
grep -Fq 'c_display_list_route_recorded shard=0x00cab93b5dd94425 records=2 ticks=1,2' "$C_LOG"
grep -Fq 'display_list_route_debug oracle_end=0 result_status=0 records=2 invocations=2 matches=2 failures=0' "$C_LOG"
grep -Fq 'display_list_route_owner_fence=1 pointer_free_packet=1' "$C_LOG"
test "$(wc -c <"$C_TRACE" | tr -d '[:space:]')" -eq $((72 + 2 * 128))
test "$(wc -l <"$C_PACKET" | tr -d '[:space:]')" -eq 1

SWIFT_OUTPUT="$TOOL_ROOT/sm64-modern-display-list-route-swift"
xcrun swiftc \
    -parse-as-library -swift-version 6 \
    -Xfrontend -strict-concurrency=complete \
    -module-cache-path "$TOOL_ROOT/module-cache" \
    "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
    "$PROJECT_ROOT/tests/sm64_modern_display_list_route_swift_smoke.swift" \
    -o "$SWIFT_OUTPUT"

SWIFT_TRACE="$RUN_ROOT/display-list-swift.trace"
TAMPERED_TRACE="$RUN_ROOT/display-list-swift.tampered.trace"
SWIFT_LOG="$RUN_ROOT/swift.log"
{
    "$SWIFT_OUTPUT" write "$C_TRACE" "$C_PACKET" "$SWIFT_TRACE"
    "$SWIFT_OUTPUT" audit "$C_TRACE" "$SWIFT_TRACE"
    "$SWIFT_OUTPUT" tamper "$SWIFT_TRACE" "$TAMPERED_TRACE"
} | tee "$SWIFT_LOG"
grep -Fq 'swift_display_list_route_recorded shard=0xcab93b5dd94425 records=2 ticks=1,2 words=4 triangles=4' "$SWIFT_LOG"
grep -Fq 'display_list_pairing_audit admitted=1 c_records=2 swift_records=2 blockers= first_divergence=none' "$SWIFT_LOG"
grep -Fq 'display_list_pairing_tamper_rejected=1' "$SWIFT_LOG"

PARTIAL_TRACE="$RUN_ROOT/display-list-swift.partial.trace"
head -c 200 "$SWIFT_TRACE" >"$PARTIAL_TRACE"
if "$SWIFT_OUTPUT" audit "$C_TRACE" "$PARTIAL_TRACE" >"$RUN_ROOT/partial.log" 2>&1; then
    echo 'display_list_partial_trace_accepted=1' >&2
    exit 1
fi
printf '%s\n' 'display_list_partial_trace_rejected=1'

RERUN_TRACE="$RUN_ROOT/display-list-c-rerun.trace"
RERUN_PACKET="$RUN_ROOT/display-list-c-rerun.packet"
"$C_OUTPUT" "$RERUN_TRACE" "$RERUN_PACKET" >"$RUN_ROOT/rerun.log" 2>&1
cmp -s "$C_TRACE" "$RERUN_TRACE"
cmp -s "$C_PACKET" "$RERUN_PACKET"
printf '%s\n' 'display_list_persistent_rerun_match=1'

make -C "$PROJECT_ROOT" \
    SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
    BUILD_DIR_BASE="$ASAN_BUILD" native-core >/dev/null
test -f "$ASAN_BUILD/us_pc/libsm64core.a"
ASAN_OUTPUT="$TOOL_ROOT/sm64-modern-display-list-route-contract-asan"
clang_contract "$ASAN_OUTPUT" "$ASAN_BUILD" -fsanitize=address
ASAN_TRACE="$RUN_ROOT/display-list-c-asan.trace"
ASAN_PACKET="$RUN_ROOT/display-list-c-asan.packet"
ASAN_LOG="$RUN_ROOT/asan.log"
ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
    "$ASAN_OUTPUT" "$ASAN_TRACE" "$ASAN_PACKET" >"$ASAN_LOG" 2>&1
if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$ASAN_LOG"; then
    echo 'AddressSanitizer emitted a finding despite a zero process status' >&2
    exit 1
fi
cmp -s "$C_TRACE" "$ASAN_TRACE"
cmp -s "$C_PACKET" "$ASAN_PACKET"
printf '%s\n' 'display_list_route_sanitizer_passed=1 debug_asan_trace_match=1 packet_match=1'

make -C "$PROJECT_ROOT" \
    SM64_MODERN_NATIVE=1 DEBUG=0 \
    BUILD_DIR_BASE="$RELEASE_BUILD" native-core >/dev/null
test -f "$RELEASE_BUILD/us_pc/libsm64core.a"
RELEASE_OUTPUT="$TOOL_ROOT/sm64-modern-display-list-route-contract-release"
clang_contract "$RELEASE_OUTPUT" "$RELEASE_BUILD"
RELEASE_TRACE="$RUN_ROOT/display-list-c-release.trace"
RELEASE_PACKET="$RUN_ROOT/display-list-c-release.packet"
RELEASE_LOG="$RUN_ROOT/release.log"
"$RELEASE_OUTPUT" "$RELEASE_TRACE" "$RELEASE_PACKET" >"$RELEASE_LOG" 2>&1
grep -Fq 'display_list_route_debug oracle_end=0 result_status=0 records=2 invocations=2 matches=2 failures=0' "$RELEASE_LOG"
cmp -s "$C_TRACE" "$RELEASE_TRACE"
cmp -s "$C_PACKET" "$RELEASE_PACKET"
printf '%s\n' 'display_list_route_release_passed=1 debug_release_trace_match=1 packet_match=1'

git -c core.fsmonitor=false diff --check
printf '%s\n' \
    'SM64 Modern display-list route pair smoke passed exact_pair=1 tamper_rejected=1' \
    'route_shard=0x00cab93b5dd94425 source=actors/door/model.inc.c identity=door_seg3_dl_03014A20' \
    'owner_boundary=geo_append_display_list parent=door_seg3_dl_03014A80 normalized_words=4 triangles=4' \
    'c_swift_pair=matched first_divergence=none c_asan_release=matched' \
    'gpu_capture=separate visual_pixels=unverified admission=0 ledger_mutation=0 fixture_only=0'
