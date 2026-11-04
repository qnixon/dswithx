# Train and test error for polynomials of degree 1 to 8, using only Tcl's
# built-in commands.
#
# Each polynomial is fitted by least squares to the training drives only: we
# build the normal equations and solve them by Gaussian elimination. Then we
# measure its root-mean-square error on the training drives and on the test
# drives it never saw. A matrix is a list of row lists; lindex reads an
# entry and lset writes one in place.

set max_degree 8

# Returns two lists of {speed litres} pairs: the training drives and the
# test drives.
proc read_drives {path} {
    set f [open $path r]
    set header [split [gets $f] ,]
    set speed_col [lsearch -exact $header speed]
    set litres_col [lsearch -exact $header litres]
    set split_col [lsearch -exact $header split]
    set train {}
    set test {}
    while {[gets $f line] >= 0} {
        set fields [split $line ,]
        set point [list [lindex $fields $speed_col] [lindex $fields $litres_col]]
        if {[lindex $fields $split_col] eq "train"} {
            lappend train $point
        } else {
            lappend test $point
        }
    }
    close $f
    return [list $train $test]
}

# Solve a x = b by Gaussian elimination with partial pivoting.
proc solve {a b} {
    set n [llength $b]
    # The augmented matrix: b becomes each row's last entry, column n.
    set m {}
    foreach row $a value $b {
        lappend m [concat $row $value]
    }
    for {set col 0} {$col < $n} {incr col} {
        # Swap up the row with the largest entry in this column, which keeps
        # the rounding error small.
        set pivot $col
        for {set r [expr {$col + 1}]} {$r < $n} {incr r} {
            if {abs([lindex $m $r $col]) > abs([lindex $m $pivot $col])} {
                set pivot $r
            }
        }
        set top [lindex $m $col]
        lset m $col [lindex $m $pivot]
        lset m $pivot $top
        for {set r [expr {$col + 1}]} {$r < $n} {incr r} {
            set factor [expr {[lindex $m $r $col] / [lindex $m $col $col]}]
            for {set c $col} {$c <= $n} {incr c} {
                lset m $r $c [expr {[lindex $m $r $c] - $factor * [lindex $m $col $c]}]
            }
        }
    }
    # Back substitution, from the last unknown up.
    set x [lrepeat $n 0.0]
    for {set r [expr {$n - 1}]} {$r >= 0} {incr r -1} {
        set total [lindex $m $r $n]
        for {set c [expr {$r + 1}]} {$c < $n} {incr c} {
            set total [expr {$total - [lindex $m $r $c] * [lindex $x $c]}]
        }
        lset x $r [expr {$total / [lindex $m $r $r]}]
    }
    return $x
}

# Least squares: the coefficients c solve (Z^T Z) c = Z^T y, where row i of
# Z is 1, z_i, z_i^2, ..., z_i^degree. zs and ys are the scaled speeds and
# the litres.
proc fit {zs ys degree} {
    set size [expr {$degree + 1}]
    set a [lrepeat $size [lrepeat $size 0.0]]
    set b [lrepeat $size 0.0]
    foreach z $zs y $ys {
        for {set i 0} {$i < $size} {incr i} {
            lset b $i [expr {[lindex $b $i] + $y * $z ** $i}]
            for {set j 0} {$j < $size} {incr j} {
                lset a $i $j [expr {[lindex $a $i $j] + $z ** ($i + $j)}]
            }
        }
    }
    return [solve $a $b]
}

proc rmse {coefs zs ys} {
    set total 0.0
    foreach z $zs y $ys {
        set predicted 0.0
        set i 0
        foreach c $coefs {
            set predicted [expr {$predicted + $c * $z ** $i}]
            incr i
        }
        set total [expr {$total + ($predicted - $y) ** 2}]
    }
    return [expr {sqrt($total / [llength $ys])}]
}

lassign [read_drives [lindex $argv 0]] train test

# Map the training speeds onto -1 to 1. Raw speeds to the 16th power (the
# largest entry at degree 8) would swamp the small ones and make the
# equations hard to solve accurately. The speeds are whole numbers, and
# dividing two integers would round down, so we divide by 2.0.
set train_speeds [lmap point $train { lindex $point 0 }]
set low [tcl::mathfunc::min {*}$train_speeds]
set high [tcl::mathfunc::max {*}$train_speeds]
set mid [expr {($low + $high) / 2.0}]
set half [expr {($high - $low) / 2.0}]

proc scaled_speeds {points mid half} {
    return [lmap point $points { expr {([lindex $point 0] - $mid) / $half} }]
}
proc litres {points} {
    return [lmap point $points { lindex $point 1 }]
}
set z_train [scaled_speeds $train $mid $half]
set z_test [scaled_speeds $test $mid $half]
set y_train [litres $train]
set y_test [litres $test]

puts "train_count [llength $train]"
puts "test_count [llength $test]"
set train_errors {}
set test_errors {}
for {set degree 1} {$degree <= $max_degree} {incr degree} {
    set coefs [fit $z_train $y_train $degree]
    lappend train_errors [rmse $coefs $z_train $y_train]
    lappend test_errors [rmse $coefs $z_test $y_test]
}
set degree 1
foreach e $train_errors {
    puts "train_rmse_d$degree [format %.6f $e]"
    incr degree
}
set degree 1
foreach e $test_errors {
    puts "test_rmse_d$degree [format %.6f $e]"
    incr degree
}
