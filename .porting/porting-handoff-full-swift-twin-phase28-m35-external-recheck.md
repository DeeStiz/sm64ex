# Full Swift Twin Handoff — Phase 28 M35 Post-Entitlement External Recheck

Date: 2026-08-20

## Scope and mutation boundary

- Rechecked M35 after Phase 27's Release entitlement correction using the
  invocation-scoped ordinary Xcode 26.6 toolchain.
- This phase added only this handoff. It did not change global `xcode-select`,
  entitlements, project settings, keychain contents, credentials, archives,
  exports, DMGs, ZIPs, notarization tickets, or Gatekeeper state.

## Stable Xcode and entitlement evidence

- Global `xcode-select --print-path` was
  `/Applications/Xcode-beta.app/Contents/Developer` both before and after the
  checks. `SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`
  selected ordinary Xcode 26.6 (`Build version 17F113`) without changing that
  global selection.
- Stable `xcrun` resolved `xcodebuild`, `notarytool`, and `stapler` from
  `/Applications/Xcode.app/Contents/Developer`; the macOS SDK was
  `MacOSX26.5.sdk`.
- Stable `xcodebuild -showBuildSettings` reported `ENABLE_HARDENED_RUNTIME=YES`
  for both configurations. Debug maps to
  `SM64Modern/SM64ModernDebug.entitlements`; Release maps to
  `SM64Modern/SM64Modern.entitlements`.
- Direct plist inspection confirms the Phase 27 correction: Release has
  `com.apple.security.get-task-allow=false` and
  `com.apple.developer.sustained-execution=true`; Debug has
  `get-task-allow=true` and no sustained-execution entitlement. The previous
  Release `get-task-allow=true` blocker is gone.

## Signing, notary, and fail-closed evidence

- `security find-identity -v -p codesigning` found valid Apple Development and
  Apple Distribution identities, but no `Developer ID Application` identity.
- No supported notary authentication configuration was present: no notary
  keychain-profile environment variable, App Store Connect API-key tuple, or
  Apple ID app-specific-password tuple was supplied. The stable preflight
  reported `notary_auth=unavailable`.
- Stable readiness returned exit `1` with exactly these two blockers:
  `no valid Developer ID Application identity is available in the local
  keychain`, and `no notarytool authentication configuration was supplied
  (profile, API key, or Apple ID credentials)`.
- The direct stable `distribution` invocation returned exit `1` on the same
  two blockers and emitted
  `distribution=BLOCKED; no archive, export, DMG, notarization, stapling, or
  ZIP mutation was performed`.
- The temporary distribution output directory did not exist after the blocked
  run; archive, export, DMG, and ZIP paths were all absent. The canonical
  `build/m9-release` M35 archive/export/options/DMG/ZIP paths were also absent
  before the check.

## Focused validation

- `./script/test_m9_release_readiness.sh` — passed.
- `./script/test_m35_distribution_flow.sh` — passed.
- `git diff --check` — passed.
- The tracked worktree remained clean (`nightly...origin/nightly [ahead 51]`)
  before and after the recheck, apart from this new handoff being added.

## Remaining blockers and acceptance boundary

The two active M35 preflight blockers are the missing authorized Developer ID
Application identity/private key and missing notary authentication. Release
entitlement correctness is no longer a blocker, although real signing still
depends on an authorized provisioned App ID accepting the sustained-execution
entitlement.

No archive/export, notarization, stapling, Gatekeeper assessment,
clean-machine launch, physical-device review, or human gameplay/visual/audio/
controller acceptance has started. Clean-machine and human acceptance remain
unstarted external gates.

## Next command after prerequisites are supplied

After the user installs the authorized Developer ID certificate/private key and
creates a notarytool keychain profile, run from the repository root (replace
the two placeholders with the exact installed identity and profile name):

```sh
cd /Users/derek/Developer/sm64ex
SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
SM64_MODERN_CODE_SIGN_IDENTITY='Developer ID Application: <AUTHORIZED CERTIFICATE COMMON NAME>' \
SM64_MODERN_NOTARY_PROFILE='<USER-SUPPLIED-NOTARYTOOL-KEYCHAIN-PROFILE>' \
./script/m9_release.sh distribution
```

That command is intentionally deferred until the external prerequisites exist;
the resulting signed/stapled artifacts still require independent clean-machine
Gatekeeper and human acceptance checks.
