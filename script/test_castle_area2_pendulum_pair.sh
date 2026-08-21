#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/sm64-castle-area2-pendulum-pair.XXXXXX")"
TOOL_ROOT="$BUILD_ROOT/tool"
NATIVE_BUILD="$PROJECT_ROOT/build/sm64-modern-debug"
NATIVE_TRACE="$NATIVE_BUILD/live-schema4.trace"
NATIVE_LOG="$BUILD_ROOT/native.log"
SWIFT_LOG="$BUILD_ROOT/swift.log"
PAIR_REPORT="$BUILD_ROOT/pendulum-pair.report"
PAIR_TOOL="$TOOL_ROOT/sm64-pendulum-pair"
WORKER_TOOL="$TOOL_ROOT/sm64-route-shard-worker-result"
MERGE_TOOL="$TOOL_ROOT/sm64-route-shard-merge"
WORKER_RESULT="$BUILD_ROOT/pendulum-worker.result"
MERGED_REPORT="$BUILD_ROOT/pendulum-merged.report"
MANIFEST="$BUILD_ROOT/pendulum-manifest.tsv"

mkdir -p "$TOOL_ROOT/module-cache"

env -u SM64_MODERN_AUTOMATED_GAMEPLAY \
    -u SM64_MODERN_AUTOMATED_BOBOMB \
    SM64_MODERN_AUTOMATED_CASTLE_AREA2=1 \
    "$PROJECT_ROOT/script/test_oracle_lifecycle_record.sh" \
    | tee "$NATIVE_LOG"

NATIVE_SLOT="$(sed -n 's/.*castleArea2PendulumSlot=\([0-9][0-9]*\).*/\1/p' "$NATIVE_LOG" | tail -1)"
[[ -n "$NATIVE_SLOT" && "$NATIVE_SLOT" != 0 ]] || {
  echo "native Castle area-2 lifecycle did not report a pendulum slot" >&2
  exit 1
}
[[ -s "$NATIVE_TRACE" ]] || { echo "native schema-4 trace was not emitted" >&2; exit 1; }

SM64_MODERN_PENDULUM_TICKS=40 \
  "$PROJECT_ROOT/script/test_decorative_pendulum_route.sh" \
  | tee "$SWIFT_LOG"
SWIFT_TRACE="$(sed -n 's/.*decorativePendulumRouteSwiftCapture output=\([^ ]*\).*/\1/p' "$SWIFT_LOG" | tail -1)"
[[ -n "$SWIFT_TRACE" && -s "$SWIFT_TRACE" ]] || {
  echo "Swift source recipe did not emit a trace" >&2
  exit 1
}

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/tools/SM64PendulumTracePairTool.swift" \
  -o "$PAIR_TOOL"

"$PAIR_TOOL" \
  --c-trace "$NATIVE_TRACE" \
  --swift-trace "$SWIFT_TRACE" \
  --pendulum-slot "$NATIVE_SLOT" \
  --output "$PAIR_REPORT" \
  | tee "$BUILD_ROOT/pair.log"
grep -Fq 'canonical_route_admission=0' "$PAIR_REPORT"
grep -Fq 'tamper_rejected=1 schema4_replay_round_trip=1' "$PAIR_REPORT"
grep -Fq "native_slot=$NATIVE_SLOT" "$PAIR_REPORT"
grep -Fq 'missing_native=3' "$PAIR_REPORT"

# Persist the failed/blocked evidence through the existing live-only worker
# and merge tools. The row is terminal but cannot be promoted because the
# pair report contains an exact divergence and no complete native domain set.
PAIR_ID=0x0000000000000053
NATIVE_RECORDS="$(sed -n 's/native_records=\([0-9][0-9]*\) swift_records=.*/\1/p' "$PAIR_REPORT")"
SWIFT_RECORDS="$(sed -n 's/native_records=[0-9][0-9]* swift_records=\([0-9][0-9]*\).*/\1/p' "$PAIR_REPORT")"
MATCHED_RECORDS="$(sed -n 's/matched_records=\([0-9][0-9]*\).*/\1/p' "$PAIR_REPORT")"
DIVERGENCE="$(sed -n 's/first_divergence=//p' "$PAIR_REPORT")"
[[ -n "$NATIVE_RECORDS" && -n "$SWIFT_RECORDS" && -n "$MATCHED_RECORDS" && -n "$DIVERGENCE" ]] || {
  echo "pair report did not expose bounded worker evidence" >&2
  exit 1
}

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/tools/SM64RouteShardWorkerResultTool.swift" \
  -o "$WORKER_TOOL"
xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/SM64Modern/RouteShardExecution.swift" \
  "$PROJECT_ROOT/tools/SM64RouteShardMergeTool.swift" \
  -o "$MERGE_TOOL"

"$WORKER_TOOL" write \
  --output "$WORKER_RESULT" \
  --shard-id "$PAIR_ID" \
  --from-state running \
  --to-state blocked \
  --expected-records "$SWIFT_RECORDS" \
  --actual-records "$NATIVE_RECORDS" \
  --matched-records "$MATCHED_RECORDS" \
  --first-divergence "$DIVERGENCE" \
  --fixture-only 0 \
  --build-fingerprint 0x0000000000000000 \
  --content-fingerprint 0x0000000000000000 \
  --timebase-fingerprint 0x0000000000000000 \
  --configuration-fingerprint 0x0000000000000000 \
  --initial-save-fingerprint 0x0000000000000000 \
  --coverage-fingerprint 0x0000000000000000
"$WORKER_TOOL" validate --require-live --result "$WORKER_RESULT"

cat > "$MANIFEST" <<EOF
# sm64-modern-route-shards-v1
# shard_id|domain|identity|source|input_seed|save_seed|expected_domains|status|notes
$PAIR_ID|behavior|bhvDecorativePendulum|levels/castle_inside/script.c|0x0000000000000053|0x0000000000000054|collision_queries,effects,object_state,script_events|planned|phase53 bounded pair evidence
EOF
"$MERGE_TOOL" \
  --manifest "$MANIFEST" \
  --result "$WORKER_RESULT" \
  --output "$MERGED_REPORT"
grep -Fq "$PAIR_ID" "$MERGED_REPORT"

if "$PAIR_TOOL" \
  --c-trace "$NATIVE_TRACE" \
  --swift-trace "$SWIFT_TRACE" \
  --pendulum-slot "$NATIVE_SLOT" \
  --output "$PAIR_REPORT" >/dev/null 2>&1; then
  echo "persistent pendulum pairing rerun unexpectedly succeeded" >&2
  exit 1
fi

printf '%s\n' \
  "SM64 Modern Castle area-2 pendulum pair smoke passed native_slot=$NATIVE_SLOT" \
  "schema4_decode=1 complete_domain_filter=1 tamper_rejected=1 replay_round_trip=1" \
  "worker_result=1 merge=1 persistent_rerun_rejected=1 promotion=not_attempted admission=0"

git -c core.fsmonitor=false diff --check
