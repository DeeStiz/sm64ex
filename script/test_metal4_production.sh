#!/usr/bin/env bash
set -euo pipefail

# M34 is a production-facing Metal 4 evidence harness.  It deliberately keeps
# source/build/runtime/validation/GPU-capture evidence together while leaving
# visual parity and physical-device acceptance as separate human gates.

APP_NAME="SM64 Modern"
BUNDLE_ID="io.github.deestiz.sm64modern"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${SM64_MODERN_M34_OUTPUT_DIR:-$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m34b.XXXXXX")}"
DERIVED_DATA="${SM64_MODERN_M34_DERIVED_DATA:-$OUTPUT_DIR/derived-data}"
RUNTIME_DIR="$OUTPUT_DIR/local-runtime"
RUNTIME_APP="$RUNTIME_DIR/$APP_NAME.app"
TRACE_PATH="$OUTPUT_DIR/m34b.gputrace"
PROFILE_TICKS="${SM64_MODERN_M34_PROFILE_TICKS:-600}"
WARMUP_TICKS="${SM64_MODERN_M34_PROFILE_WARMUP_TICKS:-60}"
PROFILE_TIMEOUT="${SM64_MODERN_M34_PROFILE_TIMEOUT_SECONDS:-120}"
SAVE_DIR="$OUTPUT_DIR/save"
M9_ENV=(
  "SM64_MODERN_M9_OUTPUT_DIR=$OUTPUT_DIR"
  "SM64_MODERN_M9_DERIVED_DATA=$DERIVED_DATA"
  "SM64_MODERN_M9_RUNTIME_BUNDLE=$RUNTIME_APP"
  "SM64_MODERN_M9_SAVE_DIR=$SAVE_DIR"
  "SM64_MODERN_CODE_SIGN_IDENTITY=-"
)

die() {
  printf 'test_metal4_production: %s\n' "$*" >&2
  exit 1
}

mkdir -p "$OUTPUT_DIR" "$SAVE_DIR"
if [[ -e "$TRACE_PATH" ]]; then
  die "refusing to overwrite existing capture: $TRACE_PATH"
fi

printf 'M34 output: %s\n' "$OUTPUT_DIR"

env "${M9_ENV[@]}" "$PROJECT_ROOT/script/m9_release.sh" build \
  > "$OUTPUT_DIR/release-build.log" 2>&1
env "${M9_ENV[@]}" "$PROJECT_ROOT/script/m9_release.sh" inspect \
  > "$OUTPUT_DIR/release-sign-inspect.log" 2>&1
test -d "$RUNTIME_APP" || die "signed runtime bundle was not produced"

if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
  die "$APP_NAME is already running; close it before collecting isolated M34 evidence"
fi

# Metal's shader-validation layer and gpucapture are mutually exclusive. Run
# the API/shader-validation stress profile first, then repeat the same bounded
# workload with capture enabled and validation disabled. This preserves both
# kinds of evidence instead of silently weakening either one.
wait_for_app_pid() {
  local pid=""
  for _ in {1..200}; do
    pid="$(pgrep -x "$APP_NAME" | head -n 1 || true)"
    if [[ -n "$pid" ]]; then
      printf '%s\n' "$pid"
      return 0
    fi
    sleep 0.1
  done
  return 1
}

wait_for_app_exit() {
  local pid="$1"
  for _ in $(seq 1 $((PROFILE_TIMEOUT * 10))); do
    kill -0 "$pid" >/dev/null 2>&1 || return 0
    sleep 0.1
  done
  return 1
}

launch_common() {
  /usr/bin/open -n "$RUNTIME_APP" \
    --env "SM64_MODERN_GAME_DIR=$PROJECT_ROOT" \
    --env "SM64_MODERN_SAVE_DIR=$SAVE_DIR" \
    --env "SM64_MODERN_M9_PROFILE_TICKS=$PROFILE_TICKS" \
    --env "SM64_MODERN_M9_PROFILE_WARMUP_TICKS=$WARMUP_TICKS" \
    --env "SM64_MODERN_M34_STRESS=1" "$@"
}

if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
  die "$APP_NAME is already running before the validation profile"
fi
launch_common \
  --env MTL_DEBUG_LAYER=1 \
  --env MTL_SHADER_VALIDATION=1 \
  --env MTL_SHADER_VALIDATION_REPORT_TO_STDERR=1
VALIDATION_PID="$(wait_for_app_pid)" || die "Release app did not launch for Metal validation"
printf 'profile_pid=%s\n' "$VALIDATION_PID" > "$OUTPUT_DIR/validation.pid"
wait_for_app_exit "$VALIDATION_PID" || die "Metal validation profile timed out"
/usr/bin/log show --last 15m --style compact \
  --predicate "processIdentifier == $VALIDATION_PID && subsystem == \"$BUNDLE_ID\"" \
  > "$OUTPUT_DIR/validation.log"

require_log() {
  local log_path="$1"
  local needle="$2"
  grep -Fq "$needle" "$log_path" \
    || die "runtime evidence missing in $(basename "$log_path"): $needle"
}

for expected in \
  "m9_profile_warmup_complete step=$WARMUP_TICKS" \
  "m9_profile_complete steps=$PROFILE_TICKS" \
  'scheduler_dropped_steps=0' \
  'audio_dropped_delta=0' \
  'm34_stress_resize_requested index=0' \
  'm34_stress_resize_requested index=7' \
  'm34_stress_pause_requested paused=true' \
  'm34_stress_pause_requested paused=false' \
  'metal_display_link_pause_state paused=true' \
  'metal_display_link_pause_state paused=false' \
  'metal_shutdown_drained' \
  'engine_thread_finished status=0' \
  'application_stopped'; do
  require_log "$OUTPUT_DIR/validation.log" "$expected"
done
resize_count="$(rg -c 'metal_resize_applied drawable=' "$OUTPUT_DIR/validation.log" || true)"
(( resize_count >= 4 )) || die "expected at least four owner-thread resize applications, found $resize_count"
if rg -n -i -- \
  'metal_frame_failed|validation[^\n]*(error|fault)|shader validation[^\n]*(error|fault)|api validation[^\n]*(error|fault)' \
  "$OUTPUT_DIR/validation.log"; then
  die "Metal validation reported an error; inspect $OUTPUT_DIR/validation.log"
fi

if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
  die "$APP_NAME is still running before the capture profile"
fi
launch_common \
  --env MTL_CAPTURE_ENABLED=1 \
  --env MTLCAPTURE_WAIT_FOR_SIGNAL=1
CAPTURE_PID="$(wait_for_app_pid)" || die "Release app did not launch for GPU capture"
printf 'profile_pid=%s\n' "$CAPTURE_PID" > "$OUTPUT_DIR/capture.pid"

# On a cold launch the display-link thread can reach MTLDevice before
# gpucapture sees the process; retrying here removes that race.
capture_ready=0
for _ in {1..160}; do
  if ! kill -0 "$CAPTURE_PID" >/dev/null 2>&1; then
    break
  fi
  if gpucapture boundaries --pid "$CAPTURE_PID" > "$OUTPUT_DIR/gpucapture-boundaries.txt" 2>&1 \
      && grep -Fq 'Device' "$OUTPUT_DIR/gpucapture-boundaries.txt"; then
    capture_ready=1
    break
  fi
  sleep 0.25
done
[[ "$capture_ready" == "1" ]] || die "Metal capture boundary did not become available"
gpucapture start --pid "$CAPTURE_PID" --until-exit --output "$TRACE_PATH" \
  > "$OUTPUT_DIR/gpucapture-start.txt" 2>&1 \
  || die "GPU capture could not start; see $OUTPUT_DIR/gpucapture-start.txt"
test -d "$TRACE_PATH" || die "GPU capture did not produce a trace bundle"
/usr/bin/log show --last 15m --style compact \
  --predicate "processIdentifier == $CAPTURE_PID && subsystem == \"$BUNDLE_ID\"" \
  > "$OUTPUT_DIR/capture.log"
for expected in \
  'metal_scene_initialized' \
  'metal_scene_presented frame=1' \
  'm34_stress_resize_requested index=7' \
  'metal_shutdown_drained' \
  'engine_thread_finished status=0' \
  'application_stopped'; do
  require_log "$OUTPUT_DIR/capture.log" "$expected"
done
if rg -n -i -- 'metal_frame_failed|validation[^\n]*(error|fault)' "$OUTPUT_DIR/capture.log"; then
  die "Metal capture runtime reported an error; inspect $OUTPUT_DIR/capture.log"
fi

gpudebug --oneshot -q -t "$TRACE_PATH" \
  -c 'go commands' \
  -c 'list --all' \
  -c 'find draw' \
  -c 'find render' \
  -c 'find depth' \
  -c 'find MTL4RenderCommandEncoder' \
  > "$OUTPUT_DIR/gpudebug.txt" 2>&1
for expected in \
  'CAMetalLayer Display Drawable' \
  'BGRA8Unorm' \
  'Depth32Float' \
  'MTL4RenderCommandEncoder drawPrimitives:Triangle' \
  'sm64_vertex / sm64_fragment' \
  '2 triangles'; do
  grep -Fq "$expected" "$OUTPUT_DIR/gpudebug.txt" \
    || die "GPU trace inspection missing: $expected"
done

printf 'M34b_RESULT validation=pass capture=pass resize_pause=pass trace=%s\n' "$TRACE_PATH"
printf 'validation_log=%s\ncapture_log=%s\ngpudebug=%s\n' \
  "$OUTPUT_DIR/validation.log" "$OUTPUT_DIR/capture.log" "$OUTPUT_DIR/gpudebug.txt"
