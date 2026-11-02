-- Logistic regression by gradient descent, using only Haskell's base library.
--
-- Predicts whether a student passed from study hours and sleep. Each feature
-- is rescaled with the training rows' mean and standard deviation, then the
-- weights start at zero and take 1,000 steps of batch gradient descent on the
-- average log-loss. A matrix here is a list of rows, and the weights are a
-- list too: each step builds a new list from the old one.

import Data.List (elemIndex, transpose)
import System.Environment (getArgs)
import Text.Printf (printf)

learningRate :: Double
learningRate = 0.5

steps :: Int
steps = 1000

-- Split a line at every comma, as in the descriptive statistics example.
splitOnComma :: String -> [String]
splitOnComma line = case break (== ',') line of
  (field, ',' : rest) -> field : splitOnComma rest
  (field, _) -> [field]

-- A row is a function from a column name to that row's field, so
-- row "hours" gives the hours. The header says where each name sits.
type Row = String -> String

readRows :: String -> [Row]
readRows text = case lines text of
  header : rows -> [field (splitOnComma row) | row <- rows, not (null row)]
    where
      names = splitOnComma header
      field values name = case elemIndex name names of
        Just index -> values !! index
        Nothing -> error ("no column " ++ name)
  [] -> error "empty file"

sigmoid :: Double -> Double
sigmoid z = 1 / (1 + exp (-z))

dot :: [Double] -> [Double] -> Double
dot u v = sum (zipWith (*) u v)

mean :: [Double] -> Double
mean xs = sum xs / fromIntegral (length xs)

-- Sample standard deviation: divide by n - 1.
sd :: [Double] -> Double
sd xs = sqrt (sum [(x - m) ^ (2 :: Int) | x <- xs] / fromIntegral (length xs - 1))
  where
    m = mean xs

-- One step of gradient descent. The gradient for weight j is the mean of
-- (p - y) times input j, summed over every student before any weight moves.
-- transpose turns the rows into columns, so each column gives one weight's sum.
step :: [[Double]] -> [Double] -> [Double] -> [Double]
step xs ys weights = zipWith (\w g -> w - learningRate * g) weights gradient
  where
    errors = [sigmoid (dot weights x) - y | (x, y) <- zip xs ys]
    gradient = [dot errors column / fromIntegral (length xs) | column <- transpose xs]

main :: IO ()
main = do
  [path] <- getArgs
  text <- readFile path
  let rows = readRows text
      features r = [read (r "hours"), read (r "sleep")] :: [Double]
      label r = read (r "passed") :: Double
      train = [r | r <- rows, r "split" == "train"]
      test = [r | r <- rows, r "split" /= "train"]
      -- Scale with the training rows only. The leading 1 multiplies the intercept.
      columns = transpose (map features train)
      means = map mean columns
      sds = map sd columns
      scale x = 1 : zipWith3 (\v m s -> (v - m) / s) x means sds
      xs = map (scale . features) train
      ys = map label train
      -- iterate builds the endless list w0, step w0, step (step w0), ...
      -- and !! picks the entry after 1,000 steps. Haskell is lazy, so no
      -- sum is worked out until a weight is printed, and then each step
      -- calls for the one before. A chain 1,000 steps long is small enough
      -- that we don't need to force the weights any sooner.
      weights = iterate (step xs ys) [0, 0, 0] !! steps
      n = fromIntegral (length xs) :: Double
      logLoss =
        -sum [y * log p + (1 - y) * log (1 - p) | (x, y) <- zip xs ys, let p = sigmoid (dot weights x)] / n
      predict x = if sigmoid (dot weights (scale x)) >= 0.5 then 1 else 0
      correct = length [r | r <- test, predict (features r) == label r]
  printf "train_count %d\n" (length train)
  printf "test_count %d\n" (length test)
  -- The weights are a list of three, so a pattern takes them apart by name.
  case weights of
    [intercept, hours, sleep] -> do
      printf "intercept %.6f\n" intercept
      printf "weight_hours %.6f\n" hours
      printf "weight_sleep %.6f\n" sleep
    _ -> error "expected three weights"
  printf "log_loss %.6f\n" logLoss
  printf "correct %d\n" correct
  printf "accuracy %.6f\n" (fromIntegral correct / fromIntegral (length test) :: Double)
