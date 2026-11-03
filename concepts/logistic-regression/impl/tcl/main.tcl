# Logistic regression by gradient descent, using only Tcl's built-in
# commands.
#
# Predicts whether a student passed from study hours and sleep. Tcl has no
# regression or classifier, so every step is written out. Each feature is
# rescaled with the training rows' mean and standard deviation, then the
# weights start at zero and take 1000 fixed steps of batch gradient descent
# on the average log-loss. expr does the arithmetic; its {braces} keep Tcl
# from substituting twice.

set features {hours sleep}
set learning_rate 0.5
set steps 1000

# Returns two lists, train and test. Each example in them is a two-element
# list: the feature values, then the 0/1 label.
proc read_examples {path features} {
    set f [open $path r]
    set header [split [gets $f] ,]
    set cols {}
    foreach name [concat $features passed split] {
        set col [lsearch -exact $header $name]
        if {$col < 0} { error "column not found: $name" }
        lappend cols $col
    }
    set train {}
    set test {}
    while {[gets $f line] >= 0} {
        set fields [split $line ,]
        set x {}
        foreach col [lrange $cols 0 end-2] {
            lappend x [lindex $fields $col]
        }
        set example [list $x [lindex $fields [lindex $cols end-1]]]
        if {[lindex $fields [lindex $cols end]] eq "train"} {
            lappend train $example
        } else {
            lappend test $example
        }
    }
    close $f
    return [list $train $test]
}

proc sigmoid {z} {
    return [expr {1.0 / (1.0 + exp(-$z))}]
}

# foreach can walk two lists side by side, one item from each per pass.
proc dot {u v} {
    set total 0.0
    foreach a $u b $v {
        set total [expr {$total + $a * $b}]
    }
    return $total
}

proc say {name value} {
    puts "$name [format %.6f $value]"
}

# lassign unpacks a list into separate variables.
lassign [read_examples [lindex $argv 0] $features] train test
set n [llength $train]

# Scale each feature to mean 0 and (sample) standard deviation 1, using the
# training rows only. lmap builds a new list from what its body returns.
set means {}
set sds {}
for {set j 0} {$j < [llength $features]} {incr j} {
    set column [lmap example $train { lindex $example 0 $j }]
    set total 0.0
    foreach v $column { set total [expr {$total + $v}] }
    set mean [expr {$total / $n}]
    set sumsq 0.0
    foreach v $column { set sumsq [expr {$sumsq + ($v - $mean) ** 2}] }
    lappend means $mean
    lappend sds [expr {sqrt($sumsq / ($n - 1))}]
}

# The leading 1.0 multiplies the intercept.
proc scale {x means sds} {
    set scaled {1.0}
    foreach v $x m $means s $sds {
        lappend scaled [expr {($v - $m) / $s}]
    }
    return $scaled
}

set xs [lmap example $train { scale [lindex $example 0] $means $sds }]
set ys [lmap example $train { lindex $example 1 }]

set weights {0.0 0.0 0.0}
for {set step 0} {$step < $steps} {incr step} {
    # Gradient of the average log-loss: the mean of (p - y) times each input.
    set gradient {0.0 0.0 0.0}
    foreach x $xs y $ys {
        set error [expr {[sigmoid [dot $weights $x]] - $y}]
        set gradient [lmap g $gradient v $x { expr {$g + $error * $v} }]
    }
    # Build the new weights from the old ones, so every weight moves by the
    # same gradient.
    set weights [lmap w $weights g $gradient {
        expr {$w - $learning_rate * $g / $n}
    }]
}

set loss 0.0
foreach x $xs y $ys {
    set p [sigmoid [dot $weights $x]]
    set loss [expr {$loss - ($y * log($p) + (1 - $y) * log(1 - $p))}]
}

set correct 0
foreach example $test {
    lassign $example x y
    set p [sigmoid [dot $weights [scale $x $means $sds]]]
    set predicted [expr {$p >= 0.5 ? 1 : 0}]
    if {$predicted == $y} { incr correct }
}

puts "train_count $n"
puts "test_count [llength $test]"
say intercept [lindex $weights 0]
say weight_hours [lindex $weights 1]
say weight_sleep [lindex $weights 2]
say log_loss [expr {$loss / $n}]
puts "correct $correct"
say accuracy [expr {double($correct) / [llength $test]}]
