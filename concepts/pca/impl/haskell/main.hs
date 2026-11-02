-- Principal component analysis by power iteration, using only Haskell's base
-- library.
--
-- Standardizes the four scores, builds their correlation matrix, and finds
-- the top two eigenvectors (the principal components): power iteration finds
-- the first, then deflation removes it from the matrix so the same steps find
-- the second. A matrix is a list of rows, and a vector is a list of numbers.

import Control.Monad (forM_)
import Data.List (elemIndex, transpose)
import System.Environment (getArgs)
import Text.Printf (printf)

subjects :: [String]
subjects = ["math", "physics", "reading", "writing"]

steps :: Int
steps = 1000

-- Split a line at every comma, as in the descriptive statistics example.
splitOnComma :: String -> [String]
splitOnComma line = case break (== ',') line of
  (field, ',' : rest) -> field : splitOnComma rest
  (field, _) -> [field]

-- Where a column name sits in the header, counting from 0.
position :: [String] -> String -> Int
position header name = case elemIndex name header of
  Just index -> index
  Nothing -> error ("no column " ++ name)

-- The named columns of every row, read as Doubles, in the order asked for.
readRows :: [String] -> String -> [[Double]]
readRows names text = case lines text of
  header : rows ->
    [[read (fields !! i) | i <- indexes] | row <- rows, not (null row), let fields = splitOnComma row]
    where
      indexes = map (position (splitOnComma header)) names
  [] -> error "empty file"

dot :: [Double] -> [Double] -> Double
dot u v = sum (zipWith (*) u v)

-- A matrix times a vector: each row of the matrix dotted with the vector.
matVec :: [[Double]] -> [Double] -> [Double]
matVec m v = map (`dot` v) m

normalize :: [Double] -> [Double]
normalize v = map (/ sqrt (dot v v)) v

-- Power iteration: multiply by the matrix and rescale, 1,000 times.
-- iterate builds the endless list v0, step v0, step (step v0), ..., and
-- !! picks the entry after 1,000 steps. Returns (eigenvalue, eigenvector).
topEigenvector :: [[Double]] -> (Double, [Double])
topEigenvector m = (dot v (matVec m v), v)
  where
    start = 1 : replicate (length m - 1) 0
    v' = iterate (normalize . matVec m) start !! steps
    -- An eigenvector can point either way; make its first entry positive.
    v = if head v' < 0 then map negate v' else v'

main :: IO ()
main = do
  [path] <- getArgs
  text <- readFile path
  let rows = readRows subjects text
      n = length rows
      k = length subjects
      count = fromIntegral n :: Double
      -- Standardize each column to mean 0 and (sample) standard deviation 1.
      standardize column = map (\x -> (x - m) / s) column
        where
          m = sum column / count
          s = sqrt (sum [(x - m) ^ (2 :: Int) | x <- column] / (count - 1))
      columns = map standardize (transpose rows)
      z = transpose columns
      -- The correlation matrix: the covariance of the standardized columns.
      corr = [[dot a b / (count - 1) | b <- columns] | a <- columns]
      (value1, pc1) = topEigenvector corr
      -- Deflation: subtract the first component's share, leaving the rest.
      deflated = [[c - value1 * a * b | (c, b) <- zip row pc1] | (row, a) <- zip corr pc1]
      (value2, pc2) = topEigenvector deflated
  printf "count %d\n" n
  forM_ (zip [1 :: Int ..] [(value1, pc1), (value2, pc2)]) $ \(c, (value, pc)) -> do
    printf "eigenvalue_%d %.6f\n" c value
    -- Standardized columns each have variance 1, so the total is k.
    printf "explained_%d %.6f\n" c (value / fromIntegral k)
    forM_ (zip subjects pc) $ \(subject, loading) ->
      printf "pc%d_%s %.6f\n" c subject loading
  printf "student_1_pc1 %.6f\n" (dot (head z) pc1)
  printf "student_1_pc2 %.6f\n" (dot (head z) pc2)
