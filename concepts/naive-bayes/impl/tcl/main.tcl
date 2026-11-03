# Categorical naive Bayes with add-one (Laplace) smoothing, using only Tcl's
# built-in commands.
#
# Tcl has no classifier and no counting helper (Tcllib isn't installed), so
# we count training rows into dictionaries, then label each test row with the
# label that has the highest log-probability.

set FEATURES {has_link mentions_money known_sender}

# Returns the rows as a list of dicts, keyed by column name.
proc read_rows {path} {
    set f [open $path r]
    set header [split [gets $f] ,]
    set rows {}
    while {[gets $f line] >= 0} {
        set row {}
        foreach name $header value [split $line ,] {
            dict set row $name $value
        }
        lappend rows $row
    }
    close $f
    return $rows
}

# Reads a count, treating a key that was never seen as zero.
proc count_of {counts key} {
    if {[dict exists $counts $key]} {
        return [dict get $counts $key]
    }
    return 0
}

set train {}
set test {}
foreach row [read_rows [lindex $argv 0]] {
    if {[dict get $row split] eq "train"} {
        lappend train $row
    } else {
        lappend test $row
    }
}

# label_counts: label -> rows. value_counts: {feature value label} -> rows.
# A list is a string, so a three-element list works as one dict key.
# values_seen: feature -> dict of the distinct values it takes.
set label_counts {}
set value_counts {}
set values_seen {}
foreach row $train {
    set label [dict get $row label]
    dict incr label_counts $label
    foreach f $FEATURES {
        set v [dict get $row $f]
        dict incr value_counts [list $f $v $label]
        dict set values_seen $f $v 1
    }
}

proc log_score {row label} {
    global FEATURES train label_counts value_counts values_seen
    set n_label [dict get $label_counts $label]
    # Logs turn the product of probabilities into a sum, avoiding underflow.
    # The 1.0 matters: with two integers, / would round down to 0.
    set score [expr {log(1.0 * $n_label / [llength $train])}]
    foreach f $FEATURES {
        set key [list $f [dict get $row $f] $label]
        # Add-one smoothing: an unseen value never gets probability zero.
        set count [expr {[count_of $value_counts $key] + 1}]
        set distinct [dict size [dict get $values_seen $f]]
        set score [expr {$score + log(1.0 * $count / ($n_label + $distinct))}]
    }
    return $score
}

# Labels are tried in alphabetical order, and only a strictly higher score
# replaces the best, so an exact tie goes to the first.
proc classify {row} {
    global label_counts
    set best {}
    foreach label [lsort [dict keys $label_counts]] {
        set score [log_score $row $label]
        if {$best eq {} || $score > $best_score} {
            set best $label
            set best_score $score
        }
    }
    return $best
}

set correct 0
foreach row $test {
    if {[classify $row] eq [dict get $row label]} {
        incr correct
    }
}

puts "train_count [llength $train]"
puts "test_count [llength $test]"
puts "correct $correct"
puts "accuracy [format %.6f [expr {double($correct) / [llength $test]}]]"
