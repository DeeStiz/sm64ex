# Full Swift Twin Handoff — Phase 84c Documentation Reconciliation

Date: 2026-08-21

## Scope and result

**COMPLETED / documentation-only reconciliation.** This phase reconciles the
latest M34 and M35 evidence across the public README, SM64 Modern status page,
the two goal ledgers, `CHANGES`, and `porting-memory.md`. It does not change
source, scripts, behavior manifests, route ledgers, credentials, host state,
capture artifacts, or distribution artifacts.

The frozen implementation counters remain **534 behavior rows** (**511 Swift
value/owner rows**, **23 explicit C adapters**) and **7,420 route shards**
(**1 non-fixture live-qualified**, **7,419 planned**). The mapping indicator is
95.693%; the live-route indicator is 0.013477%. These are separate counters,
not a Full Swift Twin completion percentage. The conservative full-goal and
acceptance floors remain **0%** because unqualified routes and independent
system/device/release/human gates remain open.

## Evidence reconciled

The documentation now links and records the following bounded phases:

- [Phase 81 M34 ready-host capture](porting-handoff-full-swift-twin-phase81-m34-ready-host-capture.md): the host gate was ready, but the unchanged validation profile failed closed at 72 scheduler drops before capture.
- [Phase 82a M34 scheduler cadence](porting-handoff-full-swift-twin-phase82a-scheduler-cadence.md): the owner-thread pipeline wait was removed; the separate validation pass reached zero scheduler drops and the capture pass produced a trace subject to capture overhead.
- [Phase 82b M34 reproducibility audit](porting-handoff-full-swift-twin-phase82b-m34-repro-audit.md): stable-Xcode validation/capture and noninteractive `gpudebug` structural evidence passed, with capture overhead kept separate.
- [Phase 82c M35 distribution readiness](porting-handoff-full-swift-twin-phase82c-m35-distribution-readiness.md): readiness remains blocked by the missing Developer ID Application identity/private key and notary authentication; no distribution mutation occurred.
- [Phase 82d Metal 4 archive reuse](porting-handoff-full-swift-twin-phase82d-archive-reuse.md): ordinary validation can load/reuse the binary archive; capture-specific interaction remained a separate failure.
- [Phase 82e M34 capture recovery](porting-handoff-full-swift-twin-phase82e-capture-recovery.md): archive-reuse validation passed, while the capture tool failed before producing a trace.
- [Phase 82f capture archive bypass](porting-handoff-full-swift-twin-phase82f-capture-archive-bypass.md): the unchanged two-pass harness passed with validation archive reuse, capture-profile archive bypass, a non-empty `.gputrace`, and noninteractive `gpudebug` structural inspection.
- [Phase 84a GPU attachment inspection](porting-handoff-full-swift-twin-phase84a-gpu-attachments.md): static replay enumerated 515 render passes and 28,216 draws, but attachment replay failed with an XPC interruption; no PNG or non-clear-pixel verdict exists.
- [Phase 84b sustained performance/thermal attempt](porting-handoff-full-swift-twin-phase84b-performance-thermal.md): two bounded 3,600-step profiles reached zero scheduler/audio drops and approximately 59.9 Hz, while the separate Instruments trace exposed only bounded encoder/allocation samples and a nominal thermal interval.

## Final gate matrix

| Gate family | Current evidence | Decision | Remaining requirement |
| --- | --- | --- | --- |
| Behavior ownership | 534 rows; 511 Swift owners; 23 explicit C adapters | Partial implementation evidence only | Close every reachable authority path and permitted compatibility leaf with independent runtime proof |
| Live route qualification | 7,420 shards; 1 live-qualified; 7,419 planned; Phase 76 found 0 newly admissible composite candidates; Mario-state owner/parity remains blocked | Open | Repair native owner/parity, independently record C and Swift, and admit exact schema-4 pairs only |
| M34 validation | Phase 82f validation profile loads/reuses the binary archive, reaches 600 steps with zero scheduler drops, and shuts down status 0 | Passed structural/runtime sub-gate | Keep separate from visual and sustained physical acceptance |
| M34 capture and GPU inspection | Phase 82f produced a non-empty trace and `gpudebug` structural inspection; Phase 84a enumerated 515 render passes/28,216 draws, but attachment fetch hit an XPC replayer interruption | Structural evidence only | Fetch color/depth attachments on a functioning replayer and compare non-clear pixels to an explicit source/reference artifact |
| M34 cadence/performance/thermal | Phase 84b produced two bounded 3,600-step zero-drop runs at about 59.94/59.96 Hz, bounded RSS, and a separate nominal thermal interval | Bounded evidence only | Run the declared longer soak and obtain complete GPU/FPS/memory/thermal/direct-display evidence; no 10/30-minute soak is claimed |
| Physical visual/feel | Host was awake/unlocked during recent runs, but compositor evidence remains insufficient | Open | Human/device inspection of visual parity, controls, camera, collision, audio, haptics, and feel |
| M35 signing/notarization | Readiness contracts pass locally | Blocked | Authorized Developer ID Application identity/private key and supported `notarytool` authentication |
| M35 distribution/clean machine | No signed archive/export, stapled app/DMG/ZIP, or clean-machine result | Not run | Produce and inspect signed/stapled artifacts, then verify Gatekeeper/import/save/relaunch on a clean machine |
| Human acceptance | No fresh-save 120-star record | Not run | Complete and record the full human checklist after signed artifacts pass clean-machine checks |

## Evidence boundaries

The M34 validation/capture/gpudebug results prove source-backed Metal 4
runtime and structural trace facts only. Static draw counts, attachment
declarations, store actions, shader names, and resource bindings do not prove
non-clear final pixels, screenshot/reference parity, physical display output,
or human acceptance. The 3,600-step profiles do not prove a 10-minute or
30-minute soak, GPU utilization, GPU watts, sensor temperature, direct-to-
display behavior, physical feel, or thermal closure. Local Release builds and
ad-hoc bundles do not prove Developer ID signing, notarization, stapling,
Gatekeeper, clean-machine, or distribution acceptance.

## Validation performed

The documentation-only change was checked with:

```text
./script/test_behavior_manifest.sh
./script/test_route_shards.sh
bash -n script/test_metal4_production.sh script/test_m34_host_readiness.sh \
  script/test_route_shard_admission_triage.sh script/m9_release.sh \
  script/test_m35_distribution_flow.sh
git diff --check
```

The ten new Phase 81/82a–82f/84a–84c handoff targets were checked for
existence and references from README, docs, and both goal ledgers. Parent
review and the automatic local Phase 84c commit remain the next step; this
worker did not commit or push.
