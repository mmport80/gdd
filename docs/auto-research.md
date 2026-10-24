# Auto research: iterating on a chapter's code

This is the round procedure for improving a chapter's example,
`code/chN/Algebra.lhs`. It covers only how to iterate. What the code should
be and how to write it is in docs/chapter-code-plan.md; how it is scored is
in docs/chapter-code-assessment.md. Code and tests only; prose is the
author's (see AGENTS.md and plan section 0).

## Inputs

1. docs/chapter-code-plan.md. Follow it for every round.
2. docs/chapter-code-assessment.md: gates, J1 to J6, X1 to X6, and the
   points scale (J and X, each out of 12; higher is better).
3. `chapters/chN.md`, if present. Read it only to check the code matches the
   claim. Do not edit it.

Starting point: the current `code/chN/Algebra.lhs`. If the chapter has none,
copy `code/template/Template.lhs` or go to Round 0.

## Baseline

Run the checker (plan section 9). Record gate status, law binding count and
pass/fail, and the ✓ / ✗ counts. A failing gate is a valid starting point;
the first job is to make the gates pass. If there is no `Algebra.lhs`, there
is no baseline to run; go to Round 0.

## Round 0 (no algebra yet)

Write `code/chN/Algebra.lhs` de novo from plan sections 2 to 6 and the chapter
claim. Commit it as round 0 with the hypothesis "baseline draft scores high
on J and X", then judge it as usual. From round 1 on, a kept round must pass
the gates and raise the points of the items it names.

## Round loop

Each round is one move (below), with a one-line hypothesis naming the rubric
item or items it targets, for example "J1: add a law for the ✓ on inverses".

Move kinds:

- small edit: a law, an example line, a renamed or removed helper;
- structural edit: changes to the types, the carrier, or the operations;
- new algebra: a candidate file (see "Trying a new algebra");
- multi-item edit: one change aimed at several named items.

Choose the kind from the weakest items and the landscape. Do not repeat the
same kind of move with new wording.

1. Write the hypothesis.
2. Make the move in `code/chN/Algebra.lhs` (or a candidate file).
3. Commit the round first, on the agent branch, with the hypothesis and rubric
   item in the message. Commit even if the round will fail. Format:
   `round N (ITEM): hypothesis`, for example `round 3 (X1): wrap code lines
   over 60 columns`.
4. Judge it: run the checker, then score J1 to J6 and X1 to X6 (0, 1, or 2).
   Each score needs a reason that points to a line range.
5. Keep the round only if all gates pass, the score of the items it names goes
   up (summed), and no item it does not name drops.
6. If not kept, commit a reversal that restores the previous contents. Format:
   `revert round N (ITEM): not kept, reason`, with a line saying which round's
   contents are restored. A kept round gets no reversal.

The history is the record of attempts. Failed and reverted rounds stay in it.
Do not squash, amend, rebase, or force-push the agent branch, and do not
squash-merge these PRs.

Stop refining a candidate after three rounds in a row with no kept change.
That is a ceiling, not a plan: before the third non-improving round, check for
a local minimum (below). Length is not a goal; a shorter file that scores
lower is not kept.

A kept round does not end the run. After a kept round, keep going with the
next hypothesis until a stop rule in Hand-off applies. Reaching a score that
looks good enough is not a stop rule.

## Local minima and stepping back

A stall can mean the design is the limit: every small edit the gates allow
leaves the score flat or lower, while a different design would score higher.
Do not keep polishing from inside that minimum. Before the third non-improving
round:

1. Survey the wider landscape. Re-read the rubric and `chapters/chN.md`, if
   present. Note two or three different designs (another carrier, observation,
   or monoid/group structure) that could score higher on J and X.
2. Check whether the design is the limit. For each weakest item, ask whether a
   small edit inside this design can fix it. If none can, the next move is a
   different design.
3. Pick the next hypothesis from that survey. The starting point may be the
   best kept version if the score has drifted.
4. Change the kind of move, not only its size: a structural edit, a
   multi-item edit, or a candidate algebra. Do not repeat the same kind of edit
   with new wording.

The survey may conclude that the design is the limit. A step back to a
substantially different design is a new candidate file, not an edit to
`Algebra.lhs`, so the current design stays comparable (see below).

A step back is not a new budget. It does not reset the stall counter; only a
kept round does. A step back that also stalls counts toward the same
three-round limit, and the next move is a candidate algebra or a stop.

## Trying a new algebra

When refinement stalls, or a step back calls for a substantially different
design, write a second candidate with a different algebra for the same
chapter (plan section 2). Put it in
`code/chN/candidates/<short-name>.lhs`, run the same gates and scoring, keep
the better one as `Algebra.lhs`, and move or drop the other. At most three
candidates per chapter. If no candidate scores higher on J and X than the
current file, keep the current file and report it.

## Agent limits

- Judge each round against the rubric; do not invent new criteria. Length is
  not a criterion.
- Do not edit `tools/assess_chapter_code.hs` or the rubric to make a score
  pass. If the rubric seems wrong, say so in the review.
- Agent scores are a working estimate. The human scores in review are the
  record. Do not mark an item as passed on your own authority.
- Do not add prose lines to `Algebra.lhs`, not even one sentence to explain a
  line. If a sentence seems needed, put it in the PR as a suggestion.
- Changes to ✓ / ✗ claims, headings, or other prose are the author's call;
  raise them in the review (plan section 7). Adding a law binding that checks
  an existing claim is allowed.
- Do not touch `.github/`, branch protection, or settings.

## Hand-off

Stop at the first of these:

- three non-improving rounds in a row, after the local-minimum check;
- three candidates used for the chapter;
- the owner tells you to stop.

This document sets no total round cap.

The PR description follows plan section 10. Per-round hypotheses, score
reasons, step backs, and candidate decisions are in the commit history, so do
not repeat them in the PR. The only addition is which stop rule ended the
run, and the final J and X points.
