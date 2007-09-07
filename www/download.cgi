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

# when preparing the tar to send to the client, we will remove
# everything up to the last slash.  So, if warehouse has /foo/bar/baz
# then:
# 
# client requests /foo/bar  tar will contain bar/baz unless /bar/baz in exclude
# client requests /foo/bar/ tar will contain baz     unless /baz     in exclude
# client requests /         tar will contain foo/... unless /foo/... in exclude
# client requests           tar will contain foo/... unless /foo/... in exclude

my $keyprefix_to_remove = $keyprefix;
$keyprefix_to_remove =~ s/[^\/]*$//;

my $exclude_fh = $q->upload ("exclude");
my @exclude = sort <$exclude_fh>;
chomp @exclude;

my $totalbytes = 0;
my $after;
my $keys;
while (1)
{
  my @keylist = $mogc->list_keys ($keyprefix, $after);
  die "MogileFS::Client::list_keys() failed" if !@keylist;
  ($after, $keys) = @keylist;
  last if (!defined ($keys) || !@$keys);
  my $ei = 0;
  foreach my $mogkey (@$keys)
  {
    my $tarkey = $mogkey;
    substr($tarkey, 0, length($keyprefix_to_remove)) = "";

    while ($ei <= $#exclude && $exclude[$ei] lt "/$tarkey")
    {
      ++$ei;
    }
    if ($ei <= $#exclude && $exclude[$ei] eq "/$tarkey")
    {
      ++$ei;
      next;
    }
    my $dataref = $mogc->get_file_data ($mogkey);
    if ($dataref)
    {
      if (length($tarkey) > 99)
      {
	substr ($tarkey, 99) = "";
      }

      my $tarheader = "\0" x 512;
      substr ($tarheader, 0, length($tarkey)) = $tarkey;
      substr ($tarheader, 100, 7) = sprintf ("%07o", 0644); # mode
      substr ($tarheader, 108, 7) = sprintf ("%07o", 0); # uid
      substr ($tarheader, 116, 7) = sprintf ("%07o", 0); # gid
      substr ($tarheader, 124, 11) = sprintf ("%011o", length($$dataref));
      substr ($tarheader, 136, 11) = sprintf ("%011o", scalar time);
      substr ($tarheader, 156, 1) = "\0"; # typeflag
      substr ($tarheader, 257, 5) = "ustar"; # magic
      substr ($tarheader, 263, 2) = "00"; # version
      substr ($tarheader, 265, 8) = "mogilefs";	# user
      substr ($tarheader, 297, 8) = "mogilefs";	# group
      substr ($tarheader, 329, 7) = "0000000";
      substr ($tarheader, 337, 7) = "0000000";
      substr ($tarheader, 148, 7) = sprintf ("%07o", tarchecksum($tarheader));
      print $tarheader;
      $totalbytes += 512;

      print $$dataref;
      $totalbytes += length($$dataref);

      my $pad = 512 - (length($$dataref) & 511);
      if ($pad != 512)
      {
	print "\0" x $pad;
	$totalbytes += $pad;
      }
    }
  }
}
print "\0" x 1024;
$totalbytes += 1024;

my $pad = 0x1000 - ($totalbytes & 0xfff);
if ($pad != 0x1000)
{
  print "\0" x $pad;
  $totalbytes += $pad;
}

sub tarchecksum
{
  my $sum = 0;
  for (@_)
  {
    for (my $i=0; $i<length; $i++)
    {
      if ($i >= 148 && $i < 156) { $sum += 32; }
      else { $sum += ord(substr($_,$i,1)); }
    }
  }
  return $sum;
}

# arch-tag: 380ef2a7-5c3e-11dc-9207-0015f2b17887
