#!/usr/bin/env bash
set -euo pipefail

# Parent-owned isolated admission for the authored wooden-door display-list
# leaf. The pair artifacts are immutable inputs; this script never mutates
# the canonical manifest or cumulative ledger.
bash -n "$0"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="${SM64_DISPLAY_LIST_DOOR_ADMISSION_BUILD_ROOT:-$PROJECT_ROOT/build/sm64-modern-door-retry-admission}"
mkdir -p "$BUILD_ROOT"
RUN_ROOT="$(mktemp -d "$BUILD_ROOT/run.XXXXXX")"
TOOL_ROOT="$RUN_ROOT/tool"
mkdir -p "$TOOL_ROOT/module-cache"
PAIR_ROOT="$PROJECT_ROOT/build/sm64-modern-door-retry"
MANIFEST="${SM64_DISPLAY_LIST_DOOR_ADMISSION_MANIFEST:-$PROJECT_ROOT/build/sm64-modern-phase85h-canonical-ledger/run.3OK2nP/route-shards.tsv}"
REPORT="$RUN_ROOT/door-admission.tsv"
ADMIT_TOOL="$TOOL_ROOT/sm64-display-list-door-route-admit"

xcrun swiftc -parse-as-library -swift-version 6 -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_ROOT/module-cache" \
  "$PROJECT_ROOT/SM64Modern/OracleTrace.swift" \
  "$PROJECT_ROOT/tools/SM64DisplayListDoorRouteAdmissionTool.swift" \
  -o "$ADMIT_TOOL"

"$ADMIT_TOOL" \
  --manifest "$MANIFEST" \
  --c-trace "$PAIR_ROOT/door.trace" \
  --swift-trace "$PAIR_ROOT/door.swift.trace" \
  --asan-trace "$PAIR_ROOT/door-asan.trace" \
  --release-trace "$PAIR_ROOT/door-release.trace" \
  --rerun-trace "$PAIR_ROOT/door-rerun.trace" \
  --tampered-trace "$PAIR_ROOT/door-swift.tampered.trace" \
  --c-packet "$PAIR_ROOT/door.packet" \
  --asan-packet "$PAIR_ROOT/door-asan.packet" \
  --release-packet "$PAIR_ROOT/door-release.packet" \
  --rerun-packet "$PAIR_ROOT/door-rerun.packet" \
  --debug-log "$PAIR_ROOT/door-debug.log" \
  --swift-log "$PAIR_ROOT/swift-audit.log" \
  --tamper-log "$PAIR_ROOT/swift-tamper.log" \
  --asan-log "$PAIR_ROOT/door-asan.log" \
  --release-log "$PAIR_ROOT/door-release.log" \
  --rerun-log "$PAIR_ROOT/rerun.log" \
  --partial-log "$PAIR_ROOT/partial.log" \
  --single-log "$PAIR_ROOT/single-artifact.log" \
  --report "$REPORT"

test "$(wc -l <"$REPORT" | tr -d '[:space:]')" -eq 7420
grep -Fq '0x01b472aae4c4277d|passed|2|2|2|' "$REPORT"
test "$(awk -F'|' '$2 == "planned" { count++ } END { print count + 0 }' "$REPORT")" -eq 7419
git -c core.fsmonitor=false diff --check
printf '%s\n' \
  "SM64 Modern door display-list isolated admission smoke passed report=$REPORT" \
  'route_shard=0x01b472aae4c4277d source=actors/door/model.inc.c identity=door_seg3_dl_03014EF0 parent=door_seg3_dl_03014F98' \
  'c_swift_asan_release_rerun=byte_match tamper=1 partial=1 single_artifact=1 owner_pointer_fence=1 fixture_only=0' \
  'canonical_ledger_mutation=0 manifest_mutation=0 admission=isolated'
