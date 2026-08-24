#!/usr/bin/env bash
set -euo pipefail

# Phase 85ef proves a source-backed, route-specific audio-only oracle capture.
# The native producer suppresses unrelated domains before the stream callback,
# marks the authored audio inventory, and emits the nonzero coverage contract
# in the original trace header. No trace filtering, header rewrite, or route
# manifest mutation is performed here.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="${SM64_PHASE85EF_BUILD_ROOT:-$PROJECT_ROOT/build/sm64-modern-phase85ef-audio-coverage}"
DEBUG_ROOT="$BUILD_ROOT/native-debug"
ASAN_ROOT="$BUILD_ROOT/native-asan"
RELEASE_ROOT="$BUILD_ROOT/native-release"
TOOL_ROOT="$BUILD_ROOT/tool"
LIVE_ROOT="$BUILD_ROOT/live"
mkdir -p "$BUILD_ROOT" "$TOOL_ROOT/module-cache" "$LIVE_ROOT"

C_OUTPUT="$TOOL_ROOT/audio-coverage-probe"
ASAN_OUTPUT="$TOOL_ROOT/audio-coverage-probe-asan"
RELEASE_OUTPUT="$TOOL_ROOT/audio-coverage-probe-release"
SWIFT_OUTPUT="$TOOL_ROOT/phase85ef-audio-coverage-swift"
LIVE_EXECUTOR="$TOOL_ROOT/live-executor"
PROMOTION_TOOL="$TOOL_ROOT/promotion"
REACHABILITY_TOOL="$TOOL_ROOT/reachability"
MANIFEST_TOOL="$TOOL_ROOT/manifest"
MANIFEST="$BUILD_ROOT/route-shards.tsv"
INVENTORY="$BUILD_ROOT/reachability.tsv"
LIVE_RESULT="$BUILD_ROOT/live-result.tsv"
LIVE_FIXTURE_RESULT="$BUILD_ROOT/live-fixture-result.tsv"
PROMOTION_REPORT="$BUILD_ROOT/promotion-report.tsv"
TRACE_ROOT="$LIVE_ROOT"

# Keep reruns deterministic while limiting cleanup to this phase's own
# generated artifacts; no repository or canonical evidence is touched.
rm -f "$LIVE_RESULT" "$LIVE_FIXTURE_RESULT" "$PROMOTION_REPORT" \
    "$TRACE_ROOT/0x03345fc560c65b75.trace.fixture_only"

C_TRACE="$BUILD_ROOT/audio-coverage-c.trace"
ASAN_TRACE="$BUILD_ROOT/audio-coverage-asan.trace"
RELEASE_TRACE="$BUILD_ROOT/audio-coverage-release.trace"
RERUN_TRACE="$BUILD_ROOT/audio-coverage-rerun.trace"
C_PCM="$BUILD_ROOT/audio-coverage-c.pcm.trace"
ASAN_PCM="$BUILD_ROOT/audio-coverage-asan.pcm.trace"
RELEASE_PCM="$BUILD_ROOT/audio-coverage-release.pcm.trace"
RERUN_PCM="$BUILD_ROOT/audio-coverage-rerun.pcm.trace"
C_RECEIPTS="$BUILD_ROOT/audio-coverage-c.receipts"
ASAN_RECEIPTS="$BUILD_ROOT/audio-coverage-asan.receipts"
RELEASE_RECEIPTS="$BUILD_ROOT/audio-coverage-release.receipts"
RERUN_RECEIPTS="$BUILD_ROOT/audio-coverage-rerun.receipts"
DEBUG_LOG="$BUILD_ROOT/debug.log"
ASAN_LOG="$BUILD_ROOT/asan.log"
RELEASE_LOG="$BUILD_ROOT/release.log"
RERUN_LOG="$BUILD_ROOT/rerun.log"
SWIFT_LOG="$BUILD_ROOT/swift.log"
TAMPER_TRACE="$BUILD_ROOT/audio-coverage-tampered.trace"
PARTIAL_TRACE="$BUILD_ROOT/audio-coverage-partial.trace"

clang_probe() {
    local output="$1" native_root="$2"
    shift 2
    xcrun --sdk macosx clang -std=c11 -Wall -Wextra -Werror \
        -DNON_MATCHING=1 -DAVOID_UB=1 -mmacosx-version-min=27.0 \
        -I"$PROJECT_ROOT" -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" \
        -I"$native_root/us_pc" \
        "$PROJECT_ROOT/tests/sm64_modern_audio_asset_route_probe.c" \
        "$native_root/us_pc/libsm64core.a" -o "$output" -lm -lpthread "$@"
}

