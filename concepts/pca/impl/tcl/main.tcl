# Principal component analysis by power iteration, using only Tcl's built-in
# commands.
#
# Standardizes the four scores, builds their correlation matrix, and finds
# the top two eigenvectors (the principal components): power iteration finds
# the first, then deflation removes it from the matrix so the same steps find
# the second. Tcl has no matrix type or eigen solver (Tcllib's
# math::linearalgebra has one, but it isn't installed), so a vector is a
# list and a matrix is a list of row lists. expr does the arithmetic; its
# {braces} keep Tcl from substituting twice.

set subjects {math physics reading writing}
set steps 1000

# Returns one list of numbers per row, in the order of the subjects.
proc read_rows {path subjects} {
    set f [open $path r]
    set header [split [gets $f] ,]
    set cols {}
    foreach name $subjects {
        set col [lsearch -exact $header $name]
        if {$col < 0} { error "column not found: $name" }
        lappend cols $col
    }
    set rows {}
    while {[gets $f line] >= 0} {
        set fields [split $line ,]
        lappend rows [lmap col $cols { lindex $fields $col }]
    }
    close $f
    return $rows
}

# foreach can walk two lists side by side, one item from each per pass.
proc dot {u v} {
    set total 0.0
    foreach a $u b $v {
        set total [expr {$total + $a * $b}]
    }
    return $total
}

# lmap builds a new list from what its body returns on each pass.
proc mat_vec {m v} {
    return [lmap row $m { dot $row $v }]
}

proc normalize {v} {
    set length [expr {sqrt([dot $v $v])}]
    return [lmap x $v { expr {$x / $length} }]
}

# Power iteration: multiply by the matrix and rescale, again and again.
# Returns the eigenvalue and the eigenvector as a two-element list.
proc top_eigenvector {m steps} {
    set v [lrepeat [llength $m] 0.0]
    lset v 0 1.0
    for {set i 0} {$i < $steps} {incr i} {
        set v [normalize [mat_vec $m $v]]
    }
    # An eigenvector can point either way; make its first entry positive.
    if {[lindex $v 0] < 0} {
        set v [lmap x $v { expr {-$x} }]
    }
    return [list [dot $v [mat_vec $m $v]] $v]
}

proc say {name value} {
    puts "$name [format %.6f $value]"
}

set rows [read_rows [lindex $argv 0] $subjects]
set n [llength $rows]
set k [llength $subjects]

# Standardize each column to mean 0 and (sample) standard deviation 1.
set means {}
set sds {}
for {set j 0} {$j < $k} {incr j} {
    set total 0.0
    foreach row $rows { set total [expr {$total + [lindex $row $j]}] }
    set mean [expr {$total / $n}]
    set sumsq 0.0
    foreach row $rows {
        set sumsq [expr {$sumsq + ([lindex $row $j] - $mean) ** 2}]
    }
    lappend means $mean
    lappend sds [expr {sqrt($sumsq / ($n - 1))}]
}
set z [lmap row $rows {
    lmap x $row m $means s $sds { expr {($x - $m) / $s} }
}]

# The correlation matrix: the covariance of the standardized columns.
set corr {}
for {set i 0} {$i < $k} {incr i} {
    set matrix_row {}
    for {set j 0} {$j < $k} {incr j} {
        set total 0.0
        foreach r $z {
            set total [expr {$total + [lindex $r $i] * [lindex $r $j]}]
        }
        lappend matrix_row [expr {$total / ($n - 1)}]
    }
    lappend corr $matrix_row
}

lassign [top_eigenvector $corr $steps] value_1 pc_1

# Deflation: subtract the first component's share, leaving the rest.
# lindex takes several indexes, so [lindex $corr $i $j] is row i, column j.
set deflated {}
for {set i 0} {$i < $k} {incr i} {
    set matrix_row {}
    for {set j 0} {$j < $k} {incr j} {
        lappend matrix_row [expr {[lindex $corr $i $j]
            - $value_1 * [lindex $pc_1 $i] * [lindex $pc_1 $j]}]
    }
    lappend deflated $matrix_row
}
lassign [top_eigenvector $deflated $steps] value_2 pc_2

puts "count $n"
foreach c {1 2} value [list $value_1 $value_2] pc [list $pc_1 $pc_2] {
    say eigenvalue_$c $value
    # Standardized columns each have variance 1, so the total is k.
    say explained_$c [expr {$value / $k}]
    foreach subject $subjects loading $pc {
        say pc${c}_$subject $loading
    }
}
say student_1_pc1 [dot [lindex $z 0] $pc_1]
say student_1_pc2 [dot [lindex $z 0] $pc_2]
