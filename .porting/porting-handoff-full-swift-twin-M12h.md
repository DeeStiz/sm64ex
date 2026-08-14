# Porting Handoff — Full Swift Twin M12h

## Scope completed

M12h routes Swift floor, ceiling, and wall collision queries through the
C-ordered 16x16 static/dynamic partition. Candidate IDs are resolved through
indexed surface storage, dynamic surface replacement rebuilds the partition
and rejects duplicate identities, and the existing exact surface arrays remain
the source of truth for geometric tests.

The affected standalone Swift scripts now include the partition source in
their strict-concurrency compile lists, so collision-data and Mario geometry
fixtures exercise the same partition-backed world rather than an unreferenced
storage-only implementation.

## Validation

- `script/test_surface_partition.sh` passed with
  `surfacePartitionFingerprint=0x48925440f517858c`.
- `script/test_surface_collision.sh` passed with
  `surfaceCollisionFingerprint=0x2f957c379423e885`.
- `script/test_surface_collision_data.sh` passed with
  `surfaceCollisionDataFingerprint=0xfee2e0cf9c269489`.
- `script/test_mario_geometry_input.sh` passed with
  `marioGeometryInputFingerprint=0x9f27a8a5f078483a`.
- `script/test_mario_input_frame.sh` passed with
  `marioInputFrameFingerprint=0xd2e21ed90c513c44`.
- The complete `script/test_*.sh` matrix passed after the partition-backed
  query integration.
- `git diff --check` passed before handoff.

## Deliberate boundary

This is local collision-query and dynamic-reload parity, not full production
level breadth or live runtime authority. Ray traversal remains a separate
production query slice, and Swift-mode `SM64ModernSwiftEngineRuntime` still
delegates lifecycle stepping to the C adapter until the gameplay domains are
wired into the owner-thread runtime. Physical haptics and visual/device review
remain external acceptance gates.

## Next slice

Keep the composed input boundary owner-thread-only by introducing the first
Swift gameplay tick coordinator, with paired simulation/legacy counters, demo
state, and rumble scheduling covered by an independent C fingerprint.
