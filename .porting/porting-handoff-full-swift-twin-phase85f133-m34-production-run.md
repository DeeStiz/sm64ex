# Full Swift Twin Handoff — Phase 85f133 M34 Production Run

Date: 2026-08-24 (EDT)

## Scope and verdict

**COMPLETED / production attempt blocked fail-closed.** The read-only M34 host
gate passed, but the unchanged M34 production harness stopped in its mandatory
Release-build preflight when the timebase audit detected source/fixture drift.
No Release bundle was produced by this run, so no app profile, GPU capture,
GPU replay, attachment fetch, pixel comparison, cadence measurement, or
sustained thermal measurement is admissible. No claim of visual, performance,
physical-device, or human acceptance follows.

The harness and all repository source/report/ledger/manifest files were left
unchanged. This handoff is the only repository artifact created by this run;
no commit, push, release, store, credential, display, power, or signing-state
operation was performed.

## Repository snapshot and concurrent HEAD movement

The task requested the fresh audit base `65f0cc87` (`origin/nightly` remains
`65f0cc87ee953ce90368449b90328d7beaa013f6`). Initial inspection observed that
HEAD. Before the harness reached its build preflight, a concurrent parent-side
docs commit moved the shared checkout to `0bbf5f558fae40fcf25a9c4f0fc62acd45acc507`
at `2026-08-24T08:21:19-04:00`. The run therefore executed from `0bbf5f55`;
the delta from `65f0cc87` is docs-only (`.porting/porting-handoff-full-swift-twin-phase85f131-candidate-route-contracts.md`),
and the harness scripts plus timebase fixture used here are byte-identical at
both commits. No reset or checkout was used.

After the attempt:

```text
HEAD=0bbf5f558fae40fcf25a9c4f0fc62acd45acc507
origin/nightly=65f0cc87ee953ce90368449b90328d7beaa013f6
worktree_status_count=0
```

## Host and tool gate

The unchanged host gate was run before the production attempt and again after
the failure. Both returned exit `0`:

```sh
bash script/test_m34_host_readiness.sh
```

The post-run result was:

```text
m34_host_os=27.0
m34_host_metal_tool=/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/metal
m34_host_gpucapture=/usr/bin/gpucapture
m34_host_gpudebug=/usr/bin/gpudebug
m34_host_display_count=2 online=2 asleep=0
m34_host_console_locked=No session_locked=unknown user_active=unknown
m34_host_thermal=No thermal warning level has been recorded
m34_host_ready=1
```

Read-only tool state showed `gpucapture 2027.0.39`, `gpudebug 1.0`, local
device `Mac17,6 / macOS 27.0`, no capturable process before launch, and no
active gpudebug sessions. The absence of a capturable process was expected
because the harness had not produced/launched its runtime bundle.

## Exact production command and result

Fresh output directory:

```text
/private/tmp/sm64-modern-m34-phase85f133.XNrHCL
```

The unchanged production command was:

```sh
M34_OUTPUT_DIR="$(mktemp -d /private/tmp/sm64-modern-m34-phase85f133.XXXXXX)"
SM64_MODERN_M34_OUTPUT_DIR="$M34_OUTPUT_DIR" \
SM64_MODERN_M34_PROFILE_TICKS=600 \
SM64_MODERN_M34_PROFILE_WARMUP_TICKS=60 \
bash script/test_metal4_production.sh
```

The actual directory selected was the path above. The harness printed
`M34 output: /private/tmp/sm64-modern-m34-phase85f133.XNrHCL` and returned
exit `1` from `m9_release.sh build` before `xcodegen`, `xcodebuild`, signing,
launch, or capture. Its mandatory audit reported:

```text
object_timer       166 files: fixture 715, current 734
random_calls        79 files: fixture 289, current 290
Time-dependent gameplay inventory changed; classify the drift before updating the fixture.
```

The retained `release-build.log` contains the two preceding green smoke
checks (`SM64 Modern audio ring smoke passed` and `SM64 Modern fixed-step
scheduler smoke passed`) followed by that audit failure. No `local-runtime/`
bundle, `validation.log`, `capture.log`, `gpucapture-boundaries.txt`,
`gpucapture-start.txt`, `m34b.gputrace`, or `gpudebug.txt` was created.

The GPU-capture workflow was verified against the installed man page and the
unchanged harness: the target must be launched with
`MTL_CAPTURE_ENABLED=1` (and this harness also uses
`MTLCAPTURE_WAIT_FOR_SIGNAL=1`), then `gpucapture boundaries --pid "$PID"`
must expose `Device`, followed by `gpucapture start --pid "$PID" --until-exit
--output "$TRACE_PATH"`. Because the Release preflight failed, there was no
target PID and those commands were not admissibly invoked; no synthetic or
historical trace was substituted.

## Additional read-only checks

These checks ran after the blocked harness, without changing repository
files:

```text
script/test_metal4_contract.sh                 exit=0
script/test_metal4_capture_archive_guard.sh    exit=0
script/test_m9_release_readiness.sh            exit=0
bash -n production scripts                     exit=0
git -c core.fsmonitor=false diff --check      exit=0
script/test_timebase_audit.sh                  exit=1 (same fixture drift)
```

