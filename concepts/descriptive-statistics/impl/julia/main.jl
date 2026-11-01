# Descriptive statistics on one CSV column, using only Base Julia.
#
# The Statistics standard library has mean, median, var, and std; they are
# avoided on purpose so the arithmetic stays visible.

using Printf

const COLUMN = "minutes"

function read_column(path, column)
    lines = readlines(path)
    index = findfirst(==(column), split(lines[1], ","))
    return [parse(Float64, split(line, ",")[index]) for line in lines[2:end]]
end

function median_of_sorted(values)
    n = length(values)
    middle = n ÷ 2
    # Julia counts from 1, so for even n the middle pair is middle and middle + 1.
    isodd(n) ? values[middle + 1] : (values[middle] + values[middle + 1]) / 2
end

function main(path)
    values = sort(read_column(path, COLUMN))

    n = length(values)
    total = sum(values)
    mean = total / n
    # Sample variance divides by n - 1, not n (Bessel's correction).
    variance = sum((values .- mean) .^ 2) / (n - 1)

    results = [
        "sum" => total,
        "mean" => mean,
        "median" => median_of_sorted(values),
        "min" => first(values),
        "max" => last(values),
        "range" => last(values) - first(values),
        "variance" => variance,
        "std_dev" => sqrt(variance),
    ]

    println("count $n")
    for (name, value) in results
        @printf("%s %.6f\n", name, value)
    end
end

main(ARGS[1])
