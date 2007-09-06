#!/usr/bin/perl

use strict;
use MogileFS::Client;
use Digest::MD5 'md5_hex';
use DBI;
use CGI ':standard';

my $q = new CGI;
print $q->header ('application/x-tar');

do '/etc/polony-tools/config.pl';

my $mogc;
for (qw(1 2 3 4 5))
{
    $mogc = eval {
	MogileFS::Client->new (domain => $main::mogilefs_default_domain,
			       hosts => [@main::mogilefs_trackers]);
      };
    last if $mogc;
}
die "$@" if !$mogc;

my $keyprefix = $q->param ("keyprefix");

my $after;
my $keys;
while (1)
{
  my @keylist = $mogc->list_keys ($keyprefix, $after);
  die "MogileFS::Client::list_keys() failed" if !@keylist;
  ($after, $keys) = @keylist;
  last if (!defined ($keys) || !@$keys);
  foreach (@$keys)
  {
    print "$_\n";
  }
}


# arch-tag: 380ef2a7-5c3e-11dc-9207-0015f2b17887
