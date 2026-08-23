# Full Swift Twin Handoff — Phase 85f122 Door-Contract Documentation

Date: 2026-08-23

## Verdict

**DOCUMENTATION RECONCILED / DOOR CONTRACT RECORDED / ROUTE STILL BLOCKED /
NO ADMISSION.** The first-party status surfaces now carry the Phase 85f121
source contract for the authored Castle Grounds door and preserve the final
fixed-input result. No route promotion, release, store publication, or human
acceptance was claimed.

## Source contract and fresh evidence

- The authored Castle Grounds special objects use preset `0x88`, which maps to
  `MODEL_CASTLE_CASTLE_DOOR` and `bhvDoorWarp`. The behavior sets
  `INTERACT_WARP_DOOR` and shares the common door collision contract:
  `hitbox radius=80 height=100`, with collision distance `1000`.
- `interact_warp_door` runs only when Mario is `ACT_WALKING` or
  `ACT_DECELERATING`, after the object has actually been collided. It then
  computes `should_push_or_pull_door`, stores the interaction object, and
  enters the pulling/pushing action. The warp-door interaction itself does not
  require an A-button press; contact and a valid action state are the gates.
- The authored door centers are `(-76,803,-3155)` and `(77,803,-3155)`. The
  best fixed samples from Phases 85f116–85f119 were `(-311,803,-3054)` and
  `(504,803,-3054)`, still outside the nearest 80-unit collision radius.
- The final fixed lateral variant remained `LEVEL_CASTLE_GROUNDS` (level 16),
  area 1 for all 3,600 steps and exited `77`; it produced no trace, receipt,
  C/Swift runtime pair, or route admission. No direct warp/load, helper call,
  object injection, coordinate branch, or synthetic trace was used.

## Counter and acceptance boundary

The designated report remains 26 terminal `passed` / 7,394 `planned`
(`26/7394`; `26/7420 = 0.350404313%`) with SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`.
The byte-identical write-once backup remains 25 terminal `passed` / 7,395
`planned` (`25/7395`; `25/7420 = 0.336927224%`) with SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`.
The route manifest remains SHA-256
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`; the
behavior manifest remains SHA-256
`83ed2a4dd580e462fa33f88f3fe126ae726f4a1f4139114f0de5d7d695355ccb`.
Behavior mapping remains 95.693%; M34, M35, human-acceptance,
implementation, and full-goal floors remain 0%.

M34 remains gated by `m34_host_ready=0`: the physical display is offline, the
console session is locked, GPU tooling is unavailable, and thermal state is
unknown. M35 remains gated by the absent Developer ID Application
identity/private key and supported notary authentication. No current Release,
capture/replay, pixel, cadence/soak, direct-display, archive/export,
notarization/stapling, clean-machine, or human evidence is admissible.

## Updated surfaces and next gates

Updated: `README.md`, `docs/SM64Modern.md`,
`.porting/goal-full-swift-twin.md`,
`.porting/goal-continuation-luna-max-2026-08-20.md`,
`.porting/porting-memory.md`, `CHANGES`, and this ordered handoff index.

The next traversal attempt must reach within the authored hitbox through a
source-faithful fixed-input recipe, or use explicitly authorized traversal
instrumentation. It must not steer by live coordinate feedback or bypass the
door interaction. Once Castle Inside and SSL area 1 are reached, real SSL
Pokey C/Swift Debug/ASan/Release/rerun receipts remain required before
admission. No source, report, route ledger, manifest, release, publication,
credential, or acceptance state changed.
