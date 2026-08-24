#!/usr/bin/env bash
set -euo pipefail

# Phase 85am admits exactly one source-backed save_mutation row.  The route
# pair runs first against fresh, phase-local save roots; admission then consumes
# only independent fixed-width artifacts and a newly generated immutable
# manifest.  No checked-in manifest, cumulative ledger, route history, or user
# save directory is ever an output of this gate.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-save-mutation-route-admission"
PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-save-mutation-route-pair"
mkdir -p "$BUILD_ROOT"
RUN_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
TOOL_ROOT="$RUN_ROOT/tool"
MANIFEST_ROOT="$RUN_ROOT/manifest"
MANIFEST="$MANIFEST_ROOT/route-shards.tsv"
MANIFEST_SECOND="$MANIFEST_ROOT/route-shards-second.tsv"
INVENTORY="$MANIFEST_ROOT/reachability.tsv"
ADMISSION_TOOL="$TOOL_ROOT/sm64-save-mutation-route-admit"
REPORT="$RUN_ROOT/save-mutation-isolated.tsv"
mkdir -p "$TOOL_ROOT/module-cache" "$MANIFEST_ROOT"

PAIR_LOG="$RUN_ROOT/pair.log"
MANIFEST_LOG="$RUN_ROOT/manifest.log"
ADMISSION_LOG="$RUN_ROOT/admission.log"
RERUN_LOG="$RUN_ROOT/rerun.log"
SINGLE_TRACE_LOG="$RUN_ROOT/single-trace.log"
SINGLE_SIDECAR_LOG="$RUN_ROOT/single-sidecar.log"
PARTIAL_LOG="$RUN_ROOT/partial.log"
ROUTE_ID=0x022fbda0ff7f2dd1

sha256_file() { shasum -a 256 "$1" | awk '{ print $1 }'; }

# Produce fresh C/Swift/ASan/Release traces, raw save images, and global
# snapshots.  The pair itself is deliberately admission=0 and ledger-free.
bash -n "$PROJECT_ROOT/script/test_save_mutation_route_pair.sh"
bash "$PROJECT_ROOT/script/test_save_mutation_route_pair.sh" >"$PAIR_LOG" 2>&1
grep -Fq 'SM64 Modern save-mutation route pair smoke passed exact_pair=1 tamper_rejected=1' "$PAIR_LOG"
grep -Fq 'native_persistence=menu_write_load_reload isolated_save_root=1' "$PAIR_LOG"
grep -Fq 'expected_domains=global_state,save_bytes' "$PAIR_LOG"
grep -Fq 'admission=0 ledger_mutation=0 fixture_only=0' "$PAIR_LOG"

# The pair script intentionally keeps evidence in a fresh mktemp run folder;
# select the newest one without relying on a fixed temporary suffix.
PAIR_RUN="$(
  find "$PAIR_ROOT" -maxdepth 1 -type d -name 'run.*' -print0 |
    while IFS= read -r -d '' directory; do
      stat -f '%m %N' "$directory"
    done |
    sort -nr |
    head -n 1 |
    cut -d' ' -f2-
)"
test -n "$PAIR_RUN"

for artifact in \
  "$PAIR_RUN/save-mutation-c.trace" \
  "$PAIR_RUN/save-mutation-swift.trace" \
  "$PAIR_RUN/save-mutation-c-asan.trace" \
  "$PAIR_RUN/save-mutation-c-release.trace" \
  "$PAIR_RUN/save-mutation-swift.tampered.trace" \
  "$PAIR_RUN/save-mutation-c.sidecar" \
  "$PAIR_RUN/save-mutation-c-asan.sidecar" \
  "$PAIR_RUN/save-mutation-c-release.sidecar" \
  "$PAIR_RUN/save-mutation-c.snapshots" \
  "$PAIR_RUN/save-mutation-c-asan.snapshots" \
  "$PAIR_RUN/save-mutation-c-release.snapshots" \
  "$PAIR_RUN/debug.log" "$PAIR_RUN/swift.log" "$PAIR_RUN/asan.log" "$PAIR_RUN/release.log"; do
  test -s "$artifact"
done

