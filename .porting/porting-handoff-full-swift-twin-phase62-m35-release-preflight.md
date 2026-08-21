# Full Swift Twin Handoff — Phase 62 M35 Release Preflight

Date: 2026-08-21

## Scope and verdict

This phase performed a read-only M35 release-preflight audit from the
repository at commit 5bd4eee995e9a01e87e3f0a6ad6f8aed3517e95d (the Phase 60
documentation commit). It inspected the local app/build candidates, current
Release settings and entitlements, selected and invocation-scoped toolchains,
signing identities, notary configuration presence, and the fail-closed
readiness/distribution contracts. It did not change source or public
documentation, xcode-select, credentials, keychains, signing identities,
external services, or release artifacts. It did not archive, export, upload,
notarize, staple, or launch an app.

M35 release readiness is BLOCKED. The stable invocation-scoped preflight fails
on exactly two user-controlled prerequisites: no valid Developer ID
Application identity/private-key pair and no supported notarytool
authentication configuration. The machine-wide selection is also a beta
Xcode, so distribution must use the ordinary Xcode override. There is no
signed/stapled M35 artifact, clean-machine Gatekeeper result, or human
acceptance result.

## Toolchain and project settings

The machine-wide selection was inspected without changing it:

    xcode-select --print-path
    /Applications/Xcode-beta.app/Contents/Developer
    xcrun --find xcodebuild
    /Applications/Xcode-beta.app/Contents/Developer/usr/bin/xcodebuild
    xcodebuild -version
    Xcode 27.0
    Build version 27A5237l
    xcrun --sdk macosx --show-sdk-path
    /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX27.0.sdk

The ordinary Xcode installation is present and was tested invocation-scoped;
the global selection remained beta before and after:

    DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -version
    Xcode 26.6
    Build version 17F113
    DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun --sdk macosx --show-sdk-path
    /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk
    DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun --find notarytool
    /Applications/Xcode.app/Contents/Developer/usr/bin/notarytool
    DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun --find stapler
    /Applications/Xcode.app/Contents/Developer/usr/bin/stapler
    xcode-select --print-path (after)
    /Applications/Xcode-beta.app/Contents/Developer

The current XcodeGen/project settings were inspected with:

    DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
      xcodebuild -project SM64Modern.xcodeproj -scheme SM64Modern \
      -configuration Release -showBuildSettings

That command exited 0 and reported:

    ARCHS = arm64
    CODE_SIGNING_ALLOWED = NO
    CODE_SIGNING_REQUIRED = YES
    CODE_SIGN_ENTITLEMENTS = SM64Modern/SM64Modern.entitlements
    CODE_SIGN_IDENTITY = Apple Development
    CODE_SIGN_STYLE = Manual
    ENABLE_HARDENED_RUNTIME = YES
    MACOSX_DEPLOYMENT_TARGET = 27.0
    PRODUCT_BUNDLE_IDENTIFIER = io.github.deestiz.sm64modern
    PRODUCT_NAME = SM64 Modern
    SDKROOT = .../Xcode.app/.../MacOSX26.5.sdk
    SWIFT_VERSION = 6.0

These are ordinary build defaults, not distribution acceptance. The
distribution script overrides signing only after readiness passes, using
CODE_SIGNING_ALLOWED=YES, CODE_SIGNING_REQUIRED=YES, manual signing, and a
Developer ID identity. script/build_prod.sh intentionally builds an
unsigned/ad-hoc Release product with CODE_SIGNING_ALLOWED=NO; that product
cannot be treated as distributable.

The current source entitlement files lint successfully. Release contains
com.apple.security.get-task-allow=false and
com.apple.developer.sustained-execution=true. Debug contains only
com.apple.security.get-task-allow=true. The source values are not a
substitute for inspecting a freshly Developer ID-signed exported artifact.

## Signing and notary state

The exact read-only keychain query reported:

    security find-identity -p codesigning -v
      1) F7DBAB7E0F7F060C5102FE64C25239BCC6D5D20F "Apple Development: Derek Stiles (RWSPYS288D)"
      2) 0F17166E195DF4FE38F93B8C9C88F788797AE1D3 "Apple Distribution: LDM Co LLC (KV5KQJ3LLD)"
         2 valid identities found

The Developer ID Application count is 0; Apple Development and Apple
Distribution counts are 1 each. Neither Apple Development, Apple Distribution,
nor ad-hoc signing satisfies M35.

