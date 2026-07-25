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

## Future Candidates

| Game        | Key Concepts                                      |
|-------------|---------------------------------------------------|
| Minesweeper | Semilattice (refinement by evidence), commutativity   |
| Nim         | XOR group, self-inverse, algebra as strategy      |

### Minesweeper — Semilattice

Each revealed number is evidence about neighboring cells. Knowledge
refines monotonically: Unknown → Safe/Mine. The join of all evidence
determines what's known.

- Associative + commutative + idempotent = semilattice
- Order of reveals doesn't matter (commutative)
- Same reveal twice teaches nothing (idempotent)
- "Refinement by evidence" — the ADD book's semilattice intuition
- Deduction loop ("this says 1, one unknown neighbor, that's a mine")
  IS the join computation — the algebra is the gameplay

Progression: Ch7 Crosswords (idempotent monoid) → add commutativity →
semilattice. Natural next step.

New concept: Semilattice, commutativity as a starring property.

### Nim — XOR Group / Strategy from Algebra

Classic Nim: heaps of stones, take any number from one heap, last move wins.
Winning strategy = nim-sum (XOR of all heap sizes). If zero, you lose.

- XOR is a group where every element is its own inverse (`a XOR a = 0`)
- Extends the Group chapter (Ch6) but the algebra IS the strategy —
  find the heap that reduces nim-sum to zero
- Sprague-Grundy theorem: every impartial game reduces to Nim (teaser)

New concept: algebra as winning strategy, self-inverse elements,
combinatorial game theory.

## Reference

Inspired by [Algebra-Driven Design](https://github.com/isovector/algebra-driven-design)
by Sandy Maguire.
