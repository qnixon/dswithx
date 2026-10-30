# Categorical naive Bayes with add-one (Laplace) smoothing, standard library only.
# Learns P(label) and P(feature value | label) by counting training rows, then
# labels each test row with the label that has the highest log-probability.

FEATURES = %w[has_link mentions_money known_sender].freeze
LABEL = "label"

# The csv library is a bundled gem since Ruby 3.4, so split lines by hand
# (no quoted fields here) and turn each row into a hash keyed by header name.
def read_rows(path)
  header, *lines = File.readlines(path, chomp: true)
  names = header.split(",")
  lines.map { |line| names.zip(line.split(",")).to_h }
end

rows = read_rows(ARGV[0])
train = rows.select { |row| row["split"] == "train" }
test = rows.select { |row| row["split"] == "test" }

label_counts = train.map { |row| row[LABEL] }.tally
# value_counts[[feature, value, label]] = number of training rows.
# Hash.new(0) makes missing keys count as zero.
value_counts = Hash.new(0)
train.each { |row| FEATURES.each { |f| value_counts[[f, row[f], row[LABEL]]] += 1 } }
distinct_values = FEATURES.to_h { |f| [f, train.map { |row| row[f] }.uniq.length] }

log_score = lambda do |row, label|
  # Logs turn the product of probabilities into a sum, avoiding underflow.
  score = Math.log(label_counts[label].fdiv(train.length))
  FEATURES.each do |f|
    # Add-one smoothing: an unseen value never gets probability zero.
    count = value_counts[[f, row[f], label]] + 1
    score += Math.log(count.fdiv(label_counts[label] + distinct_values[f]))
  end
  score
end

# Labels are tried in alphabetical order and max_by keeps the first maximum,
# so an exact tie goes to the alphabetically first label.
classify = ->(row) { label_counts.keys.sort.max_by { |label| log_score.(row, label) } }

correct = test.count { |row| classify.(row) == row[LABEL] }

puts "train_count #{train.length}"
puts "test_count #{test.length}"
puts "correct #{correct}"
puts format("accuracy %.6f", correct.fdiv(test.length))
