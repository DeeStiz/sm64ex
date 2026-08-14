# Porting Handoff — Full Swift Twin M12d

## Scope completed

M12d extends the geometry-input boundary with the floor-derived values used by
the C `update_mario_geometry_inputs` path: normal components are retained in
the query result, floor angle uses the canonical US `atan2s` table, surface
types map to the C slipperiness classes, terrain sound addends follow the
seven-terrain/six-floor-class matrix, and `INPUT_ABOVE_SLIDE` is derived from
the water-height and slipperiness thresholds. The prior wall, floor/ceiling,
water/gas, dynamic-squish, and graphics-position fallback behavior remains
unchanged.

## Validation

- `script/test_mario_geometry_input.sh`
  - Swift 6 strict-concurrency compile and expanded geometry-input smoke passed.
  - C contract fingerprint matched:
    `marioGeometryInputFingerprint=0x9f27a8a5f078483a`.
- Existing `script/test_surface_collision.sh` and
  `script/test_mario_input_core.sh` passed after the query-result shape change.
- Full `script/test_*.sh` matrix passed after the query-result shape change.
- `xcodegen generate --spec project.yml` completed, and the unsigned macOS
  `SM64Modern` Debug build completed with exit 0 using Xcode's current
  environment. CoreSimulator/profile warnings are environmental and do not
  constitute device or visual validation.

## Deliberate boundary

This is still input/geometry derivation, not the full Mario action system. The
remaining M12 work is focus/demo semantics, camera input, rumble trace
integration, dynamic partition-backed production queries, and wiring these
values into the live Swift engine runtime.

## Next slice

Add a value-type input-frame composition boundary that combines normalized
controller state, Mario button/joystick state, geometry state, and owner-thread
focus/demo/rumble admissions without mutating the C controller graph.
