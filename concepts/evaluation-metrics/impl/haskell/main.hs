-- Evaluation metrics for a binary classifier, using only Haskell's base
-- library.
--
-- Reads each part's true label and the model's score, then reports the
-- confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
-- the accuracy of never flagging anything, and the area under the ROC curve.

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

-- Every part as (defective, score), in file order.
readParts :: String -> [(Bool, Double)]
readParts text = case lines text of
  [] -> error "empty file"
  headerLine : rows ->
    [ (field "defective" == "1", read (field "score"))
    | row <- rows
    , not (null row)
    , let fields = splitOnComma row
          field name = fields !! columnIndex header name
    ]
    where
      header = splitOnComma headerLine

-- fromIntegral turns an Int into a Double for division.
ratio :: Int -> Int -> Double
ratio a b = fromIntegral a / fromIntegral b

-- The confusion matrix and the metrics built from it, at one threshold.
report :: [(Bool, Double)] -> String -> Double -> IO ()
report parts suffix threshold = do
  -- A part is flagged when its score reaches the threshold. Each count is
  -- the parts with one combination of (flagged, defective).
  let count flagged defective =
        length [() | (d, s) <- parts, (s >= threshold) == flagged, d == defective]
      tp = count True True
      fp = count True False
      fn = count False True
      tn = count False False
      accuracy = ratio (tp + tn) (length parts)
      precision = ratio tp (tp + fp) -- of the flagged parts, how many are defective
      recall = ratio tp (tp + fn) -- of the defective parts, how many are flagged
      f1 = 2 * precision * recall / (precision + recall)
  printf "tp_at_%s %d\n" suffix tp
  printf "fp_at_%s %d\n" suffix fp
  printf "fn_at_%s %d\n" suffix fn
  printf "tn_at_%s %d\n" suffix tn
  printf "accuracy_at_%s %.6f\n" suffix accuracy
  printf "precision_at_%s %.6f\n" suffix precision
  printf "recall_at_%s %.6f\n" suffix recall
  printf "f1_at_%s %.6f\n" suffix f1

-- The chance that a random defective part outscores a random good one.
-- Compare every pair, scoring 2 for a win and 1 for a tie, so the count
-- stays a whole number until the final division.
auc :: [(Bool, Double)] -> Double
auc parts = ratio points (2 * length defective * length good)
  where
    defective = [s | (True, s) <- parts]
    good = [s | (False, s) <- parts]
    points = sum [pairPoints (compare d g) | d <- defective, g <- good]
    pairPoints GT = 2
    pairPoints EQ = 1
    pairPoints LT = 0 :: Int

main :: IO ()
main = do
  [path] <- getArgs
  text <- readFile path
  let parts = readParts text
      n = length parts
      defective = length (filter fst parts)
  printf "parts %d\n" n
  printf "defective %d\n" defective
  -- Never flagging anything is right about every good part.
  printf "baseline_accuracy %.6f\n" (ratio (n - defective) n)
  report parts "50" 0.5
  report parts "30" 0.3
  printf "auc %.6f\n" (auc parts)
