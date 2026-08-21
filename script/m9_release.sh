#!/usr/bin/env bash
set -euo pipefail

# M9 is intentionally a local evidence harness. It can build, sign/package,
# exercise the Release product, and save validation/capture/leak artifacts, but
# it never claims Developer ID, notarization, or clean-machine acceptance.
# The readiness mode is a read-only M35 preflight; it only checks prerequisites
# and never submits, staples, or treats a local result as distribution proof.

MODE="${1:-all}"
APP_NAME="SM64 Modern"
BUNDLE_ID="io.github.deestiz.sm64modern"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# M35 may be run with a stable Xcode without changing the machine-wide
# xcode-select choice. The project-specific name is convenient for scripted
# release runs; the standard DEVELOPER_DIR remains supported for direct use.
DEVELOPER_DIR_OVERRIDE="${SM64_MODERN_M35_DEVELOPER_DIR:-${DEVELOPER_DIR:-}}"
if [[ -n "$DEVELOPER_DIR_OVERRIDE" ]]; then
  export DEVELOPER_DIR="$DEVELOPER_DIR_OVERRIDE"
fi
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
M35_ARCHIVE_PATH="${SM64_MODERN_M35_ARCHIVE_PATH:-$OUTPUT_DIR/SM64-Modern.xcarchive}"
M35_EXPORT_DIR="${SM64_MODERN_M35_EXPORT_DIR:-$OUTPUT_DIR/export}"
M35_EXPORT_OPTIONS_PATH="${SM64_MODERN_M35_EXPORT_OPTIONS_PATH:-$OUTPUT_DIR/export-options.plist}"
M35_EXPORTED_APP="$M35_EXPORT_DIR/$APP_NAME.app"
M35_DMG_PATH="${SM64_MODERN_M35_DMG_PATH:-$OUTPUT_DIR/SM64-Modern.dmg}"
M35_ZIP_PATH="${SM64_MODERN_M35_ZIP_PATH:-$OUTPUT_DIR/SM64-Modern.zip}"
SIGNING_IDENTITY=""
SIGNING_STATE=""

if [[ "$MODE" != "readiness" && "$MODE" != "distribution" && "$MODE" != "archive" ]]; then
  mkdir -p "$OUTPUT_DIR"
fi

die() {
  echo "m9_release: $*" >&2
  exit 1
}

assert_no_live_app() {
  if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
    die "$APP_NAME is already running; close it before collecting isolated M9 evidence"
  fi
}

readiness_blockers=()

readiness_block() {
  readiness_blockers+=("$*")
}

readiness_require_command() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    readiness_block "missing required command: $command_name"
  fi
}

readiness_require_xcrun_tool() {
  local tool_name="$1"
  local tool_path=""
  tool_path="$(xcrun --find "$tool_name" 2>/dev/null || true)"
  if [[ -z "$tool_path" || ! -x "$tool_path" ]]; then
    readiness_block "xcrun tool unavailable: $tool_name"
  fi
}

readiness_plist_value() {
  local file_path="$1"
  local key_path="$2"
  if [[ ! -x /usr/libexec/PlistBuddy ]]; then
    return 0
  fi
  /usr/libexec/PlistBuddy -c "Print :$key_path" "$file_path" 2>/dev/null || true
}

