# Full Swift Twin Handoff — Phase 85f129 Documentation/Audit Refresh

Date: 2026-08-23
Audited checkout: `/Users/derek/Developer/sm64ex`
Source handoffs: f126 (`46c4a75d`), f127 (`56385e06`), and f128 (`1289db5f`)

## Scope and verdict

**COMPLETED / DOCUMENTATION REFRESH ONLY / NO NEW ADMISSIBLE ROW.** This
phase reconciles the first-party status surfaces with the committed Phase
85f126 canonical merge-readiness audit, Phase 85f127 M34 host recheck, and
Phase 85f128 M35 readiness recheck. The canonical audit still has 13 planned
candidate rows across 11 route families and zero newly admissible rows. The
designated report, write-once backup, route manifest, and behavior manifest
remain byte-identical at their existing hashes.

M34 remains fail-closed at `m34_host_ready=0`: the only detected display is
offline/asleep, the console session is locked, no active GPU capture/debug
session is available, and thermal telemetry is unknown. M35's guarded
readiness and distribution contracts pass, but no valid Developer ID
identity/private-key pair or supported `notarytool` authentication is present;
no fresh archive, export, signed/notarized/stapled app, DMG, ZIP, or clean-
machine artifact exists. The 95.693% behavior mapping and 0% M34, M35,
human-acceptance, implementation, and full-goal floors are unchanged.

No source, public ABI, project, report, route ledger, manifest, build product,
credential, release/store state, or unrelated dirty worktree edit was changed.
No merge, staging, commit, or push was performed.

## Canonical audit readback

The immutable canonical anchors remain:

```text
designated_report=build/sm64-modern-phase85f81-serial-publication/run.elhzBC/canonical-route-ledger.tsv
designated_rows=7420 passed=26 planned=7394
designated_sha256=4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4

backup_report=build/sm64-modern-phase85f81-serial-publication/run.elhzBC/pre-publication-backup/canonical-route-ledger.tsv
backup_rows=7420 passed=25 planned=7395
backup_sha256=aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d

route_manifest=build/sm64-route-shards-smoke/route-shards.tsv
route_manifest_rows=7420 planned=7420 passed=0
route_manifest_sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715

behavior_manifest=build/sm64-modern-behavior-manifest/behavior-manifest.tsv
behavior_manifest_rows=534
behavior_manifest_sha256=83ed2a4dd580e462fa33f88f3fe126ae726f4a1f4139114f0de5d7d695355ccb
```

The 13 candidates remain pristine `planned|0|0|0|` rows:

```text
0x0114376397887ece  bhvDonutPlatformSpawner
0x028a122a6b0f0fa2  bhvSpindrift
0x132a22db8f8e0945  bhvPokey (with 0x41715ab876625588 bhvPokeyBodyPart)
0x1af5669b06931d93  bhvTTC2DRotator
0x246e8a98cbad9a7a  bhvTreasureChestsJrb
0x28e0617bfc286cbe  bhvWhompKingBoss
0x41715ab876625588  bhvPokeyBodyPart
0x6e6c6a0fc1b92a45  bhvWdwExpressElevator
0x783b75ac5fc8435f  bhvFirePiranhaPlant
0xa98dae7d4d4559ab  bhvSLSnowmanWind
0xb280cfa26a343b48  bhvSeesawPlatform
0xd52a32f6de0311da  WDW static-platform companion
0xdc93743116807bec  bhvSpindel
```

Those IDs resolve to 11 families: WDW elevator/platform, TTC rotator, Bob
seesaw, Spindrift, Spindel, Snowman wind, JRB treasure chests, Whomp King,
Fire Piranha Plant, Donut Platform, and Pokey parent/body. The retained
evidence is either blocked reachability or static-only contract output; no
candidate has independent Debug C, Swift, ASan, Release, fresh-rerun, and
admission proof. Therefore `new_admissible_rows=0` and serial canonical merge
remains unauthorized.

## M34 and M35 boundaries

The f127 host/tool recheck remains the current M34 evidence:

```text
m34_host_ready=0
m34_display_online=0
m34_console_session_locked=Yes
m34_gpu_active_session=none
m34_thermal=unknown
```

No release launch, production harness, fresh GPU capture/replay, attachment or
reference-pixel comparison, cadence/soak, direct-display interaction, physical
visual/feel review, or human acceptance is admissible from this host state.

The f128 stable-Xcode `test_m9_release_readiness.sh` and
`test_m35_distribution_flow.sh` contracts both pass. The external M35
prerequisites remain absent:

```text
developer_id_application_identity=absent
developer_id_matching_private_key=absent
supported_notarytool_authentication=absent
fresh_archive_export_dmg_zip_artifacts=absent
clean_machine_acceptance=not_run
```

The contracts are source/readiness guards only; they do not prove a signed,
notarized, stapled, Gatekeeper-accepted, or human-reviewed artifact.

## Documentation updated

The Phase 85f129 status and ordered links were synchronized in:

- `README.md`
- `docs/SM64Modern.md`
- `.porting/goal-full-swift-twin.md`
- `.porting/goal-continuation-luna-max-2026-08-20.md`
- `.porting/porting-memory.md`
- `CHANGES`

The ordered f126 → f129 handoffs are linked from each current status surface:

```text
.porting/porting-handoff-full-swift-twin-phase85f126-canonical-merge-readiness-audit.md
.porting/porting-handoff-full-swift-twin-phase85f127-m34-host-recheck.md
.porting/porting-handoff-full-swift-twin-phase85f128-m35-readiness-recheck.md
.porting/porting-handoff-full-swift-twin-phase85f129-docs-audits.md
```

## Validation and preservation

The final validation for this refresh is limited to documentation and
repository-state checks: all newly added handoff links resolve, Markdown and
tracked diffs have no whitespace errors, the requested files are the only
tracked documentation changes, and this handoff is present as an added file.
The canonical report, backup, manifests, source, and unrelated worktree edits
remain untouched. This handoff records no commit hash because no commit was
authorized or created.
