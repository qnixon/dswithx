# A decision tree classifier (CART with Gini impurity), using only Tcl's
# built-in commands.
#
# Tcl has no decision tree (nor does Tcllib, which isn't installed anyway),
# so the split search, the growing, and the predicting are all written out.
# The tree is a nested list: a leaf is {leaf yes}, and a split is
# {split feature threshold LEFT RIGHT}, where LEFT and RIGHT are trees too.

set FEATURES {humidity pressure wind}
set MAX_DEPTH 3
set MIN_SIZE 5

# Each day is a two-item list: {humidity pressure wind} and its label.
proc read_days {path} {
    set f [open $path r]
    set header [split [gets $f] ,]
    set cols {}
    foreach name $::FEATURES {
        lappend cols [lsearch -exact $header $name]
    }
    set rain [lsearch -exact $header rain]
    set part [lsearch -exact $header split]
    set train {}
    set test {}
    while {[gets $f line] >= 0} {
        set row [split $line ,]
        set x {}
        foreach c $cols {
            lappend x [lindex $row $c]
        }
        if {[lindex $row $part] eq "train"} {
            lappend train [list $x [lindex $row $rain]]
        } else {
            lappend test [list $x [lindex $row $rain]]
        }
    }
    close $f
    return [list $train $test]
}

# Chance that two days drawn at random (with replacement) disagree.
proc gini {labels} {
    set p [expr {double([llength [lsearch -all -exact $labels yes]]) / [llength $labels]}]
    return [expr {1 - $p * $p - (1 - $p) * (1 - $p)}]
}

# An even split predicts "no".
proc majority {labels} {
    set yes [llength [lsearch -all -exact $labels yes]]
    return [expr {$yes > [llength $labels] / 2.0 ? "yes" : "no"}]
}

proc labels_of {days} {
    set labels {}
    foreach day $days {
        lappend labels [lindex $day 1]
    }
    return $labels
}

# The {score feature threshold} with the lowest weighted Gini impurity, or
# an empty list if no feature has two distinct values. Features are tried in
# column order and thresholds from smallest to largest; only a strictly
# lower score replaces the best so far.
proc best_split {days} {
    set best {}
    set n [llength $days]
    for {set f 0} {$f < [llength $::FEATURES]} {incr f} {
        set column {}
        foreach day $days {
            lappend column [lindex $day 0 $f]
        }
        set values [lsort -real -unique $column]
        for {set i 1} {$i < [llength $values]} {incr i} {
            # 2.0, not 2: humidity is whole numbers, and (63 + 64) / 2 would be 63.
            set threshold [expr {([lindex $values $i-1] + [lindex $values $i]) / 2.0}]
            set left {}
            set right {}
            foreach day $days {
                if {[lindex $day 0 $f] <= $threshold} {
                    lappend left [lindex $day 1]
                } else {
                    lappend right [lindex $day 1]
                }
            }
            set score [expr {([llength $left] * [gini $left]
                              + [llength $right] * [gini $right]) / $n}]
            if {$best eq {} || $score < [lindex $best 0]} {
                set best [list $score $f $threshold]
            }
        }
    }
    return $best
}

proc grow {days {depth 0}} {
    set labels [labels_of $days]
    set impurity [gini $labels]
    if {$impurity == 0 || [llength $days] < $::MIN_SIZE || $depth == $::MAX_DEPTH} {
        return [list leaf [majority $labels]]
    }
    set best [best_split $days]
    if {$best eq {} || [lindex $best 0] >= $impurity} {
        return [list leaf [majority $labels]]   ;# no split makes the sides purer
    }
    lassign $best score f threshold
    set left {}
    set right {}
    foreach day $days {
        if {[lindex $day 0 $f] <= $threshold} {
            lappend left $day
        } else {
            lappend right $day
        }
    }
    return [list split $f $threshold \
        [grow $left [expr {$depth + 1}]] [grow $right [expr {$depth + 1}]]]
}

proc predict {node x} {
    while {[lindex $node 0] eq "split"} {
        lassign $node - f threshold left right
        set node [expr {[lindex $x $f] <= $threshold ? $left : $right}]
    }
    return [lindex $node 1]
}

# Prints each node in preorder, numbering from k, and returns the next
# number. upvar lets the proc add to the caller's leaf count.
proc show {node k leavesVar} {
    upvar $leavesVar leaves
    if {[lindex $node 0] eq "leaf"} {
        puts "node_${k}_predict [lindex $node 1]"
        incr leaves
        return [expr {$k + 1}]
    }
    lassign $node - f threshold left right
    puts "node_${k}_feature [lindex $::FEATURES $f]"
    say node_${k}_threshold $threshold
    set k [show $left [expr {$k + 1}] leaves]
    return [show $right $k leaves]
}

proc count_correct {tree days} {
    set correct 0
    foreach day $days {
        lassign $day x label
        if {[predict $tree $x] eq $label} {
            incr correct
        }
    }
    return $correct
}

proc say {name value} {
    puts "$name [format %.6f $value]"
}

lassign [read_days [lindex $argv 0]] train test
set tree [grow $train]

puts "train_count [llength $train]"
puts "test_count [llength $test]"
set leaves 0
show $tree 1 leaves
puts "leaves $leaves"

set correct [count_correct $tree $test]
say train_accuracy [expr {double([count_correct $tree $train]) / [llength $train]}]
puts "correct $correct"
say accuracy [expr {double($correct) / [llength $test]}]
