# Handoff: SM64 Modern Full Swift Twin — M30e Face Resource Manifest

## What Was Done

M30e adds `SM64MarioFaceAnimationResourceManifest`, a complete source
inventory for the 25 Mario face/intro/star animation channels. Each entry
records the Goddard component and animator IDs, checked-in source path,
primary/secondary C array symbols, exact 820/166/zero bank lengths, animation
types, and three- or six-halfword strides. The manifest is checked against the
M30b channel catalog before it can fingerprint, so an ID, type, count, or
empty-bank drift fails closed.

This is a source/resource manifest only. It does not copy the remaining bank
bytes, synthesize a content pack, mutate Goddard graph objects, or authorize
Metal rendering.

## Validation

- `script/test_mario_face_resource_manifest.sh` passes strict Swift 6 and an
  independent C manifest over all 25 entries.
- Manifest fingerprint: `0x06da7376504cc636`.
- Entry counts: 25 total, 5 empty secondary banks, 22 `GD_ANIM_3H_SCALED`,
  and 3 `GD_ANIM_6H_SCALED` primary banks.
- `git diff --check` passes and no `@unchecked Sendable` declarations were
  added.
- `xcodegen generate --spec project.yml` and the native Debug build pass in
  `/tmp/sm64-modern-m30e-build.log`.
- `script/build_and_run.sh --verify` passes the complete focused-contract
  verifier, native Apple M5 Max Metal 4 frame-one launch, and clean status-0
  shutdown in `/tmp/sm64-modern-m30e-verify.log` (`verify_exit=0`).

## What's Deferred

- Generate/import the complete 820/166 halfword payloads behind the content
  pack's source-only/ROM-derived asset boundary and freeze their hashes.
- Validate every channel's sampled/interpolated transform and compose the
  expression packet across gameplay, front-end, cutscene, ending, and LOD
  routes.
- Resolve the face mesh, material, texture, lighting, orientation, camera,
  and display-list resource IDs; compare full schema-4 render/resource
  records before Metal authority.
- Metal validation, GPU capture/debug, screenshots, physical install, and
  visual/human acceptance remain separate gates from this manifest proof.

## Watch For

- The source uses a few non-`animdata_` symbols (`anim_mario_eyebrows_3_1`)
  and singular `anim_mario_lip_6_*`; preserve exact symbols in generated
  inventory checks.
- Empty secondary entries are represented by zero count, `GD_ANIM_EMPTY`, and
  an empty symbol. They are unavailable resources, not aliases to primary
  data.
- Source paths are repository-relative and must remain safe when projected
  into a content pack. Never embed a user ROM or generated ROM asset in the
  public source tree.

## Next Milestone

M30f should add a content-pack-ready manifest serializer/reader and a complete
payload inventory report (without shipping ROM-derived bytes), then use the
manifest to drive full expression channel composition and C↔Swift resource
record comparison.
