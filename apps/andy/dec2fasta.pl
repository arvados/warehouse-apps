#!/usr/bin/perl

my @acgt = qw(a c g t);
my $lastdec = -1;

while (<>)
{
    my $dec;
    s/^(\d+)/$dec = $1; dec2fasta($1);/e;
    while ($lastdec < $dec - 1)
    {
	++$lastdec;
	print (join ("\t", dec2fasta($lastdec), 0, 0, 0, 0), "\n");
    }
    if ($lastdec < $dec)
    {
	$lastdec = $dec;
	print;
    }
}
while ($lastdec < 255)
{
    ++$lastdec;
    print (join ("\t", dec2fasta($lastdec), 0, 0, 0, 0), "\n");
}

sub dec2fasta
{
    my $dec = shift;
    my $fasta = "";
    for my $shift (6,4,2,0)
    {
	$fasta .= $acgt[($dec >> $shift) & 3];
    }
    $fasta;
}
