#!/usr/bin/env bash
set -euo pipefail

# Phase 85aj admits only the canonical oracle_hook|effects row from the
# independent C/Swift/ASan/Release fixed-width receipt pair.  The generated
# manifest is isolated immutable input and this gate writes one fresh report;
# it does not mutate the historical manifest or cumulative ledger and makes
# no device, haptic, audible, visual, or human effects-acceptance claim.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-effects-receipt-route-admission"
PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-effects-receipt-route-pair"
mkdir -p "$BUILD_ROOT"
RUN_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
TOOL_ROOT="$RUN_ROOT/tool"
MANIFEST_ROOT="$RUN_ROOT/manifest"
MANIFEST="$MANIFEST_ROOT/route-shards.tsv"
MANIFEST_SECOND="$MANIFEST_ROOT/route-shards-second.tsv"
INVENTORY="$MANIFEST_ROOT/reachability.tsv"
ADMISSION_TOOL="$TOOL_ROOT/sm64-effects-receipt-route-admit"
REPORT="$RUN_ROOT/effects-receipt-isolated.tsv"
mkdir -p "$TOOL_ROOT/module-cache" "$MANIFEST_ROOT"

PAIR_LOG="$RUN_ROOT/pair.log"
MANIFEST_LOG="$RUN_ROOT/manifest.log"
ADMISSION_LOG="$RUN_ROOT/admission.log"
RERUN_LOG="$RUN_ROOT/rerun.log"
SINGLE_LOG="$RUN_ROOT/single-evidence.log"
SINGLE_RECEIPT_LOG="$RUN_ROOT/single-receipt-evidence.log"
PARTIAL_LOG="$RUN_ROOT/partial-evidence.log"

ROUTE_ID=0x3951f0333dc3c5da
C_TRACE="$PAIR_ROOT/effects-c.trace"
SWIFT_TRACE="$PAIR_ROOT/effects-swift.trace"
ASAN_TRACE="$PAIR_ROOT/effects-c-asan.trace"
RELEASE_TRACE="$PAIR_ROOT/effects-c-release.trace"
TAMPERED_TRACE="$PAIR_ROOT/effects-tampered.trace"
C_RECEIPTS="$PAIR_ROOT/effects-c.receipts"
ASAN_RECEIPTS="$PAIR_ROOT/effects-c-asan.receipts"
RELEASE_RECEIPTS="$PAIR_ROOT/effects-c-release.receipts"
TAMPERED_RECEIPTS="$PAIR_ROOT/effects-tampered.receipts"
DEBUG_LOG="$PAIR_ROOT/debug.log"
SWIFT_LOG="$PAIR_ROOT/swift.log"
ASAN_LOG="$PAIR_ROOT/asan.log"
RELEASE_LOG="$PAIR_ROOT/release.log"

sha256_file() { shasum -a 256 "$1" | awk '{ print $1 }'; }

bash -n "$PROJECT_ROOT/script/test_effects_receipt_route_pair.sh"
bash "$PROJECT_ROOT/script/test_effects_receipt_route_pair.sh" >"$PAIR_LOG" 2>&1
for artifact in "$C_TRACE" "$SWIFT_TRACE" "$ASAN_TRACE" "$RELEASE_TRACE" \
  "$TAMPERED_TRACE" "$C_RECEIPTS" "$ASAN_RECEIPTS" "$RELEASE_RECEIPTS" \
  "$TAMPERED_RECEIPTS" "$DEBUG_LOG" "$SWIFT_LOG" "$ASAN_LOG" "$RELEASE_LOG"; do
  test -s "$artifact"
done
grep -Fq 'effects_receipt_route_pair_swift_passed=1 debug_pair=1 tamper_rejected=1' "$PAIR_LOG"
grep -Fq 'effects_receipt_route_sanitizer_passed=1 debug_asan_pair_match=1' "$PAIR_LOG"
grep -Fq 'effects_receipt_route_optimized_passed=1 debug_release_pair_match=1' "$PAIR_LOG"
grep -Fq 'admission=0 ledger_mutation=0 fixture_only=0' "$PAIR_LOG"

# Generate the canonical manifest twice under this isolated run root.  No
# checked-in manifest, cumulative report, or historical ledger is an input.
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
  $1 == id && $2 == "oracle_hook" && $3 == "effects" &&
  $4 == "src/pc/sm64_modern_gameplay_parity.c" &&
  $5 == "0x5ab408e5e404b1d6" && $6 == "0x5543fe1df61f7e9f" &&
  $7 == "effects" && $8 == "planned" { found++ }
  END { exit(found == 1 ? 0 : 1) }
' "$MANIFEST"
manifest_before="$(sha256_file "$MANIFEST")"

