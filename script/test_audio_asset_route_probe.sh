#!/usr/bin/env bash
set -euo pipefail

# Phase 85ar attempts a source-bound schema-4 audio_asset route.  The native
# C lifecycle is the only producer; this script never calls play_sequence(),
# injects star/save state, fabricates PCM, or mutates the route manifest.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-audio-asset-route-probe"
DEBUG_ROOT="$BUILD_ROOT/native-debug"
ASAN_ROOT="$BUILD_ROOT/native-asan"
RELEASE_ROOT="$BUILD_ROOT/native-release"
TOOL_ROOT="$BUILD_ROOT/tool"
PROBE="$TOOL_ROOT/sm64-modern-audio-asset-route-probe"
PROBE_ASAN="$TOOL_ROOT/sm64-modern-audio-asset-route-probe-asan"
PROBE_RELEASE="$TOOL_ROOT/sm64-modern-audio-asset-route-probe-release"
SWIFT="$TOOL_ROOT/sm64-modern-audio-asset-route-swift"
DEBUG_TRACE="$BUILD_ROOT/audio-asset-debug.trace"
ASAN_TRACE="$BUILD_ROOT/audio-asset-asan.trace"
RELEASE_TRACE="$BUILD_ROOT/audio-asset-release.trace"
RERUN_TRACE="$BUILD_ROOT/audio-asset-rerun.trace"
TAMPER_TRACE="$BUILD_ROOT/audio-asset-tampered.trace"
PARTIAL_TRACE="$BUILD_ROOT/audio-asset-partial.trace"
DEBUG_SAVE="$BUILD_ROOT/save-debug"
ASAN_SAVE="$BUILD_ROOT/save-asan"
RELEASE_SAVE="$BUILD_ROOT/save-release"
RERUN_SAVE="$BUILD_ROOT/save-rerun"
DEBUG_LOG="$BUILD_ROOT/debug.log"
ASAN_LOG="$BUILD_ROOT/asan.log"
RELEASE_LOG="$BUILD_ROOT/release.log"
RERUN_LOG="$BUILD_ROOT/rerun.log"
SWIFT_LOG="$BUILD_ROOT/swift.log"
SOURCE_PATH="sound/sequences/us/12_event_high_score.m64"
SOURCE_SHA256="2e0170f20353d6ba772af9df92f2d53e8b8d807e2b5bca24ac87bc022f08fade"

mkdir -p "$BUILD_ROOT" "$TOOL_ROOT" "$DEBUG_SAVE" "$ASAN_SAVE" \
  "$RELEASE_SAVE" "$RERUN_SAVE" "$TOOL_ROOT/module-cache"

test "$(shasum -a 256 "$PROJECT_ROOT/$SOURCE_PATH" | awk '{print $1}')" \
  = "$SOURCE_SHA256"

clang_probe() {
  local output="$1"
  local native_root="$2"
  shift 2
  xcrun --sdk macosx clang \
    -std=c11 -Wall -Wextra -Werror \
    -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
    -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
    -I"$native_root/us_pc" \
    "$PROJECT_ROOT/tests/sm64_modern_audio_asset_route_probe.c" \
    "$native_root/us_pc/libsm64core.a" \
    -o "$output" -lm -lpthread "$@"
}

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=1 BUILD_DIR_BASE="$DEBUG_ROOT" native-core >/dev/null
test -f "$DEBUG_ROOT/us_pc/libsm64core.a"
clang_probe "$PROBE" "$DEBUG_ROOT"
"$PROBE" "$DEBUG_TRACE" "$DEBUG_SAVE" >"$DEBUG_LOG" 2>&1

grep -Fq \
  'source=sound/sequences/us/12_event_high_score.m64 source_sha256=2e0170f20353d6ba772af9df92f2d53e8b8d807e2b5bca24ac87bc022f08fade' \
  "$DEBUG_LOG"
grep -Eq \
  'audio_asset_route_probe shard=0x03345fc560c65b75 .* input_seed=0x014f93c6ae7e2e59 save_seed=0x2a3582ec48614066 steps=720 records=[1-9][0-9]* audio_sequence=[1-9][0-9]* audio_pcm=[1-9][0-9]* pcm_receipts=[1-9][0-9]* sequence12=0 asset_ticks=0,0 audio_play_callbacks=[1-9][0-9]* audio_play_frames=[1-9][0-9]* oracle_end=0 result_status=0 errors=0' \
  "$DEBUG_LOG"

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
  BUILD_DIR_BASE="$ASAN_ROOT" native-core >/dev/null
test -f "$ASAN_ROOT/us_pc/libsm64core.a"
clang_probe "$PROBE_ASAN" "$ASAN_ROOT" -fsanitize=address
ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
  "$PROBE_ASAN" "$ASAN_TRACE" "$ASAN_SAVE" >"$ASAN_LOG" 2>&1
if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$ASAN_LOG"; then
  echo 'AddressSanitizer emitted a finding in the audio-asset route probe' >&2
  exit 1
fi

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=0 BUILD_DIR_BASE="$RELEASE_ROOT" native-core >/dev/null
test -f "$RELEASE_ROOT/us_pc/libsm64core.a"
clang_probe "$PROBE_RELEASE" "$RELEASE_ROOT"
"$PROBE_RELEASE" "$RELEASE_TRACE" "$RELEASE_SAVE" >"$RELEASE_LOG" 2>&1
grep -Fq 'sequence12=0' "$RELEASE_LOG"

cmp -s "$DEBUG_TRACE" "$ASAN_TRACE"
cmp -s "$DEBUG_TRACE" "$RELEASE_TRACE"

xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -import-objc-header "$PROJECT_ROOT/SM64Modern/SM64Modern-Bridging-Header.h" \
  -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_audio_asset_route_swift_smoke.swift" \
  -o "$SWIFT"

{
  "$SWIFT" audit "$DEBUG_TRACE"
  "$SWIFT" tamper "$DEBUG_TRACE" "$TAMPER_TRACE"
  "$SWIFT" partial "$DEBUG_TRACE" "$PARTIAL_TRACE"
  if "$SWIFT" single "$DEBUG_TRACE" "$DEBUG_TRACE"; then
    echo 'single-artifact audio-asset audit unexpectedly accepted' >&2
    exit 1
  else
    echo 'audio_asset_route_single_artifact_fence=1'
  fi
} | tee "$SWIFT_LOG"
grep -Fq 'source_identity_header=1 pair_deferred=1' "$SWIFT_LOG"
grep -Fq 'audio_asset_route_swift_tamper_rejected=1' "$SWIFT_LOG"
grep -Fq 'audio_asset_route_swift_partial_rejected=1' "$SWIFT_LOG"
grep -Fq 'audio_asset_route_single_artifact_fence=1' "$SWIFT_LOG"

"$PROBE" "$RERUN_TRACE" "$RERUN_SAVE" >"$RERUN_LOG" 2>&1
cmp -s "$DEBUG_TRACE" "$RERUN_TRACE"
printf '%s\n' \
  'audio_asset_route_rerun_fence=1 debug_rerun_trace_match=1' \
  'SM64 Modern audio-asset route probe passed blocked=1 source_identity=0 pair_deferred=1' \
  'native_c_lifecycle=1 schema4=1 pcm_receipts=1 debug_asan_release_byte_match=1' \
  'tamper_rejected=1 partial_rejected=1 single_artifact_rejected=1 fixture_only=0' \
  'manifest_mutation=0 ledger_mutation=0'

git -c core.fsmonitor=false diff --check
