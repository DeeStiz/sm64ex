#!/usr/bin/env bash
set -euo pipefail

# Phase 85bf runs the authored TEXTSAVES save-menu writer, retains its
# fixed-width source/text receipt, and pairs that receipt with one schema-4
# script record. The route is source-backed; no fixture text or generic script
# event is accepted. This script never mutates the route manifest or ledger.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-text-route-pair"
DEBUG_BUILD="$BUILD_ROOT/native-debug"
ASAN_BUILD="$BUILD_ROOT/native-asan"
RELEASE_BUILD="$BUILD_ROOT/native-release"
TOOL_ROOT="$BUILD_ROOT/tool"
C_OUTPUT="$TOOL_ROOT/sm64-modern-text-route-contract"
ASAN_OUTPUT="$TOOL_ROOT/sm64-modern-text-route-contract-asan"
RELEASE_OUTPUT="$TOOL_ROOT/sm64-modern-text-route-contract-release"
SWIFT_OUTPUT="$TOOL_ROOT/sm64-modern-text-route-swift"
C_TRACE="$BUILD_ROOT/text-c.trace"
C_RECEIPTS="$BUILD_ROOT/text-c.receipts"
ASAN_TRACE="$BUILD_ROOT/text-asan.trace"
ASAN_RECEIPTS="$BUILD_ROOT/text-asan.receipts"
RELEASE_TRACE="$BUILD_ROOT/text-release.trace"
RELEASE_RECEIPTS="$BUILD_ROOT/text-release.receipts"
SWIFT_TRACE="$BUILD_ROOT/text-swift.trace"
TAMPERED_TRACE="$BUILD_ROOT/text-tampered.trace"
TAMPERED_RECEIPTS="$BUILD_ROOT/text-tampered.receipts"
PARTIAL_TRACE="$BUILD_ROOT/text-partial.trace"
SAVE_ROOT="$BUILD_ROOT/save-debug"
ASAN_SAVE_ROOT="$BUILD_ROOT/save-asan"
RELEASE_SAVE_ROOT="$BUILD_ROOT/save-release"
DEBUG_LOG="$BUILD_ROOT/debug.log"
ASAN_LOG="$BUILD_ROOT/asan.log"
RELEASE_LOG="$BUILD_ROOT/release.log"
SWIFT_LOG="$BUILD_ROOT/swift.log"
ADMISSION_REPORT="$BUILD_ROOT/admission.tsv"

# Each native variant must start from the same empty, phase-local save state so
# the authored payload hash is comparable across Debug/ASan/Release and across
# reruns. These paths are generated children of this route's build root.
/bin/rm -rf -- "$SAVE_ROOT" "$ASAN_SAVE_ROOT" "$RELEASE_SAVE_ROOT"
/bin/rm -f -- "$ADMISSION_REPORT"
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
    "$PROJECT_ROOT/tests/sm64_modern_text_route_pair_contract.c" \
    "$native_root/us_pc/libsm64core.a" -o "$output" -lm -lpthread "$@"
}

run_variant() {
  local label="$1"
  local debug_flag="$2"
  local sanitizer_flag="$3"
  local native_root="$4"
  local output="$5"
  local trace="$6"
  local receipts="$7"
  local save_root="$8"
  local log="$9"

  make -C "$PROJECT_ROOT" \
    SM64_MODERN_NATIVE=1 TEXTSAVES=1 DEBUG="$debug_flag" \
    ${sanitizer_flag:+SANITIZE=address} \
    BUILD_DIR_BASE="$native_root" native-core >/dev/null
  test -f "$native_root/us_pc/libsm64core.a"
  clang_contract "$output" "$native_root" \
    ${sanitizer_flag:+-fsanitize=address}
  if [[ -n "$sanitizer_flag" ]]; then
    ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
      "$output" "$trace" "$receipts" "$save_root" >"$log" 2>&1
    if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$log"; then
      echo "AddressSanitizer emitted a finding in $label text route" >&2
      exit 1
    fi
  else
    "$output" "$trace" "$receipts" "$save_root" >"$log" 2>&1
  fi
  grep -Fq 'text_route_init status=0 oracle=0 parity=0' "$log"
  grep -Fq 'text_route_step index=0 status=0 oracle=0 parity=0' "$log"
  grep -Fq 'text_route_step index=1 status=0 oracle=0 parity=0' "$log"
  grep -Eq 'text_route_debug oracle_end=0 result_status=0 actual=[0-9]+ text_records=1 receipts=1 failures=0' "$log"
  grep -Fq 'c_text_route_recorded shard=0xdf0ce0c6988b445d' "$log"
  test "$(wc -c <"$trace" | tr -d '[:space:]')" -eq $((72 + 128))
  test "$(wc -c <"$receipts" | tr -d '[:space:]')" -eq 64
}

