// Exact two-sided permutation test for a difference in means, using only the
// standard library.
//
// If compost made no difference, the "compost" and "control" labels are
// arbitrary, and any 8 of the 16 plants could have carried the compost label.
// We try every one of those splits and count how many give a difference at
// least as large as the one we observed. That fraction is the p-value.
package main

import (
	"encoding/csv"
	"fmt"
	"os"
	"strconv"
)

func read(path string) (control, compost []int, err error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, nil, err
	}
	defer f.Close()

	records, err := csv.NewReader(f).ReadAll()
	if err != nil {
		return nil, nil, err
	}
	for _, record := range records[1:] { // skip the header
		grams, err := strconv.Atoi(record[1])
		if err != nil {
			return nil, nil, err
		}
		switch record[0] {
		case "control":
			control = append(control, grams)
		case "compost":
			compost = append(compost, grams)
		}
	}
	return control, compost, nil
}

func sum(xs []int) int {
	total := 0
	for _, x := range xs {
		total += x
	}
	return total
}

// abs for ints; math.Abs takes and returns float64.
func abs(x int) int {
	if x < 0 {
		return -x
	}
	return x
}

func main() {
	control, compost, err := read(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	n := len(compost)
	plants := append(append([]int{}, control...), compost...)
	total := sum(plants)

	// Both groups have n plants, so comparing totals is the same as comparing
	// means, and totals stay whole numbers: no floating-point near-ties.
	observed := sum(compost) - sum(control)

	splits, asExtreme := 0, 0

	// choose walks every way to pick `left` more plants from positions start
	// onward, carrying the running total of the plants picked so far. A
	// recursive closure must be declared before it is assigned.
	var choose func(start, left, chosenTotal int)
	choose = func(start, left, chosenTotal int) {
		if left == 0 {
			difference := chosenTotal - (total - chosenTotal)
			splits++
			if abs(difference) >= abs(observed) { // two-sided
				asExtreme++
			}
			return
		}
		// Stop early enough that `left` plants still remain to pick.
		for i := start; i <= len(plants)-left; i++ {
			choose(i+1, left-1, chosenTotal+plants[i])
		}
	}
	choose(0, n, 0)

	fmt.Printf("control_count %d\n", len(control))
	fmt.Printf("compost_count %d\n", n)
	fmt.Printf("control_mean %.6f\n", float64(sum(control))/float64(len(control)))
	fmt.Printf("compost_mean %.6f\n", float64(sum(compost))/float64(n))
	fmt.Printf("observed_difference %.6f\n", float64(observed)/float64(n))
	fmt.Printf("splits %d\n", splits)
	fmt.Printf("as_extreme %d\n", asExtreme)
	fmt.Printf("p_value %.6f\n", float64(asExtreme)/float64(splits))
}
