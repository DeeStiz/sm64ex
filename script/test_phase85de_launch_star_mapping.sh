#!/usr/bin/env bash
set -euo pipefail

# Phase 85de is a disjoint full-trace rerun for Castle Inside area-1 subject
# 35, the authored -135-degree bhvLaunchStarCollectWarp. All build, trace,
# PCM, receipt, projection, and negative-fence artifacts remain phase-local.
# This harness must not mutate canonical manifests, ledgers, reports,
# admission tools, or shared documentation.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="${SM64_PHASE85DE_BUILD_ROOT:-$PROJECT_ROOT/build/sm64-modern-phase85de-launch-star-mapping}"
DEBUG_ROOT="$BUILD_ROOT/native-debug"
ASAN_ROOT="$BUILD_ROOT/native-asan"
RELEASE_ROOT="$BUILD_ROOT/native-release"
TOOL_ROOT="$BUILD_ROOT/tool"
mkdir -p "$TOOL_ROOT/module-cache"

C_OUTPUT="$TOOL_ROOT/audio-full-probe"
ASAN_OUTPUT="$TOOL_ROOT/audio-full-probe-asan"
RELEASE_OUTPUT="$TOOL_ROOT/audio-full-probe-release"
SWIFT_OUTPUT="$TOOL_ROOT/launch-star-mapping-swift"
C_TRACE="$BUILD_ROOT/audio-full-c.trace"
ASAN_TRACE="$BUILD_ROOT/audio-full-c-asan.trace"
RELEASE_TRACE="$BUILD_ROOT/audio-full-c-release.trace"
RERUN_TRACE="$BUILD_ROOT/audio-full-c-rerun.trace"
SWIFT_TRACE="$BUILD_ROOT/audio-full-swift.trace"
C_PCM="$BUILD_ROOT/audio-full-c.pcm.trace"
ASAN_PCM="$BUILD_ROOT/audio-full-c-asan.pcm.trace"
RELEASE_PCM="$BUILD_ROOT/audio-full-c-release.pcm.trace"
RERUN_PCM="$BUILD_ROOT/audio-full-c-rerun.pcm.trace"
C_RECEIPTS="$BUILD_ROOT/audio-full-c.receipts"
ASAN_RECEIPTS="$BUILD_ROOT/audio-full-c-asan.receipts"
RELEASE_RECEIPTS="$BUILD_ROOT/audio-full-c-release.receipts"
RERUN_RECEIPTS="$BUILD_ROOT/audio-full-c-rerun.receipts"
TAMPER_TRACE="$BUILD_ROOT/audio-full-tampered.trace"
PARTIAL_TRACE="$BUILD_ROOT/audio-full-partial.trace"
FIXTURE_MARKER="$BUILD_ROOT/audio-full.fixture_only"

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

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 \
    BUILD_DIR_BASE="$DEBUG_ROOT" native-core >/dev/null
clang_probe "$C_OUTPUT" "$DEBUG_ROOT"
DEBUG_SAVE="$(mktemp -d "$BUILD_ROOT/save-debug.XXXXXX")"
SM64_MODERN_AUTOMATED_CASTLE_AREA2=1 "$C_OUTPUT" "$C_TRACE" "$DEBUG_SAVE" \
    "$C_PCM" "$C_RECEIPTS" >/dev/null

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=1 SANITIZE=address \
    BUILD_DIR_BASE="$ASAN_ROOT" native-core >/dev/null
clang_probe "$ASAN_OUTPUT" "$ASAN_ROOT" -fsanitize=address
ASAN_SAVE="$(mktemp -d "$BUILD_ROOT/save-asan.XXXXXX")"
ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 SM64_MODERN_AUTOMATED_CASTLE_AREA2=1 \
    "$ASAN_OUTPUT" "$ASAN_TRACE" "$ASAN_SAVE" "$ASAN_PCM" "$ASAN_RECEIPTS" >/dev/null

