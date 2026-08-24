#!/usr/bin/env bash
set -euo pipefail

# Phase 85ax uses the source-bound observer at camera.c:788.  The recipe is
# real lifecycle input/content (Bob-omb area 1, authored radial camera, A
# pulses through the act selector); no direct camera/find_floor invocation,
# fixture record, manifest edit, or canonical ledger mutation is allowed.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -n "${SM64_CAMERA_FIND_FLOOR_PAIR_ROOT:-}" ]]; then
  BUILD_ROOT="$SM64_CAMERA_FIND_FLOOR_PAIR_ROOT"
else
  # Never reuse generated objects, configs, or traces from another dirty
  # source snapshot.  Admission callers provide their own isolated root;
  # direct focused runs receive the same fresh-root guarantee.
  BUILD_PARENT="$PROJECT_ROOT/build/sm64-modern-camera-find-floor-route-pair"
  mkdir -p "$BUILD_PARENT"
  BUILD_ROOT="$(mktemp -d "$BUILD_PARENT/run.XXXXXX")"
fi
TOOL_ROOT="$BUILD_ROOT/tool"
DEBUG_BUILD="$BUILD_ROOT/native-debug"
ASAN_BUILD="$BUILD_ROOT/native-asan"
RELEASE_BUILD="$BUILD_ROOT/native-release"
C_TRACE="$BUILD_ROOT/camera-find-floor-c.trace"
ASAN_TRACE="$BUILD_ROOT/camera-find-floor-c-asan.trace"
RELEASE_TRACE="$BUILD_ROOT/camera-find-floor-c-release.trace"
RERUN_TRACE="$BUILD_ROOT/camera-find-floor-c-rerun.trace"
SWIFT_TRACE="$BUILD_ROOT/camera-find-floor-swift.trace"
TAMPERED_TRACE="$BUILD_ROOT/camera-find-floor-swift.tampered.trace"
PARTIAL_TRACE="$BUILD_ROOT/camera-find-floor-swift.partial.trace"
DEBUG_LOG="$BUILD_ROOT/debug.log"
ASAN_LOG="$BUILD_ROOT/asan.log"
RELEASE_LOG="$BUILD_ROOT/release.log"
RERUN_LOG="$BUILD_ROOT/rerun.log"
SWIFT_LOG="$BUILD_ROOT/swift.log"

mkdir -p "$TOOL_ROOT/module-cache" "$BUILD_ROOT/save-debug" \
  "$BUILD_ROOT/save-asan" "$BUILD_ROOT/save-release"

clang_contract() {
  local output="$1"
  local archive_root="$2"
  shift 2
  xcrun --sdk macosx clang \
    -std=c11 -Wall -Wextra -Werror \
    -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
    -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
    -I"$archive_root/us_pc" \
    "$PROJECT_ROOT/tests/sm64_modern_camera_find_floor_route_pair_contract.c" \
    "$archive_root/us_pc/libsm64core.a" -o "$output" -lm -lpthread "$@"
}

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 \
  BUILD_DIR_BASE="$DEBUG_BUILD" native-core >/dev/null
clang_contract "$TOOL_ROOT/camera-find-floor-route" "$DEBUG_BUILD"
SM64_MODERN_AUTOMATED_BOBOMB=1 \
  "$TOOL_ROOT/camera-find-floor-route" "$C_TRACE" \
  "$BUILD_ROOT/save-debug" debug >"$DEBUG_LOG" 2>&1
grep -Fq 'camera_find_floor_route_init variant=debug status=0' "$DEBUG_LOG"
grep -Fq 'camera_find_floor_route_step variant=debug index=0 status=0' "$DEBUG_LOG"
grep -Fq 'camera_find_floor_route_step variant=debug index=1 status=0' "$DEBUG_LOG"
grep -Fq 'camera_mode=1' "$DEBUG_LOG"
grep -Fq 'camera_find_floor_route_debug variant=debug oracle_end=0 result_status=0' "$DEBUG_LOG"
grep -Fq 'retained=30 retained_object=28 retained_identity=2 object_subject=0x0000000000000001' "$DEBUG_LOG"
grep -Fq 'first_tick=92 last_tick=93 coverage=0x1c41224c64ab005f' "$DEBUG_LOG"
grep -Fq 'c_camera_find_floor_route_recorded shard=0x1e3500f9eb2b95d4' "$DEBUG_LOG"

# A second owner-thread process must reproduce the complete oracle inventory
# fingerprint and retained bytes.  This catches the earlier
# 0x1c41224c64ab005f -> 0x9a76a4bb357f867e drift before any admission report
# can be created.
SM64_MODERN_AUTOMATED_BOBOMB=1 \
  "$TOOL_ROOT/camera-find-floor-route" "$RERUN_TRACE" \
  "$BUILD_ROOT/save-rerun" debug-rerun >"$RERUN_LOG" 2>&1
