#!/usr/bin/env bash
set -euo pipefail

# Phase 85ag admits only the generated oracle_hook|interaction_state row from
# independent C/Swift/ASan/Release schema-4 traces. The interaction snapshot
# remains C-owned value evidence: collision authority and effects stay
# unadmitted. The generated manifest is immutable input and this script writes
# only a fresh isolated report under its run directory.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-interaction-state-route-admission"
PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-interaction-state-route-pair"
mkdir -p "$BUILD_ROOT"
RUN_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
TOOL_ROOT="$RUN_ROOT/tool"
MANIFEST_ROOT="$RUN_ROOT/manifest"
MANIFEST="$MANIFEST_ROOT/route-shards.tsv"
MANIFEST_SECOND="$MANIFEST_ROOT/route-shards-second.tsv"
INVENTORY="$MANIFEST_ROOT/reachability.tsv"
ADMISSION_TOOL="$TOOL_ROOT/sm64-interaction-state-route-admit"
REPORT="$RUN_ROOT/interaction-state-isolated.tsv"
mkdir -p "$TOOL_ROOT/module-cache" "$MANIFEST_ROOT"

PAIR_LOG="$RUN_ROOT/pair.log"
MANIFEST_LOG="$RUN_ROOT/manifest.log"
ADMISSION_LOG="$RUN_ROOT/admission.log"
RERUN_LOG="$RUN_ROOT/rerun.log"
SINGLE_LOG="$RUN_ROOT/single-evidence.log"
PARTIAL_LOG="$RUN_ROOT/partial-evidence.log"

ROUTE_ID=0x3e1cdaca08b21f54
C_TRACE="$PAIR_ROOT/interaction-state-c.trace"
SWIFT_TRACE="$PAIR_ROOT/interaction-state-swift.trace"
ASAN_TRACE="$PAIR_ROOT/interaction-state-c-asan.trace"
RELEASE_TRACE="$PAIR_ROOT/interaction-state-c-release.trace"
TAMPERED_TRACE="$PAIR_ROOT/interaction-state-swift.tampered.trace"
DEBUG_LOG="$PAIR_ROOT/debug.log"
SWIFT_LOG="$PAIR_ROOT/swift.log"
ASAN_LOG="$PAIR_ROOT/asan.log"
RELEASE_LOG="$PAIR_ROOT/release.log"

sha256_file() { shasum -a 256 "$1" | awk '{ print $1 }'; }

bash "$PROJECT_ROOT/script/test_interaction_state_route_pair.sh" >"$PAIR_LOG" 2>&1
for artifact in "$C_TRACE" "$SWIFT_TRACE" "$ASAN_TRACE" "$RELEASE_TRACE" \
  "$TAMPERED_TRACE" "$DEBUG_LOG" "$SWIFT_LOG" "$ASAN_LOG" "$RELEASE_LOG"; do
  test -s "$artifact"
done
grep -Fq 'SM64 Modern interaction-state route pair smoke passed exact_pair=1 tamper_rejected=1' "$PAIR_LOG"
grep -Fq 'interaction_state_route_sanitizer_passed=1 debug_asan_trace_match=1' "$PAIR_LOG"
grep -Fq 'interaction_state_route_optimized_passed=1 debug_release_trace_match=1' "$PAIR_LOG"
grep -Fq 'admission=0 ledger_mutation=0 fixture_only=0 effects_admitted=0' "$PAIR_LOG"

# Generate the canonical manifest twice under an isolated run root. No
# existing manifest, cumulative ledger, or route history is an input.
REACHABILITY_TOOL="$TOOL_ROOT/sm64-oracle-reachability"
MANIFEST_TOOL="$TOOL_ROOT/sm64-route-shards"
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
"$REACHABILITY_TOOL" --root "$PROJECT_ROOT" --output "$INVENTORY" >"$MANIFEST_LOG"
"$MANIFEST_TOOL" --inventory "$INVENTORY" --output "$MANIFEST" >>"$MANIFEST_LOG"
"$MANIFEST_TOOL" --inventory "$INVENTORY" --output "$MANIFEST_SECOND" >>"$MANIFEST_LOG"
cmp -s "$MANIFEST" "$MANIFEST_SECOND"
test "$(awk -F'|' '$0 !~ /^#/ && NF { count++ } END { print count + 0 }' "$INVENTORY")" -eq 7420
test "$(awk -F'|' '$0 !~ /^#/ && NF { count++ } END { print count + 0 }' "$MANIFEST")" -eq 7420
awk -F'|' -v id="$ROUTE_ID" '
  $1 == id && $2 == "oracle_hook" && $3 == "interaction_state" &&
  $4 == "src/pc/sm64_modern_gameplay_parity.c" &&
  $5 == "0xee187b29391cf62c" && $6 == "0x7bc40eed25255955" &&
  $7 == "interaction_state" && $8 == "planned" { found++ }
  END { exit(found == 1 ? 0 : 1) }
' "$MANIFEST"
manifest_before="$(sha256_file "$MANIFEST")"

# Compile the focused validator with the strict Swift 6 concurrency gate.
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64InteractionStateRouteAdmissionTool.swift" \
  -o "$ADMISSION_TOOL"

