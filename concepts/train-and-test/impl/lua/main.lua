-- Train and test error for polynomials of degree 1 to 8, using only Lua's
-- standard library.
--
-- Each polynomial is fitted by least squares to the training drives only:
-- we build the normal equations and solve them by Gaussian elimination. Then
-- we measure its root-mean-square error on the training drives and on the
-- test drives it never saw. A matrix is a table of row tables, indexed
-- from 1.

local MAX_DEGREE = 8

-- Returns two arrays of { x = speed, y = litres }: the training drives and
-- the test drives.
local function read_drives(path)
  local f = assert(io.open(path, "r"))
  local col = {}                     -- column number for each name
  local i = 0
  for field in f:read("l"):gmatch("[^,]+") do
    i = i + 1
    col[field] = i
  end
  local train, test = {}, {}
  for line in f:lines() do
    local fields = {}
    for field in line:gmatch("[^,]+") do
      fields[#fields + 1] = field
    end
    local point = { x = tonumber(fields[col.speed]), y = tonumber(fields[col.litres]) }
    local into = fields[col.split] == "train" and train or test
    into[#into + 1] = point
  end
  f:close()
  return train, test
end

-- Solve a x = b by Gaussian elimination with partial pivoting.
local function solve(a, b)
  local n = #b
  local m = {}                       -- the augmented matrix: b is column n + 1
  for i = 1, n do
    m[i] = table.move(a[i], 1, n, 1, {})  -- a copy of row i
    m[i][n + 1] = b[i]
  end
  for col = 1, n do
    -- Swap up the row with the largest entry in this column, which keeps the
    -- rounding error small. Swapping two rows swaps two table references.
    local pivot = col
    for r = col + 1, n do
      if math.abs(m[r][col]) > math.abs(m[pivot][col]) then
        pivot = r
      end
    end
    m[col], m[pivot] = m[pivot], m[col]
    for r = col + 1, n do
      local factor = m[r][col] / m[col][col]
      for c = col, n + 1 do
        m[r][c] = m[r][c] - factor * m[col][c]
      end
    end
  end
  -- Back substitution, from the last unknown up.
  local x = {}
  for r = n, 1, -1 do
    local total = m[r][n + 1]
    for c = r + 1, n do
      total = total - m[r][c] * x[c]
    end
    x[r] = total / m[r][r]
  end
  return x
end

-- Least squares: the coefficients c solve (Z^T Z) c = Z^T y, where row i of
-- Z is 1, z_i, z_i^2, ..., z_i^degree. Lua counts from 1, so entry i of a
-- row holds power i - 1.
local function fit(points, degree, scale)
  local size = degree + 1
  local a, b = {}, {}
  for i = 1, size do
    a[i] = {}
    for j = 1, size do
      a[i][j] = 0.0
    end
    b[i] = 0.0
  end
  for _, p in ipairs(points) do
    local z = scale(p.x)
    for i = 1, size do
      b[i] = b[i] + p.y * z ^ (i - 1)
      for j = 1, size do
        a[i][j] = a[i][j] + z ^ (i + j - 2)
      end
    end
  end
  return solve(a, b)
end

local function rmse(coefs, points, scale)
  local total = 0.0
  for _, p in ipairs(points) do
    local z = scale(p.x)
    local predicted = 0.0
    for i, c in ipairs(coefs) do
      predicted = predicted + c * z ^ (i - 1)
    end
    total = total + (predicted - p.y) ^ 2
  end
  return math.sqrt(total / #points)
end

local train, test = read_drives(arg[1])

-- Map the training speeds onto -1 to 1. Raw speeds to the 16th power (the
-- largest entry at degree 8) would swamp the small ones and make the
-- equations hard to solve accurately.
local low, high = math.huge, -math.huge
for _, p in ipairs(train) do
  low = math.min(low, p.x)
  high = math.max(high, p.x)
end
local mid, half = (low + high) / 2, (high - low) / 2
local function scale(x)
  return (x - mid) / half
end

print("train_count " .. #train)
print("test_count " .. #test)
local train_errors, test_errors = {}, {}
for degree = 1, MAX_DEGREE do
  local coefs = fit(train, degree, scale)
  train_errors[degree] = rmse(coefs, train, scale)
  test_errors[degree] = rmse(coefs, test, scale)
end
for degree, e in ipairs(train_errors) do
  print(string.format("train_rmse_d%d %.6f", degree, e))
end
for degree, e in ipairs(test_errors) do
  print(string.format("test_rmse_d%d %.6f", degree, e))
end
