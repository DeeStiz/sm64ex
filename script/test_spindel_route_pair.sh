#!/usr/bin/env bash
set -euo pipefail

# Phase 85f78 follows only the source-authored Castle Inside SSL painting
# nodes (0x0f/0x10/0x11), SSL area 1's authored 0x14 warp, and SSL area 2's
# first script_func_local_4 Spindel tuple. Missing real reachability is exit
# 77. Direct level loads, helper calls, injection, coordinate matching,
# sibling substitution, and synthetic traces are fenced.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_PARENT="${SM64_SPINDEL_ROUTE_BUILD_PARENT:-$PROJECT_ROOT/build/sm64-modern-spindel-route-pair}"
mkdir -p "$BUILD_PARENT"
BUILD_ROOT="$(mktemp -d "$BUILD_PARENT/run.XXXXXX")"
TOOL_ROOT="$BUILD_ROOT/tool"
DEBUG_ROOT="$BUILD_ROOT/native-debug"
ASAN_ROOT="$BUILD_ROOT/native-asan"
RELEASE_ROOT="$BUILD_ROOT/native-release"
mkdir -p "$TOOL_ROOT/module-cache" "$BUILD_ROOT/save-debug" \
  "$BUILD_ROOT/save-asan" "$BUILD_ROOT/save-release" "$BUILD_ROOT/save-rerun"

grep -Fq 'PAINTING_WARP_NODE(/*id*/ 0x0F, /*destLevel*/ LEVEL_SSL, /*destArea*/ 0x01' \
  "$PROJECT_ROOT/levels/castle_inside/script.c"
grep -Fq 'PAINTING_WARP_NODE(/*id*/ 0x10, /*destLevel*/ LEVEL_SSL, /*destArea*/ 0x01' \
  "$PROJECT_ROOT/levels/castle_inside/script.c"
grep -Fq 'PAINTING_WARP_NODE(/*id*/ 0x11, /*destLevel*/ LEVEL_SSL, /*destArea*/ 0x01' \
  "$PROJECT_ROOT/levels/castle_inside/script.c"
grep -Fq 'WARP_NODE(/*id*/ 0x14, /*destLevel*/ LEVEL_SSL, /*destArea*/ 0x02' \
  "$PROJECT_ROOT/levels/ssl/script.c"
grep -Fq 'JUMP_LINK(script_func_local_4)' "$PROJECT_ROOT/levels/ssl/script.c"
grep -Fq 'MODEL_SSL_SPINDEL' "$PROJECT_ROOT/levels/ssl/script.c"
grep -Fq '/*pos*/ -2458, 2109, -1430' "$PROJECT_ROOT/levels/ssl/script.c"
grep -Fq 'LOAD_COLLISION_DATA(ssl_seg7_collision_spindel)' \
  "$PROJECT_ROOT/data/behavior_data.c"
grep -Fq 'CALL_NATIVE(bhv_spindel_init)' "$PROJECT_ROOT/data/behavior_data.c"
grep -Fq 'CALL_NATIVE(bhv_spindel_loop)' "$PROJECT_ROOT/data/behavior_data.c"
grep -Fq 'sm64_modern_spindel_route_observe' \
  "$PROJECT_ROOT/src/game/behaviors/spindel.inc.c"
grep -Fq 'SOURCE_BEHAVIOR_IDENTITY(bhvSpindel)' \
  "$PROJECT_ROOT/src/pc/sm64_modern_gameplay_parity.c"

if rg -n 'uintptr_t|spawn_object|load_level|level_register|segmented_to_virtual|cur_obj_|gMarioObject|collisionData' \
  "$PROJECT_ROOT/src/pc/sm64_modern_spindel_route_identity.c"; then
  echo 'spindel_route_pointer_or_helper_fence_failed=1' >&2
  exit 1
fi
if rg -n 'bhv_spindel_(init|loop)|load_object_collision_model|spawn_object|load_level|level_register|setenv' \
  "$PROJECT_ROOT/tests/sm64_modern_spindel_route_pair_contract.c"; then
  echo 'spindel_route_probe_helper_fence_failed=1' >&2
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
    "$PROJECT_ROOT/tests/sm64_modern_spindel_route_pair_contract.c" \
    "$archive_root/us_pc/libsm64core.a" -o "$output" -lm -lpthread "$@"
}

