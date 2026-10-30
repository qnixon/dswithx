Python makes the counting almost invisible. `csv.DictReader` gives each row
as a dictionary keyed by column name, and one `Counter` keyed by
`(feature, value, label)` tuples holds every count the model needs. Looking
up a key that was never counted returns 0, so the add-one smoothing works
for unseen combinations without any special case.

The tie rule comes nearly free. `max` returns the first maximum it meets, so
feeding it `sorted(label_counts)` sends an exact tie to the alphabetically
first label.

The standard library has no naive Bayes classifier, so here, unlike on some
pages, there was no built-in to skip.