# Compile the independent validator under the strict Swift 6 concurrency gate.
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64EffectsReceiptRouteAdmissionTool.swift" \
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
grep -Fq 'SM64 effects receipt route isolated admission passed' <<<"$admission_output"
grep -Fq 'shard=0x3951f0333dc3c5da records=58 ticks=2,3 domain=12 kind=4 ids=1:5,3:2,4:49,5:2' <<<"$admission_output"
grep -Fq 'manifest_rows=7420 report_rows=7420 passed_rows=1 planned_rows=7419' <<<"$admission_output"
grep -Fq 'c_swift_asan_release_byte_match=1 receipts_c_asan_release_byte_match=1' <<<"$admission_output"
grep -Fq 'canonical_hash_tamper_rejected=1 receipt_tamper_rejected=1' <<<"$admission_output"
grep -Fq 'effects_source_admitted=1 device_effects=unverified human_acceptance=unverified' <<<"$admission_output"
grep -Fq 'fixture_only=0 manifest_mutated=0 ledger_mutated=0 history_mutated=0 rerun_fence=1' <<<"$admission_output"
test "$(wc -l <"$REPORT" | tr -d '[:space:]')" -eq 7420
test "$(awk -F'|' -v id="$ROUTE_ID" '$1 == id && $2 == "passed" { count++ } END { print count + 0 }' "$REPORT")" -eq 1
test "$(awk -F'|' '$2 == "planned" { count++ } END { print count + 0 }' "$REPORT")" -eq 7419
target_row="$(awk -F'|' -v id="$ROUTE_ID" '$1 == id { print; exit }' "$REPORT")"
[[ "$target_row" == "$ROUTE_ID|passed|58|58|58|" ]]

# The report itself is a persistent rerun fence and must stay byte-identical.
report_before="$(sha256_file "$REPORT")"
if run_admit "$REPORT" >"$RERUN_LOG" 2>&1; then
  echo 'effects receipt isolated admission rerun unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'already exists' "$RERUN_LOG"
report_after_rerun="$(sha256_file "$REPORT")"
[[ "$report_before" == "$report_after_rerun" ]]

# Reusing a single trace or receipt file is not independent evidence.
SINGLE_REPORT="$RUN_ROOT/single-evidence.tsv"
if run_admit "$SINGLE_REPORT" "$C_TRACE" "$C_TRACE" >"$SINGLE_LOG" 2>&1; then
  echo 'single-artifact effects admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'distinct artifacts' "$SINGLE_LOG"
test ! -e "$SINGLE_REPORT"

SINGLE_RECEIPT_REPORT="$RUN_ROOT/single-receipt-evidence.tsv"
if run_admit "$SINGLE_RECEIPT_REPORT" "$C_TRACE" "$SWIFT_TRACE" \
  "$C_RECEIPTS" "$C_RECEIPTS" >"$SINGLE_RECEIPT_LOG" 2>&1; then
  echo 'single-receipt effects admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'distinct artifacts' "$SINGLE_RECEIPT_LOG"
test ! -e "$SINGLE_RECEIPT_REPORT"

# A 57-record prefix is not the exact canonical effect window.
PARTIAL_TRACE="$RUN_ROOT/partial-c.trace"
PARTIAL_REPORT="$RUN_ROOT/partial-evidence.tsv"
head -c $((72 + 57 * 128)) "$C_TRACE" >"$PARTIAL_TRACE"
if run_admit "$PARTIAL_REPORT" "$PARTIAL_TRACE" "$SWIFT_TRACE" \
  >"$PARTIAL_LOG" 2>&1; then
  echo 'partial-trace effects admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'record count 57 is not 58' "$PARTIAL_LOG"
test ! -e "$PARTIAL_REPORT"

manifest_after="$(sha256_file "$MANIFEST")"
[[ "$manifest_before" == "$manifest_after" ]]
git -c core.fsmonitor=false diff --check
report_sha256="$(sha256_file "$REPORT")"
printf '%s\n' \
  "SM64 Modern effects receipt route admission smoke passed run=$RUN_ROOT" \
  "shard=$ROUTE_ID source=oracle_hook|effects input_seed=0x5ab408e5e404b1d6 save_seed=0x5543fe1df61f7e9f" \
  'manifest=isolated route-shards.tsv manifest_rows=7420 target_status=planned' \
  'records=58 ticks=2,3 ids=1:5,3:2,4:49,5:2 domain=12 kind=4 canonical_order=1' \
  'build=0x82f629ab59f01865 content=0x2c1bd3b62dcf5a74 timebase=0xccc19787cd09f0c2 config=0xc120d19fb080bb1f save=0x87475c085edb9309 coverage=0x12756c2de89cfbc4' \
  'debug_swift_asan_release_byte_match=1 receipts_c_asan_release_byte_match=1 canonical_hash_tamper_rejected=1 receipt_tamper_rejected=1' \
  'single_trace_rejected=1 single_receipt_rejected=1 partial_trace_rejected=1 persistent_rerun_rejected=1' \
  'effects_source_admitted=1 device_effects=unverified human_acceptance=unverified fixture_only=0 manifest_mutated=0 ledger_mutated=0 history_mutated=0' \
  "report_sha256=$report_sha256 report_rows=7420 passed_rows=1 planned_rows=7419 manifest_sha256=$manifest_after"
