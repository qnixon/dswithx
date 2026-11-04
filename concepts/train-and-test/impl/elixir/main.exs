# Train and test error for polynomials of degree 1 to 8, using only
# Elixir's standard library.
#
# Each polynomial is fitted by least squares to the training drives only: we
# build the normal equations and solve them by Gaussian elimination. Then we
# measure its root-mean-square error on the training drives and on the test
# drives it never saw. A matrix is a list of row lists, and nothing is
# changed in place.

defmodule TrainAndTest do
  @max_degree 8

  def max_degree, do: @max_degree

  # Every drive as {split, speed, litres}, with each column found by its
  # header name. Float.parse returns {number, rest}; "42" parses as 42.0 too.
  def read_drives(path) do
    [header | rows] =
      path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.map(&String.split(&1, ","))

    number = fn text -> {value, ""} = Float.parse(text); value end

    for fields <- rows do
      row = header |> Enum.zip(fields) |> Map.new()
      {row["split"], number.(row["speed"]), number.(row["litres"])}
    end
  end

  # Solve a x = b by Gaussian elimination with partial pivoting. Each row of
  # the augmented matrix is a row of a with its entry of b on the end.
  def solve(a, b) do
    a
    |> Enum.zip_with(b, fn row, v -> row ++ [v] end)
    |> eliminate()
    |> back_substitute()
  end

  # Take out the row with the largest first entry, which keeps the rounding
  # error small, and subtract a multiple of it from every other row so their
  # first entries become 0. Those rows, without their first column, are a
  # smaller system of the same kind, so we recurse. Each row of the triangle
  # is one entry shorter than the last.
  defp eliminate([]), do: []

  defp eliminate(rows) do
    [p | pivot_rest] = pivot = Enum.max_by(rows, fn [x | _] -> abs(x) end)

    reduced =
      for [r | row_rest] <- List.delete(rows, pivot) do
        factor = r / p
        Enum.zip_with(pivot_rest, row_rest, fn pc, rc -> rc - factor * pc end)
      end

    [pivot | eliminate(reduced)]
  end

  # Back substitution, from the last unknown up. Each triangle row is
  # [coefficient, entries for the later unknowns ..., right-hand side].
  defp back_substitute([]), do: []

  defp back_substitute([[coefficient | rest] | rows]) do
    later = back_substitute(rows)
    {entries, [rhs]} = Enum.split(rest, -1)
    [(rhs - dot(entries, later)) / coefficient | later]
  end

  # zip_reduce walks two lists side by side, carrying a running total.
  def dot(u, v), do: Enum.zip_reduce(u, v, 0.0, fn a, b, acc -> acc + a * b end)

  # Least squares: the coefficients c solve (Z^T Z) c = Z^T y, where row i
  # of Z is 1, z_i, z_i^2, ..., z_i^degree. points holds {z, y} pairs.
  def fit(points, degree) do
    a =
      for i <- 0..degree do
        for j <- 0..degree, do: Enum.sum(for {z, _} <- points, do: z ** (i + j))
      end

    b = for i <- 0..degree, do: Enum.sum(for {z, y} <- points, do: y * z ** i)
    solve(a, b)
  end

  def rmse(coefs, points) do
    predict = fn z ->
      coefs |> Enum.with_index() |> Enum.map(fn {c, i} -> c * z ** i end) |> Enum.sum()
    end

    total = Enum.sum(for {z, y} <- points, do: (predict.(z) - y) ** 2)
    :math.sqrt(total / length(points))
  end

  def say(name, value), do: IO.puts("#{name} #{:erlang.float_to_binary(value, decimals: 6)}")
end

[path] = System.argv()
drives = TrainAndTest.read_drives(path)
train = for {"train", x, y} <- drives, do: {x, y}
test = for {"test", x, y} <- drives, do: {x, y}

# Map the training speeds onto -1 to 1. Raw speeds to the 16th power (the
# largest entry at degree 8) would swamp the small ones and make the
# equations hard to solve accurately.
{low, high} = train |> Enum.map(fn {x, _} -> x end) |> Enum.min_max()
mid = (low + high) / 2
half = (high - low) / 2
scale = fn points -> for {x, y} <- points, do: {(x - mid) / half, y} end
train_z = scale.(train)
test_z = scale.(test)

IO.puts("train_count #{length(train)}")
IO.puts("test_count #{length(test)}")
fits = for d <- 1..TrainAndTest.max_degree(), do: {d, TrainAndTest.fit(train_z, d)}
for {d, coefs} <- fits, do: TrainAndTest.say("train_rmse_d#{d}", TrainAndTest.rmse(coefs, train_z))
for {d, coefs} <- fits, do: TrainAndTest.say("test_rmse_d#{d}", TrainAndTest.rmse(coefs, test_z))
