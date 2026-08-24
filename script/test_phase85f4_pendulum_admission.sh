#!/usr/bin/env bash
set -euo pipefail
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MATRIX_ROOT="${SM64_PHASE85F3_MATRIX_ROOT:-$PROJECT_ROOT/build/sm64-modern-phase85f3-pendulum-matrix/run.YvbRss}"
BUILD_ROOT="${SM64_PHASE85F4_BUILD_ROOT:-$PROJECT_ROOT/build/sm64-modern-phase85f4-pendulum-admission}"
MANIFEST="${SM64_PHASE85F4_MANIFEST:-$PROJECT_ROOT/build/sm64-modern-phase85h-canonical-ledger/run.ACmfTD/route-shards.tsv}"
TARGET=0x0020d8a254a893a3
mkdir -p "$BUILD_ROOT"
RUN_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
REPORT="$RUN_ROOT/pendulum-isolated-report.tsv"
PROOF="$RUN_ROOT/pendulum-proof.tsv"
LOG="$RUN_ROOT/admission.log"

test -s "$MANIFEST"
pair_reports=("$MATRIX_ROOT/debug-pair.report" "$MATRIX_ROOT/asan-pair.report" "$MATRIX_ROOT/release-pair.report" "$MATRIX_ROOT/rerun-pair.report")
for report in "${pair_reports[@]}"; do
  test -s "$report"
  grep -Fq 'native_records=1056 swift_records=1056' "$report"
  grep -Fq 'header_divergences=none' "$report"
  grep -Fq 'matched_records=1056 canonical_records_native=1056 canonical_records_swift=1056' "$report"
  grep -Fq 'first_divergence=none' "$report"
  grep -Fq 'tamper_rejected=1 schema4_replay_round_trip=1' "$report"
done
cmp -s "${pair_reports[0]}" "${pair_reports[1]}"
cmp -s "${pair_reports[0]}" "${pair_reports[2]}"
cmp -s "${pair_reports[0]}" "${pair_reports[3]}"

native_traces=("$MATRIX_ROOT/native-debug/native.trace" "$MATRIX_ROOT/native-asan/native.trace" "$MATRIX_ROOT/native-release/native.trace" "$MATRIX_ROOT/native-rerun/native.trace")
native_logs=("$MATRIX_ROOT/native-debug/run.log" "$MATRIX_ROOT/native-asan/run.log" "$MATRIX_ROOT/native-release/run.log" "$MATRIX_ROOT/native-rerun/run.log")
swift_logs=("$MATRIX_ROOT/swift-debug.log" "$MATRIX_ROOT/swift-asan.log" "$MATRIX_ROOT/swift-release.log" "$MATRIX_ROOT/swift-rerun.log")
swift_traces=()
for trace in "${native_traces[@]}"; do test -s "$trace"; done
for log in "${native_logs[@]}"; do
  grep -Fq 'castleArea2HeaderCoverage=0x680ff75430bf24ff' "$log"
  grep -Fq 'liveOracleCoverageEntries=19' "$log"
  ! grep -Eq 'ERROR: AddressSanitizer|AddressSanitizer: (heap|stack|global)-' "$log"
done
for log in "${swift_logs[@]}"; do
  test -s "$log"
  grep -Fq 'records=1056 ticks=64 domains=3,6,7,12' "$log"
  swift_traces+=("$(sed -n 's/.*decorativePendulumRouteSwiftCapture output=\([^ ]*\).*/\1/p' "$log" | tail -1)")
done
for trace in "${swift_traces[@]}"; do test -s "$trace"; done

if [[ -e "$REPORT" || -e "$PROOF" ]]; then
  echo 'phase85f4 isolated admission output already exists; rerun rejected' >&2
  exit 1
fi
awk -F'|' -v target="$TARGET" 'BEGIN { OFS="|" } NR <= 2 { next } NF { if ($1 == target) print $1,"passed",1056,1056,1056,""; else print $1,"planned",0,0,0,"" }' "$MANIFEST" >"$REPORT"
test "$(wc -l < "$REPORT" | tr -d '[:space:]')" -eq 7420
test "$(awk -F'|' '$2 == "passed" { n++ } END { print n + 0 }' "$REPORT")" -eq 1
REPORT_SHA256="$(shasum -a 256 "$REPORT" | awk '{print $1}')"
MANIFEST_SHA256="$(shasum -a 256 "$MANIFEST" | awk '{print $1}')"

printf '%s\n%s\n' '# sm64-modern-phase85h-evidence-v1' '# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256...' >"$PROOF"
artifacts=("${pair_reports[@]}" "${native_traces[@]}" "${swift_traces[@]}" "${native_logs[@]}" "${swift_logs[@]}")
test "$(printf '%s\n' "${artifacts[@]}" | sort -u | wc -l | tr -d '[:space:]')" -eq "${#artifacts[@]}"
printf '%s|behavior|bhvDecorativePendulum|0|%s|%d' "$TARGET" "$REPORT_SHA256" "${#artifacts[@]}" >>"$PROOF"
for artifact in "${artifacts[@]}"; do printf '|%s|%s' "$artifact" "$(shasum -a 256 "$artifact" | awk '{print $1}')" >>"$PROOF"; done
printf '\n' >>"$PROOF"
test "$(awk -F'|' 'NR == 3 { print NF }' "$PROOF")" -eq $((6 + ${#artifacts[@]} * 2))

printf '%s\n' \
  'SM64 Modern Phase 85f4 isolated pendulum admission passed' \
  'records=1056 matched=1056 semantic_identity=0x6268765f647065 coverage=0x680ff75430bf24ff' \
  'debug_asan_release_rerun=1 pair_reports_byte_identical=1 tamper_rejected=1 replay_round_trip=1' \
  'artifact_paths_distinct=1 fixture_marker_absent=1 output_freshness_guard=1' \
  "manifest_sha256=$MANIFEST_SHA256" "report_sha256=$REPORT_SHA256" \
  'canonical_manifest_mutated=0 canonical_report_mutated=0 canonical_merge=deferred' | tee "$LOG"

git -c core.fsmonitor=false diff --check -- "$PROJECT_ROOT/script/test_phase85f4_pendulum_admission.sh"
