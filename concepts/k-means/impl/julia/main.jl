# k-means clustering (Lloyd's algorithm), using only Base Julia.
#
# Starts from the first K points as centroids, then alternates two steps until
# no point changes cluster: assign each point to its nearest centroid, and move
# each centroid to the mean of its points.

using Printf

const K = 3
const MAX_ITERATIONS = 100

distance(a, b) = sqrt(sum((a .- b) .^ 2))

# argmin returns the first of equal distances, so ties go to the lower index.
nearest(point, centroids) = argmin([distance(point, c) for c in centroids])

function main(path)
    lines = Iterators.drop(eachline(path), 1)  # skip the header
    points = [parse.(Float64, split(line, ",")) for line in lines]

    centroids = points[1:K]  # a slice is a new vector, so points is never changed
    assignment = Int[]
    iterations = 0
    while iterations < MAX_ITERATIONS
        iterations += 1
        new_assignment = [nearest(p, centroids) for p in points]
        new_assignment == assignment && break
        assignment = new_assignment
        for j in 1:K
            members = points[assignment .== j]
            if !isempty(members)  # an empty cluster keeps its old centroid
                centroids[j] = sum(members) / length(members)
            end
        end
    end

    inertia = sum(distance(p, centroids[a])^2 for (p, a) in zip(points, assignment))

    println("iterations $iterations")
    for (j, (x, y)) in enumerate(centroids)
        @printf("centroid_%d_x %.6f\n", j, x)
        @printf("centroid_%d_y %.6f\n", j, y)
    end
    for j in 1:K
        println("size_$j $(count(==(j), assignment))")
    end
    @printf("inertia %.6f\n", inertia)
end

main(ARGS[1])
