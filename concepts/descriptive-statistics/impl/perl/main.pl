# Descriptive statistics on one CSV column, using only Perl and its core
# modules.
#
# Perl has no mean, median, or variance, so each is written out. List::Util,
# a core module, supplies sum. A name's first character, its sigil, says
# what it holds: $ a single value, @ an array, % a hash.
use strict;
use warnings;
use List::Util qw(sum);

sub read_column {
    my ($path, $name) = @_;
    open my $fh, '<', $path or die "can't open $path: $!";
    chomp(my $header = <$fh>);
    my @fields = split /,/, $header;
    my ($col) = grep { $fields[$_] eq $name } 0 .. $#fields;
    die "column not found: $name" unless defined $col;
    my @values;
    while (my $line = <$fh>) {
        chomp $line;
        push @values, (split /,/, $line)[$col];
    }
    close $fh;
    return @values;
}

sub median {
    my @sorted = @_;
    my $n = @sorted;                 # an array used as a number is its length
    my $mid = int($n / 2);
    return $sorted[$mid] if $n % 2 == 1;
    return ($sorted[$mid - 1] + $sorted[$mid]) / 2;
}

sub say_value {
    my ($name, $value) = @_;
    printf "%s %.6f\n", $name, $value;
}

# A plain sort compares text, putting 10 before 9, so <=> compares numbers.
my @values = sort { $a <=> $b } read_column($ARGV[0], 'minutes');

my $n = @values;
my $total = sum(@values);
my $mean = $total / $n;

# Sample variance divides by n - 1, not n (Bessel's correction).
my $sumsq = sum(map { ($_ - $mean) ** 2 } @values);
my $variance = $sumsq / ($n - 1);

my ($min, $max) = ($values[0], $values[-1]);

print "count $n\n";
say_value('sum', $total);
say_value('mean', $mean);
say_value('median', median(@values));
say_value('min', $min);
say_value('max', $max);
say_value('range', $max - $min);
say_value('variance', $variance);
say_value('std_dev', sqrt $variance);
