# Full Swift Twin Handoff — Phase 41 M34/M35 External State Refresh

Date: 2026-08-21

## Scope and verdict

This phase performed a bounded, read-only refresh of the external M34/M35
state. It did not unlock or log in, change `xcode-select`, credentials,
keychains, signing identities, source, project files, release artifacts, or
Gatekeeper state. It did not archive, export, notarize, staple, or launch a
distribution flow. M34 remains blocked by the locked/asleep display session;
M35 remains blocked by the same two user-controlled prerequisites. Clean-machine
Gatekeeper and human acceptance remain unstarted.

The checkout at inspection was branch `nightly`, commit
`469d574139e74f091780af0b46b0911941f14472`, ahead of `origin/nightly` by 62
commits. This handoff is the only file owned by this phase.

## M34 host/compositor state

The live read-only checks reported:

- `ioreg -n Root -d 1` reported an active console user with
  `kCGSessionLoginDoneKey=Yes` and `CGSSessionScreenIsLocked=Yes`.
- `system_profiler SPDisplaysDataType` reported both the built-in Liquid
  Retina XDR display and `DELL S3220DGF` as `Online: Yes` and `Display Asleep:
  Yes`.
- No unlock, password, wake, or GUI interaction was attempted in this phase.

The latest retained M34 output directory is
`/tmp/sm64-modern-m34-phase32-host-refresh-232810/` (currently present), with
`validation.log`, `capture-manual/capture.log`, `capture-manual/m34b.gputrace`,
`signing.txt`, and `spctl.txt` among its artifacts. The validation pass records
`steps=600 scheduler_dropped_steps=67 callbacks=3 presented=3
archive_reuse=false`; the separate capture-only log records
`steps=600 scheduler_dropped_steps=0 callbacks=3 presented=3
callback_idle_ms=9966 archive_reuse=false`, followed by
`metal_shutdown_drained frames=3 completion=3` and clean status-0 shutdown.
These remain structural/diagnostic artifacts, not visible-layer, physical,
performance/thermal, visual-parity, or human-acceptance evidence. The retained
host screenshots are `/tmp/sm64-m34-phase32-host-before.png`,
`/tmp/sm64-m34-phase32-host-after-wake.png`, and
`/tmp/sm64-m34-phase32-host-after-run.png`; this phase did not create or alter
them.

## Stable Xcode 26.6 readiness

The machine-wide selection remains unchanged:

```text
xcode-select --print-path
/Applications/Xcode-beta.app/Contents/Developer
```

The invocation-scoped stable toolchain is present and reports:

```text
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -version
Xcode 26.6
Build version 17F113
xcode_sdk=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk
```

The read-only command
`SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
./script/m9_release.sh readiness` exited `1` and reported
`notary_auth=unavailable`, `clean_machine_acceptance=not checked`, and exactly
these blockers:

```text
no valid Developer ID Application identity is available in the local keychain
no notarytool authentication configuration was supplied (profile, API key, or Apple ID credentials)
```

The invocation reported the stable `xcodebuild`, `notarytool`, and `stapler`
paths under `/Applications/Xcode.app/Contents/Developer`. It also confirmed
the corrected Release entitlements (`get-task-allow=false`,
`sustained-execution=true`) and Debug `get-task-allow=true`; no entitlement
blocker was added. The machine-wide developer directory was the same before
and after the readiness invocation.

The focused read-only contract checks passed:

```text
SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/test_m9_release_readiness.sh
SM64_MODERN_M35_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/test_m35_distribution_flow.sh
```

Both tests passed their fail-closed/no-mutation contracts. They do not prove a
signed distribution or clean-machine acceptance.

## Signing and notary state

`security find-identity -v -p codesigning` still reports exactly two valid
identities:

```text
Apple Development: Derek Stiles (RWSPYS288D)
Apple Distribution: LDM Co LLC (KV5KQJ3LLD)
```

No `Developer ID Application` identity/private-key pair is available. The
notary-related environment variable names were absent from the diagnostic
process, and stable readiness reported no supplied profile, API-key tuple, or
Apple ID app-specific-password tuple. No credential value was printed,
created, or changed.

## Distribution artifact and Gatekeeper state

The expected M35 paths are absent:

```text
build/m9-release/SM64-Modern.xcarchive
build/m9-release/export
build/m9-release/export-options.plist
build/m9-release/SM64-Modern.dmg
build/m9-release/SM64-Modern.zip
```

The only ZIP in `build/m9-release` is the older local-development artifact
`build/m9-release/SM64-Modern-0.1.zip` (6,681,507 bytes, mtime
2026-08-12 20:27:27 -0400, SHA-256
`4afcfae71de12bd3b377ae26a269b44aa3ba95bbb69ae36bb019a690d0a3281e`). Its
retained `signing.txt` identifies Apple Development signing and its retained
`spctl.txt` says `rejected`; it is not an M35 artifact. The current local app
paths are also not distribution evidence:

- `build/m9-release/local-runtime/SM64 Modern.app` is Apple Development and
  `spctl -a -vv -t execute` returned `rejected` (exit 3).
- `build/xcode-derived-m9-release/Build/Products/Release/SM64 Modern.app` is
  ad hoc (`TeamIdentifier=not set`) and `spctl -a -vv -t execute` returned
  `rejected` (exit 3).
- `codesign --verify --deep --strict` validates both local apps on disk, which
  is not Gatekeeper or distribution acceptance.

No Developer ID-signed/stapled app or DMG, notarization ticket/submission
record, clean-machine Gatekeeper record, or M35 export directory is present.

## Human acceptance state

The only acceptance-related project artifact found is the prescribed procedure
`.porting/porting-handoff-full-swift-twin-phase22-m35-acceptance.md`. No
`human-acceptance`, `clean-machine`, or `gatekeeper` result directory, dated
physical display/controller/audio/haptic matrix, fresh-save 120-star record, or
first-open observation exists. The human gate remains **MISSING** and cannot be
inferred from the local app, `spctl`, source contracts, or M34 capture logs.

## Validation and handoff

- `git diff --check` passed.
- No source, docs other than this handoff, credentials, keychain, toolchain
  selection, release artifact, Gatekeeper state, archive, notarization,
  stapling, or human-acceptance state was changed.
- No commit was created; the parent agent owns review and commit.

The exact external blockers are unchanged: provide an authorized Developer ID
Application identity/private key and one supported notarytool authentication
mode, then supply an unlocked visible GUI session for M34 and a separate clean
machine plus physical setup for Gatekeeper/human acceptance.
