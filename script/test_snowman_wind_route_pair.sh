#!/usr/bin/env bash
set -euo pipefail

# Phase 85f89 follows only the authored Castle Inside Snowman painting family
# (nodes 0x24/0x25/0x26) into Snowman's Land area 1 and the exact
# script_func_local_3 Snowman wind tuple.  Missing real reachability is exit
# 77.  Direct level selection, helper calls, object injection, sibling or
# coordinate selection, and synthetic traces are fenced.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_PARENT="${SM64_SNOWMAN_WIND_ROUTE_BUILD_PARENT:-$PROJECT_ROOT/build/sm64-modern-snowman-wind-route-pair}"
mkdir -p "$BUILD_PARENT"
BUILD_ROOT="$(mktemp -d "$BUILD_PARENT/run.XXXXXX")"
TOOL_ROOT="$BUILD_ROOT/tool"
DEBUG_ROOT="$BUILD_ROOT/native-debug"
ASAN_ROOT="$BUILD_ROOT/native-asan"
RELEASE_ROOT="$BUILD_ROOT/native-release"
mkdir -p "$TOOL_ROOT/module-cache" "$BUILD_ROOT/save-debug" \
  "$BUILD_ROOT/save-asan" "$BUILD_ROOT/save-release" "$BUILD_ROOT/save-rerun"

grep -Fq 'PAINTING_WARP_NODE(/*id*/ 0x24, /*destLevel*/ LEVEL_SL, /*destArea*/ 0x01' \
  "$PROJECT_ROOT/levels/castle_inside/script.c"
grep -Fq 'PAINTING_WARP_NODE(/*id*/ 0x25, /*destLevel*/ LEVEL_SL, /*destArea*/ 0x01' \
  "$PROJECT_ROOT/levels/castle_inside/script.c"
grep -Fq 'PAINTING_WARP_NODE(/*id*/ 0x26, /*destLevel*/ LEVEL_SL, /*destArea*/ 0x01' \
  "$PROJECT_ROOT/levels/castle_inside/script.c"
grep -Fq 'static const LevelScript script_func_local_3[]' \
  "$PROJECT_ROOT/levels/sl/script.c"
grep -Fq 'OBJECT(/*model*/ MODEL_NONE,               /*pos*/  700, 3428,   700, /*angle*/ 0,  30, 0, /*behParam*/ 0x00000000, /*beh*/ bhvSLSnowmanWind)' \
  "$PROJECT_ROOT/levels/sl/script.c"
grep -Fq 'sm64_modern_snowman_wind_route_observe' \
  "$PROJECT_ROOT/src/game/behaviors/sl_snowman_wind.inc.c"
grep -Fq 'SOURCE_BEHAVIOR_IDENTITY(bhvSLSnowmanWind)' \
  "$PROJECT_ROOT/src/pc/sm64_modern_gameplay_parity.c"
grep -Fq 'SM64_MODERN_SNOWMAN_WIND_ROUTE_SHARD_ID' \
  "$PROJECT_ROOT/src/pc/sm64_modern_snowman_wind_route_identity.h"

if rg -n 'uintptr_t|spawn_object|load_level|level_register|segmented_to_virtual|cur_obj_|gMarioObject' \
  "$PROJECT_ROOT/src/pc/sm64_modern_snowman_wind_route_identity.c"; then
  echo 'snowman_wind_route_pointer_or_helper_fence_failed=1' >&2
  exit 1
fi
if rg -n 'bhv_sl_snowman_wind_loop|cur_obj_|spawn_object|load_level|level_register|setenv|gMarioObject' \
  "$PROJECT_ROOT/tests/sm64_modern_snowman_wind_route_pair_contract.c"; then
  echo 'snowman_wind_route_probe_helper_fence_failed=1' >&2
  exit 1
fi

clang_contract() {
  local output="$1" archive_root="$2"
  shift 2
  xcrun --sdk macosx clang -std=c11 -Wall -Wextra -Werror \
    -DNON_MATCHING=1 -DAVOID_UB=1 -DVERSION_US -D_LANGUAGE_C \
    -mmacosx-version-min=27.0 \
    -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
    -I"$archive_root/us_pc" -I"$archive_root/us_pc/include" \
    "$PROJECT_ROOT/tests/sm64_modern_snowman_wind_route_pair_contract.c" \
    "$archive_root/us_pc/libsm64core.a" -o "$output" -lm -lpthread "$@"
}

