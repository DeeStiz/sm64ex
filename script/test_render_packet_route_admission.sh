#!/usr/bin/env bash
set -euo pipefail

# Phase 85aa admits only the canonical oracle_hook|render_packet row from the
# independent C, Swift, ASan, and Release pair artifacts. The manifest is
# generated under an isolated run root and is immutable input to admission;
# this phase writes only a fresh isolated report. GPU capture, attachment
# inspection, pixels, and visual acceptance remain separate M34 gates.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-render-packet-route-admission"
PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-render-packet-route-pair"
mkdir -p "$BUILD_ROOT"
RUN_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
TOOL_ROOT="$RUN_ROOT/tool"
MANIFEST_ROOT="$RUN_ROOT/manifest"
MANIFEST="$MANIFEST_ROOT/route-shards.tsv"
INVENTORY="$MANIFEST_ROOT/reachability.tsv"
ADMISSION_TOOL="$TOOL_ROOT/sm64-render-packet-route-admit"
REPORT="$RUN_ROOT/render-packet-isolated.tsv"
mkdir -p "$TOOL_ROOT/module-cache" "$MANIFEST_ROOT"

PAIR_LOG="$RUN_ROOT/pair.log"
MANIFEST_LOG="$RUN_ROOT/manifest.log"
ADMISSION_LOG="$RUN_ROOT/admission.log"
RERUN_LOG="$RUN_ROOT/rerun.log"
SINGLE_LOG="$RUN_ROOT/single-evidence.log"
PARTIAL_LOG="$RUN_ROOT/partial-evidence.log"

ROUTE_ID=0x149fe4b1ab8a36a5
C_TRACE="$PAIR_ROOT/render-packet-c.trace"
SWIFT_TRACE="$PAIR_ROOT/render-packet-swift.trace"
ASAN_TRACE="$PAIR_ROOT/render-packet-c-asan.trace"
RELEASE_TRACE="$PAIR_ROOT/render-packet-c-release.trace"
TAMPERED_TRACE="$PAIR_ROOT/render-packet-swift.tampered.trace"
DEBUG_LOG="$PAIR_ROOT/debug.log"
SWIFT_LOG="$PAIR_ROOT/swift.log"
ASAN_LOG="$PAIR_ROOT/asan.log"
RELEASE_LOG="$PAIR_ROOT/release.log"

sha256_file() { shasum -a 256 "$1" | awk '{ print $1 }'; }

bash -n "$PROJECT_ROOT/script/test_render_packet_route_pair.sh"
"$PROJECT_ROOT/script/test_render_packet_route_pair.sh" >"$PAIR_LOG" 2>&1
for artifact in "$C_TRACE" "$SWIFT_TRACE" "$ASAN_TRACE" "$RELEASE_TRACE" \
  "$TAMPERED_TRACE" "$DEBUG_LOG" "$SWIFT_LOG" "$ASAN_LOG" "$RELEASE_LOG"; do
  test -s "$artifact"
done
grep -Fq 'render_packet_pairing_audit admitted=1 c_records=8 swift_records=8 blockers= first_divergence=none' "$PAIR_LOG"
grep -Fq 'render_packet_pairing_tamper_rejected=1' "$PAIR_LOG"
grep -Fq 'render_packet_route_sanitizer_passed=1 debug_asan_trace_match=1' "$PAIR_LOG"
grep -Fq 'render_packet_route_optimized_passed=1 debug_release_trace_match=1' "$PAIR_LOG"
grep -Fq 'gpu_capture=separate visual_pixels=unverified admission=0 ledger_mutation=0 fixture_only=0' "$PAIR_LOG"

# Generate the authoritative manifest twice under the isolated run root. No
# canonical build manifest, execution ledger, or history file is an input.
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
test "$(awk -F'|' '$0 !~ /^#/ && NF { count++ } END { print count + 0 }' "$MANIFEST")" -eq 7420
awk -F'|' -v id="$ROUTE_ID" \
  '$1 == id && $2 == "oracle_hook" && $3 == "render_packet" \
   && $4 == "src/pc/sm64_modern_gameplay_parity.c" \
   && $5 == "0x2cc8dc5ab4228549" && $6 == "0xbb82f7313b3d4f96" \
   && $7 == "render_packet" && $8 == "planned" { found++ } \
   END { exit(found == 1 ? 0 : 1) }' "$MANIFEST"
manifest_before="$(sha256_file "$MANIFEST")"

# Compile the admission path independently with Swift 6 strict concurrency.
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64RenderPacketRouteAdmissionTool.swift" \
  -o "$ADMISSION_TOOL"

run_admit() {
  local c_trace="$1"
  local report="$2"
  "$ADMISSION_TOOL" \
    --manifest "$MANIFEST" \
    --c-trace "$c_trace" \
    --swift-trace "$SWIFT_TRACE" \
    --asan-trace "$ASAN_TRACE" \
    --release-trace "$RELEASE_TRACE" \
    --tampered-trace "$TAMPERED_TRACE" \
    --debug-log "$DEBUG_LOG" \
    --swift-log "$SWIFT_LOG" \
    --asan-log "$ASAN_LOG" \
    --release-log "$RELEASE_LOG" \
    --report "$report"
}