run_admit() {
  local report="$1"
  local c_trace="$C_TRACE"
  local swift_trace="$SWIFT_TRACE"
  if [[ "$#" -ge 2 ]]; then c_trace="$2"; fi
  if [[ "$#" -ge 3 ]]; then swift_trace="$3"; fi
  "$ADMISSION_TOOL" \
    --manifest "$MANIFEST" \
    --c-trace "$c_trace" \
    --swift-trace "$swift_trace" \
    --asan-trace "$ASAN_TRACE" \
    --release-trace "$RELEASE_TRACE" \
    --tampered-trace "$TAMPERED_TRACE" \
    --debug-log "$DEBUG_LOG" \
    --swift-log "$SWIFT_LOG" \
    --asan-log "$ASAN_LOG" \
    --release-log "$RELEASE_LOG" \
    --report "$report"
}

admission_output="$(run_admit "$REPORT")"
printf '%s\n' "$admission_output" | tee "$ADMISSION_LOG"
grep -Fq 'SM64 interaction_state route isolated admission passed' <<<"$admission_output"
grep -Fq 'shard=0x3e1cdaca08b21f54 records=14 ticks=2,3 domain=4 kind=1 ids=200..206' <<<"$admission_output"
grep -Fq 'manifest_rows=7420 report_rows=7420 passed_rows=1 planned_rows=7419' <<<"$admission_output"
grep -Fq 'c_swift_asan_release_byte_match=1 canonical_hash_tamper_rejected=1' <<<"$admission_output"
grep -Fq 'collision_authority=c effects_admitted=0 fixture_only=0 manifest_mutated=0 ledger_mutated=0 history_mutated=0 rerun_fence=1' <<<"$admission_output"
test "$(wc -l <"$REPORT" | tr -d '[:space:]')" -eq 7420
test "$(awk -F'|' -v id="$ROUTE_ID" '$1 == id && $2 == "passed" { count++ } END { print count + 0 }' "$REPORT")" -eq 1
test "$(awk -F'|' '$2 == "planned" { count++ } END { print count + 0 }' "$REPORT")" -eq 7419
target_row="$(awk -F'|' -v id="$ROUTE_ID" '$1 == id { print; exit }' "$REPORT")"
[[ "$target_row" == "$ROUTE_ID|passed|14|14|14|" ]]

# The report is a persistent rerun fence. It must not be overwritten or
# regenerated when the same evidence is presented again.
report_before="$(sha256_file "$REPORT")"
if run_admit "$REPORT" >"$RERUN_LOG" 2>&1; then
  echo 'interaction-state isolated admission rerun unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'already exists' "$RERUN_LOG"
report_after_rerun="$(sha256_file "$REPORT")"
[[ "$report_before" == "$report_after_rerun" ]]

# Reusing one trace as both independent C and Swift evidence must fail before
# any report is written.
SINGLE_REPORT="$RUN_ROOT/single-evidence.tsv"
if run_admit "$SINGLE_REPORT" "$C_TRACE" "$C_TRACE" >"$SINGLE_LOG" 2>&1; then
  echo 'single-artifact interaction-state admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'distinct artifacts' "$SINGLE_LOG"
test ! -e "$SINGLE_REPORT"

# A 13-record prefix is not the exact two-tick/14-record contract.
PARTIAL_TRACE="$RUN_ROOT/partial-c.trace"
PARTIAL_REPORT="$RUN_ROOT/partial-evidence.tsv"
head -c $((72 + 13 * 128)) "$C_TRACE" >"$PARTIAL_TRACE"
if run_admit "$PARTIAL_REPORT" "$PARTIAL_TRACE" "$SWIFT_TRACE" >"$PARTIAL_LOG" 2>&1; then
  echo 'partial-trace interaction-state admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'record count 13 is not 14' "$PARTIAL_LOG"
test ! -e "$PARTIAL_REPORT"

manifest_after="$(sha256_file "$MANIFEST")"
[[ "$manifest_before" == "$manifest_after" ]]
git -c core.fsmonitor=false diff --check
report_sha256="$(sha256_file "$REPORT")"
printf '%s\n' \
  "SM64 Modern interaction-state route admission smoke passed run=$RUN_ROOT" \
  "shard=$ROUTE_ID source=oracle_hook|interaction_state input_seed=0xee187b29391cf62c save_seed=0x7bc40eed25255955" \
  'manifest=isolated route-shards.tsv manifest_rows=7420 target_status=planned' \
  'records=14 ticks=2,3 ids=200..206 domain=4 kind=1 value_counts=1x14' \
  'build=0x9527779bf7d0d65b content=0xb5f450d6340f1a68 timebase=0xccc19787cd09f0c2 config=0xfa26dd46235668c4 save=0x6e3cfef5f30ab26a coverage=0x7975fa8afdbc6bcf' \
  'debug_swift_asan_release_byte_match=1 canonical_hash_tamper_rejected=1' \
  'single_trace_rejected=1 partial_trace_rejected=1 persistent_rerun_rejected=1' \
  'collision_authority=c effects_admitted=0 fixture_only=0 manifest_mutated=0 ledger_mutated=0 history_mutated=0' \
  "report_sha256=$report_sha256 report_rows=7420 passed_rows=1 planned_rows=7419 manifest_sha256=$manifest_after"
