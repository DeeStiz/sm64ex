# Porting Handoff: SM64 Modern Full Swift Twin M14r

## Scope

M14r extracts `act_crawling` into `MarioCrawlingAction.swift`. The value
boundary preserves the C priority order for slide entry, first-person exit,
jump, ground dive/punch selection, unknown-input and released-Z exits, the
0.1 crawl magnitude scaling before `update_walking_speed`, the four-quarter
ground-step result, the intentional wall-clamp fall-through to floor
alignment, crawling animation ID/acceleration, and step-sound admission.

Action IDs for `ACT_STOP_CRAWLING` and `ACT_CRAWLING` are now available in the
Swift action table. Collision, animation, sound, and action transitions remain
owner-thread intents rather than pointer-backed mutations.

## Validation

- `script/test_mario_crawling.sh` — matching Swift/C fingerprint
  `0x3faba85c18461bdc`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- `check_ground_dive_or_punch` is represented by the sampled B/forward/stick
  inputs; the owner thread still applies interaction callbacks and action state.
- The crawling step sound is an intent; physical audio delivery and animation
  frame timing remain unqualified.
- Local build/test evidence does not establish physical input feel, visual
  parity, haptics, or human acceptance.

## Next slice

M14s should port held walking/heavy walking and held decelerating, then shell
ground and knockback/landing bodies can close the remaining moving-action
families before M15 airborne/submerged work.
