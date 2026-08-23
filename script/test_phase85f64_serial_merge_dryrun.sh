#!/usr/bin/env bash
set -euo pipefail
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_ROOT="${SM64_PHASE85F64_BASE_ROOT:-$PROJECT_ROOT/build/sm64-modern-phase85h-canonical-ledger/run.ACmfTD}"
AUDIO_ROOT="${SM64_PHASE85F64_AUDIO_ROOT:-$PROJECT_ROOT/build/sm64-modern-phase85f0-audio-asset-admission/run.1i26xf}"
PENDULUM_ROOT="${SM64_PHASE85F64_PENDULUM_ROOT:-$PROJECT_ROOT/build/sm64-modern-phase85f4-pendulum-admission/run.YLW2s7}"
INTRO_ROOT="${SM64_PHASE85F64_INTRO_ROOT:-$PROJECT_ROOT/build/sm64-modern-intro-transition-route-admission/run.OachXR}"
BUILD_ROOT="${SM64_PHASE85F64_BUILD_ROOT:-$PROJECT_ROOT/build/sm64-modern-phase85f64-serial-merge-dryrun}"

MANIFEST_HASH_EXPECTED=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
FIRST_STAGE_HASH_EXPECTED=aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d
FINAL_STAGE_HASH_EXPECTED=4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4
INTRO_REPORT_HASH_EXPECTED=6563b63155e1b5f4465b30dd51c5c60a02bfe08459f8e6885549ed716ceef7d2
INTRO_PROOF_HASH_EXPECTED=c6de62ac55499a20d92ac5d7ec67cb328d569df276219bfde53f95b85900fc51

mkdir -p "$BUILD_ROOT"
RUN_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
TOOL_ROOT="$RUN_ROOT/tool"
MODULE_CACHE="$TOOL_ROOT/module-cache"
mkdir -p "$MODULE_CACHE"

REACHABILITY_TOOL="$TOOL_ROOT/sm64-oracle-reachability"
MANIFEST_TOOL="$TOOL_ROOT/sm64-route-shards"
CANONICAL_TOOL="$TOOL_ROOT/canonical-merge"
INTRO_TOOL="$TOOL_ROOT/intro-merge"
SERIAL_TOOL="$TOOL_ROOT/serial-merge-dryrun"
INVENTORY="$RUN_ROOT/reachability.tsv"
MANIFEST="$RUN_ROOT/route-shards.tsv"
FIRST_OUTPUT="$RUN_ROOT/canonical-route-ledger.tsv"
FINAL_OUTPUT="$RUN_ROOT/canonical-route-ledger-final.tsv"

sha256_file() { shasum -a 256 "$1" | awk '{ print $1 }'; }

for required in \
  "$BASE_ROOT/route-shards.tsv" \
  "$BASE_ROOT/input-report.tsv" "$BASE_ROOT/input-proof.tsv" \
  "$BASE_ROOT/mario-report.tsv" "$BASE_ROOT/mario-proof.tsv" \
  "$BASE_ROOT/camera-report.tsv" "$BASE_ROOT/camera-proof.tsv" \
  "$BASE_ROOT/global-report.tsv" "$BASE_ROOT/global-proof.tsv" \
  "$BASE_ROOT/object-report.tsv" "$BASE_ROOT/object-proof.tsv" \
  "$BASE_ROOT/script-report.tsv" "$BASE_ROOT/script-proof.tsv" \
  "$BASE_ROOT/collision-report.tsv" "$BASE_ROOT/collision-proof.tsv" \
  "$BASE_ROOT/rng-report.tsv" "$BASE_ROOT/rng-proof.tsv" \
  "$BASE_ROOT/audio-report.tsv" "$BASE_ROOT/audio-proof.tsv" \
  "$BASE_ROOT/save-report.tsv" "$BASE_ROOT/save-proof.tsv" \
  "$BASE_ROOT/render-report.tsv" "$BASE_ROOT/render-proof.tsv" \
  "$BASE_ROOT/audio-pcm-report.tsv" "$BASE_ROOT/pcm-proof.tsv" \
  "$BASE_ROOT/interaction-report.tsv" "$BASE_ROOT/interaction-proof.tsv" \
  "$BASE_ROOT/effects-report.tsv" "$BASE_ROOT/effects-proof.tsv" \
  "$BASE_ROOT/save-mutation-report.tsv" "$BASE_ROOT/save-mutation-proof.tsv" \
  "$BASE_ROOT/camera-find-floor-report.tsv" "$BASE_ROOT/camera-find-floor-proof.tsv" \
  "$BASE_ROOT/display-list-report.tsv" "$BASE_ROOT/display-list-proof.tsv" \
  "$BASE_ROOT/display-list-next-report.tsv" "$BASE_ROOT/display-list-next-proof.tsv" \
  "$BASE_ROOT/render-callback-report.tsv" "$BASE_ROOT/render-callback-proof.tsv" \
  "$BASE_ROOT/rng-break-particles-report.tsv" "$BASE_ROOT/rng-break-particles-proof.tsv" \
  "$BASE_ROOT/text-report.tsv" "$BASE_ROOT/text-proof.tsv" \
  "$BASE_ROOT/inside-castle-report.tsv" "$BASE_ROOT/inside-castle-proof.tsv" \
  "$BASE_ROOT/door-report.tsv" "$BASE_ROOT/door-proof.tsv" \
  "$AUDIO_ROOT/audio-asset-isolated-report.tsv" "$AUDIO_ROOT/audio-asset-proof.tsv" \
  "$PENDULUM_ROOT/pendulum-isolated-report.tsv" "$PENDULUM_ROOT/pendulum-proof.tsv" \
  "$INTRO_ROOT/intro-transition-isolated-report.tsv" "$INTRO_ROOT/intro-transition-isolated-proof.tsv"; do
  test -s "$required"
