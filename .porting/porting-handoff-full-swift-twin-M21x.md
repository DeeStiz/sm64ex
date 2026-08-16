# SM64 Modern Full Swift Twin — M21x Handoff

## Scope

M21x ports the shared `bhvExplosion` consumer from
`src/game/behaviors/explosion.inc.c` into strict Swift 6 value code and an
owner-thread object bridge. The C object graph does not cross the boundary.

The value kernel preserves:

- `SOUND_GENERAL2_BOBOMB_EXPLOSION` and `SHAKE_ENV_EXPLOSION` initialization;
- `INTERACT_DAMAGE`, damage value 2, and the 150/150/150 destructive hitbox;
- opacity 255 initialization, 14-point fade, scale `timer / 9 + 1`, and
  animation-state cadence;
- timer-nine routing to 40 water bubbles or one ground-smoke child;
- timer-nine deactivation through the owner-thread deletion sink.

The bridge allocates generation-safe destructive-list records, publishes the
source hitbox/interaction/visual fields, presents sound and camera-shake
intents through `SM64OwnerThreadEffectRouter`, and removes stale records at
the scheduler boundary. Bubble and smoke are retained as typed child requests
until their shared behaviors are migrated.

## Evidence

- Focused contract: `script/test_explosion.sh`
- Swift/C fingerprint: `0x29e3dc6674824f4a`
- Full matrix: `/tmp/sm64-modern-m21x-final-matrix.log`,
  `MATRIX_RESULT runs=200 failures=0`
- Native build: `/tmp/sm64-modern-m21x-build.log`, `BUILD SUCCEEDED`
- Regenerated project: `SM64Modern.xcodeproj/project.pbxproj`
- Static checks: `git diff --check`; zero `@unchecked Sendable` declarations
  in `SM64Modern`

These checks establish source/value/owner and build correctness only. They do
not establish Bowser request wiring, complete bubble/smoke behavior parity,
whole-engine parity, collision-mesh authority, real camera/audio/rendering,
physical-device behavior, visual/feel acceptance, or release acceptance.

## Next bounded scope

1. Route `SM64BowserBombObjectBridge`'s explicit generic-explosion request into
   `SM64ExplosionObjectBridge` through one owner-thread coordinator and prove
   parent-generation and child-retirement behavior.
2. Migrate the shared bubble and ground-smoke consumers, retaining source
   models, child transforms, lifetimes, and effect ordering.
3. Begin M22 with a fail-closed behavior manifest that maps every reachable C
   behavior identity to a Swift implementation or an explicit, reported
   unmigrated adapter; counts alone are not coverage evidence.

No branch, worktree, push, or release artifact was created.