make -C "$PROJECT_ROOT" SM64_MODERN_NATIVE=1 DEBUG=0 \
    BUILD_DIR_BASE="$RELEASE_ROOT" native-core >/dev/null
clang_probe "$RELEASE_OUTPUT" "$RELEASE_ROOT"
RELEASE_SAVE="$(mktemp -d "$BUILD_ROOT/save-release.XXXXXX")"
SM64_MODERN_AUTOMATED_CASTLE_AREA2=1 "$RELEASE_OUTPUT" "$RELEASE_TRACE" \
    "$RELEASE_SAVE" "$RELEASE_PCM" "$RELEASE_RECEIPTS" >/dev/null

RERUN_SAVE="$(mktemp -d "$BUILD_ROOT/save-rerun.XXXXXX")"
SM64_MODERN_AUTOMATED_CASTLE_AREA2=1 "$C_OUTPUT" "$RERUN_TRACE" "$RERUN_SAVE" \
    "$RERUN_PCM" "$RERUN_RECEIPTS" >/dev/null

xcrun swiftc -parse-as-library -swift-version 6 -Xfrontend -strict-concurrency=complete \
    -module-cache-path "$TOOL_ROOT/module-cache" \
    "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
    "$PROJECT_ROOT/tests/sm64_modern_phase85de_launch_star_mapping.swift" \
    -o "$SWIFT_OUTPUT"

"$SWIFT_OUTPUT" write "$C_TRACE" "$SWIFT_TRACE"
"$SWIFT_OUTPUT" tamper "$C_TRACE" "$TAMPER_TRACE"
"$SWIFT_OUTPUT" partial "$C_TRACE" "$PARTIAL_TRACE"
if "$SWIFT_OUTPUT" fixture "$C_TRACE" "$FIXTURE_MARKER"; then
    echo 'phase85de fixture-only fence unexpectedly accepted' >&2
    exit 1
fi
if "$SWIFT_OUTPUT" single "$C_TRACE" "$C_TRACE"; then
    echo 'phase85de single-artifact fence unexpectedly accepted' >&2
    exit 1
fi

cmp -s "$C_TRACE" "$SWIFT_TRACE"
cmp -s "$C_PCM" "$ASAN_PCM"
cmp -s "$C_PCM" "$RELEASE_PCM"
cmp -s "$C_PCM" "$RERUN_PCM"
cmp -s "$C_RECEIPTS" "$ASAN_RECEIPTS"
cmp -s "$C_RECEIPTS" "$RELEASE_RECEIPTS"
cmp -s "$C_RECEIPTS" "$RERUN_RECEIPTS"
test ! -e "$FIXTURE_MARKER"

audit_status=0
if "$SWIFT_OUTPUT" audit "$C_TRACE" "$SWIFT_TRACE" "$ASAN_TRACE" \
    "$RELEASE_TRACE" "$RERUN_TRACE"; then
    audit_status=0
else
    audit_status=$?
    echo 'phase85de fail-closed: next full-trace mismatch remains unmapped' >&2
fi

git -c core.fsmonitor=false diff --check -- \
    src/pc/sm64_modern_gameplay_parity.c \
    script/test_phase85de_launch_star_mapping.sh \
    tests/sm64_modern_phase85de_launch_star_mapping.swift \
    .porting/porting-handoff-full-swift-twin-phase85de-launch-star-mapping.md

printf '%s\n' \
    'SM64 Modern Phase 85de launch-star mapping matrix completed' \
    'native_c_lifecycle=1 castle_area2=1 sequence12_tick=63 records=476365' \
    'subject35_source=bhvLaunchStarCollectWarp yaw=-135 semantic_identity=0x0b9ebb9260f83fe6' \
    'c_swift_byte_match=1 pcm_match=1 receipts_match=1 tamper_rejected=1 partial_rejected=1 fixture_only_rejected=1 single_artifact_rejected=1' \
    "full_trace_audit_status=$audit_status canonical_promotion=0 manifest_mutation=0 ledger_mutation=0 shared_docs_mutation=0"
exit "$audit_status"
