# Game Candidates: Factors, Long List, Ranking

Working document for issue #5. Iterative: scores are a first pass and
the author should adjust weights and entries. Nothing here is chapter prose.

## 1. What makes a game a good chapter

Hard requirements (a candidate fails if any is missing):

- H1. Text/CLI playable. No real-time input, graphics, or sound.
- H2. Rules explainable in one short paragraph.
- H3. The game state and moves map onto a small algebraic structure
  (monoid, group, semilattice, lattice, vector space, functor-like
  composition, ...) whose laws the code must satisfy.
- H4. Implementable in a few hundred lines of Haskell, with no large
  dependencies.

Scored factors (1 to 5 each, 5 is best):

- A. Algebra depth: the laws are non-trivial and they actually drive the
  design (not decoration).
- N. Novelty: teaches a concept not already covered by Ch4 to Ch7 or the
  planned Minesweeper/Nim entries. Overlap with Mastermind, Sudoku, or
  Crosswords lowers this.
- S. Scope: small code footprint (5 = very small).
- R. Rules simplicity for the reader (5 = trivial rules).
- P. Payoff: is it fun to play, with real decisions or a satisfying puzzle.
- F. Progression fit: builds naturally on the previous chapter, or
  opens a clear next step.

Weighted score = 2A + 2N + S + R + P + F (max 30). A and N are doubled
because the book's purpose is algebra-driven design and new concepts.
Weights are a judgement call; change them here if you disagree.

Automatic flags (not scored, but noted in the table):

- Needs search to be interesting (AI is a chapter of its own).
- Uses a dictionary or external data.
- Trademarked name (use a generic name in the chapter).

## 2. Long list

Scores are A N S R P F; Total is the weighted score. Rows are roughly
sorted by total; Section 3 is the ranking.

| Game                        | A N S R P F | Total | Core algebra / concept                                  |
|-----------------------------|-------------|-------|---------------------------------------------------------|
| 2x2 pocket cube             | 5 5 3 4 5 4 | 36    | Permutation group, generators, inverses, commutators    |
| Rock-Paper-Scissors family  | 5 4 5 5 3 2 | 33    | Cyclic group Z_n, tournament as group action (small)    |
| Lights Out                  | 5 4 5 4 3 4 | 34    | Vector space over GF(2), solving as linear algebra      |
| Hackenbush                  | 5 5 3 3 3 3 | 32    | Surreal numbers from game trees (advanced)              |
| Ultimate Tic-Tac-Toe        | 4 4 3 4 4 5 | 32    | Nested games: product/composition of Ch4 monoid         |
| 2048                        | 4 4 3 5 4 4 | 32    | Monoid of row/board moves, non-commutative composition  |
| Hex                         | 3 4 4 5 5 3 | 31    | Union-find, join of components, no draws                |
| 15-puzzle (sliding tiles)   | 5 2 4 5 4 3 | 30    | Permutation group, parity invariant, undo as inverse    |
| Chomp                       | 4 3 5 5 3 3 | 30    | Poset of divisors, combinatorial game theory            |
| Kayles                      | 4 3 5 5 3 3 | 30    | Sprague-Grundy values (overlaps Nim, so N=3)            |
| Tetris                      | 4 4 2 4 5 3 | 30    | Rotation group Z4, shape algebra, line-clear as filter  |
| Hangman                     | 3 3 5 5 3 4 | 29    | Semilattice of guesses (simpler precursor to Minesweeper)|
| Blokus                      | 4 4 3 3 4 3 | 29    | Dihedral group D4 action on polyominoes                 |
| Peg solitaire               | 4 3 4 5 3 3 | 29    | Invariants (colouring/parity), reachability             |
| Game of Life                | 4 3 5 5 3 2 | 29    | Endofunctions, monoid of transforms (toy, no choices)   |
| Battleship                  | 3 3 4 5 4 3 | 28    | Knowledge refinement (overlaps Minesweeper)             |
| Sprouts                     | 3 4 3 4 3 3 | 27    | Graph invariants (Euler characteristic)                 |
| Nonograms                   | 3 3 3 5 4 3 | 27    | Line constraints, partial solutions (overlaps Sudoku)   |
| Word ladder                 | 3 3 5 5 3 2 | 27    | Graph, paths; needs word list (flag)                    |
| Mancala / Kalah             | 3 3 3 4 4 3 | 26    | Sowing as cyclic indexing Z/n                           |
| Yahtzee                     | 3 3 3 4 4 3 | 26    | Scoring as commutative monoid over categories           |
| Sokoban                     | 3 3 3 4 4 3 | 26    | State graph, undo, reversible moves                     |
| Dots and Boxes             | 3 3 3 4 4 3 | 26    | Combinatorial game theory (overlaps Nim/Kayles)         |
| Connect Four                | 2 2 4 5 5 3 | 25    | Win detection; little algebra beyond Ch4                |
| Blackjack scoring           | 3 2 4 5 4 2 | 25    | Hand value as monoid with soft-ace (min,max) pairs      |
| Simon Says                  | 3 2 5 5 3 2 | 25    | Free monoid of sequences (list append)                  |
| Bulls and Cows              | 2 1 5 5 4 2 | 22    | Near-duplicate of Mastermind (excluded)                 |
| Klondike solitaire          | 3 3 2 4 4 2 | 24    | Deck permutations, shuffling (flag: randomness)         |
| Tower of Hanoi              | 3 2 5 5 2 2 | 24    | Recursion, group of moves (teaser)                      |
| KenKen                      | 4 2 3 4 3 2 | 24    | Latin squares (overlaps Sudoku)                         |
| Pig (dice)                  | 2 2 5 5 3 2 | 23    | Expected-value monoid; needs probability (flag)         |
| Cribbage                    | 2 2 4 3 3 2 | 20    | Mod-31 counting; scoring rules heavy                    |
| Snakes & Ladders            | 2 1 5 5 2 1 | 19    | No decisions; dynamics only (weak fit)                  |

