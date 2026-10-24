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
> newtype Secret = Secret String
>   deriving (Eq, Show)

> -- Raw input enters here: only lowercase
> -- letters are guesses.
> mkGuess :: Char -> Maybe Guesses
> mkGuess c
>   | isAsciiLower c = Just (Guesses (Set.singleton c))
>   | otherwise      = Nothing
>
> guessesFrom :: String -> Guesses
> guessesFrom = mconcat . mapMaybe mkGuess

> -- Raw input enters here: a secret is one or
> -- more lowercase letters.
> mkSecret :: String -> Maybe Secret
> mkSecret word
>   | not (null word)
>   , all isAsciiLower word = Just (Secret word)
>   | otherwise             = Nothing

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
> maskedWord (Secret word) (Guesses guessed) =
>   [ if c `Set.member` guessed then c else '_'
>   | c <- word ]
>
> wrongGuesses :: Secret -> Guesses -> Int
> wrongGuesses (Secret word) (Guesses guessed) =
>   Set.size (Set.filter (`notElem` word) guessed)
>
> won :: Secret -> Guesses -> Bool
> won (Secret word) (Guesses guessed) =
>   all (`Set.member` guessed) word
>
> maxWrong :: Int
> maxWrong = 6
>
> lost :: Secret -> Guesses -> Bool
> lost secret guessed =
>   wrongGuesses secret guessed >= maxWrong

Example
-------

> verdict :: Secret -> Guesses -> String
> verdict secret guessed
>   | won secret guessed  = "won"
>   | lost secret guessed = "lost"
>   | otherwise           = "playing"
>
> describe :: Secret -> Guesses -> String
> describe secret guessed =
>   maskedWord secret guessed
>     ++ "  wrong: " ++ show (wrongGuesses secret guessed)
>     ++ "  " ++ verdict secret guessed
>
> play :: Secret -> IO ()
> play secret = mapM_ (putStrLn . describe secret) states
>   where
>     guesses = ["a", "h", "s", "x", "k", "e", "l"]
>     states = scanl (<>) mempty (map guessesFrom guesses)
>
> example :: IO ()
> example = case mkSecret "haskell" of
>   Nothing     -> putStrLn "not a valid secret"
>   Just secret -> play secret

> ab, bc, cd :: Guesses
> ab = guessesFrom "ab"
> bc = guessesFrom "bc"
> cd = guessesFrom "cd"

> testAssociative = (ab <> bc) <> cd == ab <> (bc <> cd)
> testLeftIdentity = mempty <> ab == ab
> testRightIdentity = ab <> mempty == ab
> testCommutative = ab <> bc == bc <> ab
> testIdempotent = ab <> ab == ab

> main :: IO ()
> main = example

Algebraic Scorecard
-------------------

  Closure         ✓  <> takes two Guesses, returns a Guesses
  Associativity   ✓  testAssociative
  Identity        ✓  testLeftIdentity, testRightIdentity
                     (mempty = no guesses)
  Commutativity   ✓  testCommutative
                     (guess order does not matter)
  Idempotence     ✓  testIdempotent
                     (guessing a letter twice
                     changes nothing)
  Invertibility   ✗  no inverse: after guessesFrom "a",
                     no g gives mempty; a made guess
                     cannot be undone
