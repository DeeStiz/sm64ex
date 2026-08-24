#!/usr/bin/env bash
set -euo pipefail

# Admit the generated oracle_hook|global_state row only after the complete
# source-backed C/Swift/ASan owner pair, publication snapshots, tamper fence,
# and filtered-host evidence pass. The manifest is regenerated as a build
# artifact and read-only input; only the isolated report below is written.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-global-state-route-admission"
PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-global-state-route-pair"
TOOL_ROOT="$BUILD_ROOT/tool"
ADMISSION_TOOL="$TOOL_ROOT/sm64-global-state-route-admit"
MANIFEST="$PROJECT_ROOT/build/sm64-route-shards-smoke/route-shards.tsv"
REPORT="$BUILD_ROOT/route-shard-execution-ledger.tsv"
MANIFEST_LOG="$BUILD_ROOT/manifest.log"
PAIR_LOG="$BUILD_ROOT/pair.log"
ADMISSION_LOG="$BUILD_ROOT/admission.log"
RERUN_LOG="$BUILD_ROOT/rerun.log"
SINGLE_LOG="$BUILD_ROOT/single-trace.log"
PARTIAL_LOG="$BUILD_ROOT/partial.log"
GLOBAL_ID=0xb123ff3e997bdc78

C_TRACE="$PAIR_ROOT/global-state-c.trace"
SWIFT_TRACE="$PAIR_ROOT/global-state-swift.trace"
ASAN_TRACE="$PAIR_ROOT/global-state-c-asan.trace"
TAMPERED_TRACE="$PAIR_ROOT/global-state-swift.tampered.trace"
C_SNAPSHOTS="$PAIR_ROOT/global-state-c.trace.snapshots"
ASAN_SNAPSHOTS="$PAIR_ROOT/global-state-c-asan.trace.snapshots"
DEBUG_LOG="$PAIR_ROOT/native.log"
SWIFT_LOG="$PAIR_ROOT/swift.log"
ASAN_LOG="$PAIR_ROOT/asan.log"

mkdir -p "$TOOL_ROOT/module-cache"
rm -f "$REPORT" "$ADMISSION_LOG" "$RERUN_LOG" "$SINGLE_LOG" "$PARTIAL_LOG"

# Generate the authoritative manifest in its existing generated-artifact
# location. The admission tool does not mutate this file or historical reports.
"$PROJECT_ROOT/script/test_route_shards.sh" >"$MANIFEST_LOG" 2>&1
test -s "$MANIFEST"
awk -F'|' -v id="$GLOBAL_ID" \
  '$1 == id && $2 == "oracle_hook" && $3 == "global_state" \
   && $4 == "src/pc/sm64_modern_gameplay_parity.c" \
   && $5 == "0x0554d9bee9d4fbe0" && $6 == "0x939ff6a6efd67889" \
   && $7 == "global_state" && $8 == "planned" { found = 1 } \
   END { exit(found ? 0 : 1) }' "$MANIFEST"

# Re-run the real owner-thread pair. Its C callback retains only the exact
# global route window from the host lifecycle; the tool separately requires
# the native log's actual=1789/retained=12 filter evidence.
"$PROJECT_ROOT/script/test_global_state_route_pair.sh" >"$PAIR_LOG" 2>&1
for artifact in "$C_TRACE" "$SWIFT_TRACE" "$ASAN_TRACE" "$TAMPERED_TRACE" \
  "$C_SNAPSHOTS" "$ASAN_SNAPSHOTS" "$DEBUG_LOG" "$SWIFT_LOG" "$ASAN_LOG"; do
  test -s "$artifact"
done
grep -Fq 'global_state_pairing_audit admitted=1 c_records=12 swift_records=12 blockers= first_divergence=none' "$PAIR_LOG"
grep -Fq 'global_state_pairing_tamper_rejected=1' "$PAIR_LOG"
grep -Fq 'global_state_route_sanitizer_passed=1 debug_asan_trace_match=1 snapshots_match=1' "$PAIR_LOG"
grep -Fq 'admission=0 ledger_mutation=0' "$PAIR_LOG"

# Compile the canonical admission path independently under Swift 6 strict
# concurrency. It performs the single begin/finish ledger transition only
# after validating all independent artifacts and snapshot-to-record equality.
xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64GlobalStateRouteAdmissionTool.swift" \
  -o "$ADMISSION_TOOL"

admission_output="$($ADMISSION_TOOL \
  --manifest "$MANIFEST" \
  --c-trace "$C_TRACE" \
  --swift-trace "$SWIFT_TRACE" \
  --asan-trace "$ASAN_TRACE" \
  --tampered-trace "$TAMPERED_TRACE" \
  --c-snapshots "$C_SNAPSHOTS" \
  --asan-snapshots "$ASAN_SNAPSHOTS" \
  --debug-log "$DEBUG_LOG" \
  --swift-log "$SWIFT_LOG" \
  --asan-log "$ASAN_LOG" \
  --report "$REPORT")"
printf '%s\n' "$admission_output" | tee "$ADMISSION_LOG"
grep -Fq 'SM64 Global-state route admission passed' <<<"$admission_output"
grep -Fq 'shard=0xb123ff3e997bdc78' <<<"$admission_output"
grep -Fq 'records=12 ticks=2,3 ids=1..6 domain=0 state=1' <<<"$admission_output"
grep -Fq 'snapshots=2 host_records=1789 filtered_records=12' <<<"$admission_output"
grep -Fq 'publication_equal=1' <<<"$admission_output"
grep -Fq 'before_planned=7420 before_terminal=0' <<<"$admission_output"
grep -Fq 'after_planned=7419 after_terminal=1' <<<"$admission_output"
grep -Fq 'tamper_rejected=1' <<<"$admission_output"
grep -Fq 'fixture_only=0' <<<"$admission_output"

