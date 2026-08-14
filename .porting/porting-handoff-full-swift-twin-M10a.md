# Handoff: SM64 Modern Full Swift Twin — M10a Surface Query Foundation

## What Was Done

M10a adds a Swift 6 value-type surface model and collision world for the
legacy floor, ceiling, and environmental-water query contracts. Surface
triangles retain fixed-width vertices, normals, origin offsets, type/flags,
room, and stable IDs. Queries preserve C's integer-coordinate casts,
triangle-side tests, 78-unit floor/ceiling buffers, camera-boundary filtering,
no-camera flags, dynamic-over-static floor selection, level bounds, and
first-matching water-region semantics.

The world rejects duplicate surface identities and malformed water regions
before query execution. Misses use the retained -11000.0f sentinel and
surface metadata is returned as an immutable hit record for schema-4 collision
traces.

## Validation

- script/test_surface_collision.sh passed the Swift/C query contract with
  surfaceCollisionFingerprint=0xaa42785c5660bb5f.
- xcodegen generate --spec project.yml and the isolated unsigned macOS Debug
  build passed with SurfaceCollision.swift included.
- git diff --check passed.

## Scope Boundary

M10a is the query foundation, not complete collision migration. Wall
projection/push and wall lists, surface-data decoding and spatial
partitioning, dynamic surface lifecycle, ray intersections, poison gas,
production collision extraction, and route-level C-vs-Swift collision traces
remain open. No GUI, physical, GPU, distribution, or human acceptance claim
is made.
