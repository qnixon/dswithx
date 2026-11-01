// Principal component analysis by power iteration, using only the standard
// library.
//
// Standardizes the four scores, builds their correlation matrix, and finds the
// top two eigenvectors (the principal components): power iteration finds the
// first, then deflation removes it from the matrix so the same steps find the
// second.
package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"slices"
	"strconv"
)

var subjects = [k]string{"math", "physics", "reading", "writing"}

const (
	k     = 4 // number of subjects
	steps = 1000
)

// Arrays have a fixed length that is part of the type, and assigning one
// copies it, so a vector or matrix never shares storage by accident.
type (
	vector [k]float64
	matrix [k]vector
)

func read(path string) ([]vector, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	records, err := csv.NewReader(f).ReadAll()
	if err != nil {
		return nil, err
	}
	var index [k]int
	for j, name := range subjects {
		index[j] = slices.Index(records[0], name)
		if index[j] < 0 {
			return nil, fmt.Errorf("no column %s", name)
		}
	}

	rows := make([]vector, 0, len(records)-1)
	for _, record := range records[1:] {
		var row vector
		for j, i := range index {
			row[j], err = strconv.ParseFloat(record[i], 64)
			if err != nil {
				return nil, err
			}
		}
		rows = append(rows, row)
	}
	return rows, nil
}

func dot(u, v vector) float64 {
	total := 0.0
	for i := range k {
		total += u[i] * v[i]
	}
	return total
}

func (m matrix) times(v vector) vector {
	var out vector
	for i, row := range m {
		out[i] = dot(row, v)
	}
	return out
}

func normalize(v vector) vector {
	length := math.Sqrt(dot(v, v))
	for i := range v {
		v[i] /= length // v is a copy, so the caller's vector is untouched
	}
	return v
}

// topEigenvector runs power iteration: multiply by the matrix and rescale,
// steps times. It returns the eigenvalue and the eigenvector.
func topEigenvector(m matrix) (float64, vector) {
	v := vector{1}
	for range steps {
		v = normalize(m.times(v))
	}
	// An eigenvector can point either way; make its first entry positive.
	if v[0] < 0 {
		for i := range v {
			v[i] = -v[i]
		}
	}
	return dot(v, m.times(v)), v
}

func main() {
	rows, err := read(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	n := float64(len(rows))

	// Standardize each column to mean 0 and (sample) standard deviation 1.
	var means, sds vector
	for _, row := range rows {
		for j := range k {
			means[j] += row[j]
		}
	}
	for j := range k {
		means[j] /= n
	}
	for _, row := range rows {
		for j := range k {
			sds[j] += (row[j] - means[j]) * (row[j] - means[j])
		}
	}
	for j := range k {
		sds[j] = math.Sqrt(sds[j] / (n - 1))
	}
	z := make([]vector, len(rows))
	for r, row := range rows {
		for j := range k {
			z[r][j] = (row[j] - means[j]) / sds[j]
		}
	}

	// The correlation matrix: the covariance of the standardized columns.
	var corr matrix
	for _, r := range z {
		for i := range k {
			for j := range k {
				corr[i][j] += r[i] * r[j] / (n - 1)
			}
		}
	}

	value1, pc1 := topEigenvector(corr)
	// Deflation: subtract the first component's share, leaving the rest.
	deflated := corr // a full copy, since matrix is an array
	for i := range k {
		for j := range k {
			deflated[i][j] -= value1 * pc1[i] * pc1[j]
		}
	}
	value2, pc2 := topEigenvector(deflated)

	fmt.Printf("count %d\n", len(rows))
	for c, pc := range []struct {
		value float64
		v     vector
	}{{value1, pc1}, {value2, pc2}} {
		fmt.Printf("eigenvalue_%d %.6f\n", c+1, pc.value)
		// Standardized columns each have variance 1, so the total is k.
		fmt.Printf("explained_%d %.6f\n", c+1, pc.value/k)
		for j, subject := range subjects {
			fmt.Printf("pc%d_%s %.6f\n", c+1, subject, pc.v[j])
		}
	}
	fmt.Printf("student_1_pc1 %.6f\n", dot(z[0], pc1))
	fmt.Printf("student_1_pc2 %.6f\n", dot(z[0], pc2))
}
