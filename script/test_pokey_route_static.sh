#!/usr/bin/env bash
set -euo pipefail

# Static-only Phase 85f107 contract.  The ordinary Castle -> SSL route is the
# only allowed runtime path; this script never loads SSL, calls Pokey helpers,
# injects body parts, selects coordinates, creates traces, or mutates ledgers.
bash -n "$0"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="${SM64_POKEY_STATIC_BUILD_ROOT:-$PROJECT_ROOT/build/sm64-modern-pokey-static}"
mkdir -p "$BUILD_ROOT"

grep -Fq 'macro_pokey' "$PROJECT_ROOT/levels/ssl/areas/1/macro.inc.c"
grep -Fq 'bhvPokey' "$PROJECT_ROOT/include/macro_presets.h"
grep -Fq 'bhv_pokey_update' "$PROJECT_ROOT/data/behavior_data.c"
grep -Fq 'bhv_pokey_body_part_update' "$PROJECT_ROOT/data/behavior_data.c"
grep -Fq 'spawn_object_relative(i, 0, -i * 120 + 480' \
  "$PROJECT_ROOT/src/game/behaviors/pokey.inc.c"

if rg -n 'uintptr_t|OpaquePointer|Unsafe|spawn_object|spawn_object_relative|load_level|level_register|cur_obj_|gMarioObject' \
  "$PROJECT_ROOT/src/pc/sm64_modern_pokey_route_identity.c" \
  "$PROJECT_ROOT/tests/sm64_modern_pokey_route_contract.c"; then
  echo 'pokey_static_pointer_or_helper_fence_failed=1' >&2
  exit 1
fi

clang_cmd=(xcrun --sdk macosx clang -std=c11 -Wall -Wextra -Werror
  -DNON_MATCHING=1 -DAVOID_UB=1 -DVERSION_US -D_LANGUAGE_C
  -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src")
"${clang_cmd[@]}" -fsyntax-only \
  "$PROJECT_ROOT/src/pc/sm64_modern_pokey_route_identity.c"
"${clang_cmd[@]}" \
  "$PROJECT_ROOT/tests/sm64_modern_pokey_route_contract.c" \
  "$PROJECT_ROOT/src/pc/sm64_modern_pokey_route_identity.c" \
  -o "$BUILD_ROOT/pokey-route-contract"
"$BUILD_ROOT/pokey-route-contract" | tee "$BUILD_ROOT/contract.log"
grep -Fq 'SM64 Modern Pokey route C contract passed' "$BUILD_ROOT/contract.log"
git -c core.fsmonitor=false diff --check -- \
  src/pc/sm64_modern_pokey_route_identity.c \
  src/pc/sm64_modern_pokey_route_identity.h \
  tests/sm64_modern_pokey_route_contract.c \
  script/test_pokey_route_static.sh
printf '%s\n' \
  'SM64 Modern Pokey static route contract passed' \
  'semantic_parent_child_identity=1 source_5_child_offsets=1 pointer_free=1' \
  'runtime_receipt=absent castle_to_ssl_reachability=unproven' \
  'admission=0 canonical_ledger_mutation=0 manifest_mutation=0'
