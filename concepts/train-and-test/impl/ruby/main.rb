# Train and test error for polynomials of degree 1 to 8, using only the
# standard library.
#
# Each polynomial is fitted by least squares to the training drives only:
# we build the normal equations and solve them by Gaussian elimination. Then
# we measure its root-mean-square error on the training drives and on the
# test drives it never saw.

MAX_DEGREE = 8

# The csv library is a bundled gem since Ruby 3.4, so split lines by hand
# (no quoted fields here). Each drive becomes [speed, litres].
def read(path)
  header, *lines = File.readlines(path, chomp: true)
  columns = header.split(",")
  i_speed = columns.index("speed")
  i_litres = columns.index("litres")
  i_split = columns.index("split")
  train = []
  test = []
  lines.each do |line|
    fields = line.split(",")
    point = [Float(fields[i_speed]), Float(fields[i_litres])]
    (fields[i_split] == "train" ? train : test) << point
  end
  [train, test]
end

# Solve a x = b by Gaussian elimination with partial pivoting.
def solve(a, b)
  n = b.length
  m = a.each_with_index.map { |row, i| row + [b[i]] } # augmented matrix, copied
  (0...n).each do |col|
    # Swap up the row with the largest entry in this column, which keeps
    # the rounding error small.
    pivot = (col...n).max_by { |r| m[r][col].abs }
    m[col], m[pivot] = m[pivot], m[col]
    (col + 1...n).each do |r|
      factor = m[r][col] / m[col][col]
      (col..n).each { |c| m[r][c] -= factor * m[col][c] }
    end
  end
  # Back substitution, from the last unknown up.
  x = Array.new(n, 0.0)
  (n - 1).downto(0) do |r|
    rest = (r + 1...n).sum { |c| m[r][c] * x[c] }
    x[r] = (m[r][n] - rest) / m[r][r]
  end
  x
end

# Least squares: the coefficients c solve (Z^T Z) c = Z^T y, where row i
# of Z is 1, z_i, z_i^2, ..., z_i^degree.
def fit(points, degree, scale)
  size = degree + 1
  a = Array.new(size) { Array.new(size, 0.0) }
  b = Array.new(size, 0.0)
  points.each do |x, y|
    z = scale.call(x)
    size.times do |i|
      b[i] += y * z**i
      size.times { |j| a[i][j] += z**(i + j) }
    end
  end
  solve(a, b)
end

def rmse(coefs, points, scale)
  total = points.sum do |x, y|
    z = scale.call(x)
    predicted = coefs.each_with_index.sum { |c, i| c * z**i }
    (predicted - y)**2
  end
  Math.sqrt(total / points.length)
end

train, test = read(ARGV[0])

# Map the training speeds onto -1 to 1. Raw speeds to the 16th power (the
# largest entry at degree 8) would swamp the small ones and make the
# equations hard to solve accurately.
low, high = train.map(&:first).minmax
mid = (low + high) / 2
half = (high - low) / 2
scale = ->(x) { (x - mid) / half }

puts "train_count #{train.length}"
puts "test_count #{test.length}"
errors = (1..MAX_DEGREE).map do |degree|
  coefs = fit(train, degree, scale)
  [degree, rmse(coefs, train, scale), rmse(coefs, test, scale)]
end
errors.each { |degree, train_error, _| puts format("train_rmse_d%d %.6f", degree, train_error) }
errors.each { |degree, _, test_error| puts format("test_rmse_d%d %.6f", degree, test_error) }
