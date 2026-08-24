#!/usr/bin/env bash
set -euo pipefail

# Phase 85o admits only the generated oracle_hook|object_state row after the
# source-backed C/Swift/ASan pair, six fingerprints, exact object field window,
# tamper fence, and isolated ledger transition pass. The manifest and all
# historical reports remain read-only inputs.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-object-state-route-admission"
PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-object-state-route-pair"
TOOL_ROOT="$BUILD_ROOT/tool"
ADMISSION_TOOL="$TOOL_ROOT/sm64-object-script-route-admit"
MANIFEST="$PROJECT_ROOT/build/sm64-route-shards-smoke/route-shards.tsv"
REPORT="$BUILD_ROOT/route-shard-execution-ledger.tsv"
MANIFEST_LOG="$BUILD_ROOT/manifest.log"
PAIR_LOG="$BUILD_ROOT/pair.log"
ADMISSION_LOG="$BUILD_ROOT/admission.log"
RERUN_LOG="$BUILD_ROOT/rerun.log"
SINGLE_LOG="$BUILD_ROOT/single-trace.log"
PARTIAL_LOG="$BUILD_ROOT/partial.log"
SINGLE_REPORT="$BUILD_ROOT/single-trace-report.tsv"
PARTIAL_REPORT="$BUILD_ROOT/partial-report.tsv"
PARTIAL_TRACE="$BUILD_ROOT/object-state-swift.partial.trace"
SHARD_ID=0x862c3d78b60d657c

C_TRACE="$PAIR_ROOT/object-state-c.trace"
SWIFT_TRACE="$PAIR_ROOT/object-state-swift.trace"
ASAN_TRACE="$PAIR_ROOT/object-state-c-asan.trace"
TAMPERED_TRACE="$PAIR_ROOT/object-state-swift.tampered.trace"
DEBUG_LOG="$PAIR_ROOT/native.log"
SWIFT_LOG="$PAIR_ROOT/swift.log"
ASAN_LOG="$PAIR_ROOT/asan.log"

mkdir -p "$TOOL_ROOT/module-cache"
rm -f "$REPORT" "$ADMISSION_LOG" "$RERUN_LOG" "$SINGLE_LOG" "$PARTIAL_LOG" \
  "$SINGLE_REPORT" "$PARTIAL_REPORT" "$PARTIAL_TRACE"

"$PROJECT_ROOT/script/test_route_shards.sh" >"$MANIFEST_LOG" 2>&1
test -s "$MANIFEST"
awk -F'|' -v id="$SHARD_ID" '
  $1 == id && $2 == "oracle_hook" && $3 == "object_state" &&
  $4 == "src/pc/sm64_modern_gameplay_parity.c" &&
  $5 == "0x58cc16e4df725004" && $6 == "0x18fda13ffd33fa7d" &&
  $7 == "object_state" && $8 == "planned" { found = 1 }
  END { exit(found ? 0 : 1) }
' "$MANIFEST"
manifest_sha_before="$(shasum -a 256 "$MANIFEST" | awk '{ print $1 }')"

"$PROJECT_ROOT/script/test_object_state_route_pair.sh" >"$PAIR_LOG" 2>&1
for artifact in "$C_TRACE" "$SWIFT_TRACE" "$ASAN_TRACE" "$TAMPERED_TRACE" \
  "$DEBUG_LOG" "$SWIFT_LOG" "$ASAN_LOG"; do
  test -s "$artifact"
done
grep -Fq 'object_state_pairing_audit admitted=1 c_records=28 swift_records=28 blockers= first_divergence=none' "$PAIR_LOG"
grep -Fq 'object_state_pairing_tamper_rejected=1' "$PAIR_LOG"
grep -Fq 'object_state_route_sanitizer_passed=1 debug_asan_byte_match=1' "$PAIR_LOG"
grep -Fq 'admission=0 ledger_mutation=0' "$PAIR_LOG"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64ObjectScriptRouteAdmissionTool.swift" \
  -o "$ADMISSION_TOOL"

admission_output="$("$ADMISSION_TOOL" \
  --route object_state \
  --manifest "$MANIFEST" \
  --c-trace "$C_TRACE" \
  --swift-trace "$SWIFT_TRACE" \
  --asan-trace "$ASAN_TRACE" \
  --tampered-trace "$TAMPERED_TRACE" \
  --debug-log "$DEBUG_LOG" \
  --swift-log "$SWIFT_LOG" \
  --asan-log "$ASAN_LOG" \
  --report "$REPORT")"
