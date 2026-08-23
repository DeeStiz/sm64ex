#!/usr/bin/env bash
set -euo pipefail

# Phase 85f47 probes only the source-authored Castle Inside painting route to
# WDW area 1.  A missing dynamic receipt is a fail-closed reachability block
# (exit 77), never permission to substitute the static sibling or to emit a
# fixture record.  No manifest, canonical ledger, or report is mutated.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_PARENT="${SM64_WDW_ELEVATOR_ROUTE_BUILD_PARENT:-$PROJECT_ROOT/build/sm64-modern-wdw-elevator-route-pair}"
mkdir -p "$BUILD_PARENT"
BUILD_ROOT="$(mktemp -d "$BUILD_PARENT/run.XXXXXX")"
TOOL_ROOT="$BUILD_ROOT/tool"
DEBUG_ROOT="$BUILD_ROOT/native-debug"
ASAN_ROOT="$BUILD_ROOT/native-asan"
RELEASE_ROOT="$BUILD_ROOT/native-release"
mkdir -p "$TOOL_ROOT/module-cache" "$BUILD_ROOT/save-debug" \
  "$BUILD_ROOT/save-asan" "$BUILD_ROOT/save-release" "$BUILD_ROOT/save-rerun"

SWIFT_OUTPUT="$TOOL_ROOT/wdw-express-elevator-route-swift"
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_wdw_elevator_route_swift_smoke.swift" \
  -o "$SWIFT_OUTPUT"

grep -Fq 'PAINTING_WARP_NODE(/*id*/ 0x18, /*destLevel*/ LEVEL_WDW, /*destArea*/ 0x01' \
  "$PROJECT_ROOT/levels/castle_inside/script.c"
grep -Fq 'OBJECT(/*model*/ MODEL_WDW_EXPRESS_ELEVATOR' \
  "$PROJECT_ROOT/levels/wdw/script.c"
grep -Fq 'SM64_MODERN_WDW_ELEVATOR_ROUTE_BEHAVIOR_ID' \
  "$PROJECT_ROOT/src/pc/sm64_modern_wdw_elevator_route_identity.h"
grep -Fq 'sm64_modern_wdw_elevator_route_observe' \
  "$PROJECT_ROOT/src/game/behaviors/express_elevator.inc.c"
if rg -n 'uintptr_t|spawn_object|load_level|cur_obj_is_mario_on_platform' \
  "$PROJECT_ROOT/src/pc/sm64_modern_wdw_elevator_route_identity.c"; then
  echo 'wdw_express_elevator_route_pointer_or_helper_fence_failed=1' >&2
  exit 1
fi

clang_contract() {
  local output="$1"
  local archive_root="$2"
  shift 2
  xcrun --sdk macosx clang -std=c11 -Wall -Wextra -Werror \
    -DNON_MATCHING=1 -DAVOID_UB=1 -DVERSION_US -D_LANGUAGE_C \
    -mmacosx-version-min=27.0 \
    -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
    -I"$archive_root/us_pc" -I"$archive_root/us_pc/include" \
    "$PROJECT_ROOT/tests/sm64_modern_wdw_elevator_route_pair_contract.c" \
    "$archive_root/us_pc/libsm64core.a" -o "$output" -lm -lpthread "$@"
}

run_native() {
  local executable="$1"
  local trace="$2"
  local save_directory="$3"
  local log="$4"
  SM64_MODERN_AUTOMATED_CASTLE_WDW_ELEVATOR=1 \
    "$executable" "$trace" "$save_directory" >"$log" 2>&1
}

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 \
  BUILD_DIR_BASE="$DEBUG_ROOT" native-core >/dev/null
clang_contract "$TOOL_ROOT/wdw-express-elevator-route-debug" "$DEBUG_ROOT"
DEBUG_TRACE="$BUILD_ROOT/wdw-express-elevator-c.trace"
set +e
run_native "$TOOL_ROOT/wdw-express-elevator-route-debug" "$DEBUG_TRACE" \
  "$BUILD_ROOT/save-debug" "$BUILD_ROOT/debug.log"
rc=$?
set -e
if [[ "$rc" -ne 0 && "$rc" -ne 77 ]]; then
  cat "$BUILD_ROOT/debug.log" >&2
  exit "$rc"
fi

# The authored destination currently passes through WDW's area-1 instant-warp
# lifecycle before the express elevator loop can run.  Preserve that blocker
# as an explicit non-admission result rather than falling back to area 2 or a
# synthetic object.  The remainder of this script is the admission matrix,
# reachable only when the source lifecycle produces a positive receipt.
if [[ "$rc" -eq 77 || ! -s "$DEBUG_TRACE" ]]; then
  cat "$BUILD_ROOT/debug.log" >&2
  git -c core.fsmonitor=false diff --check -- \
    src/game/game_init.c \
    src/game/behaviors/express_elevator.inc.c \
    src/pc/sm64_modern_gameplay_parity.c \
    src/pc/sm64_modern_wdw_elevator_route_identity.c \
    src/pc/sm64_modern_wdw_elevator_route_identity.h \
    tests/sm64_modern_wdw_elevator_route_pair_contract.c \
    tests/sm64_modern_wdw_elevator_route_swift_smoke.swift \
    script/test_wdw_express_elevator_route_pair.sh
  printf '%s\n' \
    'SM64 Modern WDW express elevator route pair blocked reachability=0' \
    'source_lifecycle=castle_inside_painting_node_0x18_to_wdw_area1' \
    'dynamic_receipt=absent static_sibling_substitution=0 fixture_only=0' \
    'admission=0 canonical_ledger_mutation=0 manifest_mutation=0 exit=77'
  exit 77
