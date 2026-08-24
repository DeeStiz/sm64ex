#!/usr/bin/env bash
set -euo pipefail

# Phase 85bl admits only the source-bound inside-castle display-list row.  The
# pair runner, manifest, and report all live under isolated build roots.  This
# script never mutates the canonical route ledger/history; GPU attachment,
# pixels, and physical acceptance are separate gates.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-display-list-next-route-admission"
PAIR_ROOT="$BUILD_ROOT/pair"
mkdir -p "$BUILD_ROOT"
RUN_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
TOOL_ROOT="$RUN_ROOT/tool"
MANIFEST_ROOT="$RUN_ROOT/manifest"
MANIFEST="$MANIFEST_ROOT/route-shards.tsv"
INVENTORY="$MANIFEST_ROOT/reachability.tsv"
ADMISSION_TOOL="$TOOL_ROOT/sm64-display-list-next-route-admit"
REPORT="$RUN_ROOT/display-list-next-isolated.tsv"
mkdir -p "$TOOL_ROOT/module-cache" "$MANIFEST_ROOT" "$PAIR_ROOT"

PAIR_LOG="$RUN_ROOT/pair.log"
MANIFEST_LOG="$RUN_ROOT/manifest.log"
ADMISSION_LOG="$RUN_ROOT/admission.log"
RERUN_LOG="$RUN_ROOT/rerun.log"
SINGLE_LOG="$RUN_ROOT/single-evidence.log"
PARTIAL_LOG="$RUN_ROOT/partial-evidence.log"

ROUTE_ID=0x00a5aebe36897ac4

sha256_file() { shasum -a 256 "$1" | awk '{ print $1 }'; }

bash -n "$PROJECT_ROOT/script/test_display_list_next_route_pair.sh"
SM64_DISPLAY_LIST_NEXT_ROUTE_BUILD_ROOT="$PAIR_ROOT" \
  "$PROJECT_ROOT/script/test_display_list_next_route_pair.sh" >"$PAIR_LOG" 2>&1
PAIR_RUN="$(find "$PAIR_ROOT" -maxdepth 1 -type d -name 'run.*' -print | sort | tail -1)"
test -n "$PAIR_RUN" -a -d "$PAIR_RUN"
for artifact in \
  "$PAIR_RUN/display-list-next-c.trace" "$PAIR_RUN/display-list-next-swift.trace" \
  "$PAIR_RUN/display-list-next-c-asan.trace" "$PAIR_RUN/display-list-next-c-release.trace" \
  "$PAIR_RUN/display-list-next-c-rerun.trace" "$PAIR_RUN/display-list-next-swift.tampered.trace" \
  "$PAIR_RUN/display-list-next-c.packet" "$PAIR_RUN/display-list-next-c-asan.packet" \
  "$PAIR_RUN/display-list-next-c-release.packet" "$PAIR_RUN/display-list-next-c-rerun.packet" \
  "$PAIR_RUN/debug.log" "$PAIR_RUN/swift.log" "$PAIR_RUN/asan.log" \
  "$PAIR_RUN/release.log" "$PAIR_RUN/rerun.log"; do
  test -s "$artifact"
done
grep -Fq 'display_list_next_pairing_audit admitted=1 c_records=2 swift_records=2 blockers= first_divergence=none' "$PAIR_LOG"
grep -Fq 'display_list_next_pairing_tamper_rejected=1' "$PAIR_LOG"
grep -Fq 'display_list_next_partial_trace_rejected=1' "$PAIR_LOG"
grep -Fq 'display_list_next_persistent_rerun_match=1' "$PAIR_LOG"
grep -Fq 'display_list_next_route_sanitizer_passed=1 debug_asan_trace_match=1 packet_match=1' "$PAIR_LOG"
grep -Fq 'display_list_next_route_release_passed=1 debug_release_trace_match=1 packet_match=1' "$PAIR_LOG"

