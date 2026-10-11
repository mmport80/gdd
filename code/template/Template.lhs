#!/usr/bin/env -S nix shell nixpkgs#ghc --impure --command runhaskell

Chapter ??: Title
=================

Types
-----

> newtype Tally = Tally Int   -- TODO(author): replace with the chapter's type
>   deriving (Eq, Show)

Algebra
-------

> instance Semigroup Tally where
>   Tally a <> Tally b = Tally (a + b)
>
> instance Monoid Tally where
>   mempty = Tally 0

Observations
------------

> tally :: Tally -> Int
> tally (Tally n) = n

Example
-------

> example :: IO ()
> example = do
>   let total = mconcat [Tally 1, Tally 2, Tally 3]
>   putStrLn $ "Total: " ++ show (tally total)

> test1 = (Tally 1 <> Tally 2) <> Tally 3 == Tally 1 <> (Tally 2 <> Tally 3)
> test2 = Tally 1 <> mempty == Tally 1
> test3 = mempty <> Tally 1 == Tally 1

> main :: IO ()
> main = example

Algebraic Scorecard
-------------------

  Closure         ✓  <> takes two Tallys, returns a Tally
  Associativity   ✓  (a <> b) <> c = a <> (b <> c) — Int addition
  Identity        ✓  mempty = Tally 0
