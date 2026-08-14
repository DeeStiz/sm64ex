#!/usr/bin/env bash
set -euo pipefail

# M9 is intentionally a local evidence harness. It can build, sign/package,
# exercise the Release product, and save validation/capture/leak artifacts, but
# it never claims Developer ID, notarization, or clean-machine acceptance.

MODE="${1:-all}"
APP_NAME="SM64 Modern"
BUNDLE_ID="io.github.deestiz.sm64modern"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="${SM64_MODERN_M9_DERIVED_DATA:-$PROJECT_ROOT/build/xcode-derived-m9-release}"
APP_BUNDLE="$DERIVED_DATA/Build/Products/Release/$APP_NAME.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
OUTPUT_DIR="${SM64_MODERN_M9_OUTPUT_DIR:-$PROJECT_ROOT/build/m9-release}"
RELEASE_ENTITLEMENTS="$PROJECT_ROOT/SM64Modern/SM64Modern.entitlements"
LOCAL_ENTITLEMENTS="$PROJECT_ROOT/SM64Modern/SM64ModernDebug.entitlements"
LOCAL_RUNTIME_DIR="$OUTPUT_DIR/local-runtime"
RUNTIME_APP_BUNDLE="${SM64_MODERN_M9_RUNTIME_BUNDLE:-$LOCAL_RUNTIME_DIR/$APP_NAME.app}"
SAVE_ROOT="${SM64_MODERN_M9_SAVE_DIR:-$PROJECT_ROOT/build/sm64-modern-m9-state}"
PROFILE_TICKS="${SM64_MODERN_M9_PROFILE_TICKS:-3600}"
PROFILE_WARMUP_TICKS="${SM64_MODERN_M9_PROFILE_WARMUP_TICKS:-600}"
MAX_UNDERRUN_RATE_BPS="${SM64_MODERN_M9_MAX_AUDIO_UNDERRUN_RATE_BPS:-1000}"
MAX_RSS_DELTA_BYTES="${SM64_MODERN_M9_MAX_RSS_DELTA_BYTES:-8388608}"
PROFILE_TIMEOUT_SECONDS="${SM64_MODERN_M9_PROFILE_TIMEOUT_SECONDS:-$((PROFILE_TICKS / 30 + 30))}"
SIGNING_IDENTITY=""
SIGNING_STATE=""

mkdir -p "$OUTPUT_DIR"

die() {
  echo "m9_release: $*" >&2
  exit 1
}

assert_no_live_app() {
  if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
    die "$APP_NAME is already running; close it before collecting isolated M9 evidence"
  fi
}

select_signing_identity() {
  local requested="${SM64_MODERN_CODE_SIGN_IDENTITY:-}"
  local identities
  identities="$(security find-identity -v -p codesigning 2>/dev/null || true)"
  if [[ -n "$requested" && "$requested" != "-" && "$identities" == *"$requested"* ]]; then
    SIGNING_IDENTITY="$requested"
    SIGNING_STATE="requested identity"
  elif [[ "$requested" == "-" ]]; then
    SIGNING_IDENTITY="-"
    SIGNING_STATE="ad hoc"
  elif grep -Fq 'Developer ID Application:' <<< "$identities"; then
    SIGNING_IDENTITY="$(sed -n 's/.*Developer ID Application: \([^" ]*.*\)"$/Developer ID Application: \1/p' <<< "$identities" | head -n 1)"
    SIGNING_STATE="Developer ID Application identity"
  elif grep -Fq 'Apple Development:' <<< "$identities"; then
    SIGNING_IDENTITY="$(sed -n 's/.*Apple Development: \([^" ]*.*\)"$/Apple Development: \1/p' <<< "$identities" | head -n 1)"
    SIGNING_STATE="Apple Development identity"
  else
    SIGNING_IDENTITY="-"
    SIGNING_STATE="ad hoc (no valid local signing identity)"
  fi
}

build_release() {
  cd "$PROJECT_ROOT"
  "$PROJECT_ROOT/script/test_audio_ring.sh"
  "$PROJECT_ROOT/script/test_fixed_step_scheduler.sh"
  "$PROJECT_ROOT/script/test_timebase_audit.sh"
  "$PROJECT_ROOT/script/test_engine_authority.sh"
  "$PROJECT_ROOT/script/test_engine_runtime.sh"
  "$PROJECT_ROOT/script/test_content_pack.sh"
  "$PROJECT_ROOT/script/test_oracle_trace.sh"
  "$PROJECT_ROOT/script/test_oracle_trace_swift.sh"
  "$PROJECT_ROOT/script/test_oracle_bridge.sh"
  xcodegen generate --spec project.yml
  xcodebuild \
    -project SM64Modern.xcodeproj \
    -scheme SM64Modern \
    -configuration Release \
    -derivedDataPath "$DERIVED_DATA" \
    build \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO
  test -x "$APP_BINARY"
  echo "Release build: $APP_BUNDLE"
}

