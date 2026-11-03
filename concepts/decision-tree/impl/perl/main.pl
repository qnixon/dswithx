# A decision tree classifier (CART with Gini impurity), using only Perl and
# its core modules. Grows a tree on the training days by always making the
# split that leaves the two sides purest, then predicts rain for the test
# days. Prints the tree in preorder: each node is either a split (feature and
# threshold) or a leaf (its prediction).
use strict;
use warnings;

my @FEATURES = qw(humidity pressure wind);
my $MAX_DEPTH = 3;
my $MIN_SIZE = 5;

# Each day is a hash ref: { x => [humidity, pressure, wind], label => 'yes' }.
# Braces build an anonymous hash and brackets an anonymous array; -> reaches
# inside a reference.
sub read_days {
    my ($path) = @_;
    open my $fh, '<', $path or die "can't open $path: $!";
    chomp(my $header = <$fh>);
    my @names = split /,/, $header;
    my (@train, @test);
    while (my $line = <$fh>) {
        chomp $line;
        my %row;
        @row{@names} = split /,/, $line;    # a hash slice: many keys at once
        my $day = { x => [map { $row{$_} + 0 } @FEATURES], label => $row{rain} };
        push @{ $row{split} eq 'train' ? \@train : \@test }, $day;
    }
    close $fh;
    return (\@train, \@test);
}

# Chance that two days drawn at random (with replacement) disagree.
sub gini {
    my @labels = @_;
    my $p = (grep { $_ eq 'yes' } @labels) / @labels;   # grep counts matches
    return 1 - $p * $p - (1 - $p) * (1 - $p);
}

# An even split predicts "no".
sub majority {
    my @labels = @_;
    return (grep { $_ eq 'yes' } @labels) > @labels / 2 ? 'yes' : 'no';
}

# The [score, feature, threshold] with the lowest weighted Gini impurity.
# Features are tried in column order and thresholds from smallest to largest;
# only a strictly lower score replaces the best so far.
sub best_split {
    my @days = @_;
    my $best;
    for my $f (0 .. $#FEATURES) {
        # A hash's keys make a set of the distinct values; <=> sorts numbers.
        my %seen = map { $_->{x}[$f] => 1 } @days;
        my @values = sort { $a <=> $b } keys %seen;
        for my $i (0 .. $#values - 1) {
            my $threshold = ($values[$i] + $values[$i + 1]) / 2;
            my @left  = map { $_->{label} } grep { $_->{x}[$f] <= $threshold } @days;
            my @right = map { $_->{label} } grep { $_->{x}[$f] >  $threshold } @days;
            my $score = (@left * gini(@left) + @right * gini(@right)) / @days;
            $best = [$score, $f, $threshold] if !$best || $score < $best->[0];
        }
    }
    return $best;
}

# A leaf is { leaf => 'yes' }; a split is
# { feature => 0, threshold => 63.5, left => ..., right => ... }.
sub grow {
    my ($days, $depth) = @_;
    my @labels = map { $_->{label} } @$days;
    my $impurity = gini(@labels);
    if ($impurity == 0 || @$days < $MIN_SIZE || $depth == $MAX_DEPTH) {
        return { leaf => majority(@labels) };
    }
    my $split = best_split(@$days);
    # No split makes the sides purer.
    return { leaf => majority(@labels) } if !$split || $split->[0] >= $impurity;
    my (undef, $f, $threshold) = @$split;
    return {
        feature   => $f,
        threshold => $threshold,
        left      => grow([grep { $_->{x}[$f] <= $threshold } @$days], $depth + 1),
        right     => grow([grep { $_->{x}[$f] >  $threshold } @$days], $depth + 1),
    };
}

sub predict {
    my ($node, $x) = @_;
    until (exists $node->{leaf}) {
        $node = $x->[$node->{feature}] <= $node->{threshold}
            ? $node->{left} : $node->{right};
    }
    return $node->{leaf};
}

# Every node, parents before children, left subtree before right.
sub preorder {
    my ($node) = @_;
    return $node if exists $node->{leaf};
    return ($node, preorder($node->{left}), preorder($node->{right}));
}

my ($train, $test) = read_days($ARGV[0]);
my $tree = grow($train, 0);

printf "train_count %d\n", scalar @$train;
printf "test_count %d\n", scalar @$test;
my ($k, $leaves) = (0, 0);
for my $node (preorder($tree)) {
    $k++;
    if (exists $node->{leaf}) {
        print "node_${k}_predict $node->{leaf}\n";
        $leaves++;
    } else {
        print "node_${k}_feature $FEATURES[$node->{feature}]\n";
        printf "node_%d_threshold %.6f\n", $k, $node->{threshold};
    }
}
print "leaves $leaves\n";

my $train_correct = grep { predict($tree, $_->{x}) eq $_->{label} } @$train;
my $correct = grep { predict($tree, $_->{x}) eq $_->{label} } @$test;
printf "train_accuracy %.6f\n", $train_correct / @$train;
print "correct $correct\n";
printf "accuracy %.6f\n", $correct / @$test;