done

IMMUTABLE_INPUTS=(
  "$BASE_ROOT/input-report.tsv" "$BASE_ROOT/input-proof.tsv"
  "$BASE_ROOT/mario-report.tsv" "$BASE_ROOT/mario-proof.tsv"
  "$BASE_ROOT/camera-report.tsv" "$BASE_ROOT/camera-proof.tsv"
  "$BASE_ROOT/global-report.tsv" "$BASE_ROOT/global-proof.tsv"
  "$BASE_ROOT/object-report.tsv" "$BASE_ROOT/object-proof.tsv"
  "$BASE_ROOT/script-report.tsv" "$BASE_ROOT/script-proof.tsv"
  "$BASE_ROOT/collision-report.tsv" "$BASE_ROOT/collision-proof.tsv"
  "$BASE_ROOT/rng-report.tsv" "$BASE_ROOT/rng-proof.tsv"
  "$BASE_ROOT/audio-report.tsv" "$BASE_ROOT/audio-proof.tsv"
  "$BASE_ROOT/save-report.tsv" "$BASE_ROOT/save-proof.tsv"
  "$BASE_ROOT/render-report.tsv" "$BASE_ROOT/render-proof.tsv"
  "$BASE_ROOT/audio-pcm-report.tsv" "$BASE_ROOT/pcm-proof.tsv"
  "$BASE_ROOT/interaction-report.tsv" "$BASE_ROOT/interaction-proof.tsv"
  "$BASE_ROOT/effects-report.tsv" "$BASE_ROOT/effects-proof.tsv"
  "$BASE_ROOT/save-mutation-report.tsv" "$BASE_ROOT/save-mutation-proof.tsv"
  "$BASE_ROOT/camera-find-floor-report.tsv" "$BASE_ROOT/camera-find-floor-proof.tsv"
  "$BASE_ROOT/display-list-report.tsv" "$BASE_ROOT/display-list-proof.tsv"
  "$BASE_ROOT/display-list-next-report.tsv" "$BASE_ROOT/display-list-next-proof.tsv"
  "$BASE_ROOT/render-callback-report.tsv" "$BASE_ROOT/render-callback-proof.tsv"
  "$BASE_ROOT/rng-break-particles-report.tsv" "$BASE_ROOT/rng-break-particles-proof.tsv"
  "$BASE_ROOT/text-report.tsv" "$BASE_ROOT/text-proof.tsv"
  "$BASE_ROOT/inside-castle-report.tsv" "$BASE_ROOT/inside-castle-proof.tsv"
  "$BASE_ROOT/door-report.tsv" "$BASE_ROOT/door-proof.tsv"
  "$AUDIO_ROOT/audio-asset-isolated-report.tsv" "$AUDIO_ROOT/audio-asset-proof.tsv"
  "$PENDULUM_ROOT/pendulum-isolated-report.tsv" "$PENDULUM_ROOT/pendulum-proof.tsv"
  "$INTRO_ROOT/intro-transition-isolated-report.tsv" "$INTRO_ROOT/intro-transition-isolated-proof.tsv"
)

