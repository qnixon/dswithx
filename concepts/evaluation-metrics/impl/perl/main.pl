# Evaluation metrics for a binary classifier, using only Perl and its core
# modules.
#
# Reads each part's true label and the model's score, then reports the
# confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
# the accuracy of never flagging anything, and the area under the ROC curve.
use strict;
use warnings;

# Returns a list of parts, each an array reference [defective, score].
sub read_parts {
    my ($path) = @_;
    open my $fh, '<', $path or die "can't open $path: $!";
    chomp(my $header = <$fh>);
    my @fields = split /,/, $header;
    my %col = map { $fields[$_] => $_ } 0 .. $#fields;   # name -> position
    my @parts;
    while (my $line = <$fh>) {
        chomp $line;
        my @row = split /,/, $line;
        # == compares as numbers, so "1" and "1.0" would both count.
        push @parts, [ $row[ $col{defective} ] == 1, $row[ $col{score} ] ];
    }
    close $fh;
    return @parts;
}

sub report {
    my ($parts, $suffix, $threshold) = @_;
    # A part is flagged when its score reaches the threshold.
    my ($tp, $fp, $fn, $tn) = (0, 0, 0, 0);
    for my $part (@$parts) {
        my ($defective, $score) = @$part;
        my $flagged = $score >= $threshold;
        if    ($flagged && $defective) { $tp++ }
        elsif ($flagged)               { $fp++ }
        elsif ($defective)             { $fn++ }
        else                           { $tn++ }
    }

    my $accuracy  = ($tp + $tn) / @$parts;
    my $precision = $tp / ($tp + $fp);   # of the flagged parts, how many are defective
    my $recall    = $tp / ($tp + $fn);   # of the defective parts, how many are flagged
    my $f1        = 2 * $precision * $recall / ($precision + $recall);

    print "tp_at_$suffix $tp\n";
    print "fp_at_$suffix $fp\n";
    print "fn_at_$suffix $fn\n";
    print "tn_at_$suffix $tn\n";
    printf "accuracy_at_%s %.6f\n",  $suffix, $accuracy;
    printf "precision_at_%s %.6f\n", $suffix, $precision;
    printf "recall_at_%s %.6f\n",    $suffix, $recall;
    printf "f1_at_%s %.6f\n",        $suffix, $f1;
}

# The chance that a random defective part outscores a random good one.
# Compare every pair, scoring 2 for a win and 1 for a tie, so the count
# stays a whole number until the final division. <=> returns 1, 0, or -1,
# so adding 1 gives 2 for a win, 1 for a tie, and 0 for a loss.
sub auc {
    my @parts     = @_;
    my @defective = map { $_->[1] } grep { $_->[0] } @parts;
    my @good      = map { $_->[1] } grep { !$_->[0] } @parts;
    my $points    = 0;
    for my $d (@defective) {
        $points += ($d <=> $_) + 1 for @good;
    }
    return $points / (2 * @defective * @good);
}

my @parts     = read_parts($ARGV[0]);
my $defective = grep { $_->[0] } @parts;   # grep in scalar context counts

print 'parts ', scalar @parts, "\n";
print "defective $defective\n";
# Never flagging anything is right about every good part.
printf "baseline_accuracy %.6f\n", (@parts - $defective) / @parts;
report(\@parts, '50', 0.5);
report(\@parts, '30', 0.3);
printf "auc %.6f\n", auc(@parts);
