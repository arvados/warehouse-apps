#!/usr/bin/perl

$positionlist = shift @ARGV;
open POSITIONLIST, "<$positionlist" or die "Can't open $positionlist: $!";
scalar <POSITIONLIST>;

open STDOUT, "|tread" or die "tread: $!";

print q{#: taql-0.1/text
# field "frameno" "uint32"
# field "x" "dfloat"
# field "y" "dfloat"
# field "nreads" "uint32"
# field "ibytes" "uint32"
#.
};

while (defined ($_ = <POSITIONLIST>))
{
    chomp;
    my ($frameno, $x, $y) = split;

    $frameno = sprintf ("%04d", $frameno+1);

    my ($readcount);
    if (-e "align.reads.$frameno") {
	chomp ($readcount = `cat align.reads.$frameno | wc -l`);
    }
    elsif (-e "align.reads.$frameno.gz")
    {
	chomp ($readcount = `zcat align.reads.$frameno.gz | wc -l`);
    }
    else
    {
	die "Can't find align.reads.$frameno\{,.gz\}";
    }

    my ($imagesize);
    open STATS, "<align.reads.$frameno.stderr" or die "align.reads.$frameno.stderr: $!";
    $_ = <STATS>;
    while (/^srun:/ || /^\#/)
    {
	$_ = <STATS>;
    }
    if (/^Read (\d+) raw image/)
    {
	$imagesize = $1 * 2000000;
	$_ = <STATS>;
    }
    chomp;
    if ($_ =~ /^(\d+)$/) {
	$imagesize = $_;
    }
    if (!defined ($imagesize))
    {
	die "Can't understand line 2 of align.reads.$frameno.stderr";
    }

    print "$frameno $x $y $readcount $imagesize\n";
}

# arch-tag: Tom Clegg Thu Apr  5 15:27:06 PDT 2007 (align-call/framestats.pl)
