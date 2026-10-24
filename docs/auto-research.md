# Auto research: iterating on a chapter's code

Scope: the Haskell example in a chapter, `code/chN/Algebra.lhs`. This
procedure is for agents. It covers code and tests only. Chapter prose is
written by the author (see AGENTS.md). If a round needs prose, say so in
the review instead of writing it.

The goal is a better example, not a faster one-shot. An agent improves an
existing `Algebra.lhs` or tries a different algebra for the same chapter,
then keeps the version that scores higher against
docs/chapter-code-assessment.md.

## Inputs to read first

1. AGENTS.md and CLAUDE.md.
2. docs/chapter-code-assessment.md: gates, J1 to J6, X1 to X6, and the
   bars (J 8 of 12, X 8 of 12).
3. The current `code/chN/Algebra.lhs`, if it exists. Otherwise start from
   `code/template/Template.lhs`.
4. The other chapters' `code/ch*/Algebra.lhs` files for names and shapes, so
   the notation matches (X6). Chapter order is not settled, so treat every
   chapter as relevant, not only the ones before or after this one.
5. `chapters/chN.md`, if present, to see what the chapter claims. Read it
   only to check that the code matches the claim. Do not edit it.

## Baseline

Run the mechanical checker from the repo root:

    tools/assess_chapter_code.hs N

Record the result for the baseline round: gate status, law binding count
and pass/fail, and the ✓ / ✗ counts in the Algebraic Scorecard. A baseline
with a failing gate is still a valid starting point. The first job is to
make the gates pass.

## Round loop

Each round changes one thing and has a stated hypothesis tied to a rubric
item, for example "J1: add a law for the ✓ on inverses".

1. Write the hypothesis in one line.
2. Make the change in `code/chN/Algebra.lhs` (or a candidate file, see
   below). Keep the change minimal and in the chapter's existing style.
3. Run `tools/assess_chapter_code.hs N`. If any gate fails, revert the
   round and try a different change.
4. Score the judged items J1 to J6 and X1 to X6 (0, 1, or 2 each). Each
   score needs a reason that points to a line range. "Looks cleaner" is not
   a reason.
5. Keep the round only if all gates pass and the total of the scored
   items for the changed bar goes up, without dropping another item by
   more than it gained. Otherwise revert.
6. Commit kept rounds on the agent branch. One commit per round, with the
   rubric item in the message. Do not commit reverted rounds.

Stop refining a candidate after three rounds in a row with no kept change.
The limit is a ceiling, not a plan: before using up the three rounds,
check whether the stall is a local minimum (see below).

## Local minima and stepping back

A stall with no kept change does not always mean the design is done. The
current version can be a local minimum: every small change that the gates
allow makes the score worse or leaves it flat, while a different design
would score higher. Do not keep polishing from inside that minimum.

Stepping back means looking at the wider landscape before the next edit,
not only at the last few rounds. Before the third non-improving round, do
these checks in order:

1. Survey the bigger picture. Re-read the rubric (J1 to J6, X1 to X6) and,
   if present, `chapters/chN.md`. Ask what a better example for this
   chapter could look like if the current design were set aside. Note two
   or three different designs (another carrier, another observation,
   another monoid or group structure) that could meet both bars.
2. Check whether the design is the limit. For each weakest scored item, ask
   whether a small edit inside this design can fix it. If none can, the
   next move is a different design, not another edit.
3. Pick the next hypothesis from that survey, even if it is not the item
   the last rounds were working on. The starting point can be the current
   version or the best kept version if the score has drifted (for example,
   earlier rounds traded J6 for J1).
4. Change the kind of move, not only its size: a structural edit (the
   carrier, the observation, the laws) or a candidate algebra. Do not
   repeat the same kind of edit with new wording.

A step back is not a new budget. Do not reset the stall counter on a step
back. Only a kept round resets it. A step back that also stalls counts
toward the same three-round limit, and the next move is a candidate
algebra or a stop.

Record each step back in the hand-off: what the survey covered, which
version was used as the starting point, the hypothesis chosen, and why the
local minimum was suspected.

## Trying a new algebra

Refinement can only polish one design. When it stalls, write a second
candidate with a different algebra for the same chapter: another monoid,
a different group structure, a different carrier, or a different
observation. Put it in its own file, for example
`code/chN/candidates/<short-name>.lhs`, and run the same gates and
scoring on it. Keep the better candidate as `Algebra.lhs` and move the
other to the candidates directory or drop it. Note the comparison in the
review.

At most three candidates per chapter. If none reaches both bars, stop and
report the best one with its scores.

## What counts as improvement

- A gate going from fail to pass is the largest gain.
- A new law binding that is True and backs a ✓ improves J1.
- Removing a Maybe or Either from an operation that is total on the type
  improves J2. Keep it at the boundary.
- Wrapping an over-long line at an operator, or renaming a name that
  needs a comment, improves X1 or X2. Do not rename across chapters
  without checking X6.
- Deleting unused definitions improves J6.

Length is not a goal. A shorter file that scores lower is not kept.

## Limits

- Do not change the wording of headings, the Scorecard text, or any
  other prose in the `.lhs` file. Changing a ✓ or ✗ claim is the
  author's call: raise it in the review. Adding a law binding that checks
  an existing claim is allowed.
- Do not edit `tools/assess_chapter_code.hs` or the rubric to make a
  score pass. If the rubric seems wrong, say so in the review.
- Scores from an agent are a working estimate. The human scores in
  review are the record. Agents must not mark an item as passed on the
  rubric on their own authority.
- Do not touch `.github/`, branch protection, or settings.

## Hand-off

When stopping, report in the PR or thread:

- the baseline and final checker output for each chapter touched;
- the score table (J1 to J6, X1 to X6) for the baseline and the final
  version, with the reason for each change;
- any candidate algebras tried and why they were kept or dropped;
- open questions for the author, especially any ✓ or ✗ that needs a
  wording change.

Stop when both bars are met, or when the round and candidate limits are
reached, whichever comes first.
