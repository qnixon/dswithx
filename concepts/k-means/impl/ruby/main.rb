# k-means clustering (Lloyd's algorithm), using only the standard library.
# Starts from the first K points as centroids, then alternates two steps until
# no point changes cluster: assign each point to its nearest centroid, and move
# each centroid to the mean of its points.

K = 3
MAX_ITERATIONS = 100

# The csv library is a bundled gem since Ruby 3.4, so split lines by hand.
# Fine for this data: no quoted fields or embedded commas.
def read_points(path)
  header, *rows = File.readlines(path, chomp: true).map { |line| line.split(",") }
  ix = header.index("x") or abort "no column x"
  iy = header.index("y") or abort "no column y"
  rows.map { |row| [Float(row[ix]), Float(row[iy])] }
end

def squared_distance(a, b)
  a.zip(b).sum { |p, q| (p - q)**2 }
end

# min_by returns the first of equal values, so ties go to the lower index.
def nearest(point, centroids)
  (0...centroids.length).min_by { |j| squared_distance(point, centroids[j]) }
end

points = read_points(ARGV[0])
centroids = points.first(K)
assignment = nil
iterations = 0

while iterations < MAX_ITERATIONS
  iterations += 1
  new_assignment = points.map { |p| nearest(p, centroids) }
  break if new_assignment == assignment # this unchanged pass still counts

  assignment = new_assignment
  K.times do |j|
    members = points.select.with_index { |_, i| assignment[i] == j }
    next if members.empty? # an empty cluster keeps its old centroid

    centroids[j] = members.transpose.map { |coords| coords.sum / members.length }
  end
end

sizes = (0...K).map { |j| assignment.count(j) }
inertia = points.zip(assignment).sum { |p, a| squared_distance(p, centroids[a]) }

puts "iterations #{iterations}"
centroids.each.with_index(1) do |(x, y), j|
  puts format("centroid_%d_x %.6f", j, x)
  puts format("centroid_%d_y %.6f", j, y)
end
sizes.each.with_index(1) { |size, j| puts "size_#{j} #{size}" }
puts format("inertia %.6f", inertia)
