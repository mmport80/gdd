# gdd: Game Design through Code

A book that uses simple games to teach algebra-driven design, in the spirit of
Sandy Maguire's [Algebra-Driven Design](https://github.com/isovector/algebra-driven-design).
Each game introduces a few algebraic concepts (monoids, groups, semilattices)
and shows how the laws guide the code.

## Progress

Available on master:

- chapters/ch3.md: Chapter 3, Vanilla Algebra (draft)
- code/ch3: Vanilla Algebra examples (rational numbers, division by zero)
- code/ch4: Noughts & Crosses (monoids, smart constructors)
- code/ch5: Mastermind (feedback scoring)
- code/ch6: Sudoku, 4x4 (undoable moves, group-like inverses)
- code/ch7: Crosswords (partial solutions, patches)

The candidate games and their status are listed in GAMES.md.

## Development setup

The toolchain (GHC, cabal, stack) is defined in flake.nix.

1. Install Nix with flakes enabled.
2. From the repo root, run `nix develop`. This opens a shell with GHC 9.10,
   cabal-install and stack.
3. Optional: `.envrc` contains `use flake`, so direnv loads the same shell
   automatically.

Run an example from the repo root:

    nix develop --command runghc code/ch4/Algebra.lhs

The examples are literate Haskell (`.lhs`).

## Layout

- chapters/: chapter text
- code/chN/: Haskell example for chapter N (Algebra.lhs)
- GAMES.md: game ideas and status
- notes/: working notes on each game
- docs/: project plans

## Contributing

See AGENTS.md. Chapter prose is written by the author.
