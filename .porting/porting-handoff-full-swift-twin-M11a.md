# Porting Handoff — Full Swift Twin M11a

## Scope completed

M11a adds the Swift 6 column-major object transform boundary used by
`mtxf_rotate_zxy_and_translate`, `mtxf_mul`, `obj_apply_scale_to_transform`,
and parent-relative object updates. It preserves canonical table-backed trig,
translation slots, scale-by-column behavior, owner-thread stable-ID parent
lookup, and `oGraphYOffset` graphics-position updates. The scheduler exposes
the transform pass separately so future behavior callbacks can place it at the
same point as C `cur_obj_update` without hiding ordering decisions.

## Validation

- `script/test_object_transform.sh`
  - Swift 6 strict-concurrency compile and parent-transform smoke test passed.
  - C contract fingerprint matched:
    `objectTransformFingerprint=0x23ef6a18fb179c4c`.
  - C fixture uses `-ffp-contract=off` to retain the non-fused float operation
    order used by the deterministic oracle.
- `git diff --check` passed before checkpointing.

## Deliberate boundary

This closes matrix math and parent-relative field propagation only. It does
not claim full behavior flag coverage, animation matrices, throw matrices,
platform displacement, camera transforms, render-packet parity, or production
level differential closure.

## Next slice

Wire the transform pass into behavior-command execution and add object surface
reload/removal ownership before moving to input normalization (M12).
