#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENERATED="$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift"
ACTUAL="$(mktemp "${TMPDIR:-/tmp}/sm64-modern-trig.XXXXXX.swift")"
trap '/bin/rm -f -- "$ACTUAL"' EXIT

"$PROJECT_ROOT/script/generate_swift_trig_tables.sh" \
  "$PROJECT_ROOT/include/trig_tables.inc.c" \
  "$ACTUAL"

if ! cmp -s "$ACTUAL" "$GENERATED"; then
  echo "Swift trig table drift detected; regenerate $GENERATED" >&2
  diff -u "$GENERATED" "$ACTUAL" >&2 || true
  exit 1
fi

echo "SM64 Modern Swift trig table smoke passed"
