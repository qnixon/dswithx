-- Simple linear regression by least squares, using only Lua's standard
-- library.
--
-- Fits score = intercept + slope * hours. Lua has no regression,
-- correlation, or even sum function, so every total is a loop. Its one data
-- structure is the table, used here as an array: indexes start at 1, and #t
-- is the length.

-- Read the named columns into one array each, in file order.
local function read_columns(path, x_name, y_name)
  local f = assert(io.open(path, "r"))
  local header, x_col, y_col = f:read("l"), nil, nil
  local i = 0
  for field in header:gmatch("[^,]+") do
    i = i + 1
    if field == x_name then x_col = i end
    if field == y_name then y_col = i end
  end
  assert(x_col and y_col, "column not found")
  local xs, ys = {}, {}
  for line in f:lines() do
    local fields = {}
    for field in line:gmatch("[^,]+") do
      fields[#fields + 1] = field
    end
    xs[#xs + 1] = tonumber(fields[x_col])
    ys[#ys + 1] = tonumber(fields[y_col])
  end
  f:close()
  return xs, ys
end

local function mean(values)
  local total = 0
  for _, v in ipairs(values) do
    total = total + v
  end
  return total / #values           -- / always gives a float
end

local function say(name, value)
  print(string.format("%s %.6f", name, value))
end

local xs, ys = read_columns(arg[1], "hours", "score")
local n = #xs
local mean_x, mean_y = mean(xs), mean(ys)

-- Sums of squared deviations and of cross-products. Lua has no zip, so a
-- numeric for loop uses one index i for both arrays: xs[i] and ys[i] come
-- from the same row.
local sxx, syy, sxy = 0, 0, 0
for i = 1, n do
  local dx, dy = xs[i] - mean_x, ys[i] - mean_y
  sxx = sxx + dx * dx
  syy = syy + dy * dy
  sxy = sxy + dx * dy
end

local slope = sxy / sxx
local intercept = mean_y - slope * mean_x
local r = sxy / math.sqrt(sxx * syy)

print("count " .. n)
say("slope", slope)
say("intercept", intercept)
say("r", r)
say("r_squared", r * r)
