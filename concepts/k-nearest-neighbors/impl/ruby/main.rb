# k-nearest neighbors classification, using only the standard library.
# Each test seed gets the majority variety among its K nearest training seeds,
# by Euclidean distance.

K = 5
FEATURES = %w[length_mm width_mm].freeze
LABEL = "variety"

# The csv library is a bundled gem since Ruby 3.4, so split lines by hand
# (no quoted fields here) and turn each row into a hash keyed by header name.
def read_rows(path)
  header, *lines = File.readlines(path, chomp: true)
  names = header.split(",")
  lines.map { |line| names.zip(line.split(",")).to_h }
end

def distance(a, b)
  Math.sqrt(a.zip(b).sum { |x, y| (x - y)**2 })
end

def classify(point, train)
  # sort_by is not stable in Ruby, so add the file position as a tie-breaker:
  # equal distances keep file order.
  nearest = train.each_with_index
                 .sort_by { |(features, _), i| [distance(point, features), i] }
                 .first(K)
  # tally keeps first-seen order and max_by keeps the first maximum, so a tied
  # vote goes to the label that appears first among the nearest.
  nearest.map { |(_, label), _| label }.tally.max_by { |_, votes| votes }.first
end

rows = read_rows(ARGV[0])
points = rows.map { |row| [FEATURES.map { |f| Float(row[f]) }, row[LABEL], row["split"]] }
train, test = points.partition { |_, _, split| split == "train" }

correct = test.count { |features, label, _| classify(features, train) == label }

puts "train_count #{train.length}"
puts "test_count #{test.length}"
puts "correct #{correct}"
puts format("accuracy %.6f", correct.fdiv(test.length))
