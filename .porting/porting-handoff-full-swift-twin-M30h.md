# Handoff: SM64 Modern Full Swift Twin — M30h Mario-Face Payload Inventory

## What Was Done

M30h adds a complete source-backed inventory boundary for the Mario-face
animation payloads. The C contract compiles the checked-in Goddard tables for
all 25 channel pairs, walks both `AnimDataInfo` banks, records count/type/
stride/byte length, hashes every resident halfword bank, and emits a stable
aggregate report. The Swift 6 parser validates the report shape against the
M30e manifest, rejects malformed rows and inconsistent lengths, and preserves
the five empty secondary banks as explicit unavailable resources.

The inventory reports 50 rows and 160668 bytes. It is an admission and
provenance contract only: the full bytes are not yet transported through the
content pack or consumed by expression composition or Metal.

## Validation

- `script/test_mario_face_payload_inventory.sh` passes the independent C
  source-table inventory and strict Swift 6 parser/manifest contract.
- Inventory aggregate fingerprint: `0x59a23daa48bcd036`.
- Inventory shape: 50 banks, 160668 bytes, five empty secondary banks;
  `GD_ANIM_3H_SCALED` banks use stride 3 and `GD_ANIM_6H_SCALED` banks use
  stride 6.
- `xcodegen generate --spec project.yml` and the native Debug build pass in
  `/tmp/sm64-modern-m30h-build.log`.
- `script/build_and_run.sh --verify` passes the complete focused-contract
  verifier, native Apple M5 Max Metal 4 frame-one launch, and clean status-0
  shutdown in `/tmp/sm64-modern-m30h-verify.log` (`verify_exit=0`).
- `git diff --check` passes; the existing unrelated C/menu edits remain
  outside this milestone's scope.

## What's Deferred

- Transport all 160668 source payload bytes through an isolated content-pack
  resource policy with canonical section hashes and reload checks.
- Decode every resident bank through the full expression compositor, including
  empty-bank fallback, all mouth/eye/eyebrow/mustache/ear/nose/hat channels,
  LODs, Peach/credits overrides, and every cutscene route.
- Resolve graph/material/texture/lighting/orientation/camera IDs and compare
  complete schema-4 C↔Swift render records before any face-renderer authority.
- Metal validation, GPU capture/debug, screenshot comparison, physical install,
  and visual/human acceptance remain separate gates.

## Watch For

- Keep inventory rows ordered exactly as the M30e manifest; a reordered or
  partially resident report must fail closed rather than silently selecting a
  fallback bank.
- Preserve source provenance and avoid treating checked-in source arrays as a
  distributable ROM-derived asset. The next pack milestone must make that
  policy explicit.
- The current M30c seven-window decoder is not evidence that all 50 banks are
  decoded or renderer-ready; retain the aggregate inventory gate while adding
  payload transport.

## Next Milestone

M30i should transport the complete inventory/payload bytes through an isolated
  content-pack section, reload and hash every bank, and expose a resource
  provider that the expression compositor can query without C pointers.
