#!/usr/bin/env bash
set -euo pipefail

# Phase 85am owns the first source-backed save_mutation row.  The C contract
# calls save_file_set_sound_mode through the native lifecycle and records the
# exact global-state plus SaveBuffer byte seams.  Every output is phase-local;
# this script never mutates the manifest, route ledger, or user saves.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-save-mutation-route-pair"
DEBUG_BUILD="$BUILD_ROOT/native-debug"
ASAN_BUILD="$BUILD_ROOT/native-asan"
RELEASE_BUILD="$BUILD_ROOT/native-release"
TOOL_ROOT="$BUILD_ROOT/tool"
C_OUTPUT="$TOOL_ROOT/sm64-modern-save-mutation-route-contract"
ASAN_OUTPUT="$TOOL_ROOT/sm64-modern-save-mutation-route-contract-asan"
RELEASE_OUTPUT="$TOOL_ROOT/sm64-modern-save-mutation-route-contract-release"
SWIFT_OUTPUT="$TOOL_ROOT/sm64-modern-save-mutation-route-swift"
mkdir -p "$TOOL_ROOT/module-cache"

RUN_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
DEBUG_SAVE_ROOT="$RUN_ROOT/save-debug"
ASAN_SAVE_ROOT="$RUN_ROOT/save-asan"
RELEASE_SAVE_ROOT="$RUN_ROOT/save-release"
mkdir -p "$DEBUG_SAVE_ROOT" "$ASAN_SAVE_ROOT" "$RELEASE_SAVE_ROOT"

clang_contract() {
    local output="$1"
    local archive_root="$2"
    shift 2
    xcrun --sdk macosx clang \
        -std=c11 -Wall -Wextra -Werror \
        -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
        -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
        -I"$archive_root/us_pc" \
        "$PROJECT_ROOT/tests/sm64_modern_save_mutation_route_pair_contract.c" \
        "$archive_root/us_pc/libsm64core.a" \
        -o "$output" -lm -lpthread "$@"
}

make -C "$PROJECT_ROOT" \
    SM64_MODERN_NATIVE=1 DEBUG=1 BUILD_DIR_BASE="$DEBUG_BUILD" native-core >/dev/null
test -f "$DEBUG_BUILD/us_pc/libsm64core.a"
clang_contract "$C_OUTPUT" "$DEBUG_BUILD"

C_TRACE="$RUN_ROOT/save-mutation-c.trace"
C_SIDECAR="$RUN_ROOT/save-mutation-c.sidecar"
C_SNAPSHOTS="$RUN_ROOT/save-mutation-c.snapshots"
DEBUG_LOG="$RUN_ROOT/debug.log"
"$C_OUTPUT" "$C_TRACE" "$C_SIDECAR" "$C_SNAPSHOTS" "$DEBUG_SAVE_ROOT" \
    >"$DEBUG_LOG" 2>&1
grep -Fq 'save_mutation_route_init status=0 oracle=0 parity=0' "$DEBUG_LOG"
grep -Fq 'save_mutation_route_step index=0 status=0 oracle=0 parity=0' "$DEBUG_LOG"
grep -Fq 'save_mutation_route_step index=1 status=0 oracle=0 parity=0' "$DEBUG_LOG"
grep -Eq 'save_mutation_route_debug oracle_end=0 result_status=0 actual=[1-9][0-9]* save_records=4 global_records=12 snapshots=2 failures=0' "$DEBUG_LOG"
grep -Fq 'c_save_mutation_route_recorded shard=0x022fbda0ff7f2dd1 save_records=4 global_records=12 snapshots=2 ticks=2,3 sound_mode=0x4321' "$DEBUG_LOG"
test "$(wc -c <"$C_TRACE" | tr -d '[:space:]')" -eq $((72 + 16 * 128))
test "$(wc -l <"$C_SIDECAR" | tr -d '[:space:]')" -eq 4
test "$(wc -c <"$C_SNAPSHOTS" | tr -d '[:space:]')" -eq 96

xcrun swiftc \
    -parse-as-library -swift-version 6 \
    -Xfrontend -strict-concurrency=complete \
    -import-objc-header "$PROJECT_ROOT/SM64Modern/SM64Modern-Bridging-Header.h" \
    -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
    -module-cache-path "$TOOL_ROOT/module-cache" \
    "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
    "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
    "$PROJECT_ROOT/SM64Modern/GlobalStateMigration.swift" \
    "$PROJECT_ROOT/SM64Modern/ProgressionState.swift" \
    "$PROJECT_ROOT/SM64Modern/CoinScoreAges.swift" \
    "$PROJECT_ROOT/SM64Modern/SaveFileCodec.swift" \
    "$PROJECT_ROOT/SM64Modern/SaveFileMutator.swift" \
    "$PROJECT_ROOT/SM64Modern/ProgressionPersistence.swift" \
    "$PROJECT_ROOT/tests/sm64_modern_save_mutation_route_swift_smoke.swift" \
    -o "$SWIFT_OUTPUT"

