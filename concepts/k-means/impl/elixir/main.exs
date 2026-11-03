# k-means clustering (Lloyd's algorithm), using only Elixir's standard
# library.
#
# Starts from the first k points as centroids, then alternates two steps
# until no point changes cluster: assign each point to its nearest centroid,
# and move each centroid to the mean of its points. Elixir has no while
# loop, so the repetition is a function that calls itself.

defmodule KMeans do
  @k 3
  @max_iterations 100

  # The x and y columns as a list of {x, y} tuples. The header gives their
  # positions.
  def read_points(path) do
    [header | rows] = path |> File.read!() |> String.split("\n", trim: true)
    names = String.split(header, ",")
    xi = Enum.find_index(names, &(&1 == "x"))
    yi = Enum.find_index(names, &(&1 == "y"))

    Enum.map(rows, fn row ->
      fields = String.split(row, ",")
      # Float.parse returns {number, rest}; matching "" rejects trailing junk.
      {x, ""} = fields |> Enum.at(xi) |> Float.parse()
      {y, ""} = fields |> Enum.at(yi) |> Float.parse()
      {x, y}
    end)
  end

  # Squared Euclidean distance. It ranks centroids in the same order as the
  # distance itself, so finding the nearest one needs no sqrt.
  def squared_distance({ax, ay}, {bx, by}), do: (ax - bx) ** 2 + (ay - by) ** 2

  # The index of the closest centroid. Enum.min_by keeps the first of equal
  # distances, so a tie goes to the lower index.
  def nearest(point, centroids) do
    centroids
    |> Enum.with_index()
    |> Enum.min_by(fn {c, _j} -> squared_distance(point, c) end)
    |> elem(1)
  end

  # Move each centroid to the mean of its points. An empty cluster keeps its
  # old centroid.
  def update(points, assignment, centroids) do
    centroids
    |> Enum.with_index()
    |> Enum.map(fn {c, j} ->
      members = for {p, ^j} <- Enum.zip(points, assignment), do: p
      case members do
        [] -> c
        _ ->
          n = length(members)
          {members |> Enum.map(&elem(&1, 0)) |> Enum.sum() |> Kernel./(n),
           members |> Enum.map(&elem(&1, 1)) |> Enum.sum() |> Kernel./(n)}
      end
    end)
  end

  # One assignment step, then either stop or update and go again. previous
  # is nil before the first pass, so the first comparison always counts as a
  # change. == compares two lists element by element. Returns the number of
  # assignment steps, the final assignment, and the centroids.
  def run(points, iterations, previous, centroids) do
    step = iterations + 1
    assignment = Enum.map(points, &nearest(&1, centroids))

    cond do
      assignment == previous -> {step, assignment, centroids}
      step == @max_iterations -> {step, assignment, update(points, assignment, centroids)}
      true -> run(points, step, assignment, update(points, assignment, centroids))
    end
  end

  def k, do: @k
end

[path] = System.argv()
points = KMeans.read_points(path)
{iterations, assignment, centroids} = KMeans.run(points, 0, nil, Enum.take(points, KMeans.k()))

six = fn v -> :erlang.float_to_binary(v, decimals: 6) end
IO.puts("iterations #{iterations}")

# Clusters are numbered from 0 inside the program and from 1 in the output.
centroids
|> Enum.with_index(1)
|> Enum.each(fn {{x, y}, j} ->
  IO.puts("centroid_#{j}_x #{six.(x)}")
  IO.puts("centroid_#{j}_y #{six.(y)}")
end)

for j <- 0..(KMeans.k() - 1) do
  IO.puts("size_#{j + 1} #{Enum.count(assignment, &(&1 == j))}")
end

inertia =
  Enum.zip(points, assignment)
  |> Enum.map(fn {p, a} -> KMeans.squared_distance(p, Enum.at(centroids, a)) end)
  |> Enum.sum()

IO.puts("inertia #{six.(inertia)}")
