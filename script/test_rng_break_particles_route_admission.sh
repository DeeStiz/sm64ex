#!/usr/bin/env bash
set -euo pipefail

# Phase 85bh admits only the source-authored JRB break-particle RNG row.  The
# pair runner produces independent Debug/Swift/ASan/Release artifacts; this
# script generates an isolated manifest, invokes the write-once validator, and
# exercises the persistent-rerun, single-artifact, and partial-trace fences.
# No canonical manifest, cumulative route ledger, or history is an output.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-rng-break-particles-route-admission"
RUN_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
TOOL_ROOT="$RUN_ROOT/tool"
MANIFEST_ROOT="$RUN_ROOT/manifest"
MANIFEST="$MANIFEST_ROOT/route-shards.tsv"
INVENTORY="$MANIFEST_ROOT/reachability.tsv"
ADMISSION_TOOL="$TOOL_ROOT/sm64-rng-break-particles-route-admit"
REPORT="$RUN_ROOT/rng-break-particles-isolated.tsv"
PAIR_LOG="$RUN_ROOT/pair.log"
MANIFEST_LOG="$RUN_ROOT/manifest.log"
ADMISSION_LOG="$RUN_ROOT/admission.log"
mkdir -p "$TOOL_ROOT/module-cache" "$MANIFEST_ROOT"

ROUTE_ID=0x00576356a427dbc2
sha256_file() { shasum -a 256 "$1" | awk '{ print $1 }'; }

canonical_manifest="$PROJECT_ROOT/build/sm64-route-shards-smoke/route-shards.tsv"
canonical_manifest_before=""
if [[ -f "$canonical_manifest" ]]; then
  canonical_manifest_before="$(sha256_file "$canonical_manifest")"
fi

bash -n "$PROJECT_ROOT/script/test_rng_break_particles_route_pair.sh"
"$PROJECT_ROOT/script/test_rng_break_particles_route_pair.sh" >"$PAIR_LOG" 2>&1
PAIR_RUN="$(sed -n 's/^pair_root=//p' "$PAIR_LOG" | tail -1)"
test -n "$PAIR_RUN" -a -d "$PAIR_RUN"

C_TRACE="$PAIR_RUN/rng-break-particles-c.trace"
SWIFT_TRACE="$PAIR_RUN/rng-break-particles-swift.trace"
ASAN_TRACE="$PAIR_RUN/rng-break-particles-c-asan.trace"
RELEASE_TRACE="$PAIR_RUN/rng-break-particles-c-release.trace"
TAMPERED_TRACE="$PAIR_RUN/rng-break-particles-swift.tampered.trace"
DEBUG_LOG="$PAIR_RUN/debug.log"
SWIFT_LOG="$PAIR_RUN/swift.log"
ASAN_LOG="$PAIR_RUN/asan.log"
RELEASE_LOG="$PAIR_RUN/release.log"
for artifact in "$C_TRACE" "$SWIFT_TRACE" "$ASAN_TRACE" "$RELEASE_TRACE" \
  "$TAMPERED_TRACE" "$DEBUG_LOG" "$SWIFT_LOG" "$ASAN_LOG" "$RELEASE_LOG"; do
  test -s "$artifact"
done
grep -Fq 'rng_break_particles_route_sanitizer_passed=1 debug_asan_trace_match=1' "$PAIR_LOG"
grep -Fq 'rng_break_particles_route_optimized_passed=1 debug_release_trace_match=1' "$PAIR_LOG"

# Generate the route inventory and manifest under this phase's run root.  The
# checked-in/canonical manifest is read only for the before/after integrity
# check below.
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
MANIFEST_ROWS="$(awk -F'|' '$0 !~ /^#/ && NF { count++ } END { print count + 0 }' "$MANIFEST")"
# This isolated admission consumes the canonical denominator; an
# instrumentation-only call must not silently create a new route row.
test "$MANIFEST_ROWS" -eq 7420
awk -F'|' -v id="$ROUTE_ID" \
  '$1 == id && $2 == "rng" && $3 == "random_u16" \
   && $4 == "src/game/behaviors/break_particles.inc.c" \
   && $5 == "0x7f289fd41270636e" && $6 == "0x3e05c8a6a9f41727" \
   && $7 == "rng_draws" && $8 == "planned" { found++ } \
   END { exit(found == 1 ? 0 : 1) }' "$MANIFEST"
manifest_before="$(sha256_file "$MANIFEST")"

# Compile the isolated validator with Swift 6 strict concurrency.
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64RNGBreakParticlesRouteAdmissionTool.swift" \
  -o "$ADMISSION_TOOL"