SWIFT_TRACE="$RUN_ROOT/save-mutation-swift.trace"
TAMPERED_TRACE="$RUN_ROOT/save-mutation-swift.tampered.trace"
SWIFT_LOG="$RUN_ROOT/swift.log"
{
    "$SWIFT_OUTPUT" write "$C_TRACE" "$C_SIDECAR" "$C_SNAPSHOTS" "$SWIFT_TRACE"
    "$SWIFT_OUTPUT" audit "$C_TRACE" "$SWIFT_TRACE"
    "$SWIFT_OUTPUT" tamper "$SWIFT_TRACE" "$TAMPERED_TRACE"
} | tee "$SWIFT_LOG"
grep -Fq 'swift_save_mutation_route_recorded shard=0x22fbda0ff7f2dd1 save_records=4 global_records=12 snapshots=2 sound_mode=0x4321' "$SWIFT_LOG"
grep -Fq 'save_mutation_pairing_audit admitted=1 c_records=16 swift_records=16 blockers= first_divergence=none' "$SWIFT_LOG"
grep -Fq 'save_mutation_pairing_tamper_rejected=1' "$SWIFT_LOG"

make -C "$PROJECT_ROOT" \
    SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
    BUILD_DIR_BASE="$ASAN_BUILD" native-core >/dev/null
test -f "$ASAN_BUILD/us_pc/libsm64core.a"
clang_contract "$ASAN_OUTPUT" "$ASAN_BUILD" -fsanitize=address
ASAN_TRACE="$RUN_ROOT/save-mutation-c-asan.trace"
ASAN_SIDECAR="$RUN_ROOT/save-mutation-c-asan.sidecar"
ASAN_SNAPSHOTS="$RUN_ROOT/save-mutation-c-asan.snapshots"
ASAN_LOG="$RUN_ROOT/asan.log"
ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
    "$ASAN_OUTPUT" "$ASAN_TRACE" "$ASAN_SIDECAR" "$ASAN_SNAPSHOTS" "$ASAN_SAVE_ROOT" \
    >"$ASAN_LOG" 2>&1
if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$ASAN_LOG"; then
    echo 'AddressSanitizer emitted a finding despite a zero process status' >&2
    exit 1
fi
cmp -s "$C_TRACE" "$ASAN_TRACE"
cmp -s "$C_SIDECAR" "$ASAN_SIDECAR"
cmp -s "$C_SNAPSHOTS" "$ASAN_SNAPSHOTS"
printf '%s\n' 'save_mutation_route_sanitizer_passed=1 debug_asan_trace_match=1 sidecar_match=1 snapshots_match=1'

make -C "$PROJECT_ROOT" \
    SM64_MODERN_NATIVE=1 DEBUG=0 BUILD_DIR_BASE="$RELEASE_BUILD" native-core >/dev/null
test -f "$RELEASE_BUILD/us_pc/libsm64core.a"
clang_contract "$RELEASE_OUTPUT" "$RELEASE_BUILD"
RELEASE_TRACE="$RUN_ROOT/save-mutation-c-release.trace"
RELEASE_SIDECAR="$RUN_ROOT/save-mutation-c-release.sidecar"
RELEASE_SNAPSHOTS="$RUN_ROOT/save-mutation-c-release.snapshots"
RELEASE_LOG="$RUN_ROOT/release.log"
"$RELEASE_OUTPUT" "$RELEASE_TRACE" "$RELEASE_SIDECAR" "$RELEASE_SNAPSHOTS" "$RELEASE_SAVE_ROOT" \
    >"$RELEASE_LOG" 2>&1
grep -Eq 'save_mutation_route_debug oracle_end=0 result_status=0 actual=[1-9][0-9]* save_records=4 global_records=12 snapshots=2 failures=0' "$RELEASE_LOG"
cmp -s "$C_TRACE" "$RELEASE_TRACE"
cmp -s "$C_SIDECAR" "$RELEASE_SIDECAR"
cmp -s "$C_SNAPSHOTS" "$RELEASE_SNAPSHOTS"
printf '%s\n' 'save_mutation_route_release_passed=1 debug_release_trace_match=1 sidecar_match=1 snapshots_match=1'

git -c core.fsmonitor=false diff --check
printf '%s\n' \
    'SM64 Modern save-mutation route pair smoke passed exact_pair=1 tamper_rejected=1' \
    'route_shard=0x022fbda0ff7f2dd1 source=src/game/save_file.c identity=save_file_set_sound_mode' \
    'expected_domains=global_state,save_bytes save_records=4 global_records=12 ticks=2,3' \
    'c_swift_pair=matched first_divergence=none c_asan_release=matched' \
    'native_persistence=menu_write_load_reload isolated_save_root=1' \
    'admission=0 ledger_mutation=0 fixture_only=0'
