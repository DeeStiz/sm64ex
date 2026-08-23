#!/usr/bin/env bash
set -euo pipefail

# Phase 85f53 exercises only the source-authored Castle Inside painting route
# (0x21, with 0x22/0x23 as its authored siblings) into TTC area 1. A missing
# first clock-hand receipt is a reachability block (exit 77), never a reason
# to load TTC directly, inject a macro object, call a behavior helper, or
# substitute a cog/static sibling. No manifest, ledger, or report is written.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_PARENT="${SM64_TTC_ROTATOR_ROUTE_BUILD_PARENT:-$PROJECT_ROOT/build/sm64-modern-ttc-2d-rotator-route-pair}"
mkdir -p "$BUILD_PARENT"
BUILD_ROOT="$(mktemp -d "$BUILD_PARENT/run.XXXXXX")"
TOOL_ROOT="$BUILD_ROOT/tool"
DEBUG_ROOT="$BUILD_ROOT/native-debug"
ASAN_ROOT="$BUILD_ROOT/native-asan"
RELEASE_ROOT="$BUILD_ROOT/native-release"
mkdir -p "$TOOL_ROOT/module-cache" "$BUILD_ROOT/save-debug" \
  "$BUILD_ROOT/save-asan" "$BUILD_ROOT/save-release" "$BUILD_ROOT/save-rerun"

grep -Fq 'PAINTING_WARP_NODE(/*id*/ 0x21, /*destLevel*/ LEVEL_TTC, /*destArea*/ 0x01' \
  "$PROJECT_ROOT/levels/castle_inside/script.c"
grep -Fq 'PAINTING_WARP_NODE(/*id*/ 0x22, /*destLevel*/ LEVEL_TTC, /*destArea*/ 0x01' \
  "$PROJECT_ROOT/levels/castle_inside/script.c"
grep -Fq 'PAINTING_WARP_NODE(/*id*/ 0x23, /*destLevel*/ LEVEL_TTC, /*destArea*/ 0x01' \
  "$PROJECT_ROOT/levels/castle_inside/script.c"
grep -Fq 'MACRO_OBJECT(/*preset*/ macro_ttc_clock_hand,        /*yaw*/ 225' \
  "$PROJECT_ROOT/levels/ttc/areas/1/macro.inc.c"
grep -Fq 'MODEL_TTC_CLOCK_HAND, 0' "$PROJECT_ROOT/include/macro_presets.h"
grep -Fq 'sm64_modern_ttc_rotator_route_observe' \
  "$PROJECT_ROOT/src/game/behaviors/ttc_2d_rotator.inc.c"
grep -Fq 'SOURCE_BEHAVIOR_IDENTITY(bhvTTC2DRotator)' \
  "$PROJECT_ROOT/src/pc/sm64_modern_gameplay_parity.c"
if rg -n 'uintptr_t|spawn_object|load_level|segmented_to_virtual|cur_obj_is_mario' \
  "$PROJECT_ROOT/src/pc/sm64_modern_ttc_rotator_route_identity.c"; then
  echo 'ttc_2d_rotator_route_pointer_or_helper_fence_failed=1' >&2
  exit 1
fi
if rg -n 'bhv_ttc_2d_rotator_(init|update)|spawn_object|load_level' \
  "$PROJECT_ROOT/tests/sm64_modern_ttc_2d_rotator_route_pair_contract.c"; then
  echo 'ttc_2d_rotator_route_probe_helper_fence_failed=1' >&2
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
    "$PROJECT_ROOT/tests/sm64_modern_ttc_2d_rotator_route_pair_contract.c" \
    "$archive_root/us_pc/libsm64core.a" -o "$output" -lm -lpthread "$@"
}

run_native() {
  local executable="$1" trace="$2" save_directory="$3" log="$4"
  SM64_MODERN_AUTOMATED_CASTLE_TTC_ROTATOR=1 \
    "$executable" "$trace" "$save_directory" >"$log" 2>&1
}

