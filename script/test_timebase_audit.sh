#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPECTED="$PROJECT_ROOT/tests/fixtures/sm64_modern_timebase_audit.tsv"
ACTUAL="$(mktemp "${TMPDIR:-/tmp}/sm64-modern-timebase-audit.XXXXXX")"
trap '/bin/rm -f -- "$ACTUAL"' EXIT

count_category() {
  local category="$1"
  local pattern="$2"
  local counts
  local files
  local matches
  counts="$(rg --count-matches -g '*.c' "$pattern" \
    "$PROJECT_ROOT/src/game" "$PROJECT_ROOT/src/engine" || true)"
  files="$(printf '%s\n' "$counts" | awk 'NF { files++ } END { print files + 0 }')"
  matches="$(printf '%s\n' "$counts" | awk -F: 'NF { total += $NF } END { print total + 0 }')"
  printf '%s\t%s\t%s\n' "$category" "$files" "$matches" >> "$ACTUAL"
}

printf 'category\tfiles\tmatches\n' > "$ACTUAL"
count_category object_timer '\boTimer\b'
count_category mario_action_timer '\bactionTimer\b'
count_category global_timer '\bgGlobalTimer\b'
count_category random_calls '\brandom_(u16|float|sign|fixed_seed)\b'
count_category animation_sites 'anim(Frame|Accel)|AnimFrame|set_mario_anim|cur_obj_init_animation|cur_obj_check_if_near_animation_end'

if rg -q 'Timer\(timeInterval:' "$PROJECT_ROOT/SM64Modern/EngineHost.swift"; then
  echo "EngineHost regressed to a coalescing Foundation Timer" >&2
  exit 1
fi
rg -q 'RationalFixedStepScheduler' "$PROJECT_ROOT/SM64Modern/EngineHost.swift"

if ! diff -u "$EXPECTED" "$ACTUAL"; then
  echo "Time-dependent gameplay inventory changed; classify the drift before updating the fixture." >&2
  exit 1
fi
echo "SM64 Modern timebase audit passed"
