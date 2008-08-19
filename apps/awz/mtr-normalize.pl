#!/usr/bin/perl

my $m = shift;
$" = "\t";

while(<>)
{
    chomp;
    if (/^(\d+)\t[\d\t]*$/)
    {
	next if $1 != $m;
	my @a = split /\t/;
	my $sum = 0;
	map { $sum += $a[$_] } (2..13);
	map { $a[$_] = sprintf "%.2f", $a[$_] * 100 / $sum } (2..13);
	print "@a\n";
    }
    elsif (/^m\s/)
    {
	my @a = split /\t/;
	print "@a\n";
    }
}
