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
  foreach my $key (@$keys)
  {
    my $dataref = $mogc->get_file_data ($key);
    if ($dataref)
    {
      substr ($key, 100) = "";

      my $tarheader = "\0" x 512;
      substr ($tarheader, 0, length($key)) = $key;
      substr ($tarheader, 100, 7) = sprintf ("%07o", 0644); # mode
      substr ($tarheader, 108, 7) = sprintf ("%07o", 0); # uid
      substr ($tarheader, 116, 7) = sprintf ("%07o", 0); # gid
      substr ($tarheader, 124, 11) = sprintf ("%011o", length($$dataref));
      substr ($tarheader, 136, 11) = sprintf ("%011o", scalar time);
      substr ($tarheader, 148, 7) = sprintf ("%07o", tarchecksum($tarheader));
      print $tarheader;

      print $$dataref;
      my $pad = 512 - (length($$dataref) % 512);
      if ($pad != 512)
      {
	print "\0" x $pad;
      }
    }
  }
}
print "\0" x 1024;

sub tarchecksum
{
  my $sum = 0;
  for (@_)
  {
    for (my $i=0; $i<length; $i++)
    {
      $sum += ord(substr($_,$i,1));
    }
  }
  return $sum;
}

# arch-tag: 380ef2a7-5c3e-11dc-9207-0015f2b17887
