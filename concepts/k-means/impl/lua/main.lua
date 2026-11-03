-- k-means clustering (Lloyd's algorithm), using only Lua's standard library.
--
-- Lua has no clustering, so both steps are written out. Starting from the
-- first K points as centroids, we assign each point to its nearest centroid,
-- move each centroid to the mean of its points, and stop when no point
-- changes cluster.

local K = 3
local MAX_ITERATIONS = 100

-- Each point is a small table with named fields: {x = 1.25, y = 1.66}.
local function read_points(path)
  local f = assert(io.open(path, "r"))
  local header, xcol, ycol = f:read("l"), nil, nil
  local i = 0
  for field in header:gmatch("[^,]+") do
    i = i + 1
    if field == "x" then xcol = i elseif field == "y" then ycol = i end
  end
  local points = {}
  for line in f:lines() do
    local fields = {}
    for field in line:gmatch("[^,]+") do fields[#fields + 1] = field end
    points[#points + 1] = { x = tonumber(fields[xcol]), y = tonumber(fields[ycol]) }
  end
  f:close()
  return points
end

local function distance(p, q)
  return math.sqrt((p.x - q.x) ^ 2 + (p.y - q.y) ^ 2)
end

-- Returns the index of the nearest centroid. The test is strictly less
-- than, so a tie keeps the lower index.
local function nearest(point, centroids)
  local best, best_dist = 1, distance(point, centroids[1])
  for j = 2, #centroids do
    local d = distance(point, centroids[j])
    if d < best_dist then best, best_dist = j, d end
  end
  return best
end

-- == on two tables asks whether they are the same table, not whether they
-- hold the same values, so we compare the assignments element by element.
local function same(a, b)
  if #a ~= #b then return false end
  for i = 1, #a do
    if a[i] ~= b[i] then return false end
  end
  return true
end

local points = read_points(arg[1])
local centroids = {}
for j = 1, K do
  centroids[j] = { x = points[j].x, y = points[j].y }
end
local assignment = {}
local iterations = 0

while iterations < MAX_ITERATIONS do
  iterations = iterations + 1
  local new_assignment = {}
  for i, p in ipairs(points) do
    new_assignment[i] = nearest(p, centroids)
  end
  if same(new_assignment, assignment) then break end
  assignment = new_assignment

  for j = 1, K do
    local sx, sy, n = 0, 0, 0
    for i, p in ipairs(points) do
      if assignment[i] == j then
        sx, sy, n = sx + p.x, sy + p.y, n + 1
      end
    end
    if n > 0 then                  -- an empty cluster keeps its old centroid
      centroids[j] = { x = sx / n, y = sy / n }
    end
  end
end

local sizes, inertia = {}, 0
for j = 1, K do sizes[j] = 0 end
for i, p in ipairs(points) do
  local a = assignment[i]
  sizes[a] = sizes[a] + 1
  inertia = inertia + distance(p, centroids[a]) ^ 2
end

print("iterations " .. iterations)
for j, c in ipairs(centroids) do
  print(string.format("centroid_%d_x %.6f", j, c.x))
  print(string.format("centroid_%d_y %.6f", j, c.y))
end
for j = 1, K do
  print(string.format("size_%d %d", j, sizes[j]))
end
print(string.format("inertia %.6f", inertia))