C_TRACE="$PAIR_RUN/save-mutation-c.trace"
SWIFT_TRACE="$PAIR_RUN/save-mutation-swift.trace"
ASAN_TRACE="$PAIR_RUN/save-mutation-c-asan.trace"
RELEASE_TRACE="$PAIR_RUN/save-mutation-c-release.trace"
TAMPERED_TRACE="$PAIR_RUN/save-mutation-swift.tampered.trace"
C_SIDECAR="$PAIR_RUN/save-mutation-c.sidecar"
ASAN_SIDECAR="$PAIR_RUN/save-mutation-c-asan.sidecar"
RELEASE_SIDECAR="$PAIR_RUN/save-mutation-c-release.sidecar"
C_SNAPSHOTS="$PAIR_RUN/save-mutation-c.snapshots"
ASAN_SNAPSHOTS="$PAIR_RUN/save-mutation-c-asan.snapshots"
RELEASE_SNAPSHOTS="$PAIR_RUN/save-mutation-c-release.snapshots"
DEBUG_LOG="$PAIR_RUN/debug.log"
SWIFT_LOG="$PAIR_RUN/swift.log"
ASAN_LOG="$PAIR_RUN/asan.log"
RELEASE_LOG="$PAIR_RUN/release.log"

# Regenerate both manifest inputs under the isolated run root.  This verifies
# that target identity and both seeds are resolved from current source, not
# copied from a prior report or ledger.
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
  $1 == id && $2 == "save_mutation" && $3 == "save_file_set_sound_mode" &&
  $4 == "src/game/save_file.c" &&
  $5 == "0x0c83cf28590d4915" && $6 == "0xaaacc83cb4eb46a2" &&
  $7 == "global_state,save_bytes" && $8 == "planned" { found++ }
  END { exit(found == 1 ? 0 : 1) }
' "$MANIFEST"
MANIFEST_BEFORE="$(sha256_file "$MANIFEST")"

# Compile the independent admission validator under strict Swift 6.
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64SaveMutationRouteAdmissionTool.swift" \
  -o "$ADMISSION_TOOL"

run_admit() {
  local report="$1"
  local c_trace="${2:-$C_TRACE}"
  local swift_trace="${3:-$SWIFT_TRACE}"
  local c_sidecar="${4:-$C_SIDECAR}"
  local asan_sidecar="${5:-$ASAN_SIDECAR}"
  "$ADMISSION_TOOL" \
    --manifest "$MANIFEST" \
    --c-trace "$c_trace" --swift-trace "$swift_trace" \
    --asan-trace "$ASAN_TRACE" --release-trace "$RELEASE_TRACE" \
    --tampered-trace "$TAMPERED_TRACE" \
    --c-sidecar "$c_sidecar" --asan-sidecar "$asan_sidecar" \
    --release-sidecar "$RELEASE_SIDECAR" \
    --c-snapshots "$C_SNAPSHOTS" --asan-snapshots "$ASAN_SNAPSHOTS" \
    --release-snapshots "$RELEASE_SNAPSHOTS" \
    --debug-log "$DEBUG_LOG" --swift-log "$SWIFT_LOG" \
    --asan-log "$ASAN_LOG" --release-log "$RELEASE_LOG" \
    --report "$report"
}

ADMISSION_OUTPUT="$(run_admit "$REPORT")"
printf '%s\n' "$ADMISSION_OUTPUT" | tee "$ADMISSION_LOG"
grep -Fq 'SM64 save_mutation route isolated admission passed' <<<"$ADMISSION_OUTPUT"
grep -Fq 'shard=0x022fbda0ff7f2dd1 records=16 ticks=2,3 domains=global_state,save_bytes' <<<"$ADMISSION_OUTPUT"
grep -Fq 'c_swift_asan_release_byte_match=1 sidecar_c_asan_release_byte_match=1 snapshots_c_asan_release_byte_match=1' <<<"$ADMISSION_OUTPUT"
grep -Fq 'canonical_hash_tamper_rejected=1 fixture_only=0 manifest_mutated=0 ledger_mutated=0 history_mutated=0 rerun_fence=1' <<<"$ADMISSION_OUTPUT"
test "$(wc -l <"$REPORT" | tr -d '[:space:]')" -eq 7420
test "$(awk -F'|' -v id="$ROUTE_ID" '$1 == id && $2 == "passed" { count++ } END { print count + 0 }' "$REPORT")" -eq 1
test "$(awk -F'|' '$2 == "planned" { count++ } END { print count + 0 }' "$REPORT")" -eq 7419
TARGET_ROW="$(awk -F'|' -v id="$ROUTE_ID" '$1 == id { print; exit }' "$REPORT")"
[[ "$TARGET_ROW" == "$ROUTE_ID|passed|16|16|16|" ]]

