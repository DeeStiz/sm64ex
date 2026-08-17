# Full Swift Twin M31h Handoff

## Scope

M31h makes the remaining Swift/C authority boundary executable. It is an
authority-audit and fail-closed construction seam, not a claim that the
unmigrated gameplay/content, save, camera, audio, frontend, or rendering
domains are already Swift implementations.

## Implementation

- Added `SM64ModernSwiftEngineDomainOwner` and
  `SM64ModernSwiftEngineAuthorityLedger`, a value-semantic partition over all
  engine domains.
- The ledger maps every domain to either `.swift` or the explicitly named
  `.cCompatibilityBridge`, rejects omissions, exposes stable sorted domain
  lists, and reports unassigned domains.
- `SM64ModernSwiftEngineRuntime` validates that the ledger exactly matches the
  Swift context readiness at construction. This prevents a new domain from
  being silently routed through the compatibility adapter without updating the
  authority contract.
- Swift runtime telemetry now emits the partitioned Swift-owned and C-bridge
  domain lists while retaining the intentionally honest
  `swift_lifecycle_owner_c_domain_bridge` implementation marker.

## Validation evidence

- `script/test_engine_runtime.sh` passes with Swift 6 and complete strict
  concurrency diagnostics. The smoke asserts partition closure, zero
  unassigned domains, Swift ownership of state, and C-bridge ownership of save
  persistence plus the remaining five domains.
- `script/test_metal4_contract.sh` and `script/test_metal_scene_packet.sh`
  remain green after the M34b changes.
- Regenerated native Swift 6/macOS 27 arm64 Debug build succeeds; log:
  `/tmp/sm64-modern-m31h-build.log`.
- The complete gated native verifier passes with `verify_exit=0`; log:
  `/tmp/sm64-modern-m31h-full-verify-2.log`. It reaches the Apple M5 Max
  Metal 4 device, presents frames, drains audio/Metal, and exits status 0.
- `git diff --check` passes before commit.

## Evidence boundary

The ledger is a guardrail and an auditable declaration. It does not remove the
C lifecycle/content callback, implement the remaining domains, or prove
Swift-vs-C gameplay parity. Physical controller/audio/display behavior,
visual output, distribution, and human acceptance remain separate gates.

## Next slice

Use the ledger to promote the next complete value-only production domain behind
the Swift runtime, with a live C schema-4 oracle record and an exact route
replay. Do not widen the Swift-owned set until its C/Swift trace and native
integration evidence pass.
