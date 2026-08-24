#!/usr/bin/env bash
set -euo pipefail

# Phase 85ad admits only the canonical oracle_hook|audio_pcm row from the
# independent C/Swift/ASan/Release PCM receipt pair. The generated manifest is
# immutable input and this phase writes one fresh isolated report. The receipt
# is a fixed-width pre-device value record: effects remain unadmitted and this
# gate makes no audible, device, or full-PCM parity claim.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-audio-pcm-route-admission"
PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-audio-pcm-receipt-route-pair"
mkdir -p "$BUILD_ROOT"
RUN_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
TOOL_ROOT="$RUN_ROOT/tool"
MANIFEST_ROOT="$RUN_ROOT/manifest"
MANIFEST="$MANIFEST_ROOT/route-shards.tsv"
MANIFEST_SECOND="$MANIFEST_ROOT/route-shards-second.tsv"
INVENTORY="$MANIFEST_ROOT/reachability.tsv"
ADMISSION_TOOL="$TOOL_ROOT/sm64-audio-pcm-route-admit"
REPORT="$RUN_ROOT/audio-pcm-isolated.tsv"
mkdir -p "$TOOL_ROOT/module-cache" "$MANIFEST_ROOT"

PAIR_LOG="$RUN_ROOT/pair.log"
MANIFEST_LOG="$RUN_ROOT/manifest.log"
ADMISSION_LOG="$RUN_ROOT/admission.log"
RERUN_LOG="$RUN_ROOT/rerun.log"
SINGLE_LOG="$RUN_ROOT/single-evidence.log"
SINGLE_RECEIPT_LOG="$RUN_ROOT/single-receipt-evidence.log"
PARTIAL_LOG="$RUN_ROOT/partial-evidence.log"

ROUTE_ID=0x4aa75cc09d180fce
C_TRACE="$PAIR_ROOT/audio-pcm-debug-only.trace"
SWIFT_TRACE="$PAIR_ROOT/audio-pcm-swift.trace"
ASAN_TRACE="$PAIR_ROOT/audio-pcm-asan-only.trace"
RELEASE_TRACE="$PAIR_ROOT/audio-pcm-release-only.trace"
TAMPERED_TRACE="$PAIR_ROOT/audio-pcm-tampered.trace"
C_RECEIPTS="$PAIR_ROOT/audio-pcm-debug.receipts"
ASAN_RECEIPTS="$PAIR_ROOT/audio-pcm-asan.receipts"
RELEASE_RECEIPTS="$PAIR_ROOT/audio-pcm-release.receipts"
TAMPERED_RECEIPTS="$PAIR_ROOT/audio-pcm-tampered.receipts"
DEBUG_LOG="$PAIR_ROOT/debug.log"
SWIFT_LOG="$PAIR_ROOT/swift.log"
ASAN_LOG="$PAIR_ROOT/asan.log"
RELEASE_LOG="$PAIR_ROOT/release.log"

sha256_file() { shasum -a 256 "$1" | awk '{ print $1 }'; }

bash -n "$PROJECT_ROOT/script/test_audio_pcm_receipt_route_pair.sh"
bash "$PROJECT_ROOT/script/test_audio_pcm_receipt_route_pair.sh" >"$PAIR_LOG" 2>&1
for artifact in "$C_TRACE" "$SWIFT_TRACE" "$ASAN_TRACE" "$RELEASE_TRACE" \
  "$TAMPERED_TRACE" "$C_RECEIPTS" "$ASAN_RECEIPTS" "$RELEASE_RECEIPTS" \
  "$TAMPERED_RECEIPTS" "$DEBUG_LOG" "$SWIFT_LOG" "$ASAN_LOG" "$RELEASE_LOG"; do
  test -s "$artifact"
done
grep -Fq 'audio_pcm_receipt_route_pair_swift_passed=1 debug_pair=1 tamper_rejected=1' "$PAIR_LOG"
grep -Fq 'audio_pcm_receipt_route_sanitizer_passed=1 debug_asan_pair_match=1' "$PAIR_LOG"
grep -Fq 'audio_pcm_receipt_route_optimized_passed=1 debug_release_pair_match=1' "$PAIR_LOG"
grep -Fq 'admission=0 ledger_mutation=0 fixture_only=0' "$PAIR_LOG"

