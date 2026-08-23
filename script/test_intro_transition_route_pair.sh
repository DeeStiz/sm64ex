#!/usr/bin/env bash
set -euo pipefail

# Phase 85f30 owns the authored intro level-script transition seam.  The
# native C producer remains authoritative; the pair retains only its existing
# schema-4 script event ID 3 and never mutates the route manifest or ledger.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_PARENT="$PROJECT_ROOT/build/sm64-modern-intro-transition-route-pair"
if [[ -n "${SM64_INTRO_TRANSITION_ROUTE_BUILD_ROOT:-}" ]]; then
    BUILD_ROOT="$SM64_INTRO_TRANSITION_ROUTE_BUILD_ROOT"
    mkdir -p "$BUILD_ROOT"
else
    mkdir -p "$BUILD_PARENT"
    BUILD_ROOT="$(mktemp -d "$BUILD_PARENT/run.XXXXXX")"
fi

DEBUG_BUILD="$BUILD_ROOT/native-debug"
ASAN_BUILD="$BUILD_ROOT/native-asan"
RELEASE_BUILD="$BUILD_ROOT/native-release"
TOOL_ROOT="$BUILD_ROOT/tool"
MODULE_CACHE="$TOOL_ROOT/module-cache"
SAVE_DEBUG="$BUILD_ROOT/save-debug"
SAVE_ASAN="$BUILD_ROOT/save-asan"
SAVE_RELEASE="$BUILD_ROOT/save-release"
SAVE_RERUN="$BUILD_ROOT/save-rerun"
C_TRACE="$BUILD_ROOT/intro-transition-c.trace"
RERUN_TRACE="$BUILD_ROOT/intro-transition-c-rerun.trace"
ASAN_TRACE="$BUILD_ROOT/intro-transition-c-asan.trace"
RELEASE_TRACE="$BUILD_ROOT/intro-transition-c-release.trace"
SWIFT_TRACE="$BUILD_ROOT/intro-transition-swift.trace"
TAMPERED_TRACE="$BUILD_ROOT/intro-transition-swift.tampered.trace"
REORDERED_TRACE="$BUILD_ROOT/intro-transition-swift.reordered.trace"
MISSING_TRACE="$BUILD_ROOT/intro-transition-swift.missing.trace"
PARTIAL_TRACE="$BUILD_ROOT/intro-transition-swift.partial.trace"
DEBUG_LOG="$BUILD_ROOT/debug.log"
RERUN_LOG="$BUILD_ROOT/rerun.log"
ASAN_LOG="$BUILD_ROOT/asan.log"
RELEASE_LOG="$BUILD_ROOT/release.log"
SWIFT_LOG="$BUILD_ROOT/swift.log"

mkdir -p "$TOOL_ROOT" "$MODULE_CACHE" "$SAVE_DEBUG" "$SAVE_ASAN" \
    "$SAVE_RELEASE" "$SAVE_RERUN"

clang_contract() {
    local output="$1"
    local archive_root="$2"
    shift 2
    xcrun --sdk macosx clang \
        -std=c11 -Wall -Wextra -Werror \
        -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
        -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
        -I"$archive_root/us_pc" \
        "$PROJECT_ROOT/tests/sm64_modern_intro_transition_route_pair_contract.c" \
        "$archive_root/us_pc/libsm64core.a" \
        -o "$output" -lm -lpthread "$@"
}

expect_failure() {
    local label="$1"
    shift
    if "$@" >"$BUILD_ROOT/$label.log" 2>&1; then
        echo "intro-transition negative fence accepted: $label" >&2
        cat "$BUILD_ROOT/$label.log" >&2
        exit 1
    fi
    printf '%s\n' "intro_transition_${label}_rejected=1"
}

make -C "$PROJECT_ROOT" \
    SM64_MODERN_NATIVE=1 DEBUG=1 \
    BUILD_DIR_BASE="$DEBUG_BUILD" native-core >/dev/null
test -f "$DEBUG_BUILD/us_pc/libsm64core.a"

C_OUTPUT="$TOOL_ROOT/intro-transition-route-contract"
clang_contract "$C_OUTPUT" "$DEBUG_BUILD"
"$C_OUTPUT" "$C_TRACE" "$SAVE_DEBUG" >"$DEBUG_LOG" 2>&1
grep -Fq \
    'intro_transition_route_recorded shard=0x9a0f7b4f7ecf6c41 source=levels/intro/script.c entry=level_intro_entry_1 steps=320 records=2 ticks=311,391 hashes=0xb9e77a797c34bb9e,0x0eb91077dbe72aa4 coverage=0x8fc5fa3c2cd26867 owner_thread=1' \
    "$DEBUG_LOG"
grep -Fq \
    'intro_transition_route_debug oracle_end=0 result_status=0 actual=' \
    "$DEBUG_LOG"
grep -Fq \
    'target_ticks=311,391 target_hashes=0xb9e77a797c34bb9e,0x0eb91077dbe72aa4 failures=0 errors=0 coverage=0x8fc5fa3c2cd26867' \
    "$DEBUG_LOG"
grep -Fq 'intro_transition_route_reachability passed transition_records=2' "$DEBUG_LOG"
test "$(wc -c <"$C_TRACE" | tr -d '[:space:]')" -eq $((72 + 2 * 128))

# A separate owner-process rerun must reproduce the same native bytes before
# the Swift mirror is considered independent evidence.
"$C_OUTPUT" "$RERUN_TRACE" "$SAVE_RERUN" >"$RERUN_LOG" 2>&1
grep -Fq 'target_ticks=311,391 target_hashes=0xb9e77a797c34bb9e,0x0eb91077dbe72aa4' "$RERUN_LOG"
cmp -s "$C_TRACE" "$RERUN_TRACE"
printf '%s\n' 'intro_transition_debug_rerun_match=1'

