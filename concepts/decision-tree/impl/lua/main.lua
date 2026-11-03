-- A decision tree classifier (CART with Gini impurity), using only Lua's
-- standard library.
--
-- Lua has no decision tree, so the split search, the growing, and the
-- predicting are all written out. The tree is made of tables: a leaf is
-- {predict = "yes"}, and a split is
-- {feature = 1, threshold = 63.5, left = NODE, right = NODE}.

local FEATURES = { "humidity", "pressure", "wind" }
local MAX_DEPTH, MIN_SIZE = 3, 5

-- Each day is {x = {humidity, pressure, wind}, label = "yes" or "no"}.
local function read_days(path)
  local f = assert(io.open(path, "r"))
  local col = {}                   -- column name -> position
  local i = 0
  for name in f:read("l"):gmatch("[^,]+") do
    i = i + 1
    col[name] = i
  end
  local train, test = {}, {}
  for line in f:lines() do
    local row = {}
    for field in line:gmatch("[^,]+") do row[#row + 1] = field end
    local x = {}
    for k, name in ipairs(FEATURES) do x[k] = tonumber(row[col[name]]) end
    local days = row[col.split] == "train" and train or test
    days[#days + 1] = { x = x, label = row[col.rain] }
  end
  f:close()
  return train, test
end

local function count_yes(days)
  local yes = 0
  for _, d in ipairs(days) do
    if d.label == "yes" then yes = yes + 1 end
  end
  return yes
end

-- Chance that two days drawn at random (with replacement) disagree.
local function gini(days)
  local p = count_yes(days) / #days
  return 1 - p * p - (1 - p) * (1 - p)
end

-- An even split predicts "no".
local function majority(days)
  return count_yes(days) > #days / 2 and "yes" or "no"
end

-- Splits the days in two on feature f at threshold t.
local function partition(days, f, t)
  local left, right = {}, {}
  for _, d in ipairs(days) do
    local side = d.x[f] <= t and left or right
    side[#side + 1] = d
  end
  return left, right
end

-- The score, feature, and threshold with the lowest weighted Gini impurity,
-- or nil if no feature has two distinct values. Features are tried in column
-- order and thresholds from smallest to largest; only a strictly lower score
-- replaces the best so far.
local function best_split(days)
  local best, bf, bt
  for f = 1, #FEATURES do
    local seen, values = {}, {}    -- a table's keys make a set
    for _, d in ipairs(days) do
      if not seen[d.x[f]] then
        seen[d.x[f]] = true
        values[#values + 1] = d.x[f]
      end
    end
    table.sort(values)
    for i = 2, #values do
      local t = (values[i - 1] + values[i]) / 2
      local left, right = partition(days, f, t)
      local score = (#left * gini(left) + #right * gini(right)) / #days
      if best == nil or score < best then
        best, bf, bt = score, f, t
      end
    end
  end
  return best, bf, bt
end

local function grow(days, depth)
  local impurity = gini(days)
  if impurity == 0 or #days < MIN_SIZE or depth == MAX_DEPTH then
    return { predict = majority(days) }
  end
  local score, f, t = best_split(days)
  if score == nil or score >= impurity then
    return { predict = majority(days) }  -- no split makes the sides purer
  end
  local left, right = partition(days, f, t)
  return { feature = f, threshold = t,
           left = grow(left, depth + 1), right = grow(right, depth + 1) }
end

local function predict(node, x)
  while node.predict == nil do
    node = x[node.feature] <= node.threshold and node.left or node.right
  end
  return node.predict
end

local function say(name, value)
  print(string.format("%s %.6f", name, value))
end

-- Prints each node in preorder, numbering from k. Returns the next number
-- and how many leaves it printed.
local function show(node, k)
  if node.predict then
    print("node_" .. k .. "_predict " .. node.predict)
    return k + 1, 1
  end
  print("node_" .. k .. "_feature " .. FEATURES[node.feature])
  say("node_" .. k .. "_threshold", node.threshold)
  local next_k, left_leaves = show(node.left, k + 1)
  local last_k, right_leaves = show(node.right, next_k)
  return last_k, left_leaves + right_leaves
end

local function count_correct(tree, days)
  local correct = 0
  for _, d in ipairs(days) do
    if predict(tree, d.x) == d.label then correct = correct + 1 end
  end
  return correct
end

local train, test = read_days(arg[1])
local tree = grow(train, 0)

print("train_count " .. #train)
print("test_count " .. #test)
local _, leaves = show(tree, 1)
print("leaves " .. leaves)

local correct = count_correct(tree, test)
say("train_accuracy", count_correct(tree, train) / #train)
print("correct " .. correct)
say("accuracy", correct / #test)
