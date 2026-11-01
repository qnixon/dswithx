// Logistic regression by gradient descent, using only the standard library.
//
// Predicts whether a student passed from study hours and sleep. Each feature
// is rescaled with the training rows' mean and standard deviation, then the
// weights start at zero and take 1000 fixed steps of batch gradient descent
// on the average log-loss.
package main

import (
	"encoding/csv"
	"fmt"
	"math"
	"os"
	"strconv"
)

const (
	label        = "passed"
	learningRate = 0.5
	steps        = 1000
)

var features = []string{"hours", "sleep"}

type example struct {
	x []float64
	y float64
}

func read(path string) (train, test []example, err error) {
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
		var e example
		for _, name := range features {
			v, err := strconv.ParseFloat(record[column[name]], 64)
			if err != nil {
				return nil, nil, err
			}
			e.x = append(e.x, v)
		}
		if e.y, err = strconv.ParseFloat(record[column[label]], 64); err != nil {
			return nil, nil, err
		}
		if record[column["split"]] == "train" {
			train = append(train, e)
		} else {
			test = append(test, e)
		}
	}
	return train, test, nil
}

func sigmoid(z float64) float64 {
	return 1 / (1 + math.Exp(-z))
}

func dot(w, x []float64) float64 {
	total := 0.0
	for j := range w {
		total += w[j] * x[j]
	}
	return total
}

func main() {
	train, test, err := read(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	n := float64(len(train))

	// Scale each feature to mean 0 and (sample) standard deviation 1, using
	// the training rows only.
	means := make([]float64, len(features))
	sds := make([]float64, len(features))
	for j := range features {
		for _, e := range train {
			means[j] += e.x[j]
		}
		means[j] /= n
		for _, e := range train {
			d := e.x[j] - means[j]
			sds[j] += d * d
		}
		sds[j] = math.Sqrt(sds[j] / (n - 1))
	}
	// The leading 1 multiplies the intercept.
	scale := func(x []float64) []float64 {
		scaled := []float64{1}
		for j, v := range x {
			scaled = append(scaled, (v-means[j])/sds[j])
		}
		return scaled
	}
	xs := make([][]float64, len(train))
	for i, e := range train {
		xs[i] = scale(e.x)
	}

	weights := make([]float64, len(features)+1)
	for range steps {
		// Gradient of the average log-loss: the mean of (p - y) times each
		// input, computed in full before any weight changes.
		gradient := make([]float64, len(weights))
		for i, x := range xs {
			e := sigmoid(dot(weights, x)) - train[i].y
			for j := range gradient {
				gradient[j] += e * x[j]
			}
		}
		for j := range weights {
			weights[j] -= learningRate * gradient[j] / n
		}
	}

	logLoss := 0.0
	for i, x := range xs {
		p, y := sigmoid(dot(weights, x)), train[i].y
		logLoss -= y*math.Log(p) + (1-y)*math.Log(1-p)
	}
	logLoss /= n

	correct := 0
	for _, e := range test {
		predicted := 0.0
		if sigmoid(dot(weights, scale(e.x))) >= 0.5 {
			predicted = 1
		}
		if predicted == e.y {
			correct++
		}
	}

	fmt.Printf("train_count %d\n", len(train))
	fmt.Printf("test_count %d\n", len(test))
	fmt.Printf("intercept %.6f\n", weights[0])
	fmt.Printf("weight_hours %.6f\n", weights[1])
	fmt.Printf("weight_sleep %.6f\n", weights[2])
	fmt.Printf("log_loss %.6f\n", logLoss)
	fmt.Printf("correct %d\n", correct)
	fmt.Printf("accuracy %.6f\n", float64(correct)/float64(len(test)))
}
