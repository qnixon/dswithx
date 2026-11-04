# Exact two-sided permutation test for a difference in means, using only
# Elixir's standard library.
#
# If compost made no difference, the "compost" and "control" labels are
# arbitrary, and any 8 of the 16 plants could have carried the compost
# label. We try every one of those splits and count how many give a
# difference at least as large as the one we observed. That fraction is the
# p-value.

defmodule HypothesisTest do
  # Every row as a map, keyed by the header's column names.
  def read_rows(path) do
    [header | rows] =
      path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.map(&String.split(&1, ","))

    Enum.map(rows, fn fields -> header |> Enum.zip(fields) |> Map.new() end)
  end

  # The grams of every row in one group, as integers.
  def grams(rows, group) do
    for %{"group" => ^group, "grams" => text} <- rows, do: String.to_integer(text)
  end

  # The total of every way to choose k of the plants. The first plant is
  # either chosen (add it, and choose k - 1 from the rest) or not (choose
  # all k from the rest). The list has one total per split.
  def chosen_totals(0, _plants), do: [0]
  def chosen_totals(_k, []), do: []

  def chosen_totals(k, [plant | rest]) do
    Enum.map(chosen_totals(k - 1, rest), &(&1 + plant)) ++ chosen_totals(k, rest)
  end
end

[path] = System.argv()
rows = HypothesisTest.read_rows(path)
control = HypothesisTest.grams(rows, "control")
compost = HypothesisTest.grams(rows, "compost")
n = length(compost)
total = Enum.sum(control) + Enum.sum(compost)

# Both groups have n plants, so comparing totals is the same as comparing
# means, and integer totals stay whole numbers: no floating-point near-ties.
observed = Enum.sum(compost) - Enum.sum(control)

differences =
  for chosen <- HypothesisTest.chosen_totals(n, control ++ compost) do
    chosen - (total - chosen)
  end

splits = length(differences)
# Two-sided: a difference counts in either direction.
as_extreme = Enum.count(differences, &(abs(&1) >= abs(observed)))

# / always returns a float in Elixir, even for 3232 / 8.
format = &:erlang.float_to_binary(&1, decimals: 6)

IO.puts("control_count #{length(control)}")
IO.puts("compost_count #{n}")
IO.puts("control_mean #{format.(Enum.sum(control) / length(control))}")
IO.puts("compost_mean #{format.(Enum.sum(compost) / n)}")
IO.puts("observed_difference #{format.(observed / n)}")
IO.puts("splits #{splits}")
IO.puts("as_extreme #{as_extreme}")
IO.puts("p_value #{format.(as_extreme / splits)}")
