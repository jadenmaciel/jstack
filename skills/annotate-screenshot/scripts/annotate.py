#!/usr/bin/env python3
"""Burn circle / arrow / label annotations onto an image. Pillow only."""

from __future__ import annotations

import argparse
import json
import math
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

COLOR = (255, 45, 45, 255)
STROKE = 4
ARROW_HEAD = 16


def _default_out(src: Path) -> Path:
    return src.with_name(f"{src.stem}-annotated{src.suffix or '.png'}")


def _draw_arrow(draw: ImageDraw.ImageDraw, start: tuple[float, float], end: tuple[float, float]) -> None:
    draw.line([start, end], fill=COLOR, width=STROKE)
    angle = math.atan2(end[1] - start[1], end[0] - start[0])
    left = (
        end[0] - ARROW_HEAD * math.cos(angle - math.pi / 6),
        end[1] - ARROW_HEAD * math.sin(angle - math.pi / 6),
    )
    right = (
        end[0] - ARROW_HEAD * math.cos(angle + math.pi / 6),
        end[1] - ARROW_HEAD * math.sin(angle + math.pi / 6),
    )
    draw.polygon([end, left, right], fill=COLOR)


def annotate(src: Path, dst: Path, anns: list[dict]) -> None:
    if not src.is_file():
        raise FileNotFoundError(f"input not found: {src}")
    img = Image.open(src).convert("RGBA")
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    try:
        font = ImageFont.truetype("Helvetica", 20)
    except OSError:
        font = ImageFont.load_default()

    for i, ann in enumerate(anns):
        kind = ann.get("type")
        if kind == "circle":
            x, y = ann["xy"]
            r = ann["r"]
            draw.ellipse([x - r, y - r, x + r, y + r], outline=COLOR, width=STROKE)
        elif kind == "arrow":
            _draw_arrow(draw, tuple(ann["from"]), tuple(ann["to"]))
        elif kind == "label":
            x, y = ann["xy"]
            text = str(ann["text"])
            bbox = draw.textbbox((x, y), text, font=font)
            pad = 4
            draw.rectangle(
                [bbox[0] - pad, bbox[1] - pad, bbox[2] + pad, bbox[3] + pad],
                fill=(0, 0, 0, 180),
            )
            draw.text((x, y), text, fill=COLOR, font=font)
        else:
            raise ValueError(f"annotation[{i}]: unknown type {kind!r} (want circle|arrow|label)")

    out = Image.alpha_composite(img, overlay)
    if dst.suffix.lower() in {".jpg", ".jpeg"}:
        out = out.convert("RGB")
    dst.parent.mkdir(parents=True, exist_ok=True)
    out.save(dst)


def _self_check() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        src = Path(tmp) / "blank.png"
        dst = Path(tmp) / "blank-annotated.png"
        Image.new("RGB", (200, 150), (40, 40, 40)).save(src)
        annotate(
            src,
            dst,
            [
                {"type": "circle", "xy": [100, 75], "r": 30},
                {"type": "arrow", "from": [20, 20], "to": [90, 60]},
                {"type": "label", "xy": [10, 120], "text": "ok"},
            ],
        )
        assert dst.is_file() and dst.stat().st_size > 0, "annotated output missing"
        print("self-check ok:", dst)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="Annotate a screenshot with circle/arrow/label")
    p.add_argument("--in", dest="inp", required=True, type=Path)
    p.add_argument("--out", dest="out", type=Path, default=None)
    p.add_argument("--ann", required=True, help="JSON list of annotations")
    args = p.parse_args(argv)

    try:
        anns = json.loads(args.ann)
    except json.JSONDecodeError as e:
        print(f"bad --ann JSON: {e}", file=sys.stderr)
        return 1
    if not isinstance(anns, list):
        print("--ann must be a JSON list", file=sys.stderr)
        return 1

    out = args.out or _default_out(args.inp)
    try:
        annotate(args.inp, out, anns)
    except (FileNotFoundError, KeyError, TypeError, ValueError) as e:
        print(e, file=sys.stderr)
        return 1
    print(out)
    return 0


if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "--self-check":
        _self_check()
        raise SystemExit(0)
    raise SystemExit(main())
