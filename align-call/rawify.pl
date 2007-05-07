#!/usr/bin/perl

use strict; 
use Fcntl ':flock';

my $localfs = 1;
my $fetchprogram;
my ($stem) = @ARGV;

if ($stem =~ s/^mogilefs:\/\///)
{
    $fetchprogram = "mogextract";
    $localfs = 0;
}
elsif ($stem =~ /:\/\//)
{
    $fetchprogram = "wget -q -O -";
    $localfs = 0;
}
else
{
    open (LOCKFILE, ">>imagelockfile") or die "imagelockfile: $!";
    flock (LOCKFILE, LOCK_EX);
    $fetchprogram = "cat";
}

for (1..4)
{
    if (!$localfs || (-e "$stem.raw"))
    {
	last if 0 == system ("$fetchprogram '$stem.raw'");
    }
    if (!$localfs || (-e "$stem.tif"))
    {
	last if 0 == system ("$fetchprogram '$stem.tif' | convert tif:- -endian lsb gray:-");
	if (($? >> 8) != 0 && ($? & 127) == 11)
	{
	    next;
	}
    }
    if (!$localfs || (-e "$stem.tif.gz"))
    {
	last if 0 == system ("$fetchprogram '$stem.tif.gz' | zcat | convert tif:- -endian lsb gray:-");
	if (($? >> 8) != 0 && ($? & 127) == 11)
	{
	    next;
	}
    }
    print STDERR "No raw/tif/tif.gz, skipping $stem\n";
    last;
}

# arch-tag: Tom Clegg Fri Mar 16 20:45:35 PDT 2007 (align-read/rawify.sh)
