-- Simple linear regression by least squares, using only Haskell's base library.
--
-- Fits score = intercept + slope * hours. The base library has no regression,
-- correlation, or mean, so the sums are written out and the formulas stay
-- visible. There's no CSV reader either, so we split lines ourselves.

import Data.List (elemIndex)
import System.Environment (getArgs)
import Text.Printf (printf)

xColumn, yColumn :: String
xColumn = "hours"
yColumn = "score"

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

mean :: [Double] -> Double
mean values = sum values / fromIntegral (length values)

main :: IO ()
main = do
  [path] <- getArgs
  text <- readFile path
  let xs = readColumn xColumn text
      ys = readColumn yColumn text
      -- First pass: the means.
      meanX = mean xs
      meanY = mean ys
      -- Second pass: deviations from the means. zip pairs each hours value
      -- with the score on the same row.
      sxx = sum [(x - meanX) * (x - meanX) | x <- xs]
      syy = sum [(y - meanY) * (y - meanY) | y <- ys]
      sxy = sum [(x - meanX) * (y - meanY) | (x, y) <- zip xs ys]
      slope = sxy / sxx
      intercept = meanY - slope * meanX
      r = sxy / sqrt (sxx * syy)
      results =
        [ ("slope", slope)
        , ("intercept", intercept)
        , ("r", r)
        , ("r_squared", r * r)
        ]
  printf "count %d\n" (length xs)
  mapM_ (\(name, value) -> printf "%s %.6f\n" name value) results
