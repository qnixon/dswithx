-- Principal component analysis by power iteration, using only Lua's
-- standard library.
--
-- Standardizes the four scores, builds their correlation matrix, and finds
-- the top two eigenvectors (the principal components): power iteration finds
-- the first, then deflation removes it from the matrix so the same steps find
-- the second. Lua has no matrix type or eigen solver, so a vector is a table
-- used as an array (indexed from 1) and a matrix is a table of row tables.

local SUBJECTS = { "math", "physics", "reading", "writing" }
local STEPS = 1000

-- Returns one array of numbers per row, in the order of the subjects.
local function read_rows(path)
  local f = assert(io.open(path, "r"))
  local col = {}                     -- column number for each name
  local i = 0
  for field in f:read("l"):gmatch("[^,]+") do
    i = i + 1
    col[field] = i
  end
  local rows = {}
  for line in f:lines() do
    local fields = {}
    for field in line:gmatch("[^,]+") do
      fields[#fields + 1] = tonumber(field)
    end
    local row = {}
    for j, name in ipairs(SUBJECTS) do
      row[j] = fields[assert(col[name], "column not found: " .. name)]
    end
    rows[#rows + 1] = row
  end
  f:close()
  return rows
end

local function dot(u, v)
  local total = 0
  for i = 1, #u do
    total = total + u[i] * v[i]
  end
  return total
end

local function mat_vec(m, v)
  local result = {}
  for i, row in ipairs(m) do
    result[i] = dot(row, v)
  end
  return result
end

local function normalize(v)
  local length = math.sqrt(dot(v, v))
  local result = {}
  for i, x in ipairs(v) do
    result[i] = x / length
  end
  return result
end

-- Power iteration: multiply by the matrix and rescale, STEPS times.
-- Returns two values, the eigenvalue and the eigenvector.
local function top_eigenvector(m)
  local v = {}
  for i = 1, #m do v[i] = 0.0 end
  v[1] = 1.0
  for _ = 1, STEPS do
    v = normalize(mat_vec(m, v))
  end
  -- An eigenvector can point either way; make its first entry positive.
  if v[1] < 0 then
    for i = 1, #v do v[i] = -v[i] end
  end
  return dot(v, mat_vec(m, v)), v
end

local function say(name, value)
  print(string.format("%s %.6f", name, value))
end

local rows = read_rows(arg[1])
local n, k = #rows, #SUBJECTS

-- Standardize each column to mean 0 and (sample) standard deviation 1.
local means, sds = {}, {}
for j = 1, k do
  local total = 0
  for _, row in ipairs(rows) do total = total + row[j] end
  local mean = total / n
  local sumsq = 0
  for _, row in ipairs(rows) do sumsq = sumsq + (row[j] - mean) ^ 2 end
  means[j], sds[j] = mean, math.sqrt(sumsq / (n - 1))
end
local z = {}
for i, row in ipairs(rows) do
  z[i] = {}
  for j = 1, k do
    z[i][j] = (row[j] - means[j]) / sds[j]
  end
end

-- The correlation matrix: the covariance of the standardized columns.
local corr = {}
for i = 1, k do
  corr[i] = {}
  for j = 1, k do
    local total = 0
    for _, r in ipairs(z) do total = total + r[i] * r[j] end
    corr[i][j] = total / (n - 1)
  end
end

local value_1, pc_1 = top_eigenvector(corr)

-- Deflation: subtract the first component's share, leaving the rest.
local deflated = {}
for i = 1, k do
  deflated[i] = {}
  for j = 1, k do
    deflated[i][j] = corr[i][j] - value_1 * pc_1[i] * pc_1[j]
  end
end
local value_2, pc_2 = top_eigenvector(deflated)

print("count " .. n)
for c, result in ipairs({ { value_1, pc_1 }, { value_2, pc_2 } }) do
  local value, pc = result[1], result[2]
  say("eigenvalue_" .. c, value)
  -- Standardized columns each have variance 1, so the total is k.
  say("explained_" .. c, value / k)
  for j, subject in ipairs(SUBJECTS) do
    say("pc" .. c .. "_" .. subject, pc[j])
  end
end
say("student_1_pc1", dot(z[1], pc_1))
say("student_1_pc2", dot(z[1], pc_2))
