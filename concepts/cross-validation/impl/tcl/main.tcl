# 5-fold cross-validation for k-nearest neighbors, using only Tcl's
# built-in commands.
#
# Splits the training seeds into 5 folds, scores each odd k from 1 to 15 by
# holding out one fold at a time, picks the k with the best average
# accuracy, and then scores that k once on the untouched test seeds. expr
# does the arithmetic; its {braces} keep Tcl from substituting twice.

set FOLDS 5

# Each seed becomes a three-item list: {length width variety}.
proc read_seeds {path} {
    set f [open $path r]
    set header [split [gets $f] ,]
    set cols {}
    foreach name {length_mm width_mm variety split} {
        set col [lsearch -exact $header $name]
        if {$col < 0} { error "column not found: $name" }
        lappend cols $col
    }
    set train {}
    set test {}
    while {[gets $f line] >= 0} {
        # lassign unpacks a list into separate variables.
        lassign [lmap col $cols {lindex [split $line ,] $col}] len wid label split
        if {$split eq "train"} {
            lappend train [list $len $wid $label]
        } else {
            lappend test [list $len $wid $label]
        }
    }
    close $f
    return [list $train $test]
}

proc classify {len wid train k} {
    # Pair each training seed's distance with its label, then sort on the
    # distance (-index 0) as a number (-real). lsort is stable, so equal
    # distances keep file order.
    set scored {}
    foreach seed $train {
        lassign $seed slen swid label
        set d [expr {sqrt(($len - $slen) ** 2 + ($wid - $swid) ** 2)}]
        lappend scored [list $d $label]
    }
    set nearest [lrange [lsort -real -index 0 $scored] 0 [expr {$k - 1}]]

    # Count votes in a dict: dict incr starts a missing label at 0. With two
    # varieties and odd k, no vote ties.
    set votes [dict create]
    foreach pair $nearest {
        dict incr votes [lindex $pair 1]
    }
    set best ""
    set best_count 0
    dict for {label count} $votes {
        if {$count > $best_count} {
            set best $label
            set best_count $count
        }
    }
    return $best
}

proc count_correct {points train k} {
    set correct 0
    foreach seed $points {
        lassign $seed len wid label
        if {[classify $len $wid $train $k] eq $label} {
            incr correct
        }
    }
    return $correct
}

proc cv_accuracy {train k} {
    # Fold f is items f*size to (f+1)*size - 1. The rows are already
    # shuffled, so consecutive blocks make fair folds. lrange takes first
    # and last indices, both included; concat joins the two pieces around
    # the held-out block.
    global FOLDS
    set size [expr {[llength $train] / $FOLDS}]
    set correct 0
    for {set f 0} {$f < $FOLDS} {incr f} {
        set lo [expr {$f * $size}]
        set hi [expr {$lo + $size - 1}]
        set held_out [lrange $train $lo $hi]
        set rest [concat [lrange $train 0 [expr {$lo - 1}]] \
                         [lrange $train [expr {$hi + 1}] end]]
        incr correct [count_correct $held_out $rest $k]
    }
    return [expr {double($correct) / [llength $train]}]
}

lassign [read_seeds [lindex $argv 0]] train test

puts "train_count [llength $train]"
puts "test_count [llength $test]"
set best_k 0
set best_accuracy -1.0
for {set k 1} {$k <= 15} {incr k 2} {
    set accuracy [cv_accuracy $train $k]
    puts "cv_accuracy_k$k [format %.6f $accuracy]"
    # Strictly better, so ties keep the smaller k.
    if {$accuracy > $best_accuracy} {
        set best_k $k
        set best_accuracy $accuracy
    }
}

# Only now touch the test seeds, once, with the chosen k and all of train.
set correct [count_correct $test $train $best_k]
puts "best_k $best_k"
puts "test_correct $correct"
puts "test_accuracy [format %.6f [expr {double($correct) / [llength $test]}]]"
