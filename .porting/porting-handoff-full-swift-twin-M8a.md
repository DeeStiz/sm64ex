# Handoff: SM64 Modern Full Swift Twin — M8 Geo Layout and Scene Graph Foundation

## What Was Done

M8a adds a Swift 6 macOS-64-bit geo-layout decoder and value-type scene-graph
builder. Command lengths follow the retained `CMD_SIZE_SHIFT` physical-word
rules, including optional function/display-list payloads and all geo opcodes
through culling-radius. Scalar reads preserve C's logical-to-physical mapping.

The builder mirrors `register_scene_graph_node`: `OPEN_NODE` changes the graph
depth, node creation replaces the current depth slot and attaches to the
parent slot, `CLOSE_NODE` restores the parent slot, flags update in place, view
registrations are deterministic, and branch/return control flow is bounded.
Typed payloads cover roots, orthographic/perspective/camera nodes, transforms,
translation/rotation/animated/billboard/display-list nodes, scale, shadow,
background/generated/held nodes, object parents, LOD/switch metadata, and
culling radius. Function and display-list values remain opaque validated data;
they are not called or dereferenced.

## Validation

- `./script/test_geo_layout.sh` passed the nested root/perspective/camera graph,
  transforms, display-list and scale payloads, shadow payload, flags, view
  registration, command trace count, and malformed-length parser boundary.
- Swift/C command and scene fingerprints matched:
  `geoCommandFingerprint=0x94f8d23d90108c10`,
  `geoSceneFingerprint=0xe1212453fc095c49`.
- `xcodegen generate --spec project.yml` and the isolated unsigned macOS Debug
  build passed with `GeoLayout.swift` included.
- `git diff --check` passed.

## Scope Boundary

This closes the decoder/graph foundation, not rendering. Production geo
resource extraction, segmented target mapping, matrix traversal/negative
coordinate parity, animated callbacks, object-parent rebinding, and immutable
Metal scene-packet translation remain later M8/M29 work. GUI, physical, GPU,
distribution, and human acceptance are not claimed.
