#!/usr/bin/env bash
set -euo pipefail

# Phase 85f93 follows only the authored Castle Inside JRB painting family
# (nodes 0x09/0x0A/0x0B) into JRB area 1.  The native owner remains the sole
# producer of root/bottom/top receipts.  A missing source lifecycle is an
# explicit exit-77 block; it is never permission to load JRB directly, call a
# chest helper, inject a child, substitute a variant, match coordinates, or
# write a fixture trace.  No manifest, route report, ledger, or history is
# mutated here.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_PARENT="${SM64_TREASURE_CHEST_JRB_ROUTE_BUILD_PARENT:-$PROJECT_ROOT/build/sm64-modern-treasure-chest-jrb-route-pair}"
mkdir -p "$BUILD_PARENT"
BUILD_ROOT="$(mktemp -d "$BUILD_PARENT/run.XXXXXX")"
TOOL_ROOT="$BUILD_ROOT/tool"
DEBUG_ROOT="$BUILD_ROOT/native-debug"
ASAN_ROOT="$BUILD_ROOT/native-asan"
RELEASE_ROOT="$BUILD_ROOT/native-release"
DEBUG_TRACE="$BUILD_ROOT/treasure-chest-jrb-c.trace"
ASAN_TRACE="$BUILD_ROOT/treasure-chest-jrb-c-asan.trace"
RELEASE_TRACE="$BUILD_ROOT/treasure-chest-jrb-c-release.trace"
RERUN_TRACE="$BUILD_ROOT/treasure-chest-jrb-c-rerun.trace"
SWIFT_TRACE="$BUILD_ROOT/treasure-chest-jrb-swift.trace"
TAMPER_TRACE="$BUILD_ROOT/treasure-chest-jrb-tampered.trace"
PARTIAL_TRACE="$BUILD_ROOT/treasure-chest-jrb-partial.trace"
WRONG_VARIANT_TRACE="$BUILD_ROOT/treasure-chest-jrb-wrong-variant.trace"
DUPLICATE_TRACE="$BUILD_ROOT/treasure-chest-jrb-duplicate.trace"
FIXTURE_TRACE="$BUILD_ROOT/treasure-chest-jrb-fixture-only.trace"

mkdir -p "$TOOL_ROOT/module-cache" "$BUILD_ROOT/save-debug" \
  "$BUILD_ROOT/save-asan" "$BUILD_ROOT/save-release" "$BUILD_ROOT/save-rerun"

grep -Fq 'PAINTING_WARP_NODE(/*id*/ 0x09, /*destLevel*/ LEVEL_JRB, /*destArea*/ 0x01' \
  "$PROJECT_ROOT/levels/castle_inside/script.c"
grep -Fq 'PAINTING_WARP_NODE(/*id*/ 0x0A, /*destLevel*/ LEVEL_JRB, /*destArea*/ 0x01' \
  "$PROJECT_ROOT/levels/castle_inside/script.c"
grep -Fq 'PAINTING_WARP_NODE(/*id*/ 0x0B, /*destLevel*/ LEVEL_JRB, /*destArea*/ 0x01' \
  "$PROJECT_ROOT/levels/castle_inside/script.c"
grep -Fq 'bhvTreasureChestsJrb' "$PROJECT_ROOT/levels/jrb/script.c"
grep -Fq 'sm64_modern_treasure_chest_jrb_route_observe_root' \
  "$PROJECT_ROOT/src/game/behaviors/treasure_chest.inc.c"
grep -Fq 'sm64_modern_treasure_chest_jrb_route_observe_bottom' \
  "$PROJECT_ROOT/src/game/behaviors/treasure_chest.inc.c"
grep -Fq 'sm64_modern_treasure_chest_jrb_route_observe_top' \
  "$PROJECT_ROOT/src/game/behaviors/treasure_chest.inc.c"
grep -Fq 'SM64_MODERN_TREASURE_CHEST_JRB_ROUTE_SOURCE_ORDER' \
  "$PROJECT_ROOT/src/pc/sm64_modern_treasure_chest_jrb_route_identity.h"

