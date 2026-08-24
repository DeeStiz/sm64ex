#!/usr/bin/env bash
set -euo pipefail

# Phase 85f136 is a read-only reconciliation of the canonical merge-tool
# contracts. It exercises the 25-target retained-backup stage in a fresh
# output root; the designated 26-row report and its 25-row backup remain
# immutable inputs and are never promoted or overwritten here.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_ROOT="${SM64_PHASE85F136_BASE_ROOT:-$PROJECT_ROOT/build/sm64-modern-phase85h-canonical-ledger/run.ACmfTD}"
AUDIO_ROOT="${SM64_PHASE85F136_AUDIO_ROOT:-$PROJECT_ROOT/build/sm64-modern-phase85f0-audio-asset-admission/run.1i26xf}"
PENDULUM_ROOT="${SM64_PHASE85F136_PENDULUM_ROOT:-$PROJECT_ROOT/build/sm64-modern-phase85f4-pendulum-admission/run.YLW2s7}"
DESIGNATED_REPORT="${SM64_PHASE85F136_DESIGNATED_REPORT:-$PROJECT_ROOT/build/sm64-modern-phase85f81-serial-publication/run.elhzBC/canonical-route-ledger.tsv}"
BACKUP_REPORT="${SM64_PHASE85F136_BACKUP_REPORT:-$PROJECT_ROOT/build/sm64-modern-phase85f81-serial-publication/run.elhzBC/pre-publication-backup/canonical-route-ledger.tsv}"
BUILD_ROOT="${SM64_PHASE85F136_BUILD_ROOT:-$PROJECT_ROOT/build/sm64-modern-phase85f136-merge-tool-drift-fix}"

MANIFEST_SHA256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
BACKUP_REPORT_SHA256=aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d
DESIGNATED_REPORT_SHA256=4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4
AUDIO_ASSET_ID=0x03345fc560c65b75
PENDULUM_ID=0x0020d8a254a893a3
PENDULUM_SWIFT_TRACE_SHA256=90bcaa7514a9b4aafc6d35bb8a1a4be719c889775167ff0d56f54d91c27f64fb

sha256_file() { shasum -a 256 "$1" | awk '{ print $1 }'; }
count_states() {
  awk -F'|' '$2 == "passed" { p++ } $2 == "planned" { q++ } END { print p + 0, q + 0 }' "$1"
}
require_file() {
  test -s "$1" || { echo "missing required evidence: $1" >&2; exit 1; }
}

SOURCE_MANIFEST="${SM64_PHASE85F136_MANIFEST:-$PROJECT_ROOT/build/sm64-route-shards-smoke/route-shards.tsv}"
for required in "$SOURCE_MANIFEST" "$DESIGNATED_REPORT" "$BACKUP_REPORT" \
  "$AUDIO_ROOT/audio-asset-isolated-report.tsv" "$AUDIO_ROOT/audio-asset-proof.tsv" \
  "$PENDULUM_ROOT/pendulum-isolated-report.tsv" "$PENDULUM_ROOT/pendulum-proof.tsv"; do
  require_file "$required"
done

test "$(sha256_file "$SOURCE_MANIFEST")" = "$MANIFEST_SHA256"
test "$(sha256_file "$DESIGNATED_REPORT")" = "$DESIGNATED_REPORT_SHA256"
test "$(sha256_file "$BACKUP_REPORT")" = "$BACKUP_REPORT_SHA256"
test "$(count_states "$DESIGNATED_REPORT")" = '26 7394'
test "$(count_states "$BACKUP_REPORT")" = '25 7395'

mkdir -p "$BUILD_ROOT"
RUN_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
TOOL_ROOT="$RUN_ROOT/tool"
MODULE_CACHE="$TOOL_ROOT/module-cache"
mkdir -p "$MODULE_CACHE" "$RUN_ROOT/reports"

# Every report/proof used by the dry-run is copied into the isolated root. The
# proof artifacts themselves remain at their existing immutable paths.
MANIFEST="$RUN_ROOT/route-shards.tsv"
cp "$SOURCE_MANIFEST" "$MANIFEST"

