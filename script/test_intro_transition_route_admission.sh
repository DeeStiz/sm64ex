#!/usr/bin/env bash
set -euo pipefail

# Phase 85f32 admits only the source-authored intro transition shard.  The
# Phase 85f30 pair runs in this fresh root; the focused manifest, report, and
# proof are isolated build outputs.  The canonical 7,420-row manifest,
# cumulative report, and execution ledger are read-only and never inputs to a
# write operation here.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="${SM64_INTRO_TRANSITION_ROUTE_ADMISSION_BUILD_ROOT:-$PROJECT_ROOT/build/sm64-modern-intro-transition-route-admission}"
mkdir -p "$BUILD_ROOT"
RUN_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
PAIR_ROOT="$RUN_ROOT/pair"
TOOL_ROOT="$RUN_ROOT/tool"
MODULE_CACHE="$TOOL_ROOT/module-cache"
MANIFEST="$RUN_ROOT/source-authored-intro-transition-manifest.tsv"
ADMISSION_TOOL="$TOOL_ROOT/sm64-intro-transition-route-admit"
REPORT="$RUN_ROOT/intro-transition-isolated-report.tsv"
PROOF="$RUN_ROOT/intro-transition-isolated-proof.tsv"
PAIR_CAPTURE="$RUN_ROOT/pair.log"
PAIR_REPORT="$RUN_ROOT/intro-transition-pair.report"
PAIR_PROOF="$RUN_ROOT/intro-transition-pair.proof"
ADMISSION_LOG="$RUN_ROOT/admission.log"
TAMPERED_SWIFT_TRACE="$RUN_ROOT/tampered-swift.trace"
PARTIAL_SWIFT_TRACE="$RUN_ROOT/partial-swift.trace"
REORDERED_SWIFT_TRACE="$RUN_ROOT/reordered-swift.trace"
MISSING_SWIFT_TRACE="$RUN_ROOT/missing-swift.trace"

mkdir -p "$TOOL_ROOT" "$MODULE_CACHE" "$PAIR_ROOT"

ROUTE_ID=0x9a0f7b4f7ecf6c41
INPUT_SEED=0x6c1f8a943cb27d50
SAVE_SEED=0x2e7fdb4a0c5689b1
C_TRACE="$PAIR_ROOT/intro-transition-c.trace"
SWIFT_TRACE="$PAIR_ROOT/intro-transition-swift.trace"
ASAN_TRACE="$PAIR_ROOT/intro-transition-c-asan.trace"
RELEASE_TRACE="$PAIR_ROOT/intro-transition-c-release.trace"
RERUN_TRACE="$PAIR_ROOT/intro-transition-c-rerun.trace"
TAMPERED_TRACE="$PAIR_ROOT/intro-transition-swift.tampered.trace"
REORDERED_TRACE="$PAIR_ROOT/intro-transition-swift.reordered.trace"
MISSING_TRACE="$PAIR_ROOT/intro-transition-swift.missing.trace"
PARTIAL_TRACE="$PAIR_ROOT/intro-transition-swift.partial.trace"
DEBUG_LOG="$PAIR_ROOT/debug.log"
SWIFT_LOG="$PAIR_ROOT/swift.log"
ASAN_LOG="$PAIR_ROOT/asan.log"
RELEASE_LOG="$PAIR_ROOT/release.log"
RERUN_LOG="$PAIR_ROOT/rerun.log"

sha256_file() { shasum -a 256 "$1" | awk '{ print $1 }'; }

# Snapshot any existing canonical route inputs.  This phase does not require a
# canonical manifest row because this authored entry/seed binding is kept
# phase-local until its parent decides whether to promote it.
CANONICAL_SNAPSHOT="$RUN_ROOT/canonical-inputs.sha256"
for canonical in \
  "$PROJECT_ROOT/build/sm64-route-shards-smoke/route-shards.tsv" \
  "$PROJECT_ROOT/build/sm64-route-shard-replay-smoke/route-shards.tsv" \
  "$PROJECT_ROOT/build/sm64-route-shard-replay-smoke/route-shard-execution-ledger.tsv" \
  "$PROJECT_ROOT/build/sm64-modern-phase85h-canonical-ledger/current/canonical-route-ledger.tsv"; do
  if [[ -f "$canonical" ]]; then
    printf '%s|%s\n' "$canonical" "$(sha256_file "$canonical")" >>"$CANONICAL_SNAPSHOT"
  fi
