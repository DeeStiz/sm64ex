#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-route-shards-smoke"
TOOL_BUILD_ROOT="$BUILD_ROOT/tool"
REACHABILITY_TOOL="$TOOL_BUILD_ROOT/sm64-oracle-reachability"
SHARD_TOOL="$TOOL_BUILD_ROOT/sm64-route-shards"
INVENTORY="$BUILD_ROOT/reachability.tsv"
MANIFEST="$BUILD_ROOT/route-shards.tsv"
SECOND_MANIFEST="$BUILD_ROOT/route-shards-second.tsv"

mkdir -p "$TOOL_BUILD_ROOT/module-cache"
xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/tools/SM64OracleReachabilityTool.swift" \
  -o "$REACHABILITY_TOOL"
xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$TOOL_BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/tools/SM64RouteShardManifestTool.swift" \
  -o "$SHARD_TOOL"

"$REACHABILITY_TOOL" --root "$PROJECT_ROOT" --output "$INVENTORY" >/dev/null
"$SHARD_TOOL" --inventory "$INVENTORY" --output "$MANIFEST" >/dev/null
"$SHARD_TOOL" --inventory "$INVENTORY" --output "$SECOND_MANIFEST" >/dev/null
cmp -s "$MANIFEST" "$SECOND_MANIFEST"

if ! LC_ALL=C diff -u <(tail -n +3 "$MANIFEST" | LC_ALL=C sort) <(tail -n +3 "$MANIFEST"); then
  echo "route-shard manifest is not canonically sorted" >&2
  exit 1
fi

inventory_count="$(awk '$0 !~ /^#/ && NF { count++ } END { print count + 0 }' "$INVENTORY")"
manifest_count="$(awk -F'|' '$0 !~ /^#/ && NF { count++ } END { print count + 0 }' "$MANIFEST")"
[[ "$inventory_count" -eq 7420 ]] || {
  echo "route-shard authoritative inventory count $inventory_count does not match expected 7420" >&2
  exit 1
}
[[ "$manifest_count" -eq "$inventory_count" ]] || {
  echo "route-shard manifest count $manifest_count does not match inventory $inventory_count" >&2
  exit 1
}

if grep -Fq 'transition|initiate_warp|src/game/level_update.h|' "$INVENTORY"; then
  echo "route-shard inventory retained the initiate_warp header declaration" >&2
  exit 1
fi
grep -Eq '^transition\|initiate_warp\|src/game/[^|]+\.c\|' "$INVENTORY" || {
  echo "route-shard inventory lost the initiate_warp C transition call site" >&2
  exit 1
}

awk -F'|' '
  $0 !~ /^#/ && NF {
    if ($1 !~ /^0x[0-9a-f]{16}$/) exit 10
    if ($5 !~ /^0x[0-9a-f]{16}$/ || $6 !~ /^0x[0-9a-f]{16}$/) exit 11
    if ($8 != "planned") exit 12
    if ($7 == "") exit 13
    if (++ids[$1] != 1) exit 14
  }
  END { if (NR == 0) exit 15 }
' "$MANIFEST" || {
  echo "route-shard manifest schema/uniqueness validation failed" >&2
  exit 1
}

for domain in level_script geo_layout behavior display_list audio_asset save_mutation render_callback collision rng transition oracle_hook; do
  count="$(awk -F'|' -v domain="$domain" '$0 !~ /^#/ && $2 == domain { count++ } END { print count + 0 }' "$MANIFEST")"
  [[ "$count" -gt 0 ]] || { echo "route-shard domain missing: $domain" >&2; exit 1; }
done

printf 'SM64 Modern route-shard manifest smoke passed inventory=%s shards=%s status=planned\n' "$inventory_count" "$manifest_count"