# Generate the authoritative route manifest twice under this isolated run
# root and prove byte stability before admission.
REACHABILITY_TOOL="$TOOL_ROOT/sm64-oracle-reachability"
MANIFEST_TOOL="$TOOL_ROOT/sm64-route-shards"
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/tools/SM64OracleReachabilityTool.swift" -o "$REACHABILITY_TOOL"
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/tools/SM64RouteShardManifestTool.swift" -o "$MANIFEST_TOOL"
"$REACHABILITY_TOOL" --root "$PROJECT_ROOT" --output "$INVENTORY" >"$MANIFEST_LOG"
"$MANIFEST_TOOL" --inventory "$INVENTORY" --output "$MANIFEST" >>"$MANIFEST_LOG"
MANIFEST_SECOND="$MANIFEST_ROOT/route-shards-second.tsv"
"$MANIFEST_TOOL" --inventory "$INVENTORY" --output "$MANIFEST_SECOND" >>"$MANIFEST_LOG"
cmp -s "$MANIFEST" "$MANIFEST_SECOND"
MANIFEST_ROWS="$(awk -F'|' '$0 !~ /^#/ && NF { count++ } END { print count + 0 }' "$MANIFEST")"
test "$MANIFEST_ROWS" -gt 0
awk -F'|' -v id="$ROUTE_ID" \
  '$1 == id && $2 == "display_list" && $3 == "inside_castle_seg7_dl_070287C0" \
   && $4 == "levels/castle_inside/areas/1/2/model.inc.c" \
   && $5 == "0x38ed06da4fa1b69c" && $6 == "0x7684a9567f71ff45" \
   && $7 == "render_packet" && $8 == "planned" { found++ } \
   END { exit(found == 1 ? 0 : 1) }' "$MANIFEST"
manifest_before="$(sha256_file "$MANIFEST")"

# Compile the isolated admission path with Swift 6 strict concurrency.
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64DisplayListNextRouteAdmissionTool.swift" \
  -o "$ADMISSION_TOOL"

C_TRACE="$PAIR_RUN/display-list-next-c.trace"
SWIFT_TRACE="$PAIR_RUN/display-list-next-swift.trace"
ASAN_TRACE="$PAIR_RUN/display-list-next-c-asan.trace"
RELEASE_TRACE="$PAIR_RUN/display-list-next-c-release.trace"
RERUN_TRACE="$PAIR_RUN/display-list-next-c-rerun.trace"
TAMPERED_TRACE="$PAIR_RUN/display-list-next-swift.tampered.trace"
C_PACKET="$PAIR_RUN/display-list-next-c.packet"
ASAN_PACKET="$PAIR_RUN/display-list-next-c-asan.packet"
RELEASE_PACKET="$PAIR_RUN/display-list-next-c-release.packet"
RERUN_PACKET="$PAIR_RUN/display-list-next-c-rerun.packet"
DEBUG_LOG="$PAIR_RUN/debug.log"
SWIFT_LOG="$PAIR_RUN/swift.log"
ASAN_LOG="$PAIR_RUN/asan.log"
RELEASE_LOG="$PAIR_RUN/release.log"
PAIR_RERUN_LOG="$PAIR_RUN/rerun.log"

run_admit() {
  local c_trace="$1"
  local report="$2"
  "$ADMISSION_TOOL" \
    --manifest "$MANIFEST" \
    --c-trace "$c_trace" \
    --swift-trace "$SWIFT_TRACE" \
    --asan-trace "$ASAN_TRACE" \
    --release-trace "$RELEASE_TRACE" \
    --rerun-trace "$RERUN_TRACE" \
    --tampered-trace "$TAMPERED_TRACE" \
    --c-packet "$C_PACKET" \
    --asan-packet "$ASAN_PACKET" \
    --release-packet "$RELEASE_PACKET" \
    --rerun-packet "$RERUN_PACKET" \
    --debug-log "$DEBUG_LOG" \
    --swift-log "$SWIFT_LOG" \
    --asan-log "$ASAN_LOG" \
    --release-log "$RELEASE_LOG" \
    --rerun-log "$PAIR_RERUN_LOG" \
    --report "$report"
}

admission_output="$(run_admit "$C_TRACE" "$REPORT")"
printf '%s\n' "$admission_output" | tee "$ADMISSION_LOG"
grep -Fq 'SM64 display-list next route isolated admission passed' <<<"$admission_output"
grep -Fq 'shard=0x00a5aebe36897ac4 identity=inside_castle_seg7_dl_070287C0 source=levels/castle_inside/areas/1/2/model.inc.c records=2 ticks=1,2 domain=11 kind=7 schema=4' <<<"$admission_output"
grep -Fq 'c_swift_asan_release_rerun_byte_match=1 packet_resource_values=stable tamper_rejected=1' <<<"$admission_output"
grep -Fq 'fixture_only=0 manifest_mutated=0 canonical_ledger_mutation=0 history_mutated=0 rerun_fence=1' <<<"$admission_output"
test "$(wc -l <"$REPORT" | tr -d '[:space:]')" -eq "$MANIFEST_ROWS"
test "$(awk -F'|' -v id="$ROUTE_ID" '$1 == id && $2 == "passed" { count++ } END { print count + 0 }' "$REPORT")" -eq 1
test "$(awk -F'|' '$2 == "planned" { count++ } END { print count + 0 }' "$REPORT")" -eq "$((MANIFEST_ROWS - 1))"
target_row="$(awk -F'|' -v id="$ROUTE_ID" '$1 == id { print; exit }' "$REPORT")"
[[ "$target_row" == "$ROUTE_ID|passed|2|2|2|" ]]

