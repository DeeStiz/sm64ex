#!/usr/bin/env bash
set -euo pipefail

# Phase 85u owns only the source-backed oracle_hook|audio_sequence pair.
# C owns the native audio graph and PCM/device path. Swift replays copied
# schema-4 receipts through the value-only AudioMigration model. This script
# never injects sequence bytes and never instruments a realtime audio callback.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-audio-sequence-route-pair"
DEBUG_BUILD="$BUILD_ROOT/native-debug"
ASAN_BUILD="$BUILD_ROOT/native-asan"
RELEASE_BUILD="$BUILD_ROOT/native-release"
TOOL_ROOT="$BUILD_ROOT/tool"
C_OUTPUT="$TOOL_ROOT/sm64-modern-audio-sequence-route-contract"
ASAN_OUTPUT="$TOOL_ROOT/sm64-modern-audio-sequence-route-contract-asan"
RELEASE_OUTPUT="$TOOL_ROOT/sm64-modern-audio-sequence-route-contract-release"
SWIFT_OUTPUT="$TOOL_ROOT/sm64-modern-audio-sequence-route-swift"
C_TRACE="$BUILD_ROOT/audio-sequence-c.trace"
ASAN_TRACE="$BUILD_ROOT/audio-sequence-c-asan.trace"
RELEASE_TRACE="$BUILD_ROOT/audio-sequence-c-release.trace"
SWIFT_TRACE="$BUILD_ROOT/audio-sequence-swift.trace"
TAMPERED_TRACE="$BUILD_ROOT/audio-sequence-swift.tampered.trace"
SAVE_ROOT="$BUILD_ROOT/save"
ASAN_SAVE_ROOT="$BUILD_ROOT/save-asan"
RELEASE_SAVE_ROOT="$BUILD_ROOT/save-release"
DEBUG_LOG="$BUILD_ROOT/debug.log"
ASAN_LOG="$BUILD_ROOT/asan.log"
RELEASE_LOG="$BUILD_ROOT/release.log"
SWIFT_LOG="$BUILD_ROOT/swift.log"

mkdir -p "$BUILD_ROOT" "$SAVE_ROOT" "$ASAN_SAVE_ROOT" "$RELEASE_SAVE_ROOT" \
  "$TOOL_ROOT/module-cache"

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=1 BUILD_DIR_BASE="$DEBUG_BUILD" native-core >/dev/null
test -f "$DEBUG_BUILD/us_pc/libsm64core.a"

clang_contract() {
  local output="$1"
  local archive_root="$2"
  shift 2
  xcrun --sdk macosx clang \
    -std=c11 -Wall -Wextra -Werror \
    -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
    -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
    -I"$archive_root/us_pc" \
    "$PROJECT_ROOT/tests/sm64_modern_audio_sequence_route_pair_contract.c" \
    "$archive_root/us_pc/libsm64core.a" \
    -o "$output" -lm -lpthread "$@"
}

clang_contract "$C_OUTPUT" "$DEBUG_BUILD"
"$C_OUTPUT" "$C_TRACE" "$SAVE_ROOT" >"$DEBUG_LOG" 2>&1
grep -Fq 'audio_sequence_route_init status=0 oracle=0 parity=0' "$DEBUG_LOG"
grep -Fq 'audio_sequence_route_step index=0 status=0 oracle=0 parity=0' "$DEBUG_LOG"
grep -Fq 'audio_sequence_route_step index=1 status=0 oracle=0 parity=0' "$DEBUG_LOG"
grep -Eq 'audio_sequence_route_debug oracle_end=0 result_status=0 actual=[1-9][0-9]* retained=4 observer=4 failures=0 ticks=1' "$DEBUG_LOG"
grep -Eq 'c_audio_sequence_route_recorded shard=0xbe184196f54f8216 .* records=4 ticks=2,2 event_counts=1,2,1,0 coverage=0x[0-9a-f]{16} observer_events=4 observer_fingerprint=0x[0-9a-f]{16} trace_fingerprint=0x[0-9a-f]{16}' "$DEBUG_LOG"
test "$(wc -c <"$C_TRACE" | tr -d '[:space:]')" -eq 584

xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -import-objc-header "$PROJECT_ROOT/SM64Modern/SM64Modern-Bridging-Header.h" \
  -I"$PROJECT_ROOT/include" \
  -I"$PROJECT_ROOT/src" \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/AudioMigration.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_audio_sequence_route_swift_smoke.swift" \
  -o "$SWIFT_OUTPUT"

{
  "$SWIFT_OUTPUT" write "$C_TRACE" "$SWIFT_TRACE"
  C_FINGERPRINT="$(sed -n 's/.*trace_fingerprint=\(0x[0-9a-fA-F]*\).*/\1/p' "$DEBUG_LOG" | tail -1)"
  test -n "$C_FINGERPRINT"
  "$SWIFT_OUTPUT" audit "$C_TRACE" "$SWIFT_TRACE" "$C_FINGERPRINT"
  "$SWIFT_OUTPUT" tamper "$SWIFT_TRACE" "$TAMPERED_TRACE"
} | tee "$SWIFT_LOG"
grep -Eq 'swift_audio_sequence_route_recorded records=4 ticks=2 event_ids=1,2,3 coverage=0x[0-9a-f]+ fingerprint=0x[0-9a-f]+ model_ticks=1 queue=1' "$SWIFT_LOG"
grep -Eq 'audio_sequence_pairing_audit admitted=1 c_records=4 swift_records=4 blockers= first_divergence=none fingerprint=0x[0-9a-f]+' "$SWIFT_LOG"
grep -Fq 'audio_sequence_pairing_tamper_rejected=1' "$SWIFT_LOG"

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
  BUILD_DIR_BASE="$ASAN_BUILD" native-core >/dev/null
test -f "$ASAN_BUILD/us_pc/libsm64core.a"
clang_contract "$ASAN_OUTPUT" "$ASAN_BUILD" -fsanitize=address
ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
  "$ASAN_OUTPUT" "$ASAN_TRACE" "$ASAN_SAVE_ROOT" >"$ASAN_LOG" 2>&1
if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$ASAN_LOG"; then
  echo 'AddressSanitizer emitted a finding despite a zero process status' >&2
  exit 1
fi
cmp -s "$C_TRACE" "$ASAN_TRACE"
printf '%s\n' 'audio_sequence_route_sanitizer_passed=1 debug_asan_trace_match=1'

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=0 BUILD_DIR_BASE="$RELEASE_BUILD" native-core >/dev/null
test -f "$RELEASE_BUILD/us_pc/libsm64core.a"
clang_contract "$RELEASE_OUTPUT" "$RELEASE_BUILD"
"$RELEASE_OUTPUT" "$RELEASE_TRACE" "$RELEASE_SAVE_ROOT" >"$RELEASE_LOG" 2>&1
grep -Fq 'audio_sequence_route_debug oracle_end=0 result_status=0' "$RELEASE_LOG"
cmp -s "$C_TRACE" "$RELEASE_TRACE"
printf '%s\n' 'audio_sequence_route_optimized_passed=1 debug_release_trace_match=1'

git -c core.fsmonitor=false diff --check
printf '%s\n' \
  'SM64 Modern audio-sequence route pair smoke passed exact_pair=1 tamper_rejected=1' \
  'native_audio_authority=c sequence_players_pcm_device=1' \
  'swift_audio_observer=value_only owner_thread=1 realtime_callback_instrumentation=0' \
  'c_swift_pair=matched first_divergence=none' \
  'admission=0 ledger_mutation=0 fixture_only=0'
