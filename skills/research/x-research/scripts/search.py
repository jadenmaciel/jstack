#!/usr/bin/env python3
"""Run authenticated Grok X search and write posts.json for x-research."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

INSTALL_HINT = "grok missing — install: curl -fsSL https://x.ai/cli/install.sh | bash"
AUTH_HINT = "grok unauthenticated — run: grok login"
DISALLOWED_TOOLS = "search_replace,write_file,edit_notebook,run_terminal_cmd"
MAX_HANDLES = 20


def preflight() -> None:
    if shutil.which("grok") is None:
        print(INSTALL_HINT, file=sys.stderr)
        raise SystemExit(1)
    auth = Path.home() / ".grok" / "auth.json"
    if not auth.is_file():
        print(AUTH_HINT, file=sys.stderr)
        raise SystemExit(1)


def is_post_url(url: str) -> bool:
    try:
        parsed = urlparse(url)
    except ValueError:
        return False
    if parsed.scheme != "https":
        return False
    host = (parsed.netloc or "").lower()
    if host not in {"x.com", "www.x.com", "twitter.com", "www.twitter.com"}:
        return False
    parts = [p for p in (parsed.path or "").split("/") if p]
    return len(parts) >= 3 and parts[1] == "status" and parts[2].isdigit()


def filter_posts(posts: Any) -> list[dict[str, Any]]:
    if not isinstance(posts, list):
        return []
    kept: list[dict[str, Any]] = []
    for item in posts:
        if not isinstance(item, dict):
            continue
        url = item.get("url")
        handle = item.get("handle")
        quote = item.get("quote")
        if not isinstance(url, str) or not is_post_url(url):
            continue
        if not isinstance(handle, str) or not handle.strip():
            continue
        if not isinstance(quote, str) or not quote.strip():
            continue
        row: dict[str, Any] = {
            "url": url.strip(),
            "handle": handle.strip(),
            "quote": quote.strip(),
        }
        for key in ("posted_at", "engagement"):
            val = item.get(key)
            if isinstance(val, str) and val.strip():
                row[key] = val.strip()
        kept.append(row)
    return kept


def pick_posts_object(text: str) -> dict[str, Any] | None:
    dec = json.JSONDecoder()
    picked: dict[str, Any] | None = None
    i = 0
    while i < len(text):
        if text[i] == "{":
            try:
                obj, end = dec.raw_decode(text, i)
            except json.JSONDecodeError:
                i += 1
                continue
            if isinstance(obj, dict) and "posts" in obj:
                picked = obj
            i = end
            continue
        i += 1
    return picked


def parse_raw(raw_path: Path) -> dict[str, Any]:
    raw = raw_path.read_text(encoding="utf-8")
    try:
        outer = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise SystemExit(f"raw.json is not JSON: {exc}") from exc

    if isinstance(outer, dict) and outer.get("type") == "error":
        message = outer.get("message") or "grok error"
        return {
            "summary": "",
            "posts": [],
            "gaps": str(message),
        }

    text = (
        outer["text"]
        if isinstance(outer, dict) and isinstance(outer.get("text"), str)
        else raw
    )
    picked = pick_posts_object(text)
    if picked is None:
        raise SystemExit("no posts object in grok output")

    summary = picked.get("summary") if isinstance(picked.get("summary"), str) else ""
    gaps = picked.get("gaps") if isinstance(picked.get("gaps"), str) else ""
    posts = filter_posts(picked.get("posts"))
    result = {
        "summary": summary,
        "posts": posts,
        "gaps": gaps,
    }
    if not posts and not gaps.strip():
        result["gaps"] = "X returned no posts matching the query."
    return result


def build_prompt(
    query: str,
    handles: list[str],
    from_date: str | None,
    to_date: str | None,
) -> str:
    lines = [
        f"Search X for: {query}",
        "Use X search tools. Prefer posts from about the last 30 days unless dates below say otherwise.",
    ]
    if handles:
        lines.append("Only these @handles: " + ", ".join(handles))
    if from_date:
        lines.append(f"from_date: {from_date}")
    if to_date:
        lines.append(f"to_date: {to_date}")
    lines.extend(
        [
            "When finished, output exactly one JSON object of this shape:",
            '{"summary":"...","posts":[{"url":"https://x.com/.../status/...","handle":"@...","quote":"...","posted_at":"...","engagement":"..."}],"gaps":"..."}',
            "posts[].url, handle, and quote are required; posted_at and engagement are optional.",
            "Use real https://x.com/... or https://twitter.com/... status URLs and short verbatim quotes.",
            "gaps names what the X search did not find (not your next step).",
        ]
    )
    return "\n".join(lines)


def run_grok(prompt: str, raw_path: Path) -> None:
    cmd = [
        "grok",
        "--no-auto-update",
        "--no-plan",
        "--no-subagents",
        "--always-approve",
        "--max-turns",
        "12",
        "--disable-web-search",
        "--disallowed-tools",
        DISALLOWED_TOOLS,
        "--output-format",
        "json",
        "-p",
        prompt,
    ]
    with raw_path.open("w", encoding="utf-8") as out:
        proc = subprocess.run(cmd, stdout=out, stderr=subprocess.PIPE, text=True)
    if proc.returncode != 0:
        err = (proc.stderr or "").strip() or f"grok exited {proc.returncode}"
        # Keep raw.json for audit; surface the failure.
        print(err, file=sys.stderr)
        raise SystemExit(proc.returncode)


def write_posts(out_dir: Path, payload: dict[str, Any]) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    posts_path = out_dir / "posts.json"
    posts_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"posts={len(payload.get('posts') or [])}")
    print(f"wrote={posts_path}")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--parse-only",
        metavar="RAW_JSON",
        help="Parse an existing raw.json (or fixture) and write posts.json beside it",
    )
    parser.add_argument("--slug", help="Artifact slug under --out default path")
    parser.add_argument("--query", help="X search query")
    parser.add_argument(
        "--out",
        help="Output directory (default: .research/<slug>/x-research)",
    )
    parser.add_argument(
        "--handle",
        action="append",
        default=[],
        help="@handle filter (repeatable, max 20)",
    )
    parser.add_argument("--from", dest="from_date", help="from_date YYYY-MM-DD")
    parser.add_argument("--to", dest="to_date", help="to_date YYYY-MM-DD")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> None:
    args = parse_args(argv)

    if args.parse_only:
        raw_path = Path(args.parse_only).expanduser().resolve()
        if not raw_path.is_file():
            raise SystemExit(f"raw file not found: {raw_path}")
        out_dir = Path(args.out).expanduser().resolve() if args.out else raw_path.parent
        payload = parse_raw(raw_path)
        write_posts(out_dir, payload)
        return

    if not args.slug or not args.query:
        raise SystemExit("--slug and --query are required (or use --parse-only)")

    handles = args.handle or []
    if len(handles) > MAX_HANDLES:
        raise SystemExit(f"at most {MAX_HANDLES} --handle values")

    out_dir = (
        Path(args.out).expanduser()
        if args.out
        else Path(".research") / args.slug / "x-research"
    )
    out_dir = out_dir.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    raw_path = out_dir / "raw.json"

    preflight()
    prompt = build_prompt(args.query, handles, args.from_date, args.to_date)
    run_grok(prompt, raw_path)
    payload = parse_raw(raw_path)
    write_posts(out_dir, payload)


if __name__ == "__main__":
    main()
