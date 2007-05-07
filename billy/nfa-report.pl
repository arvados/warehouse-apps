#!/usr/bin/perl

$samplefile = shift @ARGV;
open (SAMPLES, "gprint < '$samplefile' |");

fill_placed_sample_buf ();
$sample_id = -1;
$report_sample_id = -1;
while (defined ($_ = <SAMPLES>))
{
    next if /^\#/;

    chomp;
    my (@sample) = split;
    ++$sample_id;
    ++$report_sample_id;

    my (@s) = @sample;
    for (@s) { s/\"//g; }

    my (@orig) = (">".$s[0].", start:".$s[1]." end:".$s[2]." ".$s[3].".".$s[4],
		  $s[5]."CG".$s[6]);

    my ($placed_count) = 0;
    my (@placed);
    my ($dont_report_this_sample_id) = 0;

    if (($s[5] =~ /N/)	# some of these can be placed, but we omit them to agree with previous output. FIXME
	||
	($s[6] =~ /N/))
    {
	$dont_report_this_sample_id = 1;
    }

    while ($placed_sample_id == $sample_id)
    {
	my (@p) = @placed_sample;

	if ($dont_report_this_sample_id
	    ||
	    ($p[13] == -2))	# place-report couldn't place it: bug in mer-nfa? FIXME
	{
	    fill_placed_sample_buf ();
	    next;
	}

	++$placed_count;

	my ($thegap) = $p[5] . $p[6];
	$thegap =~ s/\.//g;

	for ($p[7], $thegap, $p[10]) { tr/A-Z/a-z/; }
	for ($p[8], $p[9]) { tr/a-z/A-Z/; }

	my ($side) = $p[13];
	if ($side > 0)
	{
	    ($p[14], $p[15]) = ($p[15], $p[14]);
	    for (@p[14, 15])
	    {
		if ($_ >= 0)
		{
		    $_ = 11 - $_;
		}
	    }
	}

	my ($snppos) = "";
	if ($p[14] >= 0)
	{
	    $snppos = $p[14] - length($p[8]);
	}
	$snppos .= ",";
	if ($p[15] >= 0)
	{
	    $snppos .= "+" . (1 + $p[15]);
	}

	push (@placed, join ("\t", $report_sample_id+1, "YES,", $p[1].".".($p[3]+1),
			     length ($thegap) . ",".$p[7].",".$p[8].",".$thegap.",".$p[9].",".$p[10],
			     $snppos,
			     @orig) . "\n");
	fill_placed_sample_buf ();
    }
    if ($dont_report_this_sample_id)
    {
	--$report_sample_id;
    }
    elsif (@placed)
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
	print (join ("\t", $report_sample_id+1, "NO,0", "ERROR"),
	       "\n");
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

# arch-tag: Tom Clegg Thu Jan 25 02:33:29 PST 2007 (billy/nfa-report.pl)