run_probe() {
    local executable="$1" trace="$2" save="$3" pcm="$4" receipts="$5" log="$6"
    SM64_MODERN_AUTOMATED_CASTLE_AREA2=1 \
    SM64_MODERN_ORACLE_AUDIO_ASSET_ONLY=1 \
        "$executable" "$trace" "$save" "$pcm" "$receipts" >"$log" 2>&1
}

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 \
    BUILD_DIR_BASE="$DEBUG_ROOT" native-core >/dev/null
clang_probe "$C_OUTPUT" "$DEBUG_ROOT"
DEBUG_SAVE="$(mktemp -d "$BUILD_ROOT/save-debug.XXXXXX")"
run_probe "$C_OUTPUT" "$C_TRACE" "$DEBUG_SAVE" "$C_PCM" "$C_RECEIPTS" "$DEBUG_LOG"
grep -Eq \
    'records=[1-9][0-9]* audio_sequence=[1-9][0-9]* audio_pcm=[1-9][0-9]* .*sequence12=1 asset_ticks=63,63 .*coverage=0x[1-9a-f][0-9a-f]* .*oracle_end=0 result_status=0 errors=0' \
    "$DEBUG_LOG"

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
    BUILD_DIR_BASE="$ASAN_ROOT" native-core >/dev/null
clang_probe "$ASAN_OUTPUT" "$ASAN_ROOT" -fsanitize=address
ASAN_SAVE="$(mktemp -d "$BUILD_ROOT/save-asan.XXXXXX")"
ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 \
    run_probe "$ASAN_OUTPUT" "$ASAN_TRACE" "$ASAN_SAVE" "$ASAN_PCM" "$ASAN_RECEIPTS" "$ASAN_LOG"
if grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$ASAN_LOG"; then
    echo 'phase85ef AddressSanitizer finding' >&2
    exit 1
fi

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=0 \
    BUILD_DIR_BASE="$RELEASE_ROOT" native-core >/dev/null
clang_probe "$RELEASE_OUTPUT" "$RELEASE_ROOT"
RELEASE_SAVE="$(mktemp -d "$BUILD_ROOT/save-release.XXXXXX")"
run_probe "$RELEASE_OUTPUT" "$RELEASE_TRACE" "$RELEASE_SAVE" "$RELEASE_PCM" "$RELEASE_RECEIPTS" "$RELEASE_LOG"
grep -Eq 'sequence12=1 .*asset_ticks=63,63 .*coverage=0x[1-9a-f]' "$RELEASE_LOG"

RERUN_SAVE="$(mktemp -d "$BUILD_ROOT/save-rerun.XXXXXX")"
run_probe "$C_OUTPUT" "$RERUN_TRACE" "$RERUN_SAVE" "$RERUN_PCM" "$RERUN_RECEIPTS" "$RERUN_LOG"

xcrun swiftc -parse-as-library -swift-version 6 \
    -Xfrontend -strict-concurrency=complete \
    -module-cache-path "$TOOL_ROOT/module-cache" \
    "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
    "$PROJECT_ROOT/tests/sm64_modern_phase85ef_audio_coverage.swift" \
    -o "$SWIFT_OUTPUT"

{
    "$SWIFT_OUTPUT" audit "$C_TRACE"
    "$SWIFT_OUTPUT" audit "$ASAN_TRACE"
    "$SWIFT_OUTPUT" audit "$RELEASE_TRACE"
    "$SWIFT_OUTPUT" audit "$RERUN_TRACE"
    "$SWIFT_OUTPUT" tamper "$C_TRACE" "$TAMPER_TRACE"
    "$SWIFT_OUTPUT" partial "$C_TRACE" "$PARTIAL_TRACE"
    if "$SWIFT_OUTPUT" single "$C_TRACE" "$C_TRACE"; then
        echo 'phase85ef single-artifact fence unexpectedly accepted' >&2
        exit 1
    fi
} | tee "$SWIFT_LOG"

cmp -s "$C_TRACE" "$ASAN_TRACE"
cmp -s "$C_TRACE" "$RELEASE_TRACE"
cmp -s "$C_TRACE" "$RERUN_TRACE"
cmp -s "$C_PCM" "$ASAN_PCM"
cmp -s "$C_PCM" "$RELEASE_PCM"
cmp -s "$C_PCM" "$RERUN_PCM"
cmp -s "$C_RECEIPTS" "$ASAN_RECEIPTS"
cmp -s "$C_RECEIPTS" "$RELEASE_RECEIPTS"
cmp -s "$C_RECEIPTS" "$RERUN_RECEIPTS"
test -s "$C_PCM" -a -s "$C_RECEIPTS"

xcrun swiftc -parse-as-library -swift-version 6 \
    -Xfrontend -strict-concurrency=complete \
    -module-cache-path "$TOOL_ROOT/module-cache" \
    "$PROJECT_ROOT/tools/SM64OracleReachabilityTool.swift" \
    -o "$REACHABILITY_TOOL"
