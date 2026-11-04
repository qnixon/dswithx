# 5-fold cross-validation for k-nearest neighbors, using only Perl and its
# core modules.
#
# Scores each odd k from 1 to 15 by holding out one fold of the training
# seeds at a time, picks the best k, and then scores that k once on the
# untouched test seeds.
use strict;
use warnings;

my $FOLDS = 5;
my @KS = grep { $_ % 2 } 1 .. 15;   # odd k only, so two varieties can't tie

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
    my ($point, $train, $k) = @_;

    # Pair each training seed's distance with its row number. The + marks
    # the braces as a new hash, not a block of code.
    my @scored = map {
        my $seed = $train->[$_];
        +{ d     => sqrt(($point->{len} - $seed->{len}) ** 2
                      + ($point->{wid} - $seed->{wid}) ** 2),
           row   => $_,
           label => $seed->{label} }
    } 0 .. $#$train;

    # When distances are equal, <=> returns 0, which is false, so || falls
    # through to the row number: equal distances keep the earlier seed.
    my @nearest = (sort { $a->{d} <=> $b->{d} || $a->{row} <=> $b->{row} }
                   @scored)[0 .. $k - 1];

    # Count votes in a hash keyed by label. ++ on a missing key starts it
    # at 0, with no warning. With two varieties and odd k, no vote ties.
    my (%votes, $best);
    for my $seed (@nearest) {
        my $label = $seed->{label};
        $votes{$label}++;
        $best = $label if !defined $best || $votes{$label} > $votes{$best};
    }
    return $best;
}

sub count_correct {
    my ($points, $train, $k) = @_;
    return scalar grep { classify($_, $train, $k) eq $_->{label} } @$points;
}

sub cv_accuracy {
    my ($train, $k) = @_;
    # Fold $f is rows $lo to $hi. The rows are already shuffled, so
    # consecutive blocks make fair folds. @$train[...] is an array slice:
    # it takes the rows at a list of positions, and 0 .. -1 is empty.
    my $size = int(@$train / $FOLDS);
    my $correct = 0;
    for my $f (0 .. $FOLDS - 1) {
        my ($lo, $hi) = ($f * $size, ($f + 1) * $size - 1);
        my @held_out = @$train[$lo .. $hi];
        my @rest     = @$train[0 .. $lo - 1, $hi + 1 .. $#$train];
        $correct += count_correct(\@held_out, \@rest, $k);
    }
    return $correct / @$train;
}

my ($train, $test) = read_seeds($ARGV[0]);

print 'train_count ', scalar @$train, "\n";
print 'test_count ', scalar @$test, "\n";
my ($best_k, $best_accuracy) = (undef, -1);
for my $k (@KS) {
    my $accuracy = cv_accuracy($train, $k);
    printf "cv_accuracy_k%d %.6f\n", $k, $accuracy;
    # Strictly better, so ties keep the smaller k.
    ($best_k, $best_accuracy) = ($k, $accuracy) if $accuracy > $best_accuracy;
}

# Only now touch the test seeds, once, with the chosen k and all of train.
my $correct = count_correct($test, $train, $best_k);
print "best_k $best_k\n";
print "test_correct $correct\n";
printf "test_accuracy %.6f\n", $correct / @$test;
