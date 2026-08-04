#!/usr/bin/env python3.12
"""instruction-optimizer deterministic scorer.

Measures char/line/est_token size and applies boolean hard gates from a locked
rubric. stdlib only; no network, no LLM, never mutates the target. est_tokens is
chars/4, a labeled estimate -- there is no local tokenizer.

The scorer is ground truth for GATES and METRICS only (substring presence,
parse validity, char/line counts). It does NOT judge semantic
compression-only-ness; that is the reviewer's job (see SKILL.md Step 4).

Usage:
  score.py TARGET --rubric rubric.json [--baseline-chars N] [--label L] [--tsv scores.tsv]
  score.py --self-test

rubric.json schema (unknown top-level keys and bad types are rejected):
  {
    "must_keep":   ["exact substring that must survive", ...],
    "forbidden_new": ["substring that must NOT appear", ...],
    "anchors":     ["referenced/path/that/must/remain", ...],
    "require_frontmatter": true,
    "parse": "none" | "json" | "toml",
    "_meta": {"target_sha256_at_lock": "...", "acceptance_bar": ">=15% chars, zero rule loss"}
  }
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

_KNOWN_KEYS = {"must_keep", "forbidden_new", "anchors", "require_frontmatter", "parse", "_meta"}
_LIST_KEYS = ("must_keep", "forbidden_new", "anchors")
_PARSE_VALUES = {"none", "json", "toml"}


def validate_rubric(rubric: object) -> list[str]:
    """Reject malformed rubrics that would silently weaken the gates.

    A typo'd key (`must_keeps`) or parse value (`jsoon`) must fail loudly, not
    disable a gate. Returns a list of schema errors; empty means valid.
    """
    errs: list[str] = []
    if not isinstance(rubric, dict):
        return ["rubric is not a JSON object"]
    for key in rubric:
        if key not in _KNOWN_KEYS:
            errs.append(f"unknown rubric key: {key!r} (typo silently drops a gate)")
    for key in _LIST_KEYS:
        val = rubric.get(key, [])
        if not isinstance(val, list) or not all(isinstance(x, str) for x in val):
            errs.append(f"{key} must be a list of strings")
    if "require_frontmatter" in rubric and not isinstance(rubric["require_frontmatter"], bool):
        errs.append("require_frontmatter must be a boolean")
    parse = rubric.get("parse", "none")
    if parse not in _PARSE_VALUES:
        errs.append(f"parse must be one of {sorted(_PARSE_VALUES)}, got {parse!r}")
    if "_meta" in rubric and not isinstance(rubric["_meta"], dict):
        errs.append("_meta must be an object")
    return errs


def _preview(s: str, n: int = 60) -> str:
    """Truncate an echoed gate phrase so reasons never dump long/sensitive text."""
    s = s.replace("\n", "\\n")
    return s if len(s) <= n else s[:n] + "..."


def check_gates(text: str, rubric: dict) -> list[str]:
    """Return a list of gate-failure reasons; empty list means PASS."""
    reasons: list[str] = []

    for phrase in rubric.get("must_keep", []):
        if phrase not in text:
            reasons.append(f"missing must_keep: {_preview(phrase)!r}")
    for phrase in rubric.get("forbidden_new", []):
        if phrase in text:
            reasons.append(f"introduced forbidden_new: {_preview(phrase)!r}")
    for anchor in rubric.get("anchors", []):
        if anchor not in text:
            reasons.append(f"missing anchor: {_preview(anchor)}")

    if rubric.get("require_frontmatter"):
        lines = text.splitlines()
        if not lines or lines[0].strip() != "---":
            reasons.append("missing frontmatter block")
        else:
            closing = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
            if closing is None:
                reasons.append("frontmatter opened but never closed with ---")
            else:
                head = "\n".join(lines[1:closing])
                if "name:" not in head:
                    reasons.append("frontmatter missing name:")
                if "description:" not in head:
                    reasons.append("frontmatter missing description:")

    parse = rubric.get("parse", "none")
    if parse == "json":
        try:
            json.loads(text)
        except Exception as exc:  # noqa: BLE001 - report any parse failure as a gate fail
            reasons.append(f"JSON parse failed: {exc}")
    elif parse == "toml":
        import tomllib

        try:
            tomllib.loads(text)
        except Exception as exc:  # noqa: BLE001
            reasons.append(f"TOML parse failed: {exc}")

    return reasons


def score(path: Path, rubric: dict, baseline_chars: int | None, label: str | None) -> dict:
    label = label or path.name
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError as exc:
        return {
            "label": label,
            "chars": 0,
            "lines": 0,
            "est_tokens": 0,
            "reduction_pct": None,
            "verdict": "FAIL",
            "reasons": [f"not valid UTF-8 text (not an editable instruction asset): {exc}"],
        }
    chars = len(text)
    reasons = check_gates(text, rubric)
    reduction = None
    if baseline_chars:
        reduction = round((baseline_chars - chars) / baseline_chars * 100, 2)
    return {
        "label": label,
        "chars": chars,
        "lines": len(text.splitlines()),
        "est_tokens": round(chars / 4),
        "reduction_pct": reduction,
        "verdict": "PASS" if not reasons else "FAIL",
        "reasons": reasons,
    }


def append_tsv(tsv: Path, row: dict) -> None:
    header = "label\tchars\tlines\test_tokens\treduction_pct\tverdict\n"
    label = str(row["label"]).replace("\t", " ").replace("\n", " ")
    line = (
        f"{label}\t{row['chars']}\t{row['lines']}\t{row['est_tokens']}\t"
        f"{'' if row['reduction_pct'] is None else row['reduction_pct']}\t{row['verdict']}\n"
    )
    if not tsv.exists():
        tsv.write_text(header + line, encoding="utf-8")
    else:
        with tsv.open("a", encoding="utf-8") as fh:
            fh.write(line)


def self_test() -> int:
    import hashlib
    import tempfile

    rubric = {
        "must_keep": ["MUST invoke $codex-review", "cannot receive $check PASS"],
        "forbidden_new": ["may skip", "auto-apply"],
        "anchors": ["~/.codex/skills/codex-review/SKILL.md"],
        "require_frontmatter": True,
        "parse": "none",
    }
    good = (
        "---\nname: demo\ndescription: x\n---\n"
        "Body. MUST invoke $codex-review. A target cannot receive $check PASS "
        "without it. See ~/.codex/skills/codex-review/SKILL.md.\n"
    )
    broken = good.replace("MUST invoke $codex-review", "review is optional, may skip")
    no_close = "---\nname: demo\ndescription: x\nbody with no closing fence\n"
    bad_json = '{"a": 1,}'
    good_json = '{"server": "x", "model": "claude-opus-4-8"}'

    checks: dict[str, bool] = {}
    with tempfile.TemporaryDirectory() as d:
        dp = Path(d)
        base = dp / "good.md"
        cand = dp / "broken.md"
        base.write_text(good, encoding="utf-8")
        cand.write_text(broken, encoding="utf-8")

        sha_before = hashlib.sha256(base.read_bytes()).hexdigest()
        r_base = score(base, rubric, None, "baseline")
        r_cand = score(cand, rubric, r_base["chars"], "broken")
        sha_after = hashlib.sha256(base.read_bytes()).hexdigest()

        # frontmatter opened but never closed -> FAIL
        nc = dp / "noclose.md"
        nc.write_text(no_close, encoding="utf-8")
        r_nc = score(nc, rubric, None, "noclose")

        # anchor drop -> FAIL
        anchorless = dp / "anchorless.md"
        anchorless.write_text(good.replace("~/.codex/skills/codex-review/SKILL.md", "(removed)"), encoding="utf-8")
        r_anchor = score(anchorless, rubric, None, "anchorless")

        # JSON parse gate
        jrubric = {"parse": "json", "require_frontmatter": False}
        bj = dp / "bad.json"
        bj.write_text(bad_json, encoding="utf-8")
        gj = dp / "good.json"
        gj.write_text(good_json, encoding="utf-8")
        r_badjson = score(bj, jrubric, None, "badjson")
        r_goodjson = score(gj, jrubric, None, "goodjson")

        # non-UTF-8 target -> clean FAIL, no crash
        nb = dp / "binary.md"
        nb.write_bytes(b"\xff\xfe\x00bad")
        r_bin = score(nb, rubric, None, "binary")

        # TSV escaping: a label with a tab/newline must not corrupt columns
        tsv = dp / "scores.tsv"
        append_tsv(tsv, {**r_base, "label": "cand\t1\nx"})
        tsv_cols_ok = all(len(ln.split("\t")) == 6 for ln in tsv.read_text().splitlines())

        checks = {
            "baseline PASS": r_base["verdict"] == "PASS",
            "broken FAIL": r_cand["verdict"] == "FAIL",
            "broken cites dropped must_keep": any("must_keep" in x for x in r_cand["reasons"]),
            "broken cites forbidden_new": any("forbidden_new" in x for x in r_cand["reasons"]),
            "unclosed frontmatter FAIL": r_nc["verdict"] == "FAIL",
            "anchor drop FAIL": r_anchor["verdict"] == "FAIL",
            "bad JSON FAIL": r_badjson["verdict"] == "FAIL",
            "good JSON PASS": r_goodjson["verdict"] == "PASS",
            "non-UTF8 clean FAIL (no crash)": r_bin["verdict"] == "FAIL",
            "TSV label escaping keeps 6 columns": tsv_cols_ok,
            "est_tokens == round(chars/4)": r_base["est_tokens"] == round(r_base["chars"] / 4),
            "source byte-identical (no mutation)": sha_before == sha_after,
        }

    # rubric schema validation (no files needed)
    checks["valid rubric accepted"] = validate_rubric(rubric) == []
    checks["unknown key rejected"] = bool(validate_rubric({**rubric, "must_keeps": []}))
    checks["bad parse value rejected"] = bool(validate_rubric({"parse": "jsoon"}))
    checks["non-list must_keep rejected"] = bool(validate_rubric({"must_keep": "x"}))

    for name, ok in checks.items():
        print(f"  [{'PASS' if ok else 'FAIL'}] {name}")
    failed = [n for n, ok in checks.items() if not ok]
    print("SELF-TEST:", "PASS" if not failed else f"FAIL ({len(failed)})")
    return 0 if not failed else 1


def main() -> int:
    ap = argparse.ArgumentParser(description="instruction-optimizer deterministic scorer")
    ap.add_argument("target", nargs="?", help="file to score")
    ap.add_argument("--rubric", help="path to locked rubric.json")
    ap.add_argument("--baseline-chars", type=int, default=None)
    ap.add_argument("--label", default=None)
    ap.add_argument("--tsv", default=None)
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        return self_test()
    if not args.target or not args.rubric:
        ap.error("TARGET and --rubric are required (or use --self-test)")

    rubric = json.loads(Path(args.rubric).read_text(encoding="utf-8"))
    schema_errs = validate_rubric(rubric)
    if schema_errs:
        print(json.dumps({"verdict": "FAIL", "reasons": [f"invalid rubric: {e}" for e in schema_errs]}, indent=2))
        return 2

    row = score(Path(args.target), rubric, args.baseline_chars, args.label)
    if args.tsv:
        append_tsv(Path(args.tsv), row)
    print(json.dumps(row, indent=2))
    return 0 if row["verdict"] == "PASS" else 2


if __name__ == "__main__":
    raise SystemExit(main())
