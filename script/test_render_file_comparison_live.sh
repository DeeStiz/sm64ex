#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$PROJECT_ROOT/build/xcode-derived/Build/Products/Debug/SM64 Modern.app"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-render-file-comparison"
TRACE_PATH="$BUILD_ROOT/live.c.trace"
PACKET_PATH="$BUILD_ROOT/live.swift.packet"
COMPARATOR="$BUILD_ROOT/sm64-modern-render-file-compare"

test -d "$APP_BUNDLE"
test -x "$APP_BUNDLE/Contents/MacOS/SM64 Modern"
test -x "$COMPARATOR" || "$PROJECT_ROOT/script/test_render_file_comparison.sh" >/dev/null
mkdir -p "$BUILD_ROOT"
pkill -x 'SM64 Modern' >/dev/null 2>&1 || true

/usr/bin/open -n "$APP_BUNDLE" \
  --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
  --env SM64_MODERN_SAVE_DIR="$PROJECT_ROOT/build/sm64-modern-state" \
  --env SM64_MODERN_RENDER_PACKET_CAPTURE=1 \
  --env SM64_MODERN_RENDER_PACKET_PATH="$PACKET_PATH" \
  --env SM64_MODERN_ORACLE_TRACE_MODE=record \
  --env SM64_MODERN_ORACLE_TRACE_PATH="$TRACE_PATH" \
  --env SM64_MODERN_ORACLE_TRACE_TICKS=1

for _ in {1..100}; do
  if [[ -s "$TRACE_PATH" && -s "$PACKET_PATH" ]]; then break; fi
  sleep 0.1
done
test -s "$TRACE_PATH"
test -s "$PACKET_PATH"

for _ in {1..100}; do
  if ! pgrep -x 'SM64 Modern' >/dev/null 2>&1; then break; fi
  sleep 0.1
done
if pgrep -x 'SM64 Modern' >/dev/null 2>&1; then
  echo 'SM64 Modern live render comparison run did not stop at the oracle tick' >&2
  exit 1
fi

"$COMPARATOR" "$TRACE_PATH" "$PACKET_PATH"
runtime_log="$(/usr/bin/log show --last 2m --style compact \
  --predicate 'process == "SM64 Modern" && subsystem == "io.github.deestiz.sm64modern"')"
for expected in \
  'oracle_trace_started mode=1 schema=4' \
  'swift_render_packet_file sequence=1 events=3' \
  'swift_render_packet_capture frame=1 events=3' \
  'bounded_oracle_trace_run_complete steps=1' \
  'oracle_trace_finished status=0' \
  'engine_thread_finished status=0 steps=1' \
  'application_stopped'; do
  grep -Fq "$expected" <<< "$runtime_log"
done
printf '%s\n' "$runtime_log" \
  | grep -E 'oracle_trace_(started|finished)|swift_render_packet_(file|capture)|bounded_oracle_trace_run_complete|engine_thread_finished status=0 steps=1|application_stopped' \
  | tail -20
printf 'renderLiveTraceBytes=%s\n' "$(stat -f '%z' "$TRACE_PATH")"
printf 'renderLivePacketBytes=%s\n' "$(stat -f '%z' "$PACKET_PATH")"
printf '%s\n' 'SM64 Modern live file-backed render comparison matched'
