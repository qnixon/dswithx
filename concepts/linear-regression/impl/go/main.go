// Simple linear regression by least squares, using only the standard library.
//
// Fits score = intercept + slope * hours. Go has no regression function to
// avoid; the sums are written out so the formulas stay visible.
package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"slices"
	"strconv"
)

const xName, yName = "hours", "score"

// readColumns returns the named columns of a CSV file, found by header name.
func readColumns(path string, names ...string) ([][]float64, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	records, err := csv.NewReader(f).ReadAll()
	if err != nil {
		return nil, err
	}
	columns := make([][]float64, len(names))
	for c, name := range names {
		index := slices.Index(records[0], name)
		if index < 0 {
			return nil, fmt.Errorf("no column %q", name)
		}
		for _, record := range records[1:] {
			v, err := strconv.ParseFloat(record[index], 64)
			if err != nil {
				return nil, err
			}
			columns[c] = append(columns[c], v)
		}
	}
	return columns, nil
}

func mean(values []float64) float64 {
	total := 0.0
	for _, v := range values {
		total += v
	}
	return total / float64(len(values))
}

func main() {
	columns, err := readColumns(os.Args[1], xName, yName)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	xs, ys := columns[0], columns[1]

	meanX, meanY := mean(xs), mean(ys)

	// Sums of squared deviations and of cross-products.
	var sxx, syy, sxy float64
	for i := range xs {
		dx, dy := xs[i]-meanX, ys[i]-meanY
		sxx += dx * dx
		syy += dy * dy
		sxy += dx * dy
	}

	slope := sxy / sxx
	intercept := meanY - slope*meanX
	r := sxy / math.Sqrt(sxx*syy)

	fmt.Printf("count %d\n", len(xs))
	fmt.Printf("slope %.6f\n", slope)
	fmt.Printf("intercept %.6f\n", intercept)
	fmt.Printf("r %.6f\n", r)
	fmt.Printf("r_squared %.6f\n", r*r)
}
