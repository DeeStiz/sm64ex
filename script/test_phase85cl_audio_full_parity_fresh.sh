#!/usr/bin/env bash
set -euo pipefail

# Phase 85cl owns a fresh whole-trace parity rerun for the authored Castle
# area-2 high-score recipe after semantic bhvSignOnWall/bhvOneCoin mapping.
# It writes only isolated build/output artifacts and never mutates a manifest,
# route ledger, cumulative report, shared admission tool, or canonical docs.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="${SM64_PHASE85CL_BUILD_ROOT:-$PROJECT_ROOT/build/sm64-modern-phase85cl-audio-full-parity-fresh}"
DEBUG_ROOT="$BUILD_ROOT/native-debug"
ASAN_ROOT="$BUILD_ROOT/native-asan"
RELEASE_ROOT="$BUILD_ROOT/native-release"
TOOL_ROOT="$BUILD_ROOT/tool"
mkdir -p "$BUILD_ROOT" "$TOOL_ROOT/module-cache"

C_OUTPUT="$TOOL_ROOT/sm64-modern-audio-full-probe"
ASAN_OUTPUT="$TOOL_ROOT/sm64-modern-audio-full-probe-asan"
RELEASE_OUTPUT="$TOOL_ROOT/sm64-modern-audio-full-probe-release"
SWIFT_OUTPUT="$TOOL_ROOT/sm64-modern-audio-full-parity-swift"
C_TRACE="$BUILD_ROOT/audio-full-c.trace"
ASAN_TRACE="$BUILD_ROOT/audio-full-c-asan.trace"
RELEASE_TRACE="$BUILD_ROOT/audio-full-c-release.trace"
RERUN_TRACE="$BUILD_ROOT/audio-full-c-rerun.trace"
SWIFT_TRACE="$BUILD_ROOT/audio-full-swift.trace"
TAMPER_TRACE="$BUILD_ROOT/audio-full-tampered.trace"
PARTIAL_TRACE="$BUILD_ROOT/audio-full-partial.trace"
FIXTURE_MARKER="$BUILD_ROOT/audio-full.fixture_only"
C_PCM="$BUILD_ROOT/audio-full-c.pcm.trace"
ASAN_PCM="$BUILD_ROOT/audio-full-c-asan.pcm.trace"
RELEASE_PCM="$BUILD_ROOT/audio-full-c-release.pcm.trace"
C_RECEIPTS="$BUILD_ROOT/audio-full-c.receipts"
ASAN_RECEIPTS="$BUILD_ROOT/audio-full-c-asan.receipts"
RELEASE_RECEIPTS="$BUILD_ROOT/audio-full-c-release.receipts"
DEBUG_LOG="$BUILD_ROOT/debug.log"
ASAN_LOG="$BUILD_ROOT/asan.log"
RELEASE_LOG="$BUILD_ROOT/release.log"
RERUN_LOG="$BUILD_ROOT/rerun.log"
SWIFT_LOG="$BUILD_ROOT/swift.log"

DEBUG_SAVE="$(mktemp -d "$BUILD_ROOT/save-debug.XXXXXX")"
ASAN_SAVE="$(mktemp -d "$BUILD_ROOT/save-asan.XXXXXX")"
RELEASE_SAVE="$(mktemp -d "$BUILD_ROOT/save-release.XXXXXX")"
RERUN_SAVE="$(mktemp -d "$BUILD_ROOT/save-rerun.XXXXXX")"

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
    "$native_root/us_pc/libsm64core.a" -o "$output" -lm -lpthread "$@"
}

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 \
  BUILD_DIR_BASE="$DEBUG_ROOT" native-core >/dev/null
test -f "$DEBUG_ROOT/us_pc/libsm64core.a"
clang_probe "$C_OUTPUT" "$DEBUG_ROOT"
SM64_MODERN_AUTOMATED_CASTLE_AREA2=1 \
  "$C_OUTPUT" "$C_TRACE" "$DEBUG_SAVE" "$C_PCM" "$C_RECEIPTS" \
  >"$DEBUG_LOG" 2>&1
grep -Eq 'sequence12=1 .*asset_ticks=63,63 .*errors=0' "$DEBUG_LOG"
grep -Fq 'records=476365' "$DEBUG_LOG"

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
  BUILD_DIR_BASE="$ASAN_ROOT" native-core >/dev/null
