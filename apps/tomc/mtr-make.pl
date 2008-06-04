#!/usr/bin/perl

my %mtcount = qw{
    anopheles_gambiae 6b0867e842cc6d92923ad1c8f0a45034
    callithrix_jacchus 66515d4a08b76b4bbd2c6aae3e9133d8
    drosophila_melanogaster 11413bc5992582bd57821e99ffe45393
    canis_familiaris dab668284fb224c5ea9cbae67712becc
    gallus_gallus a8939f7c0a3e891deb31e4d8aa3d6e79
    homo_sapiens b08c1146cb407e99303b3c87795a3652
    mus_musculus .
    pan_troglodytes 3587e8e00e0275433deac8a916b3ab21
    takifugu_rubripes f0861ea4ad7ea2d5ae129002f47740cc
    xenopus_tropicalis fa10371ac4ecbc0d1898e946a3bfcc38
};

if (!-d $ARGV[0])
{
    die "usage: $0 output-directory\n";
}

my $mtrsum = $0;
$mtrsum =~ s{mtr-make.pl}{mtr-sum.pl};

for my $species (keys %mtcount)
{
    my $mtcount = $mtcount{$species};
    if ($mtcount ne '.')
    {
	my $mtrfile = $ARGV[0]. "/" . $species . ".txt";
	if (!-s $mtrfile)
	{
	    print STDERR "$mtrsum $mtcount > $mtrfile\n";
	    system "$mtrsum $mtcount > $mtrfile";
	    if ($? != 0)
	    {
		unlink $mtrfile;
		die "$mtrsum exit status $?\n";
	    }
	}
    }
}
