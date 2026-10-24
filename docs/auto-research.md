# Auto research: iterating on a chapter's code

This is the round procedure for improving a chapter's example,
`code/chN/Algebra.lhs`. It covers only how to iterate. What the code should
be and how to write it is in docs/chapter-code-plan.md; how it is scored is
in docs/chapter-code-assessment.md. Code and tests only; prose is the
author's (see AGENTS.md and plan section 0).

## Inputs

1. docs/chapter-code-plan.md. Follow it for every round.
2. docs/chapter-code-assessment.md: gates, J1 to J6, X1 to X6, bars (J and X
   at 8 of 12).
3. `chapters/chN.md`, if present. Read it only to check the code matches the
   claim. Do not edit it.

Starting point: the current `code/chN/Algebra.lhs`, or
`code/template/Template.lhs` if the chapter has none.

## Baseline

Run the checker (plan section 9). Record gate status, law binding count and
pass/fail, and the ✓ / ✗ counts. A failing gate is a valid starting point;
the first job is to make the gates pass.

## Round loop

Each round changes one thing, with a one-line hypothesis tied to a rubric
item, for example "J1: add a law for the ✓ on inverses".

1. Write the hypothesis.
2. Make a minimal change in `code/chN/Algebra.lhs` (or a candidate file).
3. Commit the round first, on the agent branch, with the hypothesis and rubric
   item in the message. Commit even if the round will fail.
4. Judge it: run the checker, then score J1 to J6 and X1 to X6 (0, 1, or 2).
   Each score needs a reason that points to a line range.
5. Keep the round only if all gates pass and the score for the changed bar
   goes up without another item dropping by more than it gained.
6. If not kept, commit a reversal that restores the previous contents, with
   the round and reason in the message. A kept round gets no reversal.

The history is the record of attempts. Failed and reverted rounds stay in it.
Do not squash, amend, rebase, or force-push the agent branch, and do not
squash-merge these PRs.

Stop refining a candidate after three rounds in a row with no kept change.
That is a ceiling, not a plan: before the third non-improving round, check for
a local minimum (below). Length is not a goal; a shorter file that scores
lower is not kept.

## Local minima and stepping back

A stall can mean the design is the limit: every small edit the gates allow
leaves the score flat or lower, while a different design would score higher.
Do not keep polishing from inside that minimum. Before the third non-improving
round:

1. Survey the wider landscape. Re-read the rubric and `chapters/chN.md`, if
   present. Note two or three different designs (another carrier, observation,
   or monoid/group structure) that could meet both bars.
2. Check whether the design is the limit. For each weakest item, ask whether a
   small edit inside this design can fix it. If none can, the next move is a
   different design.
3. Pick the next hypothesis from that survey. The starting point may be the
   best kept version if the score has drifted.
4. Change the kind of move, not only its size: a structural edit or a
   candidate algebra. Do not repeat the same kind of edit with new wording.

A step back is not a new budget. It does not reset the stall counter; only a
kept round does. A step back that also stalls counts toward the same
three-round limit, and the next move is a candidate algebra or a stop.

## Trying a new algebra

When refinement stalls, write a second candidate with a different algebra for
the same chapter (plan section 2). Put it in
`code/chN/candidates/<short-name>.lhs`, run the same gates and scoring, keep
the better one as `Algebra.lhs`, and move or drop the other. At most three
candidates per chapter. If none meets both bars, stop and report the best one.

## Agent limits

- Judge each round against the rubric; do not invent new criteria. Length is
  not a criterion.
- Do not edit `tools/assess_chapter_code.hs` or the rubric to make a score
  pass. If the rubric seems wrong, say so in the review.
- Agent scores are a working estimate. The human scores in review are the
  record. Do not mark an item as passed on your own authority.
- Changes to ✓ / ✗ claims, headings, or other prose are the author's call;
  raise them in the review (plan section 7). Adding a law binding that checks
  an existing claim is allowed.
- Do not touch `.github/`, branch protection, or settings.

## Hand-off

Report in the PR or on the thread, in addition to the PR contents in plan
section 10:

- baseline and final checker output for each chapter touched;
- the score table (J1 to J6, X1 to X6) for baseline and final, with the reason
  for each change;
- each step back: the survey, the starting point, the hypothesis, and why a
  local minimum was suspected;
- candidate algebras tried, and why each was kept or dropped.

Stop when both bars are met, or when the round and candidate limits are
reached, whichever comes first.
