---
name: drawio-skill
version: 1.14.0
description: "Use for diagrams: flowcharts, architecture, ER, UML/sequence/class, network topology, ML/DL figures (Transformer/CNN/LSTM), mind maps. Also proactively when explaining systems with 3+ components or complex data flows. Best for custom styling, swimlanes, or exportable images (PNG/SVG/PDF/JPG). Generates .drawio XML, exports via the native draw.io desktop CLI."
license: MIT
homepage: https://github.com/Agents365-ai/drawio-skill
compatibility: Requires draw.io desktop app CLI on PATH (macOS/Linux/Windows). Self-check needs a vision-enabled model (e.g. Claude Sonnet/Opus); skipped if unavailable. Optional auto-layout (scripts/autolayout.py) needs Graphviz (dot).
platforms: [macos, linux, windows]
metadata: {"openclaw":{"requires":{"anyBins":["draw.io","drawio"]},"emoji":"📐","os":["darwin","linux","win32"],"install":[{"id":"brew-drawio","kind":"brew","formula":"drawio","bins":["drawio"],"label":"Install draw.io via Homebrew","os":["darwin"]},{"id":"brew-graphviz","kind":"brew","formula":"graphviz","bins":["dot"],"label":"Install Graphviz for optional autolayout.py","os":["darwin"],"optional":true}]},"hermes":{"tags":["drawio","diagram","flowchart","architecture","visualization","uml"],"category":"design","requires_tools":["drawio","draw.io"],"related_skills":["mermaid","excalidraw","plantuml"]},"author":"Agents365-ai","version":"1.14.0"}
---

# Draw.io Diagrams

Generate `.drawio` XML, export to PNG/SVG/PDF/JPG locally via the native draw.io desktop CLI (no browser automation). PNG/SVG/PDF support `--embed-diagram` (`-e`): embeds full XML so opening the file in draw.io recovers the editable diagram — use double extension (`name.drawio.png`) to signal that.

**Use for:** polished precise diagrams (architecture, network, strict UML, ERD), solid opaque fills, 10,000+ stock/branded shapes, swimlanes, custom geometry, editable PNG/SVG/PDF. **Route elsewhere:** hand-drawn/whiteboard → excalidraw/tldraw; diagrams-as-code in git/Markdown → mermaid / plantuml (UML); freeform/freehand → tldraw.

