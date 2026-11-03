# Principal component analysis by power iteration, using only Perl and its
# core modules.
#
# Standardizes the four scores, builds their correlation matrix, and finds
# the top two eigenvectors (the principal components): power iteration finds
# the first, then deflation removes it from the matrix so the same steps find
# the second. Perl has no matrix type, so a vector is an array ref and a
# matrix is an array of array refs: $m->[$i][$j] is row $i, column $j.
use strict;
use warnings;
use List::Util qw(sum);

my @SUBJECTS = qw(math physics reading writing);
my $STEPS = 1000;

# Returns one array ref of numbers per row, in the order of the subjects.
sub read_rows {
    my ($path) = @_;
    open my $fh, '<', $path or die "can't open $path: $!";
    chomp(my $header = <$fh>);
    my @names = split /,/, $header;
    my @rows;
    while (my $line = <$fh>) {
        chomp $line;
        my %row;
        @row{@names} = split /,/, $line;     # a hash slice: names to fields
        push @rows, [ @row{@SUBJECTS} ];
    }
    close $fh;
    return @rows;
}

# $#$u is the last index of the array that $u refers to.
sub dot {
    my ($u, $v) = @_;
    return sum(map { $u->[$_] * $v->[$_] } 0 .. $#$u);
}

sub mat_vec {
    my ($m, $v) = @_;
    return [ map { dot($_, $v) } @$m ];
}

sub normalize {
    my ($v) = @_;
    my $length = sqrt dot($v, $v);
    return [ map { $_ / $length } @$v ];
}

# Power iteration: multiply by the matrix and rescale, STEPS times.
# Returns two values, the eigenvalue and the eigenvector.
sub top_eigenvector {
    my ($m) = @_;
    my $v = [ 1.0, (0.0) x $#$m ];       # x repeats a list
    $v = normalize(mat_vec($m, $v)) for 1 .. $STEPS;
    # An eigenvector can point either way; make its first entry positive.
    $v = [ map { -$_ } @$v ] if $v->[0] < 0;
    return (dot($v, mat_vec($m, $v)), $v);
}

my @rows = read_rows($ARGV[0]);
my ($n, $k) = (scalar @rows, scalar @SUBJECTS);

# Standardize each column to mean 0 and (sample) standard deviation 1.
my (@means, @sds);
for my $j (0 .. $k - 1) {
    my $mean = sum(map { $_->[$j] } @rows) / $n;
    push @means, $mean;
    push @sds, sqrt(sum(map { ($_->[$j] - $mean) ** 2 } @rows) / ($n - 1));
}
my @z = map {
    my $row = $_;
    [ map { ($row->[$_] - $means[$_]) / $sds[$_] } 0 .. $k - 1 ];
} @rows;

# The correlation matrix: the covariance of the standardized columns.
my @corr;
for my $i (0 .. $k - 1) {
    for my $j (0 .. $k - 1) {
        $corr[$i][$j] = sum(map { $_->[$i] * $_->[$j] } @z) / ($n - 1);
    }
}

my ($value_1, $pc_1) = top_eigenvector(\@corr);

# Deflation: subtract the first component's share, leaving the rest.
my @deflated;
for my $i (0 .. $k - 1) {
    for my $j (0 .. $k - 1) {
        $deflated[$i][$j] = $corr[$i][$j] - $value_1 * $pc_1->[$i] * $pc_1->[$j];
    }
}
my ($value_2, $pc_2) = top_eigenvector(\@deflated);

print "count $n\n";
my @results = ([ $value_1, $pc_1 ], [ $value_2, $pc_2 ]);
for my $c (1 .. 2) {
    my ($value, $pc) = @{ $results[$c - 1] };
    printf "eigenvalue_%d %.6f\n", $c, $value;
    # Standardized columns each have variance 1, so the total is k.
    printf "explained_%d %.6f\n", $c, $value / $k;
    printf "pc%d_%s %.6f\n", $c, $SUBJECTS[$_], $pc->[$_] for 0 .. $k - 1;
}
printf "student_1_pc1 %.6f\n", dot($z[0], $pc_1);
printf "student_1_pc2 %.6f\n", dot($z[0], $pc_2);
