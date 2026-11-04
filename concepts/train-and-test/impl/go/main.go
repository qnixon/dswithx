// Train and test error for polynomials of degree 1 to 8, using only the
// standard library.
//
// Each polynomial is fitted by least squares to the training drives only:
// we build the normal equations and solve them by Gaussian elimination. Then
// we measure its root-mean-square error on the training drives and on the
// test drives it never saw.
package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"strconv"
)

const maxDegree = 8

type point struct{ speed, litres float64 }

func read(path string) (train, test []point, err error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, nil, err
	}
	defer f.Close()

	records, err := csv.NewReader(f).ReadAll()
	if err != nil {
		return nil, nil, err
	}
	// Find each column by name in the header.
	iSpeed, iLitres, iSplit := -1, -1, -1
	for i, name := range records[0] {
		switch name {
		case "speed":
			iSpeed = i
		case "litres":
			iLitres = i
		case "split":
			iSplit = i
		}
	}
	if iSpeed < 0 || iLitres < 0 || iSplit < 0 {
		return nil, nil, fmt.Errorf("missing a column (speed, litres, split)")
	}
	for _, record := range records[1:] {
		speed, err := strconv.ParseFloat(record[iSpeed], 64)
		if err != nil {
			return nil, nil, err
		}
		litres, err := strconv.ParseFloat(record[iLitres], 64)
		if err != nil {
			return nil, nil, err
		}
		p := point{speed, litres}
		if record[iSplit] == "train" {
			train = append(train, p)
		} else {
			test = append(test, p)
		}
	}
	return train, test, nil
}

// solve solves a x = b by Gaussian elimination with partial pivoting.
func solve(a [][]float64, b []float64) []float64 {
	n := len(b)
	// The augmented matrix, a fresh copy so a and b are untouched.
	m := make([][]float64, n)
	for i := range a {
		m[i] = append(append([]float64{}, a[i]...), b[i])
	}
	for col := 0; col < n; col++ {
		// Swap up the row with the largest entry in this column, which keeps
		// the rounding error small. Rows are slices, so this swaps headers,
		// not the numbers inside.
		pivot := col
		for r := col + 1; r < n; r++ {
			if math.Abs(m[r][col]) > math.Abs(m[pivot][col]) {
				pivot = r
			}
		}
		m[col], m[pivot] = m[pivot], m[col]
		for r := col + 1; r < n; r++ {
			factor := m[r][col] / m[col][col]
			for c := col; c <= n; c++ {
				m[r][c] -= factor * m[col][c]
			}
		}
	}
	// Back substitution, from the last unknown up.
	x := make([]float64, n)
	for r := n - 1; r >= 0; r-- {
		total := m[r][n]
		for c := r + 1; c < n; c++ {
			total -= m[r][c] * x[c]
		}
		x[r] = total / m[r][r]
	}
	return x
}

// fit finds least-squares coefficients: c solves (Z^T Z) c = Z^T y, where
// row i of Z is 1, z_i, z_i^2, ..., z_i^degree.
func fit(points []point, degree int, scale func(float64) float64) []float64 {
	size := degree + 1
	a := make([][]float64, size)
	for i := range a {
		a[i] = make([]float64, size)
	}
	b := make([]float64, size)
	for _, p := range points {
		z := scale(p.speed)
		for i := 0; i < size; i++ {
			b[i] += p.litres * math.Pow(z, float64(i))
			for j := 0; j < size; j++ {
				a[i][j] += math.Pow(z, float64(i+j))
			}
		}
	}
	return solve(a, b)
}

func rmse(coefs []float64, points []point, scale func(float64) float64) float64 {
	total := 0.0
	for _, p := range points {
		z := scale(p.speed)
		predicted := 0.0
		for i, c := range coefs {
			predicted += c * math.Pow(z, float64(i))
		}
		total += (predicted - p.litres) * (predicted - p.litres)
	}
	return math.Sqrt(total / float64(len(points)))
}

func main() {
	train, test, err := read(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	// Map the training speeds onto -1 to 1. Raw speeds to the 16th power
	// (the largest entry at degree 8) would swamp the small ones and make
	// the equations hard to solve accurately.
	low, high := train[0].speed, train[0].speed
	for _, p := range train {
		low = math.Min(low, p.speed)
		high = math.Max(high, p.speed)
	}
	mid, half := (low+high)/2, (high-low)/2
	scale := func(x float64) float64 { return (x - mid) / half }

	fmt.Printf("train_count %d\n", len(train))
	fmt.Printf("test_count %d\n", len(test))
	var trainErrors, testErrors [maxDegree + 1]float64 // index 0 unused
	for degree := 1; degree <= maxDegree; degree++ {
		coefs := fit(train, degree, scale)
		trainErrors[degree] = rmse(coefs, train, scale)
		testErrors[degree] = rmse(coefs, test, scale)
	}
	for degree := 1; degree <= maxDegree; degree++ {
		fmt.Printf("train_rmse_d%d %.6f\n", degree, trainErrors[degree])
	}
	for degree := 1; degree <= maxDegree; degree++ {
		fmt.Printf("test_rmse_d%d %.6f\n", degree, testErrors[degree])
	}
}
