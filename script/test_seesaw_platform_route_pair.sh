#!/usr/bin/env bash
set -euo pipefail

# Phase 85f62 follows the compiled Castle Inside painting entry into Bob area
# 1 and retains only the source-created MODEL_BOB_SEESAW_PLATFORM instance
# with behavior parameter 3. A missing owner-thread route is exit 77; it is
# never permission to load Bob directly, register an object, call a helper,
# substitute a seesaw variant, or write a fixture trace.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -n "${SM64_SEESAW_PLATFORM_ROUTE_PAIR_ROOT:-}" ]]; then
  BUILD_ROOT="$SM64_SEESAW_PLATFORM_ROUTE_PAIR_ROOT"
else
  BUILD_PARENT="$PROJECT_ROOT/build/sm64-modern-seesaw-platform-route-pair"
  mkdir -p "$BUILD_PARENT"
  BUILD_ROOT="$(mktemp -d "$BUILD_PARENT/run.XXXXXX")"
fi

TOOL_ROOT="$BUILD_ROOT/tool"
DEBUG_BUILD="$BUILD_ROOT/native-debug"
ASAN_BUILD="$BUILD_ROOT/native-asan"
RELEASE_BUILD="$BUILD_ROOT/native-release"
DEBUG_TRACE="$BUILD_ROOT/seesaw-platform-c.trace"
ASAN_TRACE="$BUILD_ROOT/seesaw-platform-c-asan.trace"
RELEASE_TRACE="$BUILD_ROOT/seesaw-platform-c-release.trace"
RERUN_TRACE="$BUILD_ROOT/seesaw-platform-c-rerun.trace"
SWIFT_TRACE="$BUILD_ROOT/seesaw-platform-swift.trace"
TAMPER_TRACE="$BUILD_ROOT/seesaw-platform-tampered.trace"
PARTIAL_TRACE="$BUILD_ROOT/seesaw-platform-partial.trace"
WRONG_VARIANT_TRACE="$BUILD_ROOT/seesaw-platform-wrong-variant.trace"
mkdir -p "$TOOL_ROOT/module-cache" "$BUILD_ROOT/save-debug" \
  "$BUILD_ROOT/save-asan" "$BUILD_ROOT/save-release" "$BUILD_ROOT/save-rerun"

grep -Fq 'PAINTING_WARP_NODE(/*id*/ 0x00, /*destLevel*/ LEVEL_BOB, /*destArea*/ 0x01' \
  "$PROJECT_ROOT/levels/castle_inside/script.c"
grep -Fq 'MODEL_BOB_SEESAW_PLATFORM' "$PROJECT_ROOT/levels/bob/script.c"
grep -Fq '/*behParam*/ 0x00030000' "$PROJECT_ROOT/levels/bob/script.c"
grep -Fq 'bhvSeesawPlatform' "$PROJECT_ROOT/levels/bob/script.c"
grep -Fq 'SM64_MODERN_SEESAW_PLATFORM_ROUTE_SHARD_ID' \
  "$PROJECT_ROOT/src/pc/sm64_modern_seesaw_platform_route_identity.h"
grep -Fq 'sm64_modern_seesaw_platform_route_observe' \
  "$PROJECT_ROOT/src/game/behaviors/seesaw_platform.inc.c"
if rg -n 'uintptr_t|spawn_object|load_level|bhv_seesaw_platform_init|bhv_seesaw_platform_update|load_object_collision_model|cur_obj_is_mario_on_platform' \
  "$PROJECT_ROOT/src/pc/sm64_modern_seesaw_platform_route_identity.c" \
  "$PROJECT_ROOT/tests/sm64_modern_seesaw_platform_route_swift_smoke.swift"; then
  echo 'seesaw_platform_route_pointer_or_helper_fence_failed=1' >&2
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
    "$PROJECT_ROOT/tests/sm64_modern_seesaw_platform_route_pair_contract.c" \
    "$archive_root/us_pc/libsm64core.a" -o "$output" -lm -lpthread "$@"
}

run_native() {
  local executable="$1"
  local trace="$2"
  local save_directory="$3"
  local log="$4"
  SM64_MODERN_AUTOMATED_CASTLE_SEESAW=1 \
    "$executable" "$trace" "$save_directory" >"$log" 2>&1
}

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 \
  BUILD_DIR_BASE="$DEBUG_BUILD" native-core >/dev/null
clang_contract "$TOOL_ROOT/seesaw-platform-route-debug" "$DEBUG_BUILD"
set +e
run_native "$TOOL_ROOT/seesaw-platform-route-debug" "$DEBUG_TRACE" \
  "$BUILD_ROOT/save-debug" "$BUILD_ROOT/debug.log"
debug_rc=$?
set -e
if [[ "$debug_rc" -eq 77 || ! -s "$DEBUG_TRACE" ]]; then
  cat "$BUILD_ROOT/debug.log" >&2
  git -c core.fsmonitor=false diff --check -- \
    src/game/behaviors/seesaw_platform.inc.c \
    src/pc/sm64_modern_gameplay_parity.c \
    src/pc/sm64_modern_seesaw_platform_route_identity.c \
    src/pc/sm64_modern_seesaw_platform_route_identity.h \
    tests/sm64_modern_seesaw_platform_route_pair_contract.c \
    tests/sm64_modern_seesaw_platform_route_swift_smoke.swift \
    script/test_seesaw_platform_route_pair.sh
  printf '%s\n' \
    'SM64 Modern Bob seesaw route blocked reachability=0' \
    'source_lifecycle=castle_inside_painting_to_bob_area1' \
    'selected_model=MODEL_BOB_SEESAW_PLATFORM parameter=3' \
    'synthetic_trace=0 direct_level_load=0 object_injection=0 variant_substitution=0' \
    'admission=0 canonical_ledger_mutation=0 manifest_mutation=0 exit=77'
  exit 77
