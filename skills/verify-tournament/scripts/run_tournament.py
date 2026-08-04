#!/usr/bin/env python3
import argparse
import datetime as dt
import difflib
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


OLD_ACCOUNT = "/Users/jadenmaciel-shapiro"
QUICK_VALIDATE = Path("/Users/testadmin/.codex/skills/.system/skill-creator/scripts/quick_validate.py")
SECRET_PATTERNS = [
    re.compile(r"sk-[A-Za-z0-9_-]{20,}"),
    re.compile(r"ghp_[A-Za-z0-9_]{20,}"),
    re.compile(r"AKIA[0-9A-Z]{16}"),
    re.compile(r"xox[baprs]-[A-Za-z0-9-]{20,}"),
    re.compile(r"-----BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY-----"),
]
FRONTMATTER = re.compile(r"\A---\n(.*?)\n---\n", re.S)
LINK = re.compile(r"\[[^\]]+\]\(([^)#]+)(?:#[^)]+)?\)")


def read_text(path):
    return Path(path).read_text(encoding="utf-8")


def sha256(path):
    h = hashlib.sha256()
    with Path(path).open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def under_tmp(path):
    tmp = Path(tempfile.gettempdir()).resolve()
    resolved = Path(path).resolve()
    return resolved == tmp or tmp in resolved.parents


def has_secret(text):
    return any(pattern.search(text) for pattern in SECRET_PATTERNS)


def load_profile(args):
    profile = {
        "profile": "instructions-v1",
        "objective": args.objective,
        "must_keep": [],
        "forbidden_new": [],
        "anchors": [],
        "checks": [],
        "probes": [],
        "review": {"required": not args.review_not_required, "quote_proof": True},
    }
    if args.profile_file:
        with Path(args.profile_file).open(encoding="utf-8") as f:
            profile.update(json.load(f))
    profile["must_keep"] = list(profile.get("must_keep", [])) + args.must_keep
    profile["forbidden_new"] = list(profile.get("forbidden_new", [])) + args.forbidden_new
    profile["anchors"] = list(profile.get("anchors", [])) + args.anchor
    profile["objective"] = args.objective or profile.get("objective", "min_chars")
    if args.review_not_required:
        profile.setdefault("review", {})["required"] = False
    return profile


def candidate_paths(args):
    paths = [Path(p).resolve() for p in args.candidate]
    if args.candidate_dir:
        paths.extend(sorted(Path(args.candidate_dir).resolve().glob("*.md")))
    seen = set()
    out = []
    for path in paths:
        if not path.exists():
            raise SystemExit(f"candidate not found: {path}")
        label = path.name
        if label in seen:
            raise SystemExit(f"duplicate candidate name: {label}")
        seen.add(label)
        out.append((label, path))
    if not out:
        raise SystemExit("provide --candidate or --candidate-dir after authoring sandbox candidates")
    if len(out) > 5:
        raise SystemExit("candidate cap is 5")
    return out


def parse_frontmatter(content):
    match = FRONTMATTER.match(content)
    if not match:
        return None
    fields = {}
    for raw in match.group(1).splitlines():
        if ":" not in raw:
            continue
        key, value = raw.split(":", 1)
        fields[key.strip()] = value.strip().strip("\"'")
    return fields


def copy_target_tree(target, dest, candidate_file=None):
    target = Path(target)
    if target.name == "SKILL.md":
        root = dest / target.parent.name
        shutil.copytree(target.parent, root)
        if candidate_file:
            shutil.copy2(candidate_file, root / "SKILL.md")
        return root / "SKILL.md", root
    root = dest
    root.mkdir(parents=True, exist_ok=True)
    copied = root / target.name
    shutil.copy2(candidate_file or target, copied)
    return copied, root


def validate_links(content, root, failures):
    for raw in LINK.findall(content):
        link = raw.strip()
        if re.match(r"^[a-z]+:", link) or link.startswith("#"):
            continue
        clean = link.strip("<>")
        if not (root / clean).exists():
            failures.append(f"missing linked reference: {link}")


