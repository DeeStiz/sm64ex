#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="SM64 Modern"
BUNDLE_ID="io.github.deestiz.sm64modern"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="$PROJECT_ROOT/build/xcode-derived"
APP_BUNDLE="$DERIVED_DATA/Build/Products/Debug/$APP_NAME.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
SIGNING_IDENTITY="${SM64_MODERN_CODE_SIGN_IDENTITY:-Apple Development}"
DEBUG_ENTITLEMENTS="$PROJECT_ROOT/SM64Modern/SM64ModernDebug.entitlements"
DEFAULT_SAVE_ROOT="$PROJECT_ROOT/build/sm64-modern-state"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

cd "$PROJECT_ROOT"
"$PROJECT_ROOT/script/test_audio_ring.sh"
xcodegen generate --spec project.yml
xcodebuild \
  -project SM64Modern.xcodeproj \
  -scheme SM64Modern \
  -configuration Debug \
  -derivedDataPath "$DERIVED_DATA" \
  build \
  CODE_SIGNING_ALLOWED=NO

# The sustained-execution entitlement remains on Release. Debug uses the
# locally available Apple Development identity without mutating portal state.
while IFS= read -r nested_code; do
  codesign \
    --force \
    --options runtime \
    --timestamp=none \
    --sign "$SIGNING_IDENTITY" \
    "$nested_code"
done < <(find "$APP_BUNDLE/Contents" -type f -name '*.dylib' -print)

codesign \
  --force \
  --options runtime \
  --timestamp=none \
  --entitlements "$DEBUG_ENTITLEMENTS" \
  --sign "$SIGNING_IDENTITY" \
  "$APP_BUNDLE"
codesign --verify --deep --strict "$APP_BUNDLE"

open_app() {
  /usr/bin/open -n "$APP_BUNDLE" \
    --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
    --env SM64_MODERN_SAVE_DIR="$DEFAULT_SAVE_ROOT"
}

wait_for_app_pid() {
  local app_pid=""
  for _ in {1..50}; do
    app_pid="$(pgrep -x "$APP_NAME" | head -n 1 || true)"
    if [[ -n "$app_pid" ]]; then
      printf '%s\n' "$app_pid"
      return 0
    fi
    sleep 0.1
  done
  return 1
}

