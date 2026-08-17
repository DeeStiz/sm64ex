# Handoff: SM64 Modern Full Swift Twin — M30f Manifest Codec

## What Was Done

M30f adds `SM64MarioFaceResourceManifestCodec`, the canonical transport
boundary for the M30e source/resource manifest. It writes an `MFRM` v1
little-endian byte stream containing all 25 entries, their numeric animation
metadata, and UTF-8 source-path/symbol strings. The decoder rejects invalid
magic, unsupported versions, entry counts above the catalog limit, truncated
numeric/string fields, invalid UTF-8, invalid animation types, and trailing
bytes. Payload halfwords and ROM-derived assets remain outside this codec.

## Validation

- `script/test_mario_face_resource_manifest_codec.sh` passes strict Swift 6
  and an independent C byte builder/hasher.
- Codec fingerprint: `0xaf96a492679f9e37`.
- Canonical byte length: 3149; decoded entries: 25; Swift round-trip: true.
- Focused Swift smoke rejects bad magic, truncation, and trailing data.
- `git diff --check` passes and no `@unchecked Sendable` declarations were
  added.
- `xcodegen generate --spec project.yml` and the native Debug build pass in
  `/tmp/sm64-modern-m30f-build.log`.
- `script/build_and_run.sh --verify` passes the complete focused-contract
  verifier, native Apple M5 Max Metal 4 frame-one launch, and clean status-0
  shutdown in `/tmp/sm64-modern-m30f-verify.log` (`verify_exit=0`).

## What's Deferred

- Add the codec as an actual content-pack section and validate source-only vs
  ROM-derived pack policy, section hashes, and pack reload behavior.
- Import and hash all 820/166 payload bytes, then drive complete transform
  composition from the manifest rather than the seven M30c windows.
- Resolve mesh/material/texture/lighting/orientation/camera resources and
  compare complete C schema-4 render/resource records across every face route.
- Metal validation, GPU capture/debug, screenshots, physical install, and
  visual/human acceptance remain separate gates; codec parity is not visual
  parity.

## Watch For

- Keep the byte order, string lengths, entry order, and empty-symbol encoding
  canonical. A semantically equivalent reordered manifest must fail the hash.
- The codec carries repository-relative source names only. Do not place ROM
  bytes or generated ROM-derived assets in public source artifacts.
- Do not make the manifest `Sendable` wrapper imply that payload bytes are
  resident or that Metal can consume them without an owner/resource proof.

## Next Milestone

M30g should integrate the `MFRM` bytes into a source-only content-pack fixture,
reload and compare section/resource hashes, and then add a complete payload
inventory report that can gate expression-channel composition.
