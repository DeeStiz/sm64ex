# Handoff: SM64 Modern Full Swift Twin — M30i Mario-Face Payload Bundle

## What Was Done

M30i transports the complete Mario-face animation payload inventory through a
canonical `MFPB` v1 resource. The C contract walks all 25 checked-in Goddard
channel pairs and writes both `AnimDataInfo` banks, including the five explicit
empty secondary banks, as little-endian metadata plus raw signed halfwords.
Swift decodes and validates the exact manifest order, component/bank metadata,
animation type, stride, count, and value count, then exposes immutable bank,
frame, and adjacent-frame interpolation lookup. The bundle is generated into
`source_manifest/mario_face_payloads.mfpb`, built into a source-only content
pack, reloaded through `SM64ContentPackIndex`, and byte/fingerprint compared.

This closes full payload transport and lookup, not the expression compositor or
renderer: no Metal resource is mutated and no visual parity is claimed.

## Validation

- `script/test_mario_face_payload_bundle.sh` passes the independent C writer,
  source-only pack build/verify, Swift 6 decoder/resource lookup, and C↔Swift
  byte/fingerprint comparison.
- Bundle fingerprint: `0x45714415b47a9d29`.
- Bundle shape: 50 banks, 161880 canonical bytes, 160668 raw payload bytes;
  empty secondary banks remain unavailable rather than synthesized.
- Swift malformed-byte smoke fences bad magic, truncated data, trailing bytes,
  invalid bank count, and invalid animation metadata.
- `xcodegen generate --spec project.yml` and native Debug build pass in
  `/tmp/sm64-modern-m30i-build.log`.
- `script/build_and_run.sh --verify` passes the complete focused-contract
  verifier, native Apple M5 Max Metal 4 frame-one launch, and clean status-0
  shutdown in `/tmp/sm64-modern-m30i-verify.log` (`verify_exit=0`).
- `git diff --check` passes; unrelated user C/menu edits remain unstaged.

## What's Deferred

- Compose every mouth, eye, eyelid, eyebrow, mustache, ear, nose, hat, intro,
  and star channel from the resident bundle with source-order precedence,
  empty-bank fallback, LOD selection, and all cutscene overrides.
- Resolve face graph-node, mesh, material, texture, lighting, orientation, and
  camera resources and compare complete schema-4 C↔Swift render records over
  reachable face routes.
- Wire the composed packet to the Metal owner thread, then run Metal validation,
  GPU capture/debug, screenshot comparison, physical install, and
  visual/human acceptance as separate gates.

## Watch For

- `MFPB` row order is part of the canonical contract; do not sort by path or
  omit empty banks when adding resource caching.
- Source-only pack provenance is intentional. Do not convert this fixture into
  a distributable ROM-derived asset without an explicit legal/asset policy.
- The resource provider fails closed on missing adjacent frames. The compositor
  must preserve that behavior and report unavailable channels rather than
  fabricating zero transforms.

## Next Milestone

M30j should build the full resident expression compositor: select all 25
channels, apply source-order transforms and empty-bank policy, combine the
Peach/credits overrides with the resident bundle, and emit a deterministic
resource/transform packet suitable for later graph and Metal comparison.