SWIFT_OUTPUT="$TOOL_ROOT/spindel-route-swift"
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_spindel_route_swift_smoke.swift" \
  -o "$SWIFT_OUTPUT"

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 \
  BUILD_DIR_BASE="$DEBUG_ROOT" native-core >/dev/null
clang_contract "$TOOL_ROOT/spindel-route-debug" "$DEBUG_ROOT"
DEBUG_TRACE="$BUILD_ROOT/spindel-c.trace"
set +e
"$TOOL_ROOT/spindel-route-debug" "$DEBUG_TRACE" "$BUILD_ROOT/save-debug" \
  >"$BUILD_ROOT/debug.log" 2>&1
debug_status=$?
set -e
if [[ "$debug_status" -ne 0 && "$debug_status" -ne 77 ]]; then
  cat "$BUILD_ROOT/debug.log" >&2
  exit "$debug_status"
fi

if [[ ! -s "$DEBUG_TRACE" ]]; then
  cat "$BUILD_ROOT/debug.log" >&2
  git -c core.fsmonitor=false diff --check -- \
    src/game/behaviors/spindel.inc.c \
    src/pc/sm64_modern_gameplay_parity.c \
    src/pc/sm64_modern_spindel_route_identity.c \
    src/pc/sm64_modern_spindel_route_identity.h \
    tests/sm64_modern_spindel_route_pair_contract.c \
    tests/sm64_modern_spindel_route_swift_smoke.swift \
    script/test_spindel_route_pair.sh
  printf '%s\n' \
    'SM64 Modern Spindel route pair blocked reachability=0' \
    'source_lifecycle=castle_inside_ssl_painting_nodes_0x0f_0x10_0x11_to_ssl_area1_warp_0x14_to_area2' \
    'first_spindel_receipt=absent sibling_substitution=0 coordinate_matching=0 fixture_only=0' \
    'admission=0 canonical_ledger_mutation=0 manifest_mutation=0 exit=77'
  exit 77
fi

grep -Fq 'spindel_route_debug oracle_end=0 result_status=0' "$BUILD_ROOT/debug.log"
grep -Eq 'c_spindel_route_recorded shard=0xdc93743116807bec .* records=[1-9][0-9]*' \
  "$BUILD_ROOT/debug.log"

ASAN_TRACE="$BUILD_ROOT/spindel-c-asan.trace"
make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
  BUILD_DIR_BASE="$ASAN_ROOT" native-core >/dev/null
clang_contract "$TOOL_ROOT/spindel-route-asan" "$ASAN_ROOT" -fsanitize=address
if ! ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
  "$TOOL_ROOT/spindel-route-asan" "$ASAN_TRACE" "$BUILD_ROOT/save-asan" \
  >"$BUILD_ROOT/asan.log" 2>&1; then
  cat "$BUILD_ROOT/asan.log" >&2
  exit 1
fi
if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' \
  "$BUILD_ROOT/asan.log"; then
  echo 'spindel_route_asan_finding=1' >&2
  exit 1
fi
cmp -s "$DEBUG_TRACE" "$ASAN_TRACE"

RELEASE_TRACE="$BUILD_ROOT/spindel-c-release.trace"
make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=0 \
  BUILD_DIR_BASE="$RELEASE_ROOT" native-core >/dev/null
clang_contract "$TOOL_ROOT/spindel-route-release" "$RELEASE_ROOT"
if ! "$TOOL_ROOT/spindel-route-release" "$RELEASE_TRACE" \
  "$BUILD_ROOT/save-release" >"$BUILD_ROOT/release.log" 2>&1; then
  cat "$BUILD_ROOT/release.log" >&2
  exit 1
fi
cmp -s "$DEBUG_TRACE" "$RELEASE_TRACE"

RERUN_TRACE="$BUILD_ROOT/spindel-c-rerun.trace"
if ! "$TOOL_ROOT/spindel-route-debug" "$RERUN_TRACE" "$BUILD_ROOT/save-rerun" \
  >"$BUILD_ROOT/rerun.log" 2>&1; then
  cat "$BUILD_ROOT/rerun.log" >&2
  exit 1
