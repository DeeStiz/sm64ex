# Handoff: SM64 Modern Full Swift Twin — M29d File-Backed Render Comparison

## What Was Done

M29d adds a fixed, pointer-free `SM64RenderPacketFile` sidecar for the latest
closed Swift render frame and a schema-4 comparator that selects the latest
complete C domain-11/render-packet frame, projects the Swift packet into the
same records, and fails closed on missing, extra, reordered, mutated, or
non-canonical data. The packet path and oracle trace path are opt-in launch
environment values; the default Metal 4 renderer and C compatibility route
remain unchanged.

## Validation

- `script/test_render_file_comparison.sh` passes an independent C-generated
  schema-4 trace file containing two complete frames and finish records
  against a Swift-generated latest-frame sidecar at
  `renderFileCompareRecords=3` and fingerprint `0xde2543519ff3c23f`.
- `script/test_render_file_comparison_live.sh` launches the built Apple M5 Max
  product with a one-tick C oracle record session and gated Swift packet
  capture. It compares the live files at fingerprint `0xb295758c3331d40`,
  with `renderLiveTraceBytes=5448` and `renderLivePacketBytes=248`.
- The live run reports `oracle_trace_started mode=1 schema=4`, Swift packet
  sequence 1 with three events, `bounded_oracle_trace_run_complete steps=1`,
  `oracle_trace_finished status=0`, `engine_thread_finished status=0 steps=1`,
  and `application_stopped`; evidence is
  `/tmp/sm64-modern-m29d-live-verify.log`.
- The regenerated native Debug build passes in
  `/tmp/sm64-modern-m29d-build.log`; the default full verifier (including the
  new focused contract) passes in `/tmp/sm64-modern-m29d-verify.log`.
- `git diff --check` passes and `SM64Modern` still has zero
  `@unchecked Sendable` declarations.

## What's Deferred

- Expand file-backed comparison beyond the first bounded frame to title,
  menus, gameplay, pause, transitions, credits, ending, and all reachable
  content/behavior shards, including finish records and resource IDs.
- Resolve ROM/content-pack textures, samplers, display-list words, combine and
  geometry state, matrices, lights, fog, and render-layer order before Metal
  encoding; the current sidecar compares the live C render oracle values, not
  full resource payloads.
- Promote the compared packet into Metal 4 authority only after texture
  residency, explicit synchronization, shader validation, GPU capture/debug,
  screenshot comparison, sustained performance, and human visual/feel review.

## Watch For

- The sidecar is the latest closed frame, while C trace records retain their
  simulation tick and domain sequence. Never compare a candidate packet to a
  different frame or silently discard extra render records.
- Keep vertex hashing inside the owner callback; no borrowed pointer may enter
  the sidecar or any `Sendable` value.
- A one-tick live match proves the file boundary only. It does not prove whole-
  game visual, GPU, audio, controller, physical-device, or human parity.

## Next Milestone

M30a should port the product-reachable Goddard/Mario-face value and render
packet boundary (eye/mouth/cap/skin/material/lighting/animation), then run it
through front-end, gameplay, cutscene, and ending trace shards before any
face-renderer authority cutover.
