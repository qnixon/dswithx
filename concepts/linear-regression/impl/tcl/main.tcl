# Simple linear regression by least squares, using only Tcl's built-in
# commands.
#
# Fits score = intercept + slope * hours. Tcl has no regression or
# correlation command (Tcllib's math::statistics has one, but it isn't
# installed), so the sums are written out. expr does the arithmetic; its
# {braces} keep Tcl from substituting twice.

proc read_column {path name} {
    set f [open $path r]
    set header [split [gets $f] ,]
    set col [lsearch -exact $header $name]
    if {$col < 0} { error "column not found: $name" }
    set values {}
    while {[gets $f line] >= 0} {
        lappend values [lindex [split $line ,] $col]
    }
    close $f
    return $values
}

proc mean {values} {
    set total 0.0
    foreach v $values {
        set total [expr {$total + $v}]
    }
    return [expr {$total / [llength $values]}]
}

proc say {name value} {
    puts "$name [format %.6f $value]"
}

set path [lindex $argv 0]
set xs [read_column $path hours]
set ys [read_column $path score]

set n [llength $xs]
set mean_x [mean $xs]
set mean_y [mean $ys]

# Sums of squared deviations and of cross-products. foreach can walk two
# lists side by side: each pass takes the next x from xs and the next y
# from ys, so every hours value meets its own score.
set sxx 0.0
set syy 0.0
set sxy 0.0
foreach x $xs y $ys {
    set dx [expr {$x - $mean_x}]
    set dy [expr {$y - $mean_y}]
    set sxx [expr {$sxx + $dx * $dx}]
    set syy [expr {$syy + $dy * $dy}]
    set sxy [expr {$sxy + $dx * $dy}]
}

set slope [expr {$sxy / $sxx}]
set intercept [expr {$mean_y - $slope * $mean_x}]
set r [expr {$sxy / sqrt($sxx * $syy)}]

puts "count $n"
say slope $slope
say intercept $intercept
say r $r
say r_squared [expr {$r * $r}]
