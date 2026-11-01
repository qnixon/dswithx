# Principal component analysis by power iteration, using only the standard library.
# Standardizes the four scores, builds their correlation matrix, and finds the
# top two eigenvectors (the principal components): power iteration finds the
# first, then deflation removes it from the matrix so the same steps find the
# second.

SUBJECTS = %w[math physics reading writing].freeze
STEPS = 1000

# The csv library is a bundled gem since Ruby 3.4, so split lines by hand
# (no quoted fields here) and keep the four score columns of each row.
def read_rows(path)
  header, *lines = File.readlines(path, chomp: true).map { |line| line.split(",") }
  indexes = SUBJECTS.map { |s| header.index(s) or abort "no column #{s}" }
  lines.map { |fields| fields.values_at(*indexes).map { |f| Float(f) } }
end

def dot(u, v)
  u.zip(v).sum { |a, b| a * b }
end

def mat_vec(m, v)
  m.map { |row| dot(row, v) }
end

def normalize(v)
  length = Math.sqrt(dot(v, v))
  v.map { |x| x / length }
end

# Power iteration: multiply by the matrix and rescale, STEPS times.
# Returns the eigenvalue and the eigenvector.
def top_eigenvector(m)
  v = [1.0] + [0.0] * (m.length - 1)
  STEPS.times { v = normalize(mat_vec(m, v)) }
  # An eigenvector can point either way; make its first entry positive.
  v = v.map { |x| -x } if v[0].negative?
  [dot(v, mat_vec(m, v)), v]
end

rows = read_rows(ARGV[0])
n, k = rows.length, SUBJECTS.length

# Standardize each column to mean 0 and (sample) standard deviation 1.
# transpose turns the rows into one array per subject.
columns = rows.transpose
means = columns.map { |c| c.sum / n }
sds = columns.zip(means).map { |c, m| Math.sqrt(c.sum { |x| (x - m)**2 } / (n - 1)) }
z = rows.map { |row| row.zip(means, sds).map { |x, m, s| (x - m) / s } }

# The correlation matrix: the covariance of the standardized columns.
corr = Array.new(k) { |i| Array.new(k) { |j| z.sum { |r| r[i] * r[j] } / (n - 1) } }

value_1, pc_1 = top_eigenvector(corr)
# Deflation: subtract the first component's share, leaving the rest.
deflated = Array.new(k) { |i| Array.new(k) { |j| corr[i][j] - value_1 * pc_1[i] * pc_1[j] } }
value_2, pc_2 = top_eigenvector(deflated)

puts "count #{n}"
[[value_1, pc_1], [value_2, pc_2]].each.with_index(1) do |(value, pc), c|
  puts format("eigenvalue_%d %.6f", c, value)
  # Standardized columns each have variance 1, so the total is k.
  puts format("explained_%d %.6f", c, value / k)
  SUBJECTS.zip(pc).each { |subject, loading| puts format("pc%d_%s %.6f", c, subject, loading) }
end
puts format("student_1_pc1 %.6f", dot(z[0], pc_1))
puts format("student_1_pc2 %.6f", dot(z[0], pc_2))
