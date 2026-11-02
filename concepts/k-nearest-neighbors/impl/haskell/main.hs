-- k-nearest neighbors classification, using only Haskell's base library.
--
-- Each test seed is labelled with the majority variety among its k nearest
-- training seeds, by Euclidean distance. There's no CSV reader in base, so
-- we split lines ourselves and find each column by its header name.

import Data.List (elemIndex, nub, sortOn)
import System.Environment (getArgs)
import Text.Printf (printf)

k :: Int
k = 5

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
nearest :: [Seed] -> (Double, Double) -> [Seed]
nearest train point = take k (sortOn (\(features, _) -> distance point features) train)

-- The variety with the most votes. nub lists each variety once, in the order
-- it first appears. foldl1 walks the counts left to right, and > is strict,
-- so on equal counts the earlier variety would win.
majority :: [String] -> String
majority labels = fst (foldl1 pick counts)
  where
    counts = [(label, length (filter (== label) labels)) | label <- nub labels]
    pick best candidate = if snd candidate > snd best then candidate else best

classify :: [Seed] -> (Double, Double) -> String
classify train point = majority [label | (_, label) <- nearest train point]

main :: IO ()
main = do
  [path] <- getArgs
  text <- readFile path
  let seeds = readSeeds text
      train = [seed | ("train", seed) <- seeds]
      test = [seed | ("test", seed) <- seeds]
      correct = length [() | (point, label) <- test, classify train point == label]
      accuracy = fromIntegral correct / fromIntegral (length test) :: Double
  printf "train_count %d\n" (length train)
  printf "test_count %d\n" (length test)
  printf "correct %d\n" correct
  printf "accuracy %.6f\n" accuracy
