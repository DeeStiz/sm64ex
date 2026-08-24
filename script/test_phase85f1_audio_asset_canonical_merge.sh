#!/usr/bin/env bash
set -euo pipefail

# Phase 85f1 merges the isolated Phase 85f0 audio_asset row with the existing
# independently admitted reports. All inputs are immutable; the merged report
# is written only beneath this phase's build run directory.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_ROOT="${SM64_PHASE85F1_BASELINE_ROOT:-$PROJECT_ROOT/build/sm64-modern-phase85h-canonical-ledger/run.ACmfTD}"
AUDIO_ROOT="${SM64_PHASE85F0_RUN_ROOT:-$(ls -dt "$PROJECT_ROOT"/build/sm64-modern-phase85f0-audio-asset-admission/run.* | head -1)}"
BUILD_ROOT="${SM64_PHASE85F1_BUILD_ROOT:-$PROJECT_ROOT/build/sm64-modern-phase85f1-audio-asset-canonical-merge}"
mkdir -p "$BUILD_ROOT"
RUN_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
TOOL_ROOT="$RUN_ROOT/tool"
MODULE_CACHE="$TOOL_ROOT/module-cache"
TOOL="$TOOL_ROOT/sm64-canonical-route-ledger-merge"
MANIFEST="$BASE_ROOT/route-shards.tsv"
OUTPUT="$RUN_ROOT/canonical-route-ledger.tsv"

mkdir -p "$TOOL_ROOT" "$MODULE_CACHE"
test -s "$MANIFEST"
test -s "$AUDIO_ROOT/audio-asset-isolated-report.tsv"
test -s "$AUDIO_ROOT/audio-asset-proof.tsv"

xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64CanonicalRouteLedgerMergeTool.swift" \
  -o "$TOOL"

merge_args() {
  local output="$1" audio_report="$2" audio_proof="$3"
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
    --audio-asset-report "$audio_report" --audio-asset-proof "$audio_proof"
    --output "$output"
  )
}

merge_args "$OUTPUT" "$AUDIO_ROOT/audio-asset-isolated-report.tsv" "$AUDIO_ROOT/audio-asset-proof.tsv"
"$TOOL" "${MERGE_ARGS[@]}" | tee "$RUN_ROOT/merge.log"
grep -Fq 'qualified_rows=24 planned=7396 terminal=24' "$RUN_ROOT/merge.log"
grep -Fq 'manifest_sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715' "$RUN_ROOT/merge.log"
grep -Fq '0x03345fc560c65b75' "$RUN_ROOT/merge.log"
test "$(awk -F'|' '$2 == "planned" { count++ } END { print count + 0 }' "$OUTPUT")" -eq 7396
test "$(awk -F'|' '$2 == "passed" { count++ } END { print count + 0 }' "$OUTPUT")" -eq 24
test "$(awk -F'|' '$1 == "0x03345fc560c65b75" { print $2 }' "$OUTPUT")" = passed

# Terminal rerun is rejected without changing the first merged output.
if "$TOOL" "${MERGE_ARGS[@]}" >"$RUN_ROOT/rerun.log" 2>&1; then
  echo 'phase85f1 canonical merge rerun unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'cumulative ledger already exists' "$RUN_ROOT/rerun.log"

# Duplicate report path is rejected before any output is written.
merge_args "$RUN_ROOT/duplicate.tsv" "$BASE_ROOT/input-report.tsv" "$AUDIO_ROOT/audio-asset-proof.tsv"
if "$TOOL" "${MERGE_ARGS[@]}" >"$RUN_ROOT/duplicate.log" 2>&1; then
  echo 'phase85f1 duplicate-report fence unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'duplicate report artifact' "$RUN_ROOT/duplicate.log"

# A fixture-only proof cannot be promoted.
FIXTURE_PROOF="$RUN_ROOT/fixture-proof.tsv"
sed 's/|0|/|1|/' "$AUDIO_ROOT/audio-asset-proof.tsv" >"$FIXTURE_PROOF"
merge_args "$RUN_ROOT/fixture.tsv" "$AUDIO_ROOT/audio-asset-isolated-report.tsv" "$FIXTURE_PROOF"
if "$TOOL" "${MERGE_ARGS[@]}" >"$RUN_ROOT/fixture.log" 2>&1; then
  echo 'phase85f1 fixture-only proof unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'fixture_only evidence is not allowed' "$RUN_ROOT/fixture.log"

# A conflicting report is rejected by the proof/report hash fence.
CONFLICT_REPORT="$RUN_ROOT/conflicting-report.tsv"
awk -F'|' 'BEGIN { OFS="|" } $1 == "0x03345fc560c65b75" { $2="blocked"; $3=0; $4=0; $5=0; $6="" } { print }' \
  "$AUDIO_ROOT/audio-asset-isolated-report.tsv" >"$CONFLICT_REPORT"
merge_args "$RUN_ROOT/conflict.tsv" "$CONFLICT_REPORT" "$AUDIO_ROOT/audio-asset-proof.tsv"
if "$TOOL" "${MERGE_ARGS[@]}" >"$RUN_ROOT/conflict.log" 2>&1; then
  echo 'phase85f1 conflicting-report fence unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'report hash mismatch' "$RUN_ROOT/conflict.log"

git -c core.fsmonitor=false diff --check -- \
  "$PROJECT_ROOT/tools/SM64CanonicalRouteLedgerMergeTool.swift" \
  "$PROJECT_ROOT/script/test_phase85f1_audio_asset_canonical_merge.sh"

REPORT_SHA256="$(shasum -a 256 "$OUTPUT" | awk '{print $1}')"
printf '%s\n' \
  'SM64 Modern Phase 85f1 audio_asset canonical merge passed' \
  'manifest_rows=7420 qualified_rows=24 planned_rows=7396 terminal_rows=24' \
  'audio_asset=0x03345fc560c65b75 isolated_report_verified=1 proof_verified=1 fixture_only=0' \
  'duplicate_report_rejected=1 fixture_proof_rejected=1 conflict_report_rejected=1 terminal_rerun_rejected=1' \
  'manifest_sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715' \
  'merged_report_sha256='"$REPORT_SHA256" \
  'canonical_source_mutation=deferred docs_update=parent_commit_required'
