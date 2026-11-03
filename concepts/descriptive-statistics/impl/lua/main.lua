-- Descriptive statistics on one CSV column, using only Lua's standard
-- library.
--
-- Lua has no mean, median, or variance, so each is written out. Its one data
-- structure is the table, used here as an array: indexes start at 1, and #t
-- is the length.

local function read_column(path, name)
  local f = assert(io.open(path, "r"))
  local header, col = f:read("l"), nil
  local i = 0
  for field in header:gmatch("[^,]+") do
    i = i + 1
    if field == name then col = i end
  end
  assert(col, "column not found: " .. name)
  local values = {}
  for line in f:lines() do
    local j = 0
    for field in line:gmatch("[^,]+") do
      j = j + 1
      if j == col then values[#values + 1] = tonumber(field) end
    end
  end
  f:close()
  return values
end

local function median(sorted)
  local n = #sorted
  local mid = n // 2               -- // is integer (floor) division
  if n % 2 == 1 then
    return sorted[mid + 1]
  end
  return (sorted[mid] + sorted[mid + 1]) / 2
end

local function say(name, value)
  print(string.format("%s %.6f", name, value))
end

local values = read_column(arg[1], "minutes")
table.sort(values)                 -- sorts in place, smallest first

local n = #values
local total = 0
for _, v in ipairs(values) do
  total = total + v
end
local mean = total / n             -- / always gives a float

-- Sample variance divides by n - 1, not n (Bessel's correction).
local sumsq = 0
for _, v in ipairs(values) do
  sumsq = sumsq + (v - mean) ^ 2
end
local variance = sumsq / (n - 1)

local min, max = values[1], values[n]

print("count " .. n)
say("sum", total)
say("mean", mean)
say("median", median(values))
say("min", min)
say("max", max)
say("range", max - min)
say("variance", variance)
say("std_dev", math.sqrt(variance))
