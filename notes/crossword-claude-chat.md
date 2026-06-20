# Crossword — Claude discussion notes

Source: https://claude.ai/share/ (pasted from /tmp/crossword.txt)
Date: 3 Apr 2026

---

## What are we modeling?

Candidates considered:
- The grid (blank structure with black/white cells)
- The filling (letters placed in cells)
- The puzzle (grid + clues)
- A partial solution (some cells filled, others not)

The algebraically interesting one is the partial filling.

## Initial approach: Map Position Char

```haskell
merge :: Filling -> Filling -> Maybe Filling
```

Returns `Just` if the two agree on every cell they both touch, `Nothing` on conflict.

Problem: `Maybe` breaks composability — one conflict collapses the whole chain.

## Explored alternatives

1. Lift to `Maybe Filling` throughout — Nothing propagates, loses info
2. Change to `Map Position (Set Char)` — merge never fails, conflicts observable not fatal
3. Event-source style — list of placements, freely composable, conflicts surface at interpretation

User wanted: composability (merge merge merge), undo/inverse, and commutativity.

## Key insight: Abelian Group direction

Commutativity + inverse = Abelian Group.

- Order you jot down answers shouldn't matter (commutativity)
- You can undo any answer (inverse)
- Net result matters, not history

Explored `Map Position (Map Char Int)` — signed counts per letter. Place = +1, undo = -1.
`merge f (inverse f) = empty` falls out naturally.

## Shift to Clue-level interface

User: "she is thinking about solving '4 across'" — the interface should be clue-answer pairs, not individual letters.

```haskell
type Solution = Map Clue Word'
```

Inter-word constraints (shared letters) aren't in the algebra — they're in interpretation.

## Unifying merge and delete into Patches

User noticed merge and delete aren't orthogonal — both are "changes to the solution."

```haskell
type Patch = Map Clue (Maybe Word')
-- Just w  = set this clue to w
-- Nothing = delete this clue
```

- `set :: Clue -> Word' -> Patch`
- `delete :: Clue -> Patch`
- Patches compose with last-write-wins `Map.union`

## Final model: Patch monoid + toSolution + valid

```haskell
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map

-- Fixed puzzle structure
data Direction = Across | Down deriving (Eq, Ord, Show)

data Clue = Clue
  { clueNumber :: Int
  , clueDir    :: Direction
  } deriving (Eq, Ord, Show)

data Grid = Grid
  { clueLength    :: Map Clue Int
  , cluePositions :: Map Clue [(Int, Int)]
  }

-- A patch: set or delete a clue's answer
-- Nothing = deleted, Just w = answered
type Patch = Map Clue (Maybe Word')
type Word' = String

-- Patch constructors
set :: Clue -> Word' -> Patch
set c w = Map.singleton c (Just w)

delete :: Clue -> Patch
delete c = Map.singleton c Nothing

-- Monoid (right-biased, last wins)
instance Semigroup Patch where
  p1 <> p2 = Map.unionWith (const id) p2 p1

instance Monoid Patch where
  mempty = Map.empty

-- A solution is just answered clues -- no Maybes
type Solution = Map Clue Word'

toSolution :: Patch -> Solution
toSolution = Map.mapMaybe id

-- Validity (snapshot check, outside the algebra)
valid :: Grid -> Solution -> Bool
valid grid sol = lengthsOk && noConflicts
  where
    lengthsOk = all checkLength (Map.toList sol)
    checkLength (clue, word) =
      case Map.lookup clue (clueLength grid) of
        Nothing  -> False
        Just len -> length word == len

    noConflicts =
      let cellMap = buildCellMap grid sol
      in all singleLetter (Map.elems cellMap)

    singleLetter chars = length (nub chars) <= 1

buildCellMap :: Grid -> Solution -> Map (Int, Int) [Char]
buildCellMap grid sol =
  Map.unionsWith (++) $ do
    (clue, word) <- Map.toList sol
    cells <- maybeToList $ Map.lookup clue (cluePositions grid)
    return $ Map.fromList $ zip cells (map (:[]) word)
```

### Properties

**Patch (under <>):**
- Associativity ✓
- Identity (empty) ✓
- Idempotent: `merge p p = p` ✓
- Not commutative ✗ (order matters — last wins)
- => Idempotent monoid

**apply / toSolution:**
- `toSolution mempty = empty`
- `toSolution (p1 <> p2) = toSolution p1 `merged with` toSolution p2` (homomorphism)
- `apply` was initially a monoid action on Solution, but reduces to `toSolution` since Patch is already a monoid

**Validity:**
- Does NOT compose or distribute
- Two valid patches can conflict when combined
- Validity isn't monotone in either direction (partial invalid can become valid after more patches)
- `valid` is just a snapshot check — sits completely outside the algebra

## The flow

```
[Patch]          -- your history of individual moves
  |
mconcat          -- collapse to one combined Patch
  |
Patch            -- the net effect of everything
  |
toSolution       -- strip the Nothings
  |
Solution         -- what the board looks like right now
  |
valid myGrid     -- are we done?
```

## Key design points

- `Nothing` in Patch = "overwrite with nothing" (meaningful during <>)
- `Nothing` not needed in Solution — absence is just absence (missing key = unanswered clue)
- `Maybe` only lives in Patch, disappears in Solution via `toSolution`
- Generalises: `Patch k v = Map k (Maybe v)` — nothing crossword-specific
  - Same pattern: CSS cascade, config file layering, HTTP header overrides
- Grid is fixed puzzle context (read-only), Solution is mutable state, Patch is the algebra

## Validity rules (simplified to two)

1. Each answer matches expected length (from Grid)
2. No cell conflicts — shared cells must agree (includes pre-fills)

Pre-filled letters are just a special case of rule 2.

## Comparison with Sudoku

- Same pattern: free operations + snapshot validity check
- Difference: Sudoku rules are symmetric (every digit/row/col/box), crossword validity needs the Grid for lengths and cell positions — grid is external context

## Open questions

- Is the Abelian Group angle (signed counts) worth revisiting for a richer algebra?
- Does the chapter teach enough that's new vs. Sudoku?
- The `Action p s` typeclass generalisation — is that the right level of abstraction for the book?
