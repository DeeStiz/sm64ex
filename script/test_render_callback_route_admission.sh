#!/usr/bin/env bash
set -euo pipefail

# Phase 85ba admits only the source-authored render_callback|gfx_run pair into
# a fresh isolated report.  The manifest is generated under the run root and
# is immutable input to admission; this gate never writes the canonical route
# ledger or cumulative history.  GPU capture, pixels, physical presentation,
# and human acceptance remain separate gates.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-render-callback-route-admission"
mkdir -p "$BUILD_ROOT"
RUN_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
PAIR_ROOT="$RUN_ROOT/pair"
TOOL_ROOT="$RUN_ROOT/tool"
MANIFEST_ROOT="$RUN_ROOT/manifest"
MANIFEST="$MANIFEST_ROOT/route-shards.tsv"
INVENTORY="$MANIFEST_ROOT/reachability.tsv"
ADMISSION_TOOL="$TOOL_ROOT/sm64-render-callback-route-admit"
REPORT="$RUN_ROOT/render-callback-isolated.tsv"
mkdir -p "$TOOL_ROOT/module-cache" "$MANIFEST_ROOT"

PAIR_LOG="$RUN_ROOT/pair.log"
MANIFEST_LOG="$RUN_ROOT/manifest.log"
ADMISSION_LOG="$RUN_ROOT/admission.log"

ROUTE_ID=0xd5a43d537c37e833
C_TRACE="$PAIR_ROOT/render-callback-c.trace"
SWIFT_TRACE="$PAIR_ROOT/render-callback-swift.trace"
ASAN_TRACE="$PAIR_ROOT/render-callback-c-asan.trace"
RELEASE_TRACE="$PAIR_ROOT/render-callback-c-release.trace"
RERUN_TRACE="$PAIR_ROOT/render-callback-c-rerun.trace"
TAMPERED_TRACE="$PAIR_ROOT/render-callback-swift.tampered.trace"
DEBUG_LOG="$PAIR_ROOT/debug.log"
SWIFT_LOG="$PAIR_ROOT/swift.log"
ASAN_LOG="$PAIR_ROOT/asan.log"
RELEASE_LOG="$PAIR_ROOT/release.log"
RERUN_LOG="$PAIR_ROOT/rerun.log"

sha256_file() { shasum -a 256 "$1" | awk '{ print $1 }'; }

canonical_manifest="$PROJECT_ROOT/build/sm64-route-shards-smoke/route-shards.tsv"
canonical_manifest_before=""
if [[ -f "$canonical_manifest" ]]; then
  canonical_manifest_before="$(sha256_file "$canonical_manifest")"
fi

bash -n "$PROJECT_ROOT/script/test_render_callback_route_pair.sh"
SM64_RENDER_CALLBACK_ROUTE_PAIR_ROOT="$PAIR_ROOT" \
  "$PROJECT_ROOT/script/test_render_callback_route_pair.sh" >"$PAIR_LOG" 2>&1
for artifact in "$C_TRACE" "$SWIFT_TRACE" "$ASAN_TRACE" "$RELEASE_TRACE" \
  "$RERUN_TRACE" "$TAMPERED_TRACE" "$DEBUG_LOG" "$SWIFT_LOG" "$ASAN_LOG" \
  "$RELEASE_LOG" "$RERUN_LOG"; do
  test -s "$artifact"
done
grep -Fq 'c_render_callback_route_recorded shard=0xd5a43d537c37e833 identity=src/pc/gfx/gfx_pc.c:1783:gfx_run records=2 ticks=2,3 commands_present=1' "$DEBUG_LOG"
grep -Fq 'render_callback_pairing_audit admitted=1 c_records=2 swift_records=2 blockers= first_divergence=none' "$SWIFT_LOG"
grep -Fq 'render_callback_pairing_tamper_rejected=1' "$SWIFT_LOG"
grep -Fq 'render_callback_route_sanitizer_passed=1 debug_asan_trace_match=1' "$PAIR_LOG"
grep -Fq 'render_callback_route_optimized_passed=1 debug_release_trace_match=1' "$PAIR_LOG"

# Generate both manifest inputs under this run root.  No canonical manifest,
# execution ledger, or history file is used as an output of this phase.
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
test "$(awk -F'|' '$0 !~ /^#/ && NF { count++ } END { print count + 0 }' "$MANIFEST")" -eq 7420
awk -F'|' -v id="$ROUTE_ID" \
  '$1 == id && $2 == "render_callback" && $3 == "gfx_run" \
   && $4 == "src/pc/gfx/gfx_pc.c" \
   && $5 == "0xff2793527bb5fb03" && $6 == "0xc57d3aed08300d60" \
   && $7 == "render_packet" && $8 == "planned" { found++ } \
   END { exit(found == 1 ? 0 : 1) }' "$MANIFEST"
manifest_before="$(sha256_file "$MANIFEST")"

# Compile the admission path independently with Swift 6 strict concurrency.
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64RenderCallbackRouteAdmissionTool.swift" \
  -o "$ADMISSION_TOOL"

