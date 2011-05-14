#!/usr/bin/perl
use strict;
use warnings;
#use diagnostics;

use lib "/usr/local/polony-tools/current/apps/jer/modules";
use WarehouseToolbox::RecoverJob;

#$|=1;

#for (1 .. 10) {
#	my $t = time;
#	test_keys("a75388fa4baca429d68806d0fe27a10a");	
#	print "attempt #$_: ".(time - $t)." seconds.\n";
#}
#print "done\n";

my %opts = map { $_ => 1 } map { /^--?(.+)/g } @ARGV;
my @inputs = grep { /^[^-]/ } @ARGV;

$opts{verbose} = 1 unless ($opts{q} or $opts{quiet});
$opts{debug} = 1 if $opts{d};
$opts{'match-first'} = 1 if $opts{m};
$opts{'json'} = 1;
$opts{'console'} = 1;


unless ($inputs[0]) {
	print <<HERE;
recoverjob - prints a list of missing original data hashes, and the easiest
route to re-creating missing hashes.

  Usage: recoverjob n [-q] [-d] [-m]
    Where 'n' represents a Warehouse job-ID or output hash-key
	Switches:
    -q or --quiet         suppress regular output
    -d or --debug         produce additional (often nonsensical) output
    -m or --match-first   return the first-discovered option, instead
                          of the best one
                          
HERE
	exit;
}

print recoverjob(@inputs, \%opts);

# job 15425 won't be fixed
# 12200 is broken
# 16068 is ok
# 15425 is not ok
# 16004 has issues