# The isolated report is a persistent rerun fence and must remain unchanged.
REPORT_BEFORE="$(sha256_file "$REPORT")"
if run_admit "$REPORT" >"$RERUN_LOG" 2>&1; then
  echo 'save-mutation isolated admission rerun unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'already exists' "$RERUN_LOG"
[[ "$REPORT_BEFORE" == "$(sha256_file "$REPORT")" ]]

# Reusing one trace or one sidecar is not independent evidence.
SINGLE_TRACE_REPORT="$RUN_ROOT/single-trace-report.tsv"
if run_admit "$SINGLE_TRACE_REPORT" "$C_TRACE" "$C_TRACE" >"$SINGLE_TRACE_LOG" 2>&1; then
  echo 'single-trace save-mutation admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'evidence must be distinct' "$SINGLE_TRACE_LOG"
test ! -e "$SINGLE_TRACE_REPORT"

SINGLE_SIDECAR_REPORT="$RUN_ROOT/single-sidecar-report.tsv"
if run_admit "$SINGLE_SIDECAR_REPORT" "$C_TRACE" "$SWIFT_TRACE" "$C_SIDECAR" "$C_SIDECAR" >"$SINGLE_SIDECAR_LOG" 2>&1; then
  echo 'single-sidecar save-mutation admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'evidence must be distinct' "$SINGLE_SIDECAR_LOG"
test ! -e "$SINGLE_SIDECAR_REPORT"

# A partial trace must fail the exact sixteen-record gate and cannot produce
# a report.  This also fences transition/level-script synthetic substitutions.
PARTIAL_TRACE="$RUN_ROOT/partial.trace"
PARTIAL_REPORT="$RUN_ROOT/partial-report.tsv"
head -c $((72 + 15 * 128)) "$C_TRACE" >"$PARTIAL_TRACE"
if run_admit "$PARTIAL_REPORT" "$PARTIAL_TRACE" "$SWIFT_TRACE" >"$PARTIAL_LOG" 2>&1; then
  echo 'partial save-mutation admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'record count 15 is not 16' "$PARTIAL_LOG"
test ! -e "$PARTIAL_REPORT"

MANIFEST_AFTER="$(sha256_file "$MANIFEST")"
[[ "$MANIFEST_BEFORE" == "$MANIFEST_AFTER" ]]
git -c core.fsmonitor=false diff --check
REPORT_SHA="$(sha256_file "$REPORT")"
printf '%s\n' \
  "SM64 Modern save-mutation route admission smoke passed run=$RUN_ROOT" \
  "shard=$ROUTE_ID source=save_mutation|save_file_set_sound_mode input_seed=0x0c83cf28590d4915 save_seed=0xaaacc83cb4eb46a2" \
  'manifest=isolated route-shards.tsv manifest_rows=7420 target_status=planned expected_domains=global_state,save_bytes' \
  'records=16 ticks=2,3 global_state_records=12 save_bytes_records=4 canonical_order=1 transition_records=0 level_script_records=0' \
  'c_swift_asan_release_byte_match=1 sidecar_c_asan_release_byte_match=1 snapshots_c_asan_release_byte_match=1 canonical_hash_tamper_rejected=1' \
  'persistent_rerun_rejected=1 single_trace_rejected=1 single_sidecar_rejected=1 partial_trace_rejected=1 fixture_only=0 manifest_mutated=0 ledger_mutated=0 history_mutated=0' \
  "report_sha256=$REPORT_SHA report_rows=7420 passed_rows=1 planned_rows=7419 manifest_sha256=$MANIFEST_AFTER"