run_release_readiness() {
  local selected_developer_dir=""
  local developer_dir_source="xcode-select"
  local developer_dir_selected=0
  local selected_xcodebuild=""
  local selected_sdk=""
  local xcode_version=""
  local xcode_version_report=""
  local selected_app=""
  local selected_app_name=""
  local release_task_allow=""
  local release_sustained_execution=""
  local debug_task_allow=""
  local debug_sustained_execution=""
  local identities=""
  local requested_identity="${SM64_MODERN_CODE_SIGN_IDENTITY:-}"
  local notary_profile="${SM64_MODERN_NOTARY_PROFILE:-${SM64_MODERN_NOTARY_KEYCHAIN_PROFILE:-${NOTARYTOOL_KEYCHAIN_PROFILE:-}}}"
  local notary_key_id="${SM64_MODERN_NOTARY_KEY_ID:-${ASC_KEY_ID:-}}"
  local notary_issuer_id="${SM64_MODERN_NOTARY_ISSUER_ID:-${ASC_ISSUER_ID:-}}"
  local notary_private_key="${SM64_MODERN_NOTARY_PRIVATE_KEY:-${ASC_PRIVATE_KEY_PATH:-}}"
  local notary_apple_id="${SM64_MODERN_NOTARY_APPLE_ID:-${APPLE_ID:-}}"
  local notary_team_id="${SM64_MODERN_NOTARY_TEAM_ID:-${APPLE_TEAM_ID:-}}"
  local notary_app_password="${SM64_MODERN_NOTARY_APP_PASSWORD:-${APPLE_APP_SPECIFIC_PASSWORD:-}}"
  local notary_auth_mode=""

  # Keep this mode read-only. It may inspect command output and source files,
  # but it must not create an archive, disk image, keychain profile, or ticket.
  printf '%s\n' 'M35 release readiness preflight (prerequisites only; no submission/stapling performed)'

  readiness_require_command xcode-select
  readiness_require_command xcrun
  readiness_require_command xcodebuild
  readiness_require_command security
  readiness_require_command codesign
  readiness_require_command plutil
  readiness_require_command hdiutil
  readiness_require_command ditto
  readiness_require_command shasum
  readiness_require_command spctl

  if [[ ! -x /usr/libexec/PlistBuddy ]]; then
    readiness_block 'missing required command: /usr/libexec/PlistBuddy'
  fi

  if [[ -n "$DEVELOPER_DIR_OVERRIDE" ]]; then
    selected_developer_dir="$DEVELOPER_DIR_OVERRIDE"
    developer_dir_source='environment override'
    developer_dir_selected=1
  elif command -v xcode-select >/dev/null 2>&1; then
    selected_developer_dir="$(xcode-select --print-path 2>/dev/null || true)"
    developer_dir_selected=1
  fi
  if (( developer_dir_selected == 1 )); then
    if [[ -z "$selected_developer_dir" || ! -d "$selected_developer_dir" ]]; then
      readiness_block "${developer_dir_source} does not point to an installed Developer directory: ${selected_developer_dir:-unavailable}"
    else
      case "$selected_developer_dir" in
        */CommandLineTools*)
          readiness_block "${developer_dir_source} points to CommandLineTools, not ordinary Xcode: $selected_developer_dir"
          ;;
      esac
      if [[ "$selected_developer_dir" == */Contents/Developer ]]; then
        selected_app="${selected_developer_dir%/Contents/Developer}"
        selected_app_name="${selected_app##*/}"
        if [[ "$selected_app_name" != Xcode*.app ]]; then
          readiness_block "${developer_dir_source} points to a non-Xcode developer bundle: $selected_developer_dir"
        fi
        case "$selected_app_name" in
          *[Bb]eta*|*[Ss]eed*|*[Pp]review*|*[Rr][Cc]*)
            readiness_block "${developer_dir_source} points to a beta/preview Xcode; select ordinary Xcode.app: $selected_developer_dir"
            ;;
        esac
      else
        readiness_block "${developer_dir_source} path is not an Xcode Contents/Developer directory: $selected_developer_dir"
      fi
    fi
  fi

  if command -v xcrun >/dev/null 2>&1; then
    selected_xcodebuild="$(xcrun --find xcodebuild 2>/dev/null || true)"
    if [[ -z "$selected_xcodebuild" || ! -x "$selected_xcodebuild" ]]; then
      readiness_block 'xcrun cannot resolve the selected xcodebuild'
    elif [[ -n "$selected_developer_dir" && "$selected_xcodebuild" != "$selected_developer_dir/"* ]]; then
      readiness_block "xcrun xcodebuild is not from ${developer_dir_source}: $selected_xcodebuild"
    else
      xcode_version="$("$selected_xcodebuild" -version 2>/dev/null || true)"
      if [[ -z "$xcode_version" || "$xcode_version" != Xcode\ * ]]; then
        readiness_block 'selected xcodebuild did not report an Xcode version'
      fi
      if grep -Eiq 'beta|seed|preview|release candidate|[[:space:]]rc([[:space:]]|$)' <<< "$xcode_version"; then
        readiness_block "selected xcodebuild reports a beta/preview toolchain: ${xcode_version//$'\n'/ }"
      fi
    fi
    selected_sdk="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
    if [[ -z "$selected_sdk" || ! -d "$selected_sdk" ]]; then
      readiness_block 'xcrun cannot resolve an installed macOS SDK from the selected Xcode'
    fi
  fi

  identities="$(security find-identity -v -p codesigning 2>/dev/null || true)"
  if ! grep -Fq 'Developer ID Application:' <<< "$identities"; then
    readiness_block 'no valid Developer ID Application identity is available in the local keychain'
  fi
  if [[ "$requested_identity" == '-' ]]; then
    readiness_block 'SM64_MODERN_CODE_SIGN_IDENTITY=- requests ad hoc signing; M35 requires Developer ID Application'
  elif [[ -n "$requested_identity" ]]; then
    if [[ "$requested_identity" == Developer\ ID\ Application:* ]]; then
      if ! grep -Fq "$requested_identity" <<< "$identities"; then
        readiness_block "requested Developer ID Application identity is not installed: $requested_identity"
      fi
    elif [[ "$requested_identity" =~ ^[A-Fa-f0-9]{40}$ ]]; then
      if ! grep -F "$requested_identity" <<< "$identities" | grep -Fq 'Developer ID Application:'; then
        readiness_block "requested signing hash is not a Developer ID Application identity: $requested_identity"
      fi
    else
      readiness_block "requested signing identity is not a Developer ID Application identity: $requested_identity"
    fi
  fi

  for entitlement_file in "$RELEASE_ENTITLEMENTS" "$LOCAL_ENTITLEMENTS"; do
    if [[ ! -f "$entitlement_file" ]]; then
      readiness_block "missing entitlement file: $entitlement_file"
    elif ! plutil -lint -s "$entitlement_file" >/dev/null 2>&1; then
      readiness_block "invalid entitlement plist: $entitlement_file"
    fi
  done
  if [[ -f "$RELEASE_ENTITLEMENTS" ]]; then
    release_task_allow="$(readiness_plist_value "$RELEASE_ENTITLEMENTS" 'com.apple.security.get-task-allow')"
    release_sustained_execution="$(readiness_plist_value "$RELEASE_ENTITLEMENTS" 'com.apple.developer.sustained-execution')"
    [[ "$release_task_allow" == false ]] || readiness_block "Release entitlement com.apple.security.get-task-allow must be false (found ${release_task_allow:-missing})"
    [[ "$release_sustained_execution" == true ]] || readiness_block "Release entitlement com.apple.developer.sustained-execution must be true (found ${release_sustained_execution:-missing})"
  fi
  if [[ -f "$LOCAL_ENTITLEMENTS" ]]; then
    debug_task_allow="$(readiness_plist_value "$LOCAL_ENTITLEMENTS" 'com.apple.security.get-task-allow')"
    debug_sustained_execution="$(readiness_plist_value "$LOCAL_ENTITLEMENTS" 'com.apple.developer.sustained-execution')"
    [[ "$debug_task_allow" == true ]] || readiness_block "Debug entitlement com.apple.security.get-task-allow must be true (found ${debug_task_allow:-missing})"
    [[ "$debug_sustained_execution" != true ]] || readiness_block 'Debug entitlements must not carry com.apple.developer.sustained-execution'
  fi
  grep -Fq 'ENABLE_HARDENED_RUNTIME: YES' "$PROJECT_ROOT/project.yml" \
    || readiness_block 'project.yml does not enable the hardened runtime'
  grep -Fq 'CODE_SIGN_ENTITLEMENTS: SM64Modern/SM64Modern.entitlements' "$PROJECT_ROOT/project.yml" \
    || readiness_block 'project.yml Release target is not wired to the distribution entitlement file'

  if [[ -n "$selected_xcodebuild" && -x "$selected_xcodebuild" ]]; then
    local xcodebuild_help
    # This is the selected Xcode's xcodebuild -help output, not PATH's tool.
    xcodebuild_help="$("$selected_xcodebuild" -help 2>&1 || true)"
    grep -Fq -- '-archivePath' <<< "$xcodebuild_help" \
      || readiness_block 'xcodebuild does not expose archivePath/export prerequisites'
    grep -Fq -- '-exportArchive' <<< "$xcodebuild_help" \
      || readiness_block 'xcodebuild does not expose exportArchive prerequisites'
  fi
  readiness_require_xcrun_tool notarytool
  readiness_require_xcrun_tool stapler
  if [[ -n "$notary_profile" ]]; then
    notary_auth_mode='keychain profile configured (not validated)'
  elif [[ -n "$notary_key_id" && -n "$notary_issuer_id" && -n "$notary_private_key" && -r "$notary_private_key" ]]; then
    notary_auth_mode='App Store Connect API key configured (not validated)'
  elif [[ -n "$notary_apple_id" && -n "$notary_team_id" && -n "$notary_app_password" ]]; then
    notary_auth_mode='Apple ID app-specific password configured (not validated)'
  else
    readiness_block 'no notarytool authentication configuration was supplied (profile, API key, or Apple ID credentials)'
  fi

  xcode_version_report="${xcode_version//$'\n'/ | }"
  printf 'xcode_developer_dir=%s\n' "${selected_developer_dir:-unavailable}"
  printf 'xcode_developer_dir_source=%s\n' "$developer_dir_source"
  printf 'xcode_version=%s\n' "${xcode_version_report:-unavailable}"
  printf 'xcode_sdk=%s\n' "${selected_sdk:-unavailable}"
  printf 'notary_auth=%s\n' "${notary_auth_mode:-unavailable}"
  printf '%s\n' 'archive_prerequisite=xcodebuild archive/export tooling checked'
  printf '%s\n' 'dmg_prerequisite=hdiutil availability checked; disk-image creation not run'
  printf '%s\n' 'staple_prerequisite=xcrun stapler availability checked; no ticket fetched or stapled'
  printf '%s\n' 'zip_stapling_caveat=ZIP files cannot receive stapled tickets; staple the nested signed app before zipping and validate the DMG/app separately'
  printf '%s\n' 'clean_machine_acceptance=not checked by this local preflight'

  if (( ${#readiness_blockers[@]} > 0 )); then
    printf 'release_readiness=BLOCKED (%d prerequisite failures)\n' "${#readiness_blockers[@]}" >&2
    for blocker in "${readiness_blockers[@]}"; do
      printf 'BLOCKER: %s\n' "$blocker" >&2
    done
    return 1
  fi
  printf '%s\n' 'release_readiness=PREREQUISITES_PRESENT (distribution actions and clean-machine acceptance remain unverified)'
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
  "$PROJECT_ROOT/script/test_oracle_reachability.sh"
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

select_distribution_signing_identity() {
  local identities
  select_signing_identity
  identities="$(security find-identity -v -p codesigning 2>/dev/null || true)"

  if [[ "$SIGNING_IDENTITY" == Developer\ ID\ Application:* ]]; then
    grep -Fq "$SIGNING_IDENTITY" <<< "$identities" \
      || die "selected Developer ID Application identity is no longer available: $SIGNING_IDENTITY"
  elif [[ "$SIGNING_IDENTITY" =~ ^[[:xdigit:]]{40}$ ]]; then
    grep -F "$SIGNING_IDENTITY" <<< "$identities" | grep -Fq 'Developer ID Application:' \
      || die "selected signing hash is not a Developer ID Application identity: $SIGNING_IDENTITY"
  else
    die "distribution requires a Developer ID Application identity (selected: ${SIGNING_IDENTITY:-none})"
  fi
}

assert_distribution_targets_unused() {
  local output_path
  for output_path in \
    "$M35_ARCHIVE_PATH" \
    "$M35_EXPORT_DIR" \
    "$M35_EXPORT_OPTIONS_PATH" \
    "$M35_DMG_PATH" \
    "$M35_ZIP_PATH"; do
    [[ ! -e "$output_path" ]] \
      || die "distribution output already exists; refusing to overwrite: $output_path"
  done
}

write_distribution_export_options() {
  plutil -create xml1 "$M35_EXPORT_OPTIONS_PATH"
  plutil -insert method -string developer-id "$M35_EXPORT_OPTIONS_PATH"
  plutil -insert signingStyle -string manual "$M35_EXPORT_OPTIONS_PATH"
  plutil -insert signingCertificate -string 'Developer ID Application' "$M35_EXPORT_OPTIONS_PATH"
}

archive_distribution() {
  cd "$PROJECT_ROOT"
  xcodebuild \
    -project SM64Modern.xcodeproj \
    -scheme SM64Modern \
    -configuration Release \
    -archivePath "$M35_ARCHIVE_PATH" \
    archive \
    CODE_SIGNING_ALLOWED=YES \
    CODE_SIGNING_REQUIRED=YES \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
    > "$OUTPUT_DIR/archive.log" 2>&1 || {
      cat "$OUTPUT_DIR/archive.log" >&2
      die "Developer ID archive failed; no distribution artifact was produced"
    }
  test -d "$M35_ARCHIVE_PATH" \
    || die "xcodebuild archive did not produce the expected archive: $M35_ARCHIVE_PATH"
}

export_distribution_archive() {
  cd "$PROJECT_ROOT"
  xcodebuild \
    -project SM64Modern.xcodeproj \
    -scheme SM64Modern \
    -configuration Release \
    -archivePath "$M35_ARCHIVE_PATH" \
    -exportArchive \
    -exportPath "$M35_EXPORT_DIR" \
    -exportOptionsPlist "$M35_EXPORT_OPTIONS_PATH" \
    > "$OUTPUT_DIR/export.log" 2>&1 || {
      cat "$OUTPUT_DIR/export.log" >&2
      die "Developer ID archive export failed"
    }
  test -d "$M35_EXPORTED_APP" \
    || die "xcodebuild exportArchive did not produce the expected app: $M35_EXPORTED_APP"
}

validate_distribution_bundle() {
  local bundle="$1"
  local label="$2"
  local signing_report="$OUTPUT_DIR/$label-codesign.txt"
  local entitlements_path="$OUTPUT_DIR/$label-entitlements.plist"
  local task_allow
  local sustained_execution

  test -d "$bundle"
  if ! codesign --verify --deep --strict --verbose=2 "$bundle" > "$signing_report" 2>&1; then
    cat "$signing_report" >&2
    die "$label failed strict code-signature verification"
  fi
  codesign --display --verbose=4 "$bundle" >> "$signing_report" 2>&1 \
    || die "could not inspect the $label code signature"
  grep -Fq 'Authority=Developer ID Application:' "$signing_report" \
    || die "$label is not signed by Developer ID Application"

  if ! codesign --display --entitlements :- "$bundle" > "$entitlements_path" 2>/dev/null; then
    die "could not extract $label entitlements"
  fi
  plutil -lint -s "$entitlements_path" \
    || die "$label entitlements are not a valid plist"
  task_allow="$(readiness_plist_value "$entitlements_path" 'com.apple.security.get-task-allow')"
  sustained_execution="$(readiness_plist_value "$entitlements_path" 'com.apple.developer.sustained-execution')"
  [[ "$task_allow" == false ]] \
    || die "$label entitlements must set com.apple.security.get-task-allow=false (found ${task_allow:-missing})"
  [[ "$sustained_execution" == true ]] \
    || die "$label entitlements must set com.apple.developer.sustained-execution=true (found ${sustained_execution:-missing})"
}

notarize_distribution_artifact() {
  local artifact="$1"
  local label="$2"
  local notary_profile="${SM64_MODERN_NOTARY_PROFILE:-${SM64_MODERN_NOTARY_KEYCHAIN_PROFILE:-${NOTARYTOOL_KEYCHAIN_PROFILE:-}}}"
  local notary_key_id="${SM64_MODERN_NOTARY_KEY_ID:-${ASC_KEY_ID:-}}"
  local notary_issuer_id="${SM64_MODERN_NOTARY_ISSUER_ID:-${ASC_ISSUER_ID:-}}"
  local notary_private_key="${SM64_MODERN_NOTARY_PRIVATE_KEY:-${ASC_PRIVATE_KEY_PATH:-}}"
  local notary_apple_id="${SM64_MODERN_NOTARY_APPLE_ID:-${APPLE_ID:-}}"
  local notary_team_id="${SM64_MODERN_NOTARY_TEAM_ID:-${APPLE_TEAM_ID:-}}"
  local notary_app_password="${SM64_MODERN_NOTARY_APP_PASSWORD:-${APPLE_APP_SPECIFIC_PASSWORD:-}}"
  local notary_log="$OUTPUT_DIR/$label-notarytool.txt"

  if [[ -n "$notary_profile" ]]; then
    xcrun notarytool submit "$artifact" --wait --keychain-profile "$notary_profile" \
      > "$notary_log" 2>&1 || {
        cat "$notary_log" >&2
        die "notarytool rejected $label"
      }
  elif [[ -n "$notary_key_id" && -n "$notary_issuer_id" && -n "$notary_private_key" && -r "$notary_private_key" ]]; then
    xcrun notarytool submit "$artifact" --wait \
      --key "$notary_private_key" \
      --key-id "$notary_key_id" \
      --issuer "$notary_issuer_id" \
      > "$notary_log" 2>&1 || {
        cat "$notary_log" >&2
        die "notarytool rejected $label"
      }
  elif [[ -n "$notary_apple_id" && -n "$notary_team_id" && -n "$notary_app_password" ]]; then
    xcrun notarytool submit "$artifact" --wait \
      --apple-id "$notary_apple_id" \
      --team-id "$notary_team_id" \
      --password "$notary_app_password" \
      > "$notary_log" 2>&1 || {
        cat "$notary_log" >&2
        die "notarytool rejected $label"
      }
  else
    die "notarytool authentication is unavailable; refusing to submit $label"
  fi
}

staple_and_validate_distribution_artifact() {
  local artifact="$1"
  local label="$2"
  local staple_log="$OUTPUT_DIR/$label-stapler.txt"
  xcrun stapler staple "$artifact" > "$staple_log" 2>&1 || {
    cat "$staple_log" >&2
    die "stapler could not staple $label"
  }
  xcrun stapler validate "$artifact" >> "$staple_log" 2>&1 || {
    cat "$staple_log" >&2
    die "stapler validate failed for $label"
  }
}

verify_distribution_assessment() {
  local app="$1"
  local dmg="$2"
  spctl -a -vv -t execute "$app" > "$OUTPUT_DIR/spctl-app.txt" 2>&1 || {
    cat "$OUTPUT_DIR/spctl-app.txt" >&2
    die "spctl rejected the stapled app"
  }
  spctl -a -vv -t open "$dmg" > "$OUTPUT_DIR/spctl-dmg.txt" 2>&1 || {
    cat "$OUTPUT_DIR/spctl-dmg.txt" >&2
    die "spctl rejected the stapled DMG"
  }
}

create_distribution_dmg() {
  hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$M35_EXPORT_DIR" \
    -ov \
    -format UDZO \
    "$M35_DMG_PATH" \
    > "$OUTPUT_DIR/dmg-create.log" 2>&1 || {
      cat "$OUTPUT_DIR/dmg-create.log" >&2
      die "hdiutil could not create the distribution DMG"
    }
  test -f "$M35_DMG_PATH" \
    || die "hdiutil did not produce the expected DMG: $M35_DMG_PATH"
}

package_distribution_zip() {
  /usr/bin/ditto -c -k --keepParent "$M35_EXPORTED_APP" "$M35_ZIP_PATH"
  shasum -a 256 "$M35_ZIP_PATH" | tee "$OUTPUT_DIR/SM64-Modern.zip.sha256"
}

run_distribution() {
  # Readiness is deliberately the first action. In particular, do not create
  # OUTPUT_DIR until every external signing/notary prerequisite is present.
  if ! run_release_readiness; then
    die 'distribution=BLOCKED; no archive, export, DMG, notarization, stapling, or ZIP mutation was performed'
  fi

  select_distribution_signing_identity
  mkdir -p "$OUTPUT_DIR"
  assert_distribution_targets_unused
  write_distribution_export_options

  archive_distribution
  export_distribution_archive
  validate_distribution_bundle "$M35_EXPORTED_APP" exported-app

  # Notarize and staple the app before creating the DMG. ZIP files cannot
  # receive stapled tickets, so the ZIP is packaged only after app stapling.
  notarize_distribution_artifact "$M35_EXPORTED_APP" app
  staple_and_validate_distribution_artifact "$M35_EXPORTED_APP" app

  create_distribution_dmg
  notarize_distribution_artifact "$M35_DMG_PATH" dmg
  staple_and_validate_distribution_artifact "$M35_DMG_PATH" dmg
  verify_distribution_assessment "$M35_EXPORTED_APP" "$M35_DMG_PATH"
  package_distribution_zip

  printf 'distribution_app=%s\n' "$M35_EXPORTED_APP"
  printf 'distribution_dmg=%s\n' "$M35_DMG_PATH"
  printf 'distribution_zip=%s\n' "$M35_ZIP_PATH"
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
  readiness)
    run_release_readiness
    ;;
  distribution|archive)
    run_distribution
    ;;
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
    echo "usage: $0 [readiness|distribution|archive|build|inspect|package|profile|leaks|metal-validation|capture|bob|all]" >&2
    exit 2
    ;;
esac