BASE_NAMES=(
  input mario camera global object script collision rng audio save render
  audio-pcm interaction effects save-mutation camera-find-floor display-list
  display-list-next render-callback rng-break-particles text inside-castle door
)
for name in "${BASE_NAMES[@]}"; do
  cp "$BASE_ROOT/$name-report.tsv" "$RUN_ROOT/reports/$name-report.tsv"
  if [[ "$name" == audio-pcm ]]; then
    cp "$BASE_ROOT/pcm-proof.tsv" "$RUN_ROOT/reports/audio-pcm-proof.tsv"
  else
    cp "$BASE_ROOT/$name-proof.tsv" "$RUN_ROOT/reports/$name-proof.tsv"
  fi
done
cp "$AUDIO_ROOT/audio-asset-isolated-report.tsv" "$RUN_ROOT/reports/audio-asset-report.tsv"
cp "$AUDIO_ROOT/audio-asset-proof.tsv" "$RUN_ROOT/reports/audio-asset-proof.tsv"
cp "$PENDULUM_ROOT/pendulum-isolated-report.tsv" "$RUN_ROOT/reports/pendulum-report.tsv"

# The retained pendulum proof was authored with four expired temporary Swift
# trace paths. Resolve four current files with the same recorded hash and
# rewrite only the isolated proof copy; the source proof is never touched.
PENDULUM_SWIFT_PATHS=()
while IFS= read -r candidate; do
  [[ "$(sha256_file "$candidate")" == "$PENDULUM_SWIFT_TRACE_SHA256" ]] || continue
  PENDULUM_SWIFT_PATHS+=("$candidate")
  [[ "${#PENDULUM_SWIFT_PATHS[@]}" -eq 4 ]] && break
done < <(find /var/folders /private/tmp -type f -name 'swift-source-route.trace' -print 2>/dev/null | LC_ALL=C sort -u)
[[ "${#PENDULUM_SWIFT_PATHS[@]}" -eq 4 ]] || {
  echo 'could not resolve four current pendulum Swift trace artifacts' >&2
  exit 1
}
PENDULUM_PROOF="$RUN_ROOT/reports/pendulum-proof.tsv"
awk -F'|' -v OFS='|' \
  -v p1="${PENDULUM_SWIFT_PATHS[0]}" -v p2="${PENDULUM_SWIFT_PATHS[1]}" \
  -v p3="${PENDULUM_SWIFT_PATHS[2]}" -v p4="${PENDULUM_SWIFT_PATHS[3]}" '
  NR <= 2 { print; next }
  {
    n = 0
    for (i = 7; i <= NF; i += 2) {
      if ($i ~ /swift-source-route[.]trace$/) {
        n++
        if (n == 1) $i = p1
        if (n == 2) $i = p2
        if (n == 3) $i = p3
        if (n == 4) $i = p4
      }
    }
    print
  }
' "$PENDULUM_ROOT/pendulum-proof.tsv" >"$PENDULUM_PROOF"

