-- k-means clustering (Lloyd's algorithm), using only Haskell's base library.
--
-- Starts from the first k points as centroids, then alternates two steps until
-- no point changes cluster: assign each point to its nearest centroid, and move
-- each centroid to the mean of its points. Haskell has no while loop, so the
-- repetition is a function that calls itself with the new centroids.

import Data.List (elemIndex, minimumBy)
import Data.Ord (comparing)
import System.Environment (getArgs)
import Text.Printf (printf)

-- A point is a pair of coordinates, (x, y).
type Point = (Double, Double)

k :: Int
k = 3

maxIterations :: Int
maxIterations = 100

-- Split a line at every comma. break returns the text before the first comma
-- and the rest, which still starts with the comma.
splitOnComma :: String -> [String]
splitOnComma line = case break (== ',') line of
  (field, ',' : rest) -> field : splitOnComma rest
  (field, _) -> [field]

-- The x and y columns as points. The header gives their positions.
readPoints :: String -> [Point]
readPoints text = case lines text of
  header : rows
    | Just xi <- elemIndex "x" (splitOnComma header)
    , Just yi <- elemIndex "y" (splitOnComma header) ->
        [ (read (fields !! xi), read (fields !! yi))
        | row <- rows, not (null row), let fields = splitOnComma row ]
  _ -> error "no x or y column"

-- Squared Euclidean distance. It ranks centroids in the same order as the
-- distance itself, so finding the nearest one needs no sqrt.
squaredDistance :: Point -> Point -> Double
squaredDistance (x1, y1) (x2, y2) = (x1 - x2) ^ (2 :: Int) + (y1 - y2) ^ (2 :: Int)

-- The index of the closest centroid. zip [0 ..] numbers the centroids, and
-- minimumBy keeps the first of equal distances, so a tie goes to the lower index.
nearest :: [Point] -> Point -> Int
nearest centroids p =
  fst (minimumBy (comparing snd) [(j, squaredDistance p c) | (j, c) <- zip [0 ..] centroids])

-- Move each centroid to the mean of its points. An empty cluster keeps its
-- old centroid.
update :: [Point] -> [Int] -> [Point] -> [Point]
update points assignment centroids =
  [ if null members then c else (mean (map fst members), mean (map snd members))
  | (j, c) <- zip [0 ..] centroids
  , let members = [p | (p, a) <- zip points assignment, a == j] ]
  where
    mean values = sum values / fromIntegral (length values)

-- One assignment step, then either stop or update and go again. The previous
-- assignment is Maybe a list: Nothing before the first pass, so the first
-- comparison always counts as a change. Returns the number of assignment
-- steps, the final assignment, and the final centroids.
run :: [Point] -> Int -> Maybe [Int] -> [Point] -> (Int, [Int], [Point])
run points iterations previous centroids
  | Just assignment == previous = (step, assignment, centroids)
  | step == maxIterations = (step, assignment, moved)
  | otherwise = run points step (Just assignment) moved
  where
    step = iterations + 1
    assignment = map (nearest centroids) points
    moved = update points assignment centroids

main :: IO ()
main = do
  [path] <- getArgs
  text <- readFile path
  let points = readPoints text
      (iterations, assignment, centroids) = run points 0 Nothing (take k points)
      sizes = [length (filter (== j) assignment) | j <- [0 .. k - 1]]
      inertia = sum [squaredDistance p (centroids !! a) | (p, a) <- zip points assignment]
  printf "iterations %d\n" iterations
  -- Clusters are numbered from 0 inside the program and from 1 in the output.
  mapM_ (\(j, (x, y)) -> printf "centroid_%d_x %.6f\ncentroid_%d_y %.6f\n" j x j y)
    (zip [1 :: Int ..] centroids)
  mapM_ (\(j, size) -> printf "size_%d %d\n" j size) (zip [1 :: Int ..] sizes)
  printf "inertia %.6f\n" inertia
