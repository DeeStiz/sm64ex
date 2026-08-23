#!/usr/bin/env bash
set -euo pipefail
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="${SM64_PHASE85F33_BUILD_ROOT:-$PROJECT_ROOT/build/sm64-modern-phase85f33-intro-transition-canonical-merge}"
PRIOR_REPORT="${SM64_PHASE85F33_PRIOR_REPORT:-$PROJECT_ROOT/build/sm64-modern-phase85f5-pendulum-canonical-merge/run.czR8zi/canonical-route-ledger.tsv}"
INTRO_ROOT="${SM64_PHASE85F33_INTRO_ROOT:-$PROJECT_ROOT/build/sm64-modern-intro-transition-route-admission/run.OachXR}"
TARGET_REPORT="${SM64_PHASE85F33_TARGET_REPORT:-$INTRO_ROOT/intro-transition-isolated-report.tsv}"
TARGET_PROOF="${SM64_PHASE85F33_TARGET_PROOF:-$INTRO_ROOT/intro-transition-isolated-proof.tsv}"

mkdir -p "$BUILD_ROOT"
RUN_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
TOOL_ROOT="$RUN_ROOT/tool"
MODULE_CACHE="$TOOL_ROOT/module-cache"
REACHABILITY_TOOL="$TOOL_ROOT/sm64-oracle-reachability"
MANIFEST_TOOL="$TOOL_ROOT/sm64-route-shards"
MERGE_TOOL="$TOOL_ROOT/merge"
INVENTORY="$RUN_ROOT/reachability.tsv"
MANIFEST="$RUN_ROOT/route-shards.tsv"
OUTPUT="$RUN_ROOT/canonical-route-ledger.tsv"
DETERMINISTIC_OUTPUT="$RUN_ROOT/canonical-route-ledger-second.tsv"

mkdir -p "$MODULE_CACHE"
for required in "$PRIOR_REPORT" "$TARGET_REPORT" "$TARGET_PROOF"; do
  test -s "$required"
done

sha256_file() { shasum -a 256 "$1" | awk '{ print $1 }'; }

PRIOR_BEFORE="$(sha256_file "$PRIOR_REPORT")"
TARGET_REPORT_BEFORE="$(sha256_file "$TARGET_REPORT")"
TARGET_PROOF_BEFORE="$(sha256_file "$TARGET_PROOF")"

# Regenerate both inputs in this phase-local root. The canonical manifest and
# all retained reports remain read-only evidence.
xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/tools/SM64OracleReachabilityTool.swift" \
  -o "$REACHABILITY_TOOL"
xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/tools/SM64RouteShardManifestTool.swift" \
  -o "$MANIFEST_TOOL"
xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$MODULE_CACHE" \
  "$PROJECT_ROOT/tools/SM64IntroTransitionCanonicalMergeTool.swift" \
  -o "$MERGE_TOOL"

"$REACHABILITY_TOOL" --root "$PROJECT_ROOT" --output "$INVENTORY" >"$RUN_ROOT/reachability.log"
"$MANIFEST_TOOL" --inventory "$INVENTORY" --output "$MANIFEST" >"$RUN_ROOT/manifest.log"

test "$(awk '$0 !~ /^#/ && NF { count++ } END { print count + 0 }' "$INVENTORY")" -eq 7420
test "$(awk -F'|' '$0 !~ /^#/ && NF { count++ } END { print count + 0 }' "$MANIFEST")" -eq 7420
MANIFEST_SHA256="$(sha256_file "$MANIFEST")"
test "$MANIFEST_SHA256" = 23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715

merge() {
  local output="$1"
  "$MERGE_TOOL" \
    --manifest "$MANIFEST" \
    --prior-report "$PRIOR_REPORT" \
    --target-report "$TARGET_REPORT" \
    --target-proof "$TARGET_PROOF" \
    --output "$output"
}