INPUT_REPORT="$RUN_ROOT/reports/input-report.tsv"
INPUT_PROOF="$RUN_ROOT/reports/input-proof.tsv"
MARIO_REPORT="$RUN_ROOT/reports/mario-report.tsv"
MARIO_PROOF="$RUN_ROOT/reports/mario-proof.tsv"
CAMERA_REPORT="$RUN_ROOT/reports/camera-report.tsv"
CAMERA_PROOF="$RUN_ROOT/reports/camera-proof.tsv"
GLOBAL_REPORT="$RUN_ROOT/reports/global-report.tsv"
GLOBAL_PROOF="$RUN_ROOT/reports/global-proof.tsv"
OBJECT_REPORT="$RUN_ROOT/reports/object-report.tsv"
OBJECT_PROOF="$RUN_ROOT/reports/object-proof.tsv"
SCRIPT_REPORT="$RUN_ROOT/reports/script-report.tsv"
SCRIPT_PROOF="$RUN_ROOT/reports/script-proof.tsv"
COLLISION_REPORT="$RUN_ROOT/reports/collision-report.tsv"
COLLISION_PROOF="$RUN_ROOT/reports/collision-proof.tsv"
RNG_REPORT="$RUN_ROOT/reports/rng-report.tsv"
RNG_PROOF="$RUN_ROOT/reports/rng-proof.tsv"
AUDIO_REPORT="$RUN_ROOT/reports/audio-report.tsv"
AUDIO_PROOF="$RUN_ROOT/reports/audio-proof.tsv"
SAVE_REPORT="$RUN_ROOT/reports/save-report.tsv"
SAVE_PROOF="$RUN_ROOT/reports/save-proof.tsv"
RENDER_REPORT="$RUN_ROOT/reports/render-report.tsv"
RENDER_PROOF="$RUN_ROOT/reports/render-proof.tsv"
AUDIO_PCM_REPORT="$RUN_ROOT/reports/audio-pcm-report.tsv"
AUDIO_PCM_PROOF="$RUN_ROOT/reports/audio-pcm-proof.tsv"
INTERACTION_REPORT="$RUN_ROOT/reports/interaction-report.tsv"
INTERACTION_PROOF="$RUN_ROOT/reports/interaction-proof.tsv"
EFFECTS_REPORT="$RUN_ROOT/reports/effects-report.tsv"
EFFECTS_PROOF="$RUN_ROOT/reports/effects-proof.tsv"
SAVE_MUTATION_REPORT="$RUN_ROOT/reports/save-mutation-report.tsv"
SAVE_MUTATION_PROOF="$RUN_ROOT/reports/save-mutation-proof.tsv"
CAMERA_FIND_FLOOR_REPORT="$RUN_ROOT/reports/camera-find-floor-report.tsv"
CAMERA_FIND_FLOOR_PROOF="$RUN_ROOT/reports/camera-find-floor-proof.tsv"
DISPLAY_LIST_REPORT="$RUN_ROOT/reports/display-list-report.tsv"
DISPLAY_LIST_PROOF="$RUN_ROOT/reports/display-list-proof.tsv"
DISPLAY_LIST_NEXT_REPORT="$RUN_ROOT/reports/display-list-next-report.tsv"
DISPLAY_LIST_NEXT_PROOF="$RUN_ROOT/reports/display-list-next-proof.tsv"
RENDER_CALLBACK_REPORT="$RUN_ROOT/reports/render-callback-report.tsv"
RENDER_CALLBACK_PROOF="$RUN_ROOT/reports/render-callback-proof.tsv"
RNG_BREAK_PARTICLES_REPORT="$RUN_ROOT/reports/rng-break-particles-report.tsv"
RNG_BREAK_PARTICLES_PROOF="$RUN_ROOT/reports/rng-break-particles-proof.tsv"
TEXT_REPORT="$RUN_ROOT/reports/text-report.tsv"
TEXT_PROOF="$RUN_ROOT/reports/text-proof.tsv"
INSIDE_CASTLE_REPORT="$RUN_ROOT/reports/inside-castle-report.tsv"
INSIDE_CASTLE_PROOF="$RUN_ROOT/reports/inside-castle-proof.tsv"
DOOR_REPORT="$RUN_ROOT/reports/door-report.tsv"
DOOR_PROOF="$RUN_ROOT/reports/door-proof.tsv"
AUDIO_ASSET_REPORT="$RUN_ROOT/reports/audio-asset-report.tsv"
PENDULUM_REPORT="$RUN_ROOT/reports/pendulum-report.tsv"

