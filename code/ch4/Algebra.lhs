#!/usr/bin/env -S nix shell nixpkgs#ghc --impure --command runhaskell

> {-# LANGUAGE NumericUnderscores #-}
> import Data.Map (Map, fromList, singleton, union, (!))

Chapter 4: Types and Structure
===============================

The right type is the one where your rules work reliably everywhere.

In Chapter 3, we lifted operations into Maybe Rational so the algebra laws
held uniformly. Here we lift structure itself — using types to encode game
rules so invalid states are unrepresentable.

This is tic-tac-toe. A game is a monoid: moves compose like an event log.

Types
-----

> data Player = X | O deriving (Eq, Show)
> data Cell = Empty | Taken Player deriving (Eq, Show)
> type Position = (Int, Int)  -- (0..2, 0..2)
>
> newtype Board = Board (Map Position Cell) deriving (Eq, Show)
> newtype DeltaBoard = DeltaBoard (Map Position Cell)  -- move log, opaque
> data GameOver = Winner Player | Draw deriving (Eq, Show)

All positions on the board:

> allPositions :: [Position]
> allPositions = [(x, y) | x <- [0..2], y <- [0..2]]

Winning lines:

> winningLines :: [[Position]]
> winningLines =
>   [[(r, c) | c <- [0..2]] | r <- [0..2]] ++  -- rows
>   [[(r, c) | r <- [0..2]] | c <- [0..2]] ++  -- columns
>   [[(r, r) | r <- [0..2]]] ++                -- top-left to bottom-right
>   [[(r, 2-r) | r <- [0..2]]]                 -- top-right to bottom-left

Algebra
-------

DeltaBoard is a monoid — a move log. Deltas compose by union (later moves
win on conflicts):

> instance Semigroup DeltaBoard where
>   DeltaBoard a <> DeltaBoard b = DeltaBoard (b `union` a)  -- b wins
>
> instance Monoid DeltaBoard where
>   mempty = DeltaBoard (fromList [])

Project a delta log into a full board state:

> project :: DeltaBoard -> Board
> project (DeltaBoard moves) =
>   Board (moves `union` fromList [(p, Empty) | p <- allPositions])

Smart constructor — Maybe lives here only. A move is valid only if the
target cell is empty. In a real codebase you'd hide the DeltaBoard
constructor behind a module boundary (export the type name only, not the
constructor), so this is the only way to create a single-move delta from
outside.

> mkDelta :: Position -> Player -> Board -> Maybe DeltaBoard
> mkDelta pos player (Board cells)
>   | cells ! pos == Empty = Just $ DeltaBoard (singleton pos (Taken player))
>   | otherwise            = Nothing

Observations
------------

Check if a player has won:

> hasWon :: Player -> Board -> Bool
> hasWon player (Board cells) = any (all (== Taken player) . map (cells !)) winningLines

Check if the game is over:

> gameOver :: Board -> Maybe GameOver
> gameOver board
>   | hasWon X board           = Just (Winner X)
>   | hasWon O board           = Just (Winner O)
>   | null (availableMoves board) = Just Draw
>   | otherwise                = Nothing

List available moves:

> availableMoves :: Board -> [Position]
> availableMoves (Board cells) = [p | p <- allPositions, cells ! p == Empty]

Example
-------

> example :: IO ()
> example = do
>   let deltas = mempty :: DeltaBoard
>   putStrLn $ "Empty board: " ++ show (length (availableMoves (project deltas))) ++ " available moves"
>
>   case mkDelta (0, 0) X (project deltas) of
>     Just delta -> do
>       let deltas1 = deltas <> delta
>       putStrLn $ "X plays at (0,0): " ++ show (length (availableMoves (project deltas1))) ++ " moves left"
>
>       case mkDelta (1, 1) O (project deltas1) of
>         Just delta2 -> do
>           let deltas2 = deltas1 <> delta2
>           putStrLn $ "O plays at (1,1): " ++ show (length (availableMoves (project deltas2))) ++ " moves left"
>           case gameOver (project deltas2) of
>             Nothing -> putStrLn "Game continues"
>             Just end -> putStrLn $ "Game over: " ++ show end
>         Nothing -> putStrLn "Invalid move for O"
>     Nothing -> putStrLn "Invalid move for X"

> main :: IO ()
> main = example
