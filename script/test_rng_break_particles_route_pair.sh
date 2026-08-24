#!/usr/bin/env bash
set -euo pipefail

# Phase 85bg owns only the source-bound JRB break-particle RNG shard.  The
# native C lifecycle remains authoritative; Swift writes a fresh schema-4
# mirror after independently checking source identity, call-site flags, tick,
# value/seed equality, and the authored random-call cadence.  No manifest,
# cumulative ledger, or shared documentation is written here.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-rng-break-particles-route-pair"
PAIR_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
DEBUG_BUILD="$BUILD_ROOT/native-debug"
ASAN_BUILD="$BUILD_ROOT/native-asan"
RELEASE_BUILD="$BUILD_ROOT/native-release"
TOOL_ROOT="$PAIR_ROOT/tool"
C_OUTPUT="$TOOL_ROOT/rng-break-particles-route-contract"
ASAN_OUTPUT="$TOOL_ROOT/rng-break-particles-route-contract-asan"
RELEASE_OUTPUT="$TOOL_ROOT/rng-break-particles-route-contract-release"
SWIFT_OUTPUT="$TOOL_ROOT/rng-break-particles-route-swift"
C_TRACE="$PAIR_ROOT/rng-break-particles-c.trace"
ASAN_TRACE="$PAIR_ROOT/rng-break-particles-c-asan.trace"
RELEASE_TRACE="$PAIR_ROOT/rng-break-particles-c-release.trace"
SWIFT_TRACE="$PAIR_ROOT/rng-break-particles-swift.trace"
TAMPERED_TRACE="$PAIR_ROOT/rng-break-particles-swift.tampered.trace"
SAVE_ROOT="$PAIR_ROOT/save-debug"
ASAN_SAVE_ROOT="$PAIR_ROOT/save-asan"
RELEASE_SAVE_ROOT="$PAIR_ROOT/save-release"
DEBUG_LOG="$PAIR_ROOT/debug.log"
ASAN_LOG="$PAIR_ROOT/asan.log"
RELEASE_LOG="$PAIR_ROOT/release.log"
SWIFT_LOG="$PAIR_ROOT/swift.log"

mkdir -p "$TOOL_ROOT/module-cache" "$SAVE_ROOT" "$ASAN_SAVE_ROOT" "$RELEASE_SAVE_ROOT"

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=1 \
  BUILD_DIR_BASE="$DEBUG_BUILD" native-core >/dev/null
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
    "$PROJECT_ROOT/tests/sm64_modern_rng_break_particles_route_pair_contract.c" \
    "$archive_root/us_pc/libsm64core.a" \
    -o "$output" -lm -lpthread "$@"
}

clang_contract "$C_OUTPUT" "$DEBUG_BUILD"
"$C_OUTPUT" "$C_TRACE" "$SAVE_ROOT" >"$DEBUG_LOG" 2>&1
grep -Fq 'rng_break_particles_route_init status=0 oracle=0 parity=0' "$DEBUG_LOG"
grep -Fq 'rng_break_particles_route_debug oracle_end=0 result_status=0' "$DEBUG_LOG"
grep -Fq 'retained=40 failures=0 tick=2084' "$DEBUG_LOG"
grep -Fq 'c_rng_break_particles_route_recorded shard=0x00576356a427dbc2' "$DEBUG_LOG"
grep -Fq 'records=40 tick=2084 callsites=20,20 source=0xcb90922e394c3a9b' "$DEBUG_LOG"
grep -Fq 'fixture_only=0' "$DEBUG_LOG"
test "$(wc -c <"$C_TRACE" | tr -d '[:space:]')" -eq $((72 + 40 * 128))

xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" \
  "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" \
  "$PROJECT_ROOT/SM64Modern/RNGBreakParticlesMigration.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_rng_break_particles_route_swift_smoke.swift" \
  -o "$SWIFT_OUTPUT"
{
  "$SWIFT_OUTPUT" write "$C_TRACE" "$SWIFT_TRACE"
  "$SWIFT_OUTPUT" audit "$C_TRACE" "$SWIFT_TRACE"
  "$SWIFT_OUTPUT" tamper "$SWIFT_TRACE" "$TAMPERED_TRACE"
} | tee "$SWIFT_LOG"
grep -Fq 'swift_rng_break_particles_route_recorded records=40 tick=2084' "$SWIFT_LOG"
grep -Fq 'rng_break_particles_pairing_audit admitted=1 c_records=40 swift_records=40 blockers= first_divergence=none fixture_only=0' "$SWIFT_LOG"
grep -Fq 'rng_break_particles_pairing_tamper_rejected=1' "$SWIFT_LOG"
cmp -s "$C_TRACE" "$SWIFT_TRACE"

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
grep -Fq 'retained=40 failures=0 tick=2084' "$ASAN_LOG"
cmp -s "$C_TRACE" "$ASAN_TRACE"
printf '%s\n' 'rng_break_particles_route_sanitizer_passed=1 debug_asan_trace_match=1'

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=0 \
  BUILD_DIR_BASE="$RELEASE_BUILD" native-core >/dev/null
test -f "$RELEASE_BUILD/us_pc/libsm64core.a"
clang_contract "$RELEASE_OUTPUT" "$RELEASE_BUILD"
"$RELEASE_OUTPUT" "$RELEASE_TRACE" "$RELEASE_SAVE_ROOT" >"$RELEASE_LOG" 2>&1
grep -Fq 'rng_break_particles_route_debug oracle_end=0 result_status=0' "$RELEASE_LOG"
grep -Fq 'retained=40 failures=0 tick=2084' "$RELEASE_LOG"
cmp -s "$C_TRACE" "$RELEASE_TRACE"
printf '%s\n' 'rng_break_particles_route_optimized_passed=1 debug_release_trace_match=1'

git -c core.fsmonitor=false diff --check
printf '%s\n' \
  'SM64 Modern JRB break-particles RNG route pair smoke passed exact_pair=1 tamper_rejected=1' \
  'native_rng_domain=8 record_kind=3 source=0xcb90922e394c3a9b callsites=0xf2f930d7,0x4648c6c9' \
  'native_route_records=40 tick=2084 debug_asan_release=byte_identical' \
  'swift_rng_bridge=source_backed_value_only independent_random_replay=1' \
  'admission=0 ledger_mutation=0 manifest_mutation=0 fixture_only=0' \
  "pair_root=$PAIR_ROOT"