REPORTS=(
  "$INPUT_REPORT" "$MARIO_REPORT" "$CAMERA_REPORT" "$GLOBAL_REPORT"
  "$OBJECT_REPORT" "$SCRIPT_REPORT" "$COLLISION_REPORT" "$RNG_REPORT"
  "$AUDIO_REPORT" "$SAVE_REPORT" "$RENDER_REPORT" "$AUDIO_PCM_REPORT"
  "$INTERACTION_REPORT" "$EFFECTS_REPORT" "$SAVE_MUTATION_REPORT"
  "$CAMERA_FIND_FLOOR_REPORT" "$DISPLAY_LIST_REPORT" "$DISPLAY_LIST_NEXT_REPORT"
  "$RENDER_CALLBACK_REPORT" "$RNG_BREAK_PARTICLES_REPORT" "$TEXT_REPORT"
  "$INSIDE_CASTLE_REPORT" "$DOOR_REPORT" "$AUDIO_ASSET_REPORT" "$PENDULUM_REPORT"
)
PROOFS=(
  "$INPUT_PROOF" "$MARIO_PROOF" "$CAMERA_PROOF" "$GLOBAL_PROOF"
  "$OBJECT_PROOF" "$SCRIPT_PROOF" "$COLLISION_PROOF" "$RNG_PROOF"
  "$AUDIO_PROOF" "$SAVE_PROOF" "$RENDER_PROOF" "$AUDIO_PCM_PROOF"
  "$INTERACTION_PROOF" "$EFFECTS_PROOF" "$SAVE_MUTATION_PROOF"
  "$CAMERA_FIND_FLOOR_PROOF" "$DISPLAY_LIST_PROOF" "$DISPLAY_LIST_NEXT_PROOF"
  "$RENDER_CALLBACK_PROOF" "$RNG_BREAK_PARTICLES_PROOF" "$TEXT_PROOF"
  "$INSIDE_CASTLE_PROOF" "$DOOR_PROOF" "$RUN_ROOT/reports/audio-asset-proof.tsv"
  "$PENDULUM_PROOF"
)
for path in "${REPORTS[@]}" "${PROOFS[@]}"; do require_file "$path"; done
[[ "${#REPORTS[@]}" -eq 25 && "${#PROOFS[@]}" -eq 25 ]]

# Snapshot every external input and every artifact named by its proof. This
# makes the no-mutation boundary executable instead of relying on convention.
IMMUTABLE_SNAPSHOT="$RUN_ROOT/immutable-inputs.tsv"
: >"$IMMUTABLE_SNAPSHOT"
snapshot() { printf '%s|%s\n' "$1" "$(sha256_file "$1")" >>"$IMMUTABLE_SNAPSHOT"; }
snapshot "$SOURCE_MANIFEST"
snapshot "$DESIGNATED_REPORT"
snapshot "$BACKUP_REPORT"
snapshot "$AUDIO_ROOT/audio-asset-isolated-report.tsv"
snapshot "$AUDIO_ROOT/audio-asset-proof.tsv"
snapshot "$PENDULUM_ROOT/pendulum-isolated-report.tsv"
snapshot "$PENDULUM_ROOT/pendulum-proof.tsv"
for proof in "${PROOFS[@]}"; do
  while IFS= read -r artifact; do
    [[ -n "$artifact" ]] && snapshot "$artifact"
  done < <(awk -F'|' 'NR == 3 { for (i = 7; i <= NF; i += 2) print $i }' "$proof")
done

TOOL="$TOOL_ROOT/sm64-canonical-route-ledger-merge"
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64CanonicalRouteLedgerMergeTool.swift" -o "$TOOL"