# Generate the authoritative manifest twice under this isolated run root.
# Existing build manifests and cumulative reports are never admission inputs.
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
"$MANIFEST_TOOL" --inventory "$INVENTORY" --output "$MANIFEST_SECOND" >>"$MANIFEST_LOG"
cmp -s "$MANIFEST" "$MANIFEST_SECOND"
test "$(awk -F'|' '$0 !~ /^#/ && NF { count++ } END { print count + 0 }' "$INVENTORY")" -eq 7420
test "$(awk -F'|' '$0 !~ /^#/ && NF { count++ } END { print count + 0 }' "$MANIFEST")" -eq 7420
awk -F'|' -v id="$ROUTE_ID" '
  $1 == id && $2 == "oracle_hook" && $3 == "audio_pcm" &&
  $4 == "src/pc/sm64_modern_gameplay_parity.c" &&
  $5 == "0xc3e64e9c0ec5da8a" && $6 == "0x0ecb81238dddc733" &&
  $7 == "audio_pcm" && $8 == "planned" { found++ }
  END { exit(found == 1 ? 0 : 1) }
' "$MANIFEST"
manifest_before="$(sha256_file "$MANIFEST")"

# Compile the canonical validator independently under strict Swift 6.
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64AudioPCMRouteAdmissionTool.swift" \
  -o "$ADMISSION_TOOL"

run_admit() {
  local report="$1"
  local c_trace="$C_TRACE"
  local swift_trace="$SWIFT_TRACE"
  local c_receipts="$C_RECEIPTS"
  local asan_receipts="$ASAN_RECEIPTS"
  if [[ "$#" -ge 2 ]]; then c_trace="$2"; fi
  if [[ "$#" -ge 3 ]]; then swift_trace="$3"; fi
  if [[ "$#" -ge 4 ]]; then c_receipts="$4"; fi
  if [[ "$#" -ge 5 ]]; then asan_receipts="$5"; fi
  "$ADMISSION_TOOL" \
    --manifest "$MANIFEST" \
    --c-trace "$c_trace" \
    --swift-trace "$swift_trace" \
    --asan-trace "$ASAN_TRACE" \
    --release-trace "$RELEASE_TRACE" \
    --tampered-trace "$TAMPERED_TRACE" \
    --c-receipts "$c_receipts" \
    --asan-receipts "$asan_receipts" \
    --release-receipts "$RELEASE_RECEIPTS" \
    --tampered-receipts "$TAMPERED_RECEIPTS" \
    --debug-log "$DEBUG_LOG" \
    --swift-log "$SWIFT_LOG" \
    --asan-log "$ASAN_LOG" \
    --release-log "$RELEASE_LOG" \
    --report "$report"
}

admission_output="$(run_admit "$REPORT")"
printf '%s\n' "$admission_output" | tee "$ADMISSION_LOG"
grep -Fq 'SM64 audio_pcm route isolated admission passed' <<<"$admission_output"
grep -Fq 'shard=0x4aa75cc09d180fce records=2 ticks=2,3 domain=9 kind=5' <<<"$admission_output"
grep -Fq 'manifest_rows=7420 report_rows=7420 passed_rows=1 planned_rows=7419' <<<"$admission_output"
grep -Fq 'c_swift_asan_release_byte_match=1 receipts_c_asan_release_byte_match=1' <<<"$admission_output"
grep -Fq 'canonical_hash_tamper_rejected=1 receipt_tamper_rejected=1' <<<"$admission_output"
grep -Fq 'effects_admitted=0 audible_acceptance=unverified device_pcm=unverified' <<<"$admission_output"
grep -Fq 'fixture_only=0 manifest_mutated=0 ledger_mutated=0 history_mutated=0 rerun_fence=1' <<<"$admission_output"
test "$(wc -l <"$REPORT" | tr -d '[:space:]')" -eq 7420
test "$(awk -F'|' -v id="$ROUTE_ID" '$1 == id && $2 == "passed" { count++ } END { print count + 0 }' "$REPORT")" -eq 1
test "$(awk -F'|' '$2 == "planned" { count++ } END { print count + 0 }' "$REPORT")" -eq 7419
target_row="$(awk -F'|' -v id="$ROUTE_ID" '$1 == id { print; exit }' "$REPORT")"
[[ "$target_row" == "$ROUTE_ID|passed|2|2|2|" ]]