BEFORE_HASHES="$RUN_ROOT/immutable-inputs.before.sha256"
: >"$BEFORE_HASHES"
for path in "$BASE_ROOT/route-shards.tsv" "${IMMUTABLE_INPUTS[@]}"; do
  printf '%s|%s\n' "$path" "$(sha256_file "$path")"
done | tee "$BEFORE_HASHES" >/dev/null

xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/tools/SM64OracleReachabilityTool.swift" -o "$REACHABILITY_TOOL"
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/tools/SM64RouteShardManifestTool.swift" -o "$MANIFEST_TOOL"
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64CanonicalRouteLedgerMergeTool.swift" -o "$CANONICAL_TOOL"
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/tools/SM64IntroTransitionCanonicalMergeTool.swift" -o "$INTRO_TOOL"
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/tools/SM64SerialCanonicalMergeDryRunTool.swift" -o "$SERIAL_TOOL"

"$REACHABILITY_TOOL" --root "$PROJECT_ROOT" --output "$INVENTORY" >"$RUN_ROOT/reachability.log"
"$MANIFEST_TOOL" --inventory "$INVENTORY" --output "$MANIFEST" >"$RUN_ROOT/manifest.log"
test "$(awk '$0 !~ /^#/ && NF { n++ } END { print n + 0 }' "$INVENTORY")" -eq 7420
test "$(awk -F'|' '$0 !~ /^#/ && NF { n++ } END { print n + 0 }' "$MANIFEST")" -eq 7420
test "$(sha256_file "$MANIFEST")" = "$MANIFEST_HASH_EXPECTED"

build_args() {
  local first="$1"
  local final="$2"
  local manifest_path="${MANIFEST_OVERRIDE:-$MANIFEST}"
  local input_report="${INPUT_REPORT_OVERRIDE:-$BASE_ROOT/input-report.tsv}"
  local input_proof="${INPUT_PROOF_OVERRIDE:-$BASE_ROOT/input-proof.tsv}"
  local intro_report="${INTRO_REPORT_OVERRIDE:-$INTRO_ROOT/intro-transition-isolated-report.tsv}"
  local intro_proof="${INTRO_PROOF_OVERRIDE:-$INTRO_ROOT/intro-transition-isolated-proof.tsv}"
  SERIAL_ARGS=(
    "$SERIAL_TOOL" --canonical-tool "$CANONICAL_TOOL" --intro-tool "$INTRO_TOOL"
    --manifest "$manifest_path"
    --pair input "$input_report" "$input_proof"
    --pair mario "$BASE_ROOT/mario-report.tsv" "$BASE_ROOT/mario-proof.tsv"
    --pair camera "$BASE_ROOT/camera-report.tsv" "$BASE_ROOT/camera-proof.tsv"
    --pair global "$BASE_ROOT/global-report.tsv" "$BASE_ROOT/global-proof.tsv"
    --pair object "$BASE_ROOT/object-report.tsv" "$BASE_ROOT/object-proof.tsv"
    --pair script "$BASE_ROOT/script-report.tsv" "$BASE_ROOT/script-proof.tsv"
    --pair collision "$BASE_ROOT/collision-report.tsv" "$BASE_ROOT/collision-proof.tsv"
    --pair rng "$BASE_ROOT/rng-report.tsv" "$BASE_ROOT/rng-proof.tsv"
    --pair audio "$BASE_ROOT/audio-report.tsv" "$BASE_ROOT/audio-proof.tsv"
    --pair save "$BASE_ROOT/save-report.tsv" "$BASE_ROOT/save-proof.tsv"
    --pair render "$BASE_ROOT/render-report.tsv" "$BASE_ROOT/render-proof.tsv"
    --pair audio-pcm "$BASE_ROOT/audio-pcm-report.tsv" "$BASE_ROOT/pcm-proof.tsv"
    --pair interaction "$BASE_ROOT/interaction-report.tsv" "$BASE_ROOT/interaction-proof.tsv"
    --pair effects "$BASE_ROOT/effects-report.tsv" "$BASE_ROOT/effects-proof.tsv"
    --pair save-mutation "$BASE_ROOT/save-mutation-report.tsv" "$BASE_ROOT/save-mutation-proof.tsv"
    --pair camera-find-floor "$BASE_ROOT/camera-find-floor-report.tsv" "$BASE_ROOT/camera-find-floor-proof.tsv"
    --pair display-list "$BASE_ROOT/display-list-report.tsv" "$BASE_ROOT/display-list-proof.tsv"
    --pair display-list-next "$BASE_ROOT/display-list-next-report.tsv" "$BASE_ROOT/display-list-next-proof.tsv"
    --pair render-callback "$BASE_ROOT/render-callback-report.tsv" "$BASE_ROOT/render-callback-proof.tsv"
    --pair rng-break-particles "$BASE_ROOT/rng-break-particles-report.tsv" "$BASE_ROOT/rng-break-particles-proof.tsv"
    --pair text "$BASE_ROOT/text-report.tsv" "$BASE_ROOT/text-proof.tsv"
    --pair inside-castle "$BASE_ROOT/inside-castle-report.tsv" "$BASE_ROOT/inside-castle-proof.tsv"
    --pair door "$BASE_ROOT/door-report.tsv" "$BASE_ROOT/door-proof.tsv"
    --pair audio-asset "$AUDIO_ROOT/audio-asset-isolated-report.tsv" "$AUDIO_ROOT/audio-asset-proof.tsv"
    --pair pendulum "$PENDULUM_ROOT/pendulum-isolated-report.tsv" "$PENDULUM_ROOT/pendulum-proof.tsv"
    --intro-report "$intro_report" --intro-proof "$intro_proof"
    --first-output "$first" --final-output "$final"
  )
}

