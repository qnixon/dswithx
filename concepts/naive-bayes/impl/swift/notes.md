Each count is keyed by a `CountKey` struct holding the feature, value, and
label. A dictionary key must be `Hashable`, and declaring it is enough:
Swift writes the hashing and `==` for us. `counts[key, default: 0] += 1`
starts a missing count at zero, and reading with `default: 0` covers pairs
the training data never saw.

A Swift dictionary has no sorted order, and its keys came out in a
different order on each run, so we sort the labels before scoring. Only a
strictly higher score replaces the best, so an exact tie goes to the
alphabetically first label. Swift has no naive Bayes classifier, so there
was no built-in to skip.
