#!/usr/bin/env bash
set -euo pipefail

# Phase 85ac pairs the native owner-thread PCM receipt with the independent
# Swift value decoder. It never instruments AVAudio's realtime render block,
# retains no raw PCM samples, and does not mutate route manifests or ledgers.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-audio-pcm-receipt-route-pair"
DEBUG_BUILD="$BUILD_ROOT/native-debug"
ASAN_BUILD="$BUILD_ROOT/native-asan"
RELEASE_BUILD="$BUILD_ROOT/native-release"
TOOL_ROOT="$BUILD_ROOT/tool"
C_OUTPUT="$TOOL_ROOT/sm64-modern-audio-pcm-receipt-route-contract"
ASAN_OUTPUT="$TOOL_ROOT/sm64-modern-audio-pcm-receipt-route-contract-asan"
RELEASE_OUTPUT="$TOOL_ROOT/sm64-modern-audio-pcm-receipt-route-contract-release"
SWIFT_OUTPUT="$TOOL_ROOT/sm64-modern-audio-pcm-receipt-route-swift"
DEBUG_TRACE="$BUILD_ROOT/audio-pcm-debug.trace"
DEBUG_PCM_TRACE="$BUILD_ROOT/audio-pcm-debug-only.trace"
DEBUG_RECEIPTS="$BUILD_ROOT/audio-pcm-debug.receipts"
ASAN_TRACE="$BUILD_ROOT/audio-pcm-asan.trace"
ASAN_PCM_TRACE="$BUILD_ROOT/audio-pcm-asan-only.trace"
ASAN_RECEIPTS="$BUILD_ROOT/audio-pcm-asan.receipts"
RELEASE_TRACE="$BUILD_ROOT/audio-pcm-release.trace"
RELEASE_PCM_TRACE="$BUILD_ROOT/audio-pcm-release-only.trace"
RELEASE_RECEIPTS="$BUILD_ROOT/audio-pcm-release.receipts"
SWIFT_TRACE="$BUILD_ROOT/audio-pcm-swift.trace"
TAMPERED_TRACE="$BUILD_ROOT/audio-pcm-tampered.trace"
TAMPERED_RECEIPTS="$BUILD_ROOT/audio-pcm-tampered.receipts"
SAVE_ROOT="$BUILD_ROOT/save-debug"
ASAN_SAVE_ROOT="$BUILD_ROOT/save-asan"
RELEASE_SAVE_ROOT="$BUILD_ROOT/save-release"
DEBUG_LOG="$BUILD_ROOT/debug.log"
ASAN_LOG="$BUILD_ROOT/asan.log"
RELEASE_LOG="$BUILD_ROOT/release.log"
SWIFT_LOG="$BUILD_ROOT/swift.log"

mkdir -p "$BUILD_ROOT" "$TOOL_ROOT" "$SAVE_ROOT" "$ASAN_SAVE_ROOT" \
  "$RELEASE_SAVE_ROOT" "$TOOL_ROOT/module-cache"

clang_contract() {
  local output="$1"
  local native_root="$2"
  shift 2
  xcrun --sdk macosx clang \
    -std=c11 -Wall -Wextra -Werror \
    -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
    -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
    -I"$native_root/us_pc" \
    "$PROJECT_ROOT/tests/sm64_modern_audio_pcm_route_audit.c" \
    "$native_root/us_pc/libsm64core.a" \
    -o "$output" -lm -lpthread "$@"
}

