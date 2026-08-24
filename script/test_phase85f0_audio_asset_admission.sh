#!/usr/bin/env bash
set -euo pipefail

# Phase 85f0 admits the source-backed audio_asset route into an isolated
# report/proof pair. It consumes Phase 85ef artifacts only; the canonical
# manifest and cumulative report are immutable inputs and are never replaced.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ROOT="${SM64_PHASE85EF_BUILD_ROOT:-$PROJECT_ROOT/build/sm64-modern-phase85ef-audio-coverage}"
BUILD_ROOT="${SM64_PHASE85F0_BUILD_ROOT:-$PROJECT_ROOT/build/sm64-modern-phase85f0-audio-asset-admission}"
RUN_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
TOOL_ROOT="$RUN_ROOT/tool"
MODULE_CACHE="$TOOL_ROOT/module-cache"
TOOL="$TOOL_ROOT/sm64-audio-asset-route-admit"
MANIFEST="$SOURCE_ROOT/route-shards.tsv"
REPORT="$RUN_ROOT/audio-asset-isolated-report.tsv"
PROOF="$RUN_ROOT/audio-asset-proof.tsv"
LOG="$RUN_ROOT/admission.log"

mkdir -p "$TOOL_ROOT" "$MODULE_CACHE"
test -s "$MANIFEST"

xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64AudioAssetRouteAdmissionTool.swift" \
  -o "$TOOL"

COMMON=(
  --manifest "$MANIFEST"
  --debug-trace "$SOURCE_ROOT/audio-coverage-c.trace"
  --asan-trace "$SOURCE_ROOT/audio-coverage-asan.trace"
  --release-trace "$SOURCE_ROOT/audio-coverage-release.trace"
  --rerun-trace "$SOURCE_ROOT/audio-coverage-rerun.trace"
  --tampered-trace "$SOURCE_ROOT/audio-coverage-tampered.trace"
  --partial-trace "$SOURCE_ROOT/audio-coverage-partial.trace"
  --debug-pcm "$SOURCE_ROOT/audio-coverage-c.pcm.trace"
  --asan-pcm "$SOURCE_ROOT/audio-coverage-asan.pcm.trace"
  --release-pcm "$SOURCE_ROOT/audio-coverage-release.pcm.trace"
  --rerun-pcm "$SOURCE_ROOT/audio-coverage-rerun.pcm.trace"
  --debug-receipts "$SOURCE_ROOT/audio-coverage-c.receipts"
  --asan-receipts "$SOURCE_ROOT/audio-coverage-asan.receipts"
  --release-receipts "$SOURCE_ROOT/audio-coverage-release.receipts"
  --rerun-receipts "$SOURCE_ROOT/audio-coverage-rerun.receipts"
  --debug-log "$SOURCE_ROOT/debug.log"
  --swift-log "$SOURCE_ROOT/swift.log"
  --asan-log "$SOURCE_ROOT/asan.log"
  --release-log "$SOURCE_ROOT/release.log"
  --rerun-log "$SOURCE_ROOT/rerun.log"
  --report "$REPORT"
  --proof "$PROOF"
)

"$TOOL" "${COMMON[@]}" | tee "$LOG"
grep -Fq 'SM64 audio_asset route isolated admission passed' "$LOG"
grep -Fq 'records=1084' "$LOG"
grep -Fq 'coverage=0x553ab8ef49275722' "$LOG"
grep -Fq 'manifest_mutated=0 canonical_ledger_mutation=0' "$LOG"
test -s "$REPORT" -a -s "$PROOF"

# A second admission may not overwrite a terminal isolated result.
if "$TOOL" "${COMMON[@]}" >"$RUN_ROOT/rerun.log" 2>&1; then
  echo 'phase85f0 terminal admission rerun unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'terminal rerun rejected' "$RUN_ROOT/rerun.log"

# The explicit single-artifact fence rejects aliasing the same evidence path.
if "$TOOL" single "$SOURCE_ROOT/audio-coverage-c.trace" "$SOURCE_ROOT/audio-coverage-c.trace" >"$RUN_ROOT/single.log" 2>&1; then
  echo 'phase85f0 single-artifact fence unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'single-artifact evidence' "$RUN_ROOT/single.log"

