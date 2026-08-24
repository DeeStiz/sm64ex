#!/usr/bin/env bash
set -euo pipefail

# Phase 85am owns one generated level_script route only. C executes the
# authored CotMC lifecycle; Swift receives copied schema-4 receipts. The
# transition domain stays fail-closed when the bounded authored window does
# not publish a transition command. This script never mutates the manifest or
# the canonical route ledger.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-level-script-route-pair.XXXXXX")"
DEBUG_BUILD="$PROJECT_ROOT/build/sm64-modern-level-script-route-pair/native-debug"
ASAN_BUILD="$PROJECT_ROOT/build/sm64-modern-level-script-route-pair/native-asan"
RELEASE_BUILD="$PROJECT_ROOT/build/sm64-modern-level-script-route-pair/native-release"
DEBUG_NATIVE="$DEBUG_BUILD/us_pc"
ASAN_NATIVE="$ASAN_BUILD/us_pc"
RELEASE_NATIVE="$RELEASE_BUILD/us_pc"
C_OUTPUT="$RUN_ROOT/level-script-route-contract"
ASAN_OUTPUT="$RUN_ROOT/level-script-route-contract-asan"
SWIFT_OUTPUT="$RUN_ROOT/level-script-route-swift"
mkdir -p "$RUN_ROOT/save" "$RUN_ROOT/save-asan" "$RUN_ROOT/save-release" \
  "$RUN_ROOT/module-cache"

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=1 \
  BUILD_DIR_BASE="$DEBUG_BUILD" native-core >/dev/null
test -f "$DEBUG_NATIVE/libsm64core.a"

clang_contract() {
  local output="$1"
  local native="$2"
  shift 2
  xcrun --sdk macosx clang \
    -std=c11 -Wall -Wextra -Werror \
    -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
    -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
    -I"$native" "$PROJECT_ROOT/tests/sm64_modern_level_script_route_pair_contract.c" \
    "$native/libsm64core.a" -o "$output" -lm -lpthread "$@"
}

clang_contract "$C_OUTPUT" "$DEBUG_NATIVE"
"$C_OUTPUT" "$RUN_ROOT/c.trace" "$RUN_ROOT/save" >"$RUN_ROOT/debug.log" 2>&1
grep -Fq 'level_script_route_init status=0 oracle=0 parity=0' "$RUN_ROOT/debug.log"
grep -Fq 'level_script_route_step index=0 status=0 oracle=0 parity=0' "$RUN_ROOT/debug.log"
grep -Fq 'level_script_route_step index=1 status=0 oracle=0 parity=0' "$RUN_ROOT/debug.log"
grep -Fq 'level_script_route_debug oracle_end=0 result_status=0 actual=742 selected=505 snapshots=2 global=12 script=493 transition=0 failures=0' "$RUN_ROOT/debug.log"
grep -Fq 'c_level_script_route_recorded shard=0x11ea903bbb7d15d1' "$RUN_ROOT/debug.log"
grep -Fq 'ticks=2,3 coverage=0x1e21d238ed3086ec' "$RUN_ROOT/debug.log"
test -s "$RUN_ROOT/c.trace"
test -s "$RUN_ROOT/c.trace.snapshots"
test "$(wc -c <"$RUN_ROOT/c.trace" | tr -d '[:space:]')" -eq $((72 + 505 * 128))

xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$RUN_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/LevelScriptRouteMigration.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_level_script_route_swift_smoke.swift" \
  -o "$SWIFT_OUTPUT"
"$SWIFT_OUTPUT" write "$RUN_ROOT/c.trace" "$RUN_ROOT/swift.trace" \
  | tee "$RUN_ROOT/swift.log"
"$SWIFT_OUTPUT" audit "$RUN_ROOT/c.trace" "$RUN_ROOT/swift.trace" \
  | tee -a "$RUN_ROOT/swift.log"
"$SWIFT_OUTPUT" tamper "$RUN_ROOT/swift.trace" "$RUN_ROOT/swift.tampered.trace" \
  | tee -a "$RUN_ROOT/swift.log"
grep -Fq 'swift_level_script_route_recorded records=505 global=12 script=493 transition=0 ticks=2,3 coverage=0x1e21d238ed3086ec' "$RUN_ROOT/swift.log"
grep -Fq 'level_script_pairing_audit admitted=1 c_records=505 swift_records=505 blockers= first_divergence=none' "$RUN_ROOT/swift.log"
grep -Fq 'level_script_pairing_tamper_rejected=1' "$RUN_ROOT/swift.log"
test "$(wc -c <"$RUN_ROOT/swift.trace" | tr -d '[:space:]')" -eq $((72 + 505 * 128))

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
  BUILD_DIR_BASE="$ASAN_BUILD" native-core >/dev/null
test -f "$ASAN_NATIVE/libsm64core.a"
clang_contract "$ASAN_OUTPUT" "$ASAN_NATIVE" -fsanitize=address
ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
  "$ASAN_OUTPUT" "$RUN_ROOT/asan.trace" "$RUN_ROOT/save-asan" >"$RUN_ROOT/asan.log" 2>&1
if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$RUN_ROOT/asan.log"; then
  echo 'AddressSanitizer emitted a finding despite a zero process status' >&2
  exit 1
fi
cmp -s "$RUN_ROOT/c.trace" "$RUN_ROOT/asan.trace"
printf '%s\n' 'level_script_route_sanitizer_passed=1 debug_asan_trace_match=1'

make -C "$PROJECT_ROOT" \
  SM64_MODERN_NATIVE=1 DEBUG=0 \
  BUILD_DIR_BASE="$RELEASE_BUILD" native-core >/dev/null
test -f "$RELEASE_NATIVE/libsm64core.a"
clang_contract "$RUN_ROOT/level-script-route-contract-release" "$RELEASE_NATIVE"
"$RUN_ROOT/level-script-route-contract-release" "$RUN_ROOT/release.trace" \
  "$RUN_ROOT/save-release" >"$RUN_ROOT/release.log" 2>&1
grep -Fq 'level_script_route_debug oracle_end=0 result_status=0' "$RUN_ROOT/release.log"
cmp -s "$RUN_ROOT/c.trace" "$RUN_ROOT/release.trace"
printf '%s\n' 'level_script_route_optimized_passed=1 debug_release_trace_match=1'

grep -Fq 'SM64_MODERN_AUTOMATED_COTMC_LEVEL_SCRIPT' "$PROJECT_ROOT/src/game/game_init.c"
git -c core.fsmonitor=false diff --check
printf '%s\n' \
  'SM64 Modern CotMC level-script route pair smoke passed exact_pair=1' \
  'shard=0x11ea903bbb7d15d1 source=levels/cotmc/script.c input_seed=0x65ecbad1fe05f115 save_seed=0x530b598d222bfea2' \
  'native_schema=4 ticks=2,3 records=505 global_state=12 script_events=493 transition=0' \
  'c_swift_pair=matched first_divergence=none tamper_rejected=1' \
  'debug_asan_release_byte_match=1 fixture_only=0 ledger_mutation=0' \
  'qualification_blocked=1 reason=bounded_authored_cotmc_window_published_no_transition_record'
