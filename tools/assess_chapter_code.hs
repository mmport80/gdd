#!/usr/bin/env -S nix develop --command runghc
-- Assess the Haskell example in each chapter (code/chN/Algebra.lhs).
--
-- Mechanical checks only; the judgment criteria are in
-- docs/chapter-code-assessment.md.
--
-- Checks per chapter:
--   run        runghc exits 0 and prints something (gate)
--   sections   required headings are present (gate for ch4+; ch3 is reported)
--   laws       every law binding (`> testN = ...`) evaluates to True (gate)
--   scorecard  number of ✓ / ✗ rows in "Algebraic Scorecard" and whether any
--              law backs them (warning if ✓ rows exist and there are no law
--              bindings at all)
--
-- Usage (from repo root; the shebang enters `nix develop` for the toolchain):
--   tools/assess_chapter_code.hs                  # all chapters
--   tools/assess_chapter_code.hs 4 6              # selected chapters
--   tools/assess_chapter_code.hs -h               # help
--
-- Exit status: 0 if every assessed chapter passes its gates, 1 otherwise.
module Main (main) where

import Control.Exception (IOException, try)
import Control.Monad (forM, unless)
import Data.Char (isDigit, isSpace, toLower)
import Data.List (dropWhileEnd, intercalate, isInfixOf, isPrefixOf, nub, sort, stripPrefix)
import Data.Maybe (catMaybes, mapMaybe)
import GHC.IO.Encoding (setLocaleEncoding, utf8)
import System.Directory (doesDirectoryExist, doesFileExist, getCurrentDirectory, listDirectory)
import System.Environment (getArgs)
import System.Exit (ExitCode (..), exitWith)
import System.FilePath ((</>))
import System.IO (hPutStrLn, stderr)
import System.Process (CreateProcess (..), proc, readCreateProcessWithExitCode)

runTimeout :: Int
runTimeout = 300

requiredHeadings :: [String]
requiredHeadings = ["Types", "Algebra", "Observations", "Example", "Algebraic Scorecard"]

usage :: String
usage = unlines
  [ "usage: tools/assess_chapter_code.hs [N ...]"
  , ""
  , "  N            chapter numbers to assess (default: all code/chN with an Algebra.lhs)"
  , "  -h, --help   show this help"
  , ""
  , "Run from the repository root. The shebang runs the script inside `nix develop`."
  ]

-- Output of one external command: exit code, stdout, stderr.
type Output = (ExitCode, String, String)

-- Run a command in the repo root under `timeout`. A missing executable or a
-- spawn failure is reported as exit 127 with the exception text on stderr.
runIn :: FilePath -> String -> [String] -> IO Output
runIn root prog args = do
  let spec = (proc "timeout" (show runTimeout : prog : args)) { cwd = Just root }
  r <- try (readCreateProcessWithExitCode spec "")
  pure $ case r of
    Left e -> (ExitFailure 127, "", show (e :: IOException))
    Right out -> out

exitCodeInt :: ExitCode -> Int
exitCodeInt ExitSuccess = 0
exitCodeInt (ExitFailure n) = n

-- `timeout` reports an expired run as exit 124.
timedOut :: ExitCode -> Bool
timedOut ec = exitCodeInt ec == 124

-- First line mentioning "error" (case-insensitive), else the last line.
firstError :: String -> String
firstError err =
  case filter (("error" `isInfixOf`) . map toLower) (lines err) of
    (l : _) -> l
    [] -> lastLine err

lastLine :: String -> String
lastLine s = case lines s of
  [] -> ""
  ls -> last ls

trimEnd :: String -> String
trimEnd = dropWhileEnd isSpace

-- Run the chapter's example with runghc.

data RunResult = RunResult { runOk :: Bool, runDetail :: String }

checkRun :: FilePath -> FilePath -> IO RunResult
checkRun root path = do
  (ec, out, err) <- runIn root "runghc" [path]
  let rc = exitCodeInt ec
      outLines = length (filter (not . null) (lines out))
      hasOutput = any (not . isSpace) out
  pure $
    if timedOut ec
      then RunResult False "timeout"
      else
        let detail = "exit " ++ show rc ++ ", " ++ show outLines ++ " output lines"
         in if rc /= 0
              then RunResult False (detail ++ "; stderr: " ++ firstError err)
              else RunResult hasOutput detail

-- Required section headings (a line equal to the heading, ignoring trailing space).

missingSections :: String -> [String]
missingSections contents =
  [h | h <- requiredHeadings, h `notElem` map trimEnd (lines contents)]

-- Law bindings: lines of the form `> testN = ...`.

lawName :: String -> Maybe String
lawName l = do
  rest <- stripPrefix "> " l
  if "test" `isPrefixOf` rest
    then do
      let name = takeWhile isIdent rest
      case dropWhile isSpace (drop (length name) rest) of
        ('=' : _) -> Just name
        _ -> Nothing
    else Nothing
  where
    isIdent c = c == '_' || c `elem` ['A'..'Z'] ++ ['a'..'z'] ++ ['0'..'9']

lawNames :: String -> [String]
lawNames contents = nub (mapMaybe lawName (lines contents))

data LawResult = LawResult
  { lawOk :: Bool
  , lawCount :: Int
  , lawFailed :: [String]
  , lawDetail :: String
  }

