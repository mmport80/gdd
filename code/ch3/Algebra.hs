-- Chapter 3: Vanilla Algebra - Examples
-- Self-contained Haskell script demonstrating algebra properties

{-# LANGUAGE NumericUnderscores #-}

import Data.Ratio (Rational, (%))

-- Example 1: Integer division fails the inversion property
integerDivisionExample :: IO ()
integerDivisionExample = do
  putStrLn "=== Integer Division Example ==="
  putStrLn "Testing: (a / b) * b = a"
  putStrLn ""

  let test10_2 = (10 `div` 2) * 2
  putStrLn $ "10 / 2 * 2 = " ++ show test10_2 ++ " (Expected: 10) ✓"

  let test7_2 = (7 `div` 2) * 2
  putStrLn $ "7 / 2 * 2 = " ++ show test7_2 ++ " (Expected: 7) ✗"

  putStrLn ""

-- Example 2: Rational division preserves the inversion property
rationalDivisionExample :: IO ()
rationalDivisionExample = do
  putStrLn "=== Rational Division Example ==="
  putStrLn "Testing: (a / b) * b = a"
  putStrLn ""

  let test7_2 = (7 % 2) * 2
  putStrLn $ "7 / 2 * 2 = " ++ show test7_2 ++ " (Expected: 7 % 1) ✓"

  let test10_3 = (10 % 3) * 3
  putStrLn $ "10 / 3 * 3 = " ++ show test10_3 ++ " (Expected: 10 % 1) ✓"

  putStrLn ""

-- Example 3: Maybe Rational handles division by zero
safeDivide :: Rational -> Rational -> Maybe Rational
safeDivide _ 0 = Nothing
safeDivide a b = Just (a / b)

safeDivisionExample :: IO ()
safeDivisionExample = do
  putStrLn "=== Safe Division Example ==="
  putStrLn "Using Maybe Rational to handle division by zero"
  putStrLn ""

  let result1 = safeDivide 10 2
  putStrLn $ "10 / 2 = " ++ show result1

  let result2 = safeDivide 10 0
  putStrLn $ "10 / 0 = " ++ show result2

  putStrLn ""

-- Example 4: Commutativity and associativity
commutativityExample :: IO ()
commutativityExample = do
  putStrLn "=== Commutativity and Associativity ==="
  putStrLn "Testing: a + b = b + a and (a + b) + c = a + (b + c)"
  putStrLn ""

  let a = 5 :: Int
  let b = 3 :: Int
  let c = 2 :: Int

  putStrLn $ show a ++ " + " ++ show b ++ " = " ++ show (a + b)
  putStrLn $ show b ++ " + " ++ show a ++ " = " ++ show (b + a)
  putStrLn $ "Commutativity: " ++ show (a + b == b + a)
  putStrLn ""

  let assocLeft = (a + b) + c
  let assocRight = a + (b + c)
  putStrLn $ "(" ++ show a ++ " + " ++ show b ++ ") + " ++ show c ++ " = " ++ show assocLeft
  putStrLn $ show a ++ " + (" ++ show b ++ " + " ++ show c ++ ") = " ++ show assocRight
  putStrLn $ "Associativity: " ++ show (assocLeft == assocRight)
  putStrLn ""

main :: IO ()
main = do
  putStrLn "Chapter 3: Vanilla Algebra Examples\n"
  integerDivisionExample
  rationalDivisionExample
  safeDivisionExample
  commutativityExample
  putStrLn "=== End of Examples ==="