unset INPUT_REPORT_OVERRIDE INPUT_PROOF_OVERRIDE INTRO_REPORT_OVERRIDE INTRO_PROOF_OVERRIDE MANIFEST_OVERRIDE
build_args "$FIRST_OUTPUT" "$FINAL_OUTPUT"
"${SERIAL_ARGS[@]}" | tee "$RUN_ROOT/serial.log"
test "$(sha256_file "$FIRST_OUTPUT")" = "$FIRST_STAGE_HASH_EXPECTED"
test "$(sha256_file "$FINAL_OUTPUT")" = "$FINAL_STAGE_HASH_EXPECTED"
test "$(awk -F'|' '$2 == "passed" { n++ } END { print n + 0 }' "$FIRST_OUTPUT")" -eq 25
test "$(awk -F'|' '$2 == "planned" { n++ } END { print n + 0 }' "$FIRST_OUTPUT")" -eq 7395
test "$(awk -F'|' '$2 == "passed" { n++ } END { print n + 0 }' "$FINAL_OUTPUT")" -eq 26
test "$(awk -F'|' '$2 == "planned" { n++ } END { print n + 0 }' "$FINAL_OUTPUT")" -eq 7394
grep -Fq '0xca33981b30cb7815|planned|0|0|0|' "$FIRST_OUTPUT"
grep -Fq '0xca33981b30cb7815|passed|2|2|2|' "$FINAL_OUTPUT"
! grep -Fq '0x9a0f7b4f7ecf6c41|' "$FINAL_OUTPUT"

# A second pair of fresh paths must be byte-identical. Reusing the first
# output path is a terminal rerun and must fail before either stage runs.
SECOND_FIRST="$RUN_ROOT/canonical-route-ledger-second.tsv"
SECOND_FINAL="$RUN_ROOT/canonical-route-ledger-second-final.tsv"
build_args "$SECOND_FIRST" "$SECOND_FINAL"
"${SERIAL_ARGS[@]}" >"$RUN_ROOT/deterministic.log"
cmp -s "$FIRST_OUTPUT" "$SECOND_FIRST"
cmp -s "$FINAL_OUTPUT" "$SECOND_FINAL"

build_args "$FIRST_OUTPUT" "$FINAL_OUTPUT"
if "${SERIAL_ARGS[@]}" >"$RUN_ROOT/terminal-rerun.log" 2>&1; then
  echo 'phase85f64 terminal rerun unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'terminal rerun rejected' "$RUN_ROOT/terminal-rerun.log"