if rg -n 'spawn_treasure_chest|spawn_object_relative|load_level|load_segment|initiate_warp' \
  "$PROJECT_ROOT/src/pc/sm64_modern_treasure_chest_jrb_route_identity.c" \
  "$PROJECT_ROOT/tests/sm64_modern_treasure_chest_jrb_route_pair_contract.c"; then
  echo 'treasure_chest_jrb_route_helper_or_direct_load_fence_failed=1' >&2
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
    "$PROJECT_ROOT/tests/sm64_modern_treasure_chest_jrb_route_pair_contract.c" \
    "$archive_root/us_pc/libsm64core.a" -o "$output" -lm -lpthread "$@"
}

SWIFT_OUTPUT="$TOOL_ROOT/treasure-chest-jrb-route-swift"
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_treasure_chest_jrb_route_swift_smoke.swift" \
  -o "$SWIFT_OUTPUT"

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 \
  BUILD_DIR_BASE="$DEBUG_ROOT" native-core >/dev/null
clang_contract "$TOOL_ROOT/treasure-chest-jrb-route-debug" "$DEBUG_ROOT"
set +e
"$TOOL_ROOT/treasure-chest-jrb-route-debug" "$DEBUG_TRACE" \
  "$BUILD_ROOT/save-debug" >"$BUILD_ROOT/debug.log" 2>&1
debug_rc=$?
set -e
if [[ "$debug_rc" -ne 0 && "$debug_rc" -ne 77 ]]; then
  cat "$BUILD_ROOT/debug.log" >&2
  exit "$debug_rc"
fi

if [[ "$debug_rc" -eq 77 || ! -s "$DEBUG_TRACE" ]]; then
  cat "$BUILD_ROOT/debug.log" >&2
  git -c core.fsmonitor=false diff --check -- \
    src/game/behaviors/treasure_chest.inc.c \
    src/pc/sm64_modern_treasure_chest_jrb_route_identity.c \
    src/pc/sm64_modern_treasure_chest_jrb_route_identity.h \
    tests/sm64_modern_treasure_chest_jrb_route_pair_contract.c \
    tests/sm64_modern_treasure_chest_jrb_route_swift_smoke.swift \
    script/test_treasure_chest_jrb_route_pair.sh
  printf '%s\n' \
    'SM64 Modern JRB treasure-chest route pair blocked reachability=0' \
    'source_lifecycle=castle_inside_painting_nodes_0x09_0x0a_0x0b_to_jrb_area1' \
    'root_child_receipts=absent source_child_ordinals=1,2,3,4' \
    'synthetic_trace=0 direct_level_load=0 child_injection=0 variant_substitution=0' \
    'admission=0 canonical_ledger_mutation=0 manifest_mutation=0 exit=77'
  exit 77
fi
if [[ "$debug_rc" -ne 0 ]]; then
  cat "$BUILD_ROOT/debug.log" >&2
  exit "$debug_rc"
fi

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
  BUILD_DIR_BASE="$ASAN_ROOT" native-core >/dev/null
clang_contract "$TOOL_ROOT/treasure-chest-jrb-route-asan" "$ASAN_ROOT" -fsanitize=address
set +e
ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
  "$TOOL_ROOT/treasure-chest-jrb-route-asan" "$ASAN_TRACE" \
  "$BUILD_ROOT/save-asan" >"$BUILD_ROOT/asan.log" 2>&1
asan_rc=$?
set -e
if [[ "$asan_rc" -eq 77 ]]; then exit 77; fi
if [[ "$asan_rc" -ne 0 ]]; then
  cat "$BUILD_ROOT/asan.log" >&2
  exit "$asan_rc"
fi
if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' \
  "$BUILD_ROOT/asan.log"; then
  echo 'treasure_chest_jrb_route_asan_finding=1' >&2
  exit 1
