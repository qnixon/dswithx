# k-nearest neighbors classification, using only Tcl's built-in commands.
#
# Each test seed is labelled with the majority variety among its K nearest
# training seeds, by Euclidean distance. Tcl has no kNN or distance command,
# so both are written out. expr does the arithmetic; its {braces} keep Tcl
# from substituting twice.

set K 5

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

    # Count votes in a dict: dict incr starts a missing label at 0. A dict
    # keeps first-seen order, and > keeps the first maximum, so a tied vote
    # would go to the label seen first among the nearest.
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

lassign [read_seeds [lindex $argv 0]] train test

set correct 0
foreach seed $test {
    lassign $seed len wid label
    if {[classify $len $wid $train $K] eq $label} {
        incr correct
    }
}

puts "train_count [llength $train]"
puts "test_count [llength $test]"
puts "correct $correct"
puts "accuracy [format %.6f [expr {double($correct) / [llength $test]}]]"
