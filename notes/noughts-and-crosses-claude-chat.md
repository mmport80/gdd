# Noughts & Crosses (Ch4) — Claude discussion notes

Source: https://claude.ai/share/ (pasted from /tmp/xos.txt)
Date: 2 Apr 2026

---

## Game rules

- 3 in a row wins
- Must place on vacant position
- Game ends if board is full or winner declared

## Types

```haskell
data Player = X | O
data Cell   = Empty | Taken Player
type Position = (Int, Int)  -- (0..2, 0..2)
type Board = Map Position Cell
```

## Key design move: push Maybe to the boundary

Initial approach had `Maybe` in `place`:
```haskell
place :: Player -> Position -> Board -> Maybe Board
```

Insight: Maybe is only needed because of the vacancy check. Encode vacancy in the type, and place becomes total.

First attempt — VacantPosition:
```haskell
vacant :: Position -> Board -> Maybe VacantPosition
place :: Player -> VacantPosition -> Board -> Board  -- total, no Maybe
```

Then evolved to DeltaBoard pattern (the design that stuck):
```haskell
newtype Board = Board (Map Position Cell)
newtype DeltaBoard = DeltaBoard Board  -- single move, opaque

-- Smart constructor — Maybe lives here only
mkDelta :: Position -> Player -> Board -> Maybe DeltaBoard
mkDelta pos player (Board cells)
    | cells ! pos == Empty = Just $ DeltaBoard (Board (Map.singleton pos (Taken player)))
    | otherwise            = Nothing
```

## The monoid discovery

User suggested: `place player board d_board = ...` — input a delta board with the single new move.

This gives a natural binary operation — merging boards:
```haskell
merge :: Board -> Board -> Board
```

And now associativity is meaningful, with emptyBoard as identity. That's a monoid.

Since order doesn't affect the final board — commutative monoid.

`place` dissolves into `<>`:
```haskell
emptyBoard <> d1 <> d2 <> d3
```

### Final code

```haskell
data Player = X | O
data Cell   = Empty | Taken Player
type Position = (Int, Int)  -- (0..2, 0..2)

newtype Board = Board (Map Position Cell)
newtype DeltaBoard = DeltaBoard Board  -- single move, opaque

-- Monoid instance
instance Semigroup Board where
    Board a <> Board b = Board (Map.union a b)  -- b wins conflicts, but DeltaBoard prevents them

instance Monoid Board where
    mempty = Board (Map.fromList [(p, Empty) | p <- allPositions])

-- Smart constructor — Maybe lives here only
mkDelta :: Position -> Player -> Board -> Maybe DeltaBoard
mkDelta pos player (Board cells)
    | cells ! pos == Empty = Just $ DeltaBoard (Board (Map.singleton pos (Taken player)))
    | otherwise            = Nothing

-- Observations
hasWon :: Player -> Board -> Bool
hasWon player (Board cells) = any (all (== Taken player) . map (cells !)) winningLines

gameOver :: Board -> Maybe GameOver
gameOver board
    | hasWon X board                = Just (Winner X)
    | hasWon O board                = Just (Winner O)
    | null (availableMoves board)   = Just Draw
    | otherwise                     = Nothing

availableMoves :: Board -> [Position]
availableMoves (Board cells) = [p | p <- allPositions, cells ! p == Empty]
```

Usage: `emptyBoard <> d1 <> d2 <> d3`

## Properties examined (the 7 from ADD book)

The 7 properties: associativity, identity, idempotency, invertibility, distributivity, commutativity, annihilation.

| Property | Holds? | Notes |
|----------|--------|-------|
| Associativity | ✓ | Via DeltaBoard/monoid — merging boards |
| Identity | ✓ | emptyBoard |
| Commutativity | ✓ | Moves commute on the board (but game enforces turn order — nice tension) |
| Annihilation | ✓ | Wins persist — hasWon stays true after further moves |
| Idempotency | ✗ | Blocked by type (VacantPosition/DeltaBoard consumed) |
| Invertibility | ✗ | No undo in the rules (two-player game) |
| Distributivity | ✗ | Not applicable |

## Commutativity analysis

- Board doesn't care about move order: `place X p1 (place O p2 empty) = place O p2 (place X p1 empty)`
- But game enforces turn order — algebra is commutative, game layer isn't
- Board state ≅ two disjoint sets of positions (X positions, O positions)
- History is irrelevant — board fully described by sets
- Commutativity is real but inert — doesn't unlock anything practical for this game
- Teaching point: not every property you find needs to do something

## Annihilation analysis

- `hasWon p b = True ⟹ hasWon p (place p' vp b) = True` — wins persist
- gameOver similarly — finished board stays finished
- Honest assessment: kind of obvious, may not earn its place as a deep insight

## Lattice/stretching (rejected)

Claude stretched toward: boards form a lattice (empty at bottom, full at top, partial order by moves), hasWon is a monotone map. User called it out as reaching. Agreed it was overstretching.

## Key takeaways

- DeltaBoard smart constructor pattern — Maybe pushed to boundary, core operation total
- `place` dissolves into `<>` — monoid machinery works for free (mconcat, fold, etc.)
- Commutative monoid — real property, but inert in practice
- Not every chapter needs a dramatic algebraic revelation — "spot the structure, get the tools for free"
- Ch3 was the drama (Maybe), Ch4 is the payoff in practice (monoid)
- Monoid requires Semigroup in Haskell — <> is always inherited

## Chapter role

Honest, straightforward chapter. The wins:
- Clean type design (DeltaBoard as smart constructor)
- Maybe pushed to the boundary
- place dissolves into <>
- Monoid machinery just works