admission_output="$(run_admit "$C_TRACE" "$REPORT")"
printf '%s\n' "$admission_output" | tee "$ADMISSION_LOG"
grep -Fq 'SM64 render-packet route isolated admission passed' <<<"$admission_output"
grep -Fq 'shard=0x149fe4b1ab8a36a5 records=8 ticks=1,2 domain=11 kind=7' <<<"$admission_output"
grep -Fq 'manifest_rows=7420 report_rows=7420 passed_rows=1 planned_rows=7419' <<<"$admission_output"
grep -Fq 'c_swift_asan_release_byte_match=1 tamper_rejected=1' <<<"$admission_output"
grep -Fq 'gpu_capture=separate pixel_acceptance=unverified visual_acceptance=unverified' <<<"$admission_output"
grep -Fq 'fixture_only=0 manifest_mutated=0 ledger_mutated=0 history_mutated=0 rerun_fence=1' <<<"$admission_output"
test "$(wc -l <"$REPORT" | tr -d '[:space:]')" -eq 7420
test "$(awk -F'|' -v id="$ROUTE_ID" '$1 == id && $2 == "passed" { count++ } END { print count + 0 }' "$REPORT")" -eq 1
test "$(awk -F'|' '$2 == "planned" { count++ } END { print count + 0 }' "$REPORT")" -eq 7419
target_row="$(awk -F'|' -v id="$ROUTE_ID" '$1 == id { print; exit }' "$REPORT")"
[[ "$target_row" == "$ROUTE_ID|passed|8|8|8|" ]]

# The report itself is the rerun fence. A rejected rerun must not mutate it.
report_before="$(sha256_file "$REPORT")"
if run_admit "$C_TRACE" "$REPORT" >"$RERUN_LOG" 2>&1; then
  echo 'render-packet isolated admission rerun unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'already exists' "$RERUN_LOG"
report_after_rerun="$(sha256_file "$REPORT")"
[[ "$report_before" == "$report_after_rerun" ]]

# Reusing one trace for C and Swift is not independent evidence.
SINGLE_REPORT="$RUN_ROOT/single-evidence.tsv"
# Explicitly repeat the invocation with C as Swift so the tool's
# duplicate-evidence fence is used.
if "$ADMISSION_TOOL" --manifest "$MANIFEST" --c-trace "$C_TRACE" \
  --swift-trace "$C_TRACE" --asan-trace "$ASAN_TRACE" \
  --release-trace "$RELEASE_TRACE" --tampered-trace "$TAMPERED_TRACE" \
  --debug-log "$DEBUG_LOG" --swift-log "$SWIFT_LOG" --asan-log "$ASAN_LOG" \
  --release-log "$RELEASE_LOG" --report "$SINGLE_REPORT" \
  >"$SINGLE_LOG" 2>&1; then
  echo 'single-artifact render-packet admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'distinct artifacts' "$SINGLE_LOG"
test ! -e "$SINGLE_REPORT"

# A truncated seven-record trace must fail the exact eight-record gate and
# must not leave a partial report behind.
PARTIAL_TRACE="$RUN_ROOT/partial-c.trace"
PARTIAL_REPORT="$RUN_ROOT/partial-evidence.tsv"
dd if="$C_TRACE" of="$PARTIAL_TRACE" bs=1 count=$((72 + 7 * 128)) status=none
if run_admit "$PARTIAL_TRACE" "$PARTIAL_REPORT" >"$PARTIAL_LOG" 2>&1; then
  echo 'partial-trace render-packet admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'record count 7 is not 8' "$PARTIAL_LOG"
test ! -e "$PARTIAL_REPORT"

manifest_after="$(sha256_file "$MANIFEST")"
[[ "$manifest_before" == "$manifest_after" ]]
git -c core.fsmonitor=false diff --check
report_sha256="$(sha256_file "$REPORT")"
printf '%s\n' \
  "SM64 Modern render-packet route admission smoke passed run=$RUN_ROOT" \
  "shard=$ROUTE_ID source=oracle_hook|render_packet input_seed=0x2cc8dc5ab4228549 save_seed=0xbb82f7313b3d4f96" \
  'manifest=isolated route-shards.tsv manifest_rows=7420 target_status=planned' \
  'records=8 ticks=1,2 ids=2,1,3,4,2,1,3,4 domain=11 kind=7 value_counts=5,8,5,4,5,8,5,4' \
  'debug_swift_asan_release_byte_match=1 tamper_rejected=1 single_trace_rejected=1 partial_trace_rejected=1 persistent_rerun_rejected=1' \
  'gpu_capture=separate pixel_acceptance=unverified visual_acceptance=unverified fixture_only=0 manifest_mutated=0 ledger_mutated=0 history_mutated=0' \
  "report_sha256=$report_sha256 report_rows=7420 passed_rows=1 planned_rows=7419 manifest_sha256=$manifest_after"
