-- Categorical naive Bayes with add-one (Laplace) smoothing, using only
-- Haskell's base library.
--
-- Learns P(label) and P(feature value | label) by counting training rows, then
-- labels each test row with the label that has the highest log-probability.
-- base has no map type, so counts live in association lists: lists of
-- (key, count) pairs, searched with lookup.

import Data.List (group, minimumBy, nub, sort)
import Data.Maybe (fromMaybe)
import Data.Ord (Down (..), comparing)
import System.Environment (getArgs)
import Text.Printf (printf)

-- A row pairs each column name with its value, such as ("label", "spam").
type Row = [(String, String)]

features :: [String]
features = ["has_link", "mentions_money", "known_sender"]

-- Split a line at every comma. break returns the text before the first comma
-- and the rest, which still starts with the comma.
splitOnComma :: String -> [String]
splitOnComma line = case break (== ',') line of
  (field, ',' : rest) -> field : splitOnComma rest
  (field, _) -> [field]

-- Every data line, with its fields paired to the header's column names.
readRows :: String -> [Row]
readRows text = case lines text of
  header : rows -> [zip (splitOnComma header) (splitOnComma row) | row <- rows, not (null row)]
  [] -> error "empty file"

-- The value in a named column. lookup returns Maybe: Nothing if it is missing.
column :: String -> Row -> String
column name row = fromMaybe (error ("no column " ++ name)) (lookup name row)

-- How many times each key appears: sort brings equal keys together, group
-- gathers each run of them, and every group becomes (key, its length).
countAll :: Ord a => [a] -> [(a, Int)]
countAll keys = [(head run, length run) | run <- group (sort keys)]

-- A count from an association list, or 0 for a key never seen.
countOf :: Eq a => a -> [(a, Int)] -> Int
countOf key counts = fromMaybe 0 (lookup key counts)

-- The model is three sets of counts, all from the training rows.
data Model = Model
  { trainSize :: Int
  , labelCounts :: [(String, Int)]                    -- label -> rows
  , valueCounts :: [((String, String, String), Int)]  -- (feature, value, label) -> rows
  , distinctValues :: [(String, Int)]                 -- feature -> distinct values
  }

train :: [Row] -> Model
train rows = Model
  { trainSize = length rows
  , labelCounts = countAll [column "label" row | row <- rows]
  , valueCounts = countAll [(f, column f row, column "label" row) | row <- rows, f <- features]
  , distinctValues = [(f, length (nub [column f row | row <- rows])) | f <- features]
  }

-- Logs turn the product of probabilities into a sum, avoiding underflow.
-- Add-one smoothing means an unseen value never gets probability zero.
logScore :: Model -> Row -> String -> Double
logScore model row label =
  log (ratio labelCount (trainSize model))
    + sum [ log (ratio (countOf (f, column f row, label) (valueCounts model) + 1)
                       (labelCount + countOf f (distinctValues model)))
          | f <- features ]
  where
    labelCount = countOf label (labelCounts model)
    -- Counts are Ints; fromIntegral converts them so they can divide as Doubles.
    ratio a b = fromIntegral a / fromIntegral b

-- countAll sorted the labels, so they are in alphabetical order here.
-- minimumBy keeps the first of equal values, and Down flips the order so the
-- smallest is the highest score: an exact tie goes to the first label.
-- (maximumBy would keep the last, sending a tie to the wrong label.)
classify :: Model -> Row -> String
classify model row =
  minimumBy (comparing (\label -> Down (logScore model row label))) (map fst (labelCounts model))

main :: IO ()
main = do
  [path] <- getArgs
  text <- readFile path
  let rows = readRows text
      trainRows = [row | row <- rows, column "split" row == "train"]
      testRows = [row | row <- rows, column "split" row == "test"]
      model = train trainRows
      correct = length [row | row <- testRows, classify model row == column "label" row]
  printf "train_count %d\n" (length trainRows)
  printf "test_count %d\n" (length testRows)
  printf "correct %d\n" correct
  printf "accuracy %.6f\n" (fromIntegral correct / fromIntegral (length testRows) :: Double)
