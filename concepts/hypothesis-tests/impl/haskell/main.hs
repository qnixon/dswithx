-- Exact two-sided permutation test for a difference in means, using only
-- Haskell's base library.
--
-- If compost made no difference, the "compost" and "control" labels are
-- arbitrary, and any 8 of the 16 plants could have carried the compost
-- label. We try every one of those splits and count how many give a
-- difference at least as large as the one we observed. That fraction is the
-- p-value.

import Data.List (elemIndex)
import System.Environment (getArgs)
import Text.Printf (printf)

-- Split a line at every comma. break returns the text before the first comma
-- and the rest, which still starts with the comma.
splitOnComma :: String -> [String]
splitOnComma line = case break (== ',') line of
  (field, ',' : rest) -> field : splitOnComma rest
  (field, _) -> [field]

-- The position of a column in the header, or a stop with a message.
columnIndex :: [String] -> String -> Int
columnIndex header name = case elemIndex name header of
  Just index -> index
  Nothing -> error ("no column " ++ name)

-- Every row as (group, grams), in file order.
readPlants :: String -> [(String, Int)]
readPlants text = case lines text of
  [] -> error "empty file"
  headerLine : rows ->
    [ (field "group", read (field "grams"))
    | row <- rows
    , not (null row)
    , let fields = splitOnComma row
          field name = fields !! columnIndex header name
    ]
    where
      header = splitOnComma headerLine

-- The total of every way to choose k of the plants. Each plant is either in
-- the chosen group (add it and choose k - 1 from the rest) or not (choose
-- all k from the rest). The list has one total per split.
chosenTotals :: Int -> [Int] -> [Int]
chosenTotals 0 _ = [0]
chosenTotals _ [] = []
chosenTotals k (x : xs) = map (+ x) (chosenTotals (k - 1) xs) ++ chosenTotals k xs

main :: IO ()
main = do
  [path] <- getArgs
  text <- readFile path
  let plants = readPlants text
      control = [grams | ("control", grams) <- plants]
      compost = [grams | ("compost", grams) <- plants]
      n = length compost
      total = sum control + sum compost
      -- Both groups have n plants, so comparing totals is the same as
      -- comparing means, and Int totals stay whole numbers: no
      -- floating-point near-ties.
      observed = sum compost - sum control
      differences = [chosen - (total - chosen) | chosen <- chosenTotals n (control ++ compost)]
      splits = length differences
      -- Two-sided: a difference counts in either direction.
      asExtreme = length (filter (\d -> abs d >= abs observed) differences)
      -- fromIntegral turns an Int into a Double for division.
      mean xs = fromIntegral (sum xs) / fromIntegral (length xs) :: Double
  printf "control_count %d\n" (length control)
  printf "compost_count %d\n" n
  printf "control_mean %.6f\n" (mean control)
  printf "compost_mean %.6f\n" (mean compost)
  printf "observed_difference %.6f\n" (fromIntegral observed / fromIntegral n :: Double)
  printf "splits %d\n" splits
  printf "as_extreme %d\n" asExtreme
  printf "p_value %.6f\n" (fromIntegral asExtreme / fromIntegral splits :: Double)