wait_for_app_exit() {
  local app_pid="$1"
  for _ in {1..150}; do
    if ! kill -0 "$app_pid" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.1
  done
  return 1
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    env \
      SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      SM64_MODERN_SAVE_DIR="$DEFAULT_SAVE_ROOT" \
      lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --metal-validation|metal-validation)
    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_SAVE_DIR="$DEFAULT_SAVE_ROOT" \
      --env MTL_DEBUG_LAYER=1 \
      --env MTL_SHADER_VALIDATION=1 \
      --env MTL_SHADER_VALIDATION_REPORT_TO_STDERR=1
    ;;
  --metal-hud|metal-hud)
    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_SAVE_DIR="$DEFAULT_SAVE_ROOT" \
      --env MTL_HUD_ENABLED=1 \
      --env MTL_HUD_LOG_ENABLED=1
    ;;
  --metal-capture|metal-capture)
    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_SAVE_DIR="$DEFAULT_SAVE_ROOT" \
      --env MTL_CAPTURE_ENABLED=1 \
      --env MTLCAPTURE_WAIT_FOR_SIGNAL=1
    ;;
  --verify|verify)
    open_app
    app_pid=""
    for _ in {1..50}; do
      app_pid="$(pgrep -x "$APP_NAME" | head -n 1 || true)"
      if [[ -n "$app_pid" ]]; then
        break
      fi
      sleep 0.1
    done
    [[ -n "$app_pid" ]]
    sleep 3
    test "$(defaults read "$APP_BUNDLE/Contents/Info" CFBundleIdentifier)" = "$BUNDLE_ID"
    runtime_log="$(/usr/bin/log show --last 2m --style compact \
      --predicate "processIdentifier == $app_pid && subsystem == \"$BUNDLE_ID\"")"
    for expected in \
      'window_ready layer=CAMetalLayer' \
      'metal_device_ready' \
      'metal_display_link_started owner_main=false' \
      'metal_scene_initialized' \
      'metal_scene_presented frame=1' \
      'engine_thread_started' \
      'input_service_ready' \
      'input_bridge_installed abi=1' \
      'input_snapshot_started owner_main=false' \
      'audio_service_started input_hz=32000 format=s16_interleaved_stereo' \
      'audio_enqueue_started' \
      'audio_render_started' \
      'lifecycle_running cadence_hz=30 capabilities=rendering,input,audio' \
      'lifecycle_step count=1'; do
      grep -Fq "$expected" <<< "$runtime_log"
    done
    printf '%s\n' "$runtime_log" \
      | grep -E 'window_ready layer=CAMetalLayer|metal_device_ready|metal_display_link_started|metal_scene_initialized|metal_scene_presented frame=1|engine_thread_started|input_service_ready|input_bridge_installed|input_snapshot_started|audio_service_started|audio_enqueue_started|audio_render_started|lifecycle_running|lifecycle_step count=1'
    /usr/bin/osascript -e "tell application id \"$BUNDLE_ID\" to quit"
    for _ in {1..50}; do
      if ! kill -0 "$app_pid" >/dev/null 2>&1; then
        shutdown_log="$(/usr/bin/log show --last 2m --style compact \
          --predicate "processIdentifier == $app_pid && subsystem == \"$BUNDLE_ID\"")"
        for expected in \
          'audio_service_stopped' \
          'platform_shutdown' \
          'metal_shutdown_drained' \
          'engine_thread_finished status=0' \
          'application_stopped'; do
          grep -Fq "$expected" <<< "$shutdown_log"
        done
        printf '%s\n' "$shutdown_log" \
          | grep -E 'audio_service_stopped|metal_shutdown_drained|platform_shutdown|engine_thread_finished status=0|application_stopped'
        exit 0
      fi
      sleep 0.1
    done
    echo "$APP_NAME did not terminate cleanly" >&2
    exit 1
    ;;
  --parity-verify|parity-verify)
    PARITY_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-parity.XXXXXX")"
    trap '/bin/rm -rf -- "$PARITY_TEMP"' EXIT
    TRACE_PATH="$PARITY_TEMP/gameplay-v1.trace"
    RECORD_SAVE="$PARITY_TEMP/record-save"
    REPLAY_SAVE="$PARITY_TEMP/replay-save"
    mkdir -p "$RECORD_SAVE" "$REPLAY_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$TRACE_PATH" \
      --env SM64_MODERN_PARITY_TICKS=90 \
      --env SM64_MODERN_SAVE_DIR="$RECORD_SAVE"
    record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$record_pid"
    test -s "$TRACE_PATH"
    record_log="$(/usr/bin/log show --last 2m --style compact \
      --predicate "processIdentifier == $record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=1' <<< "$record_log"
    grep -Fq 'bounded_parity_run_complete steps=90' <<< "$record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=replay \
      --env SM64_MODERN_PARITY_TRACE="$TRACE_PATH" \
      --env SM64_MODERN_PARITY_TICKS=90 \
      --env SM64_MODERN_SAVE_DIR="$REPLAY_SAVE"
    replay_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$replay_pid"
    replay_log="$(/usr/bin/log show --last 2m --style compact \
      --predicate "processIdentifier == $replay_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=2 schema=1' <<< "$replay_log"
    grep -Fq 'bounded_parity_run_complete steps=90' <<< "$replay_log"
    grep -Fq 'parity_session_finished status=0' <<< "$replay_log"
    if grep -Fq 'parity_first_divergence' <<< "$replay_log"; then
      echo "Replay reported a parity divergence" >&2
      exit 1
    fi
    printf '%s\n' "$record_log" "$replay_log" \
      | grep -E 'parity_session_started|bounded_parity_run_complete|parity_result subsystem=|parity_session_finished'
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--metal-validation|--metal-hud|--metal-capture|--verify|--parity-verify]" >&2
    exit 2
    ;;
esac