-- Evaluate every law binding with `ghc -e` and check each one prints True.
checkLaws :: FilePath -> FilePath -> String -> IO LawResult
checkLaws root path contents = do
  let names = lawNames contents
      count = length names
  if null names
    then pure (LawResult True 0 [] "no law bindings")
    else do
      let items = [ "(\"" ++ n ++ "\", " ++ n ++ ")" | n <- names ]
          expr = "mapM_ (\\(n, v) -> putStrLn (n ++ \" \" ++ show v)) ["
                 ++ intercalate ", " items ++ "]"
      (ec, out, err) <- runIn root "ghc" ["-v0", "-e", expr, path]
      let outLines = lines out
          failed = [n | n <- names, (n ++ " True") `notElem` outLines]
          trueCount = count - length failed
      pure $
        if timedOut ec
          then LawResult False count names "timeout"
          else
            if exitCodeInt ec /= 0
              then LawResult False count names ("ghc -e failed: " ++ lastLine err)
              else
                LawResult (null failed) count failed
                  (show trueCount ++ "/" ++ show count ++ " laws True")

-- Algebraic Scorecard rows: indented, then a name, then ✓ or ✗.

data Scorecard = Scorecard
  { scHolds :: Int
  , scFails :: Int
  , scWarning :: Maybe String
  }

scoreRow :: Char -> String -> Bool
scoreRow mark line = case line of
  (c : _) | isSpace c ->
    case dropWhile isSpace line of
      (f : _) | f `notElem` marks ->
        case break (`elem` marks) (dropWhile isSpace line) of
          (pre, m : _) -> m == mark && length pre >= 2 && isSpace (last pre)
          _ -> False
      _ -> False
  _ -> False
  where
    marks = "✓✗" :: String

checkScorecard :: String -> Int -> Scorecard
checkScorecard contents count =
  case dropWhile (not . ("Algebraic Scorecard" `isInfixOf`)) (lines contents) of
    [] -> Scorecard 0 0 (Just "no scorecard")
    rows ->
      let holds = length (filter (scoreRow '✓') rows)
          fails = length (filter (scoreRow '✗') rows)
          warning
            | holds > 0 && count == 0 =
                Just (show holds ++ " ✓ claims but no machine-checked law bindings")
            | otherwise = Nothing
       in Scorecard holds fails warning

-- Assess one chapter: print its report block, return True on pass.

assess :: FilePath -> Int -> IO Bool
assess root ch = do
  let path = "code/ch" ++ show ch ++ "/Algebra.lhs"
  exists <- doesFileExist (root </> path)
  contents <- if exists then readFile (root </> path) else pure ""
  run <- checkRun root path
  let missing = missingSections contents
      gated = ch >= 4
      sectionsOk = null missing || not gated
  laws <- checkLaws root path contents
  let sc = checkScorecard contents (lawCount laws)
      passed = runOk run && lawOk laws && sectionsOk
      lawLine =
        "  laws:      " ++ lawDetail laws
          ++ (if null (lawFailed laws) then "" else " FAILED: " ++ intercalate ", " (lawFailed laws))
  putStrLn ("ch" ++ show ch ++ "  " ++ (if passed then "PASS" else "FAIL") ++ "  " ++ path)
  putStrLn ("  run:       " ++ (if runOk run then "ok" else "FAIL") ++ " (" ++ runDetail run ++ ")")
  putStrLn $
    if null missing
      then "  sections:  ok"
      else
        "  sections:  missing " ++ intercalate ", " missing
          ++ (if gated then "" else " (not gated before ch4)")
  putStrLn lawLine
  putStrLn ("  scorecard: " ++ show (scHolds sc) ++ " ✓, " ++ show (scFails sc) ++ " ✗")
  mapM_ (\w -> putStrLn ("  warning:   " ++ w)) (scWarning sc)
  putStrLn ""
  pure passed

-- Chapters with an Algebra.lhs under code/, in numeric order.
discoverChapters :: FilePath -> IO [Int]
discoverChapters root = do
  let codeDir = root </> "code"
  entries <- listDirectory codeDir
  found <- forM entries $ \e -> do
    hasFile <- doesFileExist (codeDir </> e </> "Algebra.lhs")
    let num = drop 2 e
    pure $
      if hasFile && "ch" `isPrefixOf` e && not (null num) && all isDigit num
        then Just (read num :: Int)
        else Nothing
  pure (sort (catMaybes found))

parseChapter :: String -> Maybe Int
parseChapter s
  | not (null s) && all isDigit s = Just (read s)
  | otherwise = Nothing

die :: String -> IO a
die msg = do
  hPutStrLn stderr msg
  hPutStrLn stderr usage
  exitWith (ExitFailure 2)

main :: IO ()
main = do
  setLocaleEncoding utf8
  args <- getArgs
  if any (`elem` ["-h", "--help"]) args
    then putStr usage >> exitWith ExitSuccess
    else pure ()

  chapters <- case args of
    [] -> pure []
    _ -> mapM parseArg args
  root <- getCurrentDirectory
  hasCode <- doesDirectoryExist (root </> "code")
  unless hasCode $ do
    hPutStrLn stderr "run from the repository root (no code/ directory here)"
    exitWith (ExitFailure 2)

  targets <- if null chapters then discoverChapters root else pure chapters
  results <- mapM (assess root) targets
  let passed = length (filter id results)
      total = length results
  putStrLn (show passed ++ "/" ++ show total ++ " chapters pass the gates")
  exitWith (if passed == total then ExitSuccess else ExitFailure 1)
  where
    parseArg a
      | "-" `isPrefixOf` a = die ("unknown option: " ++ a)
      | otherwise = case parseChapter a of
          Just n -> pure n
          Nothing -> die ("not a chapter number: " ++ a)