done

# Keep this focused source row isolated from the generated 7,420-row manifest.
# It is source identity/seed evidence, not fixture trace evidence: all trace
# bytes below come from the real owner-thread C lifecycle and its independent
# Swift value mirror.
printf '%s\n' \
  '# sm64-modern-route-shards-v1' \
  '# shard_id|domain|identity|source|input_seed|save_seed|expected_domains|status|notes' \
  "$ROUTE_ID|level_script|levels/intro/script.c|levels/intro/script.c|$INPUT_SEED|$SAVE_SEED|script_events,transition|planned|source-authored intro transition route;fixture_only=0" \
  >"$MANIFEST"
manifest_before="$(sha256_file "$MANIFEST")"

# First run the unchanged source-backed pair in a fresh, phase-local root.
bash -n "$PROJECT_ROOT/script/test_intro_transition_route_pair.sh"
SM64_INTRO_TRANSITION_ROUTE_BUILD_ROOT="$PAIR_ROOT" \
  "$PROJECT_ROOT/script/test_intro_transition_route_pair.sh" >"$PAIR_CAPTURE" 2>&1

for artifact in \
  "$C_TRACE" "$SWIFT_TRACE" "$ASAN_TRACE" "$RELEASE_TRACE" "$RERUN_TRACE" \
  "$TAMPERED_TRACE" "$REORDERED_TRACE" "$MISSING_TRACE" "$PARTIAL_TRACE" \
  "$DEBUG_LOG" "$SWIFT_LOG" "$ASAN_LOG" "$RELEASE_LOG" "$RERUN_LOG"; do
  test -s "$artifact"
done

grep -Fq 'SM64 Modern authored intro transition route pair smoke passed exact_pair=1' "$PAIR_CAPTURE"
grep -Fq 'route_shard=0x9a0f7b4f7ecf6c41 source=levels/intro/script.c entry=level_intro_entry_1 steps=320' "$PAIR_CAPTURE"
grep -Fq 'native_transition_records=2 ticks=311,391 hashes=0xb9e77a797c34bb9e,0x0eb91077dbe72aa4' "$PAIR_CAPTURE"
grep -Fq 'c_swift_asan_release_rerun_byte_match=1 owner_thread=1' "$PAIR_CAPTURE"
grep -Fq 'source_backed=1 direct_transition_call=0 synthesized_records=0 fixture_only=0' "$PAIR_CAPTURE"
cp "$PAIR_CAPTURE" "$PAIR_REPORT"

C_TRACE_SHA256="$(sha256_file "$C_TRACE")"
SWIFT_TRACE_SHA256="$(sha256_file "$SWIFT_TRACE")"
ASAN_TRACE_SHA256="$(sha256_file "$ASAN_TRACE")"
RELEASE_TRACE_SHA256="$(sha256_file "$RELEASE_TRACE")"
RERUN_TRACE_SHA256="$(sha256_file "$RERUN_TRACE")"
[[ "$C_TRACE_SHA256" == "$SWIFT_TRACE_SHA256" ]]
[[ "$C_TRACE_SHA256" == "$ASAN_TRACE_SHA256" ]]
[[ "$C_TRACE_SHA256" == "$RELEASE_TRACE_SHA256" ]]
[[ "$C_TRACE_SHA256" == "$RERUN_TRACE_SHA256" ]]
PAIR_REPORT_SHA256="$(sha256_file "$PAIR_REPORT")"

printf '%s\n' \
  '# sm64-intro-transition-pair-proof-v1' \
  "route_shard=$ROUTE_ID" \
  'source=levels/intro/script.c' \
  "input_seed=$INPUT_SEED" \
  "save_seed=$SAVE_SEED" \
  'region_code=0x00005553' \
  'schema=4' \
  'mode=record' \
  'build_fingerprint=0x62e7ffdfabb8d5ac' \
  'content_fingerprint=0x342d6d9f306b17be' \
  'timebase_fingerprint=0xccc19787cd09f0c2' \
  'configuration_fingerprint=0x123ac550762f06f4' \
  'initial_save_fingerprint=0xe18cb3aac96af32d' \
  'coverage_fingerprint=0x8fc5fa3c2cd26867' \
  "c_trace_sha256=$C_TRACE_SHA256" \
  "swift_trace_sha256=$SWIFT_TRACE_SHA256" \
  "asan_trace_sha256=$ASAN_TRACE_SHA256" \
  "release_trace_sha256=$RELEASE_TRACE_SHA256" \
  "rerun_trace_sha256=$RERUN_TRACE_SHA256" \
  "pair_report_sha256=$PAIR_REPORT_SHA256" \
  'fixture_only=0' \
  >"$PAIR_PROOF"

