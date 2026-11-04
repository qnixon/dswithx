// Evaluation metrics for a binary classifier, using only the standard
// library.
//
// Reads each part's true label and the model's score, then reports the
// confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
// the accuracy of never flagging anything, and the area under the ROC curve.
package main

import (
	"encoding/csv"
	"fmt"
	"os"
	"strconv"
)

type part struct {
	defective bool
	score     float64
}

func read(path string) ([]part, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	records, err := csv.NewReader(f).ReadAll()
	if err != nil {
		return nil, err
	}
	// Find each column by name in the header.
	iLabel, iScore := -1, -1
	for i, name := range records[0] {
		switch name {
		case "defective":
			iLabel = i
		case "score":
			iScore = i
		}
	}
	if iLabel < 0 || iScore < 0 {
		return nil, fmt.Errorf("missing a column (defective, score)")
	}
	var parts []part
	for _, record := range records[1:] {
		score, err := strconv.ParseFloat(record[iScore], 64)
		if err != nil {
			return nil, err
		}
		parts = append(parts, part{record[iLabel] == "1", score})
	}
	return parts, nil
}

func report(parts []part, suffix string, threshold float64) {
	// A part is flagged when its score reaches the threshold.
	var tp, fp, fn, tn int
	for _, p := range parts {
		flagged := p.score >= threshold
		switch {
		case flagged && p.defective:
			tp++
		case flagged:
			fp++
		case p.defective:
			fn++
		default:
			tn++
		}
	}

	// Go never converts int to float64 on its own, so each ratio says so.
	accuracy := float64(tp+tn) / float64(len(parts))
	precision := float64(tp) / float64(tp+fp) // of the flagged parts, how many are defective
	recall := float64(tp) / float64(tp+fn)    // of the defective parts, how many are flagged
	f1 := 2 * precision * recall / (precision + recall)

	fmt.Printf("tp_at_%s %d\n", suffix, tp)
	fmt.Printf("fp_at_%s %d\n", suffix, fp)
	fmt.Printf("fn_at_%s %d\n", suffix, fn)
	fmt.Printf("tn_at_%s %d\n", suffix, tn)
	fmt.Printf("accuracy_at_%s %.6f\n", suffix, accuracy)
	fmt.Printf("precision_at_%s %.6f\n", suffix, precision)
	fmt.Printf("recall_at_%s %.6f\n", suffix, recall)
	fmt.Printf("f1_at_%s %.6f\n", suffix, f1)
}

// auc is the chance that a random defective part outscores a random good
// one. Compare every pair, scoring 2 for a win and 1 for a tie, so the
// count stays a whole number until the final division.
func auc(parts []part) float64 {
	var defective, good []float64
	for _, p := range parts {
		if p.defective {
			defective = append(defective, p.score)
		} else {
			good = append(good, p.score)
		}
	}
	points := 0
	for _, d := range defective {
		for _, g := range good {
			if d > g {
				points += 2
			} else if d == g {
				points++
			}
		}
	}
	return float64(points) / float64(2*len(defective)*len(good))
}

func main() {
	parts, err := read(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	defective := 0
	for _, p := range parts {
		if p.defective {
			defective++
		}
	}

	fmt.Printf("parts %d\n", len(parts))
	fmt.Printf("defective %d\n", defective)
	// Never flagging anything is right about every good part.
	fmt.Printf("baseline_accuracy %.6f\n", float64(len(parts)-defective)/float64(len(parts)))
	report(parts, "50", 0.5)
	report(parts, "30", 0.3)
	fmt.Printf("auc %.6f\n", auc(parts))
}