sign_release() {
  test -d "$APP_BUNDLE"
  select_signing_identity
  sign_bundle "$APP_BUNDLE" "$RELEASE_ENTITLEMENTS"
  mkdir -p "$LOCAL_RUNTIME_DIR"
  /usr/bin/ditto "$APP_BUNDLE" "$RUNTIME_APP_BUNDLE"
  sign_bundle "$RUNTIME_APP_BUNDLE" "$LOCAL_ENTITLEMENTS"
  {
    echo "signing_state=$SIGNING_STATE"
    echo "signing_identity=$SIGNING_IDENTITY"
    echo "distribution_bundle=$APP_BUNDLE"
    echo "runtime_bundle=$RUNTIME_APP_BUNDLE"
    echo "runtime_entitlements=$LOCAL_ENTITLEMENTS"
  } > "$OUTPUT_DIR/signing.txt"
  echo "Signed Release candidate: $SIGNING_STATE"
  echo "Local runnable Release copy: $RUNTIME_APP_BUNDLE"
}

sign_bundle() {
  local bundle="$1"
  local entitlements="$2"
  while IFS= read -r nested_code; do
    codesign \
      --force \
      --options runtime \
      --timestamp=none \
      --sign "$SIGNING_IDENTITY" \
      "$nested_code"
  done < <(find "$bundle/Contents" -type f -name '*.dylib' -print)
  codesign \
    --force \
    --options runtime \
    --timestamp=none \
    --entitlements "$entitlements" \
    --sign "$SIGNING_IDENTITY" \
    "$bundle"
  codesign --verify --deep --strict "$bundle"
}

inspect_release() {
  test -d "$APP_BUNDLE"
  {
    echo "bundle=$APP_BUNDLE"
    echo "bundle_id=$(defaults read "$APP_BUNDLE/Contents/Info" CFBundleIdentifier)"
    echo "short_version=$(defaults read "$APP_BUNDLE/Contents/Info" CFBundleShortVersionString)"
    echo "build_version=$(defaults read "$APP_BUNDLE/Contents/Info" CFBundleVersion)"
    echo "architecture=$(file -b "$APP_BINARY")"
    echo
    codesign -dvvv "$APP_BUNDLE" 2>&1 || true
    echo
    codesign -d --entitlements :- "$APP_BUNDLE" 2>&1 || true
  } > "$OUTPUT_DIR/bundle-inspection.txt"
  if find "$APP_BUNDLE" \( -iname '*.z64' -o -iname '*.rom' -o -iname '*.png' \) -print -quit | grep -q .; then
    die "Release bundle contains an unexpected ROM or asset payload"
  fi
  if spctl -a -vv "$APP_BUNDLE" > "$OUTPUT_DIR/spctl.txt" 2>&1; then
    echo "spctl=accepted" | tee -a "$OUTPUT_DIR/bundle-inspection.txt"
  else
    echo "spctl=pending (local signature is not a distribution verdict)" | tee -a "$OUTPUT_DIR/bundle-inspection.txt"
  fi
}

package_release() {
  test -d "$APP_BUNDLE"
  local package_path="$OUTPUT_DIR/SM64-Modern-0.1.zip"
  /usr/bin/ditto -c -k --keepParent "$APP_BUNDLE" "$package_path"
  shasum -a 256 "$package_path" | tee "$OUTPUT_DIR/package.sha256"
  echo "Package: $package_path"
}

ensure_runtime_bundle() {
  if [[ ! -d "$RUNTIME_APP_BUNDLE" ]]; then
    sign_release
  fi
}

wait_for_app_pid() {
  local app_pid=""
  for _ in {1..100}; do
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
  local timeout_seconds="$2"
  local polls=$((timeout_seconds * 10))
  for _ in $(seq 1 "$polls"); do
    if ! kill -0 "$app_pid" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.1
  done
  return 1
}