# Compile the isolated admission validator with Swift 6 strict concurrency.
xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/IntroTransitionMigration.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64IntroTransitionRouteAdmissionTool.swift" \
  -o "$ADMISSION_TOOL"

admit_command() {
  local manifest="$1"
  local c_trace="$2"
  local swift_trace="$3"
  local asan_trace="$4"
  local release_trace="$5"
  local rerun_trace="$6"
  local tampered_trace="$7"
  local reordered_trace="$8"
  local missing_trace="$9"
  local partial_trace="${10}"
  local report="${11}"
  local proof="${12}"
  "$ADMISSION_TOOL" \
    --manifest "$manifest" \
    --c-trace "$c_trace" \
    --swift-trace "$swift_trace" \
    --asan-trace "$asan_trace" \
    --release-trace "$release_trace" \
    --rerun-trace "$rerun_trace" \
    --tampered-trace "$tampered_trace" \
    --reordered-trace "$reordered_trace" \
    --missing-trace "$missing_trace" \
    --partial-trace "$partial_trace" \
    --pair-report "$PAIR_REPORT" \
    --pair-proof "$PAIR_PROOF" \
    --debug-log "$DEBUG_LOG" \
    --swift-log "$SWIFT_LOG" \
    --asan-log "$ASAN_LOG" \
    --release-log "$RELEASE_LOG" \
    --rerun-log "$RERUN_LOG" \
    --report "$report" \
    --proof "$proof"
}

admission_output="$(admit_command \
  "$MANIFEST" "$C_TRACE" "$SWIFT_TRACE" "$ASAN_TRACE" "$RELEASE_TRACE" "$RERUN_TRACE" \
  "$TAMPERED_TRACE" "$REORDERED_TRACE" "$MISSING_TRACE" "$PARTIAL_TRACE" "$REPORT" "$PROOF")"
printf '%s\n' "$admission_output" | tee "$ADMISSION_LOG"
grep -Fq 'SM64 intro_transition route isolated admission passed' <<<"$admission_output"
grep -Fq "shard=$ROUTE_ID identity=levels/intro/script.c source=levels/intro/script.c input_seed=$INPUT_SEED save_seed=$SAVE_SEED records=2 ticks=311,391 domain=6 kind=3 schema=4" <<<"$admission_output"
grep -Fq 'source_authored=1 owner_thread=1 direct_transition_call=0 synthesized_records=0' <<<"$admission_output"
grep -Fq 'c_swift_asan_release_rerun_byte_match=1' <<<"$admission_output"
grep -Fq "c_trace_sha256=$C_TRACE_SHA256 swift_trace_sha256=$SWIFT_TRACE_SHA256" <<<"$admission_output"
grep -Fq "asan_trace_sha256=$ASAN_TRACE_SHA256 release_trace_sha256=$RELEASE_TRACE_SHA256 rerun_trace_sha256=$RERUN_TRACE_SHA256" <<<"$admission_output"
grep -Fq "pair_report_sha256=$PAIR_REPORT_SHA256" <<<"$admission_output"
grep -Fq 'tamper_rejected=1 partial_rejected=1 reordered_rejected=1 missing_rejected=1 single_artifact_rejected=1' <<<"$admission_output"
grep -Fq 'fixture_only=0 manifest_mutated=0 canonical_report_mutated=0 ledger_mutated=0 history_mutated=0 output_distinctness=1 rerun_fence=1' <<<"$admission_output"
test "$(wc -l <"$REPORT" | tr -d '[:space:]')" -eq 1
grep -Fq "$ROUTE_ID|passed|2|2|2|" "$REPORT"
test -s "$PROOF"