# Duplicate target rows are rejected by the existing 25-target merge before
# it can write the first-stage output.
DUPLICATE_REPORT="$RUN_ROOT/duplicate-input-report.tsv"
awk 'NR == 1 { print; print } NR > 1 { print }' "$BASE_ROOT/input-report.tsv" >"$DUPLICATE_REPORT"
INPUT_REPORT_OVERRIDE="$DUPLICATE_REPORT"
build_args "$RUN_ROOT/duplicate-first.tsv" "$RUN_ROOT/duplicate-final.tsv"
if "${SERIAL_ARGS[@]}" >"$RUN_ROOT/duplicate-target.log" 2>&1; then
  echo 'phase85f64 duplicate target unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'duplicate report shard ID' "$RUN_ROOT/duplicate-target.log"
test ! -e "$RUN_ROOT/duplicate-first.tsv"
test ! -e "$RUN_ROOT/duplicate-final.tsv"
unset INPUT_REPORT_OVERRIDE

# A conflicting passed row under the input identity must remain rejected.
CONFLICTING_REPORT="$RUN_ROOT/conflicting-input-report.tsv"
CONFLICTING_PROOF="$RUN_ROOT/conflicting-input-proof.tsv"
cp "$BASE_ROOT/mario-report.tsv" "$CONFLICTING_REPORT"
sed "s/$(sha256_file "$BASE_ROOT/input-report.tsv")/$(sha256_file "$BASE_ROOT/mario-report.tsv")/" \
  "$BASE_ROOT/input-proof.tsv" >"$CONFLICTING_PROOF"
INPUT_REPORT_OVERRIDE="$CONFLICTING_REPORT"
INPUT_PROOF_OVERRIDE="$CONFLICTING_PROOF"
build_args "$RUN_ROOT/conflicting-first.tsv" "$RUN_ROOT/conflicting-final.tsv"
if "${SERIAL_ARGS[@]}" >"$RUN_ROOT/conflicting-target.log" 2>&1; then
  echo 'phase85f64 conflicting target unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'not pristine planned' "$RUN_ROOT/conflicting-target.log"
test ! -e "$RUN_ROOT/conflicting-first.tsv"
test ! -e "$RUN_ROOT/conflicting-final.tsv"
unset INPUT_REPORT_OVERRIDE INPUT_PROOF_OVERRIDE

# Fixture-only evidence cannot enter the first stage.
FIXTURE_PROOF="$RUN_ROOT/fixture-input-proof.tsv"
awk -F'|' -v OFS='|' 'NR == 3 { $4 = 1 } { print }' "$BASE_ROOT/input-proof.tsv" >"$FIXTURE_PROOF"
INPUT_PROOF_OVERRIDE="$FIXTURE_PROOF"
build_args "$RUN_ROOT/fixture-first.tsv" "$RUN_ROOT/fixture-final.tsv"
if "${SERIAL_ARGS[@]}" >"$RUN_ROOT/fixture-proof.log" 2>&1; then
  echo 'phase85f64 fixture-only proof unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'fixture_only evidence is not allowed' "$RUN_ROOT/fixture-proof.log"
test ! -e "$RUN_ROOT/fixture-first.tsv"
test ! -e "$RUN_ROOT/fixture-final.tsv"
unset INPUT_PROOF_OVERRIDE

# Missing artifacts in either retained proof family fail before stage one.
MISSING_PROOF="$RUN_ROOT/missing-intro-proof.tsv"
awk -F'|' -v OFS='|' -v missing="$RUN_ROOT/missing-intro-artifact.trace" 'NR == 3 { $7 = missing } { print }' \
  "$INTRO_ROOT/intro-transition-isolated-proof.tsv" >"$MISSING_PROOF"
INTRO_PROOF_OVERRIDE="$MISSING_PROOF"
build_args "$RUN_ROOT/missing-first.tsv" "$RUN_ROOT/missing-final.tsv"
if "${SERIAL_ARGS[@]}" >"$RUN_ROOT/missing-artifact.log" 2>&1; then
  echo 'phase85f64 missing proof artifact unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'missing retained proof artifact' "$RUN_ROOT/missing-artifact.log"
