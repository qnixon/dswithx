# Exact two-sided permutation test for a difference in means, using only
# Tcl's built-in commands.
#
# If compost made no difference, the "compost" and "control" labels are
# arbitrary, and any n of the plants could have carried the compost label.
# We try every one of those splits and count how many give a difference at
# least as large as the one we observed. That fraction is the p-value.

# Returns a dict from group name to the list of its grams.
proc read_groups {path} {
    set f [open $path r]
    set header [split [gets $f] ,]
    set group_col [lsearch -exact $header group]
    set grams_col [lsearch -exact $header grams]
    if {$group_col < 0 || $grams_col < 0} { error "column not found" }
    set groups [dict create control {} compost {}]
    while {[gets $f line] >= 0} {
        set fields [split $line ,]
        dict lappend groups [lindex $fields $group_col] [lindex $fields $grams_col]
    }
    close $f
    return $groups
}

proc sum {values} {
    set total 0
    foreach v $values { incr total $v }
    return $total
}

# Walk the plants from index next on, choosing left more of them to carry
# the compost label; chosen is the total of those picked so far. Each call
# either takes plant next or skips it, so every choice is reached once.
proc choose {next left chosen} {
    global plants total observed splits as_extreme
    if {$left == 0} {
        incr splits
        # Two-sided: abs counts a difference in either direction.
        if {abs($chosen - ($total - $chosen)) >= abs($observed)} {
            incr as_extreme
        }
        return
    }
    # Too few plants left to finish this choice.
    if {[llength $plants] - $next < $left} { return }
    choose [expr {$next + 1}] [expr {$left - 1}] \
           [expr {$chosen + [lindex $plants $next]}]
    choose [expr {$next + 1}] $left $chosen
}

set groups [read_groups [lindex $argv 0]]
set control [dict get $groups control]
set compost [dict get $groups compost]
set n [llength $compost]
set plants [concat $control $compost]
set total [sum $plants]

# Both groups have n plants, so comparing totals is the same as comparing
# means, and totals stay whole numbers: no floating-point near-ties.
set observed [expr {[sum $compost] - [sum $control]}]

set splits 0
set as_extreme 0
choose 0 $n 0

# double() makes / divide as a decimal; between two integers, / rounds down.
puts "control_count [llength $control]"
puts "compost_count $n"
puts "control_mean [format %.6f [expr {double([sum $control]) / [llength $control]}]]"
puts "compost_mean [format %.6f [expr {double([sum $compost]) / $n}]]"
puts "observed_difference [format %.6f [expr {double($observed) / $n}]]"
puts "splits $splits"
puts "as_extreme $as_extreme"
puts "p_value [format %.6f [expr {double($as_extreme) / $splits}]]"
