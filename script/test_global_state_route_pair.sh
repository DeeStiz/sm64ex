#!/usr/bin/env bash
set -euo pipefail

# Phase 85j owns the canonical oracle_hook|global_state snapshot boundary. C
# records the real six-field owner window and publishes the same fixed-width
# snapshots; Swift mirrors only those publications. This is a pair audit, not
# a manifest/ledger admission command.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-global-state-route-pair"
NATIVE_BUILD="$BUILD_ROOT/native-debug/us_pc"
ASAN_BUILD_ROOT="$BUILD_ROOT/native-asan"
C_OUTPUT="$BUILD_ROOT/sm64-modern-global-state-route-contract"
ASAN_OUTPUT="$BUILD_ROOT/sm64-modern-global-state-route-contract-asan"
SWIFT_OUTPUT="$BUILD_ROOT/sm64-modern-global-state-route-swift"
C_TRACE="$BUILD_ROOT/global-state-c.trace"
ASAN_TRACE="$BUILD_ROOT/global-state-c-asan.trace"
SWIFT_TRACE="$BUILD_ROOT/global-state-swift.trace"
TAMPERED_TRACE="$BUILD_ROOT/global-state-swift.tampered.trace"
SNAPSHOTS="$C_TRACE.snapshots"
ASAN_SNAPSHOTS="$ASAN_TRACE.snapshots"
SAVE_ROOT="$BUILD_ROOT/save"
ASAN_SAVE_ROOT="$BUILD_ROOT/save-asan"
NATIVE_LOG="$BUILD_ROOT/native.log"
ASAN_LOG="$BUILD_ROOT/asan.log"
SWIFT_LOG="$BUILD_ROOT/swift.log"

mkdir -p "$BUILD_ROOT" "$SAVE_ROOT" "$ASAN_SAVE_ROOT"

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 \
  DEBUG=1 \
  BUILD_DIR_BASE="$PROJECT_ROOT/build/sm64-modern-global-state-route-pair/native-debug" \
  native-core >/dev/null
test -f "$NATIVE_BUILD/libsm64core.a"

xcrun --sdk macosx clang \
  -std=c11 -Wall -Wextra -Werror \
  -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
  -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  -I"$NATIVE_BUILD" \
  "$PROJECT_ROOT/tests/sm64_modern_global_state_route_pair_contract.c" \
  "$NATIVE_BUILD/libsm64core.a" \
  -o "$C_OUTPUT" -lm -lpthread

"$C_OUTPUT" "$C_TRACE" "$SAVE_ROOT" 2>&1 | tee "$NATIVE_LOG"
grep -Fq 'global_state_route_init status=0 state=2 oracle=0 parity=0' "$NATIVE_LOG"
grep -Fq 'global_state_route_step index=0 status=0 oracle=0 parity=0' "$NATIVE_LOG"
grep -Fq 'global_state_route_step index=1 status=0 oracle=0 parity=0' "$NATIVE_LOG"
grep -Fq 'global_state_route_debug oracle_end=0 result_status=0 actual=1789 retained=12 failures=0' "$NATIVE_LOG"
grep -Fq 'global_state_route_recorded' "$NATIVE_LOG"
grep -Fq 'snapshots=2 ticks=3' "$NATIVE_LOG"
test -s "$C_TRACE"
test "$(wc -c < "$C_TRACE" | tr -d '[:space:]')" -eq $((72 + 12 * 128))
test "$(wc -c < "$SNAPSHOTS" | tr -d '[:space:]')" -eq $((2 * 48))

xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -import-objc-header "$PROJECT_ROOT/SM64Modern/SM64Modern-Bridging-Header.h" \
  -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/GlobalStateMigration.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_global_state_route_swift_smoke.swift" \
  -o "$SWIFT_OUTPUT"

{
  "$SWIFT_OUTPUT" write "$SNAPSHOTS" "$C_TRACE" "$SWIFT_TRACE"
  "$SWIFT_OUTPUT" audit "$C_TRACE" "$SWIFT_TRACE"
  "$SWIFT_OUTPUT" tamper "$SWIFT_TRACE" "$TAMPERED_TRACE"
} | tee "$SWIFT_LOG"
grep -Fq 'swift_global_state_route_recorded snapshots=2 records=12 ticks=2,3 timer=1,2 seed=45572' "$SWIFT_LOG"
grep -Fq 'global_state_pairing_audit admitted=1 c_records=12 swift_records=12 blockers= first_divergence=none' "$SWIFT_LOG"
grep -Fq 'global_state_pairing_tamper_rejected=1' "$SWIFT_LOG"

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
  BUILD_DIR_BASE="$ASAN_BUILD_ROOT" native-core >/dev/null
test -f "$ASAN_BUILD_ROOT/us_pc/libsm64core.a"
xcrun --sdk macosx clang \
  -std=c11 -Wall -Wextra -Werror -fsanitize=address \
  -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
  -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  -I"$ASAN_BUILD_ROOT/us_pc" \
  "$PROJECT_ROOT/tests/sm64_modern_global_state_route_pair_contract.c" \
  "$ASAN_BUILD_ROOT/us_pc/libsm64core.a" \
  -o "$ASAN_OUTPUT" -lm -lpthread

set +e
ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
  "$ASAN_OUTPUT" "$ASAN_TRACE" "$ASAN_SAVE_ROOT" >"$ASAN_LOG" 2>&1
asan_status=$?
set -e
if (( asan_status == 0 )); then
  test -s "$ASAN_TRACE"
  test -s "$ASAN_SNAPSHOTS"
  cmp -s "$C_TRACE" "$ASAN_TRACE"
  cmp -s "$SNAPSHOTS" "$ASAN_SNAPSHOTS"
  if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$ASAN_LOG"; then
    echo 'AddressSanitizer emitted a finding despite a zero process status' >&2
    exit 1
  fi
  printf '%s\n' 'global_state_route_sanitizer_passed=1 debug_asan_trace_match=1 snapshots_match=1'
else
  grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$ASAN_LOG"
  printf '%s\n' 'global_state_route_sanitizer_blocked=1 finding=address-sanitizer'
fi

git -c core.fsmonitor=false diff --check
printf '%s\n' \
  'SM64 Modern global-state route pair smoke passed exact_pair=1 admission_deferred=1' \
  'native_global_records=12 ids=1..6 ticks=2,3 publication_snapshots=2' \
  'swift_global_mirror_records=12 source_backed=1 tamper_rejected=1' \
  'c_swift_pair=matched first_divergence=none c_status=0' \
  'authority=c publication_boundary=owner_thread tick_order=preserved' \
  'admission=0 ledger_mutation=0'
