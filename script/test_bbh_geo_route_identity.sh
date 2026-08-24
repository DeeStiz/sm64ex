#!/usr/bin/env bash
set -euo pipefail

# Phase 85az probes the authored levels/bbh/geo.c -> area-1 geo.inc.c path
# through the native lifecycle. It retains only fixed-width scene values after
# production scene-graph construction. A schema-4 C/Swift pair is deferred
# unless the runtime root proves the selected source-resource identity.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-bbh-geo-route.XXXXXX")"
trap 'rm -rf "$RUN_ROOT"' EXIT

DEBUG_BUILD="$PROJECT_ROOT/build/sm64-modern-bbh-geo-route/native-debug"
ASAN_BUILD="$PROJECT_ROOT/build/sm64-modern-bbh-geo-route/native-asan"
RELEASE_BUILD="$PROJECT_ROOT/build/sm64-modern-bbh-geo-route/native-release"

build_probe() {
    local variant="$1"
    local debug_flag="$2"
    local sanitizer="$3"
    local native_root="$4"
    local output="$RUN_ROOT/bbh-geo-route-$variant"
    local link_flag=""
    if [[ "$variant" == "asan" ]]; then
        link_flag="-fsanitize=address"
    fi

    make -C "$PROJECT_ROOT" \
        SM64_MODERN_NATIVE=1 DEBUG="$debug_flag" $sanitizer \
        BUILD_DIR_BASE="$native_root" native-core >/dev/null
    test -f "$native_root/us_pc/libsm64core.a"
    xcrun --sdk macosx clang \
        -std=c11 -Wall -Wextra -Werror \
        -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
        -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
        -I"$native_root/us_pc" \
        "$PROJECT_ROOT/tests/sm64_modern_bbh_geo_route_identity.c" \
        "$native_root/us_pc/libsm64core.a" -o "$output" -lm -lpthread \
        ${link_flag}
    printf '%s\n' "$output"
}

DEBUG_OUTPUT="$(build_probe debug 1 "" "$DEBUG_BUILD")"
"$DEBUG_OUTPUT" debug "$RUN_ROOT/save-debug" >"$RUN_ROOT/debug.log" 2>&1
grep -Fq 'bbh_geo_route_init variant=debug status=0' "$RUN_ROOT/debug.log"
grep -Fq 'bbh_geo_route_step variant=debug index=0 status=0' "$RUN_ROOT/debug.log"
grep -Fq 'bbh_geo_route_step variant=debug index=1 status=0' "$RUN_ROOT/debug.log"
grep -Fq 'source_segmented=0x0e000f00' "$RUN_ROOT/debug.log"
grep -Fq 'source_resource=levels/bbh/areas/1/geo.inc.c' "$RUN_ROOT/debug.log"
grep -Fq 'bbh_geo_route_blocked variant=debug' "$RUN_ROOT/debug.log"

# A second owner-thread process must reproduce the same fixed-width scene
# values. Pointers and allocator addresses never enter this comparison.
"$DEBUG_OUTPUT" rerun "$RUN_ROOT/save-rerun" >"$RUN_ROOT/rerun.log" 2>&1
grep -Fq 'bbh_geo_route_blocked variant=rerun' "$RUN_ROOT/rerun.log"
sed -n 's/^bbh_geo_route_scene /bbh_geo_route_scene /p' "$RUN_ROOT/debug.log" \
    | sed -E 's/variant=[^ ]+/variant=normalized/' >"$RUN_ROOT/debug.scene"
sed -n 's/^bbh_geo_route_scene /bbh_geo_route_scene /p' "$RUN_ROOT/rerun.log" \
    | sed -E 's/variant=[^ ]+/variant=normalized/' >"$RUN_ROOT/rerun.scene"
cmp -s "$RUN_ROOT/debug.scene" "$RUN_ROOT/rerun.scene"
printf '%s\n' 'bbh_geo_route_persistent_rerun_passed=1 fixed_width_scene_match=1'

ASAN_OUTPUT="$(build_probe asan 1 "SANITIZE=address" "$ASAN_BUILD")"
ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
    "$ASAN_OUTPUT" asan "$RUN_ROOT/save-asan" >"$RUN_ROOT/asan.log" 2>&1
if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$RUN_ROOT/asan.log"; then
    echo 'AddressSanitizer emitted a finding in BBH geo identity probe' >&2
    exit 1
fi
grep -Fq 'bbh_geo_route_blocked variant=asan' "$RUN_ROOT/asan.log"
sed -n 's/^bbh_geo_route_scene /bbh_geo_route_scene /p' "$RUN_ROOT/asan.log" \
    | sed -E 's/variant=[^ ]+/variant=normalized/' >"$RUN_ROOT/asan.scene"
cmp -s "$RUN_ROOT/debug.scene" "$RUN_ROOT/asan.scene"
printf '%s\n' 'bbh_geo_route_sanitizer_passed=1 debug_asan_scene_match=1'

RELEASE_OUTPUT="$(build_probe release 0 "" "$RELEASE_BUILD")"
"$RELEASE_OUTPUT" release "$RUN_ROOT/save-release" >"$RUN_ROOT/release.log" 2>&1
grep -Fq 'bbh_geo_route_blocked variant=release' "$RUN_ROOT/release.log"
sed -n 's/^bbh_geo_route_scene /bbh_geo_route_scene /p' "$RUN_ROOT/release.log" \
    | sed -E 's/variant=[^ ]+/variant=normalized/' >"$RUN_ROOT/release.scene"
cmp -s "$RUN_ROOT/debug.scene" "$RUN_ROOT/release.scene"
printf '%s\n' 'bbh_geo_route_optimized_passed=1 debug_release_scene_match=1'

grep -Fq 'SM64_MODERN_AUTOMATED_BBH_GEO' "$PROJECT_ROOT/src/game/game_init.c"
git -c core.fsmonitor=false diff --check
printf '%s\n' \
    'SM64 Modern authored BBH geo identity probe passed lifecycle=real' \
    'route_shard=0xc7531948c443f4fa source=levels/bbh/geo.c' \
    'included_resource=levels/bbh/areas/1/geo.inc.c segmented_address=0x0e000f00' \
    'debug_asan_release_fixed_width_scene_match=1 persistent_rerun=1' \
    'schema4_c_swift_pair=deferred admission=0 ledger_mutation=0 fixture_only=0' \
    'blocker=runtime_root_area_index_does_not_identify_authored_area_1'
