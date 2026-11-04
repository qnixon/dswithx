-- 5-fold cross-validation for k-nearest neighbors, using only Lua's standard
-- library.
--
-- Scores each odd k from 1 to 15 by holding out one fold of the training
-- seeds at a time, picks the best k, and then scores that k once on the
-- untouched test seeds.

local FOLDS = 5

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

local function classify(point, train, k)
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
  -- "or 0" starts each count. With two varieties and odd k, no vote ties.
  local votes, best = {}, nil
  for i = 1, k do
    local label = scored[i].label
    votes[label] = (votes[label] or 0) + 1
    if best == nil or votes[label] > votes[best] then best = label end
  end
  return best
end

local function count_correct(points, train, k)
  local correct = 0
  for _, seed in ipairs(points) do
    if classify(seed, train, k) == seed.label then correct = correct + 1 end
  end
  return correct
end

local function cv_accuracy(train, k)
  -- Fold f (1 to FOLDS) is rows first to last. The rows are already
  -- shuffled, so consecutive blocks make fair folds. Lua has no slicing,
  -- so one pass over the row numbers sends each seed to one side, in order.
  local size = #train // FOLDS
  local correct = 0
  for f = 1, FOLDS do
    local first, last = (f - 1) * size + 1, f * size
    local held_out, rest = {}, {}
    for row, seed in ipairs(train) do
      local list = (row >= first and row <= last) and held_out or rest
      list[#list + 1] = seed
    end
    correct = correct + count_correct(held_out, rest, k)
  end
  return correct / #train
end

local train, test = read_seeds(arg[1])

print("train_count " .. #train)
print("test_count " .. #test)
local best_k, best_accuracy = nil, -1
for k = 1, 15, 2 do              -- odd k only, so two varieties can't tie
  local accuracy = cv_accuracy(train, k)
  print(string.format("cv_accuracy_k%d %.6f", k, accuracy))
  -- Strictly better, so ties keep the smaller k.
  if accuracy > best_accuracy then best_k, best_accuracy = k, accuracy end
end

-- Only now touch the test seeds, once, with the chosen k and all of train.
local correct = count_correct(test, train, best_k)
print("best_k " .. best_k)
print("test_correct " .. correct)
print(string.format("test_accuracy %.6f", correct / #test))