run_variant() {
  local variant="$1"
  local debug_flag="$2"
  local sanitizer_flag="$3"
  local native_root="$4"
  local output="$5"
  local trace="$6"
  local pcm_trace="$7"
  local receipts="$8"
  local save_root="$9"
  local log="${10}"

  make -C "$PROJECT_ROOT" \
    SM64_MODERN_NATIVE=1 DEBUG="$debug_flag" \
    ${sanitizer_flag:+SANITIZE=address} \
    BUILD_DIR_BASE="$native_root" native-core >/dev/null
  test -f "$native_root/us_pc/libsm64core.a"
  clang_contract "$output" "$native_root" ${sanitizer_flag:+-fsanitize=address}
  if [[ -n "$sanitizer_flag" ]]; then
    ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
      "$output" "$trace" "$save_root" "$receipts" "$pcm_trace" >"$log" 2>&1
    if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$log"; then
      echo "AddressSanitizer emitted a finding in $variant PCM receipt route" >&2
      exit 1
    fi
  else
    "$output" "$trace" "$save_root" "$receipts" "$pcm_trace" >"$log" 2>&1
  fi
  grep -Fq \
    'audio_pcm_route_debug oracle_end=0 result_status=0 actual=1790 schema4=1790 audio_pcm=2 effect_pcm=2 audio_play_callbacks=2 audio_play_frames=1088 failures=0 owner_errors=0' \
    "$log"
  grep -Fq \
    'audio_pcm_route_audit_recorded shard=0x4aa75cc09d180fce schema4_records=1790 audio_pcm_records=2 effect_pcm_records=2 audio_play_callbacks=2 audio_play_frames=1088 pcm_receipts=2 pcm_trace_records=2 swift_pcm_seam=present' \
    "$log"
}

run_variant debug 1 "" "$DEBUG_BUILD" "$C_OUTPUT" "$DEBUG_TRACE" \
  "$DEBUG_PCM_TRACE" "$DEBUG_RECEIPTS" "$SAVE_ROOT" "$DEBUG_LOG"

xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -import-objc-header "$PROJECT_ROOT/SM64Modern/SM64Modern-Bridging-Header.h" \
  -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/AudioPCMReceiptMigration.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_audio_pcm_receipt_smoke.swift" \
  -o "$SWIFT_OUTPUT"

{
  "$SWIFT_OUTPUT" write "$DEBUG_PCM_TRACE" "$DEBUG_RECEIPTS" "$SWIFT_TRACE"
  cmp -s "$DEBUG_PCM_TRACE" "$SWIFT_TRACE"
  "$SWIFT_OUTPUT" tamper "$DEBUG_PCM_TRACE" "$DEBUG_RECEIPTS" \
    "$TAMPERED_TRACE" "$TAMPERED_RECEIPTS"
} | tee "$SWIFT_LOG"
grep -Fq 'audio_pcm_canonical_hash_tamper_rejected=1' "$SWIFT_LOG"
grep -Fq 'audio_pcm_receipt_pair_tamper_rejected=1' "$SWIFT_LOG"
printf '%s\n' 'audio_pcm_receipt_route_pair_swift_passed=1 debug_pair=1 tamper_rejected=1'

run_variant asan 1 address "$ASAN_BUILD" "$ASAN_OUTPUT" "$ASAN_TRACE" \
  "$ASAN_PCM_TRACE" "$ASAN_RECEIPTS" "$ASAN_SAVE_ROOT" "$ASAN_LOG"
cmp -s "$DEBUG_PCM_TRACE" "$ASAN_PCM_TRACE"
cmp -s "$DEBUG_RECEIPTS" "$ASAN_RECEIPTS"
printf '%s\n' 'audio_pcm_receipt_route_sanitizer_passed=1 debug_asan_pair_match=1'

run_variant release 0 "" "$RELEASE_BUILD" "$RELEASE_OUTPUT" "$RELEASE_TRACE" \
  "$RELEASE_PCM_TRACE" "$RELEASE_RECEIPTS" "$RELEASE_SAVE_ROOT" "$RELEASE_LOG"
cmp -s "$DEBUG_PCM_TRACE" "$RELEASE_PCM_TRACE"
cmp -s "$DEBUG_RECEIPTS" "$RELEASE_RECEIPTS"
printf '%s\n' 'audio_pcm_receipt_route_optimized_passed=1 debug_release_pair_match=1'

git -c core.fsmonitor=false diff --check
printf '%s\n' \
  'SM64 Modern audio PCM receipt C↔Swift route pair passed exact_pair=1 tamper_rejected=1' \
  'native_audio_authority=c synthesis_device=1 owner_thread_receipt=1' \
  'swift_audio_consumer=value_only raw_pcm_crossing=0 realtime_callback_instrumentation=0' \
  'admission=0 ledger_mutation=0 fixture_only=0'
