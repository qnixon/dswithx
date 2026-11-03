# Simple linear regression by least squares, using only Elixir's standard
# library.
#
# Fits score = intercept + slope * hours. Elixir has Enum.sum but no mean,
# correlation, or regression, so the sums are written out and the formulas
# stay visible.

defmodule Regression do
  # One column, found by its header name and read as floats.
  def column([header | rows], name) do
    col = Enum.find_index(header, &(&1 == name))
    if col == nil, do: raise("column not found: #{name}")

    Enum.map(rows, fn fields ->
      # Float.parse returns {number, rest}; "12" parses as 12.0 too.
      {value, ""} = fields |> Enum.at(col) |> Float.parse()
      value
    end)
  end

  def mean(values), do: Enum.sum(values) / length(values)

  def say(name, value) do
    IO.puts("#{name} #{:erlang.float_to_binary(value, decimals: 6)}")
  end
end

[path] = System.argv()

# Every line split at its commas; the first is the header.
csv =
  path
  |> File.read!()
  |> String.split("\n", trim: true)
  |> Enum.map(&String.split(&1, ","))

xs = Regression.column(csv, "hours")
ys = Regression.column(csv, "score")

# First pass: the means.
mean_x = Regression.mean(xs)
mean_y = Regression.mean(ys)

# Second pass: deviations from the means. Enum.zip pairs each hours value
# with the score on the same row, as a tuple {x, y}.
sxx = xs |> Enum.map(fn x -> (x - mean_x) ** 2 end) |> Enum.sum()
syy = ys |> Enum.map(fn y -> (y - mean_y) ** 2 end) |> Enum.sum()

sxy =
  Enum.zip(xs, ys)
  |> Enum.map(fn {x, y} -> (x - mean_x) * (y - mean_y) end)
  |> Enum.sum()

slope = sxy / sxx
intercept = mean_y - slope * mean_x
r = sxy / :math.sqrt(sxx * syy)

IO.puts("count #{length(xs)}")
Regression.say("slope", slope)
Regression.say("intercept", intercept)
Regression.say("r", r)
Regression.say("r_squared", r * r)
