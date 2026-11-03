# Descriptive statistics on one CSV column, using only Tcl's built-in
# commands.
#
# Tcl has no mean, median, or variance (those live in Tcllib, which isn't
# installed), so each is written out. lsort sorts the values, and expr does
# the arithmetic; its {braces} keep Tcl from substituting twice.

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

proc median {sorted} {
    set n [llength $sorted]
    set mid [expr {$n / 2}]    ;# integer division, since both are integers
    if {$n % 2 == 1} {
        return [lindex $sorted $mid]
    }
    return [expr {([lindex $sorted $mid-1] + [lindex $sorted $mid]) / 2.0}]
}

proc say {name value} {
    puts "$name [format %.6f $value]"
}

# Every value is a string, so plain lsort would put 10 before 2; -real
# compares them as numbers.
set values [lsort -real [read_column [lindex $argv 0] minutes]]

set n [llength $values]
set total 0.0
foreach v $values {
    set total [expr {$total + $v}]
}
set mean [expr {$total / $n}]

# Sample variance divides by n - 1, not n (Bessel's correction).
set sumsq 0.0
foreach v $values {
    set sumsq [expr {$sumsq + ($v - $mean) ** 2}]
}
set variance [expr {$sumsq / ($n - 1)}]

set min [lindex $values 0]
set max [lindex $values end]

puts "count $n"
say sum $total
say mean $mean
say median [median $values]
say min $min
say max $max
say range [expr {$max - $min}]
say variance $variance
say std_dev [expr {sqrt($variance)}]