No supported notary authentication variable was present in the diagnostic
environment. Only variable names were checked; no credential values were
printed. The absent names were:

    SM64_MODERN_NOTARY_PROFILE
    SM64_MODERN_NOTARY_KEYCHAIN_PROFILE
    NOTARYTOOL_KEYCHAIN_PROFILE
    SM64_MODERN_NOTARY_KEY_ID / ASC_KEY_ID
    SM64_MODERN_NOTARY_ISSUER_ID / ASC_ISSUER_ID
    SM64_MODERN_NOTARY_PRIVATE_KEY / ASC_PRIVATE_KEY_PATH
    SM64_MODERN_NOTARY_APPLE_ID / APPLE_ID
    SM64_MODERN_NOTARY_TEAM_ID / APPLE_TEAM_ID
    SM64_MODERN_NOTARY_APP_PASSWORD / APPLE_APP_SPECIFIC_PASSWORD

The direct default readiness invocation exited 1 and reported:

    xcode_developer_dir=/Applications/Xcode-beta.app/Contents/Developer
    xcode_version=Xcode 27.0 | Build version 27A5237l
    notary_auth=unavailable
    clean_machine_acceptance=not checked by this local preflight
    release_readiness=BLOCKED (3 prerequisite failures)
    BLOCKER: xcode-select points to a beta/preview Xcode; select ordinary Xcode.app: /Applications/Xcode-beta.app/Contents/Developer
    BLOCKER: no valid Developer ID Application identity is available in the local keychain
    BLOCKER: no notarytool authentication configuration was supplied (profile, API key, or Apple ID credentials)

The invocation-scoped ordinary-Xcode readiness invocation exited 1 and
reported exactly the two external blockers:

    xcode_developer_dir=/Applications/Xcode.app/Contents/Developer
    xcode_developer_dir_source=environment override
    xcode_version=Xcode 26.6 | Build version 17F113
    xcode_sdk=.../Xcode.app/.../MacOSX26.5.sdk
    notary_auth=unavailable
    archive_prerequisite=xcodebuild archive/export tooling checked
    dmg_prerequisite=hdiutil availability checked; disk-image creation not run
    staple_prerequisite=xcrun stapler availability checked; no ticket fetched or stapled
    zip_stapling_caveat=ZIP files cannot receive stapled tickets; staple the nested signed app before zipping and validate the DMG/app separately
    clean_machine_acceptance=not checked by this local preflight
    release_readiness=BLOCKED (2 prerequisite failures)
    BLOCKER: no valid Developer ID Application identity is available in the local keychain
    BLOCKER: no notarytool authentication configuration was supplied (profile, API key, or Apple ID credentials)

The guarded direct distribution invocation used the ordinary Xcode override
and an explicit ad-hoc identity to exercise the fail-closed path. It exited 1
before creating the scratch output directory:

    BLOCKER: no valid Developer ID Application identity is available in the local keychain
    BLOCKER: SM64_MODERN_CODE_SIGN_IDENTITY=- requests ad hoc signing; M35 requires Developer ID Application
    BLOCKER: no notarytool authentication configuration was supplied (profile, API key, or Apple ID credentials)
    m9_release: distribution=BLOCKED; no archive, export, DMG, notarization, stapling, or ZIP mutation was performed
    distribution_output_exists=no

## Existing app and package artifacts

No current M35 archive/export/DMG was found:

    build/m9-release/SM64-Modern.xcarchive       absent
    build/m9-release/export                      absent
    build/m9-release/export-options.plist        absent
    build/m9-release/SM64-Modern.dmg             absent
    build/m9-release/SM64-Modern.zip             absent

The existing local candidates are historical or intentionally unsigned and
are not current distribution evidence. Their binary mtimes predate the
current Phase 60 commit (2026-08-21T04:44:42-04:00):

* build/xcode-derived-m9-release/Build/Products/Release/SM64 Modern.app has a
  binary mtime of 2026-08-17 06:30:18 -0400. codesign -dvvv reports an ad-hoc
  runtime signature with TeamIdentifier=not set; the inspected embedded
  entitlements are sustained-execution=true and get-task-allow=true, so this
  is not a valid current Release distribution artifact. codesign
  --verify --deep --strict exits 0, but spctl -a -vv rejects it with exit 3.
