We count with nested hashes: `$count{$label}{$f}{$value}++` creates each
missing level on first use, which Perl calls autovivification. A count
never seen reads as `undef`, and `// 0` turns that into zero before the
add-one smoothing.

Each row is a hash filled by a slice, `@row{@names} = split`, so the
columns are found by name. Hash order changes from run to run, so the
labels are sorted before scoring, and only a strictly higher score wins,
so a tie goes to the alphabetically first label. Perl has no classifier,
so there's nothing to skip.
