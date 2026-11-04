-- Train and test error for polynomials of degree 1 to 8, using only
-- Haskell's base library.
--
-- Each polynomial is fitted by least squares to the training drives only:
-- we build the normal equations and solve them by Gaussian elimination. Then
-- we measure its root-mean-square error on the training drives and on the
-- test drives it never saw. A matrix is a list of rows.

import Control.Monad (forM_)
import Data.List (elemIndex, maximumBy)
import Data.Ord (comparing)
import System.Environment (getArgs)
import Text.Printf (printf)

maxDegree :: Int
maxDegree = 8

-- Split a line at every comma. break returns the text before the first comma
-- and the rest, which still starts with the comma.
splitOnComma :: String -> [String]
splitOnComma line = case break (== ',') line of
  (field, ',' : rest) -> field : splitOnComma rest
  (field, _) -> [field]

-- Every drive as (split, (speed, litres)), in file order.
readDrives :: String -> [(String, (Double, Double))]
readDrives text = case lines text of
  [] -> error "empty file"
  headerLine : rows ->
    [ (field "split", (read (field "speed"), read (field "litres")))
    | row <- rows
    , not (null row)
    , let fields = splitOnComma row
          field name = case elemIndex name header of
            Just index -> fields !! index
            Nothing -> error ("no column " ++ name)
    ]
    where
      header = splitOnComma headerLine

-- Solve a x = b by Gaussian elimination with partial pivoting. Each row of
-- the augmented matrix is a row of a with its entry of b on the end.
solve :: [[Double]] -> [Double] -> [Double]
solve a b = backSubstitute (eliminate (zipWith (\row v -> row ++ [v]) a b))

-- Move the row with the largest first entry to the top, which keeps the
-- rounding error small, and subtract a multiple of it from every other row
-- so their first entries become 0. Those rows, without their first column,
-- are a smaller system of the same kind, so we recurse. The result is the
-- upper triangle, one row shorter each time.
eliminate :: [[Double]] -> [[Double]]
eliminate [] = []
eliminate rows = pivot : eliminate (map reduce others)
  where
    leading row = case row of
      x : _ -> abs x
      [] -> 0
    pivotIndex = fst (maximumBy (comparing (leading . snd)) (zip [0 :: Int ..] rows))
    pivot = rows !! pivotIndex
    others = [row | (i, row) <- zip [0 ..] rows, i /= pivotIndex]
    reduce row = case (pivot, row) of
      (p : ps, r : rs) -> zipWith (\pc rc -> rc - (r / p) * pc) ps rs
      _ -> error "empty row"

-- Back substitution, from the last unknown up: each triangle row is
-- [coefficient, entries for the later unknowns ..., right-hand side].
backSubstitute :: [[Double]] -> [Double]
backSubstitute [] = []
backSubstitute (row : rows) = case row of
  coefficient : rest ->
    let later = backSubstitute rows
        rhs = last rest
        known = sum (zipWith (*) (init rest) later)
     in (rhs - known) / coefficient : later
  [] -> error "empty row"

-- Least squares: the coefficients c solve (Z^T Z) c = Z^T y, where row i of
-- Z is 1, z_i, z_i^2, ..., z_i^degree.
fit :: [(Double, Double)] -> Int -> [Double]
fit points degree = solve a b
  where
    powers = [0 .. degree]
    a = [[sum [z ^ (i + j) | (z, _) <- points] | j <- powers] | i <- powers]
    b = [sum [y * z ^ i | (z, y) <- points] | i <- powers]

rmse :: [Double] -> [(Double, Double)] -> Double
rmse coefs points = sqrt (total / fromIntegral (length points))
  where
    predict z = sum [c * z ^ i | (c, i) <- zip coefs [0 :: Int ..]]
    total = sum [(predict z - y) ^ (2 :: Int) | (z, y) <- points]

main :: IO ()
main = do
  [path] <- getArgs
  text <- readFile path
  let drives = readDrives text
      train = [p | ("train", p) <- drives]
      test = [p | ("test", p) <- drives]
      -- Map the training speeds onto -1 to 1. Raw speeds to the 16th power
      -- (the largest entry at degree 8) would swamp the small ones and make
      -- the equations hard to solve accurately.
      low = minimum (map fst train)
      high = maximum (map fst train)
      mid = (low + high) / 2
      half = (high - low) / 2
      scaled points = [((x - mid) / half, y) | (x, y) <- points]
      fits = [fit (scaled train) d | d <- [1 .. maxDegree]]
      degrees = zip [1 :: Int ..] fits
  printf "train_count %d\n" (length train)
  printf "test_count %d\n" (length test)
  forM_ degrees $ \(d, coefs) ->
    printf "train_rmse_d%d %.6f\n" d (rmse coefs (scaled train))
  forM_ degrees $ \(d, coefs) ->
    printf "test_rmse_d%d %.6f\n" d (rmse coefs (scaled test))
