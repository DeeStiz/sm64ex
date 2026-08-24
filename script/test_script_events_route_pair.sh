#!/usr/bin/env bash
set -euo pipefail

# Phase 85n owns only the canonical oracle_hook|script_events row. C remains
# the level/behavior interpreter authority; Swift receives copied schema-4
# event records and rebuilds their canonical hashes. This is not a fixture or
# a route-ledger admission command.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-script-events-route-pair"
DEBUG_BUILD="$BUILD_ROOT/native-debug"
ASAN_BUILD="$BUILD_ROOT/native-asan"
RELEASE_BUILD="$BUILD_ROOT/native-release"
TOOL_ROOT="$BUILD_ROOT/tool"
C_OUTPUT="$TOOL_ROOT/sm64-modern-script-events-route-contract"
ASAN_OUTPUT="$TOOL_ROOT/sm64-modern-script-events-route-contract-asan"
RELEASE_OUTPUT="$TOOL_ROOT/sm64-modern-script-events-route-contract-release"
SWIFT_OUTPUT="$TOOL_ROOT/sm64-modern-script-events-route-swift"
C_TRACE="$BUILD_ROOT/script-events-c.trace"
ASAN_TRACE="$BUILD_ROOT/script-events-c-asan.trace"
RELEASE_TRACE="$BUILD_ROOT/script-events-c-release.trace"
SWIFT_TRACE="$BUILD_ROOT/script-events-swift.trace"
TAMPERED_TRACE="$BUILD_ROOT/script-events-swift.tampered.trace"
SAVE_ROOT="$BUILD_ROOT/save"
ASAN_SAVE_ROOT="$BUILD_ROOT/save-asan"
RELEASE_SAVE_ROOT="$BUILD_ROOT/save-release"
DEBUG_LOG="$BUILD_ROOT/debug.log"
ASAN_LOG="$BUILD_ROOT/asan.log"
RELEASE_LOG="$BUILD_ROOT/release.log"

mkdir -p "$BUILD_ROOT" "$SAVE_ROOT" "$ASAN_SAVE_ROOT" "$RELEASE_SAVE_ROOT" \
  "$TOOL_ROOT/module-cache"

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 \
  DEBUG=1 \
  BUILD_DIR_BASE="$DEBUG_BUILD" \
  native-core >/dev/null
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
    "$PROJECT_ROOT/tests/sm64_modern_script_events_route_pair_contract.c" \
    "$archive_root/us_pc/libsm64core.a" \
    -o "$output" -lm -lpthread "$@"
}

clang_contract "$C_OUTPUT" "$DEBUG_BUILD"
"$C_OUTPUT" "$C_TRACE" "$SAVE_ROOT" >"$DEBUG_LOG" 2>&1
grep -Fq 'script_events_route_init status=0 oracle=0 parity=0' "$DEBUG_LOG"
grep -Fq 'script_events_route_step index=0 status=0 oracle=0 parity=0' "$DEBUG_LOG"
grep -Fq 'script_events_route_step index=1 status=0 oracle=0 parity=0' "$DEBUG_LOG"
grep -Eq 'script_events_route_debug oracle_end=0 result_status=0 actual=[1-9][0-9]* retained=[1-9][0-9]* failures=0 ticks=2' "$DEBUG_LOG"
grep -Eq 'c_script_events_route_recorded shard=0x2b0f6063b5463e9c .* records=[1-9][0-9]* ticks=3 event_counts=[1-9][0-9]*,[1-9][0-9]*,[0-9][0-9]*,[1-9][0-9]*,[1-9][0-9]* coverage=0x[0-9a-f]{16}' "$DEBUG_LOG"
test "$(wc -c <"$C_TRACE" | tr -d '[:space:]')" -gt 72

xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/ScriptEventsMigration.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_script_events_route_swift_smoke.swift" \
  -o "$SWIFT_OUTPUT"
{
  "$SWIFT_OUTPUT" write "$C_TRACE" "$SWIFT_TRACE"
  "$SWIFT_OUTPUT" audit "$C_TRACE" "$SWIFT_TRACE"
  "$SWIFT_OUTPUT" tamper "$SWIFT_TRACE" "$TAMPERED_TRACE"
} | tee "$BUILD_ROOT/swift.log"
grep -Eq 'swift_script_events_route_recorded records=[1-9][0-9]* ticks=2,3 event_kinds=[2-5] coverage=0x[0-9a-f]{16}' "$BUILD_ROOT/swift.log"
grep -Fq 'script_events_pairing_audit admitted=1' "$BUILD_ROOT/swift.log"
grep -Fq 'blockers= first_divergence=none' "$BUILD_ROOT/swift.log"
grep -Fq 'script_events_pairing_tamper_rejected=1' "$BUILD_ROOT/swift.log"

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
  BUILD_DIR_BASE="$ASAN_BUILD" \
  native-core >/dev/null
test -f "$ASAN_BUILD/us_pc/libsm64core.a"
clang_contract "$ASAN_OUTPUT" "$ASAN_BUILD" -fsanitize=address
ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
  "$ASAN_OUTPUT" "$ASAN_TRACE" "$ASAN_SAVE_ROOT" >"$ASAN_LOG" 2>&1
if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$ASAN_LOG"; then
  echo 'AddressSanitizer emitted a finding despite a zero process status' >&2
  exit 1
fi
cmp -s "$C_TRACE" "$ASAN_TRACE"
printf '%s\n' 'script_events_route_sanitizer_passed=1 debug_asan_trace_match=1'

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=0 \
  BUILD_DIR_BASE="$RELEASE_BUILD" \
  native-core >/dev/null
test -f "$RELEASE_BUILD/us_pc/libsm64core.a"
clang_contract "$RELEASE_OUTPUT" "$RELEASE_BUILD"
"$RELEASE_OUTPUT" "$RELEASE_TRACE" "$RELEASE_SAVE_ROOT" >"$RELEASE_LOG" 2>&1
grep -Fq 'script_events_route_debug oracle_end=0 result_status=0' "$RELEASE_LOG"
cmp -s "$C_TRACE" "$RELEASE_TRACE"
printf '%s\n' 'script_events_route_optimized_passed=1 debug_release_trace_match=1'

git -c core.fsmonitor=false diff --check
printf '%s\n' \
  'SM64 Modern script-events route pair smoke passed exact_pair=1 tamper_rejected=1' \
  'native_script_events_domain=6 record_kind=3 ticks=2,3' \
  'swift_script_events_receipts=source_backed_value_only owner_thread=1' \
  'c_swift_pair=matched first_divergence=none' \
  'admission=0 ledger_mutation=0 fixture_only=0'
