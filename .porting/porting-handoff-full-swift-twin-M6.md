# Handoff: SM64 Modern Full Swift Twin — M6 Content Runtime

## What Was Done

M6 adds `SM64ContentPackIndex` and `SM64ContentPackRuntime` on top of the
existing little-endian pack codec. The index requires the complete eight-section
inventory, preserves deterministic section/path ordering, exposes validated
resource bytes, and reuses the pack's per-file, per-section, and source
fingerprints. The runtime accepts explicit immutable mappings from N64-style
`0xSSOOOOOO` addresses to content resources, validates 24-bit segment ranges,
rejects overlap and resource overrun, and provides bounded byte reads.

No raw pointer or segmented address is handed to Swift unchecked. Unknown
segments, missing files, malformed section inventories, 24-bit overflow,
overlapping mappings, and out-of-bounds reads fail with typed errors.

## Validation

- `./script/test_content_runtime.sh` built the deterministic source-only fixture,
  loaded all eight sections and 11 resources, resolved two segments, verified
  mapped byte reads, and exercised invalid-section/resource/segment/range cases.
- Existing `./script/test_content_pack.sh` passed source-only and ROM-gated
  builds, deterministic rebuild, invalid-ROM rejection, and tamper rejection.
- `xcodegen generate --spec project.yml` and the isolated unsigned Swift 6 /
  macOS 27 arm64 Debug build passed with the runtime source included.

## Ground Truth Comparison

The runtime consumes the existing C-shaped content-pack binary produced by the
same Swift writer/loader. The fixture exercises every section kind, and the
resolver preserves the retained N64 8-bit segment plus 24-bit offset contract;
it does not reinterpret addresses as host pointers.

## Scope Boundary

M6 closes pack loading and resource-address safety, not semantic decoding. M7
must decode the level-script section into typed commands, resolve area/warp
resources, and prove C-vs-Swift command traces before script execution can move
to Swift authority.

Production ROM breadth and final legal-ROM/import evidence remain gated by the
user-supplied US ROM and later full-game qualification.

## Watch For

- Keep all pack integers little-endian independent of host architecture.
- Preserve explicit segment mappings; never infer a segment from a file path or
  expose an unsafe pointer.
- Keep section/file/source hashes as hard failures, not warnings.
- Do not treat fixture coverage as production level/asset coverage.