xcrun swiftc -parse-as-library -swift-version 6 \
    -Xfrontend -strict-concurrency=complete \
    -module-cache-path "$TOOL_ROOT/module-cache" \
    "$PROJECT_ROOT/tools/SM64RouteShardManifestTool.swift" \
    -o "$MANIFEST_TOOL"
"$REACHABILITY_TOOL" --root "$PROJECT_ROOT" --output "$INVENTORY" >/dev/null
"$MANIFEST_TOOL" --inventory "$INVENTORY" --output "$MANIFEST" >/dev/null
grep -Fq \
    '0x03345fc560c65b75|audio_asset|sound/sequences/us/12_event_high_score.m64|sound/sequences/us/12_event_high_score.m64|0x014f93c6ae7e2e59|0x2a3582ec48614066|audio_pcm,audio_sequence|planned|' \
    "$MANIFEST"

cp "$C_TRACE" "$TRACE_ROOT/0x03345fc560c65b75.trace"
xcrun swiftc -parse-as-library -swift-version 6 \
    -Xfrontend -strict-concurrency=complete \
    -module-cache-path "$TOOL_ROOT/module-cache" \
    "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
    "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
    "$PROJECT_ROOT/tools/SM64RouteShardLiveExecutorTool.swift" \
    -o "$LIVE_EXECUTOR"
"$LIVE_EXECUTOR" --manifest "$MANIFEST" --trace-root "$TRACE_ROOT" \
    --shard-id 0x03345fc560c65b75 --output "$LIVE_RESULT" \
    | tee "$BUILD_ROOT/live.log"
grep -Fq 'selected_rows=1' "$BUILD_ROOT/live.log"
grep -Fq '|running|passed|' "$LIVE_RESULT"

touch "$TRACE_ROOT/0x03345fc560c65b75.trace.fixture_only"
if "$LIVE_EXECUTOR" --manifest "$MANIFEST" --trace-root "$TRACE_ROOT" \
    --shard-id 0x03345fc560c65b75 --output "$LIVE_FIXTURE_RESULT" \
    >"$BUILD_ROOT/live-fixture.log" 2>&1; then
    echo 'phase85ef fixture-only live evidence unexpectedly accepted' >&2
    exit 1
fi
grep -Fq 'fixture-only evidence is not allowed' "$BUILD_ROOT/live-fixture.log"
rm -f "$TRACE_ROOT/0x03345fc560c65b75.trace.fixture_only"

xcrun swiftc -parse-as-library -swift-version 6 \
    -Xfrontend -strict-concurrency=complete \
    -module-cache-path "$TOOL_ROOT/module-cache" \
    "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
    "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
    "$PROJECT_ROOT/tools/SM64RouteShardPromotionTool.swift" \
    -o "$PROMOTION_TOOL"
"$PROMOTION_TOOL" --manifest "$MANIFEST" --shard-id 0x03345fc560c65b75 \
    --trace "$C_TRACE" --report "$PROMOTION_REPORT" \
    | tee "$BUILD_ROOT/promotion.log"
grep -Fq 'records=' "$BUILD_ROOT/promotion.log"
if "$PROMOTION_TOOL" --manifest "$MANIFEST" --shard-id 0x03345fc560c65b75 \
    --trace "$C_TRACE" --report "$PROMOTION_REPORT" \
    >"$BUILD_ROOT/promotion-rerun.log" 2>&1; then
    echo 'phase85ef terminal promotion rerun unexpectedly accepted' >&2
    exit 1
fi
grep -Fq 'invalid route-shard transition' "$BUILD_ROOT/promotion-rerun.log"

git -c core.fsmonitor=false diff --check -- \
    src/pc/sm64_modern_oracle_trace.c \
    tests/sm64_modern_audio_asset_route_probe.c \
    tests/sm64_modern_phase85ef_audio_coverage.swift \
    script/test_phase85ef_audio_coverage_source_repair.sh
printf '%s\n' \
    'SM64 Modern Phase 85ef source-backed audio-only coverage repair passed' \
    'native_c_lifecycle=1 audio_only_owner_filter=1 nonzero_coverage_header=1' \
    'sequence12_tick=63 audio_inventory=1,2,3,5 pcm_receipts=1' \
    'c_swift_asan_release_rerun_byte_match=1 pcm_receipts_cross_build_match=1' \
    'tamper_rejected=1 partial_rejected=1 single_artifact_rejected=1 fixture_only_rejected=1' \
    'live_executor=1 promotion=1 terminal_rerun_rejected=1 fixture_only=0' \
    'canonical_promotion=0 manifest_mutation=0 ledger_mutation=0 shared_docs_mutation=0'
