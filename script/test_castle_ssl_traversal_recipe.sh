#!/usr/bin/env bash
set -euo pipefail

# Phase 85f114 is a bounded, read-only physical-input reachability attempt.
# The only startup selector is the existing Castle Grounds gameplay bootstrap;
# movement and camera input are fixed in the owner-thread probe.  A missing
# Castle Inside/SSL state is a hard route block (exit 77), with no trace or
# receipt promotion.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_PARENT="${SM64_CASTLE_SSL_RECIPE_BUILD_PARENT:-/private/tmp/sm64-modern-castle-ssl-recipe}"
mkdir -p "$BUILD_PARENT"
BUILD_ROOT="$(mktemp -d "$BUILD_PARENT/run.XXXXXX")"
NATIVE_ROOT="$BUILD_ROOT/native-debug"
TOOL_ROOT="$BUILD_ROOT/tool"
PROBE="$TOOL_ROOT/castle-ssl-recipe-probe"
SAVE_ROOT="$BUILD_ROOT/save"
LOG="$BUILD_ROOT/debug.log"
mkdir -p "$TOOL_ROOT" "$SAVE_ROOT"

grep -Fq 'MARIO_POS(/*area*/ 1, /*yaw*/ 180, /*pos*/ -1328, 260, 4664)' \
  "$PROJECT_ROOT/levels/castle_grounds/script.c"
grep -Fq 'WARP_NODE(/*id*/ 0x00, /*destLevel*/ LEVEL_CASTLE, /*destArea*/ 0x01' \
  "$PROJECT_ROOT/levels/castle_grounds/script.c"
for node in 0x0F 0x10 0x11; do
  grep -Fq "PAINTING_WARP_NODE(/*id*/ $node, /*destLevel*/ LEVEL_SSL, /*destArea*/ 0x01, /*destNode*/ 0x0A" \
    "$PROJECT_ROOT/levels/castle_inside/script.c"
done
grep -Fq 'macro_pokey' "$PROJECT_ROOT/levels/ssl/areas/1/macro.inc.c"

if rg -n 'initiate_warp|warp_level|warp_area|load_level|level_register|spawn_object|spawn_object_relative|bhv_pokey_(init|update|body_part_update)|sm64_modern_oracle_trace|fopen' \
  "$PROJECT_ROOT/tests/sm64_modern_castle_ssl_traversal_recipe_probe.c"; then
  echo 'castle_ssl_recipe_forbidden_operation_fence_failed=1' >&2
  exit 1
fi

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=1 \
  BUILD_DIR_BASE="$NATIVE_ROOT" native-core >"$BUILD_ROOT/native-build.log" 2>&1
test -f "$NATIVE_ROOT/us_pc/libsm64core.a"

xcrun --sdk macosx clang \
  -std=c11 -Wall -Wextra -Werror \
  -DNON_MATCHING=1 -DAVOID_UB=1 -DVERSION_US -D_LANGUAGE_C \
  -mmacosx-version-min=27.0 \
  -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  -I"$NATIVE_ROOT/us_pc" \
  "$PROJECT_ROOT/tests/sm64_modern_castle_ssl_traversal_recipe_probe.c" \
  "$NATIVE_ROOT/us_pc/libsm64core.a" \
  -o "$PROBE" -lm -lpthread

set +e
(cd "$PROJECT_ROOT" && "$PROBE" "$SAVE_ROOT") >"$LOG" 2>&1
probe_exit=$?
set -e
cat "$LOG"

if [[ "$probe_exit" -ne 77 ]]; then
  echo "castle_ssl_recipe_unexpected_exit=$probe_exit" >&2
  exit 1
fi
if find "$BUILD_ROOT" -type f \( -name '*.trace' -o -name '*.trace.tmp' \) -print -quit | grep -q .; then
  echo 'castle_ssl_recipe_trace_created_on_block=1' >&2
  exit 1
fi
grep -Fq \
  'castle_ssl_recipe reachability=0 castle_inside_step=3600 ssl_step=3600 final_level=16 final_area=1 steps=3600 lifecycle_status=0 shutdown_status=0 errors=0' \
  "$LOG"

git -c core.fsmonitor=false diff --check -- \
  tests/sm64_modern_castle_ssl_traversal_recipe_probe.c \
  script/test_castle_ssl_traversal_recipe.sh
printf '%s\n' \
  'SM64 Modern Castle->SSL traversal recipe blocked reachability=0 exit=77' \
  'source_lifecycle=castle_grounds_bootstrap_physical_input_to_castle_inside_nodes_0x0f_0x10_0x11_to_ssl_area1' \
  'final_level=16 final_area=1 steps=3600 castle_inside=unreached ssl=unreached trace=absent' \
  'native_debug=passed strict_probe=passed lifecycle_errors=0' \
  'direct_level_load=0 direct_warp=0 behavior_helper=0 object_injection=0 coordinate_selection=0' \
  'route_receipt=absent admission=0 canonical_ledger_mutation=0 manifest_mutation=0' \
  "run_root=$BUILD_ROOT"
exit 77
