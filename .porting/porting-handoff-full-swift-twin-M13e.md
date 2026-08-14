# Porting Handoff — Full Swift Twin M13e

## Scope completed

M13e adds the value counterpart of `set_mario_action` for common moving,
airborne, submerged, and cutscene transition entries. It preserves action
group rewrites (including squish/quicksand jump fallback and downhill slide
selection), C direct-versus-derived velocity writes, peak-height/unknown-flag
updates, action timer resets, sound-flag clearing, and prior-action capture.
Drop and hurt wrappers expose held/ridden-object drop and hurt-counter intents
without reaching through the C object graph.

## Validation

- `script/test_mario_action.sh` passed under Swift 6 strict concurrency with
  `marioActionFingerprint=0xf572a2fdb6852162` matching the independent C
  contract.
- The focused action smoke covers walking, slide selection, double-jump,
  dive-derived velocity, quicksand fallback, metal-water jump, cutscene
  forward velocity, drop wrappers, and hurt counters.
- `git diff --check` passed before handoff.

## Deliberate boundary

This is action-entry state, not action-body execution. Stationary/moving/air/
submerged/automatic action loops, animation callbacks, collision response,
object interactions, hitboxes, audio, and runtime authority remain open.

## Next slice

Port the common stationary and moving action body kernels with explicit input,
terrain, animation, and effect intents, starting from idle/walking/crouching
and their grounded transitions.
