-- Evaluation metrics for a binary classifier, using only Lua's standard
-- library.
--
-- Reads each part's true label and the model's score, then reports the
-- confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
-- the accuracy of never flagging anything, and the area under the ROC curve.

-- Returns a list of parts, each a table {defective = bool, score = number}.
local function read_parts(path)
  local f = assert(io.open(path, "r"))
  local col, i = {}, 0
  for field in f:read("l"):gmatch("[^,]+") do
    i = i + 1
    col[field] = i                 -- column name -> position
  end
  local parts = {}
  for line in f:lines() do
    local fields = {}
    for field in line:gmatch("[^,]+") do
      fields[#fields + 1] = field
    end
    parts[#parts + 1] = {
      defective = fields[col.defective] == "1",
      score = tonumber(fields[col.score]),
    }
  end
  f:close()
  return parts
end

local function report(parts, suffix, threshold)
  -- A part is flagged when its score reaches the threshold.
  local tp, fp, fn, tn = 0, 0, 0, 0
  for _, p in ipairs(parts) do
    local flagged = p.score >= threshold
    if flagged and p.defective then tp = tp + 1
    elseif flagged then fp = fp + 1
    elseif p.defective then fn = fn + 1
    else tn = tn + 1 end
  end

  -- / always divides as a decimal, even between two integers.
  local accuracy = (tp + tn) / #parts
  local precision = tp / (tp + fp)  -- of the flagged parts, how many are defective
  local recall = tp / (tp + fn)     -- of the defective parts, how many are flagged
  local f1 = 2 * precision * recall / (precision + recall)

  print("tp_at_" .. suffix .. " " .. tp)
  print("fp_at_" .. suffix .. " " .. fp)
  print("fn_at_" .. suffix .. " " .. fn)
  print("tn_at_" .. suffix .. " " .. tn)
  print(string.format("accuracy_at_%s %.6f", suffix, accuracy))
  print(string.format("precision_at_%s %.6f", suffix, precision))
  print(string.format("recall_at_%s %.6f", suffix, recall))
  print(string.format("f1_at_%s %.6f", suffix, f1))
end

-- The chance that a random defective part outscores a random good one.
-- Compare every pair, scoring 2 for a win and 1 for a tie, so the count
-- stays a whole number until the final division.
local function auc(parts)
  local defective, good = {}, {}
  for _, p in ipairs(parts) do
    local list = p.defective and defective or good
    list[#list + 1] = p.score
  end
  local points = 0
  for _, d in ipairs(defective) do
    for _, g in ipairs(good) do
      if d > g then points = points + 2
      elseif d == g then points = points + 1 end
    end
  end
  return points / (2 * #defective * #good)
end

local parts = read_parts(arg[1])
local defective = 0
for _, p in ipairs(parts) do
  if p.defective then defective = defective + 1 end
end

print("parts " .. #parts)
print("defective " .. defective)
-- Never flagging anything is right about every good part.
print(string.format("baseline_accuracy %.6f", (#parts - defective) / #parts))
report(parts, "50", 0.5)
report(parts, "30", 0.3)
print(string.format("auc %.6f", auc(parts)))
