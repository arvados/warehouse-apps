#!perl
# -*- mode: perl; perl-indent-level: 4; indent-tabs-mode: nil; -*-

use strict;
use warnings;
use Test::More tests => 6;
use Warehouse;
use Warehouse::Manifest;
use Digest::MD5;

SKIP: {
    skip "warehouse client not configured on this machine", 6 if (! -f "/etc/warehouse/warehouse-client.conf");
    skip "preparing to run a warehouse job", 6 if exists $ENV{"MR_JOB_ID"};

    my $whc = new Warehouse;

    my $check;

    #skip "something about 'perl -T' makes fetches hang", 8 if ${^TAINT};

    my $manifesttext = ". b739bca6df51d8c189de04e59571f09b+1666 0:1666:INSTALL\n"
	. "./subdir1 2da5e40fa3dbb2531da9713144d2070b-0 f0766d92a869fcaeb765c18ca9eabef9+38108802 0:1666:INSTALL 1666:105216000:slurm-1.2.19.tar\n";

    my $manifest = new Warehouse::Manifest (whc => $whc,
					    data => \$manifesttext);
    ok ($manifest, "create-from-text");

    my $key = $manifest->write;
    ok (defined $key, "write-text");

    ok ($key eq Digest::MD5::md5_hex ($manifesttext), "key-eq-md5");

    my $oldkey = $whc->fetch_manifest_key_by_name ("manifest.t");

    my $ok = $whc->store_manifest_by_name ($key, $oldkey, "manifest.t")
	or warn $whc->errstr;
    ok ($ok, "store-name");

    my $fetchkey = $whc->fetch_manifest_key_by_name ("manifest.t");
    ok (defined $fetchkey, "fetch");

    ok (defined $fetchkey && $fetchkey eq $key, "fetchkey-eq-$key");

    print STDERR ("\n" . $whc->iostats);
};