merge "$OUTPUT" | tee "$RUN_ROOT/merge.log"
grep -Fq 'manifest_rows=7420 prior_rows=7420 prior_passed=25 prior_planned=7395 qualified_rows=26 planned=7394 terminal=26' "$RUN_ROOT/merge.log"
grep -Fq 'admitted_target=0x9a0f7b4f7ecf6c41 canonical_target=0xca33981b30cb7815' "$RUN_ROOT/merge.log"
grep -Fq 'manifest_sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715' "$RUN_ROOT/merge.log"
grep -Fq 'prior_report_sha256=aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d' "$RUN_ROOT/merge.log"
grep -Fq 'output_sha256=4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4' "$RUN_ROOT/merge.log"
test "$(wc -l <"$OUTPUT" | tr -d '[:space:]')" -eq 7420
test "$(awk -F'|' '$2 == "passed" { n++ } END { print n + 0 }' "$OUTPUT")" -eq 26
test "$(awk -F'|' '$2 == "planned" { n++ } END { print n + 0 }' "$OUTPUT")" -eq 7394
grep -Fq '0xca33981b30cb7815|passed|2|2|2|' "$OUTPUT"
! grep -Fq '0x9a0f7b4f7ecf6c41|' "$OUTPUT"
test "$(sha256_file "$OUTPUT")" = 4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4

# A second fresh output path must produce byte-identical evidence, while a
# terminal rerun of the first path must be rejected before any write.
merge "$DETERMINISTIC_OUTPUT" >"$RUN_ROOT/deterministic.log"
cmp -s "$OUTPUT" "$DETERMINISTIC_OUTPUT"
if merge "$OUTPUT" >"$RUN_ROOT/rerun.log" 2>&1; then
  echo 'phase85f33 terminal rerun unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'terminal rerun rejected' "$RUN_ROOT/rerun.log"

# Duplicate target rows are rejected before the proof can be used. This is a
# fresh malformed copy; the retained report itself is never changed.
DUPLICATE_TARGET_REPORT="$RUN_ROOT/duplicate-target.report"
awk '{ print; if (NR == 1) print }' "$TARGET_REPORT" >"$DUPLICATE_TARGET_REPORT"
if "$MERGE_TOOL" \
  --manifest "$MANIFEST" \
  --prior-report "$PRIOR_REPORT" \
  --target-report "$DUPLICATE_TARGET_REPORT" \
  --target-proof "$TARGET_PROOF" \
  --output "$RUN_ROOT/duplicate-target.tsv" >"$RUN_ROOT/duplicate-target.log" 2>&1; then
  echo 'phase85f33 duplicate target unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'duplicate target row' "$RUN_ROOT/duplicate-target.log"
test ! -e "$RUN_ROOT/duplicate-target.tsv"

# Fixture promotion is forbidden even when the rest of the proof is intact.
TAMPERED_PROOF="$RUN_ROOT/tampered-proof.tsv"
cp "$TARGET_PROOF" "$TAMPERED_PROOF"
perl -0pi -e 's/\|0\|6563b63155e1b5f4465b30dd51c5c60a02bfe08459f8e6885549ed716ceef7d2\|/|1|6563b63155e1b5f4465b30dd51c5c60a02bfe08459f8e6885549ed716ceef7d2|/' "$TAMPERED_PROOF"
if "$MERGE_TOOL" \
  --manifest "$MANIFEST" \
  --prior-report "$PRIOR_REPORT" \
  --target-report "$TARGET_REPORT" \
  --target-proof "$TAMPERED_PROOF" \
  --output "$RUN_ROOT/tampered-proof-output.tsv" >"$RUN_ROOT/tampered-proof.log" 2>&1; then
  echo 'phase85f33 tampered proof unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'fixture_only evidence is not allowed' "$RUN_ROOT/tampered-proof.log"
test ! -e "$RUN_ROOT/tampered-proof-output.tsv"