fi
cmp -s "$DEBUG_TRACE" "$RERUN_TRACE"

SWIFT_TRACE="$BUILD_ROOT/spindel-swift.trace"
TAMPER_TRACE="$BUILD_ROOT/spindel-tampered.trace"
PARTIAL_TRACE="$BUILD_ROOT/spindel-partial.trace"
WRONG_SUBJECT_TRACE="$BUILD_ROOT/spindel-wrong-subject.trace"
FIXTURE_TRACE="$BUILD_ROOT/spindel-fixture-only.trace"
GENERIC_BRIDGE_TRACE="$BUILD_ROOT/spindel-generic-bridge.trace"
DUPLICATE_TRACE="$BUILD_ROOT/spindel-duplicate.trace"
"$SWIFT_OUTPUT" write "$DEBUG_TRACE" "$SWIFT_TRACE" | tee "$BUILD_ROOT/swift.log"
if "$SWIFT_OUTPUT" write "$DEBUG_TRACE" "$SWIFT_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'spindel_persistent_rerun_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'spindel_persistent_rerun_rejected=1' | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$SWIFT_TRACE" | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" tamper "$SWIFT_TRACE" "$TAMPER_TRACE" | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" partial "$SWIFT_TRACE" "$PARTIAL_TRACE" | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" wrong-subject "$SWIFT_TRACE" "$WRONG_SUBJECT_TRACE" \
  | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" fixture-only "$SWIFT_TRACE" "$FIXTURE_TRACE" \
  | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" generic-bridge "$SWIFT_TRACE" "$GENERIC_BRIDGE_TRACE" \
  | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" duplicate "$SWIFT_TRACE" "$DUPLICATE_TRACE" \
  | tee -a "$BUILD_ROOT/swift.log"
grep -Fq 'spindel_pairing_audit admitted=1' "$BUILD_ROOT/swift.log"
grep -Fq 'spindel_tamper_rejected=1' "$BUILD_ROOT/swift.log"

if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$PARTIAL_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'spindel_partial_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'spindel_partial_rejected=1' | tee -a "$BUILD_ROOT/swift.log"
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$WRONG_SUBJECT_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'spindel_wrong_subject_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'spindel_wrong_subject_rejected=1' | tee -a "$BUILD_ROOT/swift.log"
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$FIXTURE_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'spindel_fixture_only_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'spindel_fixture_only_rejected=1' | tee -a "$BUILD_ROOT/swift.log"
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$GENERIC_BRIDGE_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'spindel_generic_bridge_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'spindel_generic_bridge_rejected=1' | tee -a "$BUILD_ROOT/swift.log"
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$DUPLICATE_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'spindel_duplicate_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'spindel_duplicate_rejected=1' | tee -a "$BUILD_ROOT/swift.log"
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$DEBUG_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'spindel_single_artifact_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'spindel_single_artifact_rejected=1' | tee -a "$BUILD_ROOT/swift.log"
cmp -s "$DEBUG_TRACE" "$SWIFT_TRACE"

git -c core.fsmonitor=false diff --check -- \
  src/game/behaviors/spindel.inc.c \
  src/pc/sm64_modern_gameplay_parity.c \
  src/pc/sm64_modern_spindel_route_identity.c \
  src/pc/sm64_modern_spindel_route_identity.h \
  tests/sm64_modern_spindel_route_pair_contract.c \
  tests/sm64_modern_spindel_route_swift_smoke.swift \
  script/test_spindel_route_pair.sh
printf '%s\n' \
  'SM64 Modern Spindel route pair passed exact_pair=1' \
  'source_receipts=script,object,collision,effect semantic_identity=1' \
  'debug_asan_release_rerun_match=1 swift_pair=1 tamper_rejected=1 persistent_rerun_rejected=1' \
  'partial_rejected=1 wrong_subject_rejected=1 fixture_only_rejected=1 generic_bridge_rejected=1 duplicate_rejected=1 single_artifact_rejected=1' \
  'admission=0 canonical_ledger_mutation=0 manifest_mutation=0' \
  "run_root=$BUILD_ROOT"