def run_check(check, candidate_file, candidate_root):
    command = check["command"].format(candidate=str(candidate_file), candidate_dir=str(candidate_root))
    timeout = int(check.get("timeout", 30))
    expected = int(check.get("expected_exit", 0))
    try:
        proc = subprocess.run(
            command,
            shell=True,
            cwd=candidate_root,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired:
        return False, command, f"timed out after {timeout}s"
    output = proc.stdout[-2000:]
    if OLD_ACCOUNT in output or has_secret(output):
        return False, command, "check output contained blocked sensitive text"
    if proc.returncode != expected:
        return False, command, f"exit {proc.returncode}, expected {expected}: {output.strip()}"
    return True, command, "pass"


def validate_review_proof(proof_path, candidate_file):
    if not proof_path:
        return False, "missing review proof"
    if not Path(proof_path).exists():
        return False, f"review proof not found: {proof_path}"
    lines = read_text(candidate_file).splitlines()
    proof = read_text(proof_path).splitlines()
    checked = 0
    for raw in proof:
        match = re.match(r"\s*L(\d+):\s*(.*)\s*$", raw)
        if not match:
            continue
        number = int(match.group(1))
        quoted = match.group(2)
        if number < 1 or number > len(lines):
            return False, f"review quote line out of range: L{number}"
        if lines[number - 1].strip() != quoted.strip():
            return False, f"review quote mismatch at L{number}"
        checked += 1
    if checked == 0:
        return False, "review proof needs at least one exact 'L<number>: text' quote"
    return True, f"verified {checked} review quote(s)"


def score_candidate(label, candidate_src, target, sandbox, profile):
    candidate_dir = sandbox / "candidates" / label
    candidate_file, candidate_root = copy_target_tree(target, candidate_dir, candidate_src)
    content = read_text(candidate_file)
    failures = []
    commands = []

    if OLD_ACCOUNT in content:
        failures.append("contains old-account path")
    if has_secret(content):
        failures.append("contains secret-looking string")
    if target.name == "SKILL.md":
        fields = parse_frontmatter(content)
        if not fields:
            failures.append("missing frontmatter")
        else:
            for key in ("name", "description"):
                value = fields.get(key, "")
                if not value or "TODO" in value or "[TODO" in value:
                    failures.append(f"bad frontmatter field: {key}")
        validate_links(content, candidate_root, failures)
        if QUICK_VALIDATE.exists():
            ok, command, message = run_check(
                {
                    "command": f"{sys.executable} {QUICK_VALIDATE} {{candidate_dir}}",
                    "timeout": 30,
                    "expected_exit": 0,
                },
                candidate_file,
                candidate_root,
            )
            commands.append({"name": "quick_validate", "command": command, "ok": ok, "message": message})
            if not ok:
                failures.append(f"quick_validate failed: {message}")

    for text in profile.get("must_keep", []):
        if text not in content:
            failures.append(f"missing must_keep: {text}")
    for text in profile.get("anchors", []):
        if text not in content:
            failures.append(f"missing anchor: {text}")
    for text in profile.get("forbidden_new", []):
        if text in content:
            failures.append(f"contains forbidden_new: {text}")
    for check in profile.get("checks", []):
        ok, command, message = run_check(check, candidate_file, candidate_root)
        commands.append({"name": check.get("name", "check"), "command": command, "ok": ok, "message": message})
        if not ok:
            failures.append(f"{check.get('name', 'check')} failed: {message}")

    chars = len(content)
    return {
        "label": label,
        "file": str(candidate_file),
        "root": str(candidate_root),
        "chars": chars,
        "est_tokens": round(chars / 4, 1),
        "gate_pass": not failures,
        "failures": failures,
        "commands": commands,
    }


def choose_winner(results, baseline_chars, profile, review_label, review_ok):
    review_required = profile.get("review", {}).get("required", True)
    eligible = []
    for item in results:
        item["review"] = "not_required"
        if review_required:
            item["review"] = "pass" if item["label"] == review_label and review_ok else "pending"
        if not item["gate_pass"]:
            continue
        if review_required and item["review"] != "pass":
            continue
        if profile.get("objective", "min_chars") == "min_chars" and item["chars"] >= baseline_chars:
            item["failures"].append("not smaller than baseline")
            item["gate_pass"] = False
            continue
        eligible.append(item)
    if not eligible:
        return None
    if profile.get("objective") == "max_passes":
        return sorted(eligible, key=lambda x: (len(x["failures"]), x["chars"]))[0]
    return min(eligible, key=lambda x: x["chars"])


def write_outputs(target, sandbox, baseline_file, before_sha, after_sha, profile, results, winner, review_message):
    baseline = read_text(baseline_file)
    result_path = sandbox / "results.tsv"
    result_path.write_text(
        "candidate\tchars\test_tokens\tgate_pass\treview\tstatus\tfailures\n"
        + "\n".join(
            "\t".join(
                [
                    item["label"],
                    str(item["chars"]),
                    str(item["est_tokens"]),
                    str(item["gate_pass"]).lower(),
                    item.get("review", "pending"),
                    "winner" if winner and item["label"] == winner["label"] else ("pass" if item["gate_pass"] else "fail"),
                    "; ".join(item["failures"]),
                ]
            )
            for item in results
        )
        + "\n",
        encoding="utf-8",
    )

    winner_diff = None
    if winner:
        winner_text = read_text(winner["file"])
        diff = difflib.unified_diff(
            baseline.splitlines(keepends=True),
            winner_text.splitlines(keepends=True),
            fromfile=f"baseline/{Path(target).name}",
            tofile=f"winner/{winner['label']}",
        )
        winner_diff = sandbox / "winner.diff"
        winner_diff.write_text("".join(diff), encoding="utf-8")

    receipt = sandbox / "receipt.md"
    command_lines = []
    for item in results:
        for command in item["commands"]:
            command_lines.append(
                f"- `{item['label']}` {command['name']}: `{command['command']}` -> "
                f"{'pass' if command['ok'] else 'fail'} ({command['message']})"
            )
    receipt.write_text(
        "\n".join(
            [
                "# Verify Tournament Receipt",
                "",
                f"- target: `{target}`",
                f"- sandbox: `{sandbox}`",
                f"- profile: `{profile.get('profile', 'instructions-v1')}`",
                f"- objective: `{profile.get('objective', 'min_chars')}`",
                f"- source_sha256_before: `{before_sha}`",
                f"- source_sha256_after: `{after_sha}`",
                f"- source_unchanged: `{str(before_sha == after_sha).lower()}`",
                f"- review: `{review_message}`",
                f"- winner: `{winner['label'] if winner else 'none'}`",
                "",
                "## Results",
                "",
                result_path.read_text(encoding="utf-8"),
                "## Commands",
                "",
                "\n".join(command_lines) if command_lines else "No command checks configured.",
                "",
                "## Profile",
                "",
                "```json",
                json.dumps(profile, indent=2),
                "```",
            ]
        ),
        encoding="utf-8",
    )
    return result_path, receipt, winner_diff


def run(args):
    target = Path(args.target).resolve()
    if not target.exists():
        raise SystemExit(f"target not found: {target}")
    if OLD_ACCOUNT in str(target):
        raise SystemExit("old-account paths are blocked")
    out_root = Path(args.out).resolve() if args.out else Path(tempfile.gettempdir()).resolve()
    if not under_tmp(out_root):
        raise SystemExit("output root must be under $TMPDIR")
    stamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    sandbox = out_root / f"verify-tournament-{stamp}"
    sandbox.mkdir(parents=True)
    profile = load_profile(args)
    candidates = candidate_paths(args)
    before_sha = sha256(target)
    baseline_file, _ = copy_target_tree(target, sandbox / "baseline")
    baseline_chars = len(read_text(baseline_file))
    results = [score_candidate(label, path, target, sandbox, profile) for label, path in candidates]

    review_ok = False
    review_message = "not_required"
    if profile.get("review", {}).get("required", True):
        reviewed_file = next((r["file"] for r in results if r["label"] == args.review_pass), None)
        if not args.review_pass:
            review_message = "review_pending"
        elif not reviewed_file:
            review_message = f"review candidate not found: {args.review_pass}"
        else:
            review_ok, review_message = validate_review_proof(args.review_proof, reviewed_file)
    winner = choose_winner(results, baseline_chars, profile, args.review_pass, review_ok)
    after_sha = sha256(target)
    if before_sha != after_sha:
        winner = None
        review_message = "source changed during run"
    result_path, receipt, winner_diff = write_outputs(target, sandbox, baseline_file, before_sha, after_sha, profile, results, winner, review_message)
    summary = {
        "sandbox": str(sandbox),
        "winner": winner["label"] if winner else None,
        "results": str(result_path),
        "receipt": str(receipt),
        "winner_diff": str(winner_diff) if winner_diff else None,
        "source_unchanged": before_sha == after_sha,
    }
    print(json.dumps(summary, indent=2))
    return summary


def self_test():
    root = Path(tempfile.mkdtemp(prefix="verify-tournament-selftest-"))
    skill = root / "demo-skill"
    (skill / "references").mkdir(parents=True)
    (skill / "references" / "ref.md").write_text("reference\n", encoding="utf-8")
    baseline = """---
name: demo-skill
description: Demo skill for tournament self-test.
---

# Demo

Keep this rule.
See [ref](references/ref.md).
Extra words to trim.
"""
    (skill / "SKILL.md").write_text(baseline, encoding="utf-8")
    cand_dir = root / "candidates"
    cand_dir.mkdir()
    (cand_dir / "valid.md").write_text(baseline.replace("Extra words to trim.\n", ""), encoding="utf-8")
    (cand_dir / "missing.md").write_text(baseline.replace("Keep this rule.\n", ""), encoding="utf-8")
    (cand_dir / "bad-frontmatter.md").write_text("---\nname: demo-skill\n---\n\nKeep this rule.\n", encoding="utf-8")
    profile = root / "profile.json"
    profile.write_text(
        json.dumps(
            {
                "profile": "instructions-v1",
                "objective": "min_chars",
                "must_keep": ["Keep this rule."],
                "forbidden_new": ["auto-apply"],
                "review": {"required": False, "quote_proof": True},
            }
        ),
        encoding="utf-8",
    )
    first = subprocess.run(
        [
            sys.executable,
            __file__,
            "--target",
            str(skill / "SKILL.md"),
            "--candidate-dir",
            str(cand_dir),
            "--profile-file",
            str(profile),
            "--review-not-required",
        ],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=True,
    )
    summary = json.loads(first.stdout)
    assert summary["winner"] == "valid.md", first.stdout
    assert summary["source_unchanged"] is True, first.stdout
    first_results = read_text(summary["results"])
    assert "missing must_keep: Keep this rule." in first_results, first_results
    assert "bad frontmatter field: description" in first_results, first_results
    supplied = subprocess.run(
        [
            sys.executable,
            __file__,
            "--target",
            str(skill / "SKILL.md"),
            "--candidate",
            str(cand_dir / "valid.md"),
            "--candidate",
            str(cand_dir / "missing.md"),
            "--profile-file",
            str(profile),
            "--review-not-required",
        ],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=True,
    )
    assert json.loads(supplied.stdout)["winner"] == "valid.md", supplied.stdout
    no_win_dir = root / "no-winner"
    no_win_dir.mkdir()
    shutil.copy2(cand_dir / "missing.md", no_win_dir / "missing.md")
    shutil.copy2(cand_dir / "bad-frontmatter.md", no_win_dir / "bad-frontmatter.md")
    second = subprocess.run(
        [
            sys.executable,
            __file__,
            "--target",
            str(skill / "SKILL.md"),
            "--candidate-dir",
            str(no_win_dir),
            "--profile-file",
            str(profile),
            "--review-not-required",
        ],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=True,
    )
    assert json.loads(second.stdout)["winner"] is None, second.stdout
    print("self-test pass")


def main():
    parser = argparse.ArgumentParser(description="Run a sandboxed verification tournament.")
    parser.add_argument("--target")
    parser.add_argument("--candidate", action="append", default=[])
    parser.add_argument("--candidate-dir")
    parser.add_argument("--profile-file")
    parser.add_argument("--must-keep", action="append", default=[])
    parser.add_argument("--forbidden-new", action="append", default=[])
    parser.add_argument("--anchor", action="append", default=[])
    parser.add_argument("--objective", choices=["min_chars", "max_passes"], default="min_chars")
    parser.add_argument("--review-pass")
    parser.add_argument("--review-proof")
    parser.add_argument("--review-not-required", action="store_true")
    parser.add_argument("--out")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return
    if not args.target:
        parser.error("--target is required unless --self-test is used")
    run(args)


if __name__ == "__main__":
    main()
