# Full Swift Twin Handoff — Phase 67d AVFAudio SDK Compatibility

Date: 2026-08-21

## Verdict

Phase 67d removes the stable-Xcode AVFAudio compile blocker without changing
the audio ring contract or owner-thread lifecycle. `AppleAudioService.m` now
selects the macOS 27 realtime-safe/error APIs when the SDK exposes them and
uses the older macOS 26 `renderBlock`/void `connect:to:format:` APIs otherwise.
The legacy branch verifies the resulting source-to-mixer connection through
the existing connection-point query and reports the same connection error
code when the graph is not connected.

## Source change

- `SM64Modern/AppleAudioService.m`
  - Defines the render block once against the stable `AVAudioSourceNode`
    block type.
  - Uses `initWithFormat:realtimeSafeRenderBlock:` under
    `__MAC_OS_X_VERSION_MAX_ALLOWED >= 270000`; older SDKs use
    `initWithFormat:renderBlock:`.
  - Uses the macOS 27 `connect:to:format:error:` result path when available;
    older SDKs use the legacy void connect method and verify the connection
    point before preparing the engine.

No audio ABI, ring capacity, sample format, buffer policy, or public docs were
changed.

## Validation

Passed:

```text
./script/test_audio_ring.sh
SM64 Modern audio ring smoke passed

./script/test_audio_migration.sh
audioSequenceMigrationFingerprint=0x175790b07cad64f
SM64 Modern audio sequence migration C↔Swift contract matched

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project SM64Modern.xcodeproj -scheme SM64Modern \
  -configuration Release -destination 'generic/platform=macOS' \
  -derivedDataPath /tmp/sm64-modern-phase67d-stable-release-generic \
  build CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
** BUILD SUCCEEDED **

git diff --check
```

The stable generic Release build no longer reports HUDRender, EngineRuntime,
or AppleAudioService API errors. The build is unsigned/local and does not
close M34 production, Developer ID/notary, clean-machine, or human gates.

## Remaining boundaries

M34 still needs an awake/unlocked host with zero scheduler drops, visible
post-resume capture, archive reuse, fresh `gpudebug`/pixel evidence, and
independent FPS/GPU/memory/thermal measurements. M35 still lacks Developer ID
identity/private key, notary authentication, signed/stapled artifacts,
Gatekeeper, clean-machine, and human acceptance evidence.

No commit was created by the worker; the parent owns the automatic Phase 67d
commit. No credentials, keychains, or release artifacts were changed.
