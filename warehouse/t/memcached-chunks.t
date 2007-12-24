#!perl

use strict;
use warnings;
use Test::More tests => 6*64*2;
use Warehouse;

my $whc = new Warehouse
    (memcached_size_threshold => $Warehouse::blocksize,
     mogilefs_size_threshold => $Warehouse::blocksize+1,
     debug_mogilefs_paths => 1);

my $check;

SKIP: {

    skip "something about 'perl -T' makes fetches hang", 6*64*2 if ${^TAINT};

    my @size;
    my @hash;
    for my $i (0..63)
    {
	my $content = "abcdefghijklmnop";
	for (6..19)
	{
	    $content = $content x 2;
	}
	for my $e (20..25)
	{
	    $content = $content x 2;
	    push @size, (length($content)+length($i));
	    push @hash, $whc->store_block ($content.$i);
	    ok ($hash[-1] =~ /^[a-f0-9]{32}$/, "store_2e${e}_${i}");
	}
    }

    for (@hash)
    {
	my $size = shift @size;
	ok ($whc->fetch_block ($_), "fetch_${size}_${_}");
    }

    print STDERR ("\n" . $whc->iostats);
};