SWIFT_OUTPUT="$TOOL_ROOT/snowman-wind-route-swift"
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_snowman_wind_route_swift_smoke.swift" \
  -o "$SWIFT_OUTPUT"

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 \
  BUILD_DIR_BASE="$DEBUG_ROOT" native-core >/dev/null
clang_contract "$TOOL_ROOT/snowman-wind-route-debug" "$DEBUG_ROOT"
DEBUG_TRACE="$BUILD_ROOT/snowman-wind-c.trace"
set +e
"$TOOL_ROOT/snowman-wind-route-debug" "$DEBUG_TRACE" \
  "$BUILD_ROOT/save-debug" >"$BUILD_ROOT/debug.log" 2>&1
debug_status=$?
set -e
if [[ "$debug_status" -ne 0 && "$debug_status" -ne 77 ]]; then
  cat "$BUILD_ROOT/debug.log" >&2
  exit "$debug_status"
fi

if [[ "$debug_status" -eq 77 || ! -s "$DEBUG_TRACE" ]]; then
  cat "$BUILD_ROOT/debug.log" >&2
  git -c core.fsmonitor=false diff --check -- \
    src/game/behaviors/sl_snowman_wind.inc.c \
    src/pc/sm64_modern_gameplay_parity.c \
    src/pc/sm64_modern_snowman_wind_route_identity.c \
    src/pc/sm64_modern_snowman_wind_route_identity.h \
    tests/sm64_modern_snowman_wind_route_pair_contract.c \
    tests/sm64_modern_snowman_wind_route_swift_smoke.swift \
    script/test_snowman_wind_route_pair.sh
  printf '%s\n' \
    'SM64 Modern Snowman wind route pair blocked reachability=0' \
    'source_lifecycle=castle_inside_painting_nodes_0x24_0x25_0x26_to_sl_area1' \
    'first_snowman_wind_receipt=absent sibling_substitution=0 coordinate_matching=0 fixture_only=0' \
    'admission=0 canonical_ledger_mutation=0 manifest_mutation=0 exit=77'
  exit 77
fi

grep -Fq 'snowman_wind_route_debug oracle_end=0 result_status=0' \
  "$BUILD_ROOT/debug.log"
grep -Eq 'c_snowman_wind_route_recorded shard=0xa98dae7d4d4559ab .* records=[1-9][0-9]*' \
  "$BUILD_ROOT/debug.log"

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
  BUILD_DIR_BASE="$ASAN_ROOT" native-core >/dev/null
clang_contract "$TOOL_ROOT/snowman-wind-route-asan" "$ASAN_ROOT" -fsanitize=address
ASAN_TRACE="$BUILD_ROOT/snowman-wind-c-asan.trace"
if ! ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
  "$TOOL_ROOT/snowman-wind-route-asan" "$ASAN_TRACE" \
  "$BUILD_ROOT/save-asan" >"$BUILD_ROOT/asan.log" 2>&1; then
  cat "$BUILD_ROOT/asan.log" >&2
  exit 1
fi
if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' \
  "$BUILD_ROOT/asan.log"; then
  echo 'snowman_wind_route_asan_finding=1' >&2
  exit 1
fi
cmp -s "$DEBUG_TRACE" "$ASAN_TRACE"

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=0 \
  BUILD_DIR_BASE="$RELEASE_ROOT" native-core >/dev/null
clang_contract "$TOOL_ROOT/snowman-wind-route-release" "$RELEASE_ROOT"
RELEASE_TRACE="$BUILD_ROOT/snowman-wind-c-release.trace"
"$TOOL_ROOT/snowman-wind-route-release" "$RELEASE_TRACE" \
  "$BUILD_ROOT/save-release" >"$BUILD_ROOT/release.log" 2>&1

RERUN_TRACE="$BUILD_ROOT/snowman-wind-c-rerun.trace"
"$TOOL_ROOT/snowman-wind-route-debug" "$RERUN_TRACE" \
  "$BUILD_ROOT/save-rerun" >"$BUILD_ROOT/rerun.log" 2>&1
cmp -s "$DEBUG_TRACE" "$RELEASE_TRACE"
cmp -s "$DEBUG_TRACE" "$RERUN_TRACE"