launch_profile() {
  local label="$1"
  shift
  local log_path="$OUTPUT_DIR/$label.log"
  local -a launch_args=(
    --env "SM64_MODERN_GAME_DIR=$PROJECT_ROOT"
    --env "SM64_MODERN_SAVE_DIR=$SAVE_ROOT"
    --env "SM64_MODERN_M9_PROFILE_TICKS=$PROFILE_TICKS"
    --env "SM64_MODERN_M9_PROFILE_WARMUP_TICKS=$PROFILE_WARMUP_TICKS"
  )
  while [[ "$#" -gt 0 ]]; do
    launch_args+=(--env "$1")
    shift
  done
  mkdir -p "$SAVE_ROOT"
  assert_no_live_app
  test -d "$RUNTIME_APP_BUNDLE"
  /usr/bin/open -n "$RUNTIME_APP_BUNDLE" "${launch_args[@]}"
  local app_pid
  app_pid="$(wait_for_app_pid)" || die "Release app did not launch"
  echo "profile_pid=$app_pid" > "$OUTPUT_DIR/$label.pid"

  if [[ "${SM64_MODERN_M9_CAPTURE_LEAKS:-0}" == "1" ]]; then
    local first_delay=$((PROFILE_WARMUP_TICKS / 60 + 2))
    sleep "$first_delay"
    if kill -0 "$app_pid" >/dev/null 2>&1; then
      leaks --noContent "$app_pid" > "$OUTPUT_DIR/$label-leaks-first.txt" 2>&1 || true
    fi
    # leaks suspends the target while scanning it. Leave enough wall time for
    # the second snapshot to finish before the bounded profile exits.
    local second_delay=$((PROFILE_TICKS / 60 - first_delay - 12))
    if (( second_delay > 0 )); then
      sleep "$second_delay"
      if kill -0 "$app_pid" >/dev/null 2>&1; then
        leaks --noContent "$app_pid" > "$OUTPUT_DIR/$label-leaks-second.txt" 2>&1 || true
      fi
    fi
  fi

  if ! wait_for_app_exit "$app_pid" "$PROFILE_TIMEOUT_SECONDS"; then
    echo "Release profile timed out after ${PROFILE_TIMEOUT_SECONDS}s" >&2
    return 1
  fi
  /usr/bin/log show --last 15m --style compact \
    --predicate "processIdentifier == $app_pid && subsystem == \"$BUNDLE_ID\"" \
    > "$log_path"
  echo "runtime_log=$log_path"
}

profile_gate() {
  local label="$1"
  local log_path="$OUTPUT_DIR/$label.log"
  test -s "$log_path"
  local summary
  summary="$(grep 'm9_profile_complete' "$log_path" | tail -n 1 || true)"
  [[ -n "$summary" ]] || die "M9 profile did not emit m9_profile_complete"
  grep -Fq 'engine_thread_finished status=0' "$log_path"
  grep -Fq 'audio_service_stopped' "$log_path"
  grep -Fq 'platform_shutdown' "$log_path"

  metric_from() {
    local line="$1"
    local key="$2"
    sed -n "s/.* $key=\([^ ]*\).*/\1/p" <<< "$line"
  }
  metric() {
    local key="$1"
    metric_from "$summary" "$key"
  }
  local audio_summary
  audio_summary="$(grep 'm9_profile_audio_final' "$log_path" | tail -n 1 || true)"
  [[ -n "$audio_summary" ]] || audio_summary="$summary"
  local scheduler_dropped audio_dropped underrun_rate rss_delta
  scheduler_dropped="$(metric scheduler_dropped_steps)"
  audio_dropped="$(metric_from "$audio_summary" audio_dropped_delta)"
  underrun_rate="$(metric_from "$audio_summary" audio_underrun_rate_bps)"
  rss_delta="$(metric rss_delta_bytes)"
  [[ -n "$scheduler_dropped" && -n "$audio_dropped" && -n "$underrun_rate" && -n "$rss_delta" ]] \
    || die "M9 profile summary is missing a release-gate metric: $summary"
  [[ "$scheduler_dropped" == "0" ]] || die "scheduler drops exceeded release gate: $summary"
  [[ "$audio_dropped" == "0" ]] || die "audio drops exceeded release gate: $summary"
  (( underrun_rate <= MAX_UNDERRUN_RATE_BPS )) \
    || die "audio underrun rate exceeded ${MAX_UNDERRUN_RATE_BPS} basis points: $summary"
  # A falling resident set is healthy; the gate is on unbounded growth.
  (( rss_delta <= MAX_RSS_DELTA_BYTES )) \
    || die "RSS delta exceeded ${MAX_RSS_DELTA_BYTES} bytes: $summary"
  printf '%s\n%s\n' "$summary" "$audio_summary" | tee "$OUTPUT_DIR/$label-metrics.txt"
}

run_profile() {
  ensure_runtime_bundle
  # A live leaks scan suspends the process and would manufacture scheduler
  # drops. Keep the performance gate isolated from leak evidence.
  SM64_MODERN_M9_CAPTURE_LEAKS=0 launch_profile profile
  profile_gate profile
}

