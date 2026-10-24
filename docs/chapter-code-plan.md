# Chapter code plan (generic, for writing code/chN/Algebra.lhs)

## Goal (the book, in one paragraph)

The book is the goal. Each chapter's code is a small, rough part of it.
The book's elevator pitch, from README.md: "A book that uses simple games
to teach algebra-driven design, in the spirit of Sandy Maguire's
Algebra-Driven Design. Each game introduces a few algebraic concepts
(monoids, groups, semilattices) and shows how the laws guide the code."

The pitch wording is the author's. Before writing a chapter, read this
paragraph and the chapter's game in GAMES.md, and check that the code
serves the pitch: the algebra should be the thing that guides the design.
If the pitch and the game disagree, flag it in the PR; do not resolve it
in code.

Purpose: one plan that a model (or a person) follows to write the Haskell
example for a new chapter. It covers code only. Chapter prose, narrative,
headings text, and the content of the Algebraic Scorecard claims are the
author's (see AGENTS.md). Where this plan touches those, it says so.

Inputs: one game from GAMES.md (the chapter's game). Everything else below
is the existing material to reuse.

## 0. Ground rules

- Work on a branch from the latest master. One game per chapter, one PR.
- Output is code/chN/Algebra.lhs, a literate Haskell file. Optional extra
  files are only for tests or tooling that the chapter needs.
- Do not write chapter prose. Do not edit chapters/*.md. If a heading or
  sentence is needed, keep the template text and flag it in the PR.
- Do not edit tools/assess_chapter_code.hs or the rubric unless the task
  says so.

## 1. Read the material first

Read these in order. Each has a specific use.

1. GAMES.md and docs/game-candidates.md. Find the game's row, its key
   concepts, and the algebraic structure it teaches (monoid, group,
   semilattice, ...). The game's entry names the laws the chapter should
   show.
2. notes/<game>-claude-chat.md, if it exists. Use it for the rules and the
   design decisions already discussed. Do not copy its prose into the
   chapter. Use the types and operations it settled on.
3. code/template/Template.lhs. Start from it. It has the required headings
   in order, a small example, and law bindings that pass the gates. It is
   a template, not a checked chapter: the checker does not read it.
4. docs/chapter-code-assessment.md. This is the rubric. Its gates (G1 to
   G3) and judged items (J1 to J6, X1 to X6) are the target. Read J1 and
   X1 before writing.
5. All available chapter code (every code/ch*/Algebra.lhs that exists),
   for inspiration and guidance. Read each one for notation, style, and
   structure. Reuse names and shapes that already exist (Position, Cell,
   Delta, mkDelta, project, the Semigroup/Monoid instance pattern) so the
   reader sees the same notation (X6).
6. tools/assess_chapter_code.hs. Its checks are the mechanical gates.

Note the state of the existing code. ch4 to ch7 pass the gates, but have
no law bindings, so their scorecard claims (J1) are unverified. Do not
copy that pattern. Every ✓ needs a `> testN = ...` binding.

## 2. Pick the algebra and write the types

- Name the algebraic structure the chapter teaches, in one line. Focus on
  a simple, high-quality algebra first (a monoid, a semilattice, a small
  group, ...), and do not force the game to fit a structure. If the
  game's entry names a structure that fits, use it; if not, pick the
  simple algebra that is clearest and note the mismatch in the PR. The
  author weaves each chapter into the book's narrative later. The code
  must satisfy the laws it names.
- Write the types first, with the smallest set of constructors. Use the
  same name for the same concept as earlier chapters.
- Make invalid states unrepresentable where the rules allow it. Hide raw
  constructors behind `mk*` smart constructors that return Maybe or
  Either.
- The chapter fixes one carrier type. Operations take and return that
  carrier and are total on it, so they compose. The carrier may itself be
  Maybe or Either (e.g. Maybe Rational, as in ch3); a Nothing is then a
  normal carrier value (J2). This rule does not require existing chapters
  such as ch3 to change.
