#!/usr/bin/env bash
set -euo pipefail

# Phase 85f107 is a bounded static seam.  The authored Castle Inside painting
# nodes remain the only allowed Castle -> SSL route; this script does not load
# SSL, call a Pokey helper, inject a child, synthesize a trace, or write any
# report, ledger, backup, or manifest.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="${SM64_POKEY_STATIC_BUILD_ROOT:-$PROJECT_ROOT/build/sm64-modern-pokey-static}"
mkdir -p "$BUILD_ROOT/module-cache"

for node in 0x0F 0x10 0x11; do
  grep -Fq "PAINTING_WARP_NODE(/*id*/ $node, /*destLevel*/ LEVEL_SSL, /*destArea*/ 0x01" \
    "$PROJECT_ROOT/levels/castle_inside/script.c"
done
grep -Fq 'macro_pokey' "$PROJECT_ROOT/levels/ssl/areas/1/macro.inc.c"
for tuple in \
  '4602,    40,  4622' \
  '5057,   143,   256' \
  '-6858,     8, -3711' \
  '-5372,    64,  3083'; do
  grep -Fq -- "$tuple" "$PROJECT_ROOT/levels/ssl/areas/1/macro.inc.c"
done
grep -Fq 'bhvPokey' "$PROJECT_ROOT/include/macro_presets.h"
grep -Fq '{bhvPokey, MODEL_NONE, 0}' "$PROJECT_ROOT/include/macro_presets.h"
grep -Fq 'const BehaviorScript bhvPokey[]' "$PROJECT_ROOT/data/behavior_data.c"
grep -Fq 'const BehaviorScript bhvPokeyBodyPart[]' "$PROJECT_ROOT/data/behavior_data.c"
grep -Fq 'MODEL_POKEY_HEAD' "$PROJECT_ROOT/src/game/behaviors/pokey.inc.c"
grep -Fq 'MODEL_POKEY_BODY_PART' "$PROJECT_ROOT/src/game/behaviors/pokey.inc.c"
grep -Fq '480' "$PROJECT_ROOT/src/game/behaviors/pokey.inc.c"
grep -Fq 'i * 120' "$PROJECT_ROOT/src/game/behaviors/pokey.inc.c"
grep -Fq 'o->oPokeyAliveBodyPartFlags' "$PROJECT_ROOT/src/game/behaviors/pokey.inc.c"
grep -Fq 'o->oPokeyNumAliveBodyParts' "$PROJECT_ROOT/src/game/behaviors/pokey.inc.c"
grep -Fq 'obj_handle_attacks(&sPokeyBodyPartHitbox' "$PROJECT_ROOT/src/game/behaviors/pokey.inc.c"
grep -Fq 'o->oTimer > 100' "$PROJECT_ROOT/src/game/behaviors/pokey.inc.c"
grep -Fq 'o->oDistanceToMario > 2500.0f' "$PROJECT_ROOT/src/game/behaviors/pokey.inc.c"
grep -Fq 'obj_mark_for_deletion(o)' "$PROJECT_ROOT/src/game/behaviors/pokey.inc.c"
grep -Fq 'cur_obj_become_intangible()' "$PROJECT_ROOT/src/game/behaviors/pokey.inc.c"
grep -Fq 'o->oAction = POKEY_ACT_UNLOAD_PARTS' "$PROJECT_ROOT/src/game/behaviors/pokey.inc.c"

OWNED_FILES=(
  "$PROJECT_ROOT/src/pc/sm64_modern_pokey_route_identity.h"
  "$PROJECT_ROOT/src/pc/sm64_modern_pokey_route_identity.c"
  "$PROJECT_ROOT/tests/sm64_modern_pokey_route_contract.c"
  "$PROJECT_ROOT/tests/sm64_modern_pokey_route_swift_smoke.swift"
)
if rg -n 'uintptr_t|OpaquePointer|UnsafePointer|UnsafeMutable|spawn_object|load_level|level_register|cur_obj_|gMarioObject|bhv_pokey_|segmented_to_virtual|oracle_trace|trace' \
  "${OWNED_FILES[@]}"; then
  echo 'pokey_static_pointer_or_helper_fence_failed=1' >&2
  exit 1
fi

CLANG_CMD=(xcrun --sdk macosx clang -std=c11 -Wall -Wextra -Werror
  -DNON_MATCHING=1 -DAVOID_UB=1 -DVERSION_US -D_LANGUAGE_C
  -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src")
"${CLANG_CMD[@]}" -fsyntax-only \
  "$PROJECT_ROOT/src/pc/sm64_modern_pokey_route_identity.c"
"${CLANG_CMD[@]}" \
  "$PROJECT_ROOT/tests/sm64_modern_pokey_route_contract.c" \
  "$PROJECT_ROOT/src/pc/sm64_modern_pokey_route_identity.c" \
  -o "$BUILD_ROOT/pokey-route-contract"
"$BUILD_ROOT/pokey-route-contract" | tee "$BUILD_ROOT/c-contract.log"
grep -Fq 'SM64 Modern Pokey route C contract passed' \
  "$BUILD_ROOT/c-contract.log"

xcrun --sdk macosx swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/tests/sm64_modern_pokey_route_swift_smoke.swift" \
  -o "$BUILD_ROOT/pokey-route-swift"
"$BUILD_ROOT/pokey-route-swift" | tee "$BUILD_ROOT/swift-contract.log"
grep -Fq 'SM64 Modern Pokey route Swift smoke passed' \
  "$BUILD_ROOT/swift-contract.log"

git -c core.fsmonitor=false diff --check -- \
  src/pc/sm64_modern_pokey_route_identity.c \
  src/pc/sm64_modern_pokey_route_identity.h \
  tests/sm64_modern_pokey_route_contract.c \
  tests/sm64_modern_pokey_route_swift_smoke.swift \
  script/test_pokey_route_static.sh
printf '%s\n' \
  'SM64 Modern Pokey static route pair passed' \
  'source_authored=1 macro_parent_tuples=4 child_tuples=5' \
  'semantic_parent_child_identity=1 generation_safe_parent_link=1 schema4_receipt=1' \
  'attack_replenish_unload_collision_effect_deletion=1 pointer_free=1' \
  'runtime_receipt=absent castle_to_ssl_reachability=unproven' \
  'reachability_exit=77_if_unreachable admission=0 canonical_ledger_mutation=0 manifest_mutation=0'
