-- Categorical naive Bayes with add-one (Laplace) smoothing, using only Lua's
-- standard library.
--
-- Lua has no classifier and no counting helper, so we count training rows
-- into tables, then label each test row with the label that has the highest
-- log-probability.

local FEATURES = { "has_link", "mentions_money", "known_sender" }

-- Returns the rows as a list of tables, keyed by column name.
local function read_rows(path)
  local f = assert(io.open(path, "r"))
  local header = {}
  for name in f:read("l"):gmatch("[^,]+") do header[#header + 1] = name end
  local rows = {}
  for line in f:lines() do
    local row, i = {}, 0
    for value in line:gmatch("[^,]+") do
      i = i + 1
      row[header[i]] = value
    end
    rows[#rows + 1] = row
  end
  f:close()
  return rows
end

local train, test = {}, {}
for _, row in ipairs(read_rows(arg[1])) do
  if row.split == "train" then
    train[#train + 1] = row
  else
    test[#test + 1] = row
  end
end

-- A table key matches by identity, so two tables {f, v, label} with the
-- same contents would be two different keys. We join the three into one
-- string instead, which matches by value.
local function key(f, v, label)
  return f .. "|" .. v .. "|" .. label
end

-- label_counts: label -> rows. value_counts: "feature|value|label" -> rows.
-- values_seen: feature -> set of the distinct values it takes.
local label_counts, value_counts, values_seen = {}, {}, {}
for _, f in ipairs(FEATURES) do values_seen[f] = {} end
for _, row in ipairs(train) do
  local label = row.label
  -- A missing key reads as nil, so "or 0" starts each count at zero.
  label_counts[label] = (label_counts[label] or 0) + 1
  for _, f in ipairs(FEATURES) do
    local k = key(f, row[f], label)
    value_counts[k] = (value_counts[k] or 0) + 1
    values_seen[f][row[f]] = true
  end
end

-- # counts only the 1, 2, 3, ... part of a table, so a set is counted by
-- walking it with pairs.
local distinct = {}
for _, f in ipairs(FEATURES) do
  local n = 0
  for _ in pairs(values_seen[f]) do n = n + 1 end
  distinct[f] = n
end

local function log_score(row, label)
  local n_label = label_counts[label]
  -- Logs turn the product of probabilities into a sum, avoiding underflow.
  local score = math.log(n_label / #train)
  for _, f in ipairs(FEATURES) do
    -- Add-one smoothing: an unseen value never gets probability zero.
    local count = (value_counts[key(f, row[f], label)] or 0) + 1
    score = score + math.log(count / (n_label + distinct[f]))
  end
  return score
end

-- pairs visits keys in no fixed order, so we sort the labels first.
local labels = {}
for label in pairs(label_counts) do labels[#labels + 1] = label end
table.sort(labels)

-- Labels are tried in alphabetical order, and only a strictly higher score
-- replaces the best, so an exact tie goes to the first.
local function classify(row)
  local best, best_score = nil, nil
  for _, label in ipairs(labels) do
    local score = log_score(row, label)
    if best == nil or score > best_score then
      best, best_score = label, score
    end
  end
  return best
end

local correct = 0
for _, row in ipairs(test) do
  if classify(row) == row.label then correct = correct + 1 end
end

print("train_count " .. #train)
print("test_count " .. #test)
print("correct " .. correct)
print(string.format("accuracy %.6f", correct / #test))
