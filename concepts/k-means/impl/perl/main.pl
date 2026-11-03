# k-means clustering (Lloyd's algorithm), using only Perl and its core
# modules.
#
# Starts from the first K points as centroids, then alternates two steps
# until no point changes cluster: assign each point to its nearest centroid,
# and move each centroid to the mean of its points.
use strict;
use warnings;
use List::Util qw(sum);

my $K = 3;
my $MAX_ITERATIONS = 100;

# Each point is a reference to a two-element array, [x, y]; $p->[0] is x.
sub read_points {
    my ($path) = @_;
    open my $fh, '<', $path or die "can't open $path: $!";
    chomp(my $header = <$fh>);
    my @fields = split /,/, $header;
    my ($ix) = grep { $fields[$_] eq 'x' } 0 .. $#fields;
    my ($iy) = grep { $fields[$_] eq 'y' } 0 .. $#fields;
    die "no x and y columns" unless defined $ix && defined $iy;
    my @points;
    while (my $line = <$fh>) {
        chomp $line;
        my @row = split /,/, $line;
        push @points, [$row[$ix], $row[$iy]];
    }
    close $fh;
    return @points;
}

sub squared_distance {
    my ($p, $q) = @_;
    return ($p->[0] - $q->[0]) ** 2 + ($p->[1] - $q->[1]) ** 2;
}

# Only a strictly smaller distance replaces the best, so ties go to the
# lower index.
sub nearest {
    my ($point, @centroids) = @_;
    my $best = 0;
    for my $j (1 .. $#centroids) {
        $best = $j
            if squared_distance($point, $centroids[$j])
             < squared_distance($point, $centroids[$best]);
    }
    return $best;
}

my @points = read_points($ARGV[0]);
# Copy the first K points so moving a centroid never changes a point.
my @centroids = map { [@$_] } @points[0 .. $K - 1];
my @assignment;
my $iterations = 0;

while ($iterations < $MAX_ITERATIONS) {
    $iterations++;
    my @new_assignment = map { nearest($_, @centroids) } @points;
    # Arrays have no ==, so join each into a string to compare them whole.
    last if "@new_assignment" eq "@assignment";   # this pass still counts
    @assignment = @new_assignment;
    for my $j (0 .. $K - 1) {
        my @members = map { $points[$_] }
                      grep { $assignment[$_] == $j } 0 .. $#points;
        next unless @members;   # an empty cluster keeps its old centroid
        $centroids[$j] = [
            sum(map { $_->[0] } @members) / @members,
            sum(map { $_->[1] } @members) / @members,
        ];
    }
}

my @sizes = map { my $j = $_; scalar grep { $_ == $j } @assignment } 0 .. $K - 1;
my $inertia = sum(map { squared_distance($points[$_], $centroids[$assignment[$_]]) }
                  0 .. $#points);

print "iterations $iterations\n";
for my $j (0 .. $K - 1) {
    printf "centroid_%d_x %.6f\n", $j + 1, $centroids[$j][0];
    printf "centroid_%d_y %.6f\n", $j + 1, $centroids[$j][1];
}
printf "size_%d %d\n", $_ + 1, $sizes[$_] for 0 .. $K - 1;
printf "inertia %.6f\n", $inertia;
