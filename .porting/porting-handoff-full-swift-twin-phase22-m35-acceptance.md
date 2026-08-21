# Full Swift Twin Handoff — Continuation Phase 22 M35 Acceptance Audit

Date: 2026-08-20

## Scope and result

This phase audited the M9/M35 signing, distribution, clean-machine, and human
acceptance boundary. It did not change `xcode-select`, keychain contents,
credentials, entitlements, or distribution artifacts. M35 remains blocked and
no release or acceptance claim is made.

## Host evidence

- The machine-wide selection is `/Applications/Xcode-beta.app/Contents/Developer`
  (`Xcode 27.0`, build `27A5237l`). The invocation-scoped stable override
  `/Applications/Xcode.app/Contents/Developer` reports `Xcode 26.6`, build
  `17F113`, and the macOS 26.5 SDK.
- `security find-identity -v -p codesigning` reports valid Apple Development
  and Apple Distribution identities, but no `Developer ID Application`
  identity. No certificate or keychain profile was created.
- The stable Xcode provides `xcodebuild -archivePath`, `-exportArchive`,
  `notarytool`, and `stapler`. Notary authentication was intentionally absent
  for this audit (no profile, API-key variables, or Apple ID password).
- `SM64Modern/SM64Modern.entitlements` has
  `com.apple.security.get-task-allow=true` and
  `com.apple.developer.sustained-execution=true`. The Debug plist has only
  `get-task-allow=true`. The source project enables the hardened runtime and
  wires Release to the distribution plist; its ordinary build defaults still
  use `CODE_SIGN_IDENTITY: Apple Development` and
  `CODE_SIGNING_ALLOWED: NO`. The distribution flow overrides those settings
  only after readiness passes.

## Validation

Both focused tests passed with the stable Xcode override:

```sh
cd /Users/derek/Developer/sm64ex
SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  ./script/test_m9_release_readiness.sh
SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  ./script/test_m35_distribution_flow.sh
```

The direct stable-Xcode readiness run returned exit `1` with exactly three
blockers:

```text
no valid Developer ID Application identity is available in the local keychain
Release entitlement com.apple.security.get-task-allow must be false (found true)
no notarytool authentication configuration was supplied (profile, API key, or Apple ID credentials)
```

The direct distribution run returned exit `1` with those three blockers plus
the deliberately forced `SM64_MODERN_CODE_SIGN_IDENTITY=-` ad-hoc-signing
blocker. It reported
`distribution=BLOCKED; no archive, export, DMG, notarization, stapling, or ZIP
mutation was performed`; the requested output directory was absent. The
machine-wide developer-directory value was unchanged before and after the
run.

## Remaining gates

1. Install or otherwise make available a Developer ID Application certificate
   with its private key in the intended signing keychain. Do not use Apple
   Development, Apple Distribution, or ad-hoc signing for M35.
2. Correct the Release `get-task-allow` entitlement to `false`. Keep the
   sustained-execution entitlement only if the intended Apple entitlement and
   signing path authorizes it; do not invent or silently remove restricted
   entitlements.
3. Configure notarytool authentication using a user-supplied keychain profile,
   App Store Connect API key, or Apple ID app-specific password.
4. After a real signed/notarized/stapled DMG exists, exercise Gatekeeper on a
   separate clean Mac and record first-open behavior. This local host has no
   clean-machine evidence.
5. On that signed build, a human must complete and record the full 120-star
   gameplay matrix, including save/relaunch persistence, course/secret/100-coin
   stars, keys, caps, cannons, Bowser progression, final 120-star access,
   controls, audio, window/display behavior, pause/resume, and crash-free
   shutdown. Automated tests cannot close this gate.

## Copy-paste continuation commands

The following commands are instructions for the next authorized run. They were
not executed here.

### Developer ID identity and stable preflight

After the Developer ID certificate and private key are installed by the user,
select the first matching identity without changing global Xcode selection:

```sh
cd /Users/derek/Developer/sm64ex
export SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
export SM64_MODERN_CODE_SIGN_IDENTITY="$(
  security find-identity -v -p codesigning |
    awk -F'"' '/Developer ID Application:/ { print $2; exit }'
)"
test -n "$SM64_MODERN_CODE_SIGN_IDENTITY"
case "$SM64_MODERN_CODE_SIGN_IDENTITY" in
  "Developer ID Application:"*) ;;
  *) echo 'selected identity is not Developer ID Application' >&2; exit 1 ;;
esac
printf 'using %s\n' "$SM64_MODERN_CODE_SIGN_IDENTITY"
"$PWD/script/m9_release.sh" readiness
```

