# Game Ideas

Games to build as chapters, each teaching different algebraic/functional concepts.

## Candidates

| Game              | Status  | Key Concepts                              |
|-------------------|---------|-------------------------------------------|
| Noughts & Crosses | Done    | Monoids, smart constructors (Ch4)         |
| Mastermind        | —       | Feedback as a monoid, secret vs guess     |
| Sudoku            | —       | Constraint propagation, 2D grids, backtracking |
| Crosswords        | —       | Adjacency, overlapping, layout algebra    |

## Concept Pairs (brainstorm)

- **Mastermind** — feedback scoring (correct position + correct colour),
  separation of secret vs guess, Maybe/Either for invalid inputs
- **Sudoku** — rows/columns/boxes as sets, constraint checking,
  recursive solving, Maybe for unsolvable states
- **Crosswords** — grid layout, word placement, intersection rules,
  validation that all crossings are real words
- **Noughts & Crosses** — already built, could extend with AI/opponent

## Reference

Inspired by [Algebra-Driven Design](https://github.com/isovector/algebra-driven-design)
by Sandy Maguire.
