# k-means clustering (Lloyd's algorithm), using only Tcl's built-in commands.
#
# Tcl has no clustering (nor any matrix or statistics package; those live in
# Tcllib, which isn't installed), so both steps are written out. Starting
# from the first K points as centroids, we assign each point to its nearest
# centroid, move each centroid to the mean of its points, and stop when no
# point changes cluster.

set K 3
set MAX_ITERATIONS 100

# Each point is a two-element list {x y}; lassign unpacks it.
proc read_points {path} {
    set f [open $path r]
    set header [split [gets $f] ,]
    set xcol [lsearch -exact $header x]
    set ycol [lsearch -exact $header y]
    set points {}
    while {[gets $f line] >= 0} {
        set fields [split $line ,]
        lappend points [list [lindex $fields $xcol] [lindex $fields $ycol]]
    }
    close $f
    return $points
}

proc distance {p q} {
    lassign $p px py
    lassign $q qx qy
    return [expr {hypot($px - $qx, $py - $qy)}]
}

# Returns the index of the nearest centroid. The test is strictly less
# than, so a tie keeps the lower index.
proc nearest {point centroids} {
    set best 0
    set best_dist [distance $point [lindex $centroids 0]]
    for {set j 1} {$j < [llength $centroids]} {incr j} {
        set d [distance $point [lindex $centroids $j]]
        if {$d < $best_dist} {
            set best $j
            set best_dist $d
        }
    }
    return $best
}

proc say {name value} {
    puts "$name [format %.6f $value]"
}

set points [read_points [lindex $argv 0]]
set centroids [lrange $points 0 $K-1]
set assignment {}
set iterations 0

while {$iterations < $MAX_ITERATIONS} {
    incr iterations
    set new_assignment {}
    foreach p $points {
        lappend new_assignment [nearest $p $centroids]
    }
    # A list is a string, so eq compares the whole assignment at once.
    if {$new_assignment eq $assignment} break
    set assignment $new_assignment

    for {set j 0} {$j < $K} {incr j} {
        set sx 0.0
        set sy 0.0
        set n 0
        # foreach can walk two lists side by side.
        foreach p $points a $assignment {
            if {$a == $j} {
                lassign $p x y
                set sx [expr {$sx + $x}]
                set sy [expr {$sy + $y}]
                incr n
            }
        }
        if {$n > 0} {    ;# an empty cluster keeps its old centroid
            lset centroids $j [list [expr {$sx / $n}] [expr {$sy / $n}]]
        }
    }
}

set inertia 0.0
foreach p $points a $assignment {
    set inertia [expr {$inertia + [distance $p [lindex $centroids $a]] ** 2}]
}

puts "iterations $iterations"
set j 0
foreach c $centroids {
    incr j
    lassign $c x y
    say centroid_${j}_x $x
    say centroid_${j}_y $y
}
for {set j 0} {$j < $K} {incr j} {
    # lsearch -all returns every matching index; count them.
    puts "size_[expr {$j + 1}] [llength [lsearch -all -exact $assignment $j]]"
}
say inertia $inertia