### Release entitlement correction

After reviewing and authorizing the source change, update only the Release
plist, then regenerate the project and rerun readiness:

```sh
cd /Users/derek/Developer/sm64ex
/usr/libexec/PlistBuddy \
  -c 'Set :com.apple.security.get-task-allow false' \
  SM64Modern/SM64Modern.entitlements
plutil -lint -s SM64Modern/SM64Modern.entitlements
plutil -p SM64Modern/SM64Modern.entitlements
xcodegen generate --spec project.yml
SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  "$PWD/script/m9_release.sh" readiness
```

The `com.apple.developer.sustained-execution` value must be validated against
the authorized Apple signing/provisioning path before distribution; this audit
does not choose a replacement value.

### Notarytool authentication and distribution

For a user-authorized keychain profile, run the credential prompt interactively
and never commit the password. Replace the two non-secret placeholders with
the user's Apple account values:

```sh
cd /Users/derek/Developer/sm64ex
export APPLE_ID='YOUR_APPLE_ID'
export APPLE_TEAM_ID='YOUR_TEAM_ID'
read -r -s -p 'Apple app-specific password: ' NOTARY_PASSWORD
printf '\n'
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun notarytool store-credentials SM64ModernNotary \
  --apple-id "$APPLE_ID" \
  --team-id "$APPLE_TEAM_ID" \
  --password "$NOTARY_PASSWORD"
unset NOTARY_PASSWORD
export SM64_MODERN_NOTARY_PROFILE=SM64ModernNotary
SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  SM64_MODERN_CODE_SIGN_IDENTITY="$SM64_MODERN_CODE_SIGN_IDENTITY" \
  "$PWD/script/m9_release.sh" readiness
SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  SM64_MODERN_CODE_SIGN_IDENTITY="$SM64_MODERN_CODE_SIGN_IDENTITY" \
  "$PWD/script/m9_release.sh" distribution
```

An App Store Connect API-key flow is also supported by setting
`SM64_MODERN_NOTARY_KEY_ID`, `SM64_MODERN_NOTARY_ISSUER_ID`, and
`SM64_MODERN_NOTARY_PRIVATE_KEY` to user-provided values instead of creating a
keychain profile.

### Clean-machine Gatekeeper

On a separate clean Mac, download the stapled DMG through a channel that
preserves quarantine metadata. Run the static checks, mount the DMG, and then
perform the first open in Finder or with `open`; record both command output and
whether macOS shows an unidentified-developer or damaged-app block:

```sh
set -euo pipefail
DMG="$HOME/Downloads/SM64-Modern.dmg"
spctl -a -vv -t open "$DMG"
MOUNT_POINT="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-gatekeeper.XXXXXX")"
hdiutil attach "$DMG" -nobrowse -mountpoint "$MOUNT_POINT"
spctl -a -vv -t execute "$MOUNT_POINT/SM64 Modern.app"
open "$MOUNT_POINT/SM64 Modern.app"
read -r -p 'After first-open and smoke review, press Return to detach: '
hdiutil detach "$MOUNT_POINT"
rmdir "$MOUNT_POINT"
```

ZIP testing must extract the nested app and run the execute assessment; a ZIP
itself cannot receive a stapled ticket. Preserve the downloaded ZIP's
quarantine state and record its SHA-256 separately.

### Human 120-star acceptance launch

Provide a legally extracted asset directory on the clean machine; ROMs and
ROM-derived assets are intentionally not embedded in the distribution bundle.
Launch the app with a fresh, dedicated save directory and use a signed app
copied from the validated DMG:

```sh
APP='/Applications/SM64 Modern.app'
ASSET_ROOT="$HOME/SM64ModernAssets"
ACCEPTANCE_SAVE="$HOME/Library/Application Support/SM64 Modern Acceptance"
mkdir -p "$ACCEPTANCE_SAVE"
open -n "$APP" \
  --env "SM64_MODERN_GAME_DIR=$ASSET_ROOT" \
  --env "SM64_MODERN_SAVE_DIR=$ACCEPTANCE_SAVE"
```

The reviewer should keep a 120-row star/course checklist and attach the build
SHA, OS/device/display/input/audio details, save/relaunch results, and any
crash or visual findings. Completion of this manual matrix is the acceptance
event; a launch, build, archive, or automated replay alone is insufficient.
