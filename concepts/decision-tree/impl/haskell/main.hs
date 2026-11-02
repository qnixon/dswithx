-- A decision tree classifier (CART with Gini impurity), using only Haskell's
-- base library.
--
-- Grows a tree on the training days by always making the split that leaves
-- the two sides purest, then predicts rain for the test days. Prints the tree
-- in preorder: each node is either a split (feature and threshold) or a leaf
-- (its prediction).

import Data.List (elemIndex, minimumBy, nub, partition, sort)
import Data.Ord (comparing)
import System.Environment (getArgs)
import Text.Printf (printf)

features :: [String]
features = ["humidity", "pressure", "wind"]

maxDepth, minSize :: Int
maxDepth = 3
minSize = 5

-- One day: its feature values, in the order of features, and whether it rained.
type Day = ([Double], Bool)

-- A tree is either a leaf holding its prediction or a split holding a feature
-- position, a threshold, and two smaller trees. The type refers to itself,
-- which is all Haskell needs for a recursive data structure.
data Tree = Leaf Bool | Split Int Double Tree Tree

-- Split a line at every comma. break returns the text before the first comma
-- and the rest, which still starts with the comma.
splitOnComma :: String -> [String]
splitOnComma line = case break (== ',') line of
  (field, ',' : rest) -> field : splitOnComma rest
  (field, _) -> [field]

-- The training days and the test days. The header gives each column's position.
readDays :: String -> ([Day], [Day])
readDays text = case lines text of
  header : rows ->
    let names = splitOnComma header
        at name = case elemIndex name names of
          Just index -> index
          Nothing -> error ("no column " ++ name)
        parse row =
          let fields = splitOnComma row
           in ( fields !! at "split" == "train"
              , ([read (fields !! at name) | name <- features], fields !! at "rain" == "yes")
              )
        tagged = [parse row | row <- rows, not (null row)]
        (train, test) = partition fst tagged
     in (map snd train, map snd test)
  [] -> error "empty file"

-- Chance that two days drawn at random (with replacement) disagree.
gini :: [Bool] -> Double
gini labels = 1 - p * p - (1 - p) * (1 - p)
  where
    p = fromIntegral (length (filter id labels)) / fromIntegral (length labels)

-- Strictly more than half must be rainy to predict rain, so an even split
-- predicts "no".
majority :: [Bool] -> Bool
majority labels = 2 * length (filter id labels) > length labels

-- The days at or below the threshold, then the days above it.
divide :: Int -> Double -> [Day] -> ([Day], [Day])
divide f threshold = partition (\(x, _) -> x !! f <= threshold)

-- The weighted Gini impurity left after splitting at this feature and threshold.
score :: [Day] -> Int -> Double -> Double
score days f threshold =
  (size left * gini (map snd left) + size right * gini (map snd right)) / size days
  where
    (left, right) = divide f threshold days
    size = fromIntegral . length

-- Every candidate split: features in column order, and for each, the
-- midpoints between neighboring distinct values, from smallest to largest.
candidates :: [Day] -> [(Int, Double)]
candidates days =
  [ (f, (a + b) / 2)
  | f <- [0 .. length features - 1]
  , let values = sort (nub [x !! f | (x, _) <- days])
  , (a, b) <- zip values (tail values)
  ]

-- The candidate with the lowest score, with that score, or Nothing when every
-- feature has a single value. On a tie minimumBy keeps the earlier candidate,
-- so the first split tried wins.
bestSplit :: [Day] -> Maybe (Double, Int, Double)
bestSplit days = case candidates days of
  [] -> Nothing
  splits -> Just (minimumBy (comparing (\(s, _, _) -> s)) scored)
    where
      scored = [(score days f t, f, t) | (f, t) <- splits]

-- Grow the tree from the root at depth 0. A node becomes a leaf when it is
-- pure, has fewer than minSize days, reaches maxDepth, or no split makes the
-- sides purer. The guards (|) are tried from top to bottom.
grow :: Int -> [Day] -> Tree
grow depth days
  | gini labels == 0 || length days < minSize || depth == maxDepth = leaf
  | otherwise = case bestSplit days of
      Just (s, f, threshold)
        | s < gini labels ->
            let (left, right) = divide f threshold days
             in Split f threshold (grow (depth + 1) left) (grow (depth + 1) right)
      _ -> leaf
  where
    labels = map snd days
    leaf = Leaf (majority labels)

-- Follow the splits down to a leaf. Each equation matches one kind of node.
predict :: Tree -> [Double] -> Bool
predict (Leaf rain) _ = rain
predict (Split f threshold left right) x
  | x !! f <= threshold = predict left x
  | otherwise = predict right x

-- Every node in preorder: the node itself, then its left side, then its right.
preorder :: Tree -> [Tree]
preorder node@(Split _ _ left right) = node : preorder left ++ preorder right
preorder leaf = [leaf]

-- The output lines for one node, given its number.
describe :: Int -> Tree -> [String]
describe k (Leaf rain) = [printf "node_%d_predict %s" k (if rain then "yes" else "no" :: String)]
describe k (Split f threshold _ _) =
  [ printf "node_%d_feature %s" k (features !! f)
  , printf "node_%d_threshold %.6f" k threshold
  ]

isLeaf :: Tree -> Bool
isLeaf (Leaf _) = True
isLeaf _ = False

-- How many days the tree labels correctly.
countCorrect :: Tree -> [Day] -> Int
countCorrect tree days = length [() | (x, rain) <- days, predict tree x == rain]

main :: IO ()
main = do
  [path] <- getArgs
  text <- readFile path
  let (train, test) = readDays text
      tree = grow 0 train
      nodes = preorder tree
      correct = countCorrect tree test
      fraction n days = fromIntegral n / fromIntegral (length days) :: Double
  printf "train_count %d\n" (length train)
  printf "test_count %d\n" (length test)
  -- zip pairs each node with its number, counting from 1.
  mapM_ putStrLn (concat (zipWith describe [1 ..] nodes))
  printf "leaves %d\n" (length (filter isLeaf nodes))
  printf "train_accuracy %.6f\n" (fraction (countCorrect tree train) train)
  printf "correct %d\n" correct
  printf "accuracy %.6f\n" (fraction correct test)