Excluded from the table: Go, Chess, Shogi (scope too large for one chapter),
Mahjong and Scrabble (large data or rules), Go Fish (too trivial).

## 3. Ranking (first pass)

Tiers reflect the score plus the hard requirements. A candidate with a
high score that breaks H1 to H4 is not in the top tier.

Tier 1, strong chapter candidates:

1. 2x2 pocket cube (36). Clearest group in the list. Needs a solver,
   which is the main scope risk. Use a generic name in the text.
2. Lights Out (34). Linear algebra over GF(2). Solving is Gaussian
   elimination. Strong self-inverse theme (mirrors the undo theme of Ch6).
3. Ultimate Tic-Tac-Toe (32). Direct sequel to Ch4 Noughts & Crosses.
   Shows algebra composing across levels of structure.
4. Hex (31). Union-find and a connectivity join. Determinacy (no draws).
5. 2048 (32). Non-commutative move monoid. Good for showing when laws
   fail to commute.

Tier 2, good but needs a choice:

6. 15-puzzle (30). Permutation group with a parity invariant. Overlaps
   the 2x2 cube, so pick one. Prefer the 2x2 cube unless the author
   wants sliding tiles.
7. Chomp or Kayles (30). Game theory; partly overlaps the planned Nim.
   Pick one as the Nim sequel.
8. Hangman (29). Simple semilattice. Could be a short precursor to the
   Minesweeper chapter.
9. Blokus (29). D4 symmetry is attractive but the game has many rules.

Tier 3, teasers or weak fit: everything at 28 and below. Hackenbush
(32) is ranked high on algebra but is advanced; treat it as a future
appendix, not a main chapter, unless the author wants surreals.

Rock-Paper-Scissors family (33) scores highly on the rubric but is
too thin to be a chapter on its own. Use it as a worked example inside
the group chapter.

## 4. Open questions for the author

- Should the rubric weight algebra over fun, or the reverse?
- Is one chapter per game still the target, or can a chapter cover two
  games (for example Hangman plus Minesweeper)?
- Is a "solver" acceptable scope for the 2x2 cube and Lights Out, or
  should those be deferred?
- Should the Hackenbush / surreal material be an appendix?

## 5. Next iteration

- Verify each Tier 1 candidate with a short prototype (code only, under
  code/ as a throwaway) to check scope estimates.
- Adjust the weights after the author responds.
- Keep this file as the source of truth; GAMES.md links here.
