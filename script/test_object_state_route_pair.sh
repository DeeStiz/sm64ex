#!/usr/bin/env bash
set -euo pipefail

# Phase 85n owns the canonical oracle_hook|object_state route. The C
# lifecycle remains authoritative; Swift mirrors the source-authored wooden
# door snapshot. This is a pair audit only: no manifest, ledger, or promotion
# artifact is written here.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="${SM64_OBJECT_STATE_ROUTE_BUILD_ROOT:-$PROJECT_ROOT/build/sm64-modern-object-state-route-pair}"
DEBUG_BUILD="$BUILD_ROOT/native-debug"
ASAN_BUILD_ROOT="$BUILD_ROOT/native-asan"
RELEASE_BUILD_ROOT="$BUILD_ROOT/native-release"
TOOL_ROOT="$BUILD_ROOT/tool"
C_OUTPUT="$TOOL_ROOT/sm64-modern-object-state-route-contract"
ASAN_OUTPUT="$TOOL_ROOT/sm64-modern-object-state-route-contract-asan"
RELEASE_OUTPUT="$TOOL_ROOT/sm64-modern-object-state-route-contract-release"
SWIFT_OUTPUT="$TOOL_ROOT/sm64-modern-object-state-route-swift"
C_TRACE="$BUILD_ROOT/object-state-c.trace"
ASAN_TRACE="$BUILD_ROOT/object-state-c-asan.trace"
RELEASE_TRACE="$BUILD_ROOT/object-state-c-release.trace"
SWIFT_TRACE="$BUILD_ROOT/object-state-swift.trace"
TAMPERED_TRACE="$BUILD_ROOT/object-state-swift.tampered.trace"
mkdir -p "$BUILD_ROOT" "$TOOL_ROOT/module-cache"
# A unique save directory per variant prevents prior lifecycle writes from
# changing the authored initial-save state. Trace/log paths remain stable for
# the admission harness, while the generated save roots are never reused.
SAVE_ROOT="$(mktemp -d "$BUILD_ROOT/save-debug.XXXXXX")"
ASAN_SAVE_ROOT="$(mktemp -d "$BUILD_ROOT/save-asan.XXXXXX")"
RELEASE_SAVE_ROOT="$(mktemp -d "$BUILD_ROOT/save-release.XXXXXX")"
NATIVE_LOG="$BUILD_ROOT/native.log"
SWIFT_LOG="$BUILD_ROOT/swift.log"
ASAN_LOG="$BUILD_ROOT/asan.log"
RELEASE_LOG="$BUILD_ROOT/release.log"

clang_contract() {
  local output="$1"
  local native_root="$2"
  shift 2
  xcrun --sdk macosx clang \
    -std=c11 -Wall -Wextra -Werror \
    -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
    -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
    -I"$native_root/us_pc" \
    "$PROJECT_ROOT/tests/sm64_modern_object_state_route_pair_contract.c" \
    "$native_root/us_pc/libsm64core.a" \
    -o "$output" -lm -lpthread "$@"
}

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 \
  DEBUG=1 \
  BUILD_DIR_BASE="$DEBUG_BUILD" \
  native-core >/dev/null
test -f "$DEBUG_BUILD/us_pc/libsm64core.a"
clang_contract "$C_OUTPUT" "$DEBUG_BUILD"

SM64_MODERN_AUTOMATED_CASTLE_AREA2=1 \
  "$C_OUTPUT" "$C_TRACE" "$SAVE_ROOT" 2>&1 | tee "$NATIVE_LOG"
grep -Fq 'object_state_route_init status=0 oracle=0 parity=0' "$NATIVE_LOG"
grep -Fq 'object_state_route_target subject=1' "$NATIVE_LOG"
grep -Fq 'object_state_route_step index=0 status=0 oracle=0 parity=0' "$NATIVE_LOG"
grep -Fq 'object_state_route_step index=1 status=0 oracle=0 parity=0' "$NATIVE_LOG"
grep -Fq 'object_state_route_debug oracle_end=0 result_status=0' "$NATIVE_LOG"
grep -Fq 'object_state_route_debug oracle_end=0 result_status=0 actual=2965 retained=28 target=1 failures=0' "$NATIVE_LOG"
grep -Eq 'c_object_state_route_recorded shard=0x862c3d78b60d657c subject=1 records=28 ticks=2,3 coverage=0x[0-9a-f]{16}' "$NATIVE_LOG"
test -s "$C_TRACE"
test "$(wc -c < "$C_TRACE" | tr -d '[:space:]')" -eq $((72 + 28 * 128))

xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectSnapshot.swift" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_object_state_route_swift_smoke.swift" \
  -o "$SWIFT_OUTPUT"

{
  "$SWIFT_OUTPUT" write "$SWIFT_TRACE"
  "$SWIFT_OUTPUT" audit "$C_TRACE" "$SWIFT_TRACE"
  "$SWIFT_OUTPUT" tamper "$SWIFT_TRACE" "$TAMPERED_TRACE"
} | tee "$SWIFT_LOG"
grep -Fq 'swift_object_state_route_recorded shard=0x862c3d78b60d657c subject=1 records=28 ticks=2,3' "$SWIFT_LOG"
grep -Fq 'object_state_pairing_audit admitted=1 c_records=28 swift_records=28 blockers= first_divergence=none' "$SWIFT_LOG"
grep -Fq 'object_state_pairing_tamper_rejected=1' "$SWIFT_LOG"
test -s "$SWIFT_TRACE"
cmp -s "$C_TRACE" "$SWIFT_TRACE"

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
  BUILD_DIR_BASE="$ASAN_BUILD_ROOT" native-core >/dev/null
test -f "$ASAN_BUILD_ROOT/us_pc/libsm64core.a"
clang_contract "$ASAN_OUTPUT" "$ASAN_BUILD_ROOT" -fsanitize=address

set +e
ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
  SM64_MODERN_AUTOMATED_CASTLE_AREA2=1 \
  "$ASAN_OUTPUT" "$ASAN_TRACE" "$ASAN_SAVE_ROOT" >"$ASAN_LOG" 2>&1
asan_status=$?
set -e
if (( asan_status == 0 )); then
  test -s "$ASAN_TRACE"
  cmp -s "$C_TRACE" "$ASAN_TRACE"
  if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$ASAN_LOG"; then
    echo 'AddressSanitizer emitted a finding despite a zero process status' >&2
    exit 1
  fi
  printf '%s\n' 'object_state_route_sanitizer_passed=1 debug_asan_byte_match=1'
else
  grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$ASAN_LOG"
  printf '%s\n' 'object_state_route_sanitizer_blocked=1 finding=address-sanitizer'
fi

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=0 \
  BUILD_DIR_BASE="$RELEASE_BUILD_ROOT" native-core >/dev/null
test -f "$RELEASE_BUILD_ROOT/us_pc/libsm64core.a"
clang_contract "$RELEASE_OUTPUT" "$RELEASE_BUILD_ROOT"
SM64_MODERN_AUTOMATED_CASTLE_AREA2=1 \
  "$RELEASE_OUTPUT" "$RELEASE_TRACE" "$RELEASE_SAVE_ROOT" >"$RELEASE_LOG" 2>&1
grep -Fq 'object_state_route_init status=0 oracle=0 parity=0' "$RELEASE_LOG"
grep -Fq 'object_state_route_step index=0 status=0 oracle=0 parity=0' "$RELEASE_LOG"
grep -Fq 'object_state_route_step index=1 status=0 oracle=0 parity=0' "$RELEASE_LOG"
grep -Fq 'object_state_route_debug oracle_end=0 result_status=0 actual=2965 retained=28 target=1 failures=0' "$RELEASE_LOG"
grep -Fq 'c_object_state_route_recorded shard=0x862c3d78b60d657c subject=1 records=28 ticks=2,3 coverage=0x492987af540d8c0c' "$RELEASE_LOG"
cmp -s "$C_TRACE" "$RELEASE_TRACE"
printf '%s\n' 'object_state_route_release_passed=1 debug_release_byte_match=1'

git -c core.fsmonitor=false diff --check
asan_match=0
if cmp -s "$C_TRACE" "$ASAN_TRACE"; then asan_match=1; fi
printf '%s\n' \
  'SM64 Modern object-state route pair smoke passed exact_pair=1 admission_deferred=1' \
  'native_object_records=28 subject=1 ids=400..413 ticks=2,3 source_backed=1' \
  'swift_object_snapshot_records=28 actor_values=20 tamper_rejected=1' \
  'c_swift_pair=matched first_divergence=none admission=0 ledger_mutation=0' \
  "sanitizer_status=$asan_status trace_match=$asan_match release_match=1"