`pmset -g therm` reported no recorded thermal, performance, or CPU-power
warning; `pmset -g batt` reported AC power with the internal battery at 80%.
These are host warning/power observations only, not sustained GPU/CPU thermal
telemetry or a performance/thermal pass.

## Evidence matrix

| Evidence domain | Result | Boundary |
|---|---|---|
| Host readiness | **PASS** | Two online/awake displays, macOS 27.0, Metal tool, gpucapture, gpudebug; exit 0 before/after. |
| Source/API contracts | **PASS** | Metal 4 contract and capture-archive guard passed; static evidence only. |
| Release readiness contract | **PASS** | Readiness contract passed; no distribution action was attempted. |
| Release build | **BLOCKED** | `m9_release.sh build` stopped at timebase audit before Xcode generation/build. |
| Release validation profile | **NOT RUN** | No runtime bundle or app process existed. |
| `gpucapture boundaries/start` | **NOT ADMISSIBLE** | No target PID after the preflight failure; no capture was attempted. |
| `.gputrace` production artifact | **ABSENT** | No fresh trace path exists in the output directory. |
| `gpudebug` replay | **NOT ADMISSIBLE** | No fresh trace; session list remained empty. |
| Color/depth attachment fetch | **NOT MEASURED** | No replay session or attachment resources. |
| Pixel/reference comparison | **NOT MEASURED** | No current PNG or declared-size source/reference comparison. |
| Cadence/profile | **NOT RUN** | No `m9_profile_complete`, callbacks, presented-frame, scheduler, or audio runtime records. |
| Thermal | **UNKNOWN / NOT ACCEPTANCE** | `pmset` recorded no warnings and AC power, but no sustained telemetry or soak. |
| Physical visual/feel | **NOT RUN** | No physical runtime observation. |
| Human acceptance | **NOT RUN** | No human review or distribution artifact. |
| Repository immutability | **PASS** | Worktree status count remained zero; no source/report/ledger/manifest mutation. |

## Artifact inventory and hashes

All local run artifacts are under
`/private/tmp/sm64-modern-m34-phase85f133.XNrHCL`:

```text
6e3c6228b4ce6875c05e43a11b8f3fd28888972a32a14a4e05bd8c19b1ba0b68  capture-archive-guard.log
59cc175aa8a0bb6e8bf4b590a4124e78b254889ba9f04a3c67e6c17e40bd855a  gpu-tool-state.log
c04578ce6758755fa61084d96e087d5a3651ce4d0652488bd29fe7332b454392  host-readiness-post.log
897db0f1cb88ba963a5854166dafb831a9ed8135da0e3c17b5572349764f6f20  metal4-contract.log
350e375c060c2fe509072575f141e826ad4150f3eafa76c12a523c80d8789b2  release-build.log
3f457f3ab7e6e9560546d087d437d63ea2e1cd306cc373014a4645cf149e4a48  release-readiness.log
235954ccbee3bb21a289b29a3acd5bcb0d51f6c07694d2337c8841e05f6388ad  static-safety.log
38bcdc5e4adf3969cf1416b6a3fea79bc4e2e7a9264244f88785777d5d4424a6  thermal-telemetry.log
8cb74cadb0a8e3db20ac4cfdc7c3972fdc4cef382a362dbacd0290ccb945a0fe  timebase-audit.log
```

Harness/input hashes at the run snapshot:

```text
0cdf8083e6741268fb7080f134ba29f93bf706b2e7811445dbc804bc42c4b4d6  script/test_m34_host_readiness.sh
869a56780d9fae2f2603e2c4e901e50d60a7f7c2028da1966ad88f3424cb6d1d  script/test_metal4_production.sh
8de9ecc04cc54d9e6e9ec8cca10518ddfad920c5edaac1cf7ad80d74ba2a8945  script/m9_release.sh
ec97ec4f9dcbd4a9fd3366c56708daaf82857059f4b7f49aa427b551491df7e3  script/test_timebase_audit.sh
b6869708bca3f3dc6b27754fc12d44ee427d2d7296a8f08013d0b9a35f15c4b2  tests/fixtures/sm64_modern_timebase_audit.tsv
```

## Next executable gate

1. Preserve this blocked result and classify the source/fixture timebase drift
   (`object_timer` +19 and `random_calls` +1). Any fixture/source decision is
   outside this run and requires its own authorization; no fixture was edited.
2. From a stable target checkout, rerun `bash
   script/test_m34_host_readiness.sh`; only if it returns `m34_host_ready=1`,
   rerun the unchanged 600-step/60-step-warmup command above into another
   fresh directory.
3. After the harness itself passes, use the produced `.gputrace` with
   noninteractive `gpudebug` replay to fetch the color/depth attachments and
   compare declared-size pixels against an explicit source/reference artifact.
   Then collect the separately declared sustained cadence, GPU/RSS, thermal,
   direct-display, physical visual/feel, and human-review evidence. None of
   those gates can be promoted from this run.

Parent owns review and any later commit. This worker did not commit, push,
publish, modify credentials, wake/unlock displays, change power policy, or
delete the temporary evidence directory.
