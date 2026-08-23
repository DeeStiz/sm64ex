# Full Swift Twin Handoff — Phase 85f125 Contact-Vector Documentation

Date: 2026-08-23

## Verdict

**DOCUMENTATION RECONCILED / CONTACT VECTOR BLOCKED / NO ADMISSION.** The
first-party status surfaces now carry the Phase 85f123 live distance
diagnostic and the Phase 85f124 fixed contact-vector result. The route remains
blocked at the authored Castle Grounds door; no route promotion, release,
store publication, or human acceptance was claimed.

## Fresh diagnostic and fixed-vector evidence

- The owner-thread diagnostic observes only live authored `bhvDoorWarp`
  objects, nearest squared distance, and Mario's copied interaction flags. It
  does not steer, branch on coordinates, invoke helpers, inject objects, or
  create traces.
- At the best fixed approach it observed:

  ```text
  door_warps=3
  nearest_door_distance_sq=64969.9  # approximately 255 units
  collided=0
  ```

  The authored door hitbox radius is 80, so this sample is outside contact.
- Phase 85f124 applied a fixed vector derived from the measured door center
  after the `(-310,803,-3054)` approach. The run still ended in
  `LEVEL_CASTLE_GROUNDS` (level 16) area 1 after all 3,600 steps and exited
  `77`. It produced no trace, native receipt, C/Swift runtime pair, route
  admission, or canonical mutation.
- No coordinate feedback was used to branch, and no direct level load/warp,
  helper call, object injection, synthetic trace, or canonical mutation
  occurred.

The source-faithful physical-input search stops for this evidence pass. Any
next attempt requires either a newly justified source-faithful fixed-input
recipe entering the authored 80-unit contact radius or explicit authorization
for traversal instrumentation or another traversal mechanism. The
source-recipe/authorization gate is explicit. After contact, real SSL Pokey
C/Swift Debug/ASan/Release/rerun parity receipts remain mandatory before route
admission or canonical merge.

## Counter and acceptance boundary

The designated local canonical report remains 7,420 rows with 26 terminal
`passed` and 7,394 `planned` (`26/7394`; `26/7420 = 0.350404313%`) at SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`.
The byte-identical write-once backup remains 25 terminal `passed` and 7,395
`planned` (`25/7395`; `25/7420 = 0.336927224%`) at SHA-256
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

Ordered evidence: [Phase 85f123 Castle-door distance diagnostic](porting-handoff-full-swift-twin-phase85f123-castle-door-distance-diagnostic.md),
[Phase 85f124 Castle-door contact vector](porting-handoff-full-swift-twin-phase85f124-castle-door-contact-vector.md), and this Phase 85f125 documentation/contact-vector handoff.

No source, report, route ledger, manifest, release, store, credential,
publication, or acceptance state changed.
