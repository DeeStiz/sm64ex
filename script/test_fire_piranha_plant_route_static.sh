#!/usr/bin/env bash
set -euo pipefail

# Phase 85f101 is a static, pointer-free seam only.  The ordinary Castle
# Inside -> THI painting route remains the sole allowed runtime path; this
# script never direct-loads THI, calls a behavior helper, injects an object,
# synthesizes a flame/star, or mutates a manifest, ledger, or report.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="${SM64_FIRE_PIRANHA_STATIC_BUILD_ROOT:-$PROJECT_ROOT/build/sm64-modern-fire-piranha-static}"
mkdir -p "$BUILD_ROOT"

grep -Fq 'PAINTING_WARP_NODE(/*id*/ 0x27, /*destLevel*/ LEVEL_THI, /*destArea*/ 0x01' \
  "$PROJECT_ROOT/levels/castle_inside/script.c"
grep -Fq 'PAINTING_WARP_NODE(/*id*/ 0x28, /*destLevel*/ LEVEL_THI, /*destArea*/ 0x01' \
  "$PROJECT_ROOT/levels/castle_inside/script.c"
grep -Fq 'PAINTING_WARP_NODE(/*id*/ 0x29, /*destLevel*/ LEVEL_THI, /*destArea*/ 0x01' \
  "$PROJECT_ROOT/levels/castle_inside/script.c"
grep -Fq 'bhvFirePiranhaPlant' "$PROJECT_ROOT/levels/thi/script.c"
grep -Fq 'MODEL_PIRANHA_PLANT' "$PROJECT_ROOT/levels/thi/script.c"
grep -Fq 'sm64_modern_fire_piranha_plant_route_identity.h' \
  "$PROJECT_ROOT/src/pc/sm64_modern_fire_piranha_plant_route_identity.c"

if rg -n 'uintptr_t|OpaquePointer|Unsafe|spawn_object|spawn_default_star|obj_spit_fire|load_level|level_register|segmented_to_virtual|cur_obj_' \
  "$PROJECT_ROOT/src/pc/sm64_modern_fire_piranha_plant_route_identity.c" \
  "$PROJECT_ROOT/tests/sm64_modern_fire_piranha_plant_route_contract.c"; then
  echo 'fire_piranha_static_pointer_or_helper_fence_failed=1' >&2
  exit 1
fi

clang_cmd=(xcrun --sdk macosx clang -std=c11 -Wall -Wextra -Werror
  -DNON_MATCHING=1 -DAVOID_UB=1 -DVERSION_US -D_LANGUAGE_C
  -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src")
"${clang_cmd[@]}" -fsyntax-only \
  "$PROJECT_ROOT/src/pc/sm64_modern_fire_piranha_plant_route_identity.c"
"${clang_cmd[@]}" \
  "$PROJECT_ROOT/tests/sm64_modern_fire_piranha_plant_route_contract.c" \
  -o "$BUILD_ROOT/fire-piranha-route-contract"
"$BUILD_ROOT/fire-piranha-route-contract" | tee "$BUILD_ROOT/contract.log"
grep -Fq 'SM64 Modern Fire Piranha Plant route C contract passed' \
  "$BUILD_ROOT/contract.log"

git -c core.fsmonitor=false diff --check -- \
  src/pc/sm64_modern_fire_piranha_plant_route_identity.c \
  src/pc/sm64_modern_fire_piranha_plant_route_identity.h \
  tests/sm64_modern_fire_piranha_plant_route_contract.c \
  script/test_fire_piranha_plant_route_static.sh
printf '%s\n' \
  'SM64 Modern Fire Piranha Plant static route contract passed' \
  'semantic_identity=1 pointer_free=1 source_tuple_fences=1' \
  'runtime_receipt=absent castle_to_thi_reachability=unproven' \
  'admission=0 canonical_ledger_mutation=0 manifest_mutation=0'
