#!/usr/bin/env bash
set -euo pipefail

# Phase 85am probes the first canonical transition row through the real native
# lifecycle.  It deliberately does not inject a floor, call level_trigger_warp
# directly, synthesize a route trace, or mutate the manifest/ledger.  A blocked
# result is the expected fail-closed outcome when authored movement does not
# reach the mario.c no-floor call site.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-transition-route-reachability"
NATIVE_ROOT="$BUILD_ROOT/native-debug"
PROBE="$BUILD_ROOT/transition-route-probe"
SAVE_ROOT="$BUILD_ROOT/save"
LOG="$BUILD_ROOT/reachability.log"

mkdir -p "$BUILD_ROOT" "$SAVE_ROOT"

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 \
  DEBUG=1 \
  BUILD_DIR_BASE="$NATIVE_ROOT" \
  native-core >/dev/null
test -f "$NATIVE_ROOT/us_pc/libsm64core.a"

xcrun --sdk macosx clang \
  -std=c11 -Wall -Wextra -Werror \
  -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
  -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  -I"$NATIVE_ROOT/us_pc" \
  "$PROJECT_ROOT/tests/sm64_modern_transition_route_probe.c" \
  "$NATIVE_ROOT/us_pc/libsm64core.a" \
  -o "$PROBE" -lm -lpthread

"$PROBE" "$SAVE_ROOT" | tee "$LOG"
grep -Fq \
  'transition_route_reachability blocked=1 triggered=0 steps=720 source=src/game/mario.c:1778 identity=level_trigger_warp native_authority=c lifecycle=owner_thread fabricated_warp=0' \
  "$LOG"

git -c core.fsmonitor=false diff --check
printf '%s\n' \
  'SM64 Modern transition-route reachability smoke passed blocked=1' \
  'source_backed_lifecycle=1 no_floor_route_reached=0 fabricated_warp=0' \
  'c_swift_pair=deferred native_recipe_blocked=1 manifest_mutation=0 ledger_mutation=0'
