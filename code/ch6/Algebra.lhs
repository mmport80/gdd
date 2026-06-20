#!/usr/bin/env -S nix shell nixpkgs#ghc --impure --command runhaskell

> {-# LANGUAGE NumericUnderscores #-}
> import Data.Map (Map, fromList, singleton, union, (!))
> import qualified Data.Map as Map

Chapter ??: Sudoku (4x4)
=========================

A puzzle you can undo. The game is a group: every move has an inverse,
so you can always backtrack. This upgrades the monoid from Noughts &
Crosses with a notion of "undo."

We use a 4x4 variant (digits 1-4, four 2x2 boxes) — same structure,
small enough to reason about concretely.

Types
-----

> data Digit = One | Two | Three | Four
>   deriving (Eq, Show, Bounded, Enum)
>
> data Cell = Empty | Clue Digit | Placed Digit
>   deriving (Eq, Show)
>
> type Position = (Int, Int)   -- (0..3, 0..3)
>
> data DeltaOp = Place Digit | Remove Digit
>   deriving (Eq, Show)
>
> newtype Delta = Delta (Position, DeltaOp)   -- single move, opaque
> newtype History = History [Delta]           -- move log, opaque

All positions:

> allPositions :: [Position]
> allPositions = [(x, y) | x <- [0..3], y <- [0..3]]

All digits:

> allDigits :: [Digit]
> allDigits = [One, Two, Three, Four]

Algebra
-------

History is a monoid (append log) AND a group (every move can be undone):

> instance Semigroup History where
>   History as <> History bs = History (as ++ bs)
>
> instance Monoid History where
>   mempty = History []

The group operation — invert the whole history (reverse + invert each op):

> invert :: History -> History
> invert (History ds) = History (reverse (map invertDelta ds))
>
> invertDelta :: Delta -> Delta
> invertDelta (Delta (pos, Place d))  = Delta (pos, Remove d)
> invertDelta (Delta (pos, Remove d)) = Delta (pos, Place d)

"Subtract" one history from another:

> (~~) :: History -> History -> History
> a ~~ b = a <> invert b

Project history into a board state:

> type Board = Map Position Cell
>
> project :: History -> Board
> project (History ds) = foldl applyDelta emptyBoard ds
>
> emptyBoard :: Board
> emptyBoard = fromList [(p, Empty) | p <- allPositions]
>
> applyDelta :: Board -> Delta -> Board
> applyDelta board (Delta (pos, op)) = case op of
>   Place d  -> Map.insert pos (Placed d) board
>   Remove _ -> Map.insert pos Empty board

Smart constructor — checks all constraints (row, col, box, cell state).
Returns Nothing if the move is invalid.

> mkDelta :: Board -> Position -> Digit -> Maybe Delta
> mkDelta board pos digit = case Map.findWithDefault Empty pos board of
>   Empty      -> checkConstraints board pos digit
>   Clue _     -> Nothing   -- can't touch clues
>   Placed _   -> Nothing   -- must undo first
>
> checkConstraints :: Board -> Position -> Digit -> Maybe Delta
> checkConstraints board (r, c) digit
>   | digitInRow board r digit    = Nothing
>   | digitInCol board c digit    = Nothing
>   | digitInBox board r c digit  = Nothing
>   | otherwise                   = Just (Delta ((r, c), Place digit))
>
> digitInRow :: Board -> Int -> Digit -> Bool
> digitInRow board r digit = any hasDigit [(r, c) | c <- [0..3]]
>   where hasDigit pos = cellDigit (Map.findWithDefault Empty pos board) == Just digit
>
> digitInCol :: Board -> Int -> Digit -> Bool
> digitInCol board c digit = any hasDigit [(r, c) | r <- [0..3]]
>   where hasDigit pos = cellDigit (Map.findWithDefault Empty pos board) == Just digit
>
> digitInBox :: Board -> Int -> Int -> Digit -> Bool
> digitInBox board r c digit = any hasDigit positions
>   where
>     (br, bc) = (r `div` 2 * 2, c `div` 2 * 2)
>     positions = [(br + i, bc + j) | i <- [0..1], j <- [0..1]]
>     hasDigit pos = cellDigit (Map.findWithDefault Empty pos board) == Just digit
>
> cellDigit :: Cell -> Maybe Digit
> cellDigit (Clue d)   = Just d
> cellDigit (Placed d) = Just d
> cellDigit Empty      = Nothing

Observations
------------

Is the puzzle solved?

> solved :: Board -> Bool
> solved board = all filled allPositions && all validUnit allUnits
>   where
>     filled pos = cellDigit (Map.findWithDefault Empty pos board) /= Nothing
>     validUnit unit = length (nubDigits unit) == 4
>     nubDigits unit = [d | pos <- unit, Just d <- [cellDigit (Map.findWithDefault Empty pos board)]]
>     allUnits = rows ++ cols ++ boxes
>     rows  = [[(r, c) | c <- [0..3]] | r <- [0..3]]
>     cols  = [[(r, c) | r <- [0..3]] | c <- [0..3]]
>     boxes = [[(br+i, bc+j) | i <- [0..1], j <- [0..1]]
>              | br <- [0,2], bc <- [0,2]]

List available moves:

> availableMoves :: Board -> [(Position, Digit)]
> availableMoves board =
>   [(pos, d) | pos <- allPositions,
>              Map.findWithDefault Empty pos board == Empty,
>              d <- allDigits,
>              not (digitInRow board (fst pos) d),
>              not (digitInCol board (snd pos) d),
>              not (digitInBox board (fst pos) (snd pos) d)]

Example
-------

> example :: IO ()
> example = do
>   let board = emptyBoard
>   putStrLn $ "Empty board: " ++ show (length (availableMoves board)) ++ " available moves"
>
>   case mkDelta board (0, 0) One of
>     Just delta -> do
>       let history = History [delta]
>           board1  = project history
>       putStrLn $ "Place One at (0,0): " ++ show (length (availableMoves board1)) ++ " moves left"
>
>       -- Undo it: history <> invert history = mempty
>       let undone  = history ~~ history
>           board0  = project undone
>       putStrLn $ "After undo: " ++ show (length (availableMoves board0)) ++ " moves left"
>     Nothing -> putStrLn "Invalid move"

> main :: IO ()
> main = example

Algebraic Scorecard
-------------------

  Closure         ✓  <> takes two Histories, returns a History — always
  Associativity   ✓  list append is associative
  Identity        ✓  mempty = no moves; empty puzzle
  Idempotence     ✗  appending the same move twice = two moves (not deduplicated)
  Commutativity   ✗  order of moves matters
  Inverses        ✓  every Place has a matching Remove; invert undoes the log
  Annihilation    ✗  no absorbing element

Key upgrade from Ch4: INVERSES. This is a GROUP, not just a monoid.
`h ~~ h = mempty` — "undo everything I just did" = reset button.
