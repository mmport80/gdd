-- Types
data Player = X | O
data Cell   = Empty | Taken Player
type Position = (Int, Int)  -- (0..2, 0..2)

newtype Board = Board (Map Position Cell)
newtype DeltaBoard = DeltaBoard Board  -- single move, opaque

-- Monoid instance
instance Semigroup Board where
    Board a <> Board b = Board (Map.union a b)  -- b wins conflicts, but DeltaBoard prevents them

instance Monoid Board where
    mempty = Board (Map.fromList [(p, Empty) | p <- allPositions])

-- Smart constructor — Maybe lives here only
mkDelta :: Position → Player → Board → Maybe DeltaBoard
mkDelta pos player (Board cells)
    | cells ! pos == Empty = Just $ DeltaBoard (Board (Map.singleton pos (Taken player)))
    | otherwise            = Nothing

-- Observations
hasWon :: Player → Board → Bool
hasWon player (Board cells) = any (all (== Taken player) . map (cells !)) winningLines

gameOver :: Board → Maybe GameOver
gameOver board
    | hasWon X board                = Just (Winner X)
    | hasWon O board                = Just (Winner O)
    | null (availableMoves board)   = Just Draw
    | otherwise                     = Nothing

availableMoves :: Board → [Position]
availableMoves (Board cells) = [p | p <- allPositions, cells ! p == Empty]
