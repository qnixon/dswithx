# k-nearest neighbors classification, using only Perl and its core modules.
#
# Each test seed is labelled with the majority variety among its K nearest
# training seeds, by Euclidean distance. Perl has no kNN or distance
# function, so both are written out.
use strict;
use warnings;

my $K = 5;

# Each seed becomes a hash reference, a small record:
# { len => 5.5, wid => 3.11, label => 'kama' }. $seed->{len} reads a field.
sub read_seeds {
    my ($path) = @_;
    open my $fh, '<', $path or die "can't open $path: $!";
    chomp(my $header = <$fh>);
    my @fields = split /,/, $header;
    my %col = map { $fields[$_] => $_ } 0 .. $#fields;   # name -> position
    my (@train, @test);
    while (my $line = <$fh>) {
        chomp $line;
        my @row = split /,/, $line;
        my $seed = {
            len   => $row[ $col{length_mm} ],
            wid   => $row[ $col{width_mm} ],
            label => $row[ $col{variety} ],
        };
        if ($row[ $col{split} ] eq 'train') { push @train, $seed }
        else                                { push @test,  $seed }
    }
    close $fh;
    return (\@train, \@test);
}

sub classify {
    my ($point, $train) = @_;

    # Pair each training seed's distance with its row number. The + marks
    # the braces as a new hash, not a block of code.
    my @scored = map {
        my $seed = $train->[$_];
        +{ d     => sqrt(($point->{len} - $seed->{len}) ** 2
                      + ($point->{wid} - $seed->{wid}) ** 2),
           row   => $_,
           label => $seed->{label} }
    } 0 .. $#$train;

    # <=> compares numbers and returns -1, 0, or 1. When distances are equal
    # it returns 0, which is false, so || falls through to the row number:
    # equal distances keep the earlier training seed. Perl's sort is stable
    # anyway, but the tie rule is now written in the code.
    my @nearest = (sort { $a->{d} <=> $b->{d} || $a->{row} <=> $b->{row} }
                   @scored)[0 .. $K - 1];

    # Count votes in a hash keyed by label. ++ on a missing key starts it
    # at 0, with no warning. With two varieties and odd K, no vote ties.
    my (%votes, $best);
    for my $seed (@nearest) {
        my $label = $seed->{label};
        $votes{$label}++;
        $best = $label if !defined $best || $votes{$label} > $votes{$best};
    }
    return $best;
}

my ($train, $test) = read_seeds($ARGV[0]);

my $correct = grep { classify($_, $train) eq $_->{label} } @$test;

print 'train_count ', scalar @$train, "\n";
print 'test_count ', scalar @$test, "\n";
print "correct $correct\n";
printf "accuracy %.6f\n", $correct / @$test;
