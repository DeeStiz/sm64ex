# Porting Handoff — Full Swift Twin M11

## Scope completed

M11 adds `SM64ObjectScheduler`, an owner-thread scheduler over the existing
Swift object pool and engine state. It preserves the C 13-list values and
update order, processes objects appended during the active list update, keeps
deactivated nodes in-list until the ordered unload pass, mirrors the terrain
object-counter replacement, sets and clears the animation graph bit around
updates, and applies the Mario/door/unimportant/initiated time-stop allowlist.
The logical-boundary time-stop latch is explicit so held native steps cannot
toggle it twice.

## Validation

- `script/test_object_scheduler.sh`
  - Swift 6 strict-concurrency compile and scheduler smoke test passed.
  - C contract fingerprint matched:
    `objectSchedulerFingerprint=0x651b22478aea0a42`.
- `xcodegen generate --spec project.yml` completed and included
  `ObjectScheduler.swift`.
- Unsigned macOS Debug build with Xcode completed successfully after project
  regeneration. CoreSimulator and provisioning-profile warnings are
  environment diagnostics, not build failures.
- `git diff --check` passed before checkpointing.

## Deliberate boundary

The scheduler callback is intentionally a narrow owner-thread mutation seam.
Mario/object transform propagation, behavior-driven callback breadth, respawn
metadata writes, dynamic surface reload integration, object collision passes,
and production-level differential traces remain open. A scheduler fingerprint
does not claim whole-game gameplay, rendering, or physical-device acceptance.

## Next slice

Continue M11 with object transform/parent propagation and behavior-scheduler
coverage, then connect dynamic object surfaces to the M10 partition/query
boundary before beginning M12 input normalization.
