---
name: annotate-screenshot
description: Burn circles, arrows, and labels onto proof screenshots (browser, IDE, terminal, or any image). Use when capturing visual proof, QA evidence, verify-this screenshots, or bug repro images.
---

# Annotate screenshot

Post-process any proof image so callouts are burned into the file.

## When

Visual proof, QA evidence, verify-this screenshots, bug repro images. Skip pure text/logs.

## Steps

1. Capture the screenshot (browser MCP, Playwright, IDE, etc.).
2. Inspect the image (`Read`) or use element boxes to pick coords.
3. Run the annotator (1–3 callouts max):

```bash
python3 ~/.cursor/skills/annotate-screenshot/scripts/annotate.py \
  --in /path/shot.png \
  --out /path/shot-annotated.png \
  --ann '[{"type":"circle","xy":[120,80],"r":40},{"type":"arrow","from":[200,200],"to":[120,100]},{"type":"label","xy":[130,40],"text":"Submit"}]'
```

4. Show the annotated image. Keep the original when useful.

If `--out` is omitted, writes `*-annotated.png` next to the input.

## Shapes

| type | fields |
|------|--------|
| `circle` | `xy` `[x,y]` center, `r` radius |
| `arrow` | `from` `[x,y]`, `to` `[x,y]` (points at `to`) |
| `label` | `xy` `[x,y]`, `text` string |

## Browser path

Optional: `browser_highlight` then `browser_take_screenshot`. Still run annotate when arrows/labels are needed — highlight alone is not durable proof.

## Coord tip

Circle the focal region; arrows point **to** it; keep labels short.
