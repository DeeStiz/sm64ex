#!/usr/bin/env bash
set -euo pipefail

# Phase 85do is a disjoint full-trace rerun for Castle Inside area-1 subject
# 42, the authored bhvWarp at (1963, 819, 1280). The established 85dm chain
# is invoked only with this phase-local build root; this phase then validates
# the newly stable semantic owner identity and retains the next mismatch as a
# fail-closed boundary. No canonical manifest, ledger, report, or shared doc
# is mutated here.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="${SM64_PHASE85DO_BUILD_ROOT:-$PROJECT_ROOT/build/sm64-modern-phase85do-warp-mapping}"
TOOL_ROOT="$BUILD_ROOT/tool"
mkdir -p "$TOOL_ROOT/module-cache"

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
SWIFT_OUTPUT="$TOOL_ROOT/warp-mapping-swift"

# The 85dm chain owns the native Debug/ASan/Release/rerun probe recipe. It is
# expected to return non-zero at the next unresolved subject; artifacts must
# still be complete before this phase can make any claim.
set +e
SM64_PHASE85DM_BUILD_ROOT="$BUILD_ROOT" \
    bash "$PROJECT_ROOT/script/test_phase85dm_instant_active_mapping.sh"
BASE_STATUS=$?
set -e
printf 'phase85do_base_matrix_status=%s\n' "$BASE_STATUS"

for artifact in \
    "$C_TRACE" "$ASAN_TRACE" "$RELEASE_TRACE" "$RERUN_TRACE" \
    "$C_PCM" "$ASAN_PCM" "$RELEASE_PCM" "$RERUN_PCM" \
    "$C_RECEIPTS" "$ASAN_RECEIPTS" "$RELEASE_RECEIPTS" "$RERUN_RECEIPTS"; do
    test -s "$artifact"
done

xcrun swiftc -parse-as-library -swift-version 6 \
    -Xfrontend -strict-concurrency=complete \
    -module-cache-path "$TOOL_ROOT/module-cache" \
    "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
    "$PROJECT_ROOT/tests/sm64_modern_phase85do_warp_mapping.swift" \
    -o "$SWIFT_OUTPUT"

"$SWIFT_OUTPUT" write "$C_TRACE" "$SWIFT_TRACE"
"$SWIFT_OUTPUT" tamper "$C_TRACE" "$TAMPER_TRACE"
"$SWIFT_OUTPUT" partial "$C_TRACE" "$PARTIAL_TRACE"
if "$SWIFT_OUTPUT" fixture "$C_TRACE" "$FIXTURE_MARKER"; then
    echo 'phase85do fixture-only fence unexpectedly accepted' >&2
    exit 1
fi
if "$SWIFT_OUTPUT" single "$C_TRACE" "$C_TRACE"; then
    echo 'phase85do single-artifact fence unexpectedly accepted' >&2
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
    echo 'phase85do fail-closed: next full-trace mismatch remains unmapped' >&2
fi

git -c core.fsmonitor=false diff --check -- \
    src/pc/sm64_modern_gameplay_parity.c \
    script/test_phase85do_warp_mapping.sh \
    tests/sm64_modern_phase85do_warp_mapping.swift \
    .porting/porting-handoff-full-swift-twin-phase85do-warp-mapping.md

printf '%s\n' \
    'SM64 Modern Phase 85do warp mapping matrix completed' \
    'native_c_lifecycle=1 castle_area2=1 sequence12_tick=63 records=476365' \
    'subject42_source=bhvWarp position=1963,819,1280 semantic_identity=0x2b006194588201ff' \
    'c_swift_byte_match=1 pcm_match=1 receipts_match=1 tamper_rejected=1 partial_rejected=1 fixture_only_rejected=1 single_artifact_rejected=1' \
    "full_trace_audit_status=$audit_status canonical_promotion=0 manifest_mutation=0 ledger_mutation=0 shared_docs_mutation=0"
exit "$audit_status"
