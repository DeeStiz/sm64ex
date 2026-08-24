#!/usr/bin/env bash
set -euo pipefail

# Phase 85z remains a native owner-boundary audit. The C audit observes the
# fixed-width schema-4 PCM receipt emitted before platform_audio_play without
# instrumenting AVAudio's realtime render callback or retaining raw samples.
# The independent Swift pair is owned by test_audio_pcm_receipt_route_pair.sh.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-audio-pcm-route-audit"
AUDIT_SOURCE="$PROJECT_ROOT/tests/sm64_modern_audio_pcm_route_audit.c"

grep -Fq 'sm64_modern_parity_record_pcm(audio_buffer, audio_frame_count)' \
  "$PROJECT_ROOT/src/pc/pc_main.c"
grep -Fq 'sPlatform.audio_play(sPlatform.context, audio_buffer, audio_frame_count)' \
  "$PROJECT_ROOT/src/pc/pc_main.c"
grep -Fq 'SM64_MODERN_GAMEPLAY_RECORD_EFFECT' \
  "$PROJECT_ROOT/src/pc/sm64_modern_gameplay_parity.c"
grep -Fq 'SM64ModernAudioPCMReceiptV1' \
  "$PROJECT_ROOT/include/sm64_modern.h"

mkdir -p "$BUILD_ROOT"

compile_and_run() {
  local variant="$1"
  local debug_flag="$2"
  local sanitizer_flag="$3"
  local native_root="$BUILD_ROOT/native-$variant"
  local output="$BUILD_ROOT/audio-pcm-audit-$variant"
  local trace="$BUILD_ROOT/audio-pcm-$variant.trace"
  local save_root="$BUILD_ROOT/save-$variant"
  local log="$BUILD_ROOT/$variant.log"
  mkdir -p "$save_root"

  make -C "$PROJECT_ROOT" \
    SM64_MODERN_NATIVE=1 DEBUG="$debug_flag" \
    ${sanitizer_flag:+SANITIZE=address} \
    BUILD_DIR_BASE="$native_root" native-core >/dev/null
  test -f "$native_root/us_pc/libsm64core.a"

  xcrun --sdk macosx clang \
    -std=c11 -Wall -Wextra -Werror \
    -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
    ${sanitizer_flag:+-fsanitize=address} \
    -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
    -I"$native_root/us_pc" "$AUDIT_SOURCE" \
    "$native_root/us_pc/libsm64core.a" -o "$output" -lm -lpthread

  if [[ -n "$sanitizer_flag" ]]; then
    ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
      "$output" "$trace" "$save_root" >"$log" 2>&1
    if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$log"; then
      echo "AddressSanitizer emitted a finding in $variant audit" >&2
      exit 1
    fi
  else
    "$output" "$trace" "$save_root" >"$log" 2>&1
  fi

  grep -Fq \
    'audio_pcm_route_debug oracle_end=0 result_status=0 actual=1790 schema4=1790 audio_pcm=2 effect_pcm=2 audio_play_callbacks=2 audio_play_frames=1088 failures=0 owner_errors=0' \
    "$log"
  grep -Fq \
    'audio_pcm_route_audit_recorded shard=0x4aa75cc09d180fce schema4_records=1790 audio_pcm_records=2 effect_pcm_records=2 audio_play_callbacks=2 audio_play_frames=1088 pcm_receipts=0 pcm_trace_records=2 swift_pcm_seam=missing' \
    "$log"
}

compile_and_run debug 1 ""
compile_and_run asan 1 address
compile_and_run release 0 ""

git -c core.fsmonitor=false diff --check
printf '%s\n' \
  'SM64 Modern audio PCM route audit passed native_debug_asan_release=1' \
  'canonical_shard=0x4aa75cc09d180fce input_seed=0xc3e64e9c0ec5da8a save_seed=0x0ecb81238dddc733' \
  'owner_thread_pcm_handoffs=2 frames=1088 schema4_audio_pcm_records=2 legacy_effect_pcm_records=2' \
  'swift_pcm_seam=available admission=0 ledger_mutation=0 realtime_callback_instrumentation=0'