run_variant debug 1 "" "$DEBUG_BUILD" "$C_OUTPUT" "$C_TRACE" \
  "$C_RECEIPTS" "$SAVE_ROOT" "$DEBUG_LOG"

xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -import-objc-header "$PROJECT_ROOT/SM64Modern/SM64Modern-Bridging-Header.h" \
  -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/TextReceiptMigration.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_text_route_swift_smoke.swift" \
  -o "$SWIFT_OUTPUT"

{
  "$SWIFT_OUTPUT" write "$C_TRACE" "$C_RECEIPTS" "$SWIFT_TRACE"
  cmp -s "$C_TRACE" "$SWIFT_TRACE"
  "$SWIFT_OUTPUT" audit "$C_TRACE" "$SWIFT_TRACE" "$C_RECEIPTS"
  "$SWIFT_OUTPUT" tamper "$C_TRACE" "$C_RECEIPTS" \
    "$TAMPERED_TRACE" "$TAMPERED_RECEIPTS"
} | tee "$SWIFT_LOG"
grep -Fq 'text_route_pair_audit admitted=1 records=1 receipts=1 first_divergence=none fixture_only=0' "$SWIFT_LOG"

expect_failure() {
  if "$@" >/dev/null 2>&1; then
    echo "expected rejection succeeded: $*" >&2
    exit 1
  fi
}
expect_failure "$SWIFT_OUTPUT" audit "$TAMPERED_TRACE" "$SWIFT_TRACE" "$C_RECEIPTS"
expect_failure "$SWIFT_OUTPUT" audit "$C_TRACE" "$SWIFT_TRACE" "$TAMPERED_RECEIPTS"
head -c 150 "$C_TRACE" >"$PARTIAL_TRACE"
expect_failure "$SWIFT_OUTPUT" audit "$PARTIAL_TRACE" "$SWIFT_TRACE" "$C_RECEIPTS"
printf '%s\n' 'text_route_tamper_partial_rejected=1'

"$SWIFT_OUTPUT" admit "$C_TRACE" "$SWIFT_TRACE" "$C_RECEIPTS" "$ADMISSION_REPORT"
expect_failure "$SWIFT_OUTPUT" admit "$C_TRACE" "$C_TRACE" "$C_RECEIPTS" "$BUILD_ROOT/single.tsv"
expect_failure "$SWIFT_OUTPUT" admit "$C_TRACE" "$SWIFT_TRACE" "$C_RECEIPTS" "$ADMISSION_REPORT"
printf '%s\n' 'text_route_single_artifact_rejected=1 persistent_rerun_rejected=1'

run_variant asan 1 address "$ASAN_BUILD" "$ASAN_OUTPUT" "$ASAN_TRACE" \
  "$ASAN_RECEIPTS" "$ASAN_SAVE_ROOT" "$ASAN_LOG"
cmp -s "$C_TRACE" "$ASAN_TRACE"
cmp -s "$C_RECEIPTS" "$ASAN_RECEIPTS"
printf '%s\n' 'text_route_sanitizer_passed=1 debug_asan_pair_match=1'

run_variant release 0 "" "$RELEASE_BUILD" "$RELEASE_OUTPUT" "$RELEASE_TRACE" \
  "$RELEASE_RECEIPTS" "$RELEASE_SAVE_ROOT" "$RELEASE_LOG"
cmp -s "$C_TRACE" "$RELEASE_TRACE"
cmp -s "$C_RECEIPTS" "$RELEASE_RECEIPTS"
printf '%s\n' 'text_route_optimized_passed=1 debug_release_pair_match=1'

git -c core.fsmonitor=false diff --check
printf '%s\n' \
  'SM64 Modern authored text route C<->Swift pair passed exact_pair=1 tamper_rejected=1' \
  'native_text_authority=c_text_save_writer source_receipt=1 script_record_binding=1' \
  'aligned_seeds_ticks_fingerprints=1 debug_asan_release_match=1 fixture_only=0' \
  'admission=1 manifest_mutation=0 ledger_mutation=0'
