# Exact two-sided permutation test for a difference in means, using only
# Perl and its core modules.
#
# If compost made no difference, the "compost" and "control" labels are
# arbitrary, and any n of the plants could have carried the compost label.
# We try every one of those splits and count how many give a difference at
# least as large as the one we observed. That fraction is the p-value.
use strict;
use warnings;

# Returns a hash reference from group name to an array reference of grams.
sub read_groups {
    my ($path) = @_;
    open my $fh, '<', $path or die "can't open $path: $!";
    chomp(my $header = <$fh>);
    my @fields = split /,/, $header;
    my %col = map { $fields[$_] => $_ } 0 .. $#fields;   # name -> position
    my %groups = (control => [], compost => []);
    while (my $line = <$fh>) {
        chomp $line;
        my @row = split /,/, $line;
        push @{ $groups{ $row[ $col{group} ] } }, $row[ $col{grams} ];
    }
    close $fh;
    return \%groups;
}

sub sum {
    my $total = 0;
    $total += $_ for @_;
    return $total;
}

my $groups  = read_groups($ARGV[0]);
my @control = @{ $groups->{control} };
my @compost = @{ $groups->{compost} };
my $n       = @compost;               # an array in scalar context is its length
my @plants  = (@control, @compost);
my $total   = sum(@plants);

# Both groups have n plants, so comparing totals is the same as comparing
# means, and totals stay whole numbers: no floating-point near-ties.
my $observed = sum(@compost) - sum(@control);

# With N plants, every subset is a whole number from 0 to 2**N - 1 whose
# bits say which plants it holds: bit i set means plant i is chosen. We keep
# the numbers with exactly n bits set. sprintf '%b' writes the bits as a
# string of 0s and 1s, and tr/1// counts the 1s without changing anything.
my ($splits, $as_extreme) = (0, 0);
for my $mask (0 .. 2**@plants - 1) {
    next unless sprintf('%b', $mask) =~ tr/1// == $n;
    my $relabeled = sum(map { $plants[$_] } grep { ($mask >> $_) & 1 } 0 .. $#plants);
    $splits++;
    # Two-sided: abs counts a difference in either direction.
    $as_extreme++ if abs($relabeled - ($total - $relabeled)) >= abs($observed);
}

print 'control_count ', scalar @control, "\n";
print "compost_count $n\n";
printf "control_mean %.6f\n", sum(@control) / @control;
printf "compost_mean %.6f\n", sum(@compost) / $n;
printf "observed_difference %.6f\n", $observed / $n;
print "splits $splits\n";
print "as_extreme $as_extreme\n";
printf "p_value %.6f\n", $as_extreme / $splits;