printf '%s\n' "$admission_output" | tee "$ADMISSION_LOG"
grep -Fq 'SM64 object_state route admission passed' <<<"$admission_output"
grep -Fq "shard=$SHARD_ID" <<<"$admission_output"
grep -Fq 'records=28 ticks=2,3 domain=3 kind=1' <<<"$admission_output"
grep -Fq 'before_planned=7420 before_terminal=0' <<<"$admission_output"
grep -Fq 'after_planned=7419 after_terminal=1' <<<"$admission_output"
grep -Fq 'tamper_rejected=1 fixture_only=0' <<<"$admission_output"

test -s "$REPORT"
row="$(awk -F'|' -v id="$SHARD_ID" '$1 == id { print; exit }' "$REPORT")"
[[ "$row" == "$SHARD_ID|passed|28|28|28|" ]] || {
  echo "unexpected object-state ledger row: $row" >&2
  exit 1
}
planned_count="$(awk -F'|' '$2 == "planned" { count++ } END { print count + 0 }' "$REPORT")"
terminal_count="$(awk -F'|' '$2 != "planned" { count++ } END { print count + 0 }' "$REPORT")"
[[ "$planned_count" -eq 7419 && "$terminal_count" -eq 1 ]]

report_before="$(shasum -a 256 "$REPORT" | awk '{ print $1 }')"
if "$ADMISSION_TOOL" \
  --route object_state \
  --manifest "$MANIFEST" \
  --c-trace "$C_TRACE" \
  --swift-trace "$SWIFT_TRACE" \
  --asan-trace "$ASAN_TRACE" \
  --tampered-trace "$TAMPERED_TRACE" \
  --debug-log "$DEBUG_LOG" \
  --swift-log "$SWIFT_LOG" \
  --asan-log "$ASAN_LOG" \
  --report "$REPORT" >"$RERUN_LOG" 2>&1; then
  echo 'persisted object-state route shard was allowed to rerun' >&2
  exit 1
fi
grep -Fq 'rerun rejected' "$RERUN_LOG"
report_after="$(shasum -a 256 "$REPORT" | awk '{ print $1 }')"
[[ "$report_before" == "$report_after" ]]

if "$ADMISSION_TOOL" \
  --route object_state \
  --manifest "$MANIFEST" \
  --c-trace "$C_TRACE" \
  --swift-trace "$C_TRACE" \
  --asan-trace "$ASAN_TRACE" \
  --tampered-trace "$TAMPERED_TRACE" \
  --debug-log "$DEBUG_LOG" \
  --swift-log "$SWIFT_LOG" \
  --asan-log "$ASAN_LOG" \
  --report "$SINGLE_REPORT" >"$SINGLE_LOG" 2>&1; then
  echo 'single object-state trace was accepted as independent evidence' >&2
  exit 1
fi
grep -Fq 'distinct artifacts' "$SINGLE_LOG"
test ! -e "$SINGLE_REPORT"

head -c $((72 + 27 * 128)) "$SWIFT_TRACE" >"$PARTIAL_TRACE"
if "$ADMISSION_TOOL" \
  --route object_state \
  --manifest "$MANIFEST" \
  --c-trace "$C_TRACE" \
  --swift-trace "$PARTIAL_TRACE" \
  --asan-trace "$ASAN_TRACE" \
  --tampered-trace "$TAMPERED_TRACE" \
  --debug-log "$DEBUG_LOG" \
  --swift-log "$SWIFT_LOG" \
  --asan-log "$ASAN_LOG" \
  --report "$PARTIAL_REPORT" >"$PARTIAL_LOG" 2>&1; then
  echo 'partial object-state evidence was accepted' >&2
  exit 1
fi
grep -Fq 'record count 27 is not 28' "$PARTIAL_LOG"
test ! -e "$PARTIAL_REPORT"

manifest_sha_after="$(shasum -a 256 "$MANIFEST" | awk '{ print $1 }')"
[[ "$manifest_sha_before" == "$manifest_sha_after" ]]
git -c core.fsmonitor=false diff --check
printf '%s\n' \
  'SM64 Modern object-state route admission smoke passed' \
  "shard=$SHARD_ID source=oracle_hook|object_state input_seed=0x58cc16e4df725004 save_seed=0x18fda13ffd33fa7d" \
  'manifest_rows=7420 records=28 ids=400..413 ticks=2,3 domain=3 kind=1' \
  'debug_swift_asan_byte_match=1 six_fingerprints_match=1 tamper_rejected=1 fixture_only=0' \
  'persistent_rerun_rejected=1 single_trace_rejected=1 partial_trace_rejected=1' \
  "ledger_before=planned:7420,terminal:0 ledger_after=planned:7419,terminal:1 report_sha256=$(shasum -a 256 "$REPORT" | awk '{ print $1 }') manifest_sha256=$manifest_sha_after"