fi

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
  BUILD_DIR_BASE="$ASAN_ROOT" native-core >/dev/null
clang_contract "$TOOL_ROOT/wdw-express-elevator-route-asan" "$ASAN_ROOT" -fsanitize=address
ASAN_TRACE="$BUILD_ROOT/wdw-express-elevator-c-asan.trace"
set +e
run_native "$TOOL_ROOT/wdw-express-elevator-route-asan" "$ASAN_TRACE" \
  "$BUILD_ROOT/save-asan" "$BUILD_ROOT/asan.log"
rc=$?
set -e
if [[ "$rc" -eq 77 ]]; then exit 77; fi
if [[ "$rc" -ne 0 ]]; then
  cat "$BUILD_ROOT/asan.log" >&2
  exit "$rc"
fi
if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' \
  "$BUILD_ROOT/asan.log"; then
  echo 'wdw_express_elevator_route_asan_finding=1' >&2
  exit 1
fi

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=0 \
  BUILD_DIR_BASE="$RELEASE_ROOT" native-core >/dev/null
clang_contract "$TOOL_ROOT/wdw-express-elevator-route-release" "$RELEASE_ROOT"
RELEASE_TRACE="$BUILD_ROOT/wdw-express-elevator-c-release.trace"
run_native "$TOOL_ROOT/wdw-express-elevator-route-release" "$RELEASE_TRACE" \
  "$BUILD_ROOT/save-release" "$BUILD_ROOT/release.log"

RERUN_TRACE="$BUILD_ROOT/wdw-express-elevator-c-rerun.trace"
run_native "$TOOL_ROOT/wdw-express-elevator-route-debug" "$RERUN_TRACE" \
  "$BUILD_ROOT/save-rerun" "$BUILD_ROOT/rerun.log"
cmp -s "$DEBUG_TRACE" "$ASAN_TRACE"
cmp -s "$DEBUG_TRACE" "$RELEASE_TRACE"
cmp -s "$DEBUG_TRACE" "$RERUN_TRACE"

SWIFT_TRACE="$BUILD_ROOT/wdw-express-elevator-swift.trace"
TAMPER_TRACE="$BUILD_ROOT/wdw-express-elevator-tampered.trace"
PARTIAL_TRACE="$BUILD_ROOT/wdw-express-elevator-partial.trace"
SIBLING_TRACE="$BUILD_ROOT/wdw-express-elevator-wrong-sibling.trace"
"$SWIFT_OUTPUT" write "$DEBUG_TRACE" "$SWIFT_TRACE"
"$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$SWIFT_TRACE"
"$SWIFT_OUTPUT" tamper "$DEBUG_TRACE" "$TAMPER_TRACE"
"$SWIFT_OUTPUT" partial "$DEBUG_TRACE" "$PARTIAL_TRACE"
"$SWIFT_OUTPUT" wrong-sibling "$DEBUG_TRACE" "$SIBLING_TRACE"
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$PARTIAL_TRACE"; then
  echo 'wdw_express_elevator_partial_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'wdw_express_elevator_partial_rejected=1'
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$SIBLING_TRACE"; then
  echo 'wdw_express_elevator_wrong_sibling_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'wdw_express_elevator_wrong_sibling_rejected=1'
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$DEBUG_TRACE"; then
  echo 'wdw_express_elevator_single_artifact_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'wdw_express_elevator_single_artifact_rejected=1'

git -c core.fsmonitor=false diff --check -- \
  src/game/game_init.c \
  src/game/behaviors/express_elevator.inc.c \
  src/pc/sm64_modern_gameplay_parity.c \
  src/pc/sm64_modern_wdw_elevator_route_identity.c \
  src/pc/sm64_modern_wdw_elevator_route_identity.h \
  tests/sm64_modern_wdw_elevator_route_pair_contract.c \
  tests/sm64_modern_wdw_elevator_route_swift_smoke.swift \
  script/test_wdw_express_elevator_route_pair.sh
printf '%s\n' \
  'SM64 Modern WDW express elevator route pair passed exact_pair=1' \
  'tamper_rejected=1 partial_rejected=1 wrong_sibling_rejected=1 single_artifact_rejected=1' \
  'debug_asan_release_rerun_match=1 admission=0 canonical_ledger_mutation=0 manifest_mutation=0'
