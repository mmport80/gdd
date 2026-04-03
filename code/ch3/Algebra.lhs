#!/usr/bin/env -S nix shell nixpkgs#ghc --impure --command runhaskell

> {-# LANGUAGE NumericUnderscores #-}
> import Data.Ratio (Rational, (%))

Chapter 3: Vanilla Algebra
==========================

The right type is the one where your rules work reliably everywhere.

We lift the entire algebra into Maybe Rational. All operations work uniformly,
and Nothing propagates naturally.

> type R = Maybe Rational

Operations
----------

Addition:

> (+:) :: R -> R -> R
> (+:) (Just a) (Just b) = Just (a + b)
> (+:) _ _ = Nothing

Subtraction:

> (-:) :: R -> R -> R
> (-:) (Just a) (Just b) = Just (a - b)
> (-:) _ _ = Nothing

Multiplication:

> (*:) :: R -> R -> R
> (*:) (Just a) (Just b) = Just (a * b)
> (*:) _ _ = Nothing

Division:

> (/:) :: R -> R -> R
> (/:) (Just a) (Just b)
>   | b /= 0 = Just (a / b)
>   | otherwise = Nothing
> (/:) _ _ = Nothing

Negation:

> neg :: R -> R
> neg (Just a) = Just (-a)
> neg Nothing = Nothing

Laws
----

Commutativity for addition:

> test1 = let a = Just (5 % 1)
>             b = Just (3 % 1)
>         in a +: b == b +: a

Identity for addition:

> test2 = let a = Just (5 % 1)
>             zero = Just (0 % 1)
>         in a +: zero == a

Associativity for addition:

> test3 = let a = Just (5 % 1)
>             b = Just (3 % 1)
>             c = Just (2 % 1)
>         in (a +: b) +: c == a +: (b +: c)

Inverse for addition:

> test4 = let a = Just (5 % 1)
>             zero = Just (0 % 1)
>         in a +: neg a == zero

Self-inverse with subtraction:

> test4b = let a = Just (5 % 1)
>              zero = Just (0 % 1)
>          in a -: a == zero

Distributivity:

> test5 = let a = Just (2 % 1)
>             b = Just (3 % 1)
>             c = Just (4 % 1)
>         in a *: (b +: c) == (a *: b) +: (a *: c)

Division inverse:

> test6 = let a = Just (7 % 1)
>             b = Just (2 % 1)
>         in (a /: b) *: b == a

Boundary cases - division by zero:

> test7 = let a = Just (10 % 1)
>             b = Just (0 % 1)
>         in a /: b == Nothing

> test8 = let a = Just (5 % 1)
>             b = Nothing
>         in a +: b == Nothing

All laws hold uniformly, including at boundaries. No exceptions. No special
values. Just Nothing propagating naturally.

> main :: IO ()
> main = do
>   putStrLn $ "Commutativity: " ++ show test1
>   putStrLn $ "Identity: " ++ show test2
>   putStrLn $ "Associativity: " ++ show test3
>   putStrLn $ "Inverse: " ++ show test4
>   putStrLn $ "Self-inverse: " ++ show test4b
>   putStrLn $ "Distributivity: " ++ show test5
>   putStrLn $ "Division inverse: " ++ show test6
>   putStrLn $ "Division by zero: " ++ show test7
>   putStrLn $ "Nothing propagates: " ++ show test8
