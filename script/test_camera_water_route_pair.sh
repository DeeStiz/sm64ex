#!/usr/bin/env bash
set -euo pipefail

# Phase 85f31 owns only the source-bound camera callback receipt at
# camera.c:2471.  The ordinary owner-thread recipe must reach authored DDD
# area 1; this script exits 77 when that reachability gate is not met.  No
# manifest, canonical ledger, or report is written.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -n "${SM64_CAMERA_WATER_PAIR_ROOT:-}" ]]; then
  BUILD_ROOT="$SM64_CAMERA_WATER_PAIR_ROOT"
else
  BUILD_PARENT="$PROJECT_ROOT/build/sm64-modern-camera-water-route-pair"
  mkdir -p "$BUILD_PARENT"
  BUILD_ROOT="$(mktemp -d "$BUILD_PARENT/run.XXXXXX")"
fi
DEBUG_BUILD="$BUILD_ROOT/native-debug"
ASAN_BUILD="$BUILD_ROOT/native-asan"
RELEASE_BUILD="$BUILD_ROOT/native-release"
TOOL_ROOT="$BUILD_ROOT/tool"
C_OUTPUT="$TOOL_ROOT/sm64-modern-camera-water-route-contract"
ASAN_OUTPUT="$TOOL_ROOT/sm64-modern-camera-water-route-contract-asan"
RELEASE_OUTPUT="$TOOL_ROOT/sm64-modern-camera-water-route-contract-release"
SWIFT_OUTPUT="$TOOL_ROOT/sm64-modern-camera-water-route-swift"
C_TRACE="$BUILD_ROOT/camera-water-c.trace"
RERUN_TRACE="$BUILD_ROOT/camera-water-c-rerun.trace"
BLOCKED_RERUN_TRACE="$BUILD_ROOT/camera-water-c-blocked-rerun.trace"
ASAN_TRACE="$BUILD_ROOT/camera-water-c-asan.trace"
RELEASE_TRACE="$BUILD_ROOT/camera-water-c-release.trace"
SWIFT_TRACE="$BUILD_ROOT/camera-water-swift.trace"
TAMPERED_TRACE="$BUILD_ROOT/camera-water-swift.tampered.trace"
PARTIAL_TRACE="$BUILD_ROOT/camera-water-swift.partial.trace"
DEBUG_LOG="$BUILD_ROOT/debug.log"
RERUN_LOG="$BUILD_ROOT/rerun.log"
ASAN_LOG="$BUILD_ROOT/asan.log"
RELEASE_LOG="$BUILD_ROOT/release.log"

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
    "$PROJECT_ROOT/tests/sm64_modern_camera_water_route_pair_contract.c" \
    "$archive_root/us_pc/libsm64core.a" -o "$output" -lm -lpthread "$@"
}

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 \
  BUILD_DIR_BASE="$DEBUG_BUILD" native-core >/dev/null
clang_contract "$C_OUTPUT" "$DEBUG_BUILD"

set +e
"$C_OUTPUT" "$C_TRACE" "$BUILD_ROOT/save-debug" >"$DEBUG_LOG" 2>&1
contract_status=$?
set -e