grep -Fq 'camera_find_floor_route_init variant=debug-rerun status=0' "$RERUN_LOG"
grep -Fq 'camera_find_floor_route_debug variant=debug-rerun oracle_end=0 result_status=0' "$RERUN_LOG"
grep -Fq 'actual=11391 all_records=11391 collision=343 identity_records=2 object_state=5796 retained=30 retained_object=28 retained_identity=2' "$RERUN_LOG"
grep -Fq 'first_tick=92 last_tick=93 coverage=0x1c41224c64ab005f' "$RERUN_LOG"
cmp -s "$C_TRACE" "$RERUN_TRACE"
printf '%s\n' 'camera_find_floor_route_persistent_rerun_passed=1 trace_match=1 coverage_match=1'

xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_camera_find_floor_route_swift_smoke.swift" \
  -o "$TOOL_ROOT/camera-find-floor-route-swift"
{
  "$TOOL_ROOT/camera-find-floor-route-swift" write "$SWIFT_TRACE"
  "$TOOL_ROOT/camera-find-floor-route-swift" audit "$C_TRACE" "$SWIFT_TRACE"
  "$TOOL_ROOT/camera-find-floor-route-swift" tamper "$SWIFT_TRACE" "$TAMPERED_TRACE"
} | tee "$SWIFT_LOG"
grep -Fq 'camera_find_floor_pairing_audit admitted=1 c_records=30 swift_records=30 blockers= first_divergence=none' "$SWIFT_LOG"
grep -Fq 'camera_find_floor_pairing_tamper_rejected=1' "$SWIFT_LOG"

PARTIAL_BYTES=$((72 + 29 * 128))
head -c "$PARTIAL_BYTES" "$SWIFT_TRACE" >"$PARTIAL_TRACE"
if "$TOOL_ROOT/camera-find-floor-route-swift" audit "$PARTIAL_TRACE" "$SWIFT_TRACE" \
  >"$BUILD_ROOT/partial.log" 2>&1; then
  echo 'partial_trace_rejected=0' >&2
  exit 1
fi
printf '%s\n' 'partial_trace_rejected=1'

if "$TOOL_ROOT/camera-find-floor-route-swift" audit "$C_TRACE" "$C_TRACE" \
  >"$BUILD_ROOT/single.log" 2>&1; then
  echo 'single_artifact_rejected=0' >&2
  exit 1
fi
printf '%s\n' 'single_artifact_rejected=1'

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
  BUILD_DIR_BASE="$ASAN_BUILD" native-core >/dev/null
clang_contract "$TOOL_ROOT/camera-find-floor-route-asan" "$ASAN_BUILD" -fsanitize=address
ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
  SM64_MODERN_AUTOMATED_BOBOMB=1 \
  "$TOOL_ROOT/camera-find-floor-route-asan" "$ASAN_TRACE" \
  "$BUILD_ROOT/save-asan" asan >"$ASAN_LOG" 2>&1
if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$ASAN_LOG"; then
  echo 'camera find-floor route emitted an AddressSanitizer finding' >&2
  exit 1
fi
cmp -s "$C_TRACE" "$ASAN_TRACE"
printf '%s\n' 'camera_find_floor_route_sanitizer_passed=1 debug_asan_trace_match=1'

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=0 \
  BUILD_DIR_BASE="$RELEASE_BUILD" native-core >/dev/null
clang_contract "$TOOL_ROOT/camera-find-floor-route-release" "$RELEASE_BUILD"
SM64_MODERN_AUTOMATED_BOBOMB=1 \
  "$TOOL_ROOT/camera-find-floor-route-release" "$RELEASE_TRACE" \
  "$BUILD_ROOT/save-release" release >"$RELEASE_LOG" 2>&1
grep -Fq 'camera_find_floor_route_debug variant=release oracle_end=0 result_status=0' "$RELEASE_LOG"
cmp -s "$C_TRACE" "$RELEASE_TRACE"
printf '%s\n' 'camera_find_floor_route_optimized_passed=1 debug_release_trace_match=1'

git -c core.fsmonitor=false diff --check
printf '%s\n' \
  'SM64 Modern camera find-floor route pair smoke passed exact_pair=1 tamper_rejected=1' \
  'route_shard=0x1e3500f9eb2b95d4 source=src/game/camera.c:788:set_camera_height:find_floor' \
  'recipe=automated_bobomb;authored_level=LEVEL_BOB;area=1;camera_mode=CAMERA_MODE_RADIAL' \
  'c_swift_pair=matched records=30 ticks=92,93 object_records=28 collision_records=2' \
  'persistent_rerun=matched coverage=0x1c41224c64ab005f' \
  'admission=0 canonical_ledger_mutation=0 fixture_only=0'
