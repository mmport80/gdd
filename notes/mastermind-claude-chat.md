# Mastermind — Claude discussion notes

Source: https://claude.ai/share/026bdca4-e1b6-45fb-9bb1-24f9fc797982
Date: 4 Apr 2026

---

## Rules stated

- Secret code: sequence of N positions, each one of K colours (classic: 4 positions, 6 colours, repetition allowed)
- Codebreaker submits a guess (another length-N sequence)
- Codemaker responds with:
  - Black pegs: correct colour, correct position
  - White pegs: correct colour, wrong position
- Goal: determine the secret code; game ends when you get N black pegs
- Classic Mastermind gives 10 guesses (termination rule, outside the algebra)

## What are we modeling?

Three options considered:

A) The guess itself (a single Code)
B) A single clue: a (Code, Blacks, Whites) triple
C) The knowledge state — what we know about the secret from all guesses so far

The idempotency intuition ("guessing the same thing twice tells you nothing new") pointed at (C) initially — a knowledge/information algebra.

## Knowledge / semilattice angle (explored then set aside)

Candidate type:

```haskell
type Knowledge = Set Code  -- all codes still consistent with clues so far
```

- `combine = Set.intersection` — semilattice (idempotent, commutative, associative)
- `fromClue` filters universe to codes that would produce the same (blacks, whites) response
- `won :: Knowledge -> Bool` — knowledge collapses to singleton

Worked example (N=2, 3 colours):
- Universe: RR, RB, RG, BR, BB, BG, GR, GB, GG (9 codes)
- Secret: RB (hidden)
- Guess RG -> blacks=1, whites=0 -> fromClue = {RR, RB}
- Guess BG -> blacks=0, whites=1 -> fromClue = {RB, GR}
- combine: {RR, RB} ∩ {RB, GR} = {RB} -> won!

BUT: `won :: Knowledge -> Bool` is the *solver's* win condition, not the *player's*. A 7-year-old wins by submitting the right guess and getting blacks == N, not by inspecting a set. Two different things:
- Player wins — blacks == N on a clue. Immediate, concrete, experiential.
- Solver knows — Set.size k == 1. Abstract, deductive.

Decision: **solver path is wrong for the chapter.** Model the player's experience instead.

## Final model: Game = [Clue]

```haskell
type Code   = [Colour]
data Colour = Red | Blue | Green | Yellow | Orange | Purple

data Clue   = Clue { guess :: Code, blacks :: Int, whites :: Int }

type Game   = [Clue]

-- Operations
newGame  :: Game
newGame  = []

guess    :: Code -> Code -> Game -> Game
guess secret code game = game ++ [Clue code b w]
  where (b, w) = score secret code

-- Outside the algebra
won  :: Game -> Bool
won  = any (\c -> blacks c == 4)

lost :: Game -> Bool
lost game = length game >= 10 && not (won game)
```

### Properties

- Identity: `newGame = []` ✓
- Associativity: list append is associative ✓
- Commutativity: ✗ — order of guesses matters (correct for player experience)
- Idempotency: ✗ — same guess twice duplicates the clue (pointless but allowed, keep it honest)

**Monoid under append.** Not every algebra needs to be a semilattice.

## Key insight: distributed feedback

Unlike previous games where validity was a final snapshot, Mastermind's feedback is woven into each turn. Each `Clue` carries its own score — the check happens at guess time, not game end.

### Distribution property (monoid homomorphism)

```haskell
won (g1 <> g2) = won g1 || won g2
```

`won = any wonClue` distributes over list concatenation naturally. Monoid homomorphism from `(Game, <>)` to `(Bool, ||)`.

This works *because* each Clue carries its own score — factoring done at construction time in `guess`, not at query time.

### Asymmetry: blacks vs whites

- Blacks — local, positional, distributable (each position independent)
- Whites — global, relational, NOT distributable (requires colour histogram across positions, minus blacks)

Structural fact about Mastermind: whites resist decomposition. Arguably why the game is interesting.

## Score helper

```haskell
score :: Code -> Code -> (Int, Int)
score secret guess = (blacks, whites)
  where
    blacks = length $ filter id $ zipWith (==) secret guess
    whites = -- correct colours, wrong positions

consistent :: Clue -> Code -> Bool
consistent clue secret = score secret (guess clue) == (blacks clue, whites clue)
```

## Pattern comparison with previous games

- Previous games: validity was a final snapshot — play, then check at end
- Mastermind: codemaker responds to every guess — each move carries its own feedback
- Validity is distributed across each individual guess — **new and interesting**

## Open questions / next steps

- Nail down the laws formally
- Fill in `whites` implementation
- Write the chapter
- The `lost` check needs `length` (inherently global) — asymmetry with `won` (distributes cleanly). Worth highlighting?