SWIFT_OUTPUT="$TOOL_ROOT/ttc-2d-rotator-route-swift"
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_ttc_2d_rotator_route_swift_smoke.swift" \
  -o "$SWIFT_OUTPUT"

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 \
  BUILD_DIR_BASE="$DEBUG_ROOT" native-core >/dev/null
clang_contract "$TOOL_ROOT/ttc-2d-rotator-route-debug" "$DEBUG_ROOT"
DEBUG_TRACE="$BUILD_ROOT/ttc-2d-rotator-c.trace"
set +e
run_native "$TOOL_ROOT/ttc-2d-rotator-route-debug" "$DEBUG_TRACE" \
  "$BUILD_ROOT/save-debug" "$BUILD_ROOT/debug.log"
debug_status=$?
set -e
if [[ "$debug_status" -ne 0 && "$debug_status" -ne 77 ]]; then
  cat "$BUILD_ROOT/debug.log" >&2
  exit "$debug_status"
fi
if [[ ! -s "$DEBUG_TRACE" ]]; then
  cat "$BUILD_ROOT/debug.log" >&2
  git -c core.fsmonitor=false diff --check -- \
    src/game/game_init.c \
    src/game/behaviors/ttc_2d_rotator.inc.c \
    src/pc/sm64_modern_gameplay_parity.c \
    src/pc/sm64_modern_ttc_rotator_route_identity.c \
    src/pc/sm64_modern_ttc_rotator_route_identity.h \
    tests/sm64_modern_ttc_2d_rotator_route_pair_contract.c \
    tests/sm64_modern_ttc_2d_rotator_route_swift_smoke.swift \
    script/test_ttc_2d_rotator_route_pair.sh
  printf '%s\n' \
    'SM64 Modern TTC 2D rotator route pair blocked reachability=0' \
    'source_lifecycle=castle_inside_painting_nodes_0x21_0x22_0x23_to_ttc_area1' \
    'first_clock_hand_receipt=absent cog_substitution=0 fixture_only=0' \
    'admission=0 canonical_ledger_mutation=0 manifest_mutation=0 exit=77'
  exit 77
fi

grep -Fq 'ttc_2d_rotator_route_debug oracle_end=0 result_status=0' "$BUILD_ROOT/debug.log"
grep -Eq 'c_ttc_2d_rotator_route_recorded shard=0x1af5669b06931d93 .* records=[1-9][0-9]*' \
  "$BUILD_ROOT/debug.log"

ASAN_TRACE="$BUILD_ROOT/ttc-2d-rotator-c-asan.trace"
make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
  BUILD_DIR_BASE="$ASAN_ROOT" native-core >/dev/null
clang_contract "$TOOL_ROOT/ttc-2d-rotator-route-asan" "$ASAN_ROOT" -fsanitize=address
if ! run_native "$TOOL_ROOT/ttc-2d-rotator-route-asan" "$ASAN_TRACE" \
    "$BUILD_ROOT/save-asan" "$BUILD_ROOT/asan.log"; then
  cat "$BUILD_ROOT/asan.log" >&2
  exit 1
fi
if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' \
  "$BUILD_ROOT/asan.log"; then
  echo 'ttc_2d_rotator_route_asan_finding=1' >&2
  exit 1
fi
cmp -s "$DEBUG_TRACE" "$ASAN_TRACE"

RELEASE_TRACE="$BUILD_ROOT/ttc-2d-rotator-c-release.trace"
make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=0 \
  BUILD_DIR_BASE="$RELEASE_ROOT" native-core >/dev/null
clang_contract "$TOOL_ROOT/ttc-2d-rotator-route-release" "$RELEASE_ROOT"
if ! run_native "$TOOL_ROOT/ttc-2d-rotator-route-release" "$RELEASE_TRACE" \
    "$BUILD_ROOT/save-release" "$BUILD_ROOT/release.log"; then
  cat "$BUILD_ROOT/release.log" >&2
  exit 1
fi
cmp -s "$DEBUG_TRACE" "$RELEASE_TRACE"