merge_args() {
  local output="$1"
  local input_report="${2:-$INPUT_REPORT}"
  local input_proof="${3:-$INPUT_PROOF}"
  MERGE_ARGS=(
    --manifest "$MANIFEST"
    --input-report "$input_report" --input-proof "$input_proof"
    --mario-report "$MARIO_REPORT" --mario-proof "$MARIO_PROOF"
    --camera-report "$CAMERA_REPORT" --camera-proof "$CAMERA_PROOF"
    --global-report "$GLOBAL_REPORT" --global-proof "$GLOBAL_PROOF"
    --object-report "$OBJECT_REPORT" --object-proof "$OBJECT_PROOF"
    --script-report "$SCRIPT_REPORT" --script-proof "$SCRIPT_PROOF"
    --collision-report "$COLLISION_REPORT" --collision-proof "$COLLISION_PROOF"
    --rng-report "$RNG_REPORT" --rng-proof "$RNG_PROOF"
    --audio-report "$AUDIO_REPORT" --audio-proof "$AUDIO_PROOF"
    --save-report "$SAVE_REPORT" --save-proof "$SAVE_PROOF"
    --render-report "$RENDER_REPORT" --render-proof "$RENDER_PROOF"
    --audio-pcm-report "$AUDIO_PCM_REPORT" --audio-pcm-proof "$AUDIO_PCM_PROOF"
    --interaction-report "$INTERACTION_REPORT" --interaction-proof "$INTERACTION_PROOF"
    --effects-report "$EFFECTS_REPORT" --effects-proof "$EFFECTS_PROOF"
    --save-mutation-report "$SAVE_MUTATION_REPORT" --save-mutation-proof "$SAVE_MUTATION_PROOF"
    --camera-find-floor-report "$CAMERA_FIND_FLOOR_REPORT" --camera-find-floor-proof "$CAMERA_FIND_FLOOR_PROOF"
    --display-list-report "$DISPLAY_LIST_REPORT" --display-list-proof "$DISPLAY_LIST_PROOF"
    --display-list-next-report "$DISPLAY_LIST_NEXT_REPORT" --display-list-next-proof "$DISPLAY_LIST_NEXT_PROOF"
    --render-callback-report "$RENDER_CALLBACK_REPORT" --render-callback-proof "$RENDER_CALLBACK_PROOF"
    --rng-break-particles-report "$RNG_BREAK_PARTICLES_REPORT" --rng-break-particles-proof "$RNG_BREAK_PARTICLES_PROOF"
    --text-report "$TEXT_REPORT" --text-proof "$TEXT_PROOF"
    --inside-castle-report "$INSIDE_CASTLE_REPORT" --inside-castle-proof "$INSIDE_CASTLE_PROOF"
    --door-report "$DOOR_REPORT" --door-proof "$DOOR_PROOF"
    --audio-asset-report "$AUDIO_ASSET_REPORT" --audio-asset-proof "$RUN_ROOT/reports/audio-asset-proof.tsv"
    --pendulum-report "$PENDULUM_REPORT" --pendulum-proof "$PENDULUM_PROOF"
    --output "$output"
  )
}

OUTPUT="$RUN_ROOT/canonical-route-ledger.tsv"
merge_args "$OUTPUT"
"$TOOL" "${MERGE_ARGS[@]}" | tee "$RUN_ROOT/merge.log"
grep -Fq 'manifest_rows=7420 qualified_rows=25 planned=7395 terminal=25' "$RUN_ROOT/merge.log"
test "$(count_states "$OUTPUT")" = '25 7395'
test "$(sha256_file "$OUTPUT")" = "$BACKUP_REPORT_SHA256"
grep -Fq "$AUDIO_ASSET_ID|passed|1084|1084|1084|" "$OUTPUT"
grep -Fq "$PENDULUM_ID|passed|1056|1056|1056|" "$OUTPUT"

# A terminal rerun is rejected and cannot rewrite the successful isolated
# output. This is deliberately checked before any canonical path is involved.
OUTPUT_BEFORE="$(sha256_file "$OUTPUT")"
if "$TOOL" "${MERGE_ARGS[@]}" >"$RUN_ROOT/rerun.log" 2>&1; then
  echo 'phase85f136 terminal rerun unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'rerun rejected' "$RUN_ROOT/rerun.log"
test "$(sha256_file "$OUTPUT")" = "$OUTPUT_BEFORE"

# Duplicate target row must fail before a destination is created.
DUPLICATE_REPORT="$RUN_ROOT/negative-duplicate-report.tsv"
{ cat "$INPUT_REPORT"; head -n 1 "$INPUT_REPORT"; } >"$DUPLICATE_REPORT"
merge_args "$RUN_ROOT/negative-duplicate-output.tsv" "$DUPLICATE_REPORT"
if "$TOOL" "${MERGE_ARGS[@]}" >"$RUN_ROOT/duplicate.log" 2>&1; then
  echo 'phase85f136 duplicate target unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'duplicate report shard ID' "$RUN_ROOT/duplicate.log"