fi
if [[ "$debug_rc" -ne 0 ]]; then
  cat "$BUILD_ROOT/debug.log" >&2
  exit "$debug_rc"
fi

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
  BUILD_DIR_BASE="$ASAN_BUILD" native-core >/dev/null
clang_contract "$TOOL_ROOT/seesaw-platform-route-asan" "$ASAN_BUILD" -fsanitize=address
set +e
ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
  run_native "$TOOL_ROOT/seesaw-platform-route-asan" "$ASAN_TRACE" \
  "$BUILD_ROOT/save-asan" "$BUILD_ROOT/asan.log"
asan_rc=$?
set -e
if [[ "$asan_rc" -eq 77 ]]; then
  cat "$BUILD_ROOT/asan.log" >&2
  exit 77
fi
if [[ "$asan_rc" -ne 0 ]]; then
  cat "$BUILD_ROOT/asan.log" >&2
  exit "$asan_rc"
fi
if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' \
  "$BUILD_ROOT/asan.log"; then
  echo 'seesaw_platform_route_asan_finding=1' >&2
  exit 1
fi

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=0 \
  BUILD_DIR_BASE="$RELEASE_BUILD" native-core >/dev/null
clang_contract "$TOOL_ROOT/seesaw-platform-route-release" "$RELEASE_BUILD"
run_native "$TOOL_ROOT/seesaw-platform-route-release" "$RELEASE_TRACE" \
  "$BUILD_ROOT/save-release" "$BUILD_ROOT/release.log"
run_native "$TOOL_ROOT/seesaw-platform-route-debug" "$RERUN_TRACE" \
  "$BUILD_ROOT/save-rerun" "$BUILD_ROOT/rerun.log"
cmp -s "$DEBUG_TRACE" "$ASAN_TRACE"
cmp -s "$DEBUG_TRACE" "$RELEASE_TRACE"
cmp -s "$DEBUG_TRACE" "$RERUN_TRACE"
printf '%s\n' 'seesaw_platform_route_debug_asan_release_rerun_match=1'

xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_seesaw_platform_route_swift_smoke.swift" \
  -o "$TOOL_ROOT/seesaw-platform-route-swift"

"$TOOL_ROOT/seesaw-platform-route-swift" write "$DEBUG_TRACE" "$SWIFT_TRACE"
"$TOOL_ROOT/seesaw-platform-route-swift" audit "$DEBUG_TRACE" "$SWIFT_TRACE"
"$TOOL_ROOT/seesaw-platform-route-swift" tamper "$DEBUG_TRACE" "$TAMPER_TRACE"
"$TOOL_ROOT/seesaw-platform-route-swift" wrong-variant "$DEBUG_TRACE" "$WRONG_VARIANT_TRACE"
"$TOOL_ROOT/seesaw-platform-route-swift" partial "$DEBUG_TRACE" "$PARTIAL_TRACE"

if "$TOOL_ROOT/seesaw-platform-route-swift" audit "$DEBUG_TRACE" "$PARTIAL_TRACE" \
  >"$BUILD_ROOT/partial.log" 2>&1; then
  echo 'seesaw_platform_route_partial_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'seesaw_platform_route_partial_rejected=1'
if "$TOOL_ROOT/seesaw-platform-route-swift" audit "$DEBUG_TRACE" "$WRONG_VARIANT_TRACE" \
  >"$BUILD_ROOT/wrong-variant.log" 2>&1; then
  echo 'seesaw_platform_route_wrong_variant_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'seesaw_platform_route_wrong_variant_rejected=1'
if "$TOOL_ROOT/seesaw-platform-route-swift" audit "$DEBUG_TRACE" "$DEBUG_TRACE" \
  >"$BUILD_ROOT/single.log" 2>&1; then
  echo 'seesaw_platform_route_single_artifact_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'seesaw_platform_route_single_artifact_rejected=1'
cmp -s "$DEBUG_TRACE" "$SWIFT_TRACE"

git -c core.fsmonitor=false diff --check -- \
  src/game/behaviors/seesaw_platform.inc.c \
  src/pc/sm64_modern_gameplay_parity.c \
  src/pc/sm64_modern_seesaw_platform_route_identity.c \
  src/pc/sm64_modern_seesaw_platform_route_identity.h \
  tests/sm64_modern_seesaw_platform_route_pair_contract.c \
  tests/sm64_modern_seesaw_platform_route_swift_smoke.swift \
  script/test_seesaw_platform_route_pair.sh
printf '%s\n' \
  'SM64 Modern Bob seesaw platform route pair passed exact_pair=1' \
  'source_receipts=script_events,object_state,collision_queries,effects semantic_identity=1' \
  'debug_asan_release_rerun_match=1 swift_pair=1 tamper_rejected=1' \
  'partial_rejected=1 wrong_variant_rejected=1 single_artifact_rejected=1' \
  'admission=0 canonical_ledger_mutation=0 manifest_mutation=0' \
  "run_root=$BUILD_ROOT"
