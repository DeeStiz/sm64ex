#!/usr/bin/env bash
set -euo pipefail

# Admit the canonical oracle_hook|camera_state row only after the existing
# independent C/Swift pair, fresh ASan C rerun, tamper fence, and exact
# schema-4 record checks pass.  This writes only an isolated report under
# build/; the generated manifest and historical route reports are immutable.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-camera-state-route-admission"
PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-camera-state-route-pair"
TOOL_ROOT="$BUILD_ROOT/tool"
ADMISSION_TOOL="$TOOL_ROOT/sm64-camera-state-route-admit"
MANIFEST="$PROJECT_ROOT/build/sm64-route-shards-smoke/route-shards.tsv"
REPORT="$BUILD_ROOT/route-shard-execution-ledger.tsv"
MANIFEST_LOG="$BUILD_ROOT/manifest.log"
PAIR_LOG="$BUILD_ROOT/pair.log"
ADMISSION_LOG="$BUILD_ROOT/admission.log"
RERUN_LOG="$BUILD_ROOT/rerun.log"
PARTIAL_LOG="$BUILD_ROOT/partial.log"
SINGLE_LOG="$BUILD_ROOT/single-trace.log"
C_TRACE="$PAIR_ROOT/camera-state-c.trace"
SWIFT_TRACE="$PAIR_ROOT/camera-state-swift.trace"
TAMPERED_TRACE="$PAIR_ROOT/camera-state-swift.tampered.trace"
ASAN_TRACE="$PAIR_ROOT/camera-state-c-asan.trace"
DEBUG_LOG="$PAIR_ROOT/native.log"
SWIFT_LOG="$PAIR_ROOT/swift.log"
ASAN_LOG="$PAIR_ROOT/asan.log"

mkdir -p "$TOOL_ROOT/module-cache"
# The report is a generated, isolated artifact.  Remove only this exact
# previous output so a fresh invocation proves a new single transition.
rm -f "$REPORT" "$ADMISSION_LOG" "$RERUN_LOG" "$PARTIAL_LOG" "$SINGLE_LOG"

# Rebuild the authoritative generated manifest.  This does not mutate source
# rows or any historical route report.
"$PROJECT_ROOT/script/test_route_shards.sh" >"$MANIFEST_LOG" 2>&1
test -s "$MANIFEST"
CAMERA_SHARD_ID="$(awk -F'|' '$2 == "oracle_hook" && $3 == "camera_state" && $5 == "0xb5728a6c95a20bac" && $6 == "0x06d7c939379a2dd5" { print $1; exit }' "$MANIFEST")"
[[ "$CAMERA_SHARD_ID" =~ ^0x[0-9a-f]{16}$ ]] || {
  echo "canonical camera manifest row was not found" >&2
  exit 1
}

# Re-run the unchanged source-backed pair.  It owns all canonical C/Swift,
# tampered, Debug, and ASan paths below.
"$PROJECT_ROOT/script/test_camera_state_route_pair.sh" >"$PAIR_LOG" 2>&1
test -s "$C_TRACE"
test -s "$SWIFT_TRACE"
test -s "$TAMPERED_TRACE"
test -s "$ASAN_TRACE"
grep -Fq 'camera_state_pairing_audit admitted=1 c_records=14 swift_records=14 blockers= first_divergence=none' "$PAIR_LOG"
grep -Fq 'camera_state_pairing_tamper_rejected=1' "$PAIR_LOG"
grep -Fq 'camera_state_route_sanitizer_passed=1 debug_asan_byte_match=1' "$PAIR_LOG"

# Compile the admission path independently under Swift 6 strict concurrency.
xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64CameraStateRouteAdmissionTool.swift" \
  -o "$ADMISSION_TOOL"

admission_output="$($ADMISSION_TOOL \
  --manifest "$MANIFEST" \
  --c-trace "$C_TRACE" \
  --swift-trace "$SWIFT_TRACE" \
  --tampered-trace "$TAMPERED_TRACE" \
  --debug-log "$DEBUG_LOG" \
  --swift-log "$SWIFT_LOG" \
  --asan-trace "$ASAN_TRACE" \
  --asan-log "$ASAN_LOG" \
  --report "$REPORT")"
printf '%s\n' "$admission_output" | tee "$ADMISSION_LOG"
grep -Fq 'SM64 Camera-state route admission passed' <<<"$admission_output"
grep -Fq 'shard=0x4eb19b71d76be0d4' <<<"$admission_output"
grep -Fq 'records=14 ticks=2,3' <<<"$admission_output"
grep -Fq 'before_planned=7420 before_terminal=0' <<<"$admission_output"
grep -Fq 'after_planned=7419 after_terminal=1' <<<"$admission_output"
grep -Fq 'tamper_rejected=1' <<<"$admission_output"

