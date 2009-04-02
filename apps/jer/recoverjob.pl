#!/usr/bin/perl
use strict;
use warnings;
#use diagnostics;

use lib "/usr/local/polony-tools/current/apps/jer/modules";
use WarehouseToolbox::RecoverJob;

my %opts = map { $_ => 1 } map { /^--?(.+)/g } @ARGV;
my @inputs = grep { /^[^-]/ } @ARGV;

$opts{verbose} = 1 unless ($opts{q} or $opts{quiet});
$opts{debug} = 1 if $opts{d};
$opts{'match-first'} = 1 if $opts{m};
$opts{human} = 1 if $opts{h};
$opts{group} = 1 if $opts{g};
$opts{portable} = 1 if $opts{p};
$opts{json} = 1 if $opts{j};
$opts{batch} = 1 if $opts{b};


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
    -h or --human         human-friendly output
    -b or --batch         batch-style output for our robot masters
    -p or --portable      display results in "portable" format

HERE
	exit;
}

my $rv = recoverjob(@inputs, \%opts);
print $rv if ($rv && ($opts{json} || $opts{portable}));

# job 15425 won't be fixed
# 12200 is broken
# 16068 is ok
# 15425 is not ok
# 16004 has issues