# The report itself is a persistent rerun fence and must stay byte-identical.
report_before="$(sha256_file "$REPORT")"
if run_admit "$REPORT" >"$RERUN_LOG" 2>&1; then
  echo 'audio PCM isolated admission rerun unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'already exists' "$RERUN_LOG"
report_after_rerun="$(sha256_file "$REPORT")"
[[ "$report_before" == "$report_after_rerun" ]]

# Reusing one trace or receipt artifact is not independent evidence.
SINGLE_REPORT="$RUN_ROOT/single-evidence.tsv"
if run_admit "$SINGLE_REPORT" "$C_TRACE" "$C_TRACE" >"$SINGLE_LOG" 2>&1; then
  echo 'single-artifact PCM admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'distinct artifacts' "$SINGLE_LOG"
test ! -e "$SINGLE_REPORT"

SINGLE_RECEIPT_REPORT="$RUN_ROOT/single-receipt-evidence.tsv"
if run_admit "$SINGLE_RECEIPT_REPORT" "$C_TRACE" "$SWIFT_TRACE" \
  "$C_RECEIPTS" "$C_RECEIPTS" >"$SINGLE_RECEIPT_LOG" 2>&1; then
  echo 'single-receipt PCM admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'distinct artifacts' "$SINGLE_RECEIPT_LOG"
test ! -e "$SINGLE_RECEIPT_REPORT"

# A one-record trace must fail the exact two-record gate with no partial report.
PARTIAL_TRACE="$RUN_ROOT/partial-c.trace"
PARTIAL_REPORT="$RUN_ROOT/partial-evidence.tsv"
head -c $((72 + 1 * 128)) "$C_TRACE" >"$PARTIAL_TRACE"
if run_admit "$PARTIAL_REPORT" "$PARTIAL_TRACE" "$SWIFT_TRACE" \
  >"$PARTIAL_LOG" 2>&1; then
  echo 'partial-trace PCM admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'record count 1 is not 2' "$PARTIAL_LOG"
test ! -e "$PARTIAL_REPORT"

manifest_after="$(sha256_file "$MANIFEST")"
[[ "$manifest_before" == "$manifest_after" ]]
git -c core.fsmonitor=false diff --check
report_sha256="$(sha256_file "$REPORT")"
printf '%s\n' \
  "SM64 Modern audio PCM route admission smoke passed run=$RUN_ROOT" \
  "shard=$ROUTE_ID source=oracle_hook|audio_pcm input_seed=0xc3e64e9c0ec5da8a save_seed=0x0ecb81238dddc733" \
  'manifest=isolated route-shards.tsv manifest_rows=7420 target_status=planned' \
  'records=2 ticks=2,3 ids=5,5 sequences=4,0 domain=9 kind=5 value_counts=5,5 frames=544,544' \
  'debug_swift_asan_release_byte_match=1 receipts_c_asan_release_byte_match=1 canonical_hash_tamper_rejected=1 receipt_tamper_rejected=1' \
  'single_trace_rejected=1 single_receipt_rejected=1 partial_trace_rejected=1 persistent_rerun_rejected=1' \
  'effects_admitted=0 audible_acceptance=unverified device_pcm=unverified fixture_only=0 manifest_mutated=0 ledger_mutated=0 history_mutated=0' \
  "report_sha256=$report_sha256 report_rows=7420 passed_rows=1 planned_rows=7419 manifest_sha256=$manifest_after"
