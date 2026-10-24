#!/usr/bin/env -S nix shell nixpkgs#ghc --impure --command runhaskell

> import Data.Char (isAsciiLower)
> import Data.Maybe (mapMaybe)
> import Data.Set (Set)
> import qualified Data.Set as Set

Chapter ??: Hangman
===================

Types
-----

> newtype Guesses = Guesses (Set Char)
>   deriving (Eq, Show)
>
> type Secret = String

> -- Raw input enters here: only lowercase letters are guesses.
> mkGuess :: Char -> Maybe Guesses
> mkGuess c
>   | isAsciiLower c = Just (Guesses (Set.singleton c))
>   | otherwise      = Nothing
>
> guessesFrom :: String -> Guesses
> guessesFrom = mconcat . mapMaybe mkGuess

Algebra
-------

> instance Semigroup Guesses where
>   Guesses a <> Guesses b = Guesses (Set.union a b)
>
> instance Monoid Guesses where
>   mempty = Guesses Set.empty

Observations
------------

> maskedWord :: Secret -> Guesses -> String
> maskedWord secret (Guesses gs) =
>   [ if c `Set.member` gs then c else '_' | c <- secret ]
>
> wrongGuesses :: Secret -> Guesses -> Int
> wrongGuesses secret (Guesses gs) =
>   Set.size (Set.filter (`notElem` secret) gs)
>
> won :: Secret -> Guesses -> Bool
> won secret (Guesses gs) = all (`Set.member` gs) secret
>
> maxWrong :: Int
> maxWrong = 6
>
> lost :: Secret -> Guesses -> Bool
> lost secret gs = wrongGuesses secret gs >= maxWrong

Example
-------

> verdict :: Secret -> Guesses -> String
> verdict secret gs
>   | won secret gs  = "won"
>   | lost secret gs = "lost"
>   | otherwise      = "playing"
>
> describe :: Secret -> Guesses -> String
> describe secret gs =
>   maskedWord secret gs
>     ++ "  wrong: " ++ show (wrongGuesses secret gs)
>     ++ "  " ++ verdict secret gs
>
> example :: IO ()
> example = mapM_ (putStrLn . describe secret) states
>   where
>     secret = "haskell"
>     guesses = ["a", "h", "s", "x", "k", "e", "l"]
>     states = scanl (<>) mempty (map guessesFrom guesses)

> ab, bc, cd :: Guesses
> ab = guessesFrom "ab"
> bc = guessesFrom "bc"
> cd = guessesFrom "cd"

> test1 = (ab <> bc) <> cd == ab <> (bc <> cd)
> test2 = mempty <> ab == ab
> test3 = ab <> mempty == ab
> test4 = ab <> bc == bc <> ab
> test5 = ab <> ab == ab

> main :: IO ()
> main = example

Algebraic Scorecard
-------------------

  Closure         ✓  <> takes two Guesses, returns a Guesses
  Associativity   ✓  test1
  Identity        ✓  test2, test3 (mempty = no guesses)
  Commutativity   ✓  test4 (guess order does not matter)
  Idempotence     ✓  test5 (guessing a letter twice changes nothing)
  Invertibility   ✗  no inverse: after guessesFrom "a", no g gives
                     mempty; a made guess cannot be undone