SWIFT_TRACE="$BUILD_ROOT/snowman-wind-swift.trace"
TAMPER_TRACE="$BUILD_ROOT/snowman-wind-tampered.trace"
PARTIAL_TRACE="$BUILD_ROOT/snowman-wind-partial.trace"
WRONG_SUBJECT_TRACE="$BUILD_ROOT/snowman-wind-wrong-subject.trace"
GENERIC_BRIDGE_TRACE="$BUILD_ROOT/snowman-wind-generic-bridge.trace"
FIXTURE_TRACE="$BUILD_ROOT/snowman-wind-fixture-only.trace"
DUPLICATE_TRACE="$BUILD_ROOT/snowman-wind-duplicate.trace"
"$SWIFT_OUTPUT" write "$DEBUG_TRACE" "$SWIFT_TRACE" | tee "$BUILD_ROOT/swift.log"
if "$SWIFT_OUTPUT" write "$DEBUG_TRACE" "$SWIFT_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'snowman_wind_persistent_rerun_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'snowman_wind_persistent_rerun_rejected=1' \
  | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$SWIFT_TRACE" | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" tamper "$SWIFT_TRACE" "$TAMPER_TRACE" | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" partial "$SWIFT_TRACE" "$PARTIAL_TRACE" | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" wrong-subject "$SWIFT_TRACE" "$WRONG_SUBJECT_TRACE" \
  | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" generic-bridge "$SWIFT_TRACE" "$GENERIC_BRIDGE_TRACE" \
  | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" fixture-only "$SWIFT_TRACE" "$FIXTURE_TRACE" \
  | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" duplicate "$SWIFT_TRACE" "$DUPLICATE_TRACE" \
  | tee -a "$BUILD_ROOT/swift.log"
grep -Fq 'snowman_wind_pairing_audit admitted=1' "$BUILD_ROOT/swift.log"
grep -Fq 'snowman_wind_tamper_rejected=1' "$BUILD_ROOT/swift.log"

if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$PARTIAL_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'snowman_wind_partial_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'snowman_wind_partial_rejected=1' | tee -a "$BUILD_ROOT/swift.log"
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$WRONG_SUBJECT_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'snowman_wind_wrong_subject_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'snowman_wind_wrong_subject_rejected=1' \
  | tee -a "$BUILD_ROOT/swift.log"
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$GENERIC_BRIDGE_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'snowman_wind_generic_bridge_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'snowman_wind_generic_bridge_rejected=1' \
  | tee -a "$BUILD_ROOT/swift.log"
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$FIXTURE_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'snowman_wind_fixture_only_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'snowman_wind_fixture_only_rejected=1' \
  | tee -a "$BUILD_ROOT/swift.log"
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$DUPLICATE_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'snowman_wind_duplicate_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'snowman_wind_duplicate_rejected=1' | tee -a "$BUILD_ROOT/swift.log"
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$DEBUG_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'snowman_wind_single_artifact_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'snowman_wind_single_artifact_rejected=1' \
  | tee -a "$BUILD_ROOT/swift.log"
cmp -s "$DEBUG_TRACE" "$SWIFT_TRACE"

git -c core.fsmonitor=false diff --check -- \
  src/game/behaviors/sl_snowman_wind.inc.c \
  src/pc/sm64_modern_gameplay_parity.c \
  src/pc/sm64_modern_snowman_wind_route_identity.c \
  src/pc/sm64_modern_snowman_wind_route_identity.h \
  tests/sm64_modern_snowman_wind_route_pair_contract.c \
  tests/sm64_modern_snowman_wind_route_swift_smoke.swift \
  script/test_snowman_wind_route_pair.sh
printf '%s\n' \
  'SM64 Modern Snowman wind route pair passed exact_pair=1' \
  'source_receipts=script,object,collision,effect semantic_identity=1' \
  'debug_asan_release_rerun_match=1 swift_pair=1 tamper_rejected=1 persistent_rerun_rejected=1' \
  'partial_rejected=1 wrong_subject_rejected=1 generic_bridge_rejected=1 fixture_only_rejected=1 duplicate_rejected=1 single_artifact_rejected=1' \
  'admission=0 canonical_ledger_mutation=0 manifest_mutation=0' \
  "run_root=$BUILD_ROOT"
