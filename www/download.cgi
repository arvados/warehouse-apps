#!/usr/bin/perl

use strict;
use MogileFS::Client;
use Digest::MD5 qw(md5_hex md5);
use DBI;
use CGI ':standard';

my $q = new CGI;

my $keyprefix = $q->param ("keyprefix");
my $manifest = $q->param ("manifest");
my $format = $q->param ("format"); # "", "text", "1md5", or "2md5"

if (!($format eq "1md5" ||
      $format eq "2md5" ||
      $format eq "text"))
{
    $format = "text";
}

if ($manifest)
{
    if ($format eq "text")
    {
	print $q->header ('text/plain');
    }
    else
    {
	print $q->header ('application/binary');
    }
}
else
{
    print $q->header ('application/x-tar');
}

do '/etc/polony-tools/config.pl';

my $dbh = DBI->connect($main::mogilefs_dsn,
		       $main::mrwebgui_mysql_username,
		       $main::mrwebgui_mysql_password)
    or die DBI->errstr;

my $sth = $dbh->prepare ("select dmid from domain where namespace=?");
$sth->execute ($main::mogilefs_default_domain) or die DBI->errstr;
my ($dmid) = $sth->fetchrow_array;
die "Couldn't find dmid for namespace '$main::mogilefs_default_domain'"
    unless $dmid > 0;

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

if ($manifest && $format eq "text")
{
  print "- 0 ,\n";
}

$sth = $dbh->prepare ("select
 dkey, length, md5
 from file
 left join md5 on file.fid=md5.fid
 where dmid = ? and dkey like ?");

$sth->{"mysql_use_result"} = 1;
$sth->execute ($dmid, $keyprefix."%")
    or die DBI->errstr;

my $totalbytes = 0;
my $fetchmore = 1;
my $keys;
while ($fetchmore)
{
  my @results;
  while ($fetchmore)
  {
    if (my ($mogkey, $moglength, $mogmd5) = $sth->fetchrow_array)
    {
      push @results, [$mogkey, $moglength, $mogmd5];
      last if $#results == 9999;
    }
    else
    {
      $fetchmore = 0;
    }
  }
  @results = sort { $$a[0] cmp $$b[0] } @results;

  my $ei = 0;
  while (@results)
  {
    my ($mogkey, $moglength, $mogmd5) = @{shift @results};
    my $tarkey = $mogkey;
    substr($tarkey, 0, length($keyprefix_to_remove)) = "";

    while ($ei <= $#exclude && $exclude[$ei] lt "/$tarkey")
    {
      ++$ei;
    }
    if ($ei <= $#exclude &&
	(
	 ($exclude[$ei] eq "/$tarkey")
	 ||
	 ($exclude[$ei] eq "/$tarkey $moglength")
	 ||
	 ($exclude[$ei] eq "/$tarkey $moglength $mogmd5")
	 )
	)
    {
      ++$ei;
      next;
    }

    if ($manifest)
    {
	if ($format eq "text")
	{
	    print "$mogkey $moglength $mogmd5\n";
	}
	elsif ($format eq "1md5")
	{
	    print md5 ("$mogkey $moglength");
	}
	elsif ($format eq "2md5")
	{
	    print md5 ("$mogkey $moglength");
	    print pack ("H32", $mogmd5);
	}
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

if ($manifest)
{
    if ($format eq "text")
    {
	print "eof 0 --------------------------------\n";
    }
    elsif ($format eq "1md5")
    {
	print pack ("H32", 0);
    }
    elsif ($format eq "2md5")
    {
	print pack ("H32", 0);
	print pack ("H32", 0);
    }
}
else
{
  print "\0" x 1024;
  $totalbytes += 1024;

  my $pad = 0x1000 - ($totalbytes & 0xfff);
  if ($pad != 0x1000)
  {
    print "\0" x $pad;
    $totalbytes += $pad;
  }
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
