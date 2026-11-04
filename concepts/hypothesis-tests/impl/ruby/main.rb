# Exact two-sided permutation test for a difference in means, using only the
# standard library.
#
# If compost made no difference, the "compost" and "control" labels are
# arbitrary, and any 8 of the 16 plants could have carried the compost label.
# We try every one of those splits and count how many give a difference at
# least as large as the one we observed. That fraction is the p-value.

# The csv library is a bundled gem since Ruby 3.4, so split lines by hand
# (no quoted fields here).
def read(path)
  groups = { "control" => [], "compost" => [] }
  File.readlines(path, chomp: true).drop(1).each do |line|
    group, grams = line.split(",")
    groups.fetch(group) << Integer(grams)
  end
  groups.values_at("control", "compost")
end

control, compost = read(ARGV[0])
n = compost.length
plants = control + compost
total = plants.sum

# Both groups have n plants, so comparing totals is the same as comparing
# means, and totals stay whole numbers: no floating-point near-ties.
observed = compost.sum - control.sum

splits = 0
as_extreme = 0
# combination(n) yields each choice of n plants once, in a fixed order.
plants.combination(n) do |chosen|
  relabeled = chosen.sum
  difference = relabeled - (total - relabeled)
  splits += 1
  as_extreme += 1 if difference.abs >= observed.abs # two-sided
end

puts "control_count #{control.length}"
puts "compost_count #{n}"
puts format("control_mean %.6f", control.sum.fdiv(control.length))
puts format("compost_mean %.6f", compost.sum.fdiv(n))
puts format("observed_difference %.6f", observed.fdiv(n))
puts "splits #{splits}"
puts "as_extreme #{as_extreme}"
puts format("p_value %.6f", as_extreme.fdiv(splits))
