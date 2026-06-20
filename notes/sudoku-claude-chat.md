# Sudoku — Claude discussion notes

Source: https://claude.ai/share/ (pasted from /tmp/suduko.txt)
Date: 2-3 Apr 2026

---

## Type

Two framings considered:

```haskell
-- Framing 1: explicit grid
type Cell = Maybe Digit      -- Nothing = empty
type Board = Grid Cell       -- 9x9

-- Framing 2: only filled cells (preferred)
type Pos = (Row, Col)        -- (0..8, 0..8)
type Board = Map Pos Digit   -- only filled cells, empty board = Map.empty
```

## What does a player do?

Key grounding question — user had never played Sudoku.

Pen-and-paper solving:
- Scan row/col/box, find missing digits
- Find a cell where only one digit can go
- Place it, repeat

Two layers emerge:
| Layer | What it is | Direction |
|-------|-----------|-----------|
| Committed board (pen) | placed digits | only grows |
| Candidates (pencil) | possible digits per cell | only shrinks |

Pencil marks = "this number is still possible for this cell" — track uncertainty, not mistakes.
Candidate sets only shrink (monotone), never grow back.

```haskell
type Candidates = Set Digit       -- starts as {1..9}
eliminate :: Digit -> Candidates -> Candidates   -- only shrinks
```

## The two layers move in opposite directions

- Committed board grows monotonically (place)
- Candidate sets shrink monotonically (eliminate)
- They meet when a candidate set hits size 1 — that's the commit moment

## Undo / inversion — the key insight

User: "pencil is like an undo, which means we should have an inversion property"

This was initially explored for pencil marks, but the real inversion lives in the committed board:
- One player game → undo is natural, not cheating
- Undo as inversion → group rather than monoid
- Genuine upgrade on the X's and O's story (monoid → group)

## Simplifying to 4x4 variant

4x4 Sudoku (digits 1-4, four 2x2 boxes) preserves all interesting structure:
- Same row/col/box constraints
- Same candidate elimination
- Same try-and-backtrack strategy
- Small enough to reason about concretely

## Smart constructor pattern (same as X's and O's)

Push Maybe to the boundary — mkDelta checks all constraints, then place/undo are total.

```haskell
data Digit = One | Two | Three | Four

data Cell
  = Empty
  | Clue   Digit    -- given at start, untouchable
  | Placed Digit    -- our move, can be undone/replaced

type Pos   = (Int, Int)   -- (0..3, 0..3)
type Board = Map Pos Cell

-- Opaque — only mkDelta can create one
newtype Delta = Delta (Pos, Digit)

-- Smart constructor — all constraints checked here
mkDelta :: Board -> Pos -> Digit -> Maybe Delta
mkDelta board pos digit = case Map.lookup pos board of
  Just (Clue _)   -> Nothing   -- can't touch clues
  Just (Placed _) -> Nothing   -- must undo first
  Just Empty      -> checkConstraints board pos digit
  Nothing         -> checkConstraints board pos digit

checkConstraints :: Board -> Pos -> Digit -> Maybe Delta
checkConstraints board pos digit
  | digitInRow board pos digit = Nothing
  | digitInCol board pos digit = Nothing
  | digitInBox board pos digit = Nothing
  | otherwise                  = Just (Delta (pos, digit))

-- All three operations total
place   :: Board -> Delta -> Board
undo    :: Board -> Delta -> Board
replace :: Board -> Delta -> Delta -> Board
replace board old new = place (undo board old) new
```

Key points:
- `replace` isn't a primitive — it's just `undo` then `place`
- `Clue` vs `Placed` distinction lives in the type
- `mkDelta` rejecting `Placed` cells forces explicit undo first
- Group laws hold cleanly for `Placed` cells; `Clue` cells are outside the algebra

## Group typeclass (not in Haskell base)

```haskell
class Monoid g => Group g where
    invert :: g -> g

-- Derived
(~~) :: Group g => g -> g -> g
a ~~ b = a <> invert b    -- "subtract" / remove b from a
```

Hierarchy: Semigroup (<>), Monoid (<> + mempty), Group (<> + mempty + invert)

## Event sourcing: Group lives on History, not Board

Key realization: inverting a whole board doesn't make sense. The group structure lives on the delta history.

```haskell
data DeltaOp = Place Digit | Remove Digit
newtype Delta = Delta (Pos, DeltaOp)

type History = [Delta]

-- Board is just a fold over history
toBoard :: History -> Board
toBoard = foldl applyDelta emptyBoard

instance Semigroup History where
    (<>) = (++)

instance Monoid History where
    mempty = []

instance Group History where
    invert = reverse . map invertDelta

invertDelta :: Delta -> Delta
invertDelta (Delta (pos, Place d)) = Delta (pos, Remove d)
invertDelta (Delta (pos, Remove d)) = Delta (pos, Place d)
```

Note: `Remove` needs to remember what digit it's removing to be invertible.

### Group laws

```haskell
h <> mempty      = h          -- identity
h <> invert h    = mempty     -- undo everything = empty
h ~~ h           = mempty     -- subtract self = empty (reset button)
```

`h ~~ h` = "undo everything I just did" = player hitting reset. Natural for a puzzle game.

## Chapter progression (from this discussion)

| Chapter | Game | Structure | New idea |
|---------|------|-----------|----------|
| 3 | Numbers | Maybe | Pushing failure to boundary |
| 4 | X's & O's | Monoid | Delta board, smart constructor |
| 5 | 4x4 Sudoku | Group | Undo as inversion |

## Overwriting vs undo

Overwriting a previous move = undo then place (not a new primitive).
But: undo your own move = always valid; overwrite a clue = never valid.
The `Clue` vs `Placed` distinction handles this in the type.

## Symmetries (mentioned but not developed)

Completed boards have transform operations forming a group:
- rotate90, reflectH, relabel (digit permutation), permuteRows (within band)
- These compose: `rotate90 . rotate90 . rotate90 . rotate90 = id`

## Open questions

- Hard puzzles need search trees and backtracking — is that too complex for the book?
- Candidate set algebra (sets shrinking under elimination) — worth developing separately?
- Constraint propagation (placing one digit forces others) — could be its own topic

## Notes on what came after

The discussion then moved to brainstorming other games:
- Idempotence considered (Minesweeper: reveal . reveal = reveal) but felt forced
- Lattices discussed (semilattice = assoc + comm + idempotent)
- Led to crossword puzzles as the next candidate (dual constraint = across AND down, lattice-like)
