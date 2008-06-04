#!/usr/bin/perl

while(<>)
{
    if (/^\d/)
    {
	my @a = split /\t/;
	my $sum = 0;
	map { $sum += $a[$_] } (2..$#a);
	map { $a[$_] = sprintf "%.2f", $a[$_] * 100 / $sum } (2..$#a);
	print (join ("\t", @a), "\n");
    }
    else
    {
	print;
    }
}