xcrun swiftc \
    -parse-as-library -swift-version 6 \
    -Xfrontend -strict-concurrency=complete \
    -module-cache-path "$MODULE_CACHE" \
    "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
    "$PROJECT_ROOT/SM64Modern/IntroTransitionMigration.swift" \
    "$PROJECT_ROOT/tests/sm64_modern_intro_transition_route_swift_smoke.swift" \
    -o "$TOOL_ROOT/intro-transition-route-swift"

SWIFT_OUTPUT="$TOOL_ROOT/intro-transition-route-swift"
{
    "$SWIFT_OUTPUT" write "$C_TRACE" "$SWIFT_TRACE"
    "$SWIFT_OUTPUT" audit "$C_TRACE" "$SWIFT_TRACE"
    "$SWIFT_OUTPUT" tamper "$SWIFT_TRACE" "$TAMPERED_TRACE"
    "$SWIFT_OUTPUT" reorder "$C_TRACE" "$REORDERED_TRACE"
} | tee "$SWIFT_LOG"
grep -Fq \
    'swift_intro_transition_route_recorded shard=0x9a0f7b4f7ecf6c41 records=2 ticks=311,391 hashes=0xb9e77a797c34bb9e,0x0eb91077dbe72aa4' \
    "$SWIFT_LOG"
grep -Fq \
    'intro_transition_pairing_audit admitted=1 c_records=2 swift_records=2 ticks=311,391 hashes=0xb9e77a797c34bb9e,0x0eb91077dbe72aa4 blockers= first_divergence=none' \
    "$SWIFT_LOG"
grep -Fq 'intro_transition_pairing_tamper_rejected=1' "$SWIFT_LOG"
expect_failure reordered_trace "$SWIFT_OUTPUT" audit "$C_TRACE" "$REORDERED_TRACE"

"$SWIFT_OUTPUT" missing "$C_TRACE" "$MISSING_TRACE"
expect_failure missing_trace "$SWIFT_OUTPUT" audit "$C_TRACE" "$MISSING_TRACE"

"$SWIFT_OUTPUT" partial "$C_TRACE" "$PARTIAL_TRACE"
expect_failure partial_trace "$SWIFT_OUTPUT" audit "$C_TRACE" "$PARTIAL_TRACE"

expect_failure single_artifact "$SWIFT_OUTPUT" audit "$C_TRACE" "$C_TRACE"
expect_failure persistent_rerun "$SWIFT_OUTPUT" write "$C_TRACE" "$SWIFT_TRACE"
cmp -s "$C_TRACE" "$SWIFT_TRACE"
printf '%s\n' 'intro_transition_swift_pair_bytes_match=1'

make -C "$PROJECT_ROOT" \
    SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
    BUILD_DIR_BASE="$ASAN_BUILD" native-core >/dev/null
test -f "$ASAN_BUILD/us_pc/libsm64core.a"
ASAN_OUTPUT="$TOOL_ROOT/intro-transition-route-contract-asan"
clang_contract "$ASAN_OUTPUT" "$ASAN_BUILD" -fsanitize=address
ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
    "$ASAN_OUTPUT" "$ASAN_TRACE" "$SAVE_ASAN" >"$ASAN_LOG" 2>&1
if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$ASAN_LOG"; then
    echo 'AddressSanitizer emitted a finding despite a zero process status' >&2
    exit 1
fi
grep -Fq 'target_ticks=311,391 target_hashes=0xb9e77a797c34bb9e,0x0eb91077dbe72aa4 failures=0 errors=0 coverage=0x8fc5fa3c2cd26867' "$ASAN_LOG"
cmp -s "$C_TRACE" "$ASAN_TRACE"
printf '%s\n' 'intro_transition_asan_passed=1 debug_asan_trace_match=1'

make -C "$PROJECT_ROOT" \
    SM64_MODERN_NATIVE=1 DEBUG=0 \
    BUILD_DIR_BASE="$RELEASE_BUILD" native-core >/dev/null
test -f "$RELEASE_BUILD/us_pc/libsm64core.a"
RELEASE_OUTPUT="$TOOL_ROOT/intro-transition-route-contract-release"
clang_contract "$RELEASE_OUTPUT" "$RELEASE_BUILD"
"$RELEASE_OUTPUT" "$RELEASE_TRACE" "$SAVE_RELEASE" >"$RELEASE_LOG" 2>&1
grep -Fq 'target_ticks=311,391 target_hashes=0xb9e77a797c34bb9e,0x0eb91077dbe72aa4 failures=0 errors=0 coverage=0x8fc5fa3c2cd26867' "$RELEASE_LOG"
cmp -s "$C_TRACE" "$RELEASE_TRACE"
printf '%s\n' 'intro_transition_release_passed=1 debug_release_trace_match=1'

git -c core.fsmonitor=false diff --check
printf '%s\n' \
    'SM64 Modern authored intro transition route pair smoke passed exact_pair=1' \
    'route_shard=0x9a0f7b4f7ecf6c41 source=levels/intro/script.c entry=level_intro_entry_1 steps=320' \
    'native_transition_records=2 ticks=311,391 hashes=0xb9e77a797c34bb9e,0x0eb91077dbe72aa4' \
    'c_swift_asan_release_rerun_byte_match=1 owner_thread=1' \
    'tamper_rejected=1 reordered_trace_rejected=1 missing_trace_rejected=1 partial_trace_rejected=1 single_artifact_rejected=1 persistent_rerun_rejected=1' \
    'source_backed=1 direct_transition_call=0 synthesized_records=0 fixture_only=0 manifest_mutation=0 ledger_mutation=0'
