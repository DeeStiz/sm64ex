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

if [[ -z "${SM64_MODERN_CODE_SIGN_IDENTITY:-}" ]]; then
  if ! security find-identity -v -p codesigning 2>/dev/null | grep -Fq 'Apple Development:'; then
    # Local CI/managed shells often have no development certificate. Ad hoc
    # signing keeps the build artifact runnable without pretending it is a
    # distributable Developer ID product.
    SIGNING_IDENTITY="-"
  fi
fi

CODE_SIGN_ARGS=(--force --timestamp=none --sign "$SIGNING_IDENTITY")
if [[ "$SIGNING_IDENTITY" != "-" ]]; then
  CODE_SIGN_ARGS+=(--options runtime)
fi

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

cd "$PROJECT_ROOT"
if [[ "$MODE" == "--m7-shadow-live" || "$MODE" == "m7-shadow-live" ]]; then
  # The trace fingerprints the signed app directory. Re-linking between the
  # live record and shadow passes would correctly reject the trace at tick 0,
  # so shadow must reuse the exact product that produced the record.
  test -x "$APP_BINARY"
  codesign --verify --deep --strict "$APP_BUNDLE"
else
  "$PROJECT_ROOT/script/test_audio_ring.sh"
  "$PROJECT_ROOT/script/test_fixed_step_scheduler.sh"
  "$PROJECT_ROOT/script/test_timebase_audit.sh"
  "$PROJECT_ROOT/script/test_engine_authority.sh"
  "$PROJECT_ROOT/script/test_configuration.sh"
  "$PROJECT_ROOT/script/test_configuration_runtime.sh"
  "$PROJECT_ROOT/script/test_cheats.sh"
  "$PROJECT_ROOT/script/test_hud.sh"
  "$PROJECT_ROOT/script/test_hud_render.sh"
  "$PROJECT_ROOT/script/test_dialog.sh"
  "$PROJECT_ROOT/script/test_save_replay_artifact.sh"
  "$PROJECT_ROOT/script/test_save_replay_execution.sh"
  "$PROJECT_ROOT/script/test_engine_runtime.sh"
  "$PROJECT_ROOT/script/test_content_pack.sh"
  "$PROJECT_ROOT/script/test_oracle_trace.sh"
  "$PROJECT_ROOT/script/test_oracle_trace_swift.sh"
  "$PROJECT_ROOT/script/test_oracle_bridge.sh"
  "$PROJECT_ROOT/script/test_oracle_reachability.sh"
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
      "${CODE_SIGN_ARGS[@]}" \
      "$nested_code"
  done < <(find "$APP_BUNDLE/Contents" -type f -name '*.dylib' -print)

  codesign \
    "${CODE_SIGN_ARGS[@]}" \
    --entitlements "$DEBUG_ENTITLEMENTS" \
    "$APP_BUNDLE"
  codesign --verify --deep --strict "$APP_BUNDLE"
fi

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

