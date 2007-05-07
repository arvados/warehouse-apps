#!/usr/bin/perl

$samplefile = shift @ARGV;
open (SAMPLES, "<$samplefile");

$biggapmin = shift @ARGV;
$biggapmax = shift @ARGV;
$genomesize = shift @ARGV;

fill_placed_sample_buf ();
$sample_id = -1;
while (defined ($_ = <SAMPLES>))
{
    chomp;
    my (@sample) = split;
    ++$sample_id;

    my (@s) = @sample;
    for (@s) { s/\"//g; }

    my (@orig) = @s[30,31];

    my ($placed_count) = 0;
    my (@placed);
    while ($placed_sample_id == $sample_id)
    {
	my (@p) = @placed_sample;

	my ($sample_id, $flags, $pos0, $pos1,
	    $mer0gap, $mer1gap, $mer0pre, $mer0ref, $mer1ref, $mer1suf, $mer0, $mer1,
	    $side, $snppos0, $snppos1)
	    = @p;

	my ($biggapsize) = $pos1 - $pos0 - 12 - length($mer0gap); # FIXME: might not be correct for side=1

	if (($side == -2)	# place-report couldn't place it: bug in mer-nfa? FIXME
	    ||
	    ($biggapsize < $biggapmin)
	    ||
	    ($biggapsize > $biggapmax))
	{
	    fill_placed_sample_buf ();
	    next;
	}

	++$placed_count;

	my ($bp7) = $mer0gap =~ /(.)$/;
	my ($bp20) = $mer1gap =~ /(.)$/;

	my ($refmer) = $mer0ref . $mer1ref;
	substr ($refmer, 6, 0) = $bp7;
	substr ($refmer, 19, 0) = $bp20;

	if ($side)
	{
	    # pretend we matched the sample against a reverse complement genome
	    $refmer = reverse $refmer;
	    $refmer =~ tr/ACGTacgt/TGCAtgca/;
	    if ($genomesize > 0)
	    {
		($pos0, $pos1) = ($genomesize - $pos1 - 12 - length($mer1gap),
				  $genomesize - $pos0 - 12 - length($mer0gap));
		($mer0gap, $mer1gap) = ($mer1gap, $mer0gap);
	    }
	}

	push (@placed,
	      join ("\t", @orig, uc($refmer), "@orig",
		    $pos0, $pos1,
		    12+length($mer0gap), 12+length($mer1gap),
		    ($side ? "-1" : "1"))
	      . "\n");
	fill_placed_sample_buf ();
    }
    if (@placed)
    {
	$N = scalar @placed;
	foreach (@placed)
	{
	    s/,/,$N/;
	}
	print @placed;
    }
    else
    {
	print (join ("\t", @orig, "NO_MATCH"), "\n");
    }
}

sub fill_placed_sample_buf
{
    do {
	if (!defined ($_ = <STDIN>))
	{
	    @placed_sample = ();
	    $placed_sample_id = -1;
	    return;
	}
    } until (!/^\#/);

    chomp;
    @placed_sample = split;
    $placed_sample_id = @placed_sample[0];
}

# arch-tag: Tom Clegg Sun Jan 28 03:31:34 PST 2007 (madeleine/nfa-report.pl)
