#!/usr/bin/env bash
set -euo pipefail

# Phase 85f97 follows only Castle Inside's authored WF painting family into
# WF area 1 ACT_1.  Reachability is fail-closed (exit 77); this script never
# direct-loads/registers WF, calls a behavior/collision helper, injects a
# Whomp or star, substitutes a small Whomp, matches coordinates, or mutates a
# manifest/report/ledger.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_PARENT="${SM64_WHOMP_KING_ROUTE_BUILD_PARENT:-$PROJECT_ROOT/build/sm64-modern-whomp-king-route-pair}"
mkdir -p "$BUILD_PARENT"
BUILD_ROOT="$(mktemp -d "$BUILD_PARENT/run.XXXXXX")"
TOOL_ROOT="$BUILD_ROOT/tool"
DEBUG_ROOT="$BUILD_ROOT/native-debug"
ASAN_ROOT="$BUILD_ROOT/native-asan"
RELEASE_ROOT="$BUILD_ROOT/native-release"
mkdir -p "$TOOL_ROOT/module-cache" "$BUILD_ROOT/save-debug" \
  "$BUILD_ROOT/save-asan" "$BUILD_ROOT/save-release" "$BUILD_ROOT/save-rerun"

grep -Fq 'PAINTING_WARP_NODE(/*id*/ 0x06, /*destLevel*/ LEVEL_WF, /*destArea*/ 0x01' \
  "$PROJECT_ROOT/levels/castle_inside/script.c"
grep -Fq 'PAINTING_WARP_NODE(/*id*/ 0x07, /*destLevel*/ LEVEL_WF, /*destArea*/ 0x01' \
  "$PROJECT_ROOT/levels/castle_inside/script.c"
grep -Fq 'PAINTING_WARP_NODE(/*id*/ 0x08, /*destLevel*/ LEVEL_WF, /*destArea*/ 0x01' \
  "$PROJECT_ROOT/levels/castle_inside/script.c"
grep -Fq 'OBJECT_WITH_ACTS(/*model*/ MODEL_WHOMP, /*pos*/     0, 3584,    0' \
  "$PROJECT_ROOT/levels/wf/script.c"
grep -Fq '/*beh*/ bhvWhompKingBoss' "$PROJECT_ROOT/levels/wf/script.c"
grep -Fq '/*acts*/ ACT_1' "$PROJECT_ROOT/levels/wf/script.c"
grep -Fq 'sm64_modern_whomp_king_route_observe' \
  "$PROJECT_ROOT/src/game/behaviors/whomp.inc.c"
grep -Fq 'SM64_MODERN_WHOMP_KING_ROUTE_BEHAVIOR_ID' \
  "$PROJECT_ROOT/src/pc/sm64_modern_whomp_king_route_identity.h"
grep -Fq 'SOURCE_BEHAVIOR_IDENTITY(bhvWhompKingBoss)' \
  "$PROJECT_ROOT/src/pc/sm64_modern_gameplay_parity.c"
grep -Fq 'SOURCE_BEHAVIOR_IDENTITY(bhvStarSpawnCoordinates)' \
  "$PROJECT_ROOT/src/pc/sm64_modern_gameplay_parity.c"

if rg -n 'uintptr_t|spawn_object|load_level|level_register|segmented_to_virtual|cur_obj_|gMarioObject' \
  "$PROJECT_ROOT/src/pc/sm64_modern_whomp_king_route_identity.c"; then
  echo 'whomp_king_route_pointer_or_helper_fence_failed=1' >&2
  exit 1
fi
if rg -n 'bhv_whomp_(loop|act)|cur_obj_|spawn_object|load_level|level_register|setenv' \
  "$PROJECT_ROOT/tests/sm64_modern_whomp_king_route_pair_contract.c"; then
  echo 'whomp_king_route_probe_helper_fence_failed=1' >&2
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
    "$PROJECT_ROOT/tests/sm64_modern_whomp_king_route_pair_contract.c" \
    "$archive_root/us_pc/libsm64core.a" -o "$output" -lm -lpthread "$@"
}

