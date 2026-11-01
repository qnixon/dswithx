# Principal component analysis by power iteration, using only Base Julia.
#
# Standardizes the four scores, builds their correlation matrix, and finds the
# top two eigenvectors (the principal components): power iteration finds the
# first, then deflation removes it from the matrix so the same steps find the
# second.

using Printf

const SUBJECTS = ["math", "physics", "reading", "writing"]
const STEPS = 1000

function top_eigenvector(M)
    # Power iteration: multiply by the matrix and rescale, STEPS times.
    v = [1.0; zeros(size(M, 1) - 1)]
    for _ in 1:STEPS
        w = M * v
        v = w / sqrt(w' * w)
    end
    # An eigenvector can point either way; make its first entry positive.
    v[1] < 0 && (v = -v)
    return v' * M * v, v  # eigenvalue, eigenvector
end

function main(path)
    lines = readlines(path)
    header = split(lines[1], ",")
    order = [findfirst(==(s), header) for s in SUBJECTS]
    # One row per student, one column per subject.
    rows = [parse.(Float64, split(line, ","))[order] for line in lines[2:end]]
    X = reduce(vcat, permutedims.(rows))
    n, k = size(X)

    # Standardize each column to mean 0 and (sample) standard deviation 1.
    means = sum(X, dims = 1) / n
    sds = sqrt.(sum((X .- means) .^ 2, dims = 1) / (n - 1))
    Z = (X .- means) ./ sds

    # The correlation matrix: the covariance of the standardized columns.
    corr = Z' * Z / (n - 1)

    value_1, pc_1 = top_eigenvector(corr)
    # Deflation: subtract the first component's share, leaving the rest.
    value_2, pc_2 = top_eigenvector(corr - value_1 * pc_1 * pc_1')

    println("count $n")
    for (c, (value, pc)) in enumerate([(value_1, pc_1), (value_2, pc_2)])
        @printf("eigenvalue_%d %.6f\n", c, value)
        # Standardized columns each have variance 1, so the total is k.
        @printf("explained_%d %.6f\n", c, value / k)
        for (subject, loading) in zip(SUBJECTS, pc)
            @printf("pc%d_%s %.6f\n", c, subject, loading)
        end
    end
    @printf("student_1_pc1 %.6f\n", Z[1, :]' * pc_1)
    @printf("student_1_pc2 %.6f\n", Z[1, :]' * pc_2)
end

main(ARGS[1])
