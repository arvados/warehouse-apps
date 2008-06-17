#!/usr/bin/perl

use strict;
use Warehouse;
use Warehouse::Manifest;
use Warehouse::Stream;

my @keys = qw(ac ag at ca cg ct ga gc gt ta tc tg empty_hits redundant_hits unique_hits unique_misses);
print (join ("\t", "m", "n", @keys), "\n");

my $whc = new Warehouse;
my $in = new Warehouse::Manifest (whc => $whc,
				  key => shift @ARGV);
my $want_m = shift @ARGV;

$in->rewind;
while (my $s = $in->subdir_next)
{
    if ($s->name =~ /m(\d+)n(\d+)/)
    {
	my ($m, $n) = ($1, $2);
	next if $m != $want_m;

	$s->rewind;
	while (my ($pos, $size, $filename) = $s->file_next)
	{
	    last if !defined $pos;
	    if ($filename eq "stats.txt")
	    {
		my %sum;
		$s->seek ($pos);
		while (my $dataref = $s->read_until ($pos+$size, "\n"))
		{
		    if ($$dataref =~ /^(.*)=(\d+)/)
		    {
			$sum{$1} = $2;
		    }
		}
		my $tot = 0;
		map { $tot += $sum{$_} } @keys[0..11];
		map { $sum{$_} = sprintf "%.2f", 100 * $sum{$_} / $tot } @keys[0..11] if $tot > 0;
		print (join ("\t", $m, $n, map { $sum{$_} + 0 } @keys), "\n");
	    }
	}
    }
}
