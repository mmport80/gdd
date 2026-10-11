# Chapter code assessment

Scope: the Haskell example in each chapter, `code/chN/Algebra.lhs`. This
rubric judges the code only. It does not judge chapter prose, which the
author writes (see AGENTS.md).

Run the mechanical checks from the repo root:

    tools/assess_chapter_code.hs                  # all chapters
    tools/assess_chapter_code.hs 4 6              # selected chapters
    tools/assess_chapter_code.hs -h               # help

The checker is a Haskell script (`tools/assess_chapter_code.hs`). Its
shebang runs it inside `nix develop`, so GHC comes from the flake. It needs
only GHC's bundled libraries (base, process, directory, filepath). It exits
0 only when every assessed chapter passes.

## Gates (must pass, checked by the script)

G1 Runs. `runghc` exits 0 and prints output. The example is the chapter's
   demo, so an empty output is a failure.

G2 Laws hold. Every law binding (`> testN = ...`) evaluates to `True` under
   `ghc -e`. A law that evaluates to `False` is a bug in the code or in the
   claim the chapter makes about it.

G3 Sections present (chapter 4 onward). The headings Types, Algebra,
   Observations, Example, Algebraic Scorecard. Chapter 3 is reported but
   not gated, because its layout differs.

## Judged (human review, scored 0-2 each)

J1 Claims are backed. Each ✓ in the Algebraic Scorecard has a law binding
   that checks it. Each ✗ has a reason. The script reports the counts and
   warns when ✓ claims have no law bindings at all.

J2 Smart constructors. Maybe / Either appears only at the boundary (the
   `mk*` constructors and observations that can fail). Algebra operations
   are total on the chapter's type.

J3 Monoid / group structure matches the chapter's claim. Chapter 6 is
   claimed to be a group, so it needs inverses that satisfy the laws, not
   just `invert` defined.

J4 Example exercises the algebra. It composes values with the chapter's
   operation and observes the result. It does not only print hardcoded
   strings.

J5 Literate form. Code lines are prefixed with `> `. Non-code text is
   plain. Imports are at the top and needed.

J6 Minimal. No unused definitions, no helpers that the chapter does not
   use.

## Scoring

A chapter passes when all gates pass. Judged items are a 0-2 scale each,
recorded in the review of the issue or PR. A chapter at or above 8 of 12
on the judged items is ready. Anything below needs refinement.

## Current status (first run)

- ch3: runs; 9 law bindings, all True. Not gated on sections (its
  headings differ). No scorecard.
- ch4-ch7: run and pass the gates, but have no law bindings. Scorecards
  claim ✓ for ch4 (4), ch5 (3), ch6 (4), ch7 (4). No law checks back
  those claims, so J1 is unverified for these chapters until law
  bindings are added. Adding them is code work; which laws to show is
  the author's call.