SWIFT_OUTPUT="$TOOL_ROOT/whomp-king-route-swift"
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_whomp_king_route_swift_smoke.swift" \
  -o "$SWIFT_OUTPUT"

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 \
  BUILD_DIR_BASE="$DEBUG_ROOT" native-core >/dev/null
clang_contract "$TOOL_ROOT/whomp-king-route-debug" "$DEBUG_ROOT"
DEBUG_TRACE="$BUILD_ROOT/whomp-king-c.trace"
set +e
"$TOOL_ROOT/whomp-king-route-debug" "$DEBUG_TRACE" \
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
    src/game/behaviors/whomp.inc.c \
    src/pc/sm64_modern_gameplay_parity.c \
    src/pc/sm64_modern_whomp_king_route_identity.c \
    src/pc/sm64_modern_whomp_king_route_identity.h \
    tests/sm64_modern_whomp_king_route_pair_contract.c \
    tests/sm64_modern_whomp_king_route_swift_smoke.swift \
    script/test_whomp_king_route_pair.sh
  printf '%s\n' \
    'SM64 Modern Whomp King route pair blocked reachability=0' \
    'source_lifecycle=castle_inside_painting_nodes_0x06_0x07_0x08_to_wf_area1_act1' \
    'first_king_receipt=absent small_whomp_substitution=0 coordinate_matching=0 fixture_only=0' \
    'admission=0 canonical_ledger_mutation=0 manifest_mutation=0 exit=77'
  exit 77
fi

grep -Fq 'whomp_king_route_debug oracle_end=0 result_status=0' \
  "$BUILD_ROOT/debug.log"
grep -Eq 'c_whomp_king_route_recorded shard=0x28e0617bfc286cbe .* records=[1-9][0-9]*' \
  "$BUILD_ROOT/debug.log"

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
  BUILD_DIR_BASE="$ASAN_ROOT" native-core >/dev/null
clang_contract "$TOOL_ROOT/whomp-king-route-asan" "$ASAN_ROOT" -fsanitize=address
ASAN_TRACE="$BUILD_ROOT/whomp-king-c-asan.trace"
if ! ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
  "$TOOL_ROOT/whomp-king-route-asan" "$ASAN_TRACE" \
  "$BUILD_ROOT/save-asan" >"$BUILD_ROOT/asan.log" 2>&1; then
  cat "$BUILD_ROOT/asan.log" >&2
  exit 1
fi
if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' \
  "$BUILD_ROOT/asan.log"; then
  echo 'whomp_king_route_asan_finding=1' >&2
  exit 1
fi
cmp -s "$DEBUG_TRACE" "$ASAN_TRACE"

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=0 \
  BUILD_DIR_BASE="$RELEASE_ROOT" native-core >/dev/null
clang_contract "$TOOL_ROOT/whomp-king-route-release" "$RELEASE_ROOT"
RELEASE_TRACE="$BUILD_ROOT/whomp-king-c-release.trace"
"$TOOL_ROOT/whomp-king-route-release" "$RELEASE_TRACE" \
  "$BUILD_ROOT/save-release" >"$BUILD_ROOT/release.log" 2>&1

RERUN_TRACE="$BUILD_ROOT/whomp-king-c-rerun.trace"
"$TOOL_ROOT/whomp-king-route-debug" "$RERUN_TRACE" \
  "$BUILD_ROOT/save-rerun" >"$BUILD_ROOT/rerun.log" 2>&1
cmp -s "$DEBUG_TRACE" "$RELEASE_TRACE"
cmp -s "$DEBUG_TRACE" "$RERUN_TRACE"

SWIFT_TRACE="$BUILD_ROOT/whomp-king-swift.trace"
TAMPER_TRACE="$BUILD_ROOT/whomp-king-tampered.trace"
PARTIAL_TRACE="$BUILD_ROOT/whomp-king-partial.trace"
WRONG_VARIANT_TRACE="$BUILD_ROOT/whomp-king-wrong-variant.trace"
WRONG_SUBJECT_TRACE="$BUILD_ROOT/whomp-king-wrong-subject.trace"
GENERIC_BRIDGE_TRACE="$BUILD_ROOT/whomp-king-generic-bridge.trace"
FIXTURE_TRACE="$BUILD_ROOT/whomp-king-fixture-only.trace"
DUPLICATE_TRACE="$BUILD_ROOT/whomp-king-duplicate.trace"

