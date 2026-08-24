#!/usr/bin/env bash
set -euo pipefail

# Phase 85f8 owns only the bounded source-reachability check for the planned
# Snowman's Land Moneybag random_float shard.  It intentionally stops before
# creating a Swift mirror or touching the canonical route ledger.

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-phase85f8-rng-float-reachability"
TOOL_ROOT="$BUILD_ROOT/tools"
RUN_ROOT="$BUILD_ROOT/run"
SAVE_ROOT="$RUN_ROOT/save"
mkdir -p "$TOOL_ROOT" "$RUN_ROOT" "$SAVE_ROOT"

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 \
  DEBUG=1 \
  BUILD_DIR_BASE="${BUILD_ROOT}/native" \
  native-core \
  >"$RUN_ROOT/native-build.log" 2>&1

xcrun --sdk macosx clang \
  -std=c11 -Wall -Wextra -Werror \
  -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
  -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  -I"${BUILD_ROOT}/native/us_pc" \
  "$PROJECT_ROOT/tests/sm64_modern_rng_float_route_probe.c" \
  "${BUILD_ROOT}/native/us_pc/libsm64core.a" \
  -o "$TOOL_ROOT/sm64-modern-phase85f8-rng-float-reachability" \
  -lm -lpthread

"$TOOL_ROOT/sm64-modern-phase85f8-rng-float-reachability" "$SAVE_ROOT" \
  >"$RUN_ROOT/probe.log" 2>&1

grep -Fq 'INIT status=0 level=1 area=0 moneybags=0' "$RUN_ROOT/probe.log"
grep -Fq 'STEP 0 status=0 level=10 area=2 moneybags=0 matches=0' "$RUN_ROOT/probe.log"
grep -Fq 'WARP requested level=10 area=1 node=0x0b' "$RUN_ROOT/probe.log"
grep -Fq 'PROBE ok=1 errors=0 records=9598 route_records=0 matches=0 reads=240' "$RUN_ROOT/probe.log"

# Source reachability fences: the authored Moneybags are area-1 macro objects,
# while the initialized automated lifecycle is observed in area 2.  Keep these
# checks source-backed and fail closed if the level data changes.
test "$(rg -c 'MACRO_OBJECT\(/\*preset\*/ macro_moneybag' \
  "$PROJECT_ROOT/levels/sl/areas/1/macro.inc.c")" -eq 2
if rg -q 'MACRO_OBJECT\(/\*preset\*/ macro_moneybag' \
  "$PROJECT_ROOT/levels/sl/areas/2/macro.inc.c"; then
  echo 'unexpected authored area-2 Moneybag macro' >&2
  exit 1
fi
rg -q 'void obj_return_and_displace_home\(' "$PROJECT_ROOT/src/game/obj_behaviors.c"
rg -q 'obj_return_and_displace_home\(o,' \
  "$PROJECT_ROOT/src/game/behaviors/moneybag.inc.c"
rg -q 'SM64_MODERN_AUTOMATED_SL_MONEYBAG' "$PROJECT_ROOT/src/game/game_init.c"

printf '%s\n' \
  'phase85f8_rng_float_reachability=fail_closed' \
  'phase85f8_native_build=passed' \
  'phase85f8_probe=passed' \
  'phase85f8_source_moneybags_area1=2' \
  'phase85f8_runtime_moneybags_area2=0' \
  'phase85f8_route_records=0' \
  'phase85f8_swift_pair=not_attempted' \
  'phase85f8_canonical_mutation=0' \
  "phase85f8_run_root=$RUN_ROOT"
