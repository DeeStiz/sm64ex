# Handoff: SM64 Modern Full Swift Twin — M30n Live Goddard Route Oracle

## What Was Done

M30n extends the schema-4 render inventory with Mario-face route event `5`.
`sm64_modern_parity_record_mario_face_route` emits the copied route ID,
display-list ID, update domain, route policy flags, 320x240 view, and two-light
count. `geo_draw_mario_head_goddard` calls it only after a fresh
`gdm_gettestdl` generation on the legacy boundary; a held native redraw reuses
the existing display-list pointer and does not duplicate the route record.
The hook has no pointer or Metal handle in its values and remains behind the
existing active-oracle gate.

The Swift live-route smoke appends the Mario-normal route candidate from
`SM64MarioFaceRouteRenderOracle.liveCRecord` to the existing owner-context
sidecar. The C replay consumes the same schema-4 record shape, while the
oracle bridge smoke calls the new C parity API directly and validates route ID,
update domain, and policy values.

## Validation

- `script/test_live_route_oracle.sh full` passes an eight-record full replay,
  including the route event at tick 8, and its deliberate tamper still reports
  first divergence `3`.
- `script/test_live_route_oracle.sh input-only` remains a one-record trace and
  does not fabricate a face route when the route is not exercised.
- `script/test_oracle_bridge.sh` passes after extending the C inventory and
  bridge record count to 26, including render event `5`.
- `script/test_mario_face_route_resources.sh` continues to match route,
  metadata, and live-record fingerprints.
- `script/build_and_run.sh --verify` passes the focused matrix plus native
  Apple M5 Max Metal 4 frame one and clean status-0 shutdown in
  `/tmp/sm64-modern-m30n-verify.log` (`BUILD SUCCEEDED`,
  `metal_shutdown_drained`, `engine_thread_finished status=0`, and
  `application_stopped`).
- `git diff --check` passes; unrelated user C/menu edits remain unstaged.

## What's Deferred

- Drive every route ID `0...5` through a real title/intro/front-end/cutscene
  execution and compare its C event sequence to Swift, rather than the
  bounded Mario-normal replay fixture.
- Attach the route event to all texture/material/camera records and verify
  frame ordering across gameplay, Peach, credits, ending, and star shards.
- Promote no face renderer authority yet: Metal 4 texture residency, mesh
  encoding, GPU capture/debug, screenshots, physical device, and human visual
  acceptance remain open.

## Watch For

- Event `5` is a render-domain inventory item; keep the legacy event IDs 1–4
  unchanged for draw/frame-begin/frame-end/finish consumers.
- The route hook must remain generation-only. Recording on the held redraw
  path would double the C sequence and create a false parity failure.
- The seven route values are a copied ABI. Do not add pointers, `Gfx` values,
  texture addresses, or Metal objects to the trace.

## Next Milestone

M30o should execute all six Goddard routes through a route-shard manifest,
compare route/camera/texture/material/face records end-to-end, and then start
the Metal 4 face-resource residency/encoder slice only if the records match.
