// 5-fold cross-validation for k-nearest neighbors, using only the standard
// library.
//
// Splits the training seeds into 5 folds, scores each odd k from 1 to 15 by
// holding out one fold at a time, picks the k with the best average accuracy,
// and then scores that k once on the untouched test seeds.
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

const folds = 5

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

func classify(point []float64, train []seed, k int) string {
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

	// Count the votes of the k nearest. The comparison is strict, so a tied
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

func countCorrect(points, train []seed, k int) int {
	correct := 0
	for _, s := range points {
		if classify(s.features, train, k) == s.label {
			correct++
		}
	}
	return correct
}

// Fold f is rows f*size up to (f+1)*size. The rows are already shuffled, so
// consecutive blocks make fair folds.
func cvAccuracy(train []seed, k int) float64 {
	size := len(train) / folds
	correct := 0
	for f := range folds {
		heldOut := train[f*size : (f+1)*size]
		// slices.Concat copies into a new slice. append(train[:f*size], ...)
		// would write over train's own rows, since the two share memory.
		rest := slices.Concat(train[:f*size], train[(f+1)*size:])
		correct += countCorrect(heldOut, rest, k)
	}
	return float64(correct) / float64(len(train))
}

func main() {
	train, test, err := read(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	fmt.Printf("train_count %d\n", len(train))
	fmt.Printf("test_count %d\n", len(test))
	bestK, bestAccuracy := 0, -1.0
	for k := 1; k <= 15; k += 2 { // odd k only
		accuracy := cvAccuracy(train, k)
		fmt.Printf("cv_accuracy_k%d %.6f\n", k, accuracy)
		if accuracy > bestAccuracy { // strictly better, so ties keep the smaller k
			bestK, bestAccuracy = k, accuracy
		}
	}

	// Only now touch the test seeds, once, with the chosen k and all of train.
	correct := countCorrect(test, train, bestK)
	fmt.Printf("best_k %d\n", bestK)
	fmt.Printf("test_correct %d\n", correct)
	fmt.Printf("test_accuracy %.6f\n", float64(correct)/float64(len(test)))
}