test ! -e "$RUN_ROOT/missing-first.tsv"
test ! -e "$RUN_ROOT/missing-final.tsv"
unset INTRO_PROOF_OVERRIDE

# Manifest and report/proof hash mismatches fail closed before publication.
TAMPERED_MANIFEST="$RUN_ROOT/tampered-manifest.tsv"
sed 's/|planned|deterministic route shard/|blocked|deterministic route shard/' "$MANIFEST" >"$TAMPERED_MANIFEST"
MANIFEST_OVERRIDE="$TAMPERED_MANIFEST"
build_args "$RUN_ROOT/tampered-manifest-first.tsv" "$RUN_ROOT/tampered-manifest-final.tsv"
if "${SERIAL_ARGS[@]}" >"$RUN_ROOT/tampered-manifest.log" 2>&1; then
  echo 'phase85f64 manifest mismatch unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'manifest SHA-256 mismatch' "$RUN_ROOT/tampered-manifest.log"
test ! -e "$RUN_ROOT/tampered-manifest-first.tsv"
test ! -e "$RUN_ROOT/tampered-manifest-final.tsv"
unset MANIFEST_OVERRIDE

TAMPERED_INTRO_REPORT="$RUN_ROOT/tampered-intro-report.tsv"
sed 's/|passed|2|2|2|/|passed|2|2|1|/' "$INTRO_ROOT/intro-transition-isolated-report.tsv" >"$TAMPERED_INTRO_REPORT"
INTRO_REPORT_OVERRIDE="$TAMPERED_INTRO_REPORT"
build_args "$RUN_ROOT/tampered-intro-first.tsv" "$RUN_ROOT/tampered-intro-final.tsv"
if "${SERIAL_ARGS[@]}" >"$RUN_ROOT/tampered-intro.log" 2>&1; then
  echo 'phase85f64 intro report mismatch unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'Phase85f32 report SHA-256 mismatch' "$RUN_ROOT/tampered-intro.log"
test ! -e "$RUN_ROOT/tampered-intro-final.tsv"
unset INTRO_REPORT_OVERRIDE

# An output path that names any immutable input is rejected without touching
# that retained report.
build_args "$BASE_ROOT/input-report.tsv" "$RUN_ROOT/collision-final.tsv"
if "${SERIAL_ARGS[@]}" >"$RUN_ROOT/output-collision.log" 2>&1; then
  echo 'phase85f64 output collision unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'output path collides with an immutable input' "$RUN_ROOT/output-collision.log"

# The retained manifest, all 25 report/proof pairs, and both intro inputs are
# read-only evidence. Their hashes must match the preflight snapshot.
while IFS='|' read -r path expected; do
  test "$(sha256_file "$path")" = "$expected"
done <"$BEFORE_HASHES"
test "$(sha256_file "$MANIFEST")" = "$MANIFEST_HASH_EXPECTED"

printf '%s\n' \
  'SM64 Modern Phase85f64 serial canonical merge dry-run passed' \
  'first_stage_pairs=25 first_stage_passed=25 first_stage_planned=7395' \
  'second_stage_target=0x9a0f7b4f7ecf6c41 canonical_target=0xca33981b30cb7815' \
  'final_stage_passed=26 final_stage_planned=7394 published_canonical_state=0' \
  'duplicate_target_rejected=1 conflicting_target_rejected=1 fixture_only_rejected=1' \
  'missing_proof_artifact_rejected=1 manifest_hash_mismatch_rejected=1 intro_report_hash_mismatch_rejected=1' \
  'output_collision_rejected=1 terminal_rerun_rejected=1 deterministic_output=1' \
  "manifest_sha256=$(sha256_file "$MANIFEST")" \
  "first_stage_sha256=$(sha256_file "$FIRST_OUTPUT")" \
  "final_stage_sha256=$(sha256_file "$FINAL_OUTPUT")" \
  "intro_report_sha256=$(sha256_file "$INTRO_ROOT/intro-transition-isolated-report.tsv")" \
  "intro_proof_sha256=$(sha256_file "$INTRO_ROOT/intro-transition-isolated-proof.tsv")" \
  'retained_manifest_mutated=0 retained_reports_mutated=0 retained_proofs_mutated=0 canonical_ledger_overwrite=0' \
  "run_root=$RUN_ROOT" | tee "$RUN_ROOT/phase-summary.log"