ADMIT_ARGS=(
  --manifest "$MANIFEST" --c-trace "$C_TRACE" --swift-trace "$SWIFT_TRACE"
  --asan-trace "$ASAN_TRACE" --release-trace "$RELEASE_TRACE"
  --tampered-trace "$TAMPERED_TRACE" --debug-log "$DEBUG_LOG"
  --swift-log "$SWIFT_LOG" --asan-log "$ASAN_LOG" --release-log "$RELEASE_LOG"
  --report "$REPORT"
)
"$ADMISSION_TOOL" "${ADMIT_ARGS[@]}" >"$ADMISSION_LOG" 2>&1
grep -Fq 'SM64 RNG break-particles route isolated admission passed shard=0x00576356a427dbc2 identity=random_u16' "$ADMISSION_LOG"
grep -Fq 'records=40 tick=2084 domain=8 kind=3 schema=4 source_identity=0xcb90922e394c3a9b' "$ADMISSION_LOG"
grep -Fq 'c_swift_asan_release_byte_match=1 trace_sha256=' "$ADMISSION_LOG"
grep -Fq 'tamper_rejected=1 fixture_only=0 manifest_mutated=0 canonical_ledger_mutation=0 history_mutated=0 rerun_fence=1' "$ADMISSION_LOG"
test "$(wc -l <"$REPORT" | tr -d '[:space:]')" -eq "$MANIFEST_ROWS"
test "$(awk -F'|' '$2 == "passed" { count++ } END { print count + 0 }' "$REPORT")" -eq 1
test "$(awk -F'|' '$2 == "planned" { count++ } END { print count + 0 }' "$REPORT")" -eq $((MANIFEST_ROWS - 1))
target_row="$(awk -F'|' -v id="$ROUTE_ID" '$1 == id { print; exit }' "$REPORT")"
[[ "$target_row" == "$ROUTE_ID|passed|40|40|40|" ]]

# The report is write-once evidence. A rerun must fail without changing its
# bytes, independently of the canonical ledger.
report_before="$(sha256_file "$REPORT")"
if "$ADMISSION_TOOL" "${ADMIT_ARGS[@]}" >"$RUN_ROOT/report-rerun.log" 2>&1; then
  echo 'JRB RNG isolated admission rerun unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'already exists' "$RUN_ROOT/report-rerun.log"
test "$report_before" = "$(sha256_file "$REPORT")"

# Reusing C as Swift is not independent evidence.
if "$ADMISSION_TOOL" \
  --manifest "$MANIFEST" --c-trace "$C_TRACE" --swift-trace "$C_TRACE" \
  --asan-trace "$ASAN_TRACE" --release-trace "$RELEASE_TRACE" \
  --tampered-trace "$TAMPERED_TRACE" --debug-log "$DEBUG_LOG" \
  --swift-log "$SWIFT_LOG" --asan-log "$ASAN_LOG" --release-log "$RELEASE_LOG" \
  --report "$RUN_ROOT/single-evidence.tsv" >"$RUN_ROOT/single-evidence.log" 2>&1; then
  echo 'JRB RNG single-artifact admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'distinct artifacts' "$RUN_ROOT/single-evidence.log"
test ! -e "$RUN_ROOT/single-evidence.tsv"

# A 39-record prefix must fail the exact-count gate before writing a report.
PARTIAL_TRACE="$RUN_ROOT/partial.trace"
dd if="$C_TRACE" of="$PARTIAL_TRACE" bs=1 count=$((72 + 39 * 128)) status=none
if "$ADMISSION_TOOL" \
  --manifest "$MANIFEST" --c-trace "$PARTIAL_TRACE" --swift-trace "$SWIFT_TRACE" \
  --asan-trace "$ASAN_TRACE" --release-trace "$RELEASE_TRACE" \
  --tampered-trace "$TAMPERED_TRACE" --debug-log "$DEBUG_LOG" \
  --swift-log "$SWIFT_LOG" --asan-log "$ASAN_LOG" --release-log "$RELEASE_LOG" \
  --report "$RUN_ROOT/partial-evidence.tsv" >"$RUN_ROOT/partial-evidence.log" 2>&1; then
  echo 'JRB RNG partial-trace admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'C record count 39 is not 40' "$RUN_ROOT/partial-evidence.log"
test ! -e "$RUN_ROOT/partial-evidence.tsv"

manifest_after="$(sha256_file "$MANIFEST")"
test "$manifest_before" = "$manifest_after"
if [[ -n "$canonical_manifest_before" ]]; then
  test "$canonical_manifest_before" = "$(sha256_file "$canonical_manifest")"
fi
git -c core.fsmonitor=false diff --check

report_sha256="$(sha256_file "$REPORT")"
trace_sha256="$(sha256_file "$C_TRACE")"
printf '%s\n' \
  "SM64 Modern JRB break-particles RNG isolated route admission passed run=$RUN_ROOT" \
  "target=$ROUTE_ID|rng|random_u16|$PROJECT_ROOT/src/game/behaviors/break_particles.inc.c|passed|40|40|40" \
  'records=40 tick=2084 domain=8 kind=3 schema=4 source_identity=0xcb90922e394c3a9b callsites=0xf2f930d7,0x4648c6c9' \
  'c_swift_asan_release_byte_match=1 tamper_rejected=1 single_artifact_rejected=1 partial_trace_rejected=1 persistent_rerun_rejected=1' \
  'fixture_only=0 manifest_mutated=0 canonical_ledger_mutation=0 history_mutated=0' \
  "trace_sha256=$trace_sha256 report_sha256=$report_sha256 manifest_sha256=$manifest_after report_rows=$MANIFEST_ROWS passed_rows=1 planned_rows=$((MANIFEST_ROWS - 1))"
