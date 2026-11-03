# Simple linear regression by least squares, using only Perl and its core
# modules.
#
# Fits score = intercept + slope * hours. Perl has no regression or
# correlation function, so the sums are written out. List::Util, a core
# module, supplies sum.
use strict;
use warnings;
use List::Util qw(sum);

# Returns two array references, one per named column. \@xs is a reference:
# a single value that points at the array, so a sub can return several.
sub read_columns {
    my ($path, $x_name, $y_name) = @_;
    open my $fh, '<', $path or die "can't open $path: $!";
    chomp(my $header = <$fh>);
    my @fields = split /,/, $header;
    my %col = map { $fields[$_] => $_ } 0 .. $#fields;   # name -> position
    my (@xs, @ys);
    while (my $line = <$fh>) {
        chomp $line;
        my @row = split /,/, $line;
        push @xs, $row[ $col{$x_name} ];
        push @ys, $row[ $col{$y_name} ];
    }
    close $fh;
    return (\@xs, \@ys);
}

my ($xs, $ys) = read_columns($ARGV[0], 'hours', 'score');
my @xs = @$xs;                       # @$xs follows the reference to its array
my @ys = @$ys;

my $n = @xs;                         # an array used as a number is its length
my $mean_x = sum(@xs) / $n;
my $mean_y = sum(@ys) / $n;

# Sums of squared deviations and of cross-products. map runs its block once
# per item, with the item in $_; the cross-products walk the row numbers so
# each x stays paired with its y.
my $sxx = sum(map { ($_ - $mean_x) ** 2 } @xs);
my $syy = sum(map { ($_ - $mean_y) ** 2 } @ys);
my $sxy = sum(map { ($xs[$_] - $mean_x) * ($ys[$_] - $mean_y) } 0 .. $#xs);

my $slope = $sxy / $sxx;
my $intercept = $mean_y - $slope * $mean_x;
my $r = $sxy / sqrt($sxx * $syy);

print "count $n\n";
printf "slope %.6f\n", $slope;
printf "intercept %.6f\n", $intercept;
printf "r %.6f\n", $r;
printf "r_squared %.6f\n", $r * $r;
