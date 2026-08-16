# SM64 Modern Full Swift Twin — M21z Handoff

## Scope

M21z migrates the shared explosion child consumers from
`corkbox.inc.c`/`bhv_dust_smoke_loop` into strict Swift 6 value kernels and
the owner-thread explosion bridge.

The bridge now creates source-model/behavior children for both timer-nine
branches:

- 40 `MODEL_WHITE_PARTICLE_SMALL` bubble children with explicit placement,
  expansion-rate, initial-timer, and velocity inputs;
- one `MODEL_SMOKE` ground-smoke child with the source Y offset of -300 and
  one-frame behavior delay.

Bubble scale-factor sine cadence, upward movement, water-level splash request,
timer-61/deletion fence, and the dust-smoke movement/smokeTimer-10 deletion
fence are value-owned. Child IDs remain generation-safe and are retired by the
same scheduler/deletion sink. The water-splash consumer itself is still a
typed request; Bowser's separate generic route still needs to share this child
factory rather than duplicate typed requests.

## Evidence

- Focused child contract: `script/test_explosion_children.sh`
- Swift/C fingerprint: `0x03fdfa6ee829478b`
- Regression contracts: `script/test_explosion.sh`,
  `script/test_bowser_bomb.sh`, and
  `script/test_bowser_explosion_integration.sh`
- Full matrix: `/tmp/sm64-modern-m21z-final-matrix.log`,
  `MATRIX_RESULT runs=202 failures=0`
- Native build: `/tmp/sm64-modern-m21z-build.log`, `BUILD SUCCEEDED`
- Static checks: `git diff --check`; zero `@unchecked Sendable` declarations
  in `SM64Modern`

These checks establish the shared child value/owner boundary only. They do not
establish the water-splash behavior, Bowser child-route unification, complete
Bowser controller/arena authority, production collision mesh coverage,
durable reward/warp mutation, real camera/audio/rendering consumers,
whole-engine parity, device behavior, visual/feel acceptance, or release
acceptance.

## Next bounded scope

1. Extract one shared child factory/coordinator and route Bowser's generic
   explosion path through the same bubble/smoke owner implementation, proving
   parent-generation and child-order parity in both callers.
2. Migrate the water-splash consumer and its source presentation/effect
   request, keeping any remaining renderer/audio owner explicit.
3. Begin M22 with a fail-closed behavior manifest mapping every reachable C
   behavior identity to a Swift implementation or an explicit reported
   unmigrated adapter.

No branch, worktree, push, or release artifact was created.
