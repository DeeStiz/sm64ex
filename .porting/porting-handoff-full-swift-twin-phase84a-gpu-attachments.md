# Full Swift Twin Handoff — Phase 84a GPU Attachment and Reference Inspection

Date: 2026-08-21

## Scope and verdict

**COMPLETED / static GPU-trace attachment inspection.** This phase inspected
the final Phase 82f trace with noninteractive `gpudebug` and retained the
complete static command-buffer, render-pass, attachment, encoder, resource,
and representative-draw outputs under
`/tmp/sm64-modern-phase84a-gpudebug/`.

The trace structurally contains a substantial Metal 4 workload: 515 command
buffers, 515 render passes, three additional texture-upload compute encoders,
and 28,216 draw calls. Every inspected render pass has a BGRA8Unorm color
attachment and a Depth32Float depth attachment. The color attachment is
`Clear/Store` and managed; the depth attachment is `Clear/DontCare` and
memoryless. Representative draw records have `sm64_vertex` / `sm64_fragment`
pipelines, triangle work, transient vertex buffers, and sampled RGBA8Unorm
textures.

**Pixel verdict: undetermined.** `gpudebug` static navigation and `info`
worked, but the local replayer failed with an XPC interruption before any
attachment could be fetched. No color or depth PNG was produced. Draw calls,
store actions, and resource bindings do not prove that final pixels are
non-clear, so this phase makes no non-clear-pixel claim.

**Reference-parity verdict: not assessed.** There is no fetched attachment and
no paired source/reference image in the Phase 82f artifact directory. Visual
or source/reference parity, physical-display output, and human acceptance
remain open.

## Trace and tool

Trace inspected:

```text
/tmp/sm64-modern-m34-phase82f-capture-guard-r2/m34b.gputrace
```

The bundle is approximately 2.8 GiB. `gpudebug` was `/usr/bin/gpudebug`,
version 1.0, and static browsing identified the local replay device as Apple
M5 Max. No debug session remains after inspection (`gpudebug --list-sessions`
reported `No active sessions`).

## Exact static commands

The root and full command-buffer listing used:

```sh
OUT=/tmp/sm64-modern-phase84a-gpudebug
mkdir -p "$OUT"
gpudebug --oneshot -q \
  -t /tmp/sm64-modern-m34-phase82f-capture-guard-r2/m34b.gputrace \
  -o "$OUT" \
  -c 'status' -c 'go commands' -c 'list --all' \
  > "$OUT/root-commands.txt" 2>&1
```

The 515 command buffers were then navigated with absolute paths. The three
buffers containing texture-upload compute encoders use render encoder `re1`
because `ce0` precedes the render pass; all other buffers use `re0`:

```sh
{
  seq 0 514 | while IFS= read -r n; do
    case "$n" in 127|142|169) re=re1 ;; *) re=re0 ;; esac
    printf 'go /commands/cb%s/grp0/%s\n' "$n" "$re"
    printf 'info color0\n'
    printf 'info depth\n'
  done
} | gpudebug --oneshot -q \
  -t /tmp/sm64-modern-m34-phase82f-capture-guard-r2/m34b.gputrace \
  -o "$OUT" \
  > "$OUT/all-render-pass-attachments-corrected.txt" 2>&1
```

The final `cb514` automatic list was separately captured because pipe-mode
EOF can omit the final automatic list even though its two `info` results are
present:

```sh
gpudebug --oneshot -q \
  -t /tmp/sm64-modern-m34-phase82f-capture-guard-r2/m34b.gputrace \
  -c 'go /commands/cb514/grp0/re0' \
  > "$OUT/cb514-final-render-list.txt" 2>&1
```

## Static enumeration

The extracted summary is `/tmp/sm64-modern-phase84a-gpudebug/summary.txt`.
The full attachment output is
`/tmp/sm64-modern-phase84a-gpudebug/all-render-pass-attachments-corrected.txt`,
and the compact list index is
`/tmp/sm64-modern-phase84a-gpudebug/render-pass-index.txt`.

Observed counts:

| Item | Count / result |
| --- | --- |
| Command buffers | 515 (`cb0` through `cb514`) |
| Render passes | 515 (`commands/cbN/grp0/re0`, except `cb127`, `cb142`, `cb169` use `re1`) |
| Additional compute encoders | 3: `cb127` (5 blits), `cb142` (1 blit), `cb169` (6 blits) |
| Total encoders | 518, matching the trace root summary |
| Draw calls | 28,216, matching the trace root summary |
| Render attachment info pairs | 515 color + 515 depth |
| Texture catalog | 85 resources |

