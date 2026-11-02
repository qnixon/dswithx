# Principal component analysis with eigen, from the LinearAlgebra standard library.
#
# The built-in version of ../julia/main.jl. Statistics.cor builds the
# correlation matrix, and eigen finds all its eigenvalues and eigenvectors at
# once. eigen may return a vector with every sign flipped, so we apply the same
# rule as the from-scratch version: each one's first entry is positive.

using LinearAlgebra
using Printf
using Statistics

const SUBJECTS = ["math", "physics", "reading", "writing"]

function main(path)
    lines = readlines(path)
    header = split(lines[1], ",")
    order = [findfirst(==(s), header) for s in SUBJECTS]
    # One row per student, one column per subject.
    rows = [parse.(Float64, split(line, ","))[order] for line in lines[2:end]]
    X = reduce(vcat, permutedims.(rows))
    n, k = size(X)

    # Standardize with mean and std (std divides by n - 1).
    Z = (X .- mean(X, dims = 1)) ./ std(X, dims = 1)

    # For a symmetric matrix, eigen sorts eigenvalues from smallest to
    # largest, so sortby = - puts the largest first.
    values, vectors = eigen(Symmetric(cor(X)), sortby = -)

    println("count $n")
    pcs = Vector{Vector{Float64}}()
    for c in 1:2
        pc = vectors[:, c]
        pc[1] < 0 && (pc = -pc)
        push!(pcs, pc)
        @printf("eigenvalue_%d %.6f\n", c, values[c])
        # Standardized columns each have variance 1, so the total is k.
        @printf("explained_%d %.6f\n", c, values[c] / k)
        for (subject, loading) in zip(SUBJECTS, pc)
            @printf("pc%d_%s %.6f\n", c, subject, loading)
        end
    end
    @printf("student_1_pc1 %.6f\n", Z[1, :]' * pcs[1])
    @printf("student_1_pc2 %.6f\n", Z[1, :]' * pcs[2])
end

main(ARGS[1])
