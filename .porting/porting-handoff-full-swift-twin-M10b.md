# Handoff: SM64 Modern Full Swift Twin — M10b Wall and Ray Collision

## What Was Done

M10b extends the M10a surface world with C-matching wall collision and ray
intersection behavior. Wall queries clamp the legacy maximum radius, preserve
dynamic-then-static list ownership, per-list base coordinates, lower/upper-Y
rejection, plane-distance checks, X-projection and Z-projection triangle
tests, camera/vanish-cap filtering, accumulated push, and the first-four
surface identities while retaining the total collision count.

Ray queries normalize the input direction, preserve finite ray length and
vertical bounds, reject invalid/parallel/out-of-triangle hits, and select the
nearest accepted surface with canonical hit position and distance.

## Validation

- script/test_surface_collision.sh passed matching Swift/C wall, floor,
  ceiling, water, and ray fingerprints:
  surfaceCollisionFingerprint=0x2f957c379423e885.
- xcodegen generate --spec project.yml and the isolated unsigned macOS Debug
  build passed with the expanded SurfaceCollision.swift source.
- git diff --check passed.

## Scope Boundary

Surface binary decoding, spatial partition construction/sorting, dynamic
surface lifecycle, poison-gas and full environment boxes, moving-platform
updates, production collision extraction, and route-level C-vs-Swift
qualification remain open. No GUI, physical, GPU, distribution, or human
acceptance claim is made.