Render-pass dimensions, with each row counting complete render passes (color
and depth have the same dimensions):

| Dimensions | Render passes |
| --- | ---: |
| 1024x768 | 392 |
| 800x600 | 90 |
| 960x720 | 22 |
| 1280x960 | 11 |

All 515 render passes report:

```text
color0: BGRA8Unorm, Managed, RenderTarget, loadAction=Clear, storeAction=Store
depth:  Depth32Float, Memoryless, RenderTarget, loadAction=Clear, storeAction=DontCare
```

The depth `allocatedSize` is `0 bytes`, consistent with the memoryless
attachment declaration. Color attachment resources are reused across passes;
the trace resource catalog includes labels such as `CAMetalLayer Display
Drawable`, with `@tex0` through `@tex78` used by drawable/depth resources and
source-backed texture resources interleaved in the catalog.

The three compute encoders are documented in
`compute-encoder-locations.txt`, `compute-blits.txt`, and
`compute-blit-info.txt`. They stage source-backed RGBA8Unorm textures via
`copyFromBuffer:...toTexture:` before their corresponding scene render pass.

Representative static draw inspection is retained in:

```text
/tmp/sm64-modern-phase84a-gpudebug/representative-draws.txt
/tmp/sm64-modern-phase84a-gpudebug/representative-bindings.txt
```

The inspected `cb0` first draw, `cb256` middle draw, and `cb514` final draw
all expose `MTL4RenderCommandEncoder drawPrimitives:Triangle`; later draws
also expose transient buffers, sampled RGBA8Unorm textures, samplers, and the
`sm64_vertex` / `sm64_fragment` stages. These are structural facts only.

## Attachment fetch attempt and failure

The fetch attempt used both encoder attachment selectors and direct resource
references:

```sh
gpudebug --oneshot -q \
  -t /tmp/sm64-modern-m34-phase82f-capture-guard-r2/m34b.gputrace \
  -o /tmp/sm64-modern-phase84a-gpudebug \
  -c 'status' \
  -c 'go /commands/cb0/grp0/re0' \
  -c 'info color0' -c 'info depth' \
  -c 'fetch @tex0 --out /tmp/sm64-modern-phase84a-gpudebug/tex0-color.png' \
  -c 'fetch @tex1 --out /tmp/sm64-modern-phase84a-gpudebug/tex1-depth.png' \
  > /tmp/sm64-modern-phase84a-gpudebug/fetch-attempts-explicit.txt 2>&1
```

The equivalent `color0` / `depth` attachment fetch was also attempted for
`cb0` and `cb514` with outputs retained in `cb0-fetch.txt` and
`cb514-fetch-d0.txt`. All fetch attempts returned `error: replayer failed`;
the requested PNG paths do not exist. A persistent session was checked after
15 seconds and reported:

```text
Replayer:  error — failed to load trace: Encountered an XPC error: Connection interrupted
```

The default local device and explicit device ID 0 were both tried. Static
navigation remained available, so the failure does not invalidate the
structural enumeration; it only prevents resource replay/fetch and therefore
prevents a pixel-content conclusion.

## Acceptance boundary and follow-up

This phase proves:

- the retained trace is non-empty and statically parseable;
- 515 render passes and 28,216 draw calls are present;
- color/depth attachment declarations, load/store actions, dimensions, and
  resource references are captured;
- three texture-upload compute encoders and representative sampled textures are
  present.

This phase does not prove:

- non-clear color or depth pixels;
- screenshot, source/reference image parity, or visual correctness;
- direct-to-display/compositor visibility, sustained FPS/GPU/memory/thermal
  behavior, physical-device feel, or human acceptance.

Follow-up requires rerunning the same noninteractive `fetch` selectors on a
host/toolchain where the `gpudebug` replayer loads successfully, then
inspecting the fetched color/depth pixels and comparing a captured color image
against an explicitly paired source/reference artifact. Keep that result
separate from structural trace evidence.

No source, scripts, route ledgers, credentials, capture output, or external
state were modified by this phase. Parent owns review and the automatic local
commit.