**IEND caveat (issue #8, referenced throughout):** `-e` embeds XML but draw.io's CLI truncates the PNG IEND chunk (`IEND` type+CRC, 8 bytes, missing) → corrupt file; Anthropic vision API returns 400 "Could not process image" (strict PNG decoders also error). SVG/PDF unaffected. So **preview PNG (steps 4/5) = no `-e`; final PNG (step 7) = `-e` then `scripts/repair_png.py`.**

## Bundled resources — read on demand, none needed up front

| File | Read when |
|---|---|
| `references/diagram-types.md` | User names a diagram type (ERD, UML class, sequence, architecture, ML/DL, flowchart) |
| `references/shapes.md` + `scripts/shapesearch.py` | Need a **specific shape** (AWS/Azure/GCP, Cisco/Kubernetes/network, UML/BPMN/ER/electrical/P&ID) or you'd guess a `style=`. `shapesearch.py "<keywords>"` → exact official style, 10k+ shapes |
| `scripts/aiicons.py` | **AI/LLM brand** (OpenAI, Claude, Gemini, Mistral, Llama, HuggingFace, Ollama, LangChain, …). `aiicons.py "<brand>"` → draw.io `image` style (lobe-icons CDN; `--embed` to inline). draw.io has no built-in AI logos. See `references/shapes.md` → "AI / LLM brand logos" |
| `references/style-presets.md` | Learn/save/list/set-default/delete a preset, or apply a resolved active preset |
| `references/style-extraction.md` | Inside the Learn flow — extraction procedure (from `style-presets.md`) |
| `references/troubleshooting.md` | Export fails, vision rejects a PNG, rendering wrong |
| `scripts/repair_png.py` | After every `-e` PNG export — fixes truncated IEND chunk (issue #8) |
| `scripts/encode_drawio_url.py` | CLI unavailable — browser-fallback diagrams.net URL (`--edit` = editable) |
| `references/autolayout.md` | Large/layout-heavy (dependency/call graph, code structure, >~15 nodes); Graphviz places nodes + routes edges |
| `scripts/pyimports.py` · `jsimports.py` · `goimports.py` · `rustimports.py` | **Python/JS-TS/Go/Rust project** — import graph (transitive-reduced, optional `--group` containers nested by sub-package) for autolayout |
| `scripts/pyclasses.py` | **Python class hierarchy / class diagram** — classes + inheritance edges (boxed by module with `--group`) for autolayout |
| `scripts/validate.py` | After generating a `.drawio` (esp. autolayout/large) — structural lint (dangling edges, dup/reserved ids, broken parents, overlaps) before self-check |

## Prerequisites

draw.io desktop installed, CLI accessible (Homebrew CLI binary is `drawio`, not `draw.io`). Verify: `drawio --version` (or resolved binary/full path — see Step 1 for per-platform paths). Install if missing — macOS: `brew install --cask drawio` or https://github.com/jgraph/drawio-desktop/releases ; Windows: installer from that releases page ; Linux: `.deb`/`.rpm` from it — **not snap** (AppArmor denies secrets/keyring on servers → crash).

**Sandbox-isolation note (macOS, e.g. codex.app):** CLI (even `drawio --version`) may crash or give no output — see the sandbox branch under Workflow (unavailable in-sandbox; don't retry; use non-sandboxed host or browser fallback / XML-only).

## Workflow

If the request lacks key details, ask 1-3 focused questions (skip if specific or clearly simple like "draw a flowchart of X"): **type** (ERD/UML/Sequence/Architecture/ML-DL/Flowchart/general)? **format** (PNG default, SVG, PDF, JPG)? **location** (default = working dir; honor explicit path e.g. `./artifacts/`, don't ask if unmentioned)? **scope/fidelity** (component count, tech/labels)?

**Step 0 — Resolve active preset.**
- Phrase clearly naming a preset: "use my `<name>` style", "with my `<name>` style", "in `<name>` mode", "in the style of `<name>`" → active preset = `<name>`. Bare `with <name>` does **not** count (component, not style).
- Else `~/.drawio-skill/styles/` file with `"default": true` → that preset.
- Else none; use built-in color/shape/edge conventions.

Load preset JSON from `~/.drawio-skill/styles/<name>.json`, else `<this-skill-dir>/styles/built-in/<name>.json`. If in neither: tell the user the name is unknown, list available presets (user dir + built-in), stop — do **not** silently fall back to defaults. On success, first reply line: *"Using preset `<name>` (confidence: `<level>`)."* Application rules: `references/style-presets.md`.

1. **Check deps** — resolve the binary name, use it verbatim everywhere. Order: (a) `drawio --version` (Homebrew cask, jgraph `.deb`/`.rpm`, Arch AUR), (b) `draw.io --version` (older builds, custom symlinks, some distro pkgs), (c) macOS `.app`: `/Applications/draw.io.app/Contents/MacOS/draw.io --version`, (d) Windows: `"C:\Program Files\draw.io\draw.io.exe" --version`. First that prints a version = your binary; substitute for `drawio` below — **don't copy examples verbatim if yours differs.** macOS-Homebrew `drawio` is a thin wrapper execing `/Applications/draw.io.app/Contents/MacOS/draw.io` (same engine); (c) only needed if the wrapper is absent (drag-and-drop install without cask). WSL2: CLI is `/mnt/c/Program Files/draw.io/draw.io.exe` (note the space).
2. **Plan** — shapes, relationships, layout (LR or TB), group by tier/layer.
3. **Generate** — write `.drawio` XML to disk. Hand-place coordinates for small/styled. **Large/layout-heavy (dependency/call graphs, code structure, >~15 nodes): don't hand-place** — describe graph as JSON, run `python3 <this-skill-dir>/scripts/autolayout.py graph.json -o <name>.drawio` (node positions + orthogonal edge routing via Graphviz; `references/autolayout.md`). **Python/JS-TS/Go/Rust project:** matching importer (`scripts/pyimports.py`, `jsimports.py`, `goimports.py`, `rustimports.py`) extracts the import graph (transitive-reduced; `--group` boxes modules by sub-package, nested for deep trees). **Python class hierarchy:** `scripts/pyclasses.py` extracts classes + inheritance. After any `.drawio`, run `python3 <this-skill-dir>/scripts/validate.py <name>.drawio` before exporting. Default output dir = working dir; if user gave a path/dir (e.g. `./artifacts/`, `docs/images/`), use it — `mkdir -p` first. Same dir for exports in steps 4/7.
4. **Export draft** — CLI preview PNG, **no `-e`** (IEND caveat). **Cap width `--width 2000` (not `-s 2`)** — Claude vision rejects >2576×2576px ("dimensions exceed the 2576x2576px limit"); `-s 2` on medium+ overshoots. Save `<name>.png` (single extension). Embedding + full-res scale are final-only.
5. **Self-check** — agent vision reads the PNG, catch issues, auto-fix before showing user (needs vision-enabled model). 400 / "Could not process image" almost always = exported with `-e` → re-export without `-e`, retry once; still failing → skip, go to step 6. (Checks below.)
6. **Review loop** — show image, collect feedback, targeted XML edits, re-export, repeat until approved. (Rules below.)
7. **Final export** — re-export approved to all requested formats, `-e` on PNG/SVG/PDF; save `<name>.drawio.png`. **`-e` PNG: run `python3 <this-skill-dir>/scripts/repair_png.py <name>.drawio.png` immediately after** (IEND caveat). Report file paths.

**Sandbox branch — `drawio --version` crashes/prints nothing (restricted macOS sandbox, e.g. codex.app):** don't keep retrying; skip steps 4-7, use **Browser fallback** (`scripts/encode_drawio_url.py`) or deliver `.drawio` XML only; if PNG/SVG/PDF needed, ask user to run exports in a **non-sandboxed host** and share files.

**Escalation:** binary on PATH/known app path but execution fails abnormally (empty output, Electron startup failure, display/session error, likely sandbox restriction) → one escalated retry before falling back. Binary missing entirely → don't escalate to search; go to install guidance or fallback.

### Step 5 checks

Draft PNG must be exported **without** `-e`; agent lacks vision → skip, show PNG directly. 400 here → re-export without `-e`, retry once; still failing (any reason) → skip, go to step 6.

| Check | Look for | Auto-fix |
|---|---|---|
| Overlapping shapes | Shapes stacked | Shift apart ≥200px |
| Clipped labels | Text cut at boundaries | Increase shape width/height |
| Missing connections | Arrows not connecting | Verify `source`/`target` ids match existing cells |
| Off-canvas shapes | Negative coords / far from group | Move to positive coords near cluster |
| Edge-shape overlap | Edge crosses unrelated shape | Waypoints (`<Array as="points">`) or more spacing |
| Stacked edges | Edges overlap on same path | Distribute entry/exit (different exitX/entryX) |

Max **2 self-check rounds** — issues remain after 2 fixes → show user anyway. Re-export + re-read after each fix.

### Step 6 rules

Show image, ask feedback. **Targeted edits** (minimal XML change):

| User request | XML edit |
|---|---|
| Change color of X | `mxCell` by `value`=X, update `fillColor`/`strokeColor` in `style` |
| Add a node | Append `mxCell` vertex, next `id`, near related nodes |
| Remove a node | Delete `mxCell` vertex + edges matching `source`/`target` |
| Move shape X | Update `x`/`y` in matching `mxGeometry` |
| Resize shape X | Update `width`/`height` in matching `mxGeometry` |
| Add arrow A→B | Append `mxCell` edge, `source`/`target` = A,B ids |
| Change label text | Update `value` attribute |
| Change layout direction | **Full regeneration** — rebuild XML, new orientation |

- Single-element: edit XML in place (preserves prior layout tuning). Layout-wide (swap LR↔TB, "start over"): regenerate full XML.
- Overwrite the same `{name}.png` (no `-e`) each iteration — no `v1`/`v2`/`v3`. `-e` reserved for step 7.
- Re-export + show after edits. Loop until user says approved/done/LGTM.
- **Safety valve:** after 5 iteration rounds, suggest opening the `.drawio` in draw.io desktop for fine-grained edits.

### Step 7 finish

All requested formats (PNG, SVG, PDF, JPG) — default PNG. Report paths for `.drawio` source + image(s). **Auto-launch:** offer to open the `.drawio` — `open diagram.drawio` (macOS), `xdg-open` (Linux), `start` (Windows). Confirm files saved.

## Style Presets

**Style preset** = named JSON file (palette, shapes, font, edges); when active, fully replaces built-in conventions. **Lookup order** (Step 0):
1. `~/.drawio-skill/styles/<name>.json` — user presets (survive `git pull`)
2. `<this-skill-dir>/styles/built-in/<name>.json` — built-ins (`default`, `corporate`, `handdrawn`)

Lowercase the user name before any file op (schema enforces lowercase). **Everything else — Learn flow (extract preset from a file), management ops (list/default/delete/rename), application rules (color lookup, shape keywords, edges, fonts, extras, interaction with diagram-type presets), validation — read `references/style-presets.md`.** Only when the user invokes those flows or an active preset must be applied.

## Draw.io XML Structure

Skeleton: `<mxfile host="drawio" version="26.0.0">` → `<diagram name="Page-1">` → `<mxGraphModel><root>` with `<mxCell id="0" />` and `<mxCell id="1" parent="0" />`, then user shapes.

**Rules:** `id="0"` and `id="1"` = required root cells (never omit). User shapes start at `id="2"`, increment sequentially. All shapes `parent="1"` (unless inside a container → container's id). All text `html=1`. **Never `--` inside XML comments** (illegal per XML spec → parse errors). Escape attribute values: `&amp;`, `&lt;`, `&gt;`, `&quot;`. **Multi-line labels:** `&#xa;` for line breaks inside `value` (not literal `\n`), e.g. `value="Line 1&#xa;Line 2"`.

### Shape types (vertex)

| Style keyword | Use for |
|---|---|
| `rounded=0` | plain rectangle (default) |
| `rounded=1` | rounded rectangle — services, modules |
| `ellipse;` | circles/ovals — start/end, databases |
| `rhombus;` | diamond — decision points |
| `shape=mxgraph.aws4.resourceIcon;` | AWS icons |
| `shape=cylinder3;` | cylinder — databases |
| `swimlane;` | group/container with title bar |

**Vendor/branded icons** (AWS/Azure/GCP/Cisco/Kubernetes) + any non-trivial shape: don't guess `shape=mxgraph.*` (wrong name → blank box) — `python3 <this-skill-dir>/scripts/shapesearch.py "<keywords>"` → exact official style + size, or `references/shapes.md`. **AI/LLM brand logos** (draw.io has none): `python3 <this-skill-dir>/scripts/aiicons.py "<brand>"`.

Vertex needs `style`, `vertex="1"`, `parent`, and an `mxGeometry` child with x/y/width/height. Example: `<mxCell id="2" value="Label" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;" vertex="1" parent="1"><mxGeometry x="100" y="100" width="160" height="60" as="geometry" /></mxCell>`. Cylinder DB → `style="shape=cylinder3;whiteSpace=wrap;html=1;..."`; diamond → `style="rhombus;whiteSpace=wrap;html=1;..."`.

### Containers and groups

Nested-element architecture: use parent-child containment — do **not** place shapes on top of larger shapes.

| Type | Style | When |
|---|---|---|
| **Group** (invisible) | `group;pointerEvents=0;` | No visual border, no connections |
| **Swimlane** (titled) | `swimlane;startSize=30;` | Visible title bar, or container has connections |
| **Custom container** | add `container=1;pointerEvents=0;` to any shape | Shape as container without own connections |

Add `pointerEvents=0;` to container styles that shouldn't capture child connections. Children set `parent="containerId"` with coordinates **relative to the container** (e.g. `swimlane;startSize=30;` parent `id="svc1"`, children `parent="svc1"` at local x/y).

### Connector (edge)

**CRITICAL:** every edge `mxCell` must contain a `<mxGeometry relative="1" as="geometry" />` child. Self-closing edge cells (`<mxCell ... edge="1" ... />`) are **invalid** and won't render — use the expanded form. Example: `<mxCell id="10" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=1;orthogonalLoop=1;jettySize=auto;html=1;" edge="1" parent="1" source="2" target="3"><mxGeometry relative="1" as="geometry" /></mxCell>`. Labels + explicit direction: add `exitX=0.5;exitY=1;exitDx=0;exitDy=0;entryX=0.5;entryY=0;entryDx=0;entryDy=0;` to `style`. Detour: waypoint child `<mxGeometry relative="1" as="geometry"><Array as="points"><mxPoint x="500" y="50" /></Array></mxGeometry>`.

**Edge rules:**
- **Animated:** `flowAnimation=1;` → moving-dot animation (SVG export + draw.io desktop; ideal data-flow/pipeline), e.g. `edgeStyle=orthogonalEdgeStyle;flowAnimation=1;rounded=1;...`.
- **Always** `rounded=1;orthogonalLoop=1;jettySize=auto` (smart routing avoiding overlaps).
- Pin `exitX/exitY/entryX/entryY` on every edge when a node has 2+ connections (spreads lines across the perimeter).
- `<Array as="points">` waypoints when an edge must detour around a shape.
- **Arrowhead room:** final straight segment (last bend → target) ≥20px; too short → arrowhead overlaps the bend — more spacing or waypoints.

### Distributing connections on a shape

Different entry/exit points when multiple edges hit one shape (prevents stacking):

| Position | exitX/entryX | exitY/entryY | Use when |
|---|---|---|---|
| Top center | 0.5 | 0 | node above |
| Top-left | 0.25 | 0 | 2nd from top |
| Top-right | 0.75 | 0 | 3rd from top |
| Right center | 1 | 0.5 | node right |
| Bottom center | 0.5 | 1 | node below |
| Left center | 0 | 0.5 | node left |

**Rule:** N connections on one side → space evenly (3 on bottom → exitX = 0.25, 0.5, 0.75).

### Color palette (fillColor / strokeColor) — only when no preset active

| Color | fillColor | strokeColor | Use for |
|---|---|---|---|
| Blue | `#dae8fc` | `#6c8ebf` | services, clients |
| Green | `#d5e8d4` | `#82b366` | success, databases |
| Yellow | `#fff2cc` | `#d6b656` | queues, decisions |
| Orange | `#ffe6cc` | `#d79b00` | gateways, APIs |
| Red/Pink | `#f8cecc` | `#b85450` | errors, alerts |
| Grey | `#f5f5f5` | `#666666` | external/neutral |
| Purple | `#e1d5e7` | `#9673a6` | security, auth |

### Layout tips

Spacing by complexity: Simple ≤5 → 200px horiz / 150px vert; Medium 6–10 → 280px / 200px; Complex >10 → 350px / 250px.

- **Routing corridors:** ~80px empty corridor between shape rows/columns for edges; never place a shape in a gap edges must traverse.
- **Grid:** snap `x`,`y`,`width`,`height` to **multiples of 10** (draw.io default grid; eases editing).
- Plan the grid before x/y. Group related nodes in one band. `swimlane` cells for grouping with visible borders.
- Heavily-connected "hub" nodes centrally → edges radiate outward.
- Straight vertical connections: pin `exitX=0.5;exitY=1;exitDx=0;exitDy=0;entryX=0.5;entryY=0;entryDx=0;entryDy=0`.
- Center-align a child under its parent (same center x) → no diagonal routing.
- **Event bus:** Kafka/bus nodes in the **center of the service row**, not below — services either side reach it via short horizontal arrows (`exitX=1` left, `exitX=0` right), no crossings.
- Horizontal connections (`exitX=1`/`exitX=0`) never cross vertical nodes in the same row — use for peer-to-peer + publish.
- **Edge-shape overlap:** trace each edge before finalizing — crosses an unrelated shape → move it or add waypoints. Tree/hierarchical: layer nodes into rows, connect only adjacent layers. Star/hub: hub center, satellites around (short radial edges). Edge spanning multiple rows/columns: route along the outer corridor, not the middle.

## Export

**Preview** (step 4): no `-e`, output `diagram.png`. **Final** (step 7): `-e`, output `diagram.drawio.png` (embedded XML keeps it editable). See IEND caveat. `drawio` below = binary resolved in Step 1; if `draw.io` (with dot) on PATH substitute throughout; if only macOS `.app` / Windows `.exe`, use its full path (Prerequisites).

```bash
# Preview PNG (step 4) — NO -e, width-capped under vision's 2576px ceiling
drawio -x -f png --width 2000 -o diagram.png input.drawio
# Final PNG (step 7) — WITH -e, double extension
drawio -x -f png -e -s 2 -o diagram.drawio.png input.drawio
# Windows
"C:\Program Files\draw.io\draw.io.exe" -x -f png -e -s 2 -o diagram.drawio.png input.drawio
# Linux headless (needs xvfb-run; on servers add HOME + --disable-gpu)
export HOME=${HOME:-/tmp}
xvfb-run -a --server-args="-screen 0 1280x1024x24" \
  drawio -x -f png -e -s 2 -o diagram.drawio.png input.drawio --disable-gpu
# Running as root (CI/Docker)? Append --no-sandbox AT THE END (earlier, drawio treats it as the input filename)
drawio -x -f svg -e -o diagram.svg input.drawio    # SVG final (-e safe; SVG is text)
drawio -x -f pdf -e -o diagram.pdf input.drawio    # PDF final
# Custom output dir (e.g. CI artifacts) — create then export there
mkdir -p ./artifacts && drawio -x -f png -e -s 2 -o ./artifacts/diagram.drawio.png input.drawio
```

### Post-export PNG repair (required after every `-e` PNG export)

Per the IEND caveat, immediately after every `-e` PNG:
```bash
python3 <this-skill-dir>/scripts/repair_png.py diagram.drawio.png
```
Its `endswith(IEND)` guard makes it a no-op once draw.io fixes the bug upstream — safe to run unconditionally.

**Key flags:**
- `-x` — export mode (required)
- `-f` — format: `png`, `svg`, `pdf`, `jpg`
- `-e` — embed XML (PNG/SVG/PDF), stays editable. **Skip for the step-5 self-check preview PNG** (IEND caveat); final PNG keep `-e` + run `scripts/repair_png.py`. SVG/PDF unaffected.
- `-s` — scale: `1`, `2`, `3` (2 for final PNG; NOT for step-4 preview — see `--width`)
- `--width <px>` — target width, no short form (`-w` does **not** exist, silently breaks the input-file parser). `--width 2000` for the step-4 preview → under Claude's 2576×2576 vision ceiling. Also `--height <px>` for tall-narrow. Don't combine `--width` with `-s`.
- `-o` — output path; any directory (e.g. `./artifacts/diagram.drawio.png`) — `mkdir -p` first. `.drawio.png` double extension when embedding.
- `-b` — border width (default 0, recommend 10)
- `-t` — transparent background (PNG only)
- `--page-index 0` — export specific page (default: all)

### Browser fallback (no CLI needed)

CLI unavailable → client-side URL:
```bash
python3 <this-skill-dir>/scripts/encode_drawio_url.py input.drawio          # read-only viewer
python3 <this-skill-dir>/scripts/encode_drawio_url.py --edit input.drawio    # opens in the editor
```
Default → `https://viewer.diagrams.net/...#R…` viewer URL; `--edit` → `https://app.diagrams.net/...#create=…` editable URL. XML is `encodeURIComponent`-encoded, deflate-compressed, base64'd into the URL fragment — the part after `#` is never sent to the server, nothing uploaded. `encodeURIComponent` mandatory: without it any diagram with a literal `%` or non-ASCII (e.g. CJK) label → browser "URI malformed", never opens. Open with `open "$URL"` (macOS) / `xdg-open "$URL"` (Linux). **WSL2 / Windows:** `cmd.exe` drops the `#fragment` — write a `.url` shortcut file, open that (see `references/troubleshooting.md` → "WSL2 / Windows specifics").

### Fallback chain (degrade gracefully)

| Scenario | Behavior |
|---|---|
| CLI missing, Python available | Browser fallback (diagrams.net URL) |
| CLI missing, Python missing | `.drawio` XML only; user opens in draw.io desktop or diagrams.net |
| CLI crashes / no output, macOS sandbox isolation | CLI unavailable in-sandbox; browser fallback / XML-only; user runs CLI exports in a non-sandboxed host |
| Vision unavailable | Skip self-check (step 5); show the exported PNG directly |
| Export fails (Chromium/display) | Linux: retry `xvfb-run -a`; still failing → `.drawio` XML, suggest manual export |
| Export fails on Linux server (headless) | In order: (1) `xvfb-run -a`, (2) append `--no-sandbox` at the very end if root, (3) `--disable-gpu`, (4) `export HOME=/tmp`, (5) apt deps (`libgtk-3-0 libnotify4 libnss3 libgbm1 libasound2t64` etc.), (6) [tomkludy/drawio-renderer](https://hub.docker.com/r/tomkludy/drawio-renderer) Docker (REST API for headless export) |

### Detecting the binary (PATH)

Resolution order = Step 1 (a-d): `command -v drawio` → `command -v draw.io` (older installs, manual symlinks) → `/Applications/draw.io.app/Contents/MacOS/draw.io` → WSL2 `/mnt/c/Program Files/draw.io/draw.io.exe` (detect via `grep -qi microsoft /proc/version`, note the space). None → install from https://github.com/jgraph/drawio-desktop/releases (Homebrew: `brew install --cask drawio`). **WSL2 / native Windows:** opening exported files + browser-fallback URLs needs path conversion + a `.url`-file workaround (`cmd.exe` drops URL `#fragment`s) — see `references/troubleshooting.md` → "WSL2 / Windows specifics".

## Common Mistakes

Something wrong (export fails, vision rejects a PNG, layout broken, edges misroute) → `references/troubleshooting.md` row-by-row mistake → fix table.

## Diagram Type Presets

Specific diagram type requested → read `references/diagram-types.md` for the matching preset (shapes, edges, layout direction). Pick by phrasing:

| User says | Section in `references/diagram-types.md` |
|---|---|
| "ER diagram", "schema diagram", "data model" | ERD |
| "UML class diagram", "class diagram" | UML Class |
| "sequence diagram", "interaction diagram", "lifeline" | Sequence |
| "architecture", "system diagram", "service diagram" | Architecture |
| "neural network", "model architecture", "ML diagram", "deep learning" | ML / Deep Learning Model |
| "flowchart", "decision tree", "process flow" | Flowchart |

Diagram-type preset sets **structural** style keywords. If a user style preset is also active (see `## Style Presets`), keep the structural keywords, layer color/font/edge/extras on top — `references/style-presets.md` → "Interaction with diagram-type presets" for merge rules.
