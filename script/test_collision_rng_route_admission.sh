#!/usr/bin/env bash
set -euo pipefail

# Phase 85r validates only the two independent Phase 85q oracle-hook pairs.
# The generated manifest is immutable input.  The Swift admission tool emits
# one full 7,420-row isolated report per selected target; it never mutates the
# manifest, cumulative history, or execution ledger.
bash -n "$0"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-collision-rng-route-admission"
RUN_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
TOOL_ROOT="$RUN_ROOT/tool"
MANIFEST_ROOT="$RUN_ROOT/manifest"
MANIFEST="$MANIFEST_ROOT/route-shards.tsv"
TOOL_OUTPUT="$TOOL_ROOT/sm64-collision-rng-route-admit"
COLLISION_PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-collision-queries-route-pair"
RNG_PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-rng-draws-route-pair"
COLLISION_REPORT="$RUN_ROOT/collision-isolated.tsv"
RNG_REPORT="$RUN_ROOT/rng-isolated.tsv"

mkdir -p "$TOOL_ROOT/module-cache" "$MANIFEST_ROOT"

bash -n "$PROJECT_ROOT/script/test_collision_queries_route_pair.sh"
bash -n "$PROJECT_ROOT/script/test_rng_draws_route_pair.sh"

"$PROJECT_ROOT/script/test_collision_queries_route_pair.sh" \
  >"$RUN_ROOT/collision-pair.log" 2>&1
"$PROJECT_ROOT/script/test_rng_draws_route_pair.sh" \
  >"$RUN_ROOT/rng-pair.log" 2>&1
"$PROJECT_ROOT/script/test_route_shards.sh" \
  >"$RUN_ROOT/manifest.log" 2>&1
cp "$PROJECT_ROOT/build/sm64-route-shards-smoke/route-shards.tsv" "$MANIFEST"

manifest_before="$(shasum -a 256 "$MANIFEST" | awk '{ print $1 }')"

xcrun swiftc \
  -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64CollisionRNGRouteAdmissionTool.swift" \
  -o "$TOOL_OUTPUT"

admit_route() {
  local route="$1"
  local pair_root="$2"
  local trace_prefix="$3"
  local report="$4"
  local output_log="$5"

  "$TOOL_OUTPUT" \
    --route "$route" \
    --manifest "$MANIFEST" \
    --c-trace "$pair_root/${trace_prefix}-c.trace" \
    --swift-trace "$pair_root/${trace_prefix}-swift.trace" \
    --asan-trace "$pair_root/${trace_prefix}-c-asan.trace" \
    --tampered-trace "$pair_root/${trace_prefix}-swift.tampered.trace" \
    --debug-log "$pair_root/debug.log" \
    --swift-log "$pair_root/swift.log" \
    --asan-log "$pair_root/asan.log" \
    --report "$report" \
    >"$output_log" 2>&1
  grep -Fq 'tamper_rejected=1 fixture_only=0 effects_admitted=0 unpaired_rows_admitted=0' "$output_log"
  grep -Fq 'manifest_mutated=0 ledger_mutated=0 history_mutated=0 rerun_fence=1' "$output_log"
  test "$(wc -l <"$report" | tr -d '[:space:]')" -eq 7420
  test "$(awk -F'|' '$2 == "passed" { count++ } END { print count + 0 }' "$report")" -eq 1
  test "$(awk -F'|' '$2 == "planned" { count++ } END { print count + 0 }' "$report")" -eq 7419
}

admit_route \
  collision_queries "$COLLISION_PAIR_ROOT" collision-queries \
  "$COLLISION_REPORT" "$RUN_ROOT/collision-admission.log"
admit_route \
  rng_draws "$RNG_PAIR_ROOT" rng-draws \
  "$RNG_REPORT" "$RUN_ROOT/rng-admission.log"

