# Logistic regression by gradient descent, using only Perl and its core
# modules.
#
# Predicts whether a student passed from study hours and sleep. Each feature
# is rescaled with the training rows' mean and standard deviation, then the
# weights start at zero and take STEPS fixed steps of batch gradient descent
# on the average log-loss. List::Util, a core module, supplies sum.
use strict;
use warnings;
use List::Util qw(sum);

my @FEATURES = qw(hours sleep);
my $LEARNING_RATE = 0.5;
my $STEPS = 1000;

# Returns two array refs, train and test. Each example is a hash ref,
# { x => [hours, sleep], y => passed }; [...] and {...} build references.
sub read_examples {
    my ($path) = @_;
    open my $fh, '<', $path or die "can't open $path: $!";
    chomp(my $header = <$fh>);
    my @names = split /,/, $header;
    my (@train, @test);
    while (my $line = <$fh>) {
        chomp $line;
        my %row;
        @row{@names} = split /,/, $line;     # a hash slice: names to fields
        my $example = { x => [ @row{@FEATURES} ], y => $row{passed} };
        push @{ $row{split} eq 'train' ? \@train : \@test }, $example;
    }
    close $fh;
    return (\@train, \@test);
}

sub sigmoid { return 1 / (1 + exp(-$_[0])) }

# The dot product of two array refs; $#$u is the last index of @$u.
sub dot {
    my ($u, $v) = @_;
    return sum(map { $u->[$_] * $v->[$_] } 0 .. $#$u);
}

my ($train, $test) = read_examples($ARGV[0]);
my $n = @$train;

# Scale each feature to mean 0 and (sample) standard deviation 1, using the
# training rows only.
my (@means, @sds);
for my $j (0 .. $#FEATURES) {
    my @column = map { $_->{x}[$j] } @$train;
    my $mean = sum(@column) / $n;
    push @means, $mean;
    push @sds, sqrt(sum(map { ($_ - $mean) ** 2 } @column) / ($n - 1));
}

# The leading 1 multiplies the intercept.
sub scale {
    my ($x) = @_;
    return [ 1.0, map { ($x->[$_] - $means[$_]) / $sds[$_] } 0 .. $#$x ];
}

my @xs = map { scale($_->{x}) } @$train;
my @ys = map { $_->{y} } @$train;
my @weights = (0.0) x @{ $xs[0] };       # x repeats a list: three zeros

for (1 .. $STEPS) {
    # Gradient of the average log-loss: the mean of (p - y) times each input.
    my @errors = map { sigmoid(dot(\@weights, $xs[$_])) - $ys[$_] } 0 .. $n - 1;
    my @gradient = map {
        my $j = $_;
        sum(map { $errors[$_] * $xs[$_][$j] } 0 .. $n - 1) / $n;
    } 0 .. $#weights;
    @weights = map { $weights[$_] - $LEARNING_RATE * $gradient[$_] } 0 .. $#weights;
}

my @p = map { sigmoid(dot(\@weights, $_)) } @xs;
my $log_loss = -sum(map {
    $ys[$_] * log($p[$_]) + (1 - $ys[$_]) * log(1 - $p[$_])
} 0 .. $n - 1) / $n;

# grep keeps the test examples predicted right; assigned to a single value,
# it gives their count.
my $correct = grep {
    (sigmoid(dot(\@weights, scale($_->{x}))) >= 0.5 ? 1 : 0) == $_->{y}
} @$test;

printf "train_count %d\n", $n;
printf "test_count %d\n", scalar @$test;
printf "intercept %.6f\n", $weights[0];
printf "weight_hours %.6f\n", $weights[1];
printf "weight_sleep %.6f\n", $weights[2];
printf "log_loss %.6f\n", $log_loss;
printf "correct %d\n", $correct;
printf "accuracy %.6f\n", $correct / @$test;
