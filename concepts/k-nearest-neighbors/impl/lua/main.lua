-- k-nearest neighbors classification, using only Lua's standard library.
--
-- Each test seed is labelled with the majority variety among its K nearest
-- training seeds, by Euclidean distance. Lua has no kNN or distance
-- function, so both are written out.

local K = 5

-- Each seed becomes a table with named fields, like a small record:
-- {len = 5.5, wid = 3.11, label = "kama"}.
local function read_seeds(path)
  local f = assert(io.open(path, "r"))
  local col, i = {}, 0
  for field in f:read("l"):gmatch("[^,]+") do
    i = i + 1
    col[field] = i                 -- column name -> position
  end
  local train, test = {}, {}
  for line in f:lines() do
    local fields = {}
    for field in line:gmatch("[^,]+") do
      fields[#fields + 1] = field
    end
    local seed = {
      len = tonumber(fields[col.length_mm]),
      wid = tonumber(fields[col.width_mm]),
      label = fields[col.variety],
    }
    local list = fields[col.split] == "train" and train or test
    list[#list + 1] = seed
  end
  f:close()
  return train, test
end

local function classify(point, train)
  -- Pair each training seed's distance with its row number.
  local scored = {}
  for row, seed in ipairs(train) do
    local d = math.sqrt((point.len - seed.len) ^ 2 + (point.wid - seed.wid) ^ 2)
    scored[row] = {d = d, row = row, label = seed.label}
  end
  -- table.sort isn't stable, so equal distances could come out in any
  -- order. Breaking ties by row number keeps the earlier training seed.
  table.sort(scored, function(a, b)
    if a.d ~= b.d then return a.d < b.d end
    return a.row < b.row
  end)

  -- Count votes in a table keyed by label; a missing key reads as nil, so
  -- "or 0" starts each count. With two varieties and odd K, no vote ties.
  local votes, best = {}, nil
  for i = 1, K do
    local label = scored[i].label
    votes[label] = (votes[label] or 0) + 1
    if best == nil or votes[label] > votes[best] then best = label end
  end
  return best
end

local train, test = read_seeds(arg[1])

local correct = 0
for _, seed in ipairs(test) do
  if classify(seed, train) == seed.label then
    correct = correct + 1
  end
end

print("train_count " .. #train)
print("test_count " .. #test)
print("correct " .. correct)
print(string.format("accuracy %.6f", correct / #test))