"$SWIFT_OUTPUT" write "$DEBUG_TRACE" "$SWIFT_TRACE" \
  | tee "$BUILD_ROOT/swift.log"
if "$SWIFT_OUTPUT" write "$DEBUG_TRACE" "$SWIFT_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'whomp_king_persistent_rerun_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'whomp_king_persistent_rerun_rejected=1' \
  | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$SWIFT_TRACE" \
  | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" tamper "$SWIFT_TRACE" "$TAMPER_TRACE" \
  | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" partial "$SWIFT_TRACE" "$PARTIAL_TRACE" \
  | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" wrong-variant "$SWIFT_TRACE" "$WRONG_VARIANT_TRACE" \
  | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" wrong-subject "$SWIFT_TRACE" "$WRONG_SUBJECT_TRACE" \
  | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" generic-bridge "$SWIFT_TRACE" "$GENERIC_BRIDGE_TRACE" \
  | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" fixture-only "$SWIFT_TRACE" "$FIXTURE_TRACE" \
  | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" duplicate "$SWIFT_TRACE" "$DUPLICATE_TRACE" \
  | tee -a "$BUILD_ROOT/swift.log"
grep -Fq 'whomp_king_pairing_audit admitted=1' "$BUILD_ROOT/swift.log"
grep -Fq 'whomp_king_tamper_rejected=1' "$BUILD_ROOT/swift.log"

if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$PARTIAL_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'whomp_king_partial_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'whomp_king_partial_rejected=1' | tee -a "$BUILD_ROOT/swift.log"
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$WRONG_VARIANT_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'whomp_king_wrong_variant_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'whomp_king_wrong_variant_rejected=1' \
  | tee -a "$BUILD_ROOT/swift.log"
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$WRONG_SUBJECT_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'whomp_king_wrong_subject_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'whomp_king_wrong_subject_rejected=1' \
  | tee -a "$BUILD_ROOT/swift.log"
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$GENERIC_BRIDGE_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'whomp_king_generic_bridge_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'whomp_king_generic_bridge_rejected=1' \
  | tee -a "$BUILD_ROOT/swift.log"
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$FIXTURE_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'whomp_king_fixture_only_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'whomp_king_fixture_only_rejected=1' \
  | tee -a "$BUILD_ROOT/swift.log"
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$DUPLICATE_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'whomp_king_duplicate_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'whomp_king_duplicate_rejected=1' \
  | tee -a "$BUILD_ROOT/swift.log"
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$DEBUG_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'whomp_king_single_artifact_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'whomp_king_single_artifact_rejected=1' \
  | tee -a "$BUILD_ROOT/swift.log"
cmp -s "$DEBUG_TRACE" "$SWIFT_TRACE"

git -c core.fsmonitor=false diff --check -- \
  src/game/behaviors/whomp.inc.c \
  src/pc/sm64_modern_gameplay_parity.c \
  src/pc/sm64_modern_whomp_king_route_identity.c \
  src/pc/sm64_modern_whomp_king_route_identity.h \
  tests/sm64_modern_whomp_king_route_pair_contract.c \
  tests/sm64_modern_whomp_king_route_swift_smoke.swift \
  script/test_whomp_king_route_pair.sh
printf '%s\n' \
  'SM64 Modern WF Whomp King route pair passed exact_pair=1' \
  'source_receipts=script,object,collision,effect semantic_king_identity=1 reward_child_identity=1' \
  'debug_asan_release_rerun_match=1 swift_pair=1 tamper_rejected=1 persistent_rerun_rejected=1' \
  'partial_rejected=1 wrong_variant_rejected=1 wrong_subject_rejected=1 generic_bridge_rejected=1' \
  'fixture_only_rejected=1 duplicate_rejected=1 single_artifact_rejected=1' \
  'admission=0 canonical_ledger_mutation=0 manifest_mutation=0' \
  "run_root=$BUILD_ROOT"