fi

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=0 \
  BUILD_DIR_BASE="$RELEASE_ROOT" native-core >/dev/null
clang_contract "$TOOL_ROOT/treasure-chest-jrb-route-release" "$RELEASE_ROOT"
"$TOOL_ROOT/treasure-chest-jrb-route-release" "$RELEASE_TRACE" \
  "$BUILD_ROOT/save-release" >"$BUILD_ROOT/release.log" 2>&1
"$TOOL_ROOT/treasure-chest-jrb-route-debug" "$RERUN_TRACE" \
  "$BUILD_ROOT/save-rerun" >"$BUILD_ROOT/rerun.log" 2>&1
cmp -s "$DEBUG_TRACE" "$ASAN_TRACE"
cmp -s "$DEBUG_TRACE" "$RELEASE_TRACE"
cmp -s "$DEBUG_TRACE" "$RERUN_TRACE"

"$SWIFT_OUTPUT" write "$DEBUG_TRACE" "$SWIFT_TRACE" >"$BUILD_ROOT/swift.log"
if "$SWIFT_OUTPUT" write "$DEBUG_TRACE" "$SWIFT_TRACE" \
  >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'treasure_chest_jrb_persistent_rerun_accepted=1' >&2
  exit 1
fi
"$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$SWIFT_TRACE" >>"$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" tamper "$SWIFT_TRACE" "$TAMPER_TRACE" >>"$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" partial "$SWIFT_TRACE" "$PARTIAL_TRACE"
"$SWIFT_OUTPUT" wrong-variant "$SWIFT_TRACE" "$WRONG_VARIANT_TRACE"
"$SWIFT_OUTPUT" duplicate "$SWIFT_TRACE" "$DUPLICATE_TRACE"
"$SWIFT_OUTPUT" fixture-only "$SWIFT_TRACE" "$FIXTURE_TRACE"

if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$PARTIAL_TRACE" >"$BUILD_ROOT/partial.log" 2>&1; then
  echo 'treasure_chest_jrb_partial_accepted=1' >&2
  exit 1
fi
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$WRONG_VARIANT_TRACE" >"$BUILD_ROOT/wrong-variant.log" 2>&1; then
  echo 'treasure_chest_jrb_wrong_variant_accepted=1' >&2
  exit 1
fi
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$DUPLICATE_TRACE" >"$BUILD_ROOT/duplicate.log" 2>&1; then
  echo 'treasure_chest_jrb_duplicate_accepted=1' >&2
  exit 1
fi
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$FIXTURE_TRACE" >"$BUILD_ROOT/fixture.log" 2>&1; then
  echo 'treasure_chest_jrb_fixture_only_accepted=1' >&2
  exit 1
fi
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$DEBUG_TRACE" >"$BUILD_ROOT/single.log" 2>&1; then
  echo 'treasure_chest_jrb_single_artifact_accepted=1' >&2
  exit 1
fi

git -c core.fsmonitor=false diff --check -- \
  src/game/behaviors/treasure_chest.inc.c \
  src/pc/sm64_modern_treasure_chest_jrb_route_identity.c \
  src/pc/sm64_modern_treasure_chest_jrb_route_identity.h \
  tests/sm64_modern_treasure_chest_jrb_route_pair_contract.c \
  tests/sm64_modern_treasure_chest_jrb_route_swift_smoke.swift \
  script/test_treasure_chest_jrb_route_pair.sh
printf '%s\n' \
  'SM64 Modern JRB treasure-chest route pair passed exact_pair=1' \
  'source_receipts=script_events,object_state,collision_queries,effects semantic_identity=1' \
  'debug_asan_release_rerun_match=1 swift_pair=1 tamper_rejected=1' \
  'partial_rejected=1 wrong_variant_rejected=1 duplicate_rejected=1 single_artifact_rejected=1' \
  'fixture_only_rejected=1 persistent_rerun_rejected=1 admission=0 manifest_mutation=0' \
  "run_root=$BUILD_ROOT"
