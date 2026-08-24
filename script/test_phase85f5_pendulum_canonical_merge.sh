#!/usr/bin/env bash
set -euo pipefail
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_ROOT="${SM64_PHASE85F5_BASELINE_ROOT:-$PROJECT_ROOT/build/sm64-modern-phase85h-canonical-ledger/run.ACmfTD}"
AUDIO_ROOT="$PROJECT_ROOT/build/sm64-modern-phase85f0-audio-asset-admission/run.1i26xf"
PENDULUM_ROOT="${SM64_PHASE85F4_RUN_ROOT:-$(ls -dt "$PROJECT_ROOT"/build/sm64-modern-phase85f4-pendulum-admission/run.* | head -1)}"
BUILD_ROOT="${SM64_PHASE85F5_BUILD_ROOT:-$PROJECT_ROOT/build/sm64-modern-phase85f5-pendulum-canonical-merge}"
mkdir -p "$BUILD_ROOT"
RUN_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
TOOL_ROOT="$RUN_ROOT/tool"
mkdir -p "$TOOL_ROOT/module-cache"
TOOL="$TOOL_ROOT/merge"
MANIFEST="$BASE_ROOT/route-shards.tsv"
OUTPUT="$RUN_ROOT/canonical-route-ledger.tsv"

xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64CanonicalRouteLedgerMergeTool.swift" -o "$TOOL"

merge_args() {
  local output="$1"
  local pendulum_report="${2:-$PENDULUM_ROOT/pendulum-isolated-report.tsv}"
  MERGE_ARGS=(
    --manifest "$MANIFEST"
    --input-report "$BASE_ROOT/input-report.tsv" --input-proof "$BASE_ROOT/input-proof.tsv"
    --mario-report "$BASE_ROOT/mario-report.tsv" --mario-proof "$BASE_ROOT/mario-proof.tsv"
    --camera-report "$BASE_ROOT/camera-report.tsv" --camera-proof "$BASE_ROOT/camera-proof.tsv"
    --global-report "$BASE_ROOT/global-report.tsv" --global-proof "$BASE_ROOT/global-proof.tsv"
    --object-report "$BASE_ROOT/object-report.tsv" --object-proof "$BASE_ROOT/object-proof.tsv"
    --script-report "$BASE_ROOT/script-report.tsv" --script-proof "$BASE_ROOT/script-proof.tsv"
    --collision-report "$BASE_ROOT/collision-report.tsv" --collision-proof "$BASE_ROOT/collision-proof.tsv"
    --rng-report "$BASE_ROOT/rng-report.tsv" --rng-proof "$BASE_ROOT/rng-proof.tsv"
    --audio-report "$BASE_ROOT/audio-report.tsv" --audio-proof "$BASE_ROOT/audio-proof.tsv"
    --save-report "$BASE_ROOT/save-report.tsv" --save-proof "$BASE_ROOT/save-proof.tsv"
    --render-report "$BASE_ROOT/render-report.tsv" --render-proof "$BASE_ROOT/render-proof.tsv"
    --audio-pcm-report "$BASE_ROOT/audio-pcm-report.tsv" --audio-pcm-proof "$BASE_ROOT/pcm-proof.tsv"
    --interaction-report "$BASE_ROOT/interaction-report.tsv" --interaction-proof "$BASE_ROOT/interaction-proof.tsv"
    --effects-report "$BASE_ROOT/effects-report.tsv" --effects-proof "$BASE_ROOT/effects-proof.tsv"
    --save-mutation-report "$BASE_ROOT/save-mutation-report.tsv" --save-mutation-proof "$BASE_ROOT/save-mutation-proof.tsv"
    --camera-find-floor-report "$BASE_ROOT/camera-find-floor-report.tsv" --camera-find-floor-proof "$BASE_ROOT/camera-find-floor-proof.tsv"
    --display-list-report "$BASE_ROOT/display-list-report.tsv" --display-list-proof "$BASE_ROOT/display-list-proof.tsv"
    --display-list-next-report "$BASE_ROOT/display-list-next-report.tsv" --display-list-next-proof "$BASE_ROOT/display-list-next-proof.tsv"
    --render-callback-report "$BASE_ROOT/render-callback-report.tsv" --render-callback-proof "$BASE_ROOT/render-callback-proof.tsv"
    --rng-break-particles-report "$BASE_ROOT/rng-break-particles-report.tsv" --rng-break-particles-proof "$BASE_ROOT/rng-break-particles-proof.tsv"
    --text-report "$BASE_ROOT/text-report.tsv" --text-proof "$BASE_ROOT/text-proof.tsv"
    --inside-castle-report "$BASE_ROOT/inside-castle-report.tsv" --inside-castle-proof "$BASE_ROOT/inside-castle-proof.tsv"
    --door-report "$BASE_ROOT/door-report.tsv" --door-proof "$BASE_ROOT/door-proof.tsv"
    --audio-asset-report "$AUDIO_ROOT/audio-asset-isolated-report.tsv" --audio-asset-proof "$AUDIO_ROOT/audio-asset-proof.tsv"
    --pendulum-report "$pendulum_report" --pendulum-proof "$PENDULUM_ROOT/pendulum-proof.tsv"
    --output "$output"
  )
}

merge_args "$OUTPUT"
"$TOOL" "${MERGE_ARGS[@]}" | tee "$RUN_ROOT/merge.log"
grep -Fq 'qualified_rows=25 planned=7395 terminal=25' "$RUN_ROOT/merge.log"
grep -Fq 'manifest_sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715' "$RUN_ROOT/merge.log"
test "$(awk -F'|' '$2 == "passed" { n++ } END { print n + 0 }' "$OUTPUT")" -eq 25
test "$(awk -F'|' '$2 == "planned" { n++ } END { print n + 0 }' "$OUTPUT")" -eq 7395
test "$(awk -F'|' '$1 == "0x0020d8a254a893a3" { print $2 }' "$OUTPUT")" = passed

if "$TOOL" "${MERGE_ARGS[@]}" >"$RUN_ROOT/rerun.log" 2>&1; then
  echo 'phase85f5 terminal rerun unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'cumulative ledger already exists' "$RUN_ROOT/rerun.log"

merge_args "$RUN_ROOT/duplicate.tsv" "$BASE_ROOT/input-report.tsv"
if "$TOOL" "${MERGE_ARGS[@]}" >"$RUN_ROOT/duplicate.log" 2>&1; then
  echo 'phase85f5 duplicate-report fence unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'duplicate report artifact' "$RUN_ROOT/duplicate.log"

git -c core.fsmonitor=false diff --check -- \
  "$PROJECT_ROOT/tools/SM64CanonicalRouteLedgerMergeTool.swift" \
  "$PROJECT_ROOT/script/test_phase85f5_pendulum_canonical_merge.sh"
REPORT_SHA256="$(shasum -a 256 "$OUTPUT" | awk '{print $1}')"
printf '%s\n' \
  'SM64 Modern Phase 85f5 pendulum canonical merge passed' \
  'manifest_rows=7420 qualified_rows=25 planned_rows=7395 terminal_rows=25' \
  'pendulum=0x0020d8a254a893a3 isolated_report_verified=1 proof_verified=1 fixture_only=0' \
  'duplicate_report_rejected=1 terminal_rerun_rejected=1' \
  'manifest_sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715' \
  "merged_report_sha256=$REPORT_SHA256" \
  'canonical_manifest_mutated=0 canonical_source_report_mutation=deferred' | tee "$RUN_ROOT/phase-summary.log"
