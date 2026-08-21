#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASE_SCRIPT="$PROJECT_ROOT/script/m9_release.sh"

bash -n "$RELEASE_SCRIPT"

for entitlement_file in \
  "$PROJECT_ROOT/SM64Modern/SM64Modern.entitlements" \
  "$PROJECT_ROOT/SM64Modern/SM64ModernDebug.entitlements"; do
  plutil -lint -s "$entitlement_file"
done

require_contract() {
  local needle="$1"
  rg -Fq -- "$needle" "$RELEASE_SCRIPT" \
    || { printf 'M9 release readiness contract missing: %s\n' "$needle" >&2; exit 1; }
}

for required in \
  'readiness)' \
  'run_release_readiness' \
  'SM64_MODERN_M35_DEVELOPER_DIR' \
  'DEVELOPER_DIR' \
  'xcode-select --print-path' \
  'xcode_developer_dir_source=' \
  'xcode_version=' \
  'Developer ID Application:' \
  'com.apple.security.get-task-allow' \
  'com.apple.developer.sustained-execution' \
  'xcodebuild -help' \
  'hdiutil' \
  'notarytool' \
  'stapler' \
  'zip_stapling_caveat=' \
  'clean_machine_acceptance=not checked' \
  'no submission/stapling performed'; do
  require_contract "$required"
done

# The readiness mode must not create the normal evidence directory. It may
# return blocked (1) or pass prerequisites (0), but neither result is allowed
# to be confused with notarization or clean-machine acceptance.
scratch_dir="$(mktemp -d "${TMPDIR:-/tmp}/sm64-m35-readiness.XXXXXX")"
scratch_log="$scratch_dir/readiness.log"
trap 'rm -f "$scratch_dir"/*.log; rmdir "$scratch_dir"' EXIT
scratch_output="$scratch_dir/output"
set +e
SM64_MODERN_M9_OUTPUT_DIR="$scratch_output" "$RELEASE_SCRIPT" readiness >"$scratch_log" 2>&1
readiness_rc=$?
set -e
if (( readiness_rc != 0 && readiness_rc != 1 )); then
  printf 'unexpected release readiness exit code: %d\n' "$readiness_rc" >&2
  exit 1
fi
[[ ! -e "$scratch_output" ]] \
  || { echo 'readiness mode created an output directory' >&2; exit 1; }
rg -Fq 'zip_stapling_caveat=' "$scratch_log"
rg -Fq 'clean_machine_acceptance=not checked' "$scratch_log"

# When ordinary Xcode 26.6 is installed, prove that an invocation-scoped
# DEVELOPER_DIR override bypasses a beta xcode-select choice without changing
# the machine-wide selection. Signing and notary blockers must still remain
# visible; this is toolchain evidence, not distribution acceptance.
stable_developer_dir="/Applications/Xcode.app/Contents/Developer"
stable_xcodebuild="$stable_developer_dir/usr/bin/xcodebuild"
if [[ -x "$stable_xcodebuild" ]]; then
  stable_xcode_version="$("$stable_xcodebuild" -version 2>/dev/null || true)"
  if [[ "$stable_xcode_version" == Xcode\ 26.6* ]]; then
    global_developer_dir_before="$(xcode-select --print-path 2>/dev/null || true)"
    stable_log="$scratch_dir/readiness-stable.log"
    stable_output="$scratch_dir/stable-output"
    set +e
    DEVELOPER_DIR="$stable_developer_dir" \
      SM64_MODERN_M9_OUTPUT_DIR="$stable_output" \
      "$RELEASE_SCRIPT" readiness >"$stable_log" 2>&1
    stable_readiness_rc=$?
    set -e
    [[ "$stable_readiness_rc" == 0 || "$stable_readiness_rc" == 1 ]]
    [[ ! -e "$stable_output" ]]
    rg -Fq "xcode_developer_dir=$stable_developer_dir" "$stable_log"
    rg -Fq 'xcode_developer_dir_source=environment override' "$stable_log"
    rg -Fq 'xcode_version=Xcode 26.6' "$stable_log"
    ! rg -Fq 'beta/preview Xcode' "$stable_log"
    rg -Fq 'no valid Developer ID Application identity' "$stable_log"
    rg -Fq 'no notarytool authentication configuration' "$stable_log"
    global_developer_dir_after="$(xcode-select --print-path 2>/dev/null || true)"
    [[ "$global_developer_dir_before" == "$global_developer_dir_after" ]]
  fi
fi

printf '%s\n' 'SM64 Modern M9 release readiness contract passed'