if (( contract_status == 77 )); then
  set +e
  "$C_OUTPUT" "$BLOCKED_RERUN_TRACE" "$BUILD_ROOT/save-blocked-rerun" \
    >"$RERUN_LOG" 2>&1
  blocked_rerun_status=$?
  set -e
  if (( blocked_rerun_status != 77 )); then
    cat "$RERUN_LOG" >&2
    exit "$blocked_rerun_status"
  fi
  cmp -s "$C_TRACE" "$BLOCKED_RERUN_TRACE"
  printf '%s\n' 'camera_water_route_blocked_rerun_stable=1 trace_match=1'
  xcrun swiftc -parse-as-library -swift-version 6 \
    -Xfrontend -strict-concurrency=complete \
    -module-cache-path "$TOOL_ROOT/module-cache" \
    "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
    "$PROJECT_ROOT/SM64Modern/CameraWaterQueryMigration.swift" \
    "$PROJECT_ROOT/tests/sm64_modern_camera_water_route_swift_smoke.swift" \
    -o "$SWIFT_OUTPUT"
  "$SWIFT_OUTPUT" write "$SWIFT_TRACE"
  "$SWIFT_OUTPUT" negative
  "$SWIFT_OUTPUT" tamper "$SWIFT_TRACE" "$TAMPERED_TRACE"
  PARTIAL_BYTES=$((72 + 128 - 1))
  head -c "$PARTIAL_BYTES" "$SWIFT_TRACE" >"$PARTIAL_TRACE"
  if "$SWIFT_OUTPUT" audit "$PARTIAL_TRACE" "$SWIFT_TRACE" \
      >"$BUILD_ROOT/partial.log" 2>&1; then
    echo 'camera_water_partial_trace_rejected=0' >&2
    exit 1
  fi
  printf '%s\n' 'camera_water_partial_trace_rejected=1'
  if "$SWIFT_OUTPUT" audit "$SWIFT_TRACE" "$SWIFT_TRACE" \
      >"$BUILD_ROOT/single.log" 2>&1; then
    echo 'camera_water_single_artifact_rejected=0' >&2
    exit 1
  fi
  printf '%s\n' 'camera_water_single_artifact_rejected=1'
  git -c core.fsmonitor=false diff --check
  printf '%s\n' \
    'SM64 Modern camera-water route pair blocked fail_closed=1' \
    'reason=ordinary_owner_thread_lifecycle_did_not_reach_authored_ddd_area1' \
    'synthetic_receipt=0 direct_level_load=0 forced_camera_mode=0 sushi_injection=0' \
    'canonical_manifest_mutation=0 canonical_ledger_mutation=0'
  exit 77
fi

if (( contract_status != 0 )); then
  cat "$DEBUG_LOG" >&2
  exit "$contract_status"
fi

grep -Fq 'camera_water_route_init status=0 oracle=0' "$DEBUG_LOG"
grep -Fq 'camera_water_route_debug oracle_end=0 result_status=0' "$DEBUG_LOG"
grep -Fq 'c_camera_water_route_recorded shard=0x340565d4295ea359' "$DEBUG_LOG"
test -s "$C_TRACE"

"$C_OUTPUT" "$RERUN_TRACE" "$BUILD_ROOT/save-rerun" >"$RERUN_LOG" 2>&1
cmp -s "$C_TRACE" "$RERUN_TRACE"
printf '%s\n' 'camera_water_route_persistent_rerun_passed=1 trace_match=1'

xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/CameraWaterQueryMigration.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_camera_water_route_swift_smoke.swift" \
  -o "$SWIFT_OUTPUT"
"$SWIFT_OUTPUT" write "$SWIFT_TRACE"
"$SWIFT_OUTPUT" audit "$C_TRACE" "$SWIFT_TRACE"
"$SWIFT_OUTPUT" tamper "$SWIFT_TRACE" "$TAMPERED_TRACE"

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
  BUILD_DIR_BASE="$ASAN_BUILD" native-core >/dev/null
clang_contract "$ASAN_OUTPUT" "$ASAN_BUILD" -fsanitize=address
ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
  "$ASAN_OUTPUT" "$ASAN_TRACE" "$BUILD_ROOT/save-asan" >"$ASAN_LOG" 2>&1
if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' \
    "$ASAN_LOG"; then
  echo 'camera-water route emitted an AddressSanitizer finding' >&2
  exit 1
fi
cmp -s "$C_TRACE" "$ASAN_TRACE"
printf '%s\n' 'camera_water_route_sanitizer_passed=1 debug_asan_trace_match=1'

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=0 \
  BUILD_DIR_BASE="$RELEASE_BUILD" native-core >/dev/null
clang_contract "$RELEASE_OUTPUT" "$RELEASE_BUILD"
"$RELEASE_OUTPUT" "$RELEASE_TRACE" "$BUILD_ROOT/save-release" \
  >"$RELEASE_LOG" 2>&1
cmp -s "$C_TRACE" "$RELEASE_TRACE"
printf '%s\n' 'camera_water_route_optimized_passed=1 debug_release_trace_match=1'

git -c core.fsmonitor=false diff --check
printf '%s\n' \
  'SM64 Modern camera-water route pair smoke passed exact_pair=1 tamper_rejected=1' \
  'native_camera_domain=5 record_kind=3 event=307 source=src/game/camera.c:2471' \
  'recipe=authored_ddd_area1;camera_mode=CAMERA_MODE_OUTWARD_RADIAL' \
  'c_swift_pair=matched first_divergence=none admission=0 ledger_mutation=0'
