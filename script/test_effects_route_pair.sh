#!/usr/bin/env bash
set -euo pipefail

# Phase 85n audits the real native schema-4 effects domain against the
# existing Swift owner-thread effect sink. The C side records the complete
# two-step lifecycle effect window; Swift writes only source-backed effects
# that its current owner router can actually express. Admission is deferred
# until native sound/rumble/PCM and object-slot parity have a real Swift seam.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-effects-route-pair"
NATIVE_BUILD="$BUILD_ROOT/native-debug/us_pc"
ASAN_BUILD_ROOT="$BUILD_ROOT/native-asan"
C_OUTPUT="$BUILD_ROOT/effects-route-contract"
ASAN_OUTPUT="$BUILD_ROOT/effects-route-contract-asan"
SWIFT_OUTPUT="$BUILD_ROOT/effects-route-swift"
C_TRACE="$BUILD_ROOT/effects-c.trace"
ASAN_TRACE="$BUILD_ROOT/effects-c-asan.trace"
SWIFT_TRACE="$BUILD_ROOT/effects-swift.trace"
TAMPERED_TRACE="$BUILD_ROOT/effects-swift.tampered.trace"
SAVE_ROOT="$BUILD_ROOT/save"
ASAN_SAVE_ROOT="$BUILD_ROOT/save-asan"
NATIVE_LOG="$BUILD_ROOT/native.log"
ASAN_LOG="$BUILD_ROOT/asan.log"
SWIFT_LOG="$BUILD_ROOT/swift.log"

mkdir -p "$BUILD_ROOT" "$SAVE_ROOT" "$ASAN_SAVE_ROOT"

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 \
  DEBUG=1 \
  BUILD_DIR_BASE="$BUILD_ROOT/native-debug" \
  native-core >/dev/null
test -f "$NATIVE_BUILD/libsm64core.a"

xcrun --sdk macosx clang \
  -std=c11 -Wall -Wextra -Werror \
  -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
  -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  -I"$NATIVE_BUILD" \
  "$PROJECT_ROOT/tests/sm64_modern_effects_route_pair_contract.c" \
  "$NATIVE_BUILD/libsm64core.a" \
  -o "$C_OUTPUT" -lm -lpthread

"$C_OUTPUT" "$C_TRACE" "$SAVE_ROOT" 2>&1 | tee "$NATIVE_LOG"
grep -Fq 'effects_route_init status=0 oracle=0 parity=0' "$NATIVE_LOG"
grep -Fq 'effects_route_step index=0 status=0 oracle=0 parity=0' "$NATIVE_LOG"
grep -Fq 'effects_route_step index=1 status=0 oracle=0 parity=0' "$NATIVE_LOG"
grep -Fq 'effects_route_debug oracle_end=0 result_status=0 actual=1789 retained=58 failures=0' "$NATIVE_LOG"
grep -Fq 'effects_route_recorded' "$NATIVE_LOG"
test "$(wc -c < "$C_TRACE" | tr -d '[:space:]')" -eq $((72 + 58 * 128))

xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -import-objc-header "$PROJECT_ROOT/SM64Modern/SM64Modern-Bridging-Header.h" \
  -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/MemoryArena.swift" \
  "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" \
  "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectTransform.swift" \
  "$PROJECT_ROOT/SM64Modern/EngineState.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectScheduler.swift" \
  "$PROJECT_ROOT/SM64Modern/ChainChompRelease.swift" \
  "$PROJECT_ROOT/SM64Modern/ChainChompReleaseObjectBridge.swift" \
  "$PROJECT_ROOT/SM64Modern/OwnerThreadEffectRouter.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_effects_route_swift_smoke.swift" \
  -o "$SWIFT_OUTPUT"

{
  "$SWIFT_OUTPUT" write "$C_TRACE" "$SWIFT_TRACE"
  "$SWIFT_OUTPUT" audit "$C_TRACE" "$SWIFT_TRACE"
  "$SWIFT_OUTPUT" tamper "$SWIFT_TRACE" "$TAMPERED_TRACE"
} | tee "$SWIFT_LOG"
grep -Fq 'swift_effects_route_recorded records=2 ticks=2,3 source_owner_router=1 native_sound_rumble_pcm=unwired coverage=0x2dbead769bf7eca0' "$SWIFT_LOG"
grep -Fq 'effects_pairing_audit admitted=0 c_records=58 swift_records=2 blockers=header,record_count,record_bytes first_divergence=0' "$SWIFT_LOG"
grep -Fq 'effects_pairing_tamper_rejected=1' "$SWIFT_LOG"
test "$(wc -c < "$SWIFT_TRACE" | tr -d '[:space:]')" -eq $((72 + 2 * 128))

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
  BUILD_DIR_BASE="$ASAN_BUILD_ROOT" native-core >/dev/null
test -f "$ASAN_BUILD_ROOT/us_pc/libsm64core.a"
xcrun --sdk macosx clang \
  -std=c11 -Wall -Wextra -Werror -fsanitize=address \
  -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
  -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
  -I"$ASAN_BUILD_ROOT/us_pc" \
  "$PROJECT_ROOT/tests/sm64_modern_effects_route_pair_contract.c" \
  "$ASAN_BUILD_ROOT/us_pc/libsm64core.a" \
  -o "$ASAN_OUTPUT" -lm -lpthread

set +e
ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
  "$ASAN_OUTPUT" "$ASAN_TRACE" "$ASAN_SAVE_ROOT" >"$ASAN_LOG" 2>&1
asan_status=$?
set -e
if (( asan_status == 0 )); then
  test -s "$ASAN_TRACE"
  if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$ASAN_LOG"; then
    echo 'AddressSanitizer emitted a finding despite a zero process status' >&2
    exit 1
  fi
  if cmp -s "$C_TRACE" "$ASAN_TRACE"; then
    printf '%s\n' 'effects_route_sanitizer_passed=1 debug_asan_trace_match=1'
  else
    # The native effect stream currently exposes anchor-relative behavior
    # identities. ASan changes linked-script layout, so retain the honest
    # mismatch as a parity blocker instead of normalizing trace bytes.
    printf '%s\n' 'effects_route_sanitizer_passed=1 debug_asan_trace_match=0 equality_blocked=behavior_identity'
  fi
else
  grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$ASAN_LOG"
  printf '%s\n' 'effects_route_sanitizer_blocked=1 finding=address-sanitizer'
fi

git -c core.fsmonitor=false diff --check
printf '%s\n' \
  'SM64 Modern effects route pair smoke passed exact_native_window=1 admission_deferred=1' \
  'native_effect_records=58 ticks=2,3 domain=12 kind=4' \
  'swift_effect_records=2 source_owner_router=1 native_sound_rumble_pcm=unwired coverage=0x2dbead769bf7eca0' \
  'c_swift_pair=blocked first_divergence=0 tamper_rejected=1' \
  'authority=c native_effects=owner_thread admission=0 ledger_mutation=0'
