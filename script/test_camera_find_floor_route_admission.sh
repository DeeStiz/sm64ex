#!/usr/bin/env bash
set -euo pipefail

# Phase 85ay admits only the source-bound camera/find_floor row.  The pair
# script runs the real Bob-omb area-1 radial lifecycle, then this gate checks
# exact schema-4 source/value parity, sanitizer/optimized/persistent-rerun
# equality, and negative-evidence fences.  The canonical manifest and ledger
# remain immutable; only a fresh isolated report is written.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-camera-find-floor-route-admission"
mkdir -p "$BUILD_ROOT"
RUN_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
PAIR_ROOT="$RUN_ROOT/pair"
TOOL_ROOT="$RUN_ROOT/tool"
MANIFEST="$RUN_ROOT/route-shards.tsv"
REPORT="$RUN_ROOT/camera-find-floor-isolated.tsv"
TOOL_OUTPUT="$TOOL_ROOT/sm64-camera-find-floor-route-admit"

mkdir -p "$TOOL_ROOT/module-cache"
bash -n "$PROJECT_ROOT/script/test_camera_find_floor_route_pair.sh"

SM64_CAMERA_FIND_FLOOR_PAIR_ROOT="$PAIR_ROOT" \
  "$PROJECT_ROOT/script/test_camera_find_floor_route_pair.sh" \
  >"$RUN_ROOT/pair.log" 2>&1

"$PROJECT_ROOT/script/test_route_shards.sh" >"$RUN_ROOT/manifest.log" 2>&1
cp "$PROJECT_ROOT/build/sm64-route-shards-smoke/route-shards.tsv" "$MANIFEST"
manifest_before="$(shasum -a 256 "$MANIFEST" | awk '{ print $1 }')"

xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64CameraFindFloorRouteAdmissionTool.swift" \
  -o "$TOOL_OUTPUT"

admit_args=(
  --manifest "$MANIFEST"
  --c-trace "$PAIR_ROOT/camera-find-floor-c.trace"
  --swift-trace "$PAIR_ROOT/camera-find-floor-swift.trace"
  --asan-trace "$PAIR_ROOT/camera-find-floor-c-asan.trace"
  --release-trace "$PAIR_ROOT/camera-find-floor-c-release.trace"
  --rerun-trace "$PAIR_ROOT/camera-find-floor-c-rerun.trace"
  --tampered-trace "$PAIR_ROOT/camera-find-floor-swift.tampered.trace"
  --debug-log "$PAIR_ROOT/debug.log"
  --swift-log "$PAIR_ROOT/swift.log"
  --asan-log "$PAIR_ROOT/asan.log"
  --release-log "$PAIR_ROOT/release.log"
  --rerun-log "$PAIR_ROOT/rerun.log"
  --report "$REPORT"
)

"$TOOL_OUTPUT" "${admit_args[@]}" >"$RUN_ROOT/admission.log" 2>&1
grep -Fq 'SM64 camera/find_floor route isolated admission passed shard=0x1e3500f9eb2b95d4' "$RUN_ROOT/admission.log"
grep -Fq 'schema=4' "$RUN_ROOT/admission.log"
grep -Fq 'c_swift_asan_release_rerun=matched tamper_rejected=1' "$RUN_ROOT/admission.log"
grep -Fq 'fixture_only=0 manifest_mutated=0 canonical_ledger_mutation=0 history_mutated=0 rerun_fence=1' "$RUN_ROOT/admission.log"
test "$(wc -l <"$REPORT" | tr -d '[:space:]')" -eq 7420
test "$(awk -F'|' '$2 == "passed" { count++ } END { print count + 0 }' "$REPORT")" -eq 1
test "$(awk -F'|' '$2 == "planned" { count++ } END { print count + 0 }' "$REPORT")" -eq 7419

