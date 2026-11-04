# Evaluation metrics for a binary classifier, using only Tcl's built-in
# commands.
#
# Reads each part's true label and the model's score, then reports the
# confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
# the accuracy of never flagging anything, and the area under the ROC curve.

# Returns a list of parts, each a two-element list {defective score}, where
# defective is 1 or 0.
proc read_parts {path} {
    set f [open $path r]
    set header [split [gets $f] ,]
    set defective_col [lsearch -exact $header defective]
    set score_col [lsearch -exact $header score]
    if {$defective_col < 0 || $score_col < 0} { error "column not found" }
    set parts {}
    while {[gets $f line] >= 0} {
        set fields [split $line ,]
        lappend parts [list [lindex $fields $defective_col] [lindex $fields $score_col]]
    }
    close $f
    return $parts
}

proc report {parts suffix threshold} {
    # A part is flagged when its score reaches the threshold.
    set tp 0; set fp 0; set fn 0; set tn 0
    foreach part $parts {
        lassign $part defective score
        set flagged [expr {$score >= $threshold}]
        if {$flagged && $defective} {
            incr tp
        } elseif {$flagged} {
            incr fp
        } elseif {$defective} {
            incr fn
        } else {
            incr tn
        }
    }

    # double() makes / divide as a decimal; between two integers, / rounds down.
    set accuracy [expr {double($tp + $tn) / [llength $parts]}]
    set precision [expr {double($tp) / ($tp + $fp)}]  ;# of the flagged parts, how many are defective
    set recall [expr {double($tp) / ($tp + $fn)}]     ;# of the defective parts, how many are flagged
    set f1 [expr {2 * $precision * $recall / ($precision + $recall)}]

    puts "tp_at_$suffix $tp"
    puts "fp_at_$suffix $fp"
    puts "fn_at_$suffix $fn"
    puts "tn_at_$suffix $tn"
    puts "accuracy_at_$suffix [format %.6f $accuracy]"
    puts "precision_at_$suffix [format %.6f $precision]"
    puts "recall_at_$suffix [format %.6f $recall]"
    puts "f1_at_$suffix [format %.6f $f1]"
}

# The chance that a random defective part outscores a random good one.
# Compare every pair, scoring 2 for a win and 1 for a tie, so the count
# stays a whole number until the final division.
proc auc {parts} {
    set defective {}
    set good {}
    foreach part $parts {
        lassign $part is_defective score
        if {$is_defective} { lappend defective $score } else { lappend good $score }
    }
    set points 0
    foreach d $defective {
        foreach g $good {
            if {$d > $g} {
                incr points 2
            } elseif {$d == $g} {
                incr points
            }
        }
    }
    return [expr {double($points) / (2 * [llength $defective] * [llength $good])}]
}

set parts [read_parts [lindex $argv 0]]
set n [llength $parts]
set defective 0
foreach part $parts { incr defective [lindex $part 0] }

puts "parts $n"
puts "defective $defective"
# Never flagging anything is right about every good part.
puts "baseline_accuracy [format %.6f [expr {double($n - $defective) / $n}]]"
report $parts 50 0.5
report $parts 30 0.3
puts "auc [format %.6f [auc $parts]]"
