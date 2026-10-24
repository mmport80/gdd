#!/usr/bin/env -S nix shell nixpkgs#ghc --impure --command runhaskell

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

Raw input enters through mkGuess. Only lowercase letters are guesses.

> mkGuess :: Char -> Maybe Guesses
> mkGuess c
>   | c `elem` ['a' .. 'z'] = Just (Guesses (Set.singleton c))
>   | otherwise             = Nothing
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
> lost secret guesses = wrongGuesses secret guesses >= maxWrong

Example
-------

> describe :: Secret -> Guesses -> String
> describe secret guesses =
>   maskedWord secret guesses
>     ++ "  wrong: " ++ show (wrongGuesses secret guesses)
>
> example :: IO ()
> example = mapM_ (putStrLn . describe secret) states
>   where
>     secret = "haskell"
>     states = scanl (<>) mempty (map guessesFrom ["a", "h", "s", "x", "k", "e", "l"])

> test1 = (guessesFrom "ab" <> guessesFrom "bc") <> guessesFrom "cd"
>      == guessesFrom "ab" <> (guessesFrom "bc" <> guessesFrom "cd")
> test2 = mempty <> guessesFrom "ab" == guessesFrom "ab"
> test3 = guessesFrom "ab" <> mempty == guessesFrom "ab"
> test4 = guessesFrom "ab" <> guessesFrom "bc" == guessesFrom "bc" <> guessesFrom "ab"
> test5 = guessesFrom "ab" <> guessesFrom "ab" == guessesFrom "ab"

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
