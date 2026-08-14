# Handoff: SM64 Modern Full Swift Twin — M8 Segmented Geo Resource Integration

## What Was Done

M8b connects geo-layout resources to the M6 segmented content runtime. Geo
commands now enumerate their opaque pointer fields, and
`SM64ContentPackRuntime` loads a geometry resource and derives an immutable
target map. Branch targets and callback/display-list values are resolved only
when they are valid 24-bit segmented addresses into the requested resource and
land on a decoded command boundary. Unknown segments, cross-resource targets,
and non-command targets fail closed.

## Validation

- `./script/test_geo_layout_content.sh` built an eight-section source-only pack
  in memory, mapped a geometry resource into segment `0x01`, resolved the
  branch target `0x01000010`, and built the Swift root scene through the
  segmented branch.
- `./script/test_geo_layout.sh` retained matching command/scene fingerprints.
- `xcodegen generate --spec project.yml` and the isolated unsigned macOS Debug
  build passed with `GeoLayoutContentRuntime.swift` included.
- `git diff --check` passed.

## Scope Boundary

The available fixture is production-shaped but not a compiled US ROM geo
resource. Full geo resource extraction, all callback-bearing layouts, matrix
traversal/negative-coordinate parity, object-parent rebinding, animation
updates, and Metal scene-packet translation remain open. No GUI, physical, GPU,
distribution, or human acceptance claim is made.
