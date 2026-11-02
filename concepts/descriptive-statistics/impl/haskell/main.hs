-- Descriptive statistics on one CSV column, using only Haskell's base library.
--
-- Haskell has no loops and no variables that change: every value below is
-- defined once, and totals come from folds such as sum. The base library has
-- no mean, median, or variance, and no CSV reader, so we split lines ourselves.

import Data.List (elemIndex, sort)
import System.Environment (getArgs)
import Text.Printf (printf)

column :: String
column = "minutes"

-- Split a line at every comma. break returns the text before the first comma
-- and the rest, which still starts with the comma.
splitOnComma :: String -> [String]
splitOnComma line = case break (== ',') line of
  (field, ',' : rest) -> field : splitOnComma rest
  (field, _) -> [field]

-- The named column, read as Doubles. The header gives its position.
readColumn :: String -> String -> [Double]
readColumn name text = case lines text of
  header : rows
    | Just index <- elemIndex name (splitOnComma header) ->
        [read (splitOnComma row !! index) | row <- rows, not (null row)]
  _ -> error ("no column " ++ name)

-- The middle value of a sorted list, or the mean of the two middle values.
-- Lists count from 0: for n = 120 the middle pair is positions 59 and 60.
median :: [Double] -> Double
median sorted
  | odd n = sorted !! middle
  | otherwise = (sorted !! (middle - 1) + sorted !! middle) / 2
  where
    n = length sorted
    middle = n `div` 2

main :: IO ()
main = do
  [path] <- getArgs
  text <- readFile path
  let values = sort (readColumn column text)
      n = length values
      -- length gives an Int; fromIntegral converts it so it can divide a Double.
      count = fromIntegral n :: Double
      total = sum values
      mean = total / count
      -- Sample variance divides by n - 1, not n (Bessel's correction). The
      -- exponent's type is spelled out, or -Wall warns that it guessed Integer.
      variance = sum [(x - mean) ^ (2 :: Int) | x <- values] / (count - 1)
      results =
        [ ("sum", total)
        , ("mean", mean)
        , ("median", median values)
        , ("min", head values)
        , ("max", last values)
        , ("range", last values - head values)
        , ("variance", variance)
        , ("std_dev", sqrt variance)
        ]
  printf "count %d\n" n
  mapM_ (\(name, value) -> printf "%s %.6f\n" name value) results