- Operations on the chapter's type must be total.

## 3. Write the algebra

- Give the Semigroup and Monoid instances (or the group operations) with
  the same shape as Template.lhs.
- For a group claim, define the inverse and check it against the laws
  (J3). Defining `invert` alone is not enough.
- Keep each operation to one idea (X4). If a definition needs two ideas,
  split it.

## 4. Write observations

- Observations are pure functions that read the state: winners, scores,
  availability, validity. Keep them total. An observation that can fail
  returns Maybe or Either (J2).
- Each observation a reader needs for the example gets a short, plain name
  (X2).

## 5. Write the example

- The example is the chapter's demo. It must print output (G1).
- It composes values with the chapter's operation and observes the result.
  It does not print hardcoded strings (J4).
- Keep the example in one place, `example :: IO ()`, with `main = example`.

## 6. Write the law bindings

- Add one `> testN = ...` per law the scorecard will claim. Each law is an
  expression that evaluates to Bool. The checker runs them through
  `ghc -e` and each must print True (G2).
- The scorecard marks each algebraic property as ✓ or ✗. ✓ means the
  algebra has the property, so bind a law that checks it. ✗ means the
  algebra does not have the property (e.g. order matters, so it is not
  commutative). A law that would be false cannot be bound, so a ✗ gets no
  law. Instead, write a short reason: why the property fails here and,
  where possible, a small concrete counterexample (two inputs whose
  results differ).
- Law bindings are code. Which laws to show is the author's call. If it is
  unclear, list the candidate laws in the PR description and let the
  author pick.

## 7. Scorecard and headings

- Keep the five required headings, exactly as spelled, in this order:
  Types, Algebra, Observations, Example, Algebraic Scorecard (G3).
- The scorecard rows (✓ / ✗ with a short reason) are a draft. Put the
  draft in the PR description. The author writes the final text.
- Do not add other top-level headings the gates do not need.

## 8. Literate form and minimality

- Code lines start with `> `. Other lines are plain text (J5).
- Imports go at the top, and each one is used.
- Remove any definition the chapter does not use (J6).
- Lines up to 50 columns are the target. Lines over 60 are wrapped at an
  operator or an argument (X1). Do not hide an idea by splitting it.
- One definition per idea, short enough to read on one screen (X4).
- Definitions come before use, in the order the chapter explains them
  (X5). Related definitions sit together with blank lines between them
  (X3).

## 9. Run and check

From the repo root, inside the dev shell:

    nix develop --command runghc code/chN/Algebra.lhs
    tools/assess_chapter_code.hs N

Use the README form (`nix develop --command runghc`). The template's
shebang uses `nix shell nixpkgs#ghc ... runhaskell`. That is a known
difference, not a reason to change the template in this task.

Pass criteria before opening the PR:

- runghc exits 0 and prints output (G1).
- assess_chapter_code.hs N reports every gate as passed (G2, G3).
- The scorecard's ✓ rows each have a law binding, or the PR says why not.
- Check X1 by reading the longest lines of the file, not by a column count
  alone.

## 10. Hand-off

PR contents:

- code/chN/Algebra.lhs (and tests or tooling if the chapter needs them).
- GAMES.md: update the game's Status column in the same PR.
- The PR description: the algebra chosen, the laws bound, the checker
  output, the draft scorecard, and any open question for the author (for
  example, which laws to show, or a heading that differs from the
  template).

Do not edit README.md progress lists or chapters/*.md in this PR unless the
author asks. Those are the author's text.

## 11. Known open points

- The template and README use different toolchain shebangs (see step 9).
- ch3 does not have the required headings (issue #19, author's call).
- ch4 to ch7 lack law bindings, so J1 is unverified for them. Adding them
  is code work, and it can be its own PR per chapter.
- There is no J or X threshold. Points out of 12 are reported as they are
  (docs/chapter-code-assessment.md, Scoring).
