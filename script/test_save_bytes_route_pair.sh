#!/usr/bin/env bash
set -euo pipefail

# Phase 85u owns only the canonical oracle_hook|save_bytes row. C remains the
# native SaveBuffer/persistence authority; Swift independently hashes and
# decodes isolated raw images before copying the exact schema-4 receipts.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-save-bytes-route-pair"
DEBUG_BUILD="$BUILD_ROOT/native-debug"
ASAN_BUILD="$BUILD_ROOT/native-asan"
RELEASE_BUILD="$BUILD_ROOT/native-release"
TOOL_ROOT="$BUILD_ROOT/tool"
C_OUTPUT="$TOOL_ROOT/sm64-modern-save-bytes-route-contract"
ASAN_OUTPUT="$TOOL_ROOT/sm64-modern-save-bytes-route-contract-asan"
RELEASE_OUTPUT="$TOOL_ROOT/sm64-modern-save-bytes-route-contract-release"
SWIFT_OUTPUT="$TOOL_ROOT/sm64-modern-save-bytes-route-swift"
C_TRACE="$BUILD_ROOT/save-bytes-c.trace"
ASAN_TRACE="$BUILD_ROOT/save-bytes-c-asan.trace"
RELEASE_TRACE="$BUILD_ROOT/save-bytes-c-release.trace"
SIDE_CAR="$BUILD_ROOT/save-bytes-c.sidecar"
ASAN_SIDE_CAR="$BUILD_ROOT/save-bytes-c-asan.sidecar"
RELEASE_SIDE_CAR="$BUILD_ROOT/save-bytes-c-release.sidecar"
SWIFT_TRACE="$BUILD_ROOT/save-bytes-swift.trace"
TAMPERED_TRACE="$BUILD_ROOT/save-bytes-swift.tampered.trace"
SAVE_ROOT="$BUILD_ROOT/save"
ASAN_SAVE_ROOT="$BUILD_ROOT/save-asan"
RELEASE_SAVE_ROOT="$BUILD_ROOT/save-release"
DEBUG_LOG="$BUILD_ROOT/debug.log"
ASAN_LOG="$BUILD_ROOT/asan.log"
RELEASE_LOG="$BUILD_ROOT/release.log"
SWIFT_LOG="$BUILD_ROOT/swift.log"

# Each native run must begin from a fresh isolated EEPROM image.  These are
# generated children of this phase's build root, never user save locations.
/bin/rm -rf -- "$SAVE_ROOT" "$ASAN_SAVE_ROOT" "$RELEASE_SAVE_ROOT"
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
    "$PROJECT_ROOT/tests/sm64_modern_save_bytes_route_pair_contract.c" \
    "$archive_root/us_pc/libsm64core.a" \
    -o "$output" -lm -lpthread "$@"
}

clang_contract "$C_OUTPUT" "$DEBUG_BUILD"
"$C_OUTPUT" "$C_TRACE" "$SIDE_CAR" "$SAVE_ROOT" >"$DEBUG_LOG" 2>&1
grep -Fq 'save_bytes_route_init status=0 oracle=0 parity=0' "$DEBUG_LOG"
grep -Fq 'save_bytes_route_step index=0 status=0 oracle=0 parity=0' "$DEBUG_LOG"
grep -Fq 'save_bytes_route_step index=1 status=0 oracle=0 parity=0' "$DEBUG_LOG"
grep -Eq 'save_bytes_route_debug oracle_end=0 result_status=0 actual=[1-9][0-9]* retained=4 failures=0 ticks=2 input_calls=[1-9][0-9]*' "$DEBUG_LOG"
grep -Fq 'c_save_bytes_route_recorded shard=0x4e5552533aaa717d records=4 ticks=3 event_counts=1,1,1,1' "$DEBUG_LOG"
test "$(wc -c <"$C_TRACE" | tr -d '[:space:]')" -eq $((72 + 4 * 128))
test "$(wc -l <"$SIDE_CAR" | tr -d '[:space:]')" -eq 4

xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/ProgressionState.swift" \
  "$PROJECT_ROOT/SM64Modern/CoinScoreAges.swift" \
  "$PROJECT_ROOT/SM64Modern/SaveFileCodec.swift" \
  "$PROJECT_ROOT/SM64Modern/SaveFileMutator.swift" \
  "$PROJECT_ROOT/SM64Modern/ProgressionPersistence.swift" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_save_bytes_route_swift_smoke.swift" \
  -o "$SWIFT_OUTPUT"
{
  "$SWIFT_OUTPUT" write "$C_TRACE" "$SIDE_CAR" "$SWIFT_TRACE"
  "$SWIFT_OUTPUT" audit "$C_TRACE" "$SWIFT_TRACE"
  "$SWIFT_OUTPUT" tamper "$SWIFT_TRACE" "$TAMPERED_TRACE"
} | tee "$SWIFT_LOG"
grep -Fq 'swift_save_bytes_route_recorded shard=0x4e5552533aaa717d records=4 ticks=2,3 event_ids=1,2,3,4' "$SWIFT_LOG"
grep -Fq 'save_bytes_pairing_audit admitted=1 c_records=4 swift_records=4 blockers= first_divergence=none' "$SWIFT_LOG"
grep -Fq 'save_bytes_pairing_tamper_rejected=1' "$SWIFT_LOG"

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
  BUILD_DIR_BASE="$ASAN_BUILD" native-core >/dev/null
test -f "$ASAN_BUILD/us_pc/libsm64core.a"
clang_contract "$ASAN_OUTPUT" "$ASAN_BUILD" -fsanitize=address
ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
  "$ASAN_OUTPUT" "$ASAN_TRACE" "$ASAN_SIDE_CAR" "$ASAN_SAVE_ROOT" >"$ASAN_LOG" 2>&1
if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$ASAN_LOG"; then
  echo 'AddressSanitizer emitted a finding despite a zero process status' >&2
  exit 1
fi
cmp -s "$C_TRACE" "$ASAN_TRACE"
cmp -s "$SIDE_CAR" "$ASAN_SIDE_CAR"
printf '%s\n' 'save_bytes_route_sanitizer_passed=1 debug_asan_trace_match=1 sidecar_match=1'

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=0 BUILD_DIR_BASE="$RELEASE_BUILD" native-core >/dev/null
test -f "$RELEASE_BUILD/us_pc/libsm64core.a"
clang_contract "$RELEASE_OUTPUT" "$RELEASE_BUILD"
"$RELEASE_OUTPUT" "$RELEASE_TRACE" "$RELEASE_SIDE_CAR" "$RELEASE_SAVE_ROOT" >"$RELEASE_LOG" 2>&1
grep -Eq 'save_bytes_route_debug oracle_end=0 result_status=0 actual=[1-9][0-9]* retained=4 failures=0' "$RELEASE_LOG"
cmp -s "$C_TRACE" "$RELEASE_TRACE"
cmp -s "$SIDE_CAR" "$RELEASE_SIDE_CAR"
printf '%s\n' 'save_bytes_route_release_passed=1 debug_release_trace_match=1 sidecar_match=1'

git -c core.fsmonitor=false diff --check
printf '%s\n' \
  'SM64 Modern save-bytes route pair smoke passed exact_pair=1 tamper_rejected=1' \
  'native_save_bytes=512 image_bytes event_ids=1,2,3,4 ticks=2,3' \
  'swift_persistence_boundary=512_byte_image decode=1 primary_backup_equal=1 menu_equal=1' \
  'c_swift_pair=matched first_divergence=none' \
  'admission=0 ledger_mutation=0 fixture_only=0'
