-- Logistic regression by gradient descent, using only Lua's standard
-- library.
--
-- Predicts whether a student passed from study hours and sleep. Lua has no
-- regression, classifier, or matrix type, so every step is written out. Each
-- feature is rescaled with the training rows' mean and standard deviation,
-- then the weights start at zero and take 1000 fixed steps of batch gradient
-- descent on the average log-loss. Tables serve as arrays, indexed from 1.

local FEATURES = { "hours", "sleep" }
local LEARNING_RATE = 0.5
local STEPS = 1000

-- Returns two arrays, train and test. Each example is a table with the
-- feature values in x and the 0/1 label in y.
local function read_examples(path)
  local f = assert(io.open(path, "r"))
  local header = {}
  for field in f:read("l"):gmatch("[^,]+") do
    header[#header + 1] = field
  end
  local train, test = {}, {}
  for line in f:lines() do
    local row, i = {}, 0
    for field in line:gmatch("[^,]+") do
      i = i + 1
      row[header[i]] = field         -- a table keyed by column name
    end
    local x = {}
    for j, name in ipairs(FEATURES) do
      x[j] = tonumber(row[name])
    end
    local example = { x = x, y = tonumber(row.passed) }
    local split = row.split == "train" and train or test
    split[#split + 1] = example
  end
  f:close()
  return train, test
end

local function sigmoid(z)
  return 1 / (1 + math.exp(-z))
end

local function dot(u, v)
  local total = 0
  for i = 1, #u do
    total = total + u[i] * v[i]
  end
  return total
end

local function say(name, value)
  print(string.format("%s %.6f", name, value))
end

local train, test = read_examples(arg[1])
local n = #train

-- Scale each feature to mean 0 and (sample) standard deviation 1, using the
-- training rows only.
local means, sds = {}, {}
for j = 1, #FEATURES do
  local total = 0
  for _, e in ipairs(train) do total = total + e.x[j] end
  local mean = total / n
  local sumsq = 0
  for _, e in ipairs(train) do sumsq = sumsq + (e.x[j] - mean) ^ 2 end
  means[j], sds[j] = mean, math.sqrt(sumsq / (n - 1))
end

-- The leading 1 multiplies the intercept.
local function scale(x)
  local scaled = { 1.0 }
  for j, v in ipairs(x) do
    scaled[j + 1] = (v - means[j]) / sds[j]
  end
  return scaled
end

local xs = {}
for i, e in ipairs(train) do xs[i] = scale(e.x) end

local weights = { 0.0, 0.0, 0.0 }
for _ = 1, STEPS do
  -- Gradient of the average log-loss: the mean of (p - y) times each input.
  local gradient = { 0.0, 0.0, 0.0 }
  for i, x in ipairs(xs) do
    local err = sigmoid(dot(weights, x)) - train[i].y
    for j = 1, #gradient do
      gradient[j] = gradient[j] + err * x[j]
    end
  end
  -- Only now, with the whole gradient summed, does any weight move.
  for j = 1, #weights do
    weights[j] = weights[j] - LEARNING_RATE * gradient[j] / n
  end
end

local loss = 0
for i, x in ipairs(xs) do
  local p, y = sigmoid(dot(weights, x)), train[i].y
  loss = loss - (y * math.log(p) + (1 - y) * math.log(1 - p))
end

local correct = 0
for _, e in ipairs(test) do
  local predicted = sigmoid(dot(weights, scale(e.x))) >= 0.5 and 1 or 0
  if predicted == e.y then correct = correct + 1 end
end

print("train_count " .. n)
print("test_count " .. #test)
say("intercept", weights[1])
say("weight_hours", weights[2])
say("weight_sleep", weights[3])
say("log_loss", loss / n)
print("correct " .. correct)
say("accuracy", correct / #test)   -- / always gives a float
