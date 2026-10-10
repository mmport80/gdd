#!/usr/bin/env python3
"""Assess the Haskell example in each chapter (code/chN/Algebra.lhs).

Mechanical checks only; the judgment criteria are in
docs/chapter-code-assessment.md.

Checks per chapter:
  run        runghc exits 0 and prints something (gate)
  sections   required headings are present (gate for ch4+; ch3 is reported)
  laws       every law binding (`> testN = ...`) evaluates to True (gate)
  scorecard  number of ✓ / ✗ rows in "Algebraic Scorecard" and whether any
             machine-checked law backs them (warning if ✓ rows exist and
             there are no law bindings at all)

Usage (from repo root):
  python3 tools/assess_chapter_code.py                 # all chapters
  python3 tools/assess_chapter_code.py 4 6             # selected chapters
  python3 tools/assess_chapter_code.py --json

Toolchain: runs commands through RUN_PREFIX (default "nix develop --command").
Set --run-prefix "" when already inside `nix develop`.
"""

import argparse
import glob
import json
import os
import re
import subprocess
import sys

REQUIRED_HEADINGS = ["Types", "Algebra", "Observations", "Example", "Algebraic Scorecard"]
LAW_BINDING = re.compile(r"^> (test\w*)\s*=")
SCORE_ROW = re.compile(r"^\s+(\S[^✓✗]*?)\s+([✓✗])")
RUN_TIMEOUT = 300


def repo_root():
    here = os.path.dirname(os.path.abspath(__file__))
    return os.path.dirname(here)


def shell(cmd_list, prefix, cwd):
    """Run a command, optionally wrapped by the toolchain prefix."""
    full = (prefix.split() if prefix else []) + cmd_list
    return subprocess.run(full, cwd=cwd, capture_output=True, text=True, timeout=RUN_TIMEOUT)


def check_run(path, prefix, root):
    try:
        p = shell(["runghc", path], prefix, root)
    except subprocess.TimeoutExpired:
        return {"ok": False, "detail": "timeout"}
    out = p.stdout.strip()
    ok = p.returncode == 0 and bool(out)
    detail = "exit %d, %d output lines" % (p.returncode, len(out.splitlines()))
    if p.returncode != 0:
        detail += "; stderr: " + (p.stderr.strip().splitlines() or [""])[-1]
    return {"ok": ok, "detail": detail}


def check_sections(text, chapter):
    missing = []
    for h in REQUIRED_HEADINGS:
        if not re.search(r"^" + re.escape(h) + r"\s*$", text, re.MULTILINE):
            missing.append(h)
    ok = not missing
    return {"ok": ok, "missing": missing, "required_for_gate": int(chapter) >= 4}


def check_laws(text, path, prefix, root):
    names = []
    for line in text.splitlines():
        m = LAW_BINDING.match(line)
        if m and m.group(1) not in names:
            names.append(m.group(1))
    if not names:
        return {"ok": True, "count": 0, "failed": [], "detail": "no law bindings"}
    expr = "mapM_ (\\(n, v) -> putStrLn (n ++ \" \" ++ show v)) [%s]" % ", ".join(
        '("%s", %s)' % (n, n) for n in names
    )
    try:
        p = shell(["ghc", "-v0", "-e", expr, path], prefix, root)
    except subprocess.TimeoutExpired:
        return {"ok": False, "count": len(names), "failed": names, "detail": "timeout"}
    if p.returncode != 0:
        return {"ok": False, "count": len(names), "failed": names,
                "detail": "ghc -e failed: " + (p.stderr.strip().splitlines() or [""])[-1]}
    results = {}
    for line in p.stdout.splitlines():
        parts = line.split(" ", 1)
        if len(parts) == 2:
            results[parts[0]] = parts[1].strip()
    failed = [n for n in names if results.get(n) != "True"]
    return {"ok": not failed, "count": len(names), "failed": failed,
            "detail": "%d/%d laws True" % (len(names) - len(failed), len(names))}


def check_scorecard(text, law_count):
    idx = text.find("Algebraic Scorecard")
    if idx < 0:
        return {"ok": False, "holds": 0, "fails": 0, "warning": "no scorecard"}
    rows = [SCORE_ROW.match(l) for l in text[idx:].splitlines()]
    rows = [r for r in rows if r]
    holds = sum(1 for r in rows if r.group(2) == "✓")
    fails = sum(1 for r in rows if r.group(2) == "✗")
    warning = None
    if holds and law_count == 0:
        warning = "%d ✓ claims but no machine-checked law bindings" % holds
    return {"ok": True, "holds": holds, "fails": fails, "warning": warning}


def assess(chapter, prefix, root):
    path = os.path.join("code", "ch%s" % chapter, "Algebra.lhs")
    with open(os.path.join(root, path), encoding="utf-8") as f:
        text = f.read()
    run = check_run(path, prefix, root)
    sections = check_sections(text, chapter)
    laws = check_laws(text, path, prefix, root)
    score = check_scorecard(text, laws["count"])
    gates_ok = run["ok"] and laws["ok"] and (sections["ok"] or not sections["required_for_gate"])
    return {"chapter": int(chapter), "path": path, "pass": gates_ok,
            "run": run, "sections": sections, "laws": laws, "scorecard": score}


def print_report(results):
    for r in results:
        status = "PASS" if r["pass"] else "FAIL"
        print("ch%d  %s  %s" % (r["chapter"], status, r["path"]))
        print("  run:       %s" % ("ok" if r["run"]["ok"] else "FAIL") + " (" + r["run"]["detail"] + ")")
        s = r["sections"]
        if s["missing"]:
            note = "" if s["required_for_gate"] else " (not gated before ch4)"
            print("  sections:  missing " + ", ".join(s["missing"]) + note)
        else:
            print("  sections:  ok")
        L = r["laws"]
        print("  laws:      %s%s" % (L["detail"], (" FAILED: " + ", ".join(L["failed"])) if L["failed"] else ""))
        sc = r["scorecard"]
        print("  scorecard: %d ✓, %d ✗" % (sc["holds"], sc["fails"]))
        if sc.get("warning"):
            print("  warning:   " + sc["warning"])
        print()
    passed = sum(1 for r in results if r["pass"])
    print("%d/%d chapters pass the gates" % (passed, len(results)))


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("chapters", nargs="*", help="chapter numbers (default: all code/chN)")
    ap.add_argument("--run-prefix", default="nix develop --command",
                    help='command prefix for runghc/ghc; "" if already in nix develop')
    ap.add_argument("--json", action="store_true", help="emit JSON instead of text")
    args = ap.parse_args(argv)

    root = repo_root()
    chapters = args.chapters or sorted(
        m.group(1)
        for m in (re.search(r"ch(\d+)$", d) for d in glob.glob(os.path.join(root, "code", "ch*")))
        if m and os.path.isfile(os.path.join(root, "code", "ch" + m.group(1), "Algebra.lhs"))
    )
    results = [assess(c, args.run_prefix, root) for c in chapters]
    if args.json:
        print(json.dumps(results, indent=2, ensure_ascii=False))
    else:
        print_report(results)
    return 0 if all(r["pass"] for r in results) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
