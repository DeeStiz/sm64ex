# Porting Handoff: SM64 Modern Full Swift Twin M16b

## Scope

M16b adds the immutable camera selection and mode-transition boundary in
`CameraModeState.swift`.

- Mario/Lakitu angle switching preserves the active-angle bits, zoomed-out
  save/restore, and activation sound intents.
- Alternate Mario/fixed selection preserves selection bits, fixed-mode return,
  selection sound intents, and the fixed-selection Lakitu reset.
- Camera mode transitions preserve previous-mode resolution, movement restrict
  and rotate flag clearing, transition-out-of-C-Up admission, frame counts, and
  the C-ordered scalar reset set.
- HUD status derives fixed/Mario/Lakitu plus C-down/C-up bits without mutating
  owner-thread camera state.

## Validation

- `script/test_camera_mode_state.sh` — matching Swift/C fingerprint
  `0x80ec629967e739dc`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Camera geometry, surface/wall collision ownership, mode callback geometry,
  cutscene timers, shake/FOV mutation, audio/HUD delivery, and render mutation
  remain explicit owner-thread effects.
- Local build/test evidence does not establish physical input feel, visual
  parity, or human acceptance.

## Next slice

M16c should port camera collision ownership and radial/behind-Mario/C-up mode
geometry using immutable surface snapshots, then add shake/FOV and cutscene
state before closing negative-coordinate whole-mode differential coverage.