# A persistent isolated report cannot be admitted twice.  The failed rerun
# must leave the first report byte-identical.
report_before="$(shasum -a 256 "$REPORT" | awk '{ print $1 }')"
if "$TOOL_OUTPUT" "${admit_args[@]}" >"$RUN_ROOT/report-rerun.log" 2>&1; then
  echo 'camera/find_floor isolated admission rerun unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'already exists' "$RUN_ROOT/report-rerun.log"
report_after="$(shasum -a 256 "$REPORT" | awk '{ print $1 }')"
test "$report_before" = "$report_after"

# Reusing one artifact as both C and Swift evidence is not an independent
# pair, even when every other input remains valid.
if "$TOOL_OUTPUT" \
  --manifest "$MANIFEST" \
  --c-trace "$PAIR_ROOT/camera-find-floor-c.trace" \
  --swift-trace "$PAIR_ROOT/camera-find-floor-c.trace" \
  --asan-trace "$PAIR_ROOT/camera-find-floor-c-asan.trace" \
  --release-trace "$PAIR_ROOT/camera-find-floor-c-release.trace" \
  --rerun-trace "$PAIR_ROOT/camera-find-floor-c-rerun.trace" \
  --tampered-trace "$PAIR_ROOT/camera-find-floor-swift.tampered.trace" \
  --debug-log "$PAIR_ROOT/debug.log" --swift-log "$PAIR_ROOT/swift.log" \
  --asan-log "$PAIR_ROOT/asan.log" --release-log "$PAIR_ROOT/release.log" \
  --rerun-log "$PAIR_ROOT/rerun.log" --report "$RUN_ROOT/single.tsv" \
  >"$RUN_ROOT/single.log" 2>&1; then
  echo 'camera/find_floor single-artifact admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'evidence must be distinct' "$RUN_ROOT/single.log"
test ! -e "$RUN_ROOT/single.tsv"

# A 29-record artifact must fail before a report can be written.
partial_bytes=$((72 + 29 * 128))
head -c "$partial_bytes" "$PAIR_ROOT/camera-find-floor-c.trace" >"$RUN_ROOT/partial.trace"
if "$TOOL_OUTPUT" \
  --manifest "$MANIFEST" \
  --c-trace "$RUN_ROOT/partial.trace" \
  --swift-trace "$PAIR_ROOT/camera-find-floor-swift.trace" \
  --asan-trace "$PAIR_ROOT/camera-find-floor-c-asan.trace" \
  --release-trace "$PAIR_ROOT/camera-find-floor-c-release.trace" \
  --rerun-trace "$PAIR_ROOT/camera-find-floor-c-rerun.trace" \
  --tampered-trace "$PAIR_ROOT/camera-find-floor-swift.tampered.trace" \
  --debug-log "$PAIR_ROOT/debug.log" --swift-log "$PAIR_ROOT/swift.log" \
  --asan-log "$PAIR_ROOT/asan.log" --release-log "$PAIR_ROOT/release.log" \
  --rerun-log "$PAIR_ROOT/rerun.log" --report "$RUN_ROOT/partial.tsv" \
  >"$RUN_ROOT/partial.log" 2>&1; then
  echo 'camera/find_floor partial-trace admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'record count 29' "$RUN_ROOT/partial.log"
test ! -e "$RUN_ROOT/partial.tsv"

manifest_after="$(shasum -a 256 "$MANIFEST" | awk '{ print $1 }')"
test "$manifest_before" = "$manifest_after"
git -c core.fsmonitor=false diff --check

printf '%s\n' \
  "SM64 Modern camera/find_floor isolated route admission passed run=$RUN_ROOT" \
  "report=$REPORT" \
  'target=0x1e3500f9eb2b95d4|passed|30|30|30|' \
  'records=30 ticks=92,93 domains=collision_queries,object_state schema=4' \
  'independent_c_swift_asan_release_rerun=matched tamper=1 single=1 partial=1 rerun=1' \
  'manifest_mutated=0 canonical_ledger_mutation=0 history_mutated=0 fixture_only=0'
