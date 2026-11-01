// Descriptive statistics on one CSV column, using only the standard library.
//
// Go has no statistics package, so the sum, mean, median, and variance are
// written out by hand.
package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"slices"
	"strconv"
)

const column = "minutes"

// readColumn returns one column of a CSV file, found by its header name.
func readColumn(path, name string) ([]float64, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	records, err := csv.NewReader(f).ReadAll()
	if err != nil {
		return nil, err
	}
	index := slices.Index(records[0], name)
	if index < 0 {
		return nil, fmt.Errorf("no column %q", name)
	}

	values := make([]float64, 0, len(records)-1)
	for _, record := range records[1:] {
		v, err := strconv.ParseFloat(record[index], 64)
		if err != nil {
			return nil, err
		}
		values = append(values, v)
	}
	return values, nil
}

// median expects the values already sorted.
func median(sorted []float64) float64 {
	n := len(sorted)
	middle := n / 2 // integer division: 120 / 2 is 60
	if n%2 == 1 {
		return sorted[middle]
	}
	return (sorted[middle-1] + sorted[middle]) / 2
}

func main() {
	values, err := readColumn(os.Args[1], column)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	slices.Sort(values)

	n := len(values)
	total := 0.0
	for _, v := range values {
		total += v
	}
	// n is an int; Go never converts between number types implicitly.
	mean := total / float64(n)

	// Sample variance divides by n - 1, not n (Bessel's correction).
	squares := 0.0
	for _, v := range values {
		squares += (v - mean) * (v - mean)
	}
	variance := squares / float64(n-1)

	fmt.Printf("count %d\n", n)
	fmt.Printf("sum %.6f\n", total)
	fmt.Printf("mean %.6f\n", mean)
	fmt.Printf("median %.6f\n", median(values))
	fmt.Printf("min %.6f\n", values[0])
	fmt.Printf("max %.6f\n", values[n-1])
	fmt.Printf("range %.6f\n", values[n-1]-values[0])
	fmt.Printf("variance %.6f\n", variance)
	fmt.Printf("std_dev %.6f\n", math.Sqrt(variance))
}
