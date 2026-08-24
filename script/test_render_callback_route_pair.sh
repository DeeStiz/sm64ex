#!/usr/bin/env bash
set -euo pipefail

# Phase 85az owns only the source-authored render_callback|gfx_run route.  The
# C harness reaches gfx_run through lifecycle.step and writes only the callback
# event (render event 6); existing render-packet records remain a separate
# route.  GPU capture, attachment/pixel parity, presentation, and human
# acceptance are intentionally outside this schema-4 value-pair gate.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="${SM64_RENDER_CALLBACK_ROUTE_PAIR_ROOT:-$PROJECT_ROOT/build/sm64-modern-render-callback-route-pair}"
TOOL_ROOT="$BUILD_ROOT/tool"
DEBUG_BUILD="$BUILD_ROOT/native-debug"
ASAN_BUILD="$BUILD_ROOT/native-asan"
RELEASE_BUILD="$BUILD_ROOT/native-release"
C_TRACE="$BUILD_ROOT/render-callback-c.trace"
RERUN_TRACE="$BUILD_ROOT/render-callback-c-rerun.trace"
ASAN_TRACE="$BUILD_ROOT/render-callback-c-asan.trace"
RELEASE_TRACE="$BUILD_ROOT/render-callback-c-release.trace"
SWIFT_TRACE="$BUILD_ROOT/render-callback-swift.trace"
TAMPERED_TRACE="$BUILD_ROOT/render-callback-swift.tampered.trace"
PARTIAL_TRACE="$BUILD_ROOT/render-callback-swift.partial.trace"
DEBUG_LOG="$BUILD_ROOT/debug.log"
RERUN_LOG="$BUILD_ROOT/rerun.log"
ASAN_LOG="$BUILD_ROOT/asan.log"
RELEASE_LOG="$BUILD_ROOT/release.log"
SWIFT_LOG="$BUILD_ROOT/swift.log"

mkdir -p "$TOOL_ROOT/module-cache" "$BUILD_ROOT/save-debug" \
  "$BUILD_ROOT/save-rerun" "$BUILD_ROOT/save-asan" "$BUILD_ROOT/save-release"

clang_contract() {
  local output="$1"
  local archive_root="$2"
  shift 2
  xcrun --sdk macosx clang \
    -std=c11 -Wall -Wextra -Werror \
    -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
    -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
    -I"$archive_root/us_pc" \
    "$PROJECT_ROOT/tests/sm64_modern_render_callback_route_pair_contract.c" \
    "$archive_root/us_pc/libsm64core.a" -o "$output" -lm -lpthread "$@"
}

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 \
  BUILD_DIR_BASE="$DEBUG_BUILD" native-core >/dev/null
clang_contract "$TOOL_ROOT/render-callback-route" "$DEBUG_BUILD"
SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
  "$TOOL_ROOT/render-callback-route" "$C_TRACE" "$BUILD_ROOT/save-debug" debug \
  >"$DEBUG_LOG" 2>&1
grep -Fq 'c_render_callback_route_recorded shard=0xd5a43d537c37e833 identity=src/pc/gfx/gfx_pc.c:1783:gfx_run records=2 ticks=2,3 commands_present=1' "$DEBUG_LOG"
grep -Fq 'render_callback_route_debug oracle_end=0 result_status=0 failures=0 invocations=2 backend_starts=2 backend_finishes=2' "$DEBUG_LOG"
grep -Eq 'coverage=0x[0-9a-f]{16} trace_fingerprint=0x[0-9a-f]{16}' "$DEBUG_LOG"
test "$(wc -c <"$C_TRACE" | tr -d '[:space:]')" -eq 328

# A fresh owner-thread process must reproduce both the callback records and
# their finalized route header.  This is the persistent rerun fence.
SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
  "$TOOL_ROOT/render-callback-route" "$RERUN_TRACE" "$BUILD_ROOT/save-rerun" rerun \
  >"$RERUN_LOG" 2>&1
grep -Fq 'render_callback_route_debug oracle_end=0 result_status=0 failures=0 invocations=2' "$RERUN_LOG"
cmp -s "$C_TRACE" "$RERUN_TRACE"
printf '%s\n' 'render_callback_route_persistent_rerun_passed=1 trace_match=1'

xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_render_callback_route_swift_smoke.swift" \
  -o "$TOOL_ROOT/render-callback-route-swift"
{
  "$TOOL_ROOT/render-callback-route-swift" write "$SWIFT_TRACE"
  "$TOOL_ROOT/render-callback-route-swift" audit "$C_TRACE" "$SWIFT_TRACE"
  "$TOOL_ROOT/render-callback-route-swift" tamper "$SWIFT_TRACE" "$TAMPERED_TRACE"
} | tee "$SWIFT_LOG"
grep -Fq 'swift_render_callback_route_recorded shard=0xd5a43d537c37e833 identity=src/pc/gfx/gfx_pc.c:1783:gfx_run records=2 ticks=2,3 commands_present=1' "$SWIFT_LOG"
grep -Fq 'render_callback_pairing_audit admitted=1 c_records=2 swift_records=2 blockers= first_divergence=none' "$SWIFT_LOG"
grep -Fq 'render_callback_pairing_tamper_rejected=1' "$SWIFT_LOG"

PARTIAL_BYTES=$((72 + 128))
head -c "$PARTIAL_BYTES" "$SWIFT_TRACE" >"$PARTIAL_TRACE"
if "$TOOL_ROOT/render-callback-route-swift" audit "$PARTIAL_TRACE" "$SWIFT_TRACE" \
    >"$BUILD_ROOT/partial.log" 2>&1; then
  echo 'render_callback_partial_trace_rejected=0' >&2
  exit 1
fi
printf '%s\n' 'render_callback_partial_trace_rejected=1'

if "$TOOL_ROOT/render-callback-route-swift" audit "$C_TRACE" "$C_TRACE" \
    >"$BUILD_ROOT/single.log" 2>&1; then
  echo 'render_callback_single_artifact_rejected=0' >&2
  exit 1
fi
printf '%s\n' 'render_callback_single_artifact_rejected=1'

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
  BUILD_DIR_BASE="$ASAN_BUILD" native-core >/dev/null
clang_contract "$TOOL_ROOT/render-callback-route-asan" "$ASAN_BUILD" -fsanitize=address
ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
  SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
  "$TOOL_ROOT/render-callback-route-asan" "$ASAN_TRACE" "$BUILD_ROOT/save-asan" asan \
  >"$ASAN_LOG" 2>&1
if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$ASAN_LOG"; then
  echo 'render callback route emitted an AddressSanitizer finding' >&2
  exit 1
fi
cmp -s "$C_TRACE" "$ASAN_TRACE"
printf '%s\n' 'render_callback_route_sanitizer_passed=1 debug_asan_trace_match=1'

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=0 \
  BUILD_DIR_BASE="$RELEASE_BUILD" native-core >/dev/null
clang_contract "$TOOL_ROOT/render-callback-route-release" "$RELEASE_BUILD"
SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
  "$TOOL_ROOT/render-callback-route-release" "$RELEASE_TRACE" \
  "$BUILD_ROOT/save-release" release >"$RELEASE_LOG" 2>&1
grep -Fq 'render_callback_route_debug oracle_end=0 result_status=0 failures=0 invocations=2' "$RELEASE_LOG"
cmp -s "$C_TRACE" "$RELEASE_TRACE"
printf '%s\n' 'render_callback_route_optimized_passed=1 debug_release_trace_match=1'

git -c core.fsmonitor=false diff --check
printf '%s\n' \
  'SM64 Modern render-callback route pair smoke passed exact_pair=1 tamper_rejected=1' \
  'route_shard=0xd5a43d537c37e833 source=src/pc/gfx/gfx_pc.c:1783:gfx_run' \
  'recipe=authored_lifecycle_step;callback_path=display_and_vsync/send_display_list/gfx_run' \
  'c_swift_pair=matched records=2 ticks=2,3 commands_present=1' \
  'persistent_rerun=matched partial=1 single_artifact=1' \
  'gpu_capture=separate visual_pixels=unverified physical_presentation=unverified human_acceptance=unverified' \
  'admission=0 canonical_ledger_mutation=0 manifest_mutation=0 fixture_only=0'
