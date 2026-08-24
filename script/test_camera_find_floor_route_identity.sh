#!/usr/bin/env bash
set -euo pipefail

# Phase 85ar probes only the source-authored non-oracle collision identity
# at src/game/camera.c:788.  A real lifecycle is required to reach the seam;
# this script does not call camera.c or find_floor directly and does not create
# a Swift pair when the authored camera mode is not entered.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-camera-find-floor-route-identity"
mkdir -p "$BUILD_ROOT"

build_and_probe() {
  local variant="$1"
  local debug_flag="$2"
  local sanitize_flag="$3"
  local native_root="$BUILD_ROOT/native-$variant"
  local output="$BUILD_ROOT/camera-find-floor-route-identity-$variant"
  local save_root="$BUILD_ROOT/save-$variant"
  local log="$BUILD_ROOT/$variant.log"

  make -C "$PROJECT_ROOT" \
    SM64_MODERN_NATIVE=1 DEBUG="$debug_flag" $sanitize_flag \
    BUILD_DIR_BASE="$native_root" native-core >/dev/null
  test -f "$native_root/us_pc/libsm64core.a"

  local extra_flags=( -O0 )
  if [[ "$variant" == "release" ]]; then
    extra_flags=( -O2 )
  fi
  if [[ "$variant" == "asan" ]]; then
    extra_flags+=( -fsanitize=address )
  fi
  xcrun --sdk macosx clang \
    -std=c11 -Wall -Wextra -Werror \
    -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
    -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
    -I"$native_root/us_pc" \
    "${extra_flags[@]}" \
    "$PROJECT_ROOT/tests/sm64_modern_camera_find_floor_route_identity.c" \
    "$native_root/us_pc/libsm64core.a" \
    -o "$output" -lm -lpthread

  mkdir -p "$save_root"
  # The native config loader persists its generated file below this isolated
  # probe root. Remove only that generated artifact so reruns use the exact
  # lifecycle recipe instead of stale local settings.
  rm -f "$save_root/sm64-modern-camera-find-floor-route.cfg"
  if [[ "$variant" == "asan" ]]; then
    ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
      "$output" "$save_root" "$variant" >"$log" 2>&1
    if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$log"; then
      echo "AddressSanitizer emitted a finding in $variant camera identity probe" >&2
      exit 1
    fi
  else
    "$output" "$save_root" "$variant" >"$log" 2>&1
  fi
  grep -Fq "camera_find_floor_identity_init variant=$variant status=0" "$log"
  grep -Fq "camera_find_floor_identity_step variant=$variant index=0 status=0" "$log"
  grep -Fq "camera_find_floor_identity_step variant=$variant index=1 status=0" "$log"
  grep -Fq "camera_find_floor_identity_blocked variant=$variant reached=0 identity_records=0" "$log"
  cat "$log"
}

build_and_probe debug 1 ""
build_and_probe asan 1 "SANITIZE=address"
build_and_probe release 0 ""

git -c core.fsmonitor=false diff --check
printf '%s\n' \
  'SM64 Modern camera find-floor source identity probe passed lifecycle=real' \
  'route_shard=0x1e3500f9eb2b95d4 source=src/game/camera.c identity=set_camera_height:find_floor' \
  'admission=0 swift_pair=deferred blocker=authored_camera_mode_radial_path_unreached' \
  'debug_asan_release=blocked_consistently tamper_partial_single_artifact_fences=not_applicable'