test -s "$REPORT"
row="$(awk -F'|' -v id="$CAMERA_SHARD_ID" '$1 == id { print; exit }' "$REPORT")"
[[ "$row" == "$CAMERA_SHARD_ID|passed|14|14|14|" ]] || {
  echo "unexpected camera-state ledger row: $row" >&2
  exit 1
}
planned_count="$(awk -F'|' '$2 == "planned" { count++ } END { print count + 0 }' "$REPORT")"
terminal_count="$(awk -F'|' '$2 != "planned" { count++ } END { print count + 0 }' "$REPORT")"
[[ "$planned_count" -eq 7419 && "$terminal_count" -eq 1 ]] || {
  echo "unexpected ledger counts planned=$planned_count terminal=$terminal_count" >&2
  exit 1
}

# A terminal report fences a second transition and must remain byte-identical.
report_before="$(shasum -a 256 "$REPORT" | awk '{ print $1 }')"
if "$ADMISSION_TOOL" \
  --manifest "$MANIFEST" \
  --c-trace "$C_TRACE" \
  --swift-trace "$SWIFT_TRACE" \
  --tampered-trace "$TAMPERED_TRACE" \
  --debug-log "$DEBUG_LOG" \
  --swift-log "$SWIFT_LOG" \
  --asan-trace "$ASAN_TRACE" \
  --asan-log "$ASAN_LOG" \
  --report "$REPORT" >"$RERUN_LOG" 2>&1; then
  echo 'persisted camera-state route shard was allowed to rerun' >&2
  exit 1
fi
grep -Fq 'rerun rejected' "$RERUN_LOG"
report_after="$(shasum -a 256 "$REPORT" | awk '{ print $1 }')"
[[ "$report_before" == "$report_after" ]] || {
  echo 'rejected camera-state rerun mutated the isolated report' >&2
  exit 1
}

# Passing one trace as both C and Swift evidence must be rejected before any
# report is written; this prevents a single artifact from self-pairing.
SINGLE_REPORT="$BUILD_ROOT/single-trace-report.tsv"
if "$ADMISSION_TOOL" \
  --manifest "$MANIFEST" \
  --c-trace "$C_TRACE" \
  --swift-trace "$C_TRACE" \
  --tampered-trace "$TAMPERED_TRACE" \
  --debug-log "$DEBUG_LOG" \
  --swift-log "$SWIFT_LOG" \
  --asan-trace "$ASAN_TRACE" \
  --asan-log "$ASAN_LOG" \
  --report "$SINGLE_REPORT" >"$SINGLE_LOG" 2>&1; then
  echo 'single camera-state trace was accepted as independent evidence' >&2
  exit 1
fi
grep -Fq 'distinct artifacts' "$SINGLE_LOG"
test ! -e "$SINGLE_REPORT"

# A truncated independent trace must also fail without changing the successful
# report.  Keep this check isolated from the persisted terminal report.
PARTIAL_TRACE="$BUILD_ROOT/camera-state-swift.partial.trace"
PARTIAL_REPORT="$BUILD_ROOT/partial-report.tsv"
rm -f "$PARTIAL_TRACE" "$PARTIAL_REPORT"
head -c $((72 + 13 * 128)) "$SWIFT_TRACE" >"$PARTIAL_TRACE"
if "$ADMISSION_TOOL" \
  --manifest "$MANIFEST" \
  --c-trace "$C_TRACE" \
  --swift-trace "$PARTIAL_TRACE" \
  --tampered-trace "$TAMPERED_TRACE" \
  --debug-log "$DEBUG_LOG" \
  --swift-log "$SWIFT_LOG" \
  --asan-trace "$ASAN_TRACE" \
  --asan-log "$ASAN_LOG" \
  --report "$PARTIAL_REPORT" >"$PARTIAL_LOG" 2>&1; then
  echo 'partial camera-state evidence was accepted' >&2
  exit 1
fi
grep -Fq 'record count 13 is not 14' "$PARTIAL_LOG"
test ! -e "$PARTIAL_REPORT"

git -c core.fsmonitor=false diff --check
printf '%s\n' \
  'SM64 Modern camera-state route admission smoke passed' \
  'camera_shard=0x4eb19b71d76be0d4 manifest_camera_row='"$CAMERA_SHARD_ID" \
  'records=14 ids=300..306 ticks=2,3 domain=5 kind=1' \
  'debug_c_swift_byte_match=1 asan_debug_byte_match=1 tamper_rejected=1' \
  'ledger_before=planned:7420,terminal:0 ledger_after=planned:7419,terminal:1' \
  'persistent_rerun_rejected=1 single_trace_rejected=1 partial_trace_rejected=1 fixture_only=0'
