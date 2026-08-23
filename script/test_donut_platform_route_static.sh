#!/usr/bin/env bash
set -euo pipefail

# Static-only Phase 85f104 contract.  The authored Castle Inside node 0x2A
# remains the only permitted runtime route; no RR load/warp, helper call,
# object injection, coordinate-selected child, trace, or ledger write occurs.
bash -n "$0"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="${SM64_DONUT_STATIC_BUILD_ROOT:-$PROJECT_ROOT/build/sm64-modern-donut-static}"
mkdir -p "$BUILD_ROOT"

grep -Fq 'PAINTING_WARP_NODE(/*id*/ 0x2A, /*destLevel*/ LEVEL_RR, /*destArea*/ 0x01' \
  "$PROJECT_ROOT/levels/castle_inside/script.c"
grep -Fq 'bhvDonutPlatformSpawner' "$PROJECT_ROOT/levels/rr/script.c"
grep -Fq 'sDonutPlatformPositions' "$PROJECT_ROOT/src/game/behaviors/donut_platform.inc.c"
grep -Fq 'MODEL_RR_DONUT_PLATFORM' "$PROJECT_ROOT/src/game/behaviors/donut_platform.inc.c"

if rg -n 'uintptr_t|OpaquePointer|Unsafe|spawn_object|spawn_object_relative|load_level|level_register|cur_obj_|gMarioObject' \
  "$PROJECT_ROOT/src/pc/sm64_modern_donut_platform_route_identity.c" \
  "$PROJECT_ROOT/tests/sm64_modern_donut_platform_route_contract.c"; then
  echo 'donut_platform_static_pointer_or_helper_fence_failed=1' >&2
  exit 1
fi

clang_cmd=(xcrun --sdk macosx clang -std=c11 -Wall -Wextra -Werror
  -DNON_MATCHING=1 -DAVOID_UB=1 -DVERSION_US -D_LANGUAGE_C
  -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src")
"${clang_cmd[@]}" -fsyntax-only \
  "$PROJECT_ROOT/src/pc/sm64_modern_donut_platform_route_identity.c"
"${clang_cmd[@]}" \
  "$PROJECT_ROOT/tests/sm64_modern_donut_platform_route_contract.c" \
  "$PROJECT_ROOT/src/pc/sm64_modern_donut_platform_route_identity.c" \
  -o "$BUILD_ROOT/donut-platform-route-contract"
"$BUILD_ROOT/donut-platform-route-contract" | tee "$BUILD_ROOT/contract.log"
grep -Fq 'SM64 Modern Donut Platform route C contract passed' \
  "$BUILD_ROOT/contract.log"
git -c core.fsmonitor=false diff --check -- \
  src/pc/sm64_modern_donut_platform_route_identity.c \
  src/pc/sm64_modern_donut_platform_route_identity.h \
  tests/sm64_modern_donut_platform_route_contract.c \
  script/test_donut_platform_route_static.sh
printf '%s\n' \
  'SM64 Modern Donut Platform static route contract passed' \
  'semantic_parent_child_identity=1 source_31_child_table=1 pointer_free=1' \
  'runtime_receipt=absent castle_to_rr_reachability=unproven' \
  'admission=0 canonical_ledger_mutation=0 manifest_mutation=0'
