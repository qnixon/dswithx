-- 5-fold cross-validation for k-nearest neighbors, using only Haskell's
-- base library.
--
-- Splits the training seeds into 5 folds, scores each odd k from 1 to 15 by
-- holding out one fold at a time, picks the k with the best average
-- accuracy, and then scores that k once on the untouched test seeds.

import Data.List (elemIndex, nub, sortOn)
import System.Environment (getArgs)
import Text.Printf (printf)

folds :: Int
folds = 5

-- Odd k only, so two varieties can't tie.
ks :: [Int]
ks = [1, 3 .. 15]

-- A seed is its (length, width) in millimetres and its variety.
type Seed = ((Double, Double), String)

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

-- Every row as a seed, paired with its split ("train" or "test").
readSeeds :: String -> [(String, Seed)]
readSeeds text = case lines text of
  [] -> error "empty file"
  headerLine : rows ->
    [ (field "split", ((read (field "length_mm"), read (field "width_mm")), field "variety"))
    | row <- rows
    , not (null row)
    , let fields = splitOnComma row
          field name = fields !! columnIndex header name
    ]
    where
      header = splitOnComma headerLine

distance :: (Double, Double) -> (Double, Double) -> Double
distance (l1, w1) (l2, w2) = sqrt ((l1 - l2) ^ (2 :: Int) + (w1 - w2) ^ (2 :: Int))

-- Sort the training seeds by distance and keep the first k. sortOn is stable,
-- so seeds at exactly equal distances stay in file order.
nearest :: Int -> [Seed] -> (Double, Double) -> [Seed]
nearest k train point = take k (sortOn (\(features, _) -> distance point features) train)

-- The variety with the most votes. nub lists each variety once, in the order
-- it first appears. foldl1 walks the counts left to right, and > is strict,
-- so on equal counts the earlier variety would win.
majority :: [String] -> String
majority labels = fst (foldl1 pick counts)
  where
    counts = [(label, length (filter (== label) labels)) | label <- nub labels]
    pick best candidate = if snd candidate > snd best then candidate else best

classify :: Int -> [Seed] -> (Double, Double) -> String
classify k train point = majority [label | (_, label) <- nearest k train point]

countCorrect :: Int -> [Seed] -> [Seed] -> Int
countCorrect k train points =
  length [() | (point, label) <- points, classify k train point == label]

-- Fold f is rows f*size up to (f+1)*size. The rows are already shuffled, so
-- consecutive blocks make fair folds. splitAt cuts a list in two at a
-- position; cutting the second half again gives the fold and what follows.
cvAccuracy :: [Seed] -> Int -> Double
cvAccuracy train k = fromIntegral (sum (map foldCorrect [0 .. folds - 1])) / fromIntegral (length train)
  where
    size = length train `div` folds
    foldCorrect f =
      let (before, from) = splitAt (f * size) train
          (heldOut, after) = splitAt size from
       in countCorrect k (before ++ after) heldOut

-- The k with the highest accuracy. foldl1 walks left to right and > is
-- strict, so a tie keeps the smaller k.
bestK :: [(Int, Double)] -> Int
bestK scores = fst (foldl1 pick scores)
  where
    pick best candidate = if snd candidate > snd best then candidate else best

main :: IO ()
main = do
  [path] <- getArgs
  text <- readFile path
  let seeds = readSeeds text
      train = [seed | ("train", seed) <- seeds]
      test = [seed | ("test", seed) <- seeds]
      scores = [(k, cvAccuracy train k) | k <- ks]
      chosen = bestK scores
      -- Only now touch the test seeds, once, with the chosen k and all of train.
      correct = countCorrect chosen train test
  printf "train_count %d\n" (length train)
  printf "test_count %d\n" (length test)
  mapM_ (\(k, accuracy) -> printf "cv_accuracy_k%d %.6f\n" k accuracy) scores
  printf "best_k %d\n" chosen
  printf "test_correct %d\n" correct
  printf "test_accuracy %.6f\n" (fromIntegral correct / fromIntegral (length test) :: Double)
