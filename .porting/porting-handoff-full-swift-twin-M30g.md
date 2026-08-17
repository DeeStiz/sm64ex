# Handoff: SM64 Modern Full Swift Twin — M30g Content-Pack Manifest

## What Was Done

M30g integrates the M30f `MFRM` manifest into an actual source-only content
pack fixture. The test generates `source_manifest/mario_face_manifest.mfrm`
from the Swift codec, builds a `.cpk` with the existing content-pack tool,
reloads it through `SM64ContentPackIndex`, reads the exact source-manifest
resource, decodes it, and compares bytes/entries/fingerprint. The classifier
now treats repository-relative `source_manifest/` resources as the
`sourceManifest` section. No ROM-derived payload bytes are committed.

## Validation

- `script/test_mario_face_content_pack.sh` passes source-only pack build and
  verify, resource lookup, codec decode, and byte/fingerprint equality.
- Manifest fingerprint: `0xaf96a492679f9e37`.
- Manifest bytes: 3149; resource path:
  `source_manifest/mario_face_manifest.mfrm`; source-only flag is preserved.
- `git diff --check` passes and no `@unchecked Sendable` declarations were
  added.
- `xcodegen generate --spec project.yml` and the native Debug build pass in
  `/tmp/sm64-modern-m30g-build.log`.
- `script/build_and_run.sh --verify` passes the complete focused-contract
  verifier, native Apple M5 Max Metal 4 frame-one launch, and clean status-0
  shutdown in `/tmp/sm64-modern-m30g-verify.log` (`verify_exit=0`).

## What's Deferred

- Add all 820/166 halfword bytes to the content pack under its source-only vs
  ROM-derived policy, freeze per-resource hashes, and compare reloads from
  isolated pack roots.
- Drive complete face expression composition from the manifest and payloads,
  including missing-channel/empty-bank behavior and every LOD/cutscene route.
- Resolve face mesh/material/texture/lighting/orientation/camera/display-list
  resource IDs and compare complete schema-4 C↔Swift render records before
  Metal authority.
- Metal validation, GPU capture/debug, screenshots, physical installation,
  and visual/human acceptance remain separate gates.

## Watch For

- The source-only fixture proves manifest transport and section classification,
  not that a runtime has every face payload or a legal ROM-derived asset.
- Keep `source_manifest/` paths safe and canonical; content-pack ordering and
  section hashes must remain deterministic across isolated roots.
- Do not turn successful pack reload into a visual/render claim. Resource
  residency, Metal encoding, and human acceptance still need direct evidence.

## Next Milestone

M30h should add a complete payload inventory report (counts, byte lengths,
source symbols, and per-bank hashes) against the content-pack manifest, then
use that report to drive full expression channel composition and route-shard
resource parity.