run_leak_profile() {
  ensure_runtime_bundle
  SM64_MODERN_M9_CAPTURE_LEAKS=1 launch_profile leak-profile
  test -s "$OUTPUT_DIR/leak-profile-leaks-first.txt"
  echo "Leak snapshots: $OUTPUT_DIR/leak-profile-leaks-first.txt and $OUTPUT_DIR/leak-profile-leaks-second.txt"
  sed -n '/leaks Report Version/,$p' "$OUTPUT_DIR/leak-profile-leaks-first.txt" \
    | head -n 12
}

run_metal_validation() {
  ensure_runtime_bundle
  launch_profile metal-validation \
    MTL_DEBUG_LAYER=1 \
    MTL_SHADER_VALIDATION=1 \
    MTL_SHADER_VALIDATION_REPORT_TO_STDERR=1
  grep -E 'm9_profile_complete|engine_thread_finished|metal_|audio_service_stopped' \
    "$OUTPUT_DIR/metal-validation.log" || true
  echo "Metal validation output is saved at $OUTPUT_DIR/metal-validation.log"
}

run_gpu_capture() {
  local capture_path="$OUTPUT_DIR/m9.gputrace"
  ensure_runtime_bundle
  assert_no_live_app
  test -d "$RUNTIME_APP_BUNDLE"
  /usr/bin/open -n "$RUNTIME_APP_BUNDLE" \
    --env "SM64_MODERN_GAME_DIR=$PROJECT_ROOT" \
    --env "SM64_MODERN_SAVE_DIR=$SAVE_ROOT" \
    --env "SM64_MODERN_M9_PROFILE_TICKS=${SM64_MODERN_M9_CAPTURE_TICKS:-600}" \
    --env "SM64_MODERN_M9_PROFILE_WARMUP_TICKS=60" \
    --env MTL_CAPTURE_ENABLED=1 \
    --env MTLCAPTURE_WAIT_FOR_SIGNAL=1
  local app_pid
  app_pid="$(wait_for_app_pid)" || die "Release app did not launch for GPU capture"
  gpucapture boundaries --pid "$app_pid" > "$OUTPUT_DIR/gpucapture-boundaries.txt" 2>&1 || true
  if ! gpucapture start --pid "$app_pid" --until-exit --output "$capture_path" \
    > "$OUTPUT_DIR/gpucapture-start.txt" 2>&1; then
    echo "GPU capture could not start; see $OUTPUT_DIR/gpucapture-start.txt" >&2
    wait_for_app_exit "$app_pid" 120 || true
    return 1
  fi
  test -s "$capture_path"
  echo "GPU capture: $capture_path"
}

run_bob_check() {
  local bob_dir="${SM64_MODERN_M9_BOB_DIR:-$OUTPUT_DIR/bob-live-$(date +%Y%m%d-%H%M%S)}"
  local bob_ticks="${SM64_MODERN_M9_BOB_TICKS:-1800}"
  if [[ -e "$bob_dir" ]]; then
    die "BOB evidence directory already exists: $bob_dir"
  fi
  SM64_MODERN_CODE_SIGN_IDENTITY="${SM64_MODERN_CODE_SIGN_IDENTITY:--}" \
  SM64_MODERN_M7_DIR="$bob_dir" \
  SM64_MODERN_M7_TICKS="$bob_ticks" \
    "$PROJECT_ROOT/script/build_and_run.sh" --m7-record-live
  SM64_MODERN_CODE_SIGN_IDENTITY="${SM64_MODERN_CODE_SIGN_IDENTITY:--}" \
  SM64_MODERN_M7_DIR="$bob_dir" \
  SM64_MODERN_M7_TICKS="$bob_ticks" \
  SM64_MODERN_M7_SWIFT_TICKS="$bob_ticks" \
    "$PROJECT_ROOT/script/build_and_run.sh" --m7-shadow-live
}

case "$MODE" in
  build)
    build_release
    ;;
  inspect)
    sign_release
    inspect_release
    ;;
  package)
    sign_release
    inspect_release
    package_release
    ;;
  profile)
    run_profile
    ;;
  metal-validation)
    run_metal_validation
    ;;
  capture)
    run_gpu_capture
    ;;
  leaks)
    run_leak_profile
    ;;
  bob)
    run_bob_check
    ;;
  all)
    build_release
    sign_release
    inspect_release
    package_release
    run_profile
    ;;
  *)
    echo "usage: $0 [build|inspect|package|profile|leaks|metal-validation|capture|bob|all]" >&2
    exit 2
    ;;
esac
