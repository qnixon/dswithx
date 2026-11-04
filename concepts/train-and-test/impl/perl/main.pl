# Train and test error for polynomials of degree 1 to 8, using only Perl and
# its core modules.
#
# Each polynomial is fitted by least squares to the training drives only: we
# build the normal equations and solve them by Gaussian elimination. Then we
# measure its root-mean-square error on the training drives and on the test
# drives it never saw. A matrix is an array of array refs: $m->[$i][$j] is
# row $i, column $j.
use strict;
use warnings;
use List::Util qw(sum min max);

my $MAX_DEGREE = 8;

# Returns two array refs of [speed, litres] pairs: the training drives and
# the test drives.
sub read_drives {
    my ($path) = @_;
    open my $fh, '<', $path or die "can't open $path: $!";
    chomp(my $header = <$fh>);
    my @names = split /,/, $header;
    my (@train, @test);
    while (my $line = <$fh>) {
        chomp $line;
        my %row;
        @row{@names} = split /,/, $line;     # a hash slice: names to fields
        my $point = [ $row{speed}, $row{litres} ];
        if ($row{split} eq 'train') { push @train, $point } else { push @test, $point }
    }
    close $fh;
    return (\@train, \@test);
}

# Solve a x = b by Gaussian elimination with partial pivoting. ($a and $b
# are reserved for sort, so the arguments are $lhs and $rhs.)
sub solve {
    my ($lhs, $rhs) = @_;
    my $n = @$rhs;    # an array in scalar context is its length
    # The augmented matrix: a copy of each row, with b's entry on the end.
    my @m = map { [ @{ $lhs->[$_] }, $rhs->[$_] ] } 0 .. $n - 1;
    for my $col (0 .. $n - 1) {
        # Swap up the row with the largest entry in this column, which keeps
        # the rounding error small. The rows are refs, so a slice assignment
        # swaps them without copying any numbers.
        my $pivot = $col;
        for my $r ($col + 1 .. $n - 1) {
            $pivot = $r if abs $m[$r][$col] > abs $m[$pivot][$col];
        }
        @m[$col, $pivot] = @m[$pivot, $col];
        for my $r ($col + 1 .. $n - 1) {
            my $factor = $m[$r][$col] / $m[$col][$col];
            $m[$r][$_] -= $factor * $m[$col][$_] for $col .. $n;
        }
    }
    # Back substitution, from the last unknown up.
    my @x = (0) x $n;
    for my $r (reverse 0 .. $n - 1) {
        my $total = $m[$r][$n];
        $total -= $m[$r][$_] * $x[$_] for $r + 1 .. $n - 1;
        $x[$r] = $total / $m[$r][$r];
    }
    return \@x;
}

# Least squares: the coefficients c solve (Z^T Z) c = Z^T y, where row i of
# Z is 1, z_i, z_i^2, ..., z_i^degree.
sub fit {
    my ($points, $degree, $scale) = @_;
    my @a = map { [ (0) x ($degree + 1) ] } 0 .. $degree;
    my @b = (0) x ($degree + 1);
    for my $p (@$points) {
        my ($x, $y) = @$p;
        my $z = $scale->($x);
        for my $i (0 .. $degree) {
            $b[$i] += $y * $z ** $i;
            $a[$i][$_] += $z ** ($i + $_) for 0 .. $degree;
        }
    }
    return solve(\@a, \@b);
}

sub rmse {
    my ($coefs, $points, $scale) = @_;
    my $total = 0;
    for my $p (@$points) {
        my ($x, $y) = @$p;
        my $z = $scale->($x);
        my $predicted = sum(map { $coefs->[$_] * $z ** $_ } 0 .. $#$coefs);
        $total += ($predicted - $y) ** 2;
    }
    return sqrt($total / @$points);
}

my ($train, $test) = read_drives($ARGV[0]);

# Map the training speeds onto -1 to 1. Raw speeds to the 16th power (the
# largest entry at degree 8) would swamp the small ones and make the
# equations hard to solve accurately.
my @speeds = map { $_->[0] } @$train;
my ($low, $high) = (min(@speeds), max(@speeds));
my ($mid, $half) = (($low + $high) / 2, ($high - $low) / 2);
my $scale = sub { ($_[0] - $mid) / $half };  # an anonymous sub, called as $scale->(x)

printf "train_count %d\n", scalar @$train;
printf "test_count %d\n", scalar @$test;
my (@train_errors, @test_errors);
for my $degree (1 .. $MAX_DEGREE) {
    my $coefs = fit($train, $degree, $scale);
    push @train_errors, rmse($coefs, $train, $scale);
    push @test_errors, rmse($coefs, $test, $scale);
}
printf "train_rmse_d%d %.6f\n", $_ + 1, $train_errors[$_] for 0 .. $#train_errors;
printf "test_rmse_d%d %.6f\n", $_ + 1, $test_errors[$_] for 0 .. $#test_errors;