wait_for_app_exit_long() {
  local app_pid="$1"
  for _ in {1..3600}; do
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
      'gameplay_bridge_installed abi=1 slices=mario_buttons,mario_ground_speed,bobomb_release' \
      'input_snapshot_started owner_main=false' \
      'audio_service_started input_hz=32000 format=s16_interleaved_stereo' \
      'audio_enqueue_started blocks_per_native_step=1' \
      'audio_render_started' \
      'timebase_configured simulation_hz=60/1 legacy_hz=30/1 paired_ticks=2' \
      'fixed_step_scheduler_started clock=monotonic_raw max_catch_up=2' \
      'lifecycle_running cadence_hz=60/1 capabilities=rendering,input,audio' \
      'presentation_cadence native_hz=60/1 legacy_hz=30/1 drawable_per_native_tick=true' \
      'fixed_step_scheduler_status step=1' \
      'lifecycle_step count=1'; do
      grep -Fq "$expected" <<< "$runtime_log"
    done
    printf '%s\n' "$runtime_log" \
      | grep -E 'window_ready layer=CAMetalLayer|metal_device_ready|metal_display_link_started|metal_scene_initialized|metal_scene_presented frame=1|engine_thread_started|input_service_ready|input_bridge_installed|gameplay_bridge_installed|input_snapshot_started|audio_service_started|audio_enqueue_started|audio_render_started|timebase_configured|fixed_step_scheduler_(started|status)|lifecycle_running|presentation_cadence|lifecycle_step count=1'
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
    TRACE_PATH="$PARITY_TEMP/gameplay-v3.trace"
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
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$record_log"
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
    grep -Fq 'parity_session_started mode=2 schema=3' <<< "$replay_log"
    grep -Fq 'bounded_parity_run_complete steps=90' <<< "$replay_log"
    grep -Fq 'parity_session_finished status=0' <<< "$replay_log"
    if grep -Fq 'parity_first_divergence' <<< "$replay_log"; then
      echo "Replay reported a parity divergence" >&2
      exit 1
    fi
    printf '%s\n' "$record_log" "$replay_log" \
      | grep -E 'parity_session_started|bounded_parity_run_complete|parity_result subsystem=|parity_session_finished'
    ;;
  --m11-shadow-verify|m11-shadow-verify)
    M11_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m11-shadow.XXXXXX")"
    trap '/bin/rm -rf -- "$M11_TEMP"' EXIT
    M11_TRACE="$M11_TEMP/mario-ground-speed-v3.trace"
    M11_RECORD_SAVE="$M11_TEMP/record-save"
    M11_SHADOW_SAVE="$M11_TEMP/shadow-save"
    M11_TICKS="${SM64_MODERN_M11_TICKS:-360}"
    mkdir -p "$M11_RECORD_SAVE" "$M11_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M11_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M11_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M11_RECORD_SAVE" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1
    m11_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m11_record_pid"
    test -s "$M11_TRACE"
    m11_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m11_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m11_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M11_TICKS" <<< "$m11_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m11_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m11_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M11_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M11_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M11_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_SLICES=mario-buttons \
      --env SM64_MODERN_SWIFT_PROMOTE=0 \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1
    m11_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m11_shadow_pid"
    m11_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m11_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m11_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1 promote=false' <<< "$m11_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m11_shadow_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=[1-9][0-9]* mario_ground_speed=[1-9][0-9]*' <<< "$m11_shadow_log"
    grep -Fq "bounded_parity_run_complete steps=$M11_TICKS" <<< "$m11_shadow_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m11_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m11_shadow_log"
    printf '%s\n' "$m11_record_log" "$m11_shadow_log" \
      | grep -E 'parity_session_started|swift_shadow_started|swift_gameplay_evidence|bounded_parity_run_complete|parity_result subsystem=1|parity_session_finished|engine_thread_finished status=0'
    ;;
  --m13-shadow-verify|m13-shadow-verify)
    M13_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m13-shadow.XXXXXX")"
    trap '/bin/rm -rf -- "$M13_TEMP"' EXIT
    M13_TRACE="$M13_TEMP/bobomb-release-v3.trace"
    M13_RECORD_SAVE="$M13_TEMP/record-save"
    M13_SHADOW_SAVE="$M13_TEMP/shadow-save"
    M13_TICKS="${SM64_MODERN_M13_TICKS:-360}"
    mkdir -p "$M13_RECORD_SAVE" "$M13_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M13_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M13_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M13_RECORD_SAVE" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m13_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m13_record_pid"
    test -s "$M13_TRACE"
    m13_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m13_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m13_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M13_TICKS" <<< "$m13_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m13_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m13_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M13_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M13_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M13_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_SLICES=bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=0 \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m13_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m13_shadow_pid"
    m13_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m13_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m13_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=4 promote=false' <<< "$m13_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m13_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*bobomb_release=[1-9][0-9]*' <<< "$m13_shadow_log"
    grep -Fq "bounded_parity_run_complete steps=$M13_TICKS" <<< "$m13_shadow_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m13_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m13_shadow_log"
    printf '%s\n' "$m13_record_log" "$m13_shadow_log" \
      | grep -E 'parity_session_started|swift_shadow_started|swift_gameplay_evidence|bounded_parity_run_complete|parity_result subsystem=4|parity_session_finished|engine_thread_finished status=0'
    ;;
  --m14-native-verify|m14-native-verify)
    M14_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m14-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M14_TEMP"' EXIT
    M14_TRACE="$M14_TEMP/bobomb-native-default-v1.trace"
    M14_RECORD_SAVE="$M14_TEMP/record-save"
    M14_SHADOW_SAVE="$M14_TEMP/shadow-save"
    M14_TICKS="${SM64_MODERN_M14_TICKS:-8}"
    M14_SWIFT_TICKS="${SM64_MODERN_M14_SWIFT_TICKS:-8}"
    M14_TOTAL_TICKS=$((M14_TICKS + M14_SWIFT_TICKS))
    mkdir -p "$M14_RECORD_SAVE" "$M14_SHADOW_SAVE"

    # Explicit C fallback records the deterministic Battlefield trace. The
    # authority telemetry makes the default safe path observable.
    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M14_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M14_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M14_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m14_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m14_record_pid"
    test -s "$M14_TRACE"
    m14_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m14_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m14_record_log"
    grep -Fq 'swift_authority_fallback=c' <<< "$m14_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M14_TICKS" <<< "$m14_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m14_record_log"
    grep -Eq 'swift_gameplay_evidence .*bobomb_release=0' <<< "$m14_record_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m14_record_log"

    # Native Swift authority is never enabled directly. This pass requires a
    # bounded shadow comparison, promotes only after eligibility/evidence, and
    # then proves post-promotion callback execution for a second bounded slice.
    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M14_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M14_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M14_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M14_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m14_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m14_shadow_pid"
    m14_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m14_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m14_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m14_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=4 promote=true' <<< "$m14_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*bobomb_release=[1-9][0-9]*' <<< "$m14_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m14_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=4' <<< "$m14_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M14_TOTAL_TICKS authority_steps=$M14_SWIFT_TICKS" <<< "$m14_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m14_shadow_log"
    printf '%s\n' "$m14_record_log" "$m14_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=4|engine_thread_finished status=0'
    ;;
  --m7-record-live|m7-record-live)
    M7_DIR="${SM64_MODERN_M7_DIR:-$PROJECT_ROOT/build/sm64-modern-m7-live}"
    M7_SOURCE_SAVE="${SM64_MODERN_M7_SOURCE_SAVE:-$PROJECT_ROOT/build/sm64-modern-state}"
    M7_TICKS="${SM64_MODERN_M7_TICKS:-1800}"
    M7_BASELINE_SAVE="$M7_DIR/baseline-save"
    M7_RECORD_SAVE="$M7_DIR/record-save"
    M7_TRACE="$M7_DIR/bob-gameplay-v3.trace"
    if [[ -e "$M7_DIR" ]]; then
      echo "M7 record directory already exists: $M7_DIR" >&2
      echo "Set SM64_MODERN_M7_DIR to a new directory to preserve the existing evidence." >&2
      exit 2
    fi
    mkdir -p "$M7_DIR"
    if [[ -d "$M7_SOURCE_SAVE" ]]; then
      /usr/bin/ditto "$M7_SOURCE_SAVE" "$M7_BASELINE_SAVE"
    else
      mkdir -p "$M7_BASELINE_SAVE"
    fi
    /usr/bin/ditto "$M7_BASELINE_SAVE" "$M7_RECORD_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M7_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M7_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M7_RECORD_SAVE"
    record_pid="$(wait_for_app_pid)"
    wait_for_app_exit_long "$record_pid"
    test -s "$M7_TRACE"
    record_log="$(/usr/bin/log show --last 15m --style compact \
      --predicate "processIdentifier == $record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$record_log"
    grep -Fq "bounded_parity_run_complete steps=$M7_TICKS" <<< "$record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$record_log"
    printf '%s\n' "$record_log" \
      | grep -E 'parity_session_started|bounded_parity_run_complete|parity_result subsystem=4|parity_session_finished'
    echo "M7 live trace recorded at $M7_TRACE"
    ;;
  --m7-shadow-live|m7-shadow-live)
    M7_DIR="${SM64_MODERN_M7_DIR:-$PROJECT_ROOT/build/sm64-modern-m7-live}"
    M7_TICKS="${SM64_MODERN_M7_TICKS:-1800}"
    M7_SWIFT_TICKS="${SM64_MODERN_M7_SWIFT_TICKS:-1800}"
    M7_BASELINE_SAVE="$M7_DIR/baseline-save"
    M7_TRACE="$M7_DIR/bob-gameplay-v3.trace"
    M7_SHADOW_SAVE="$M7_DIR/shadow-save-$(date +%Y%m%d-%H%M%S)"
    test -d "$M7_BASELINE_SAVE"
    test -s "$M7_TRACE"
    /usr/bin/ditto "$M7_BASELINE_SAVE" "$M7_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M7_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M7_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M7_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_SLICES=mario-buttons,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M7_SWIFT_TICKS"
    shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit_long "$shadow_pid"
    shadow_log="$(/usr/bin/log show --last 15m --style compact \
      --predicate "processIdentifier == $shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$shadow_log"
    grep -Fq 'bounded_swift_authority_run_complete' <<< "$shadow_log"
    test "$(grep -Fc 'swift_gameplay_slice_exercised slice=mario_buttons' <<< "$shadow_log")" -ge 2
    test "$(grep -Fc 'swift_gameplay_slice_exercised slice=bobomb_release' <<< "$shadow_log")" -ge 2
    grep -Fq 'engine_thread_finished status=0' <<< "$shadow_log"
    printf '%s\n' "$shadow_log" \
      | grep -E 'swift_shadow_started|swift_gameplay_slice_exercised|parity_result subsystem=(1|4)|swift_authority_promoted|bounded_swift_authority_run_complete|engine_thread_finished status=0'
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--metal-validation|--metal-hud|--metal-capture|--verify|--parity-verify|--m11-shadow-verify|--m13-shadow-verify|--m14-native-verify|--m7-record-live|--m7-shadow-live]" >&2
    exit 2
    ;;
esac
