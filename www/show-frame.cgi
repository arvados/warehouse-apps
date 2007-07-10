#!/usr/bin/perl

use strict;
use MogileFS::Client;
use DBI;
use CGI;

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

my $q = new CGI;
my $dsid = $q->param('dsid');
my $frame = $q->param('frame');

print $q->header;

my @ext = qw(tif tif.gz raw raw.gz);
my $extcount = @ext;
my $e0 = 0;

my $dbh = DBI->connect($main::analysis_dsn,
		       $main::analysis_mysql_username,
		       $main::analysis_mysql_password);

my $sth = $dbh->prepare("select cid, nfiles, nframes
 from cycle
 left join dataset on cycle.dsid=dataset.dsid
 where cycle.dsid='$dsid'
 order by cid");

$sth->execute() or die;

my @row = $sth->fetchrow_array;
while (@row)
{
    my ($cid, $nfiles, $nframes) = @row;
    my $prefix;
    if ($cid == '999')
    {
	$prefix = "WL";
    }
    else
    {
	$prefix = "SC";
    }
    my $startimage;
    my $stopimage;
    if ($nfiles == $nframes)
    {
	$startimage = $frame;
	$stopimage = $frame;
    }
    elsif ($nfiles > $nframes)
    {
	$startimage = $frame * 4 - 3;
	$stopimage = $frame * 4;
    }
    for (my $i=$startimage; $i<=$stopimage; $i++)
    {
	my $fileid = sprintf ("%04d", $i);
	for (my $e = 0; $e < 1 || $e < $extcount; $e++)
	{
	    my $dkey = "/$dsid/IMAGES/RAW/$cid/".$prefix."_".$fileid.".".$ext[($e0+$e)%$extcount];
	    my @url = $mogc->get_paths ($dkey, 1);
	    if (@url)
	    {
		$e0 = $e;
		print "<a href=\"get.php?domain=images&dkey=$dkey&format=png\">$dkey</a><br>\n";
		last;
	    }
	}
    }
    @row = $sth->fetchrow_array;
}
