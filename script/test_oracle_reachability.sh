#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-oracle-reachability-smoke"
TOOL_BUILD_ROOT="$BUILD_ROOT/tool"
TOOL="$TOOL_BUILD_ROOT/sm64-oracle-reachability"
FIRST="$BUILD_ROOT/reachability-first.tsv"
SECOND="$BUILD_ROOT/reachability-second.tsv"

mkdir -p "$TOOL_BUILD_ROOT/module-cache"
xcrun swiftc \
  -parse-as-library \
  -module-cache-path "$TOOL_BUILD_ROOT/module-cache" \
  "$PROJECT_ROOT/tools/SM64OracleReachabilityTool.swift" \
  -o "$TOOL"

"$TOOL" --root "$PROJECT_ROOT" --output "$FIRST" >/dev/null
"$TOOL" --root "$PROJECT_ROOT" --output "$SECOND" >/dev/null
cmp -s "$FIRST" "$SECOND"

if ! LC_ALL=C diff -u <(tail -n +3 "$FIRST" | LC_ALL=C sort) <(tail -n +3 "$FIRST"); then
  echo "oracle reachability inventory is not canonically sorted" >&2
  exit 1
fi

require_count() {
  local domain="$1"
  local minimum="$2"
  local actual
  actual="$(awk -F'|' -v domain="$domain" '$0 !~ /^#/ && $1 == domain { count++ } END { print count + 0 }' "$FIRST")"
  if (( actual < minimum )); then
    echo "oracle reachability domain $domain has $actual rows; expected at least $minimum" >&2
    exit 1
  fi
}

require_count level_script 30
require_count geo_layout 60
require_count behavior 500
require_count display_list 500
require_count audio_asset 100
require_count text 1
require_count save_mutation 50
require_count render_callback 100
require_count collision 20
require_count rng 50
require_count transition 5
require_count oracle_hook 14

for required in \
  'oracle_hook|input|.*|hooked|' \
  'oracle_hook|global_state|.*|hooked|' \
  'oracle_hook|object_state|.*|hooked|' \
  'oracle_hook|audio_pcm|.*|hooked|' \
  'oracle_hook|save_bytes|.*|deferred|' \
  'oracle_hook|render_packet|.*|deferred|' \
  'oracle_hook|script_events|.*|deferred|' \
  'oracle_hook|collision_queries|.*|deferred|' \
  'oracle_hook|rng_draws|.*|deferred|' \
  'oracle_hook|audio_sequence|.*|deferred|'; do
  if ! rg -q "^${required}" "$FIRST"; then
    echo "missing oracle hook contract row: $required" >&2
    exit 1
  fi
done

printf '%s\n' "SM64 Modern oracle reachability inventory smoke passed"
