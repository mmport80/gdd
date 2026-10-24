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

New chapters start from `code/template/Template.lhs`, which has the
required headings in order and a small example that passes the gates. The
checker does not read `code/template/`.

## Gates (must pass, checked by the script)

G1 Runs. `runghc` exits 0 and prints output. The example is the chapter's
   demo, so an empty output is a failure.

G2 Laws hold. Every law binding (`> testN = ...`) evaluates to `True` under
   `ghc -e`. A law that evaluates to `False` is a bug in the code or in the
   claim the chapter makes about it.

G3 Sections present (every chapter). The headings Types, Algebra,
   Observations, Example, Algebraic Scorecard. Every chapter is gated,
   including chapter 3.

## Judged: technical (human review, scored 0-2 each)

J1 Claims are backed. Each ✓ in the Algebraic Scorecard has a law binding
   that checks it. Each ✗ has a reason. The script reports the counts and
   warns when ✓ claims have no law bindings at all.

J2 Smart constructors. Maybe / Either is only created at the boundary (the mk* constructors that convert raw input, and observations that convert results out). Algebra operations take and return the chapter's uniform carrier type, are total on it, and so compose.

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

## Judged: readability (human review, scored 0-2 each)

The code has to read on the page, not only run. These items are the X
side of the rubric. They are judged by a person and are not checked by the
script. The scale is 0 (not met), 1 (partly), 2 (fully).

Reference points for the measure (not rules in themselves): the Tweag
Haskell style guide and HaskellWiki's programming guidelines use 80
columns (HaskellWiki prefers 75); the cardano-sl style guide allows 100
when 80 forces worse structure. Typeset Haskell in books (lhs2TeX, as used
by DSLsofMath) sets code in proportional type, so a column count is a
proxy for how much fits on the page, not the page itself.

X1 Fits the page. The example reads at the book's measure without a line
   break splitting an idea. Judge by reading, not by counting: one clear
   expression at 55 columns is fine; a 45-column line packed with nested
   calls is not. Guide: up to 50 columns is comfortable; 51 to 60 is
   allowed when wrapping would split an expression the reader needs whole;
   over 60 is not, and the line must be wrapped at an operator or argument.
   Score 2 when every line is within 50 or the longer ones are justified;
   1 when a few lines pass 60 or a wrap splits an idea; 0 when many do.

X2 Names say what they mean. Types, operations and laws use names a
   reader can guess without a glossary. A name that needs a comment to
   explain it is a weak name.

X3 Layout shows structure. Blank lines and indentation separate the ideas,
   so the outline of the chapter is visible at a glance. Related
   definitions sit together.

X4 One idea at a time. Each definition does one thing and fits on a
   screen. A reader meets one new idea per step, in the order the chapter
   introduces them.

X5 Reads top to bottom. Definitions come before they are used, in the
   order the chapter explains them. The reader does not have to jump back
   and forth to follow the example.

X6 Consistent notation. The same concept has the same name and shape as
   in earlier chapters. A reader who knows one chapter can read the next
   without relearning the symbols.

## High-level goal (guidance, not scored)

The code should draw the reader in at a glance: a reader wants to keep
reading without effort. It may be expressive with little code, or terse
where the terseness is earned. Whether it is beautiful is a judgement for
the reader and the author, so no score or checklist is attached. The X
items above are the measurable side of this goal; the rest is left to
review.

## Scoring

A chapter passes when all gates pass. Judged items are scored 0-2 each,
recorded in the review of the issue or PR. Technical (J) and readability
(X) are scored separately, each out of 12, and both count toward ready:

- J: 8 of 12 or more (six items).
- X: 8 of 12 or more (six items).

A chapter is ready when it passes the gates and meets both bars. Anything
below needs refinement. The X bar is a starting point and can be changed
after the first chapters are scored.

## Current status (first run)

- ch3: runs; 9 law bindings, all True. Fails the sections gate: its
  headings differ (no Types, Observations, Example, or Algebraic
  Scorecard heading). Restructuring it is the author's call (issue #19).
- ch4-ch7: run and pass the gates, but have no law bindings. Scorecards
  claim ✓ for ch4 (4), ch5 (3), ch6 (4), ch7 (4). No law checks back
  those claims, so J1 is unverified for these chapters until law
  bindings are added. Adding them is code work; which laws to show is
  the author's call.
