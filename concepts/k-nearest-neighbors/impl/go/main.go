// k-nearest neighbors classification, using only the standard library.
//
// Each test seed is labelled with the majority variety among its K nearest
// training seeds, by Euclidean distance.
package main

import (
	"cmp"
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"slices"
	"strconv"
)

const k = 5

var features = []string{"length_mm", "width_mm"}

const label = "variety"

type seed struct {
	features []float64
	label    string
}

func read(path string) (train, test []seed, err error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, nil, err
	}
	defer f.Close()

	records, err := csv.NewReader(f).ReadAll()
	if err != nil {
		return nil, nil, err
	}
	// Map each header name to its column number.
	column := map[string]int{}
	for i, name := range records[0] {
		column[name] = i
	}

	for _, record := range records[1:] {
		s := seed{label: record[column[label]]}
		for _, name := range features {
			v, err := strconv.ParseFloat(record[column[name]], 64)
			if err != nil {
				return nil, nil, err
			}
			s.features = append(s.features, v)
		}
		if record[column["split"]] == "train" {
			train = append(train, s)
		} else {
			test = append(test, s)
		}
	}
	return train, test, nil
}

func distance(a, b []float64) float64 {
	sum := 0.0
	for i := range a {
		sum += (a[i] - b[i]) * (a[i] - b[i])
	}
	return math.Sqrt(sum)
}

func classify(point []float64, train []seed) string {
	type neighbor struct {
		distance float64
		label    string
	}
	neighbors := make([]neighbor, len(train))
	for i, s := range train {
		neighbors[i] = neighbor{distance(point, s.features), s.label}
	}
	// A stable sort, so equal distances keep file order.
	slices.SortStableFunc(neighbors, func(a, b neighbor) int {
		return cmp.Compare(a.distance, b.distance)
	})

	// Count the votes of the K nearest. The comparison is strict, so a tied
	// vote goes to the label that reached the top count first.
	votes := map[string]int{}
	winner := ""
	for _, n := range neighbors[:k] {
		votes[n.label]++
		if votes[n.label] > votes[winner] {
			winner = n.label
		}
	}
	return winner
}

func main() {
	train, test, err := read(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	correct := 0
	for _, s := range test {
		if classify(s.features, train) == s.label {
			correct++
		}
	}

	fmt.Printf("train_count %d\n", len(train))
	fmt.Printf("test_count %d\n", len(test))
	fmt.Printf("correct %d\n", correct)
	fmt.Printf("accuracy %.6f\n", float64(correct)/float64(len(test)))
}
