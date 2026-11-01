# Simple linear regression by least squares, using only Base Julia.
#
# Fits score = intercept + slope * hours. The backslash operator, X \ y,
# would solve it in one step; the sums are written out instead.

using Printf

function read_columns(path)
    lines = readlines(path)
    header = split(lines[1], ",")
    rows = [parse.(Float64, split(line, ",")) for line in lines[2:end]]
    column(name) = [row[findfirst(==(name), header)] for row in rows]
    return column("hours"), column("score")
end

function main(path)
    x, y = read_columns(path)

    n = length(x)
    mean_x = sum(x) / n
    mean_y = sum(y) / n

    # Sums of squared deviations and of cross-products. The dot in .- and .*
    # applies the operator to every element.
    sxx = sum((x .- mean_x) .^ 2)
    syy = sum((y .- mean_y) .^ 2)
    sxy = sum((x .- mean_x) .* (y .- mean_y))

    slope = sxy / sxx
    intercept = mean_y - slope * mean_x
    r = sxy / sqrt(sxx * syy)

    println("count $n")
    @printf("slope %.6f\n", slope)
    @printf("intercept %.6f\n", intercept)
    @printf("r %.6f\n", r)
    @printf("r_squared %.6f\n", r^2)
end

main(ARGS[1])
