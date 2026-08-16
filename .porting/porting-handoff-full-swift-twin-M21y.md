# SM64 Modern Full Swift Twin — M21y Handoff

## Scope

M21y closes the Bowser Mario-hit request seam left explicit by M21w. An
opt-in `SM64BowserBombObjectBridge` route now allocates the shared
`SM64ExplosionKernel` behavior in the same owner-thread scheduler. The child
uses the source `MODEL_EXPLOSION`/`bhvExplosion` identity, keeps the Bowser
bomb's generation-safe parent ID, receives the shared sound/camera-shake
presentation, and is retired through the same deletion/unload boundary. The
existing mine-hit flame and Bowser-smoke route remains unchanged.

The default bridge initializer keeps request-only behavior for compatibility;
callers must set `routesGenericExplosionRequests: true` to enable the new
consumer while it is being qualified.

## Evidence

- Focused integration contract: `script/test_bowser_explosion_integration.sh`
- Swift/C fingerprint: `0x09ea3ea3033a8de3`
- Existing bomb regression: `script/test_bowser_bomb.sh`, fingerprint
  `0x1570ecd9d93c5b41`
- Full matrix: `/tmp/sm64-modern-m21y-final-matrix.log`,
  `MATRIX_RESULT runs=201 failures=0`
- Native build: `/tmp/sm64-modern-m21y-build.log`, `BUILD SUCCEEDED`
- Static checks: `git diff --check`; zero `@unchecked Sendable` declarations
  in `SM64Modern`

These checks establish the bounded value/owner integration only. They do not
establish bubble/smoke behavior parity, full Bowser controller/arena
authority, production collision mesh coverage, durable reward/warp mutation,
real camera/audio/rendering consumers, whole-engine parity, device behavior,
visual/feel acceptance, or release acceptance.

## Next bounded scope

1. Migrate the shared timer-nine water-bubble and ground-smoke consumers and
   route the generic explosion child requests to generation-safe children with
   source models/transforms/lifetimes.
2. Expand the Bowser controller/arena value and owner routes, including
   collision authority, camera/cutscene sequencing, music, reward persistence,
   and warp transitions.
3. Begin M22 with a fail-closed behavior manifest that maps every reachable C
   behavior identity to a Swift implementation or an explicit reported
   unmigrated adapter; inventory counts alone do not close coverage.

No branch, worktree, push, or release artifact was created.
