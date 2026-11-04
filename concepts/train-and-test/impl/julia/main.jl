# Train and test error for polynomials of degree 1 to 8, using only Base Julia.
#
# Each polynomial is fitted by least squares to the training drives only:
# we build the normal equations and solve them by Gaussian elimination,
# written out instead of the backslash operator. Then we measure its
# root-mean-square error on the training drives and on the test drives it
# never saw.

using Printf

const MAX_DEGREE = 8

# Each drive becomes a (speed, litres) tuple; columns are found by name.
function read_drives(path)
    lines = readlines(path)
    columns = split(lines[1], ",")
    i_speed = findfirst(==("speed"), columns)
    i_litres = findfirst(==("litres"), columns)
    i_split = findfirst(==("split"), columns)
    train, test = Tuple{Float64,Float64}[], Tuple{Float64,Float64}[]
    for line in lines[2:end]
        fields = split(line, ",")
        point = (parse(Float64, fields[i_speed]), parse(Float64, fields[i_litres]))
        push!(fields[i_split] == "train" ? train : test, point)
    end
    return train, test
end

# Solve A x = b by Gaussian elimination with partial pivoting.
function gauss(A, b)
    n = length(b)
    M = [A b]  # augmented matrix: a new copy, with b as an extra column
    for col in 1:n
        # Swap up the row with the largest entry in this column, which keeps
        # the rounding error small. argmax gives a position within col:n.
        pivot = col - 1 + argmax(abs.(M[col:n, col]))
        M[[col, pivot], :] = M[[pivot, col], :]
        for r in col+1:n
            factor = M[r, col] / M[col, col]
            M[r, :] .-= factor .* M[col, :]  # a whole row at once
        end
    end
    # Back substitution, from the last unknown up.
    x = zeros(n)
    for r in n:-1:1
        x[r] = (M[r, n+1] - sum(M[r, r+1:n] .* x[r+1:n])) / M[r, r]
    end
    return x
end

# Least squares: the coefficients c solve (Z' Z) c = Z' y, where row i of Z
# is 1, z_i, z_i^2, ..., z_i^degree. Broadcasting a column of z against a
# row of powers builds Z in one line.
powers(z, degree) = z .^ (0:degree)'

function fit(points, degree, scale)
    Z = powers(scale.(first.(points)), degree)
    y = last.(points)
    return gauss(Z' * Z, Z' * y)
end

function rmse(coefs, points, scale)
    predicted = powers(scale.(first.(points)), length(coefs) - 1) * coefs
    return sqrt(sum((predicted .- last.(points)) .^ 2) / length(points))
end

function main(path)
    train, test = read_drives(path)

    # Map the training speeds onto -1 to 1. Raw speeds to the 16th power (the
    # largest entry at degree 8) would swamp the small ones and make the
    # equations hard to solve accurately.
    low, high = extrema(first.(train))
    mid, half = (low + high) / 2, (high - low) / 2
    scale(x) = (x - mid) / half

    println("train_count $(length(train))")
    println("test_count $(length(test))")
    errors = map(1:MAX_DEGREE) do degree
        coefs = fit(train, degree, scale)
        (rmse(coefs, train, scale), rmse(coefs, test, scale))
    end
    for (degree, (train_error, _)) in enumerate(errors)
        @printf("train_rmse_d%d %.6f\n", degree, train_error)
    end
    for (degree, (_, test_error)) in enumerate(errors)
        @printf("test_rmse_d%d %.6f\n", degree, test_error)
    end
end

main(ARGS[1])
