# Full Swift Twin Handoff — Phase 67c HUD Render Type-Check Fix

Date: 2026-08-21

## Scope and verdict

**HUDRender fix complete; full stable Release build remains open.** The
stable-Xcode-only type-check failure in `SM64Modern/HUDRender.swift:31` and
`:39` was reduced by splitting each edge expression into explicitly typed
`Double` intermediates. The original arithmetic order, `floor`/`ceil`
behavior, render output, and C↔Swift contract are unchanged. No ABI, HUD
semantics, public documentation, or focused test contract was changed.

## Source change

`SM64HUDLayout.leftEdge(_:)` and `rightEdge(_:)` now explicitly bind:

- half screen width and height as `Double` values;
- the aspect-scaled horizontal extent as `Double`;
- the integer offset converted to `Double`;
- the final `Double` value before applying `floor` or `ceil` and converting to
  `Int32`.

This is a type-checking refactor only. The operation ordering remains
`halfWidth ± (halfHeight * aspectRatio) ∓ offset`.

## Validation

Focused render contract:

```text
./script/test_hud_render.sh
hudRenderFingerprint=0xc086889d07474862
SM64 Modern HUD render smoke passed
hudRenderFingerprint=0xc086889d07474862
SM64 Modern HUD render C contract passed
SM64 Modern HUD render C↔Swift contract matched
```

Focused HUD projection contract:

```text
./script/test_hud.sh
hudFingerprint=0x1d0a1956d7a8121e
SM64 Modern HUD smoke passed
hudFingerprint=0x1d0a1956d7a8121e
SM64 Modern HUD C contract passed
SM64 Modern HUD C↔Swift contract matched
```

Formatting validation passed:

```text
git diff --check
```

## Stable Release build

Stable toolchain:

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -version
Xcode 26.6
Build version 17F113
```

The isolated generic-host invocation was:

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project SM64Modern.xcodeproj -scheme SM64Modern \
  -configuration Release -destination 'generic/platform=macOS' \
  -derivedDataPath /tmp/sm64-modern-phase67c-stable-release-generic build \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
```

It reached compilation and exited `65`. The only compiler errors in the
captured log
(`/tmp/sm64-modern-phase67c-stable-release-generic/build.log`) are the
existing stable-SDK Objective-C AVAudio API errors:

```text
SM64Modern/AppleAudioService.m:77:9: error: no visible @interface for 'AVAudioSourceNode' declares the selector 'initWithFormat:realtimeSafeRenderBlock:'
SM64Modern/AppleAudioService.m:246:19: error: no visible @interface for 'AVAudioEngine' declares the selector 'connect:to:format:error:'
** BUILD FAILED **
```

The log contains no `HUDRender.swift` type-check diagnostic and no “unable to
type-check this expression in reasonable time” diagnostic. A first invocation
without an explicit generic destination selected the connected passcode-locked
Mac and was interrupted after repeated remote-service failures; that was a
destination-selection issue, not a source result. The generic invocation is
the authoritative stable compile attempt for this phase.

## Remaining risk and follow-up

The HUD type-check blocker is resolved and both focused C↔Swift fingerprints
remain unchanged. The stable full-app Release build is still blocked by the
pre-existing `AppleAudioService.m` AVFAudio declarations above. A separate
parent-owned build/audio phase must address or explicitly document that
toolchain/API blocker before stable Xcode 26.6 can serve as a full Release
build gate. This handoff does not claim M34 production, M35 distribution,
notarization, or human acceptance.