RERUN_TRACE="$BUILD_ROOT/ttc-2d-rotator-c-rerun.trace"
if ! run_native "$TOOL_ROOT/ttc-2d-rotator-route-debug" "$RERUN_TRACE" \
    "$BUILD_ROOT/save-rerun" "$BUILD_ROOT/rerun.log"; then
  cat "$BUILD_ROOT/rerun.log" >&2
  exit 1
fi
cmp -s "$DEBUG_TRACE" "$RERUN_TRACE"

SWIFT_TRACE="$BUILD_ROOT/ttc-2d-rotator-swift.trace"
TAMPER_TRACE="$BUILD_ROOT/ttc-2d-rotator-tampered.trace"
PARTIAL_TRACE="$BUILD_ROOT/ttc-2d-rotator-partial.trace"
VARIANT_TRACE="$BUILD_ROOT/ttc-2d-rotator-wrong-variant.trace"
DUPLICATE_TRACE="$BUILD_ROOT/ttc-2d-rotator-duplicate.trace"
"$SWIFT_OUTPUT" write "$DEBUG_TRACE" "$SWIFT_TRACE" | tee "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$SWIFT_TRACE" | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" tamper "$SWIFT_TRACE" "$TAMPER_TRACE" | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" partial "$SWIFT_TRACE" "$PARTIAL_TRACE" | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" wrong-variant "$SWIFT_TRACE" "$VARIANT_TRACE" | tee -a "$BUILD_ROOT/swift.log"
"$SWIFT_OUTPUT" duplicate "$SWIFT_TRACE" "$DUPLICATE_TRACE" | tee -a "$BUILD_ROOT/swift.log"
grep -Fq 'ttc_2d_rotator_pairing_audit admitted=1' "$BUILD_ROOT/swift.log"
grep -Fq 'ttc_2d_rotator_tamper_rejected=1' "$BUILD_ROOT/swift.log"

if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$PARTIAL_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'ttc_2d_rotator_partial_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'ttc_2d_rotator_partial_rejected=1' | tee -a "$BUILD_ROOT/swift.log"
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$VARIANT_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'ttc_2d_rotator_wrong_variant_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'ttc_2d_rotator_wrong_variant_rejected=1' | tee -a "$BUILD_ROOT/swift.log"
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$DUPLICATE_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'ttc_2d_rotator_duplicate_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'ttc_2d_rotator_duplicate_rejected=1' | tee -a "$BUILD_ROOT/swift.log"
if "$SWIFT_OUTPUT" audit "$DEBUG_TRACE" "$DEBUG_TRACE" \
    >>"$BUILD_ROOT/swift-negative.log" 2>&1; then
  echo 'ttc_2d_rotator_single_artifact_accepted=1' >&2
  exit 1
fi
printf '%s\n' 'ttc_2d_rotator_single_artifact_rejected=1' | tee -a "$BUILD_ROOT/swift.log"
cmp -s "$DEBUG_TRACE" "$SWIFT_TRACE"

git -c core.fsmonitor=false diff --check -- \
  src/game/game_init.c \
  src/game/behaviors/ttc_2d_rotator.inc.c \
  src/pc/sm64_modern_gameplay_parity.c \
  src/pc/sm64_modern_ttc_rotator_route_identity.c \
  src/pc/sm64_modern_ttc_rotator_route_identity.h \
  tests/sm64_modern_ttc_2d_rotator_route_pair_contract.c \
  tests/sm64_modern_ttc_2d_rotator_route_swift_smoke.swift \
  script/test_ttc_2d_rotator_route_pair.sh
printf '%s\n' \
  'SM64 Modern TTC 2D rotator route pair passed exact_pair=1' \
  'source_receipts=script,object,collision,effect semantic_identity=1' \
  'debug_asan_release_rerun_match=1 swift_pair=1 tamper_rejected=1' \
  'partial_rejected=1 wrong_variant_rejected=1 duplicate_rejected=1 single_artifact_rejected=1' \
  'admission=0 canonical_ledger_mutation=0 manifest_mutation=0' \
  "run_root=$BUILD_ROOT"
