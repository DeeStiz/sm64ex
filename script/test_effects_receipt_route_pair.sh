#!/usr/bin/env bash
set -euo pipefail

# Phase 85ai pairs the real native effect gateways with a value-only Swift
# receipt consumer. The C owner still performs object/audio/rumble mutation;
# no realtime audio callback, raw PCM bytes, or C pointer crosses the seam.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-effects-receipt-route-pair"
DEBUG_BUILD="$BUILD_ROOT/native-debug"
ASAN_BUILD="$BUILD_ROOT/native-asan"
RELEASE_BUILD="$BUILD_ROOT/native-release"
TOOL_ROOT="$BUILD_ROOT/tool"
C_OUTPUT="$TOOL_ROOT/effects-route-contract"
ASAN_OUTPUT="$TOOL_ROOT/effects-route-contract-asan"
RELEASE_OUTPUT="$TOOL_ROOT/effects-route-contract-release"
SWIFT_OUTPUT="$TOOL_ROOT/effects-receipt-swift"
DEBUG_TRACE="$BUILD_ROOT/effects-c.trace"
DEBUG_RECEIPTS="$BUILD_ROOT/effects-c.receipts"
ASAN_TRACE="$BUILD_ROOT/effects-c-asan.trace"
ASAN_RECEIPTS="$BUILD_ROOT/effects-c-asan.receipts"
RELEASE_TRACE="$BUILD_ROOT/effects-c-release.trace"
RELEASE_RECEIPTS="$BUILD_ROOT/effects-c-release.receipts"
SWIFT_TRACE="$BUILD_ROOT/effects-swift.trace"
TAMPERED_TRACE="$BUILD_ROOT/effects-tampered.trace"
TAMPERED_RECEIPTS="$BUILD_ROOT/effects-tampered.receipts"
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
    "$PROJECT_ROOT/tests/sm64_modern_effects_route_pair_contract.c" \
    "$native_root/us_pc/libsm64core.a" -o "$output" -lm -lpthread "$@"
}

run_variant() {
  local variant="$1"
  local debug_flag="$2"
  local sanitizer_flag="$3"
  local native_root="$4"
  local output="$5"
  local trace="$6"
  local receipts="$7"
  local save_root="$8"
  local log="$9"

  make -C "$PROJECT_ROOT" \
    SM64_MODERN_NATIVE=1 DEBUG="$debug_flag" \
    ${sanitizer_flag:+SANITIZE=address} \
    BUILD_DIR_BASE="$native_root" native-core >/dev/null
  test -f "$native_root/us_pc/libsm64core.a"
  clang_contract "$output" "$native_root" ${sanitizer_flag:+-fsanitize=address}
  if [[ -n "$sanitizer_flag" ]]; then
    ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
      "$output" "$trace" "$save_root" "$receipts" >"$log" 2>&1
    if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$log"; then
      echo "AddressSanitizer emitted a finding in $variant effects receipt route" >&2
      exit 1
    fi
  else
    "$output" "$trace" "$save_root" "$receipts" >"$log" 2>&1
  fi
  grep -Fq \
    'effects_route_debug oracle_end=0 result_status=0 actual=' \
    "$log"
  grep -Fq \
    'retained=58 failures=0' \
    "$log"
  grep -Fq \
    'effects_route_recorded path=' \
    "$log"
  grep -Fq \
    'records=58 receipts=58 ticks=3 coverage=0x12756c2de89cfbc4 owner_thread=1' \
    "$log"
  test "$(wc -c < "$trace" | tr -d '[:space:]')" -eq $((72 + 58 * 128))
  test "$(wc -c < "$receipts" | tr -d '[:space:]')" -eq $((58 * 120))
}

run_variant debug 1 "" "$DEBUG_BUILD" "$C_OUTPUT" "$DEBUG_TRACE" \
  "$DEBUG_RECEIPTS" "$SAVE_ROOT" "$DEBUG_LOG"

xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -import-objc-header "$PROJECT_ROOT/SM64Modern/SM64Modern-Bridging-Header.h" \
  -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/EffectsMigration.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_effects_receipt_smoke.swift" \
  -o "$SWIFT_OUTPUT"

{
  "$SWIFT_OUTPUT" pair "$DEBUG_TRACE" "$DEBUG_RECEIPTS" "$SWIFT_TRACE"
  cmp -s "$DEBUG_TRACE" "$SWIFT_TRACE"
  "$SWIFT_OUTPUT" tamper "$DEBUG_TRACE" "$DEBUG_RECEIPTS" \
    "$TAMPERED_TRACE" "$TAMPERED_RECEIPTS"
} | tee "$SWIFT_LOG"
grep -Fq 'swift_effects_route_recorded records=58 ticks=2,3 ids=1:5,3:2,4:49,5:2 owner_thread_receipts=1' "$SWIFT_LOG"
grep -Fq 'effects_canonical_hash_tamper_rejected=1' "$SWIFT_LOG"
grep -Fq 'effects_receipt_hash_tamper_rejected=1' "$SWIFT_LOG"
printf '%s\n' 'effects_receipt_route_pair_swift_passed=1 debug_pair=1 tamper_rejected=1'

run_variant asan 1 address "$ASAN_BUILD" "$ASAN_OUTPUT" "$ASAN_TRACE" \
  "$ASAN_RECEIPTS" "$ASAN_SAVE_ROOT" "$ASAN_LOG"
cmp -s "$DEBUG_TRACE" "$ASAN_TRACE"
cmp -s "$DEBUG_RECEIPTS" "$ASAN_RECEIPTS"
printf '%s\n' 'effects_receipt_route_sanitizer_passed=1 debug_asan_pair_match=1'

run_variant release 0 "" "$RELEASE_BUILD" "$RELEASE_OUTPUT" "$RELEASE_TRACE" \
  "$RELEASE_RECEIPTS" "$RELEASE_SAVE_ROOT" "$RELEASE_LOG"
cmp -s "$DEBUG_TRACE" "$RELEASE_TRACE"
cmp -s "$DEBUG_RECEIPTS" "$RELEASE_RECEIPTS"
printf '%s\n' 'effects_receipt_route_optimized_passed=1 debug_release_pair_match=1'

git -c core.fsmonitor=false diff --check
printf '%s\n' \
  'SM64 Modern effects receipt C↔Swift route pair passed exact_pair=1 tamper_rejected=1' \
  'native_effect_authority=c object_audio_rumble=1 owner_thread_receipt=1' \
  'swift_effect_consumer=value_only raw_pcm_crossing=0 realtime_callback_instrumentation=0' \
  'behavior_identity=source_name_hash anchor_relative_fallback=fail_closed' \
  'admission=0 ledger_mutation=0 fixture_only=0'
