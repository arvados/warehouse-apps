#!perl
# -*- mode: perl; perl-indent-level: 4; -*-

use strict;
use warnings;
use Test::More tests => 7;
use Warehouse;
use Warehouse::Keep;
use Digest::MD5;

my $keeppid = fork();
if ($keeppid == 0)
{
    open STDOUT, ">/dev/null";
    my $daemon = new Warehouse::Keep (Directories => ["/nonexistent", "/tmp"],
				      ListenPort => 25168);
    $daemon->run;
    exit 0;
}

my $data = "0123456789abcdef0123456789abcdef";
my $hash = Digest::MD5::md5_hex ($data);

SKIP: {
	skip "warehouse client not configured on this machine", 7 if (! -f "/etc/warehouse/warehouse-client.conf");

	my $whc = new Warehouse (keeps => ["localhost:25168"]);

	my $storehash = $whc->store_block (\$data);
	ok ($storehash, "store_block")
    or diag ($whc->errstr);
	ok (substr ($storehash,0,32) eq $hash, "storehash eq $hash");

	my $keephash;
	ok (($keephash = $whc->store_in_keep (hash => $storehash)), "store_in_keep")
    or diag ($whc->errstr);

	diag ("keephash = $keephash");

	my $dataref;
	ok ($dataref = $whc->fetch_from_keep ($keephash), "fetch-$keephash")
    or diag ($whc->errstr);
	$dataref && ok ($$dataref eq $data, "fetch-$keephash eq stored");

	ok ($dataref = $whc->fetch_from_keep ($hash), "fetch-$hash")
    or diag ($whc->errstr);
	$dataref && ok ($$dataref eq $data, "fetch-$hash eq stored");

	my ($k, @probe) = $whc->_hash_keeps (0, $storehash);
	diag ("probe order for $storehash is @probe");

	($k, @probe) = $whc->_hash_keeps (0, $hash);
	diag ("probe order for $hash is @probe");

	diag ($whc->iostats);

}

kill 15, $keeppid;
wait;
