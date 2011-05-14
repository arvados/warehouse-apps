#!/usr/bin/perl

$maxsamples = $ARGV[0];
shift @ARGV;

$basename = $ARGV[0];
shift @ARGV;

$s = $maxsamples;
$f = 0;

while (<>)
{
    if ($s == $maxsamples) {
	$f = sprintf ("%04d", $f+1);
	open STDOUT, ">$basename$f" or die ("$basename$f: $!");
	$s = 0;
    }
    ++$s;
    print;
}

# arch-tag: Tom Clegg Tue Jan 30 23:31:43 PST 2007 (madeleine/samples-split.pl)
