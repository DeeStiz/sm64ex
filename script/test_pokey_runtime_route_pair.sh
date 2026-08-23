#!/usr/bin/env bash
set -euo pipefail

# Phase 85f110 attempts only the ordinary Castle Inside painting family
# 0x0F/0x10/0x11 -> SSL area 1.  The probe starts at the source Castle
# Grounds bootstrap and uses physical input only.  It never direct-loads or
# warps SSL, calls a Pokey helper, injects an object, selects a coordinate, or
# synthesizes a trace.  No trace means a hard reachability block (exit 77).
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_PARENT="${SM64_POKEY_RUNTIME_ROUTE_BUILD_PARENT:-$PROJECT_ROOT/build/sm64-modern-pokey-runtime-route-pair}"
mkdir -p "$BUILD_PARENT"
BUILD_ROOT="$(mktemp -d "$BUILD_PARENT/run.XXXXXX")"
NATIVE_ROOT="$BUILD_ROOT/native-debug"
TOOL_ROOT="$BUILD_ROOT/tool"
PROBE="$TOOL_ROOT/pokey-runtime-route-probe"
SAVE_ROOT="$BUILD_ROOT/save-debug"
LOG="$BUILD_ROOT/debug.log"
mkdir -p "$TOOL_ROOT" "$SAVE_ROOT" "$TOOL_ROOT/module-cache"

for node in 0x0F 0x10 0x11; do
  grep -Fq "PAINTING_WARP_NODE(/*id*/ $node, /*destLevel*/ LEVEL_SSL, /*destArea*/ 0x01" \
    "$PROJECT_ROOT/levels/castle_inside/script.c"
done
grep -Fq 'macro_pokey' "$PROJECT_ROOT/levels/ssl/areas/1/macro.inc.c"
grep -Fq 'bhvPokey' "$PROJECT_ROOT/include/macro_presets.h"
grep -Fq 'const BehaviorScript bhvPokey[]' "$PROJECT_ROOT/data/behavior_data.c"
grep -Fq 'const BehaviorScript bhvPokeyBodyPart[]' "$PROJECT_ROOT/data/behavior_data.c"

if rg -n 'initiate_warp|warp_level|warp_area|load_level|level_register|spawn_object|spawn_object_relative|bhv_pokey_(init|update|body_part_update)|sm64_modern_oracle_trace_begin|fopen' \
  "$PROJECT_ROOT/tests/sm64_modern_pokey_runtime_route_probe.c"; then
  echo 'pokey_runtime_route_probe_forbidden_operation_fence_failed=1' >&2
  exit 1
fi

# Keep the strengthened f109 C/Swift schema mirror green before the runtime
# attempt.  It is not a runtime receipt and cannot promote this route.
SM64_POKEY_STATIC_BUILD_ROOT="$BUILD_ROOT/static" \
  "$PROJECT_ROOT/script/test_pokey_route_static.sh" >"$BUILD_ROOT/static.log"

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=1 \
  BUILD_DIR_BASE="$NATIVE_ROOT" native-core >/dev/null
test -f "$NATIVE_ROOT/us_pc/libsm64core.a"

xcrun --sdk macosx clang \
  -std=c11 -Wall -Wextra -Werror \
  -DNON_MATCHING=1 -DAVOID_UB=1 -DVERSION_US -D_LANGUAGE_C \
  -mmacosx-version-min=27.0 \
  -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  -I"$NATIVE_ROOT/us_pc" \
  "$PROJECT_ROOT/tests/sm64_modern_pokey_runtime_route_probe.c" \
  "$NATIVE_ROOT/us_pc/libsm64core.a" \
  -o "$PROBE" -lm -lpthread

set +e
"$PROBE" "$SAVE_ROOT" >"$LOG" 2>&1
probe_status=$?
set -e
cat "$LOG"

if [[ "$probe_status" -ne 77 ]]; then
  echo "pokey_runtime_route_unexpected_exit=$probe_status" >&2
  exit 1
fi
if find "$BUILD_ROOT" -type f \( -name '*.trace' -o -name '*.trace.tmp' \) -print -quit | grep -q .; then
  echo 'pokey_runtime_route_trace_created_on_block=1' >&2
  exit 1
fi
grep -Fq \
  'pokey_runtime_route reachability=0 ssl_step=1800 pokey_step=1800 pokey_objects=0 final_level=16 final_area=1 steps=1800 lifecycle_status=0 shutdown_status=0 errors=0' \
  "$LOG"

git -c core.fsmonitor=false diff --check -- \
  tests/sm64_modern_pokey_runtime_route_probe.c \
  script/test_pokey_runtime_route_pair.sh
printf '%s\n' \
  'SM64 Modern Pokey runtime route blocked reachability=0 exit=77' \
  'source_lifecycle=castle_grounds_input_bootstrap_to_castle_inside_painting_nodes_0x0f_0x10_0x11_to_ssl_area1' \
  'final_level=16 final_area=1 steps=1800 pokey_objects=0 trace=absent' \
  'f109_c_swift_schema_mirror=passed runtime_receipt=absent admission=0' \
  'canonical_ledger_mutation=0 manifest_mutation=0' \
  "run_root=$BUILD_ROOT"
exit 77
