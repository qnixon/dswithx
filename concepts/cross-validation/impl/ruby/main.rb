# 5-fold cross-validation for k-nearest neighbors, using only the standard
# library. Scores each odd k from 1 to 15 by holding out one fold of the
# training seeds at a time, picks the best k, and then scores that k once on
# the untouched test seeds.

FOLDS = 5
KS = (1..15).step(2).to_a # odd k only, so two varieties can't tie
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

def classify(point, train, k)
  # sort_by is not stable in Ruby, so add the file position as a tie-breaker:
  # equal distances keep file order.
  nearest = train.each_with_index
                 .sort_by { |(features, _), i| [distance(point, features), i] }
                 .first(k)
  nearest.map { |(_, label), _| label }.tally.max_by { |_, votes| votes }.first
end

def count_correct(points, train, k)
  points.count { |features, label| classify(features, train, k) == label }
end

def cv_accuracy(train, k)
  # Fold f is the block of size rows starting at f * size. The rows are
  # already shuffled, so consecutive blocks make fair folds. arr[start, n]
  # takes n rows from start, and arr[start..] runs to the end.
  size = train.length / FOLDS
  correct = (0...FOLDS).sum do |f|
    held_out = train[f * size, size]
    rest = train[0, f * size] + train[(f + 1) * size..]
    count_correct(held_out, rest, k)
  end
  correct.fdiv(train.length)
end

rows = read_rows(ARGV[0])
points = rows.map { |row| [FEATURES.map { |f| Float(row[f]) }, row[LABEL], row["split"]] }
train, test = points.partition { |_, _, split| split == "train" }

puts "train_count #{train.length}"
puts "test_count #{test.length}"
best_k, best_accuracy = nil, -1.0
KS.each do |k|
  accuracy = cv_accuracy(train, k)
  puts format("cv_accuracy_k%d %.6f", k, accuracy)
  # Strictly better, so ties keep the smaller k.
  best_k, best_accuracy = k, accuracy if accuracy > best_accuracy
end

# Only now touch the test seeds, once, with the chosen k and all of train.
correct = count_correct(test, train, best_k)
puts "best_k #{best_k}"
puts "test_correct #{correct}"
puts format("test_accuracy %.6f", correct.fdiv(test.length))
