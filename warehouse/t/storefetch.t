#!perl

use strict;
use warnings;
use Test::More tests => 8;
use Warehouse;

my $content26 = "abcdefghijklmnopqrstuvwxyz";
my $content4M = "abcdefghijklmnop" x 262144;
my $content64M = "abcdefghijklmnop" x 4194304;
my $content128M = $content64M x 2;

SKIP: {
    skip "warehouse client not configured on this machine", 8 if (! -f "/etc/warehouse/warehouse-client.conf");
    my $whc = new Warehouse (debug_mogilefs_paths => 1);

    my $check;

    skip "something about 'perl -T' makes fetches hang", 8 if ${^TAINT};

    my $hash26 = $whc->store_block ($content26);
    ok ($hash26 =~ /^[a-f0-9]{32}/, "store-small");

    $check = $whc->fetch_block ($hash26);
    ok ($check eq $content26, "fetch-small");

    my $hash4M = $whc->store_block ($content4M);
    ok ($hash4M =~ /^[a-f0-9]{32}/, "store-4M");

    $check = $whc->fetch_block ($hash4M);
    ok ($check eq $content4M, "fetch-4M");

    my $hash64M = $whc->store_block ($content64M);
    ok ($hash64M =~ /^[a-f0-9]{32}/, "store-64M");

    $check = $whc->fetch_block ($hash64M);
    ok ($check eq $content64M, "fetch-64M");

    $whc->write_start;
    $whc->write_data ($content26);
    $whc->write_data ($content128M);
    $whc->write_data ($content64M);
    my @hashes = $whc->write_finish;
    ok (@hashes == 4, "write-192M")
	or diag ("write_finish returned qw(@hashes)");

    $check = "";
    map { $check .= $whc->fetch_block ($_) } @hashes;
    ok ($check eq $content26.$content128M.$content64M, "fetch-192M");

    print STDERR ("\n" . $whc->iostats);
};