* build/m9-release/local-runtime/SM64 Modern.app is an Apple Development
  signed local runtime copy (Apple Development: Derek Stiles (RWSPYS288D)),
  with get-task-allow=true. Strict code-signature verification exits 0, but
  spctl -a -vv rejects it with exit 3 (origin=Apple Development).
* build/xcode-derived-prod/Build/Products/Release/SM64 Modern.app has a
  binary mtime of 2026-08-20 08:35:36 -0400, but is ad-hoc linker-signed,
  has Info.plist=not bound and Sealed Resources=none. Deep strict
  verification exits 1 with code has no resources but signature indicates
  they must be present; spctl -a -vv returns the same failure. This is the
  unsigned fast production path, not M35 evidence.
* build/m9-release/SM64-Modern-0.1.zip is an older local-development ZIP, not
  the M35 SM64-Modern.zip. It is 6,681,507 bytes, mtime
  2026-08-12 20:27:27 -0400, SHA-256
  4afcfae71de12bd3b377ae26a269b44aa3ba95bbb69ae36bb019a690d0a3281e.
  spctl -a -vv rejects it with source=no usable signature. ZIP itself cannot
  receive a stapled ticket; the nested app must be signed/stapled and
  separately validated before packaging.

All three inspected app bundles contain no .z64, .rom, or .png asset payload
(rom_asset_count=0). A fresh first launch therefore still requires the
legally extracted external game asset directory described by the human
acceptance procedure.

## Runtime, first-launch, and human-acceptance boundary

The retained local M9 host logs are from August 12 and are not current
distribution or human-acceptance evidence. They show a bounded host run did
reach application_ready, metal_scene_presented frame=1, and
audio_service_started; the 3,600-step profile ended with
engine_thread_finished status=0, scheduler_dropped_steps=0,
audio_dropped_delta=0, and audio_underrun_rate_bps=0. The same log reports
controllers=0 and input_focus active=false, so it does not prove physical
controller routing or feel. The display-link and audio lines prove only that
an old local host run emitted platform telemetry; they do not prove physical
display quality, post-resume behavior, audio parity, thermal behavior, or
human review.

The retained BOB record/baseline save files are both old (mtime 2026-08-10)
and have the same SHA-256
ed22a78d4e77ded30cd61898a7aa03a355a1db16d15b5a19d24a4538aac9020a. That is
not a fresh-save import/relaunch/recovery result. No dated human-acceptance,
clean-machine, or gatekeeper result directory, fresh 120-star checklist, or
first-open observation exists. The following gates remain OPEN/MISSING:

1. Build a fresh Release product from the current commit after the real
   signing prerequisites are available; inspect the exported app with
   codesign -dvvv --entitlements :- and
   codesign --verify --deep --strict.
2. Run the actual signed/stapled DMG/app on a separate clean machine and
   record quarantine-preserving first open plus
   spctl -a -vv -t open/execute.
3. Provide the external asset directory and exercise first launch, asset
   import/loading, fresh save creation, relaunch persistence, save recovery,
   and crash-free shutdown.
4. Exercise physical controller connection, focus, mapping, feel, audio
   output/continuity, display/window/fullscreen/resize behavior, pause/resume,
   and post-resume presentation on the target setup.
5. Complete and record the human fresh-save 120-star gameplay matrix,
   including progression, secrets, keys/caps/cannons/Bowser, final access,
   controls, audio, display, and recovery.

## Validation and minimum unblock conditions

The existing fail-closed contracts passed:

    ./script/test_m35_distribution_flow.sh
    SM64 Modern M35 distribution-flow contract passed

    ./script/test_m9_release_readiness.sh
    SM64 Modern M9 release readiness contract passed

    plutil -lint -s SM64Modern/SM64Modern.entitlements
    plutil -lint -s SM64Modern/SM64ModernDebug.entitlements

The direct readiness/distribution results above were captured without creating
an output directory. git diff --check passed before and after this handoff was
written. No commit was created by this worker; the parent agent owns review
and the automatic local phase commit.

Minimum M35 unblock conditions are: use ordinary Xcode through
SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer;
install an authorized Developer ID Application certificate with its private
key; supply one supported notarytool profile/API-key/Apple-ID authentication
mode; run the distribution flow; and independently validate the signed/
stapled app and DMG on a clean machine. Those steps still do not close
physical or human acceptance until the separate first-launch, save/import,
controller, audio, display, and 120-star matrix is recorded.
