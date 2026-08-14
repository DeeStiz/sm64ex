# Handoff: SM64 Modern Full Swift Twin — M10c Collision Data Decoder

## What Was Done

M10c adds a strict little-endian s16 collision-command decoder for the
retained COL_VERTEX_INIT, COL_TRI_INIT, COL_TRI_STOP, COL_WATER_BOX_INIT, and
COL_END stream. It validates alignment, command counts, vertex indices, and
unsupported object sections; derives C-compatible triangle normals, origin
offsets, Y bounds, no-camera/X-projection flags, stable surface identities,
force fields, and water/environment regions.

Decoded surfaces can be passed directly into the M10 surface world, preserving
the same query behavior without exposing C pointers or raw object graphs.

## Validation

- script/test_surface_collision_data.sh passed matching Swift/C derived-data
  fingerprints:
  surfaceCollisionDataFingerprint=0xfee2e0cf9c269489.
- script/test_surface_collision.sh remained green for floor, ceiling, water,
  wall, and ray behavior.
- xcodegen generate --spec project.yml and the isolated unsigned macOS Debug
  build passed with SurfaceCollisionData.swift included.
- git diff --check passed.

## Scope Boundary

The decoder currently rejects special-object loading by design, and full
16x16 partition construction/sorting, dynamic object-surface reload/reset,
all environment-box types, production collision extraction, and route-level
C-vs-Swift surface traces remain open. No GUI, physical, GPU, distribution,
or human acceptance claim is made.
