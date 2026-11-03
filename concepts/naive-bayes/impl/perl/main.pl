# Categorical naive Bayes with add-one (Laplace) smoothing, using only Perl
# and its core modules.
#
# Learns P(label) and P(feature value | label) by counting training rows,
# then labels each test row with the label that has the highest
# log-probability.
use strict;
use warnings;

my @FEATURES = qw(has_link mentions_money known_sender);
my $LABEL = 'label';

# Each row becomes a hash reference keyed by column name.
sub read_rows {
    my ($path) = @_;
    open my $fh, '<', $path or die "can't open $path: $!";
    chomp(my $header = <$fh>);
    my @names = split /,/, $header;
    my @rows;
    while (my $line = <$fh>) {
        chomp $line;
        my %row;
        @row{@names} = split /,/, $line;   # a hash slice sets every column
        push @rows, \%row;
    }
    close $fh;
    return @rows;
}

my @rows = read_rows($ARGV[0]);
my @train = grep { $_->{split} eq 'train' } @rows;
my @test = grep { $_->{split} eq 'test' } @rows;

# Nested hashes spring into existence on first use (autovivification), so
# $count{$label}{$feature}{$value}++ needs no setup.
my (%label_count, %count, %seen);
for my $row (@train) {
    my $label = $row->{$LABEL};
    $label_count{$label}++;
    for my $f (@FEATURES) {
        $count{$label}{$f}{$row->{$f}}++;
        $seen{$f}{$row->{$f}} = 1;
    }
}
# keys of a hash used as a number is how many keys it has.
my %distinct = map { $_ => scalar keys %{ $seen{$_} } } @FEATURES;

sub log_score {
    my ($row, $label) = @_;
    # Logs turn the product of probabilities into a sum, avoiding underflow.
    my $score = log($label_count{$label} / @train);
    for my $f (@FEATURES) {
        # Add-one smoothing: an unseen value never gets probability zero.
        # // gives 0 when the count is undef, a value never seen with $label.
        my $n = ($count{$label}{$f}{$row->{$f}} // 0) + 1;
        $score += log($n / ($label_count{$label} + $distinct{$f}));
    }
    return $score;
}

# Hash order changes from run to run, so sort the labels, and only a
# strictly higher score wins: an exact tie goes to the alphabetically first.
sub classify {
    my ($row) = @_;
    my ($best, @rest) = sort keys %label_count;
    for my $label (@rest) {
        $best = $label if log_score($row, $label) > log_score($row, $best);
    }
    return $best;
}

my $correct = grep { classify($_) eq $_->{$LABEL} } @test;

printf "train_count %d\n", scalar @train;
printf "test_count %d\n", scalar @test;
print "correct $correct\n";
printf "accuracy %.6f\n", $correct / @test;
