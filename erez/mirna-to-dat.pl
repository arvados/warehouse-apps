#!/usr/bin/perl

open STDOUT, "|gread" or die "forking gread: $!";

$mercount = shift @ARGV;
$n_mers = shift @ARGV;



print q{#: taql-0.1/text
# field "id" "uint32"
};
for (0..$mercount-1)
{
    print qq{\# field "mer$_" "uint64"\n};
}
print qq{\#.\n};



while (<>)
{
    @a=split;
    $m=$a[1];
    if ($m !~ /[^ACGTN]/i)
    {
	for (0,1)
	{
	    if ($_)
	    {
		$m = reverse $m;
		$m =~ tr/acgtACGT/tgcaTGCA/;
	    }
	    print "$a[0]";
	    for (my $k = 0; $k < $mercount; ++$k)
	    {
		if ($k*$n_mers >= length($m))
		{
		    print " .";
		}
		else
		{
		    print " ".substr ($m, $k*$n_mers, $n_mers);
		}
	    }
	    print "\n";
	}
    }
}

# arch-tag: Wed Jan 31 00:53:28 PST 2007 (erez/mirna-to-dat.pl)
