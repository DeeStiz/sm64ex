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

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

cd "$PROJECT_ROOT"
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
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
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
      --env MTL_DEBUG_LAYER=1 \
      --env MTL_SHADER_VALIDATION=1 \
      --env MTL_SHADER_VALIDATION_REPORT_TO_STDERR=1
    ;;
  --metal-hud|metal-hud)
    /usr/bin/open -n "$APP_BUNDLE" \
      --env MTL_HUD_ENABLED=1 \
      --env MTL_HUD_LOG_ENABLED=1
    ;;
  --metal-capture|metal-capture)
    /usr/bin/open -n "$APP_BUNDLE" \
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
      'lifecycle_running cadence_hz=30 capabilities=rendering,input' \
      'lifecycle_step count=1'; do
      grep -Fq "$expected" <<< "$runtime_log"
    done
    printf '%s\n' "$runtime_log" \
      | grep -E 'window_ready layer=CAMetalLayer|metal_device_ready|metal_display_link_started|metal_scene_initialized|metal_scene_presented frame=1|engine_thread_started|input_service_ready|input_bridge_installed|input_snapshot_started|lifecycle_running|lifecycle_step count=1'
    /usr/bin/osascript -e "tell application id \"$BUNDLE_ID\" to quit"
    for _ in {1..50}; do
      if ! kill -0 "$app_pid" >/dev/null 2>&1; then
        shutdown_log="$(/usr/bin/log show --last 2m --style compact \
          --predicate "processIdentifier == $app_pid && subsystem == \"$BUNDLE_ID\"")"
        for expected in \
          'platform_shutdown' \
          'metal_shutdown_drained' \
          'engine_thread_finished status=0' \
          'application_stopped'; do
          grep -Fq "$expected" <<< "$shutdown_log"
        done
        printf '%s\n' "$shutdown_log" \
          | grep -E 'metal_shutdown_drained|platform_shutdown|engine_thread_finished status=0|application_stopped'
        exit 0
      fi
      sleep 0.1
    done
    echo "$APP_NAME did not terminate cleanly" >&2
    exit 1
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--metal-validation|--metal-hud|--metal-capture|--verify]" >&2
    exit 2
    ;;
esac
