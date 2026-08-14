# Porting Handoff — Full Swift Twin M12c

## Scope completed

M12c composes the Swift collision world into Mario geometry inputs. It
preserves the two wall probes, floor-to-ceiling query buffer, dynamic floor /
ceiling selection, water and poison-gas region predicates, dynamic squish
window, off-floor/water/gas flags, and C's fallback from a missed floor to the
graphics position. The collision world now also selects dynamic ceilings and
exposes gas-region lookup.

## Validation

- `script/test_mario_geometry_input.sh`
  - Swift 6 strict-concurrency compile and geometry-input smoke test passed.
  - C contract fingerprint matched:
    `marioGeometryInputFingerprint=0x751a739ea0e06ef0`.
- Full `script/test_*.sh` matrix passed after the collision normal-sign fix,
  including the existing surface-collision fingerprint
  `surfaceCollisionFingerprint=0x2f957c379423e885`.
- `xcodegen generate --spec project.yml` completed, and the unsigned macOS
  `SM64Modern` Debug build completed with exit 0 using Xcode's current
  environment. CoreSimulator/profile warnings are environmental and do not
  constitute device or visual validation.
- `git diff --check` passed before checkpointing.

## Deliberate boundary

This is geometry-input composition, not full Mario movement. Floor-angle
classification, terrain sound, action transitions, interaction collision,
focus/demo semantics, rumble, dynamic partition-backed queries, and the
production Swift runtime path remain open.

## Next slice

Wire geometry results into the Mario input state and begin the first grounded
movement/action seam while retaining C as the differential oracle.
