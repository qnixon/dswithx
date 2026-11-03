# Descriptive statistics on one CSV column, using only Elixir's standard
# library.
#
# Elixir has Enum.sum but no mean, median, or variance, so those are written
# out. Data never changes in place: each step takes a list and returns a new
# value, and |> passes a value into the next function as its first argument.

defmodule Stats do
  def read_column(path, name) do
    [header | rows] = path |> File.read!() |> String.split("\n", trim: true)
    col = header |> String.split(",") |> Enum.find_index(&(&1 == name))
    if col == nil, do: raise("column not found: #{name}")

    Enum.map(rows, fn row ->
      # Float.parse returns {number, rest}; "12" parses as 12.0 too.
      {value, ""} = row |> String.split(",") |> Enum.at(col) |> Float.parse()
      value
    end)
  end

  def median(sorted) do
    n = length(sorted)
    mid = div(n, 2)                    # div is integer division
    if rem(n, 2) == 1 do
      Enum.at(sorted, mid)
    else
      (Enum.at(sorted, mid - 1) + Enum.at(sorted, mid)) / 2
    end
  end

  def say(name, value) do
    IO.puts("#{name} #{:erlang.float_to_binary(value, decimals: 6)}")
  end
end

[path] = System.argv()
values = path |> Stats.read_column("minutes") |> Enum.sort()

n = length(values)
total = Enum.sum(values)
mean = total / n                       # / always gives a float

# Sample variance divides by n - 1, not n (Bessel's correction).
sumsq = values |> Enum.map(fn v -> (v - mean) ** 2 end) |> Enum.sum()
variance = sumsq / (n - 1)

min = List.first(values)
max = List.last(values)

IO.puts("count #{n}")
Stats.say("sum", total)
Stats.say("mean", mean)
Stats.say("median", Stats.median(values))
Stats.say("min", min)
Stats.say("max", max)
Stats.say("range", max - min)
Stats.say("variance", variance)
Stats.say("std_dev", :math.sqrt(variance))
