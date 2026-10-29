# Descriptive statistics on one CSV column, using only the standard library.

COLUMN = "minutes"

# The csv library is a bundled gem since Ruby 3.4, not standard library, so
# split lines by hand. Fine for this data: no quoted fields or embedded commas.
def read_column(path, column)
  header, *rows = File.readlines(path, chomp: true)
  index = header.split(",").index(column) or abort "no column #{column}"
  rows.map { |row| Float(row.split(",")[index]) }
end

def median(sorted)
  middle = sorted.length / 2
  return sorted[middle] if sorted.length.odd?

  (sorted[middle - 1] + sorted[middle]) / 2
end

values = read_column(ARGV[0], COLUMN).sort

n = values.length
total = values.sum
mean = total / n
# Sample variance divides by n - 1, not n (Bessel's correction).
variance = values.sum { |x| (x - mean)**2 } / (n - 1)

results = {
  sum: total,
  mean: mean,
  median: median(values),
  min: values.first,
  max: values.last,
  range: values.last - values.first,
  variance: variance,
  std_dev: Math.sqrt(variance),
}

puts "count #{n}"
results.each { |name, value| puts format("%s %.6f", name, value) }
