// k-means clustering (Lloyd's algorithm), using only the standard library.
//
// Starts from the first K points as centroids, then alternates two steps until
// no point changes cluster: assign each point to its nearest centroid, and move
// each centroid to the mean of its points.
package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"slices"
	"strconv"
)

const (
	k             = 3
	maxIterations = 100
)

type point struct{ x, y float64 }

func readPoints(path string) ([]point, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	records, err := csv.NewReader(f).ReadAll()
	if err != nil {
		return nil, err
	}
	xi, yi := slices.Index(records[0], "x"), slices.Index(records[0], "y")
	if xi < 0 || yi < 0 {
		return nil, fmt.Errorf("need columns x and y")
	}

	points := make([]point, 0, len(records)-1)
	for _, record := range records[1:] {
		x, err := strconv.ParseFloat(record[xi], 64)
		if err != nil {
			return nil, err
		}
		y, err := strconv.ParseFloat(record[yi], 64)
		if err != nil {
			return nil, err
		}
		points = append(points, point{x, y})
	}
	return points, nil
}

func distance(a, b point) float64 {
	return math.Hypot(a.x-b.x, a.y-b.y)
}

// nearest returns the index of the closest centroid. The comparison is strict,
// so a tie goes to the lower index.
func nearest(p point, centroids []point) int {
	best := 0
	for j := 1; j < len(centroids); j++ {
		if distance(p, centroids[j]) < distance(p, centroids[best]) {
			best = j
		}
	}
	return best
}

func main() {
	points, err := readPoints(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	// Clone, so moving a centroid never overwrites one of the points.
	centroids := slices.Clone(points[:k])
	var assignment []int // nil until the first pass
	iterations := 0
	for iterations < maxIterations {
		iterations++
		newAssignment := make([]int, len(points))
		for i, p := range points {
			newAssignment[i] = nearest(p, centroids)
		}
		if slices.Equal(newAssignment, assignment) {
			break
		}
		assignment = newAssignment

		var sums [k]point
		var counts [k]int
		for i, p := range points {
			j := assignment[i]
			sums[j].x += p.x
			sums[j].y += p.y
			counts[j]++
		}
		for j := range k {
			if counts[j] > 0 { // an empty cluster keeps its old centroid
				n := float64(counts[j])
				centroids[j] = point{sums[j].x / n, sums[j].y / n}
			}
		}
	}

	var sizes [k]int
	inertia := 0.0
	for i, p := range points {
		j := assignment[i]
		sizes[j]++
		d := distance(p, centroids[j])
		inertia += d * d
	}

	fmt.Printf("iterations %d\n", iterations)
	for j, c := range centroids {
		fmt.Printf("centroid_%d_x %.6f\n", j+1, c.x)
		fmt.Printf("centroid_%d_y %.6f\n", j+1, c.y)
	}
	for j, size := range sizes {
		fmt.Printf("size_%d %d\n", j+1, size)
	}
	fmt.Printf("inertia %.6f\n", inertia)
}