# Prior report and manifest mismatches fail closed before output creation.
TAMPERED_PRIOR="$RUN_ROOT/tampered-prior.tsv"
cp "$PRIOR_REPORT" "$TAMPERED_PRIOR"
perl -0pi -e 's/\|planned\|0\|0\|0\|/|planned|1|0|0|/;' "$TAMPERED_PRIOR"
if "$MERGE_TOOL" \
  --manifest "$MANIFEST" \
  --prior-report "$TAMPERED_PRIOR" \
  --target-report "$TARGET_REPORT" \
  --target-proof "$TARGET_PROOF" \
  --output "$RUN_ROOT/tampered-prior-output.tsv" >"$RUN_ROOT/tampered-prior.log" 2>&1; then
  echo 'phase85f33 prior hash mismatch unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'report SHA-256 mismatch' "$RUN_ROOT/tampered-prior.log"
test ! -e "$RUN_ROOT/tampered-prior-output.tsv"

TAMPERED_MANIFEST="$RUN_ROOT/tampered-manifest.tsv"
cp "$MANIFEST" "$TAMPERED_MANIFEST"
perl -0pi -e 's/\|planned\|deterministic route shard/|blocked|deterministic route shard/;' "$TAMPERED_MANIFEST"
if "$MERGE_TOOL" \
  --manifest "$TAMPERED_MANIFEST" \
  --prior-report "$PRIOR_REPORT" \
  --target-report "$TARGET_REPORT" \
  --target-proof "$TARGET_PROOF" \
  --output "$RUN_ROOT/tampered-manifest-output.tsv" >"$RUN_ROOT/tampered-manifest.log" 2>&1; then
  echo 'phase85f33 manifest mismatch unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'manifest SHA-256 mismatch' "$RUN_ROOT/tampered-manifest.log"
test ! -e "$RUN_ROOT/tampered-manifest-output.tsv"

# Collision against any immutable input is rejected. The target report path
# is an existing file, so this also proves no canonical input is overwritten.
if "$MERGE_TOOL" \
  --manifest "$MANIFEST" \
  --prior-report "$PRIOR_REPORT" \
  --target-report "$TARGET_REPORT" \
  --target-proof "$TARGET_PROOF" \
  --output "$TARGET_REPORT" >"$RUN_ROOT/output-collision.log" 2>&1; then
  echo 'phase85f33 output collision unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'output path collides with an immutable input' "$RUN_ROOT/output-collision.log"

test "$(sha256_file "$PRIOR_REPORT")" = "$PRIOR_BEFORE"
test "$(sha256_file "$TARGET_REPORT")" = "$TARGET_REPORT_BEFORE"
test "$(sha256_file "$TARGET_PROOF")" = "$TARGET_PROOF_BEFORE"
test "$(sha256_file "$MANIFEST")" = "$MANIFEST_SHA256"

git -c core.fsmonitor=false diff --check -- \
  "$PROJECT_ROOT/tools/SM64IntroTransitionCanonicalMergeTool.swift" \
  "$PROJECT_ROOT/script/test_phase85f33_intro_transition_canonical_merge.sh"

REPORT_SHA256="$(sha256_file "$OUTPUT")"
printf '%s\n' \
  'SM64 Modern Phase 85f33 intro-transition canonical merge passed' \
  'manifest_rows=7420 prior_passed=25 prior_planned=7395 qualified_rows=26 planned_rows=7394 terminal_rows=26' \
  'admitted_target=0x9a0f7b4f7ecf6c41 canonical_target=0xca33981b30cb7815 target_records=2' \
  'duplicate_target_rejected=1 tampered_proof_rejected=1 prior_hash_mismatch_rejected=1 manifest_mismatch_rejected=1' \
  'output_collision_rejected=1 terminal_rerun_rejected=1 deterministic_output=1 fixture_only=0' \
  "manifest_sha256=$MANIFEST_SHA256" \
  "prior_report_sha256=$PRIOR_BEFORE" \
  "target_report_sha256=$TARGET_REPORT_BEFORE" \
  "target_proof_sha256=$TARGET_PROOF_BEFORE" \
  "merged_report_sha256=$REPORT_SHA256" \
  'canonical_manifest_mutated=0 prior_report_mutated=0 intro_proof_mutated=0 canonical_ledger_overwrite=0' \
  "run_root=$RUN_ROOT" | tee "$RUN_ROOT/phase-summary.log"