# Keep direct negative invocations path-distinct from the corresponding
# negative-evidence input.  The admission tool rejects aliased evidence before
# decoding, so these are byte-identical copies with independent paths.
cp "$TAMPERED_TRACE" "$TAMPERED_SWIFT_TRACE"
cp "$PARTIAL_TRACE" "$PARTIAL_SWIFT_TRACE"
cp "$REORDERED_TRACE" "$REORDERED_SWIFT_TRACE"
cp "$MISSING_TRACE" "$MISSING_SWIFT_TRACE"

expect_rejection() {
  local label="$1"
  shift
  if "$@" >"$RUN_ROOT/$label.log" 2>&1; then
    echo "intro-transition admission negative fence accepted: $label" >&2
    exit 1
  fi
}

# The successful report/proof pair is write-once: the same evidence cannot be
# admitted a second time under the same output paths.
REPORT_SHA256="$(sha256_file "$REPORT")"
PROOF_SHA256="$(sha256_file "$PROOF")"
expect_rejection persistent_rerun admit_command \
  "$MANIFEST" "$C_TRACE" "$SWIFT_TRACE" "$ASAN_TRACE" "$RELEASE_TRACE" "$RERUN_TRACE" \
  "$TAMPERED_TRACE" "$REORDERED_TRACE" "$MISSING_TRACE" "$PARTIAL_TRACE" "$REPORT" "$PROOF"
grep -Fq 'duplicate admission rejected' "$RUN_ROOT/persistent_rerun.log"
[[ "$REPORT_SHA256" == "$(sha256_file "$REPORT")" ]]
[[ "$PROOF_SHA256" == "$(sha256_file "$PROOF")" ]]

# A proof output colliding with an immutable trace is rejected before any
# report is written.  This is the output-distinctness fence.
expect_rejection output_collision admit_command \
  "$MANIFEST" "$C_TRACE" "$SWIFT_TRACE" "$ASAN_TRACE" "$RELEASE_TRACE" "$RERUN_TRACE" \
  "$TAMPERED_TRACE" "$REORDERED_TRACE" "$MISSING_TRACE" "$PARTIAL_TRACE" \
  "$RUN_ROOT/collision-report.tsv" "$C_TRACE"
grep -Fq 'collides with immutable evidence' "$RUN_ROOT/output_collision.log"
test ! -e "$RUN_ROOT/collision-report.tsv"

# Every negative pair artifact is independently rejected at admission time.
expect_rejection tampered_trace admit_command \
  "$MANIFEST" "$C_TRACE" "$TAMPERED_SWIFT_TRACE" "$ASAN_TRACE" "$RELEASE_TRACE" "$RERUN_TRACE" \
  "$TAMPERED_TRACE" "$REORDERED_TRACE" "$MISSING_TRACE" "$PARTIAL_TRACE" "$RUN_ROOT/tampered-report.tsv" "$RUN_ROOT/tampered-proof.tsv"
expect_rejection partial_trace admit_command \
  "$MANIFEST" "$C_TRACE" "$PARTIAL_SWIFT_TRACE" "$ASAN_TRACE" "$RELEASE_TRACE" "$RERUN_TRACE" \
  "$TAMPERED_TRACE" "$REORDERED_TRACE" "$MISSING_TRACE" "$PARTIAL_TRACE" "$RUN_ROOT/partial-report.tsv" "$RUN_ROOT/partial-proof.tsv"
expect_rejection reordered_trace admit_command \
  "$MANIFEST" "$C_TRACE" "$REORDERED_SWIFT_TRACE" "$ASAN_TRACE" "$RELEASE_TRACE" "$RERUN_TRACE" \
  "$TAMPERED_TRACE" "$REORDERED_TRACE" "$MISSING_TRACE" "$PARTIAL_TRACE" "$RUN_ROOT/reordered-report.tsv" "$RUN_ROOT/reordered-proof.tsv"
expect_rejection missing_record admit_command \
  "$MANIFEST" "$C_TRACE" "$MISSING_SWIFT_TRACE" "$ASAN_TRACE" "$RELEASE_TRACE" "$RERUN_TRACE" \
  "$TAMPERED_TRACE" "$REORDERED_TRACE" "$MISSING_TRACE" "$PARTIAL_TRACE" "$RUN_ROOT/missing-report.tsv" "$RUN_ROOT/missing-proof.tsv"