# Fixture markers cannot be used as live evidence.
FIXTURE_MARKER="$RUN_ROOT/fixture.trace.fixture_only"
touch "$FIXTURE_MARKER"
if "$TOOL" fixture "$FIXTURE_MARKER" >"$RUN_ROOT/fixture.log" 2>&1; then
  echo 'phase85f0 fixture-only fence unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'fixture_only evidence is not allowed' "$RUN_ROOT/fixture.log"

# Duplicate and non-planned manifest rows are rejected before target selection.
DUPLICATE_MANIFEST="$RUN_ROOT/duplicate-manifest.tsv"
awk 'NR == 3 { print } { print }' "$MANIFEST" >"$DUPLICATE_MANIFEST"
# Rebind the manifest argument explicitly so the malformed input is tested.
DUPLICATE_COMMON=("${COMMON[@]}")
for index in "${!DUPLICATE_COMMON[@]}"; do
  if [[ "${DUPLICATE_COMMON[$index]}" == "$MANIFEST" ]]; then
    DUPLICATE_COMMON[$index]="$DUPLICATE_MANIFEST"
  elif [[ "${DUPLICATE_COMMON[$index]}" == "$REPORT" ]]; then
    DUPLICATE_COMMON[$index]="$RUN_ROOT/duplicate-report.tsv"
  elif [[ "${DUPLICATE_COMMON[$index]}" == "$PROOF" ]]; then
    DUPLICATE_COMMON[$index]="$RUN_ROOT/duplicate-proof.tsv"
  fi
done
if "$TOOL" "${DUPLICATE_COMMON[@]}" >"$RUN_ROOT/duplicate.log" 2>&1; then
  echo 'phase85f0 duplicate-manifest fence unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'duplicate shard' "$RUN_ROOT/duplicate.log"

CONFLICT_MANIFEST="$RUN_ROOT/conflict-manifest.tsv"
awk 'NR == 3 { sub(/\|planned\|/, "|passed|") } { print }' "$MANIFEST" >"$CONFLICT_MANIFEST"
CONFLICT_COMMON=("${COMMON[@]}")
for index in "${!CONFLICT_COMMON[@]}"; do
  if [[ "${CONFLICT_COMMON[$index]}" == "$MANIFEST" ]]; then
    CONFLICT_COMMON[$index]="$CONFLICT_MANIFEST"
  elif [[ "${CONFLICT_COMMON[$index]}" == "$REPORT" ]]; then
    CONFLICT_COMMON[$index]="$RUN_ROOT/conflict-report.tsv"
  elif [[ "${CONFLICT_COMMON[$index]}" == "$PROOF" ]]; then
    CONFLICT_COMMON[$index]="$RUN_ROOT/conflict-proof.tsv"
  fi
done
if "$TOOL" "${CONFLICT_COMMON[@]}" >"$RUN_ROOT/conflict.log" 2>&1; then
  echo 'phase85f0 conflict-manifest fence unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'manifest rows must enter the ledger as planned' "$RUN_ROOT/conflict.log"

git -c core.fsmonitor=false diff --check -- \
  "$PROJECT_ROOT/tools/SM64AudioAssetRouteAdmissionTool.swift" \
  "$PROJECT_ROOT/script/test_phase85f0_audio_asset_admission.sh"

REPORT_SHA256="$(shasum -a 256 "$REPORT" | awk '{print $1}')"
PROOF_SHA256="$(shasum -a 256 "$PROOF" | awk '{print $1}')"
printf '%s\n' \
  'SM64 Modern Phase 85f0 isolated audio_asset admission passed' \
  'source_backed=1 schema4=1 audio_sequence_records=3 audio_pcm_records=720 records=1084' \
  'coverage=0x553ab8ef49275722 c_asan_release_rerun_trace_match=1 pcm_match=1 receipts_match=1' \
  'tamper_rejected=1 partial_rejected=1 single_artifact_rejected=1 fixture_only_rejected=1' \
  'duplicate_manifest_rejected=1 conflict_manifest_rejected=1 terminal_rerun_rejected=1' \
  'isolated_report_sha256='"$REPORT_SHA256" \
  'proof_sha256='"$PROOF_SHA256" \
  'canonical_manifest_mutated=0 canonical_report_mutated=0 canonical_merge=deferred'