test -s "$REPORT"
row="$(awk -F'|' -v id="$GLOBAL_ID" '$1 == id { print; exit }' "$REPORT")"
[[ "$row" == "$GLOBAL_ID|passed|12|12|12|" ]] || {
  echo "unexpected global-state ledger row: $row" >&2
  exit 1
}
planned_count="$(awk -F'|' '$2 == "planned" { count++ } END { print count + 0 }' "$REPORT")"
terminal_count="$(awk -F'|' '$2 != "planned" { count++ } END { print count + 0 }' "$REPORT")"
[[ "$planned_count" -eq 7419 && "$terminal_count" -eq 1 ]] || {
  echo "unexpected ledger counts planned=$planned_count terminal=$terminal_count" >&2
  exit 1
}

# A terminal report fences the same evidence from a second transition and
# leaves the successful isolated report byte-identical.
report_before="$(shasum -a 256 "$REPORT" | awk '{ print $1 }')"
if "$ADMISSION_TOOL" \
  --manifest "$MANIFEST" \
  --c-trace "$C_TRACE" \
  --swift-trace "$SWIFT_TRACE" \
  --asan-trace "$ASAN_TRACE" \
  --tampered-trace "$TAMPERED_TRACE" \
  --c-snapshots "$C_SNAPSHOTS" \
  --asan-snapshots "$ASAN_SNAPSHOTS" \
  --debug-log "$DEBUG_LOG" \
  --swift-log "$SWIFT_LOG" \
  --asan-log "$ASAN_LOG" \
  --report "$REPORT" >"$RERUN_LOG" 2>&1; then
  echo 'persisted global-state route shard was allowed to rerun' >&2
  exit 1
fi
grep -Fq 'rerun rejected' "$RERUN_LOG"
report_after="$(shasum -a 256 "$REPORT" | awk '{ print $1 }')"
[[ "$report_before" == "$report_after" ]] || {
  echo 'rejected rerun mutated the isolated report' >&2
  exit 1
}

# Reusing one trace for C and Swift must fail before any report is written.
SINGLE_REPORT="$BUILD_ROOT/single-trace-report.tsv"
rm -f "$SINGLE_REPORT"
if "$ADMISSION_TOOL" \
  --manifest "$MANIFEST" \
  --c-trace "$C_TRACE" \
  --swift-trace "$C_TRACE" \
  --asan-trace "$ASAN_TRACE" \
  --tampered-trace "$TAMPERED_TRACE" \
  --c-snapshots "$C_SNAPSHOTS" \
  --asan-snapshots "$ASAN_SNAPSHOTS" \
  --debug-log "$DEBUG_LOG" \
  --swift-log "$SWIFT_LOG" \
  --asan-log "$ASAN_LOG" \
  --report "$SINGLE_REPORT" >"$SINGLE_LOG" 2>&1; then
  echo 'single global-state trace was accepted as independent evidence' >&2
  exit 1
fi
grep -Fq 'distinct artifacts' "$SINGLE_LOG"
test ! -e "$SINGLE_REPORT"

# A truncated filtered trace must fail the exact twelve-record gate and must
# not create a partial report.
PARTIAL_TRACE="$BUILD_ROOT/global-state-swift.partial.trace"
PARTIAL_REPORT="$BUILD_ROOT/partial-report.tsv"
rm -f "$PARTIAL_TRACE" "$PARTIAL_REPORT"
head -c $((72 + 11 * 128)) "$SWIFT_TRACE" >"$PARTIAL_TRACE"
if "$ADMISSION_TOOL" \
  --manifest "$MANIFEST" \
  --c-trace "$C_TRACE" \
  --swift-trace "$PARTIAL_TRACE" \
  --asan-trace "$ASAN_TRACE" \
  --tampered-trace "$TAMPERED_TRACE" \
  --c-snapshots "$C_SNAPSHOTS" \
  --asan-snapshots "$ASAN_SNAPSHOTS" \
  --debug-log "$DEBUG_LOG" \
  --swift-log "$SWIFT_LOG" \
  --asan-log "$ASAN_LOG" \
  --report "$PARTIAL_REPORT" >"$PARTIAL_LOG" 2>&1; then
  echo 'partial global-state evidence was accepted' >&2
  exit 1
fi
grep -Fq 'filtered route record count 11 is not 12' "$PARTIAL_LOG"
test ! -e "$PARTIAL_REPORT"

git -c core.fsmonitor=false diff --check
manifest_sha256="$(shasum -a 256 "$MANIFEST" | awk '{ print $1 }')"
printf '%s\n' \
  'SM64 Modern global-state route admission smoke passed' \
  "shard=$GLOBAL_ID source=oracle_hook|global_state input_seed=0x0554d9bee9d4fbe0 save_seed=0x939ff6a6efd67889" \
  'manifest=generated route-shards.tsv manifest_rows=7420' \
  'debug_swift_asan_byte_match=1 publication_snapshot_bytes_match=1 snapshot_record_equality=1' \
  'filtered_host_records=1789 retained_route_records=12 ids=1..6 ticks=2,3 domain=0 kind=1' \
  'tamper_rejected=1 persistent_rerun_rejected=1 single_trace_rejected=1 partial_trace_rejected=1 fixture_only=0' \
  "ledger_before=planned:7420,terminal:0 ledger_after=planned:7419,terminal:1 report_sha256=$report_after manifest_sha256=$manifest_sha256"