grep -Fq 'invalid source-authored header' "$RUN_ROOT/missing_record.log"

# Passing one native artifact as both C and Swift evidence is not an
# independent pair and must fail before creating an output.
expect_rejection single_artifact admit_command \
  "$MANIFEST" "$C_TRACE" "$C_TRACE" "$ASAN_TRACE" "$RELEASE_TRACE" "$RERUN_TRACE" \
  "$TAMPERED_TRACE" "$REORDERED_TRACE" "$MISSING_TRACE" "$PARTIAL_TRACE" "$RUN_ROOT/single-report.tsv" "$RUN_ROOT/single-proof.tsv"
grep -Fq 'must be distinct artifacts' "$RUN_ROOT/single_artifact.log"
test ! -e "$RUN_ROOT/single-report.tsv"

# The explicit absent-evidence fence distinguishes a missing artifact from a
# valid one-record missing-window artifact.
ABSENT_TRACE="$RUN_ROOT/no-such-trace"
expect_rejection missing_artifact admit_command \
  "$MANIFEST" "$C_TRACE" "$SWIFT_TRACE" "$ASAN_TRACE" "$RELEASE_TRACE" "$RERUN_TRACE" \
  "$TAMPERED_TRACE" "$REORDERED_TRACE" "$ABSENT_TRACE" "$PARTIAL_TRACE" "$RUN_ROOT/absent-report.tsv" "$RUN_ROOT/absent-proof.tsv"
grep -Fq 'missing required evidence' "$RUN_ROOT/missing_artifact.log"

# Duplicate target rows are rejected by the immutable manifest parser; this
# is the duplicate-admission fence and does not touch the successful output.
DUPLICATE_MANIFEST="$RUN_ROOT/duplicate-manifest.tsv"
awk 'NR == 3 { print } { print }' "$MANIFEST" >"$DUPLICATE_MANIFEST"
expect_rejection duplicate_admission admit_command \
  "$DUPLICATE_MANIFEST" "$C_TRACE" "$SWIFT_TRACE" "$ASAN_TRACE" "$RELEASE_TRACE" "$RERUN_TRACE" \
  "$TAMPERED_TRACE" "$REORDERED_TRACE" "$MISSING_TRACE" "$PARTIAL_TRACE" "$RUN_ROOT/duplicate-report.tsv" "$RUN_ROOT/duplicate-proof.tsv"
grep -Fq 'duplicate shard' "$RUN_ROOT/duplicate_admission.log"
test ! -e "$RUN_ROOT/duplicate-report.tsv"

[[ "$manifest_before" == "$(sha256_file "$MANIFEST")" ]]
if [[ -s "$CANONICAL_SNAPSHOT" ]]; then
  while IFS='|' read -r canonical expected; do
    [[ -f "$canonical" ]]
    [[ "$(sha256_file "$canonical")" == "$expected" ]]
  done <"$CANONICAL_SNAPSHOT"
fi

git -c core.fsmonitor=false diff --check
bash -n "$0"
printf '%s\n' \
  "SM64 Modern Phase 85f32 intro-transition isolated admission passed run=$RUN_ROOT" \
  "source_authored=1 shard=$ROUTE_ID source=levels/intro/script.c input_seed=$INPUT_SEED save_seed=$SAVE_SEED" \
  'header_schema=4 region=0x00005553 mode=record build=0x62e7ffdfabb8d5ac content=0x342d6d9f306b17be timebase=0xccc19787cd09f0c2 coverage=0x8fc5fa3c2cd26867' \
  "c_swift_asan_release_rerun_trace_sha256=$C_TRACE_SHA256" \
  "pair_report_sha256=$PAIR_REPORT_SHA256 pair_proof_sha256=$(sha256_file "$PAIR_PROOF")" \
  "isolated_report_sha256=$REPORT_SHA256 isolated_proof_sha256=$PROOF_SHA256" \
  'tamper_rejected=1 partial_rejected=1 reordered_rejected=1 missing_rejected=1 single_artifact_rejected=1 persistent_rerun_rejected=1 duplicate_admission_rejected=1 output_distinctness=1' \
  'fixture_only=0 canonical_manifest_mutated=0 canonical_report_mutated=0 canonical_ledger_mutated=0 history_mutated=0 canonical_merge=deferred'