test ! -e "$RUN_ROOT/negative-duplicate-output.tsv"

# Missing target row must fail closed rather than being treated as a partial
# report or silently leaving the target planned.
MISSING_REPORT="$RUN_ROOT/negative-missing-report.tsv"
awk -F'|' -v target="$AUDIO_ASSET_ID" '$1 != target { print }' "$INPUT_REPORT" >"$MISSING_REPORT"
merge_args "$RUN_ROOT/negative-missing-output.tsv" "$MISSING_REPORT"
if "$TOOL" "${MERGE_ARGS[@]}" >"$RUN_ROOT/missing.log" 2>&1; then
  echo 'phase85f136 missing target unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'missing' "$RUN_ROOT/missing.log"
test ! -e "$RUN_ROOT/negative-missing-output.tsv"

# An output path colliding with the isolated manifest is rejected before any
# input is read or written. The source manifest hash is checked afterward.
MANIFEST_BEFORE="$(sha256_file "$MANIFEST")"
merge_args "$MANIFEST"
if "$TOOL" "${MERGE_ARGS[@]}" >"$RUN_ROOT/output-collision.log" 2>&1; then
  echo 'phase85f136 output collision unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'output paths collide' "$RUN_ROOT/output-collision.log"
test "$(sha256_file "$MANIFEST")" = "$MANIFEST_BEFORE"

# A stale report with an unchanged proof hash is rejected before output. This
# models a report copied from a prior manifest/run without mutating that source.
STALE_REPORT="$RUN_ROOT/negative-stale-report.tsv"
STALE_TARGET=0xd9446dfed10e189e
awk -F'|' -v OFS='|' -v target="$STALE_TARGET" \
  '$1 == target { $2 = "planned"; $3 = 0; $4 = 0; $5 = 0; $6 = "" } { print }' \
  "$INPUT_REPORT" >"$STALE_REPORT"
merge_args "$RUN_ROOT/negative-stale-output.tsv" "$STALE_REPORT"
if "$TOOL" "${MERGE_ARGS[@]}" >"$RUN_ROOT/stale.log" 2>&1; then
  echo 'phase85f136 stale report unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'report hash mismatch' "$RUN_ROOT/stale.log"
test ! -e "$RUN_ROOT/negative-stale-output.tsv"

# Re-read every external path, including proof artifacts, to prove the dry-run
# did not mutate designated/backup reports, manifests, route history, or any
# retained evidence artifact.
while IFS='|' read -r path expected; do
  test "$(sha256_file "$path")" = "$expected"
done <"$IMMUTABLE_SNAPSHOT"
test "$(sha256_file "$SOURCE_MANIFEST")" = "$MANIFEST_SHA256"
test "$(sha256_file "$BACKUP_REPORT")" = "$BACKUP_REPORT_SHA256"
test "$(sha256_file "$DESIGNATED_REPORT")" = "$DESIGNATED_REPORT_SHA256"
test "$(count_states "$BACKUP_REPORT")" = '25 7395'
test "$(count_states "$DESIGNATED_REPORT")" = '26 7394'

printf '%s\n' \
  'SM64 Modern Phase85f136 canonical merge-tool drift fix passed' \
  'target_set=25 shell_swift_reconciled=1' \
  'isolated_manifest_rows=7420 isolated_terminal=25 isolated_planned=7395' \
  'retained_backup_terminal=25 retained_backup_planned=7395 designated_terminal=26 designated_planned=7394' \
  'duplicate_target_rejected=1 missing_target_rejected=1 output_collision_rejected=1 stale_report_rejected=1 terminal_rerun_rejected=1' \
  'designated_mutated=0 backup_mutated=0 manifest_mutated=0 evidence_artifacts_mutated=0 canonical_publication=0' \
  "manifest_sha256=$(sha256_file "$SOURCE_MANIFEST")" \
  "isolated_output_sha256=$(sha256_file "$OUTPUT")" \
  "run_root=$RUN_ROOT" | tee "$RUN_ROOT/phase-summary.log"
