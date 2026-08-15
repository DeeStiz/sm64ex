# M19k Handoff — TTC treadmill behavior seam

## Scope

M19k extracts TTC treadmill initialization and the master-treadmill update
path. It does not claim the global TTC RNG/master owner, object ownership,
dynamic collision replacement, surface reload, or remaining mechanism and
hazard families.

## Implementation

- `SM64Modern/TTCTreadmillBehavior.swift` preserves collision-model selection,
  speed-surface initialization, master-election gating, random target-speed
  approach, shared surface speed, and the C `0.084f` forward-velocity
  conversion as Swift 6 value state.
- `tests/sm64_modern_ttc_treadmill_contract.c` independently mirrors the C
  update and hashes float bits plus election/sound intents.
- `script/test_ttc_treadmill.sh` compiles Swift with complete strict
  concurrency and the C oracle with `-ffp-contract=off`, then requires
  matching fingerprints.

## Validation

- Focused Swift/C contract: `ttcTreadmillFingerprint=0xd19867880b32d14f`.
- Full `script/test_*.sh` matrix target after this script is included:
  `runs=148 failures=0`.
- Regenerated native Swift 6/macOS 27 Debug build and `git diff --check` pass.

## Remaining gate

M19 remains open for global TTC RNG/master ownership, platform
collision/surface reload, remaining mechanisms and environmental hazards, and
effect delivery. M20–M35 remain open.
