# Descriptive statistics on one CSV column, with the Statistics standard library.
#
# The built-in version of ../julia/main.jl: mean, median, var, and std do the
# arithmetic. var and std are the sample versions, dividing by n - 1, unless
# you pass corrected=false.

using Printf
using Statistics

const COLUMN = "minutes"

function read_column(path, column)
    lines = readlines(path)
    index = findfirst(==(column), split(lines[1], ","))
    return [parse(Float64, split(line, ",")[index]) for line in lines[2:end]]
end

function main(path)
    values = read_column(path, COLUMN)
    low, high = extrema(values)

    results = [
        "sum" => sum(values),
        "mean" => mean(values),
        "median" => median(values),
        "min" => low,
        "max" => high,
        "range" => high - low,
        "variance" => var(values),
        "std_dev" => std(values),
    ]

    println("count $(length(values))")
    for (name, value) in results
        @printf("%s %.6f\n", name, value)
    end
end

main(ARGS[1])