test -f "$ASAN_ROOT/us_pc/libsm64core.a"
clang_probe "$ASAN_OUTPUT" "$ASAN_ROOT" -fsanitize=address
set +e
ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
  SM64_MODERN_AUTOMATED_CASTLE_AREA2=1 \
  "$ASAN_OUTPUT" "$ASAN_TRACE" "$ASAN_SAVE" "$ASAN_PCM" "$ASAN_RECEIPTS" \
  >"$ASAN_LOG" 2>&1
ASAN_STATUS=$?
set -e
if (( ASAN_STATUS != 0 )); then
  cat "$ASAN_LOG" >&2
  exit "$ASAN_STATUS"
fi
if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$ASAN_LOG"; then
  echo 'phase85cl AddressSanitizer finding' >&2
  exit 1
fi

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=0 \
  BUILD_DIR_BASE="$RELEASE_ROOT" native-core >/dev/null
test -f "$RELEASE_ROOT/us_pc/libsm64core.a"
clang_probe "$RELEASE_OUTPUT" "$RELEASE_ROOT"
SM64_MODERN_AUTOMATED_CASTLE_AREA2=1 \
  "$RELEASE_OUTPUT" "$RELEASE_TRACE" "$RELEASE_SAVE" "$RELEASE_PCM" "$RELEASE_RECEIPTS" \
  >"$RELEASE_LOG" 2>&1
grep -Eq 'sequence12=1 .*asset_ticks=63,63 .*errors=0' "$RELEASE_LOG"
grep -Fq 'records=476365' "$RELEASE_LOG"

SM64_MODERN_AUTOMATED_CASTLE_AREA2=1 \
  "$C_OUTPUT" "$RERUN_TRACE" "$RERUN_SAVE" "$BUILD_ROOT/audio-full-rerun.pcm.trace" \
  "$BUILD_ROOT/audio-full-rerun.receipts" >"$RERUN_LOG" 2>&1

xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_phase85cl_audio_full_parity_fresh.swift" \
  -o "$SWIFT_OUTPUT"

{
  "$SWIFT_OUTPUT" write "$C_TRACE" "$SWIFT_TRACE"
  "$SWIFT_OUTPUT" audit "$C_TRACE" "$SWIFT_TRACE" "$ASAN_TRACE" "$RELEASE_TRACE" "$RERUN_TRACE"
  "$SWIFT_OUTPUT" tamper "$C_TRACE" "$TAMPER_TRACE"
  "$SWIFT_OUTPUT" partial "$C_TRACE" "$PARTIAL_TRACE"
  "$SWIFT_OUTPUT" fixture "$C_TRACE" "$FIXTURE_MARKER"
  if "$SWIFT_OUTPUT" single "$C_TRACE" "$C_TRACE"; then
    echo 'phase85cl single-artifact fence unexpectedly accepted' >&2
    exit 1
  fi
} | tee "$SWIFT_LOG"

cmp -s "$C_TRACE" "$SWIFT_TRACE"
cmp -s "$C_TRACE" "$ASAN_TRACE"
cmp -s "$C_TRACE" "$RELEASE_TRACE"
cmp -s "$C_TRACE" "$RERUN_TRACE"
test ! -e "$FIXTURE_MARKER"
test -s "$C_PCM" -a -s "$ASAN_PCM" -a -s "$RELEASE_PCM"
test -s "$C_RECEIPTS" -a -s "$ASAN_RECEIPTS" -a -s "$RELEASE_RECEIPTS"
cmp -s "$C_PCM" "$ASAN_PCM"
cmp -s "$C_PCM" "$RELEASE_PCM"
cmp -s "$C_RECEIPTS" "$ASAN_RECEIPTS"
cmp -s "$C_RECEIPTS" "$RELEASE_RECEIPTS"

git -c core.fsmonitor=false diff --check
printf '%s\n' \
  'SM64 Modern Phase 85cl audio full-trace parity passed exact_pair=1' \
  'native_c_lifecycle=1 castle_area2=1 sequence12_tick=63 records=476365' \
  'bhvSignOnWall_semantic_identity=0x58c5c9f354614b2d bhvOneCoin_semantic_identity=0x0c4e3fcc926a6842' \
  'c_swift_asan_release_rerun_byte_match=1 pcm_and_receipts_cross_build_match=1' \
  'tamper_rejected=1 partial_rejected=1 single_artifact_rejected=1 fixture_only_rejected=1' \
  'canonical_promotion=0 manifest_mutation=0 ledger_mutation=0 shared_docs_mutation=0'
