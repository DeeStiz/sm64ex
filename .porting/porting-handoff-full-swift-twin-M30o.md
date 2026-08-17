# Handoff: SM64 Modern Full Swift Twin — M30o All-Route Mario-Face Shards

## What Was Done

M30o adds a deterministic six-route Goddard shard contract on top of the
M30n live route event. The Swift smoke builds one schema-4 render-domain event
`5` for every `SM64MarioFaceGoddardRouteID`: Yoshi scene, Yoshi shell, Mario
normal, Mario game-over, car scene, and testnet2. Each record carries the
source-copied route/update/policy/camera values, round-trips through the
canonical `SM64OracleTraceRecord` codec, and is written as an isolated schema-4
trace with route-specific configuration fingerprints.

The independent C contract replays all six records, validates the exact route
update domains (`1,1,2,2,3,3`) and policy flags (`4,0,7,7,4,0`), computes the
same aggregate fingerprint, and rejects a route-4 mutation at first
divergence `4`. The route shard script is registered in the default verifier.

## Validation

- `script/test_mario_face_route_shards.sh` passes strict Swift 6 compilation,
  C replay, fingerprint equality, and deliberate tamper detection.
- The independent Swift/C shard fingerprint is
  `0xb543d62cbccedce6` over six route records.
- `git diff --check` passes; unrelated user C/menu edits remain unstaged.
- `script/build_and_run.sh --verify` passes the corrected focused matrix and
  native Apple M5 Max Metal 4 startup/presentation in
  `/tmp/sm64-modern-m30o-verify.log` (`BUILD SUCCEEDED`,
  `metal_device_ready ... api=Metal4`, `metal_scene_presented frame=1`,
  `metal_shutdown_drained`, `engine_thread_finished status=0`, and
  `application_stopped`).

## What's Deferred

- The six records are route candidates/shards, not proof that every route has
  been entered by a real title, front-end, gameplay, cutscene, or ending
  execution. Drive the real C owner-thread entry points and compare complete
  ordered traces before promotion.
- Route metadata still does not make textures resident or prove material,
  camera, mesh, lighting, or animation parity in a Metal frame. Keep the C
  renderer as authority while the Metal 4 resource-binding slice is built.
- Metal API validation, GPU capture/debug, shader/resource validation,
  real-layer screenshots, physical-device cadence/thermal checks, and visual
  or human acceptance remain separate gates.

## Watch For

- Preserve route IDs and source policy/update tables exactly; do not infer
  route values from array position when a source display-list symbol is the
  authority.
- Keep schema-4 event `5` distinct from legacy render events `1...4` and keep
  the C hook generation-only so held display-list redraws do not duplicate
  route records.
- Do not treat the shard fingerprint or native Metal frame as visual or GPU
  evidence. The next slice must add an explicit Metal resource-binding
  contract with residency, format, sampler, and encoder ownership checks.

## Next Milestone

M30p should introduce the pointer-free Metal-facing face resource-binding
packet: map the 19 route textures and six mesh/material groups to explicit
Metal 4 texture/buffer usage, residency scope, sampler/format policy, and
encoder-owner values; compare the packet independently in C and Swift before
touching live authority. Then execute real route entry points against that
packet and keep the renderer cutover deferred until Metal validation and
visual evidence are available.
