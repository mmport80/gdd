#!/usr/bin/env -S nix shell nixpkgs#ghc --impure --command runhaskell

> {-# LANGUAGE NumericUnderscores #-}
> import Data.Map (Map, fromList, singleton, unionWith, (!))
> import qualified Data.Map as Map
> import Data.List (nub)

Chapter ??: Crosswords
=======================

A partial solution you build up and undo. Patches compose: setting a
clue's answer overwrites; deleting removes. The algebra is an idempotent
monoid — patching the same clue twice with the same answer is a no-op.

Types
-----

> data Direction = Across | Down deriving (Eq, Ord, Show)
> data Clue = Clue
>   { clueNumber :: Int
>   , clueDir    :: Direction
>   } deriving (Eq, Ord, Show)
>
> type Word' = String
>
> -- A patch: set or delete a clue's answer.
> -- Just w  = answer this clue with w
> -- Nothing = delete this clue's answer
> newtype Patch = Patch (Map Clue (Maybe Word'))
> type Solution = Map Clue Word'
>
> -- Fixed puzzle structure (read-only context)
> data Grid = Grid
>   { clueLengths    :: Map Clue Int
>   , cluePositions  :: Map Clue [(Int, Int)]
>   }

Algebra
-------

Patch is a monoid — last-write-wins on merge:

> instance Semigroup Patch where
>   Patch p1 <> Patch p2 = Patch (unionWith const p1 p2)  -- p2 wins on conflicts
>
> instance Monoid Patch where
>   mempty = Patch (fromList [])

Smart constructors for setting and deleting clues:

> set :: Clue -> Word' -> Patch
> set c w = Patch (singleton c (Just w))
>
> delete :: Clue -> Patch
> delete c = Patch (singleton c Nothing)

Project a patch into a solution (strip the Nothings):

> toSolution :: Patch -> Solution
> toSolution (Patch p) = Map.mapMaybe id p

Observations
------------

Is the solution valid? (Snapshot check — outside the algebra)

> valid :: Grid -> Solution -> Bool
> valid grid sol = lengthsOk && noConflicts
>   where
>     lengthsOk = all checkLength (Map.toList sol)
>     checkLength (clue, word) = case Map.lookup clue (clueLengths grid) of
>       Just len -> length word == len
>       Nothing  -> False
>
>     noConflicts = all singleLetter (Map.elems cellMap)
>     cellMap = buildCellMap grid sol
>     singleLetter letters = length (nub letters) <= 1

> buildCellMap :: Grid -> Solution -> Map (Int, Int) [Char]
> buildCellMap grid sol =
>   Map.unionsWith (++) $ do
>     (clue, word) <- Map.toList sol
>     cells <- maybeToList $ Map.lookup clue (cluePositions grid)
>     return $ Map.fromList $ zip cells (map (:[]) word)

> maybeToList :: Maybe a -> [a]
> maybeToList Nothing  = []
> maybeToList (Just x) = [x]

Example
-------

A tiny 2x2 crossword for illustration:

> exampleGrid :: Grid
> exampleGrid = Grid
>   { clueLengths   = fromList [(Clue 1 Across, 2), (Clue 1 Down, 2)]
>   , cluePositions = fromList
>       [(Clue 1 Across, [(0,0), (0,1)]), (Clue 1 Down, [(0,0), (1,0)])]
>   }

> example :: IO ()
> example = do
>   let patch = mempty :: Patch
>
>   -- Answer 1 Across with "AB"
>   let patch1 = patch <> set (Clue 1 Across) "AB"
>       sol1   = toSolution patch1
>   putStrLn $ "After 1 Across = AB: " ++ show (valid exampleGrid sol1)
>
>   -- Answer 1 Down with "AC" — conflicts at (0,0): 'A' vs 'A' (ok!)
>   let patch2 = patch1 <> set (Clue 1 Down) "AC"
>       sol2   = toSolution patch2
>   putStrLn $ "After 1 Down = AC: " ++ show (valid exampleGrid sol2)
>
>   -- Delete 1 Across
>   let patch3 = patch2 <> delete (Clue 1 Across)
>       sol3   = toSolution patch3
>   putStrLn $ "After delete 1 Across: " ++ show (valid exampleGrid sol3)

> main :: IO ()
> main = example

Algebraic Scorecard
-------------------

  Closure         ✓  <> takes two Patches, returns a Patch — always
  Associativity   ✓  Map.unionWith is associative
  Identity        ✓  mempty = no patches; empty solution
  Idempotence     ✓  patching the same clue with the same answer twice = same patch
  Commutativity   ✗  last-write-wins: order matters on conflicts
  Inverses        ✗  no true inverse (delete is not invertible — what was the old value?)
  Annihilation    ✗  no absorbing element

Key idea: IDEMPOTENCE. `p <> p = p` — re-applying the same patch is a no-op.
This is a genuine upgrade from Ch4 (where idempotence was incidental via Map
deduplication; here it's structural and meaningful).
