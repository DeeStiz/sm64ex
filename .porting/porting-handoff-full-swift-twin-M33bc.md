# SM64 Modern Full Swift Twin — M33bc Handoff

Date: 2026-08-17

## Completed slice

M33bc creates `TTCPitBlockBehavior` and migrates `bhvTTCPitBlock` through
`TTCPitBlockObjectBridge`, dispatch route 57. Swift owns the TTC speed/wait
tables, wait-versus-move timer boundary, endpoint clamp and direction flip.
The owner bridge owns the authored collision/model byte, copied home/peak
state, level-list position/velocity/transform mutation, and the explicit
random wait used by the random TTC setting.

## Validation

- New `script/test_ttc_pit_block.sh` Swift/C contract passes with fingerprint
  `0xc3d7d5eca91d331a`.
- `script/test_behavior_dispatch_bridge.sh` exercises route 57, endpoint
  clamping, direction reversal, wait-table selection, and record mutation
  while preserving the existing dispatch fingerprint.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x6407c55ada6af8ff`, 534 rows, 99 Swift value/owner routes, and 435 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, route-shard inventory/ledger/replay,
  live route promotion, progression replay, timebase audit, strict regenerated
  Swift 6 Xcode Debug build, Metal 4 source contract, shell syntax, and
  `git diff --check` pass.

## Open evidence

435 reachable C adapters remain, and the 7,419-shard execution ledger is still
planned rather than fully executed. Native runtime promotion and Metal
validation/capture remain blocked by the host-wide LaunchServices `-10827`
boundary before `NSApplication`/engine startup. Physical visual, thermal,
device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining non-kernel platform behavior queue, preserving one
independent Swift/C contract and one owner-thread route per slice, then execute
the complete schema-4 shard ledger once runtime authority can launch on a
healthy AppKit host.
