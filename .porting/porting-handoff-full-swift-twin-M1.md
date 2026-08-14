# Handoff: Full Swift Twin M1 Dual-Engine Lifecycle

## What Was Done

M1 establishes the permanent runtime authority boundary. `SM64ModernEngineRuntime` now owns initialize, step, stop, and shutdown; `SM64ModernCEngineRuntimeAdapter` forwards the existing C lifecycle on the owner thread; and `SM64ModernSwiftEngineRuntime` is the Swift authority shell that delegates to the C fallback until the domain migrations replace it. `EngineHost` selects one immutable runtime at startup and no longer calls the lifecycle directly from its scheduler path.

The app resolves `SM64_MODERN_ENGINE` first, then the persisted Advanced setting, then Swift by default. The Advanced menu persists Swift or C Compatibility and clearly requires restart. Invalid environment overrides fail closed. Invalid persisted values recover to Swift and are rewritten. The C object graph and existing platform/Metal/audio bridges are unchanged.

## Validation Evidence

- `./script/test_engine_authority.sh` — passed, including precedence and invalid-value cases.
- `./script/test_engine_runtime.sh` — passed, including C callback forwarding and Swift-shell delegation.
- `./script/test_audio_ring.sh` — passed.
- `./script/test_fixed_step_scheduler.sh` — passed with an isolated module cache.
- `./script/test_timebase_audit.sh` — passed after the intentional `initializeCEngineOnEngineThread` audit-anchor rename.
- `xcodegen generate --spec project.yml` — passed and includes both new Swift files.
- Isolated Swift 6/macOS 27 arm64 Debug `xcodebuild` — passed with no Swift compiler diagnostics.
- `git diff --check` — passed.

## Runtime Evidence Boundary

The managed session has no usable development signing identity and LaunchServices cannot launch the Xcode 27 Debug-dylib app from this shell (`kLSNoExecutableErr`); direct headless launch aborts inside AppKit application registration. The build and protocol evidence therefore prove code integration, not GUI, visual, audio, physical-device, or human acceptance. The canonical runner now falls back to clearly non-distributable ad hoc signing when no development identity exists, while Developer ID and notarization remain M35 gates.

## Deferred Work

- `SM64ModernSwiftEngineRuntime` contains the explicit `STUB(M31)` lifecycle fallback; no gameplay or C callback has been silently claimed as Swift authority.
- M2 must define and generate the deterministic US content pack before executable Swift gameplay migration begins.
- Full C-vs-Swift differential traces, Metal captures, normal gameplay, physical input/audio, distribution, clean-machine, and fresh-save 120-star acceptance remain open.

## Next Milestone

M2 implements the legal-ROM importer and deterministic, hashed content-pack format for scripts, geometry, behaviors, display lists, text, audio tables, and ROM-derived assets.