admit_args=(
  --manifest "$MANIFEST"
  --c-trace "$C_TRACE"
  --swift-trace "$SWIFT_TRACE"
  --asan-trace "$ASAN_TRACE"
  --release-trace "$RELEASE_TRACE"
  --rerun-trace "$RERUN_TRACE"
  --tampered-trace "$TAMPERED_TRACE"
  --debug-log "$DEBUG_LOG"
  --swift-log "$SWIFT_LOG"
  --asan-log "$ASAN_LOG"
  --release-log "$RELEASE_LOG"
  --rerun-log "$RERUN_LOG"
  --report "$REPORT"
)

"$ADMISSION_TOOL" "${admit_args[@]}" >"$ADMISSION_LOG" 2>&1
grep -Fq 'SM64 render-callback route isolated admission passed shard=0xd5a43d537c37e833 identity=src/pc/gfx/gfx_pc.c:1783:gfx_run callback=gfx_run records=2 ticks=2,3 domain=11 kind=3 schema=4' "$ADMISSION_LOG"
grep -Fq 'c_swift_asan_release_rerun_byte_match=1 tamper_rejected=1' "$ADMISSION_LOG"
grep -Fq 'fixture_only=0 manifest_mutated=0 canonical_ledger_mutation=0 history_mutated=0 rerun_fence=1' "$ADMISSION_LOG"
test "$(wc -l <"$REPORT" | tr -d '[:space:]')" -eq 7420
test "$(awk -F'|' '$2 == "passed" { count++ } END { print count + 0 }' "$REPORT")" -eq 1
test "$(awk -F'|' '$2 == "planned" { count++ } END { print count + 0 }' "$REPORT")" -eq 7419
awk -F'|' -v id="$ROUTE_ID" '$1 == id && $2 == "passed" && $3 == 2 && $4 == 2 && $5 == 2 && $6 == "" { found++ } END { exit(found == 1 ? 0 : 1) }' "$REPORT"

# The report is persistent evidence, not an appendable cache.  A second
# admission attempt must fail without changing the first report.
report_before="$(sha256_file "$REPORT")"
if "$ADMISSION_TOOL" "${admit_args[@]}" >"$RUN_ROOT/report-rerun.log" 2>&1; then
  echo 'render-callback isolated admission rerun unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'already exists' "$RUN_ROOT/report-rerun.log"
report_after="$(sha256_file "$REPORT")"
test "$report_before" = "$report_after"

# Reusing one trace as both C and Swift evidence is not an independent pair.
if "$ADMISSION_TOOL" \
  --manifest "$MANIFEST" --c-trace "$C_TRACE" --swift-trace "$C_TRACE" \
  --asan-trace "$ASAN_TRACE" --release-trace "$RELEASE_TRACE" \
  --rerun-trace "$RERUN_TRACE" --tampered-trace "$TAMPERED_TRACE" \
  --debug-log "$DEBUG_LOG" --swift-log "$SWIFT_LOG" --asan-log "$ASAN_LOG" \
  --release-log "$RELEASE_LOG" --rerun-log "$RERUN_LOG" \
  --report "$RUN_ROOT/single.tsv" >"$RUN_ROOT/single.log" 2>&1; then
  echo 'render-callback single-artifact admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'evidence must be distinct' "$RUN_ROOT/single.log"
test ! -e "$RUN_ROOT/single.tsv"

# A one-record trace must fail before any isolated report is written.
head -c $((72 + 128)) "$C_TRACE" >"$RUN_ROOT/partial.trace"
if "$ADMISSION_TOOL" \
  --manifest "$MANIFEST" --c-trace "$RUN_ROOT/partial.trace" \
  --swift-trace "$SWIFT_TRACE" --asan-trace "$ASAN_TRACE" \
  --release-trace "$RELEASE_TRACE" --rerun-trace "$RERUN_TRACE" \
  --tampered-trace "$TAMPERED_TRACE" --debug-log "$DEBUG_LOG" \
  --swift-log "$SWIFT_LOG" --asan-log "$ASAN_LOG" \
  --release-log "$RELEASE_LOG" --rerun-log "$RERUN_LOG" \
  --report "$RUN_ROOT/partial.tsv" >"$RUN_ROOT/partial.log" 2>&1; then
  echo 'render-callback partial-trace admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'record count 1' "$RUN_ROOT/partial.log"
test ! -e "$RUN_ROOT/partial.tsv"

manifest_after="$(sha256_file "$MANIFEST")"
test "$manifest_before" = "$manifest_after"
if [[ -n "$canonical_manifest_before" ]]; then
  test "$canonical_manifest_before" = "$(sha256_file "$canonical_manifest")"
fi
git -c core.fsmonitor=false diff --check

printf '%s\n' \
  "SM64 Modern render-callback isolated route admission passed run=$RUN_ROOT" \
  "target=0xd5a43d537c37e833|render_callback|gfx_run|src/pc/gfx/gfx_pc.c:1783:gfx_run|passed|2|2|2" \
  'records=2 ticks=2,3 domain=11 kind=3 schema=4 source_callback_identity=exact' \
  'independent_c_swift_asan_release_rerun=matched tamper=1 single=1 partial=1 rerun=1' \
  'gpu_capture=separate visual_pixels=unverified physical_presentation=unverified human_acceptance=unverified' \
  'manifest_mutated=0 canonical_ledger_mutation=0 history_mutated=0 fixture_only=0'
