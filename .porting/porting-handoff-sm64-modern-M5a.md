# Handoff: M5a Apple Input

## What Was Done

Implemented and validated native macOS input while preserving the existing SM64 controller contracts and portable backends. A versioned fixed-width input snapshot and capability cross the public C ABI; the `CAPI_NONE` adapter maps that snapshot into the existing persisted keyboard, mouse-button, and SDL-style controller bindings. `AppleInputService` captures AppKit events and the current GameController through immutable state snapshots, drains a depth-20 physical-input queue each 30 Hz engine tick, retains short press edges for one tick, clears held and pending state on focus loss, and publishes bounded startup/activity telemetry. The input bridge installs before the capability is advertised and uninstalls during owner-thread shutdown. Physical Xbox acceptance covered movement, A/jump, right-stick camera rotation, and menu input. The validated implementation checkpoint is commit `33c4db2`.

## Ground Truth Comparison

M5a is a non-rendering input milestone, and discovery contains no checked-in controller trace or deterministic input reference artifact. No GPTK, RenderDoc, or GPU ground truth comparison was applicable. Validation instead established the following compatibility evidence:

- The native virtual-key namespace and button indices were compared in source with the existing SDL controller backends and persisted configuration bindings.
- Right-stick left/right/up/down signs match both SDL backends' legacy C-button/Lakitu translation exactly; the user's inverted-camera impression is therefore a control-ergonomics caveat, not a native sign regression.
- A fresh live Metal scene capture confirmed that enabling the input capability did not regress window presentation, textures, geometry, depth, or HUD output. This was a visual regression check, not rendering ground truth.
- Signed runtime telemetry and user testing confirmed real AppKit keyboard/mouse-button activity, recovered short Xbox button edges, analog movement, jump, camera, and menu control.

## What's Deferred

- `rg -n "STUB\\(M5b\\)" SM64Modern src include` — install the real-time-safe AVAudioEngine adapter and publish audio capability only after it is complete.
- `rg -n "STUB\\(M6\\)" SM64Modern src include` — define deterministic gameplay snapshot/effect schemas and record streams for parity comparison.
- `rg -n "STUB\\(M8\\)" SM64Modern src include` — replace legacy 30 Hz pacing with the audited fixed 1/60-second full-world clock.
- Relative mouse-look remains out of scope while `BETTERCAMERA=0`; controller rumble and multi-controller/player assignment were not added.

## Known Issues

- The current right-stick camera direction feels inverted to the user, but its signs match the legacy SDL C-button mapping. Treat a reversal as an explicit camera-control product change, not an input-port bug fix.
- Physical acceptance used an Xbox Wireless Controller. Other controller models, subjective latency, and broad control-feel acceptance remain unproven.
- Apple ASan leak detection is unavailable. Full Swift+C ASan found no memory error, normal `leaks` reported 0 leaks/0 bytes, and bounded Metal HUD/RSS evidence was stable; this is not long-duration performance acceptance.
- Linux, Windows, and web full product builds remain future regression gates. M5a passed the legacy macOS build and x86_64/i686 MinGW syntax checks.
- Developer ID Application signing/notarization and sustained-execution Release provisioning remain external release prerequisites.

## Watch For

- Preserve `GCController.current` as the single active-controller policy unless multiplayer/product requirements explicitly change. Do not start wireless discovery, enable background monitoring, or assign player indices implicitly.
- Configure `inputStateQueueDepth = 20` only when a controller connects. Reconfiguring it on every current-controller notification can discard queued edges.
- Drain immutable queued states once per engine tick, OR recovered buttons into the live semantic state, and keep current analog values from `capture()`. Do not replace this with unsynchronized mutable handler state.
- Focus loss must clear held keyboard/mouse/controller state and pending one-tick presses so controls cannot stick or replay after refocus.
- Preserve the SDL-compatible virtual-key bases, controller indices, trigger indices 26/27, and full signed axis range. The native path deliberately adds no second deadzone over GameController's normalized values.
- Keep the input-service object alive in `EngineHost` while the public table holds its unretained context, and install/uninstall the bridge on the engine owner thread before publishing/removing input capability.
- M5b audio callbacks must remain real-time safe: no blocking, allocation, logging, AppKit access, or engine-state mutation from the render thread. Make ring-buffer ownership, format conversion, underrun silence, and teardown order explicit.

## Key Decisions Made

- M5 was split into M5a input and M5b audio so real controller acceptance and real-time audio design remain separately bounded and reviewable.
- Swift receives and emits only versioned POD state. It never retains or traverses the legacy gameplay object graph.
- Native input preserves existing configuration semantics instead of creating a second bindings system: AppKit hardware positions map to the persisted Windows Set 1 scancode namespace, and GameController semantic controls map to SDL-compatible virtual keys.
- Buffered controller states and one-tick AppKit press latches recover press/release pairs that occur between 30 Hz engine reads while preserving live held and analog state.
- Input capability is initialization truth: it is advertised only after the service and complete callback table install successfully, and a callback/status failure stops the lifecycle instead of silently dropping input.

## Skills Needed Next

- `porting-methodology`
- `porting-start-milestone`
- `build-macos-apps:build-run-debug`
- `build-macos-apps:telemetry`
- Use Apple's AVAudioEngine documentation and the existing 32 kHz stereo PCM contract for M5b; no dedicated game-porting audio skill is currently available.
