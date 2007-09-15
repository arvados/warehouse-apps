#!/usr/bin/perl

use strict;
use MogileFS::Client;
use Digest::MD5 'md5_hex';
use DBI;
use Fcntl ':flock';

do '/etc/polony-tools/config.pl';


debuglog ("Connecting to mysql");


my $dbh = DBI->connect($main::analysis_dsn,
		       $main::mrwebgui_mysql_username,
		       $main::mrwebgui_mysql_password)
    or die DBI->errstr;


debuglog ("Looking up dmid for $main::mogilefs_default_domain");

my $sth = $dbh->prepare ("select dmid from mogilefs.domain where namespace=?");
$sth->execute ($main::mogilefs_default_domain) or die DBI->errstr;
my ($dmid) = $sth->fetchrow_array;
die "Couldn't find dmid for namespace '$main::mogilefs_default_domain'"
    unless $dmid > 0;


debuglog ("Locking");

open LOCKFILE, "+>>/var/lock/lock.polony-tools.update" or die "lockfile open";
flock LOCKFILE, LOCK_EX or die "lockfile flock";


debuglog ("Reading all MogileFS keys");

my %count;
my %size;
my $after = "";
my $lastdsid;
my $lastcycle;
my $lengthcache;
my $countcache;

$sth = $dbh->prepare ("select dkey,length
 from mogilefs.file
 where dmid=?
 and dkey>?
 order by dkey")
    or die DBI->errstr;

$sth->{"mysql_use_result"} = 1;	# do not try to buffer the result at client

while (defined $after)
{
    $sth->execute ($dmid, $after)
	or die DBI->errstr;
    $after = undef;
    while (my ($dkey, $length) = $sth->fetchrow_array)
    {
	$after = $dkey;
	my ($dsid, $cycle);
	if ($dkey =~ m,^/([^/]+)/IMAGES/RAW/([^/]+)/[^/]*\.(tiff?|raw)(\.g?z)?$,)
	{
	    $dsid = $1;
	    $cycle = $2;
	    $cycle =~ tr/A-Z/a-z/;
	}
	elsif ($dkey =~ m,^/([^/]+), && $dkey !~ m,^/\d+/frame/,)
	{
	    $dsid = $1;
	    $cycle = "none";
	}
	else
	{
	    $dsid = "none";
	    $cycle = "none";
	}
	if ($lastdsid ne $dsid || $lastcycle ne $cycle)
	{
	    if (defined $lastdsid)
	    {
		if (!ref $size{$lastdsid})
		{
		    $size{$lastdsid} = {};
		    $count{$lastdsid} = {};
		    print STDERR "$lastdsid\n";
		}
		$size{$lastdsid}{$lastcycle} += $lengthcache;
		$count{$lastdsid}{$lastcycle} += $countcache;
	    }
	    $lengthcache = 0;
	    $countcache = 0;
	}
	$lastdsid = $dsid;
	$lastcycle = $cycle;
	$lengthcache += $length;
	$countcache ++;
	print STDERR "." if ($countcache % 1000 == 0);
    }
}

if (defined $lastdsid)
{
    if (!ref $size{$lastdsid})
    {
	$size{$lastdsid} = {};
	$count{$lastdsid} = {};
	print STDERR "$lastdsid\n";
    }
    $size{$lastdsid}{$lastcycle} += $lengthcache;
    $count{$lastdsid}{$lastcycle} += $countcache;
    $lengthcache = 0;
    $countcache = 0;
}


debuglog ("Connecting to MogileFS");

my $mogc;
for (qw(10 20 30 40 50))
{
    $mogc = eval {
	MogileFS::Client->new (domain => $main::mogilefs_default_domain,
			       hosts => [@main::mogilefs_trackers]);
      };
    last if $mogc;
    debuglog ("Failed, wait $_ seconds");
    sleep $_;
}
die "$@" if !$mogc;


debuglog ("Building dataset_tmp and cycle_tmp");

$dbh->do ("create table dataset_tmp like dataset");
$dbh->do ("delete from dataset_tmp"); # maybe it already existed
$dbh->do ("create table cycle_tmp like cycle");
$dbh->do ("delete from cycle_tmp"); # maybe it already existed

foreach my $dsid (sort keys %size)
{
    my %cycle;
    my $nframes;

    if (my $positions = $mogc->get_file_data ("/$dsid/IMAGES/RAW/positions"))
    {
	foreach (split ("\n", $$positions))
	{
	    ++$nframes if /^\d+\s/;
	}
    }

    if (my $cycles = $mogc->get_file_data ("/$dsid/IMAGES/RAW/cycles"))
    {
	foreach (split ("\n", $$cycles))
	{
	    if (my @c = split (","))
	    {
		if (@c > 1)
		{
		    $c[1] =~ tr/A-Z/a-z/;
		    $cycle{$c[1]} = 1;
		    $dbh->do ("insert into cycle_tmp (dsid, cid, exposure) values (?, ?, ?)",
			      undef, $dsid, $c[1], $_);
		}
	    }
	}
    }

    foreach my $cycle (sort keys %{$size{$dsid}})
    {
	if (!exists $cycle{$cycle})
	{
	    $cycle{$cycle} = 1;
	    $dbh->do ("insert into cycle_tmp (dsid, cid) values (?, ?)",
		      undef, $dsid, $cycle);
	}
	$dbh->do ("update cycle_tmp set nfiles=?, nbytes=? where dsid=? and cid=?",
		  undef,
		  $count{$dsid}{$cycle},
		  $size{$dsid}{$cycle},
		  $dsid,
		  $cycle);
    }

    my $ncycles = scalar keys %cycle;
    $dbh->do ("insert into dataset_tmp (dsid,nframes,ncycles) values (?,?,?)",
	      undef, $dsid, $nframes, $ncycles);
}


debuglog ("Copying dataset_tmp and cycle_tmp to dataset and cycle tables");

$dbh->do ("lock tables dataset write, cycle write, dataset_tmp write, cycle_tmp write") or die DBI->errstr;
$dbh->do ("delete from dataset") or die DBI->errstr;
$dbh->do ("delete from cycle") or die DBI->errstr;
$dbh->do ("insert into dataset select * from dataset_tmp") or die DBI->errstr;
$dbh->do ("insert into cycle select * from cycle_tmp") or die DBI->errstr;
$dbh->do ("unlock tables") or die DBI->errstr;
$dbh->do ("drop table dataset_tmp") or die DBI->errstr;
$dbh->do ("drop table cycle_tmp") or die DBI->errstr;


debuglog ("Done");


sub debuglog
{
    print STDERR (scalar localtime, " ", @_, "\n");
}
