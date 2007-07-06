#!/usr/bin/perl

use strict;
use MogileFS::Client;
use Digest::MD5 'md5_hex';
use DBI;
use Time::HiRes qw(gettimeofday tv_interval);
use Fcntl ':flock';

do '/etc/polony-tools/config.pl';

my %opts = qw (quick 0);
while (@ARGV && $ARGV[0] =~ /^--?([^-].*?)(=(.*))?$/)
{
    if (defined ($2))
    {
	$opts{$1} = $3;
    }
    else
    {
	$opts{$1} = 1;
    }
    shift @ARGV;
}
if (@ARGV == 1 && $ARGV[0] eq "list")
{
    print map("$_\n", keys %main::remote_lims);
    exit 0;
}
if (@ARGV != 2)
{
    my $remotelist
	= join ("\n",
		map (sprintf (" %-12s %s",
			      $_,
			      join (", ",
				    @{$main::remote_lims{$_}{"trackers"}})),
		     sort keys %main::remote_lims));
    warn qq{
$0:      Copy files from local cluster to remote cluster.
usage:   $0 [options] keyprefix remote-lims-name
options:
 -v       verbose
 --quick  don't update remote md5 table (not recommended)
configured remote limses:
$remotelist
};
    exit 1;
}
my $keyprefix = shift @ARGV;
my $remotelimsname = shift @ARGV;
my %remotelims = %{$main::remote_lims{$remotelimsname}};

my $lockfile = $keyprefix;
$lockfile =~ s|^/||g;
$lockfile =~ s|/.*||g;
$lockfile = $main::lockfile_prefix . "dscopy.$remotelimsname.$lockfile";
if (!open (LOCKFILE, ">>$lockfile")
    ||
    !flock (LOCKFILE, LOCK_EX | LOCK_NB))
{
    die "$0: Couldn't lock $lockfile -- exiting.\n";
}
$main::lockfile = $lockfile;
$main::havelock = 1;
# $SIG{"INT"} = \&unlock_and_exit;

my @trackers = $main::mogilefs_trackers;
my @copyto_trackers = @{$remotelims{'trackers'}};

my $mogc = MogileFS::Client->new
    (domain => $main::mogilefs_default_domain,
     hosts => [@main::mogilefs_trackers]);

my $copyto_mogc = MogileFS::Client->new
    (domain => $remotelims{'default_domain'},
     hosts => $remotelims{'trackers'});

my $dbh = DBI->connect($main::mogilefs_dsn,
		       $main::mogilefs_username,
		       $main::mogilefs_password);

my $copyto_dbh = DBI->connect($remotelims{'dsn'},
			      $remotelims{'username'},
			      $remotelims{'password'});

my $sth = $dbh->prepare("select dkey, md5 from file left join md5 on md5.fid=file.fid left join file_on on file.fid=file_on.fid where dkey like ? and file_on.fid is not null group by dkey order by binary dkey");

my $copyto_sth = $copyto_dbh->prepare("select dkey, md5 from file left join md5 on md5.fid=file.fid left join file_on on file.fid=file_on.fid where dkey like ? and file_on.fid is not null order by binary dkey");

my $md5_sth = $copyto_dbh->prepare ("insert into md5 (fid, md5) select fid, ? from file left join domain on domain.dmid=file.dmid where dkey=? and domain.namespace=?");

print "Getting local manifest.\n";
$sth->execute ($keyprefix . "%") or die;

print "Getting remote manifest.\n";
$copyto_sth->execute ($keyprefix . "%") or die;

my @row = $sth->fetchrow_array;
my @copyto_row = $copyto_sth->fetchrow_array;

my $txbytes = 0;
my $t0 = [gettimeofday];

my $attempt = 0;
my $failed = 0;

print "Comparing manifests.\n";
while (@row)
{
    # if @copyto_row already has this dkey, fetch next copyto_row
    if (@copyto_row
	&& $row[0] eq $copyto_row[0]
	&& ($row[1] eq $copyto_row[1]
	    || !defined($row[1])
	    || !defined($copyto_row[1])))
    {
	printf ("skip    %s\n", $row[0])
	    if $opts{v};
    }
    # else, fetch from $mogc and inject in $copyto_mogc
    else
    {
	if (@copyto_row
	    && $row[0] eq $copyto_row[0])
	{
	    printf ("md5!!!! %-32s %s\n", $copyto_row[1], $copyto_row[0]);
	}
	printf ("copy    %-50s ", $row[0]);

	my ($dkey, $md5) = @row;
	$attempt = 0;
      GETCONTENT:
	my $content = eval { $mogc->get_file_data ($dkey); };
	if ($@) {
	    if ($attempt > 5) { die "$@"; }
	    if ($attempt++ > 0) { sleep($attempt); }
	    $mogc = MogileFS::Client->new
		(domain => $main::mogilefs_default_domain,
		 hosts => [@main::mogilefs_trackers]);
	    goto GETCONTENT;
	}
	my $ok = defined($content);
	if (!$ok)
	{
	    printf ("\nempty!! %-50s ", $row[0]);
	}
	if ($ok)
	{
	    $attempt = 0;
	  PUTCONTENT:
	    $ok = eval { $copyto_mogc->store_content
		($dkey,
		 $remotelims{'default_class'},
		 $content); };
	    if ($@) {
		if ($attempt > 5) { die "$@"; }
		if ($attempt++ > 0) { sleep($attempt); }
		$copyto_mogc = MogileFS::Client->new
		    (domain => $remotelims{'default_domain'},
		     hosts => $remotelims{'trackers'});
		goto PUTCONTENT;
	    }
	}
	if ($ok)
	{
	    $txbytes += length $$content;
	    if (!$opts{quick})
	    {
		$md5_sth->execute ($md5, $dkey, $remotelims{'default_domain'});
	    }
	}
	my $speed = $txbytes / 1048576 / tv_interval($t0);
	printf ("%0.2f MB/s\n", $speed);
	if (!$ok)
	{
	    printf ("FAIL    %-32s\n", $row[0]);
	    $failed++;
	}
    }

    @row = $sth->fetchrow_array;
    while (@copyto_row && ($row[0] gt $copyto_row[0]))
    {
	@copyto_row = $copyto_sth->fetchrow_array;
    }
}

if ($failed)
{
    exit(1);
}

sub unlock_and_exit
{
    unlock();
    exit(0);
}

sub unlock
{
    if (defined ($main::havelock))
    {
	unlink($main::lockfile);
	undef $main::havelock;
    }
}

END {
    unlock();
}

# arch-tag: 7d3f35aa-1df0-11dc-9207-0015f2b17887
