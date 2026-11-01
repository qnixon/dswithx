// Categorical naive Bayes with add-one (Laplace) smoothing, standard library only.
//
// Learns P(label) and P(feature value | label) by counting training rows, then
// labels each test row with the label that has the highest log-probability.
package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"slices"
)

var features = []string{"has_link", "mentions_money", "known_sender"}

const label = "label"

// key identifies one count: how many training rows of a label have a value.
type key struct{ feature, value, label string }

// readRows returns each CSV row as a map from header name to value.
func readRows(path string) ([]map[string]string, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	records, err := csv.NewReader(f).ReadAll()
	if err != nil {
		return nil, err
	}
	rows := make([]map[string]string, 0, len(records)-1)
	for _, record := range records[1:] {
		row := map[string]string{}
		for i, name := range records[0] {
			row[name] = record[i]
		}
		rows = append(rows, row)
	}
	return rows, nil
}

func main() {
	rows, err := readRows(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	var train, test []map[string]string
	for _, row := range rows {
		if row["split"] == "train" {
			train = append(train, row)
		} else {
			test = append(test, row)
		}
	}

	// A missing map key reads as zero, so these work as counters.
	labelCounts := map[string]int{}
	valueCounts := map[key]int{}
	seen := map[string]map[string]bool{} // distinct values of each feature
	for _, f := range features {
		seen[f] = map[string]bool{}
	}
	for _, row := range train {
		labelCounts[row[label]]++
		for _, f := range features {
			valueCounts[key{f, row[f], row[label]}]++
			seen[f][row[f]] = true
		}
	}

	// Map iteration order is random in Go, so sort the labels to get a fixed
	// order: an exact tie goes to the alphabetically first label.
	labels := make([]string, 0, len(labelCounts))
	for l := range labelCounts {
		labels = append(labels, l)
	}
	slices.Sort(labels)

	logScore := func(row map[string]string, l string) float64 {
		// Logs turn the product of probabilities into a sum, avoiding underflow.
		score := math.Log(float64(labelCounts[l]) / float64(len(train)))
		for _, f := range features {
			// Add-one smoothing: an unseen value never gets probability zero.
			count := float64(valueCounts[key{f, row[f], l}] + 1)
			score += math.Log(count / float64(labelCounts[l]+len(seen[f])))
		}
		return score
	}

	classify := func(row map[string]string) string {
		best := labels[0]
		for _, l := range labels[1:] {
			if logScore(row, l) > logScore(row, best) {
				best = l
			}
		}
		return best
	}

	correct := 0
	for _, row := range test {
		if classify(row) == row[label] {
			correct++
		}
	}

	fmt.Printf("train_count %d\n", len(train))
	fmt.Printf("test_count %d\n", len(test))
	fmt.Printf("correct %d\n", correct)
	fmt.Printf("accuracy %.6f\n", float64(correct)/float64(len(test)))
}
