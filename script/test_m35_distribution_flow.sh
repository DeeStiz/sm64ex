#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASE_SCRIPT="$PROJECT_ROOT/script/m9_release.sh"

bash -n "$RELEASE_SCRIPT"

require_contract() {
  local needle="$1"
  rg -Fq -- "$needle" "$RELEASE_SCRIPT" \
    || { printf 'M35 distribution contract missing: %s\n' "$needle" >&2; exit 1; }
}

for required in \
  'distribution|archive)' \
  'run_distribution' \
  '-archivePath' \
  'archive' \
  'CODE_SIGNING_ALLOWED=YES' \
  '-exportArchive' \
  'Developer ID Application:' \
  'hdiutil create' \
  'notarytool submit' \
  '--wait' \
  'stapler staple' \
  'stapler validate' \
  'spctl -a -vv' \
  'ZIP files cannot receive stapled tickets' \
  'distribution=BLOCKED'; do
  require_contract "$required"
done

# Force a known blocker even on a future host that has ordinary Xcode and a
# Developer ID certificate. The test must stop before creating the output
# directory, archive, DMG, ZIP, or any other distribution artifact.
scratch_dir="$(mktemp -d "${TMPDIR:-/tmp}/sm64-m35-distribution.XXXXXX")"
scratch_log="$scratch_dir/distribution.log"
scratch_output="$scratch_dir/output"
trap 'rm -f "$scratch_log"; rmdir "$scratch_output" 2>/dev/null || true; rmdir "$scratch_dir"' EXIT

set +e
env \
  -u SM64_MODERN_NOTARY_PROFILE \
  -u SM64_MODERN_NOTARY_KEYCHAIN_PROFILE \
  -u NOTARYTOOL_KEYCHAIN_PROFILE \
  -u SM64_MODERN_NOTARY_KEY_ID \
  -u ASC_KEY_ID \
  -u SM64_MODERN_NOTARY_ISSUER_ID \
  -u ASC_ISSUER_ID \
  -u SM64_MODERN_NOTARY_PRIVATE_KEY \
  -u ASC_PRIVATE_KEY_PATH \
  -u SM64_MODERN_NOTARY_APPLE_ID \
  -u APPLE_ID \
  -u SM64_MODERN_NOTARY_TEAM_ID \
  -u APPLE_TEAM_ID \
  -u SM64_MODERN_NOTARY_APP_PASSWORD \
  -u APPLE_APP_SPECIFIC_PASSWORD \
  SM64_MODERN_CODE_SIGN_IDENTITY=- \
  SM64_MODERN_M9_OUTPUT_DIR="$scratch_output" \
  "$RELEASE_SCRIPT" distribution > "$scratch_log" 2>&1
distribution_rc=$?
set -e

(( distribution_rc != 0 )) \
  || { echo 'distribution unexpectedly passed blocked prerequisites' >&2; exit 1; }
[[ ! -e "$scratch_output" ]] \
  || { echo 'blocked distribution created an output directory' >&2; exit 1; }
rg -Fq 'BLOCKER:' "$scratch_log"
rg -Fq 'distribution=BLOCKED' "$scratch_log"
rg -Fq 'no archive, export, DMG, notarization, stapling, or ZIP mutation was performed' "$scratch_log"

printf '%s\n' 'SM64 Modern M35 distribution-flow contract passed'
