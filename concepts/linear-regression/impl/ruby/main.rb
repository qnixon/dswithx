# Simple linear regression by least squares, using only the standard library.
# Fits score = intercept + slope * hours.

X = "hours"
Y = "score"

# The csv library is a bundled gem since Ruby 3.4, not standard library, so
# split lines by hand. Fine for this data: no quoted fields or embedded commas.
def read_columns(path, *columns)
  header, *rows = File.readlines(path, chomp: true).map { |line| line.split(",") }
  columns.map do |column|
    index = header.index(column) or abort "no column #{column}"
    rows.map { |row| Float(row[index]) }
  end
end

xs, ys = read_columns(ARGV[0], X, Y)

n = xs.length
mean_x = xs.sum / n
mean_y = ys.sum / n

# Sums of squared deviations and of cross-products.
sxx = xs.sum { |x| (x - mean_x)**2 }
syy = ys.sum { |y| (y - mean_y)**2 }
sxy = xs.zip(ys).sum { |x, y| (x - mean_x) * (y - mean_y) }

slope = sxy / sxx
intercept = mean_y - slope * mean_x
r = sxy / Math.sqrt(sxx * syy)

puts "count #{n}"
{ slope: slope, intercept: intercept, r: r, r_squared: r * r }.each do |name, value|
  puts format("%s %.6f", name, value)
end