# A second invocation against the same isolated report must fail before any
# output write.  This is the rerun fence, independent of a cumulative ledger.
collision_report_before="$(shasum -a 256 "$COLLISION_REPORT" | awk '{ print $1 }')"
if "$TOOL_OUTPUT" \
  --route collision_queries \
  --manifest "$MANIFEST" \
  --c-trace "$COLLISION_PAIR_ROOT/collision-queries-c.trace" \
  --swift-trace "$COLLISION_PAIR_ROOT/collision-queries-swift.trace" \
  --asan-trace "$COLLISION_PAIR_ROOT/collision-queries-c-asan.trace" \
  --tampered-trace "$COLLISION_PAIR_ROOT/collision-queries-swift.tampered.trace" \
  --debug-log "$COLLISION_PAIR_ROOT/debug.log" \
  --swift-log "$COLLISION_PAIR_ROOT/swift.log" \
  --asan-log "$COLLISION_PAIR_ROOT/asan.log" \
  --report "$COLLISION_REPORT" \
  >"$RUN_ROOT/collision-rerun.log" 2>&1; then
  echo 'collision isolated admission rerun unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'already exists' "$RUN_ROOT/collision-rerun.log"
collision_report_after="$(shasum -a 256 "$COLLISION_REPORT" | awk '{ print $1 }')"
test "$collision_report_before" = "$collision_report_after"

# Passing one artifact for both C and Swift is not independent evidence.
if "$TOOL_OUTPUT" \
  --route collision_queries \
  --manifest "$MANIFEST" \
  --c-trace "$COLLISION_PAIR_ROOT/collision-queries-c.trace" \
  --swift-trace "$COLLISION_PAIR_ROOT/collision-queries-c.trace" \
  --asan-trace "$COLLISION_PAIR_ROOT/collision-queries-c-asan.trace" \
  --tampered-trace "$COLLISION_PAIR_ROOT/collision-queries-swift.tampered.trace" \
  --debug-log "$COLLISION_PAIR_ROOT/debug.log" \
  --swift-log "$COLLISION_PAIR_ROOT/swift.log" \
  --asan-log "$COLLISION_PAIR_ROOT/asan.log" \
  --report "$RUN_ROOT/single-evidence.tsv" \
  >"$RUN_ROOT/single-evidence.log" 2>&1; then
  echo 'single-artifact admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'distinct artifacts' "$RUN_ROOT/single-evidence.log"
test ! -e "$RUN_ROOT/single-evidence.tsv"

# A partial C trace must fail the exact record-count gate and must not leave a
# report behind.  This intentionally exercises the partial-evidence fence.
partial_size=$((72 + (204 - 1) * 128))
dd if="$COLLISION_PAIR_ROOT/collision-queries-c.trace" \
  of="$RUN_ROOT/partial-c.trace" bs=1 count="$partial_size" status=none
if "$TOOL_OUTPUT" \
  --route collision_queries \
  --manifest "$MANIFEST" \
  --c-trace "$RUN_ROOT/partial-c.trace" \
  --swift-trace "$COLLISION_PAIR_ROOT/collision-queries-swift.trace" \
  --asan-trace "$COLLISION_PAIR_ROOT/collision-queries-c-asan.trace" \
  --tampered-trace "$COLLISION_PAIR_ROOT/collision-queries-swift.tampered.trace" \
  --debug-log "$COLLISION_PAIR_ROOT/debug.log" \
  --swift-log "$COLLISION_PAIR_ROOT/swift.log" \
  --asan-log "$COLLISION_PAIR_ROOT/asan.log" \
  --report "$RUN_ROOT/partial-evidence.tsv" \
  >"$RUN_ROOT/partial-evidence.log" 2>&1; then
  echo 'partial-trace admission unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'record count' "$RUN_ROOT/partial-evidence.log"
test ! -e "$RUN_ROOT/partial-evidence.tsv"

manifest_after="$(shasum -a 256 "$MANIFEST" | awk '{ print $1 }')"
test "$manifest_before" = "$manifest_after"

git -c core.fsmonitor=false diff --check

printf '%s\n' \
  "SM64 Modern collision/RNG isolated route admission passed run=$RUN_ROOT" \
  "collision_report=$COLLISION_REPORT" \
  "rng_report=$RNG_REPORT" \
  'collision_records=204 ids=1,2,3,4 counts=128,10,22,44 domain=7 kind=3' \
  'rng_records=168 ids=1,2,3 counts=84,84,0 domain=8 kind=3' \
  'independent_c_swift_asan=matched tamper=1 single=1 partial=1 rerun=1' \
  'manifest_mutated=0 ledger_mutated=0 history_mutated=0 effects_admitted=0 unpaired_rows_admitted=0 fixture_only=0'
