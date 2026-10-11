-- Hello world++ for exercising the tessera wrapper.
--
-- Run from the repo root:
--   runghc tools/hello_wrapper.hs
--   runghc tools/hello_wrapper.hs Ada
--   runghc tools/hello_wrapper.hs Ada --fail   (exits 3, writes to stderr)
--
-- Covers: positional args, stdout, stderr, and a non-zero exit code.
module Main (main) where

import Control.Monad (when)
import System.Environment (getArgs)
import System.Exit (exitWith, ExitCode (..))
import System.IO (hPutStrLn, stderr)

main :: IO ()
main = do
  args <- getArgs
  let failRequested = "--fail" `elem` args
      names = filter (/= "--fail") args
      name = case names of
        (n : _) -> n
        []      -> "world"
  putStrLn ("Hello, " ++ name ++ "!")
  putStrLn ("argument count: " ++ show (length args))
  when failRequested $ do
    hPutStrLn stderr "hello_wrapper: --fail requested, exiting with 3"
    exitWith (ExitFailure 3)
  putStrLn "done"
