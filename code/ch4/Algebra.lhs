#!/usr/bin/env -S nix shell nixpkgs#ghc --impure --command runhaskell

> {-# LANGUAGE NumericUnderscores #-}
> import Data.Map (Map, fromList, singleton, union, (!))

Chapter 4: Types and Structure
===============================

The right type is the one where your rules work reliably everywhere.

In Chapter 3, we lifted operations into Maybe Rational so the algebra laws
held uniformly. Here we lift structure itself — using types to encode game
rules so invalid states are unrepresentable.

This is tic-tac-toe. The board is a monoid: moves compose without friction.

Types
-----

> data Player = X | O deriving (Eq, Show)
> data Cell = Empty | Taken Player deriving (Eq, Show)
> type Position = (Int, Int)  -- (0..2, 0..2)
>
> newtype Board = Board (Map Position Cell) deriving (Eq, Show)
> newtype DeltaBoard = DeltaBoard Board  -- single move, opaque
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

Board is a monoid. Moves compose via union (second map wins on conflicts):

> instance Semigroup Board where
>   Board a <> Board b = Board (b `union` a)  -- b wins, so delta overwrites
>
> instance Monoid Board where
>   mempty = Board (fromList [(p, Empty) | p <- allPositions])

Smart constructor — Maybe lives here only. A move is valid only if the
target cell is empty.

> mkDelta :: Position -> Player -> Board -> Maybe DeltaBoard
> mkDelta pos player (Board cells)
>   | cells ! pos == Empty = Just $ DeltaBoard (Board (singleton pos (Taken player)))
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

Helper to unwrap a delta move:

> applyDelta :: Board -> DeltaBoard -> Board
> applyDelta board (DeltaBoard delta) = board <> delta

Example
-------

> example :: IO ()
> example = do
>   let board = mempty :: Board
>   putStrLn $ "Empty board: " ++ show (length (availableMoves board)) ++ " available moves"
>
>   case mkDelta (0, 0) X board of
>     Just delta -> do
>       let board1 = applyDelta board delta
>       putStrLn $ "X plays at (0,0): " ++ show (length (availableMoves board1)) ++ " moves left"
>
>       case mkDelta (1, 1) O board1 of
>         Just delta2 -> do
>           let board2 = applyDelta board1 delta2
>           putStrLn $ "O plays at (1,1): " ++ show (length (availableMoves board2)) ++ " moves left"
>           case gameOver board2 of
>             Nothing -> putStrLn "Game continues"
>             Just end -> putStrLn $ "Game over: " ++ show end
>         Nothing -> putStrLn "Invalid move for O"
>     Nothing -> putStrLn "Invalid move for X"

> main :: IO ()
> main = example
