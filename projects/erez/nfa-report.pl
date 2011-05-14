#!/usr/bin/perl

my $maxsnps = $ENV{'MAXSNPS'};
my $mersize = $ENV{'MERSIZE'};
my $last_id = -1;

while(<>)
{
    @r = split;

    my $inrec = shift @r;
    my $side = $inrec & 1;

    my $chr = shift @r;

    my $flags = shift @r;

    my $pos = shift @r;

    while ($r[0] ne ".") { shift @r; }
    while ($r[0] eq ".") { shift @r; }

    my $ref;
    shift @r;
    while ($r[0] =~ /^[ACGTN]/i)
    {
	$ref .= shift @r;
    }
    while ($r[0] eq ".") { shift @r; }

    my $id = shift @r;

    my $sample;
    my $mer0size = length ($r[0]);
    while ($r[0] =~ /^[ACGTN]/i)
    {
	$sample .= shift @r;
    }
    while ($r[0] eq ".") { shift @r; }

    shift @r;

    my $snppos0 = shift @r;
    my $snppos1 = $mer0size + shift @r;

    $sample = marksnps ($sample, $ref);

    my $eq = $sample =~ tr/acgt/acgt/;
    my $snps = length($sample)-$eq;

    if ($last_id != $id)
    {
	flush();
	$last_id = $id;
    }
    if ((!defined ($maxsnps) && ($snps <= 1+int(length($sample)/$mersize)))
	||
	($snps <= $maxsnps))
    {
	push (@placed, "$id $eq $snps $side $chr $pos $ref $sample\n");
    }
}
flush();

sub marksnps
{
    my ($a, $b) = (lc $_[0], lc $_[1]);
    for (my $x = 0; $x < length($a) && $x < length($b); ++$x)
    {
	if (substr($a,$x,1) ne substr($b,$x,1))
	{
	    substr($a,$x,1) = uc (substr ($a,$x,1));
	}
    }
    return $a;
}

sub flush
{
    if (@placed > 0)
    {
	my $c = scalar @placed;
	for (@placed)
	{
	    s/ / $c /;
	    print;
	}
    }
    @placed = ();
}

# arch-tag: Tom Clegg Thu Feb  1 01:53:56 PST 2007 (erez/nfa-report.pl)
