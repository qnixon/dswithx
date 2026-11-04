-- Exact two-sided permutation test for a difference in means, using only
-- Lua's standard library.
--
-- If compost made no difference, the "compost" and "control" labels are
-- arbitrary, and any n of the plants could have carried the compost label.
-- We try every one of those splits and count how many give a difference at
-- least as large as the one we observed. That fraction is the p-value.

-- Returns a table from group name to the list of its grams.
local function read_groups(path)
  local f = assert(io.open(path, "r"))
  local col, i = {}, 0
  for field in f:read("l"):gmatch("[^,]+") do
    i = i + 1
    col[field] = i                 -- column name -> position
  end
  local groups = {control = {}, compost = {}}
  for line in f:lines() do
    local fields = {}
    for field in line:gmatch("[^,]+") do
      fields[#fields + 1] = field
    end
    local list = groups[fields[col.group]]
    -- "459" becomes the integer 459, not the float 459.0.
    list[#list + 1] = tonumber(fields[col.grams])
  end
  f:close()
  return groups.control, groups.compost
end

local function sum(values)
  local total = 0
  for _, v in ipairs(values) do total = total + v end
  return total
end

local control, compost = read_groups(arg[1])
local n = #compost
local plants = {}
for _, g in ipairs(control) do plants[#plants + 1] = g end
for _, g in ipairs(compost) do plants[#plants + 1] = g end
local total = sum(plants)

-- Both groups have n plants, so comparing totals is the same as comparing
-- means, and totals stay whole numbers: no floating-point near-ties.
local observed = sum(compost) - sum(control)

local splits, as_extreme = 0, 0

-- Walk the plants from position next on, choosing left more of them to
-- carry the compost label; chosen is the total of those picked so far. Each
-- call either takes plant next or skips it, so every choice is reached once.
-- "local function" lets choose call itself and update the counters above.
local function choose(next, left, chosen)
  if left == 0 then
    splits = splits + 1
    -- Two-sided: math.abs counts a difference in either direction.
    if math.abs(chosen - (total - chosen)) >= math.abs(observed) then
      as_extreme = as_extreme + 1
    end
    return
  end
  if #plants - next + 1 < left then return end   -- too few plants left
  choose(next + 1, left - 1, chosen + plants[next])
  choose(next + 1, left, chosen)
end

choose(1, n, 0)                    -- Lua arrays start at 1

-- / always divides as a decimal, even between two integers.
print("control_count " .. #control)
print("compost_count " .. n)
print(string.format("control_mean %.6f", sum(control) / #control))
print(string.format("compost_mean %.6f", sum(compost) / n))
print(string.format("observed_difference %.6f", observed / n))
print("splits " .. splits)
print("as_extreme " .. as_extreme)
print(string.format("p_value %.6f", as_extreme / splits))
