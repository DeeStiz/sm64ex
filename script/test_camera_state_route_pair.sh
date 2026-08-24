#!/usr/bin/env bash
set -euo pipefail

# Phase 85f is deliberately a pair audit, not a route-admission command. The
# C owner records the real camera snapshot window; the independent Swift
# camera kernels must now match every record byte-for-byte. No manifest or
# route ledger is written here.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-camera-state-route-pair"
NATIVE_BUILD="$PROJECT_ROOT/build/sm64-modern-camera-state-route-pair/native-debug/us_pc"
ASAN_BUILD_ROOT="$BUILD_ROOT/native-asan"
C_OUTPUT="$BUILD_ROOT/sm64-modern-camera-state-route-contract"
ASAN_OUTPUT="$BUILD_ROOT/sm64-modern-camera-state-route-contract-asan"
SWIFT_OUTPUT="$BUILD_ROOT/sm64-modern-camera-state-route-swift"
C_TRACE="$BUILD_ROOT/camera-state-c.trace"
SWIFT_TRACE="$BUILD_ROOT/camera-state-swift.trace"
TAMPERED_TRACE="$BUILD_ROOT/camera-state-swift.tampered.trace"
ASAN_TRACE="$BUILD_ROOT/camera-state-c-asan.trace"
SAVE_ROOT="$BUILD_ROOT/save"
ASAN_SAVE_ROOT="$BUILD_ROOT/save-asan"
NATIVE_LOG="$BUILD_ROOT/native.log"
SWIFT_LOG="$BUILD_ROOT/swift.log"
ASAN_LOG="$BUILD_ROOT/asan.log"

mkdir -p "$BUILD_ROOT" "$SAVE_ROOT" "$ASAN_SAVE_ROOT"

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 \
  DEBUG=1 \
  BUILD_DIR_BASE="$PROJECT_ROOT/build/sm64-modern-camera-state-route-pair/native-debug" \
  native-core >/dev/null
test -f "$NATIVE_BUILD/libsm64core.a"

xcrun --sdk macosx clang \
  -std=c11 -Wall -Wextra -Werror \
  -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
  -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  -I"$NATIVE_BUILD" \
  "$PROJECT_ROOT/tests/sm64_modern_camera_state_route_pair_contract.c" \
  "$NATIVE_BUILD/libsm64core.a" \
  -o "$C_OUTPUT" -lm -lpthread

"$C_OUTPUT" "$C_TRACE" "$SAVE_ROOT" 2>&1 | tee "$NATIVE_LOG"
grep -Fq 'camera_state_route_init status=0 oracle=0' "$NATIVE_LOG"
grep -Fq 'camera_state_route_step index=0 status=0 oracle=0 parity=0' "$NATIVE_LOG"
grep -Fq 'camera_state_route_step index=1 status=0 oracle=0 parity=0' "$NATIVE_LOG"
grep -Fq 'camera_state_route_debug oracle_end=0 result_status=0' "$NATIVE_LOG"
grep -Fq 'c_camera_state_route_recorded shard=0x4eb19b71d76be0d4' "$NATIVE_LOG"
grep -Eq 'c_camera_state_route_recorded .* records=14 ticks=3 .*coverage=0x[0-9a-f]{16}' "$NATIVE_LOG"
test -s "$C_TRACE"
test "$(wc -c < "$C_TRACE" | tr -d '[:space:]')" -eq $((72 + 14 * 128))

xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" \
  "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/CameraPrimitives.swift" \
  "$PROJECT_ROOT/SM64Modern/CameraGeometry.swift" \
  "$PROJECT_ROOT/SM64Modern/CameraModeState.swift" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_camera_state_route_swift_smoke.swift" \
  -o "$SWIFT_OUTPUT"

{
  "$SWIFT_OUTPUT" write "$SWIFT_TRACE"
  "$SWIFT_OUTPUT" audit "$C_TRACE" "$SWIFT_TRACE"
  "$SWIFT_OUTPUT" tamper "$SWIFT_TRACE" "$TAMPERED_TRACE"
} | tee "$SWIFT_LOG"
grep -Fq 'swift_camera_state_route_recorded' "$SWIFT_LOG"
grep -Fq 'records=14 ticks=2,3 coverage=0x14ba7a692ee1c471' "$SWIFT_LOG"
grep -Fq 'camera_position_pairing matched=1' "$SWIFT_LOG"
grep -Fq 'camera_focus_pairing matched=1' "$SWIFT_LOG"
grep -Fq 'camera_state_pairing_audit admitted=1 c_records=14 swift_records=14 blockers= first_divergence=none' "$SWIFT_LOG"
grep -Fq 'camera_state_pairing_tamper_rejected=1' "$SWIFT_LOG"

# Keep a fresh sanitizer attempt as explicit evidence. A nonzero sanitizer
# result is retained as a blocker, never treated as route qualification; a
# clean run must also produce byte-identical C evidence.
make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
  BUILD_DIR_BASE="$ASAN_BUILD_ROOT" native-core >/dev/null
test -f "$ASAN_BUILD_ROOT/us_pc/libsm64core.a"
xcrun --sdk macosx clang \
  -std=c11 -Wall -Wextra -Werror -fsanitize=address \
  -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
  -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  -I"$ASAN_BUILD_ROOT/us_pc" \
  "$PROJECT_ROOT/tests/sm64_modern_camera_state_route_pair_contract.c" \
  "$ASAN_BUILD_ROOT/us_pc/libsm64core.a" \
  -o "$ASAN_OUTPUT" -lm -lpthread

set +e
ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
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
  printf '%s\n' 'camera_state_route_sanitizer_passed=1 debug_asan_byte_match=1'
else
  grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$ASAN_LOG"
  printf '%s\n' 'camera_state_route_sanitizer_blocked=1 finding=address-sanitizer'
fi

git -c core.fsmonitor=false diff --check
asan_match=0
if cmp -s "$C_TRACE" "$ASAN_TRACE"; then asan_match=1; fi
printf '%s\n' \
  'SM64 Modern camera-state route pair smoke passed exact_pair=1 admission_deferred=1' \
  'native_camera_records=14 ids=300..306 ticks=2,3 c_status=0' \
  'swift_camera_kernel_records=14 source_backed=1 tamper_rejected=1' \
  'camera_focus_pair=matched camera_position_pair=matched first_divergence=none' \
  'c_swift_pair=matched admission=0 ledger_mutation=0' \
  "sanitizer_status=$asan_status trace_match=$asan_match"