# The isolated report is write-once. A rerun must fail and leave its bytes
# unchanged, independent of any canonical ledger state.
report_before="$(sha256_file "$REPORT")"
if run_admit "$C_TRACE" "$REPORT" >"$RERUN_LOG" 2>&1; then
  echo 'display-list-next isolated admission rerun unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'already exists' "$RERUN_LOG"
report_after_rerun="$(sha256_file "$REPORT")"
[[ "$report_before" == "$report_after_rerun" ]]

# Reusing C as Swift is not independent evidence.
SINGLE_REPORT="$RUN_ROOT/single-evidence.tsv"
if "$ADMISSION_TOOL" \
  --manifest "$MANIFEST" --c-trace "$C_TRACE" --swift-trace "$C_TRACE" \
  --asan-trace "$ASAN_TRACE" --release-trace "$RELEASE_TRACE" --rerun-trace "$RERUN_TRACE" \
  --tampered-trace "$TAMPERED_TRACE" --c-packet "$C_PACKET" --asan-packet "$ASAN_PACKET" \
  --release-packet "$RELEASE_PACKET" --rerun-packet "$RERUN_PACKET" \
  --debug-log "$DEBUG_LOG" --swift-log "$SWIFT_LOG" --asan-log "$ASAN_LOG" \
  --release-log "$RELEASE_LOG" --rerun-log "$PAIR_RERUN_LOG" --report "$SINGLE_REPORT" \
  >"$SINGLE_LOG" 2>&1; then
  echo 'single-artifact display-list admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'distinct artifacts' "$SINGLE_LOG"
test ! -e "$SINGLE_REPORT"

# A one-record trace must fail the exact two-record gate and must not leave a
# partial report behind.
PARTIAL_TRACE="$RUN_ROOT/partial.trace"
PARTIAL_REPORT="$RUN_ROOT/partial-evidence.tsv"
dd if="$C_TRACE" of="$PARTIAL_TRACE" bs=1 count=$((72 + 128)) status=none
if run_admit "$PARTIAL_TRACE" "$PARTIAL_REPORT" >"$PARTIAL_LOG" 2>&1; then
  echo 'partial-trace display-list admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'record count 1 is not 2' "$PARTIAL_LOG"
test ! -e "$PARTIAL_REPORT"

manifest_after="$(sha256_file "$MANIFEST")"
[[ "$manifest_before" == "$manifest_after" ]]
git -c core.fsmonitor=false diff --check
report_sha256="$(sha256_file "$REPORT")"
printf '%s\n' \
  "SM64 Modern display-list-next route admission smoke passed run=$RUN_ROOT" \
  "shard=$ROUTE_ID source=levels/castle_inside/areas/1/2/model.inc.c identity=inside_castle_seg7_dl_070287C0 input_seed=0x38ed06da4fa1b69c save_seed=0x7684a9567f71ff45" \
  "manifest=isolated route-shards.tsv manifest_rows=$MANIFEST_ROWS target_status=planned target_parent=inside_castle_seg7_dl_07028FD0" \
  'records=2 ticks=1,2 domain=11 kind=7 source_identity=0xea260066b29ece0c owner_identity=0xad524f68d4a58ea8' \
  'packet_fingerprint=0x8ffa117b4fac4bd6 resource_fingerprint=0x64ed5e12bb6ae628 words=16 resources=8' \
  'c_swift_asan_release_rerun_byte_match=1 packet_sidecars_match=1 stable_packet_resource_values=1 tamper_rejected=1 single_artifact_rejected=1 partial_trace_rejected=1 persistent_rerun_rejected=1' \
  'gpu_capture=separate pixel_acceptance=unverified physical_acceptance=unverified fixture_only=0 manifest_mutated=0 canonical_ledger_mutation=0 history_mutated=0' \
  "report_sha256=$report_sha256 report_rows=$MANIFEST_ROWS passed_rows=1 planned_rows=$((MANIFEST_ROWS - 1)) manifest_sha256=$manifest_after"
