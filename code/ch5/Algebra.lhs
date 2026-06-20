#!/usr/bin/env -S nix shell nixpkgs#ghc --impure --command runhaskell

> {-# LANGUAGE NumericUnderscores #-}
> import Data.List (foldl', nub, sort)

Chapter ??: Mastermind
=======================

Each guess gets feedback. The game is a monoid: guesses compose like an
event log, and each clue carries its own score.

Types
-----

> data Colour = Red | Blue | Green | Yellow | Orange | Purple
>   deriving (Eq, Show, Bounded, Enum)
>
> type Code = [Colour]         -- length N
> data Clue = Clue
>   { clueGuess  :: Code
>   , clueBlacks :: Int        -- correct colour, correct position
>   , clueWhites :: Int        -- correct colour, wrong position
>   } deriving (Eq, Show)
>
> newtype Game = Game [Clue]   -- move log, opaque

Algebra
-------

Game is a monoid — a log of clues. Composing is appending guesses:

> instance Semigroup Game where
>   Game as <> Game bs = Game (as ++ bs)
>
> instance Monoid Game where
>   mempty = Game []

Smart constructor — score the guess against the secret, build a Clue,
append to the game. Maybe is not needed here (any guess produces a
clue), but we guard against wrong-length guesses:

> mkGuess :: Code -> Code -> Game -> Maybe Game
> mkGuess secret guess (Game clues)
>   | length guess /= length secret = Nothing
>   | otherwise = let (b, w) = score secret guess
>                 in Just (Game (clues ++ [Clue guess b w]))

Observations
------------

Has the player won (all blacks)?

> won :: Game -> Bool
> won (Game clues) = any (\c -> clueBlacks c > 0 && clueWhites c == 0
>                              && clueBlacks c == length (clueGuess c)) clues

Number of guesses so far:

> guessCount :: Game -> Int
> guessCount (Game clues) = length clues

Scoring — blacks are positional, whites are relational:

> score :: Code -> Code -> (Int, Int)
> score secret guess = (blacks, whites)
>   where
>     blacks = length $ filter id $ zipWith (==) secret guess
>     whites = totalMatches - blacks
>     totalMatches = sum $ map minCount $ nub guess
>     minCount c = min (count c secret) (count c guess)
>     count c = length . filter (== c)

Example
-------

> example :: IO ()
> example = do
>   let secret = [Red, Blue, Green, Yellow] :: Code
>   let game = mempty :: Game
>
>   case mkGuess secret [Red, Red, Blue, Green] game of
>     Just game1 -> do
>       let Clue _ b1 w1 = lastClue game1
>       putStrLn $ "Guess 1: " ++ show b1 ++ " black, " ++ show w1 ++ " white"
>
>       case mkGuess secret [Red, Blue, Green, Yellow] game1 of
>         Just game2 -> do
>           let Clue _ b2 w2 = lastClue game2
>           putStrLn $ "Guess 2: " ++ show b2 ++ " black, " ++ show w2 ++ " white"
>           putStrLn $ "Won? " ++ show (won game2)
>         Nothing -> putStrLn "Invalid guess"
>     Nothing -> putStrLn "Invalid guess"
>
> lastClue :: Game -> Clue
> lastClue (Game clues) = last clues

> main :: IO ()
> main = example

Algebraic Scorecard
-------------------

  Closure         ✓  <> takes two Games, returns a Game — always
  Associativity   ✓  list append is associative
  Identity        ✓  mempty = no guesses yet; a new game
  Idempotence     ✗  guessing twice duplicates the clue (honest: pointless but allowed)
  Commutativity   ✗  order of guesses matters (correct for player experience)
  Inverses        ✗  can't un-guess; the log is append-only
  Annihilation    ✗  no absorbing element

Bonus: monoid homomorphism — `won (g1 <> g2) = won g1 || won g2`
because `won = any wonClue` distributes over list concatenation.
