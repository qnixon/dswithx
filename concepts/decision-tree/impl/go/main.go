// A decision tree classifier (CART with Gini impurity), using only the
// standard library.
//
// Grows a tree on the training days by always making the split that leaves
// the two sides purest, then predicts rain for the test days. Prints the tree
// in preorder: each node is either a split (feature and threshold) or a leaf
// (its prediction).
package main

import (
	"encoding/csv"
	"fmt"
	"os"
	"slices"
	"strconv"
)

var features = []string{"humidity", "pressure", "wind"}

const (
	maxDepth = 3
	minSize  = 5
)

type day struct {
	x    []float64
	rain string
}

// One struct serves for both kinds of node. A split has two children; a leaf
// has nil children and a label.
type node struct {
	feature     int
	threshold   float64
	left, right *node
	label       string
}

func (n *node) isLeaf() bool { return n.left == nil }

func read(path string) (train, test []day, err error) {
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
		d := day{rain: record[column["rain"]]}
		for _, name := range features {
			v, err := strconv.ParseFloat(record[column[name]], 64)
			if err != nil {
				return nil, nil, err
			}
			d.x = append(d.x, v)
		}
		if record[column["split"]] == "train" {
			train = append(train, d)
		} else {
			test = append(test, d)
		}
	}
	return train, test, nil
}

// gini is the chance that two days drawn at random (with replacement) disagree.
func gini(days []day) float64 {
	p := float64(countYes(days)) / float64(len(days))
	return 1 - p*p - (1-p)*(1-p)
}

func countYes(days []day) int {
	yes := 0
	for _, d := range days {
		if d.rain == "yes" {
			yes++
		}
	}
	return yes
}

// majority predicts "yes" only for a strict majority; an even split is "no".
func majority(days []day) string {
	if 2*countYes(days) > len(days) {
		return "yes"
	}
	return "no"
}

// partition splits days into those at or below the threshold and the rest.
func partition(days []day, f int, threshold float64) (left, right []day) {
	for _, d := range days {
		if d.x[f] <= threshold {
			left = append(left, d)
		} else {
			right = append(right, d)
		}
	}
	return left, right
}

// bestSplit returns the split with the lowest weighted Gini impurity. Features
// are tried in column order and thresholds from smallest to largest; only a
// strictly lower score replaces the best so far. found is false if no feature
// has two distinct values.
func bestSplit(days []day) (score float64, feature int, threshold float64, found bool) {
	n := float64(len(days))
	for f := range features {
		values := make([]float64, len(days))
		for i, d := range days {
			values[i] = d.x[f]
		}
		slices.Sort(values)
		values = slices.Compact(values) // drop repeats, leaving the distinct values
		for i := 1; i < len(values); i++ {
			t := (values[i-1] + values[i]) / 2
			left, right := partition(days, f, t)
			s := (float64(len(left))*gini(left) + float64(len(right))*gini(right)) / n
			if !found || s < score {
				score, feature, threshold, found = s, f, t, true
			}
		}
	}
	return score, feature, threshold, found
}

func grow(days []day, depth int) *node {
	g := gini(days)
	if g == 0 || len(days) < minSize || depth == maxDepth {
		return &node{label: majority(days)}
	}
	score, f, t, found := bestSplit(days)
	if !found || score >= g {
		return &node{label: majority(days)} // no split makes the sides purer
	}
	left, right := partition(days, f, t)
	return &node{feature: f, threshold: t, left: grow(left, depth+1), right: grow(right, depth+1)}
}

func predict(n *node, x []float64) string {
	for !n.isLeaf() {
		if x[n.feature] <= n.threshold {
			n = n.left
		} else {
			n = n.right
		}
	}
	return n.label
}

// preorder lists every node, parents before children, left before right.
func preorder(n *node) []*node {
	if n.isLeaf() {
		return []*node{n}
	}
	return append(append([]*node{n}, preorder(n.left)...), preorder(n.right)...)
}

func accuracy(tree *node, days []day) (correct int, share float64) {
	for _, d := range days {
		if predict(tree, d.x) == d.rain {
			correct++
		}
	}
	return correct, float64(correct) / float64(len(days))
}

func main() {
	train, test, err := read(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	tree := grow(train, 0)

	fmt.Printf("train_count %d\n", len(train))
	fmt.Printf("test_count %d\n", len(test))
	leaves := 0
	for i, n := range preorder(tree) {
		k := i + 1
		if n.isLeaf() {
			fmt.Printf("node_%d_predict %s\n", k, n.label)
			leaves++
		} else {
			fmt.Printf("node_%d_feature %s\n", k, features[n.feature])
			fmt.Printf("node_%d_threshold %.6f\n", k, n.threshold)
		}
	}
	fmt.Printf("leaves %d\n", leaves)

	_, trainAccuracy := accuracy(tree, train)
	correct, testAccuracy := accuracy(tree, test)
	fmt.Printf("train_accuracy %.6f\n", trainAccuracy)
	fmt.Printf("correct %d\n", correct)
	fmt.Printf("accuracy %.6f\n", testAccuracy)
}
