#!/usr/bin/perl

use strict;
use DBI;
use CGI ':standard';

my $q = new CGI;

print $q->header ('text/plain');

do '/etc/polony-tools/genomerator.conf.pl';

my $dbh = DBI->connect($main::analysis_dsn,
		       $main::mrwebgui_mysql_username,
		       $main::mrwebgui_mysql_password)
    or die DBI->errstr;


my $needfullpath = !defined $ENV{"DSID"};
my $dsid = $q->param ('dsid');
$dsid =~ s/[^-_a-zA-Z0-9]//g;

my $sth = $dbh->prepare ("select cid from cycle where dsid=? and nfiles>0 and cid<>'none' order by cid");
$sth->execute ($dsid) or die DBI->errstr;
while (my @row = $sth->fetchrow)
{
    my ($cid) = @row;
    my $nimages = $cid =~ /\D/ ? 4 : 1;

    my $imagesrc = "/getimage.cgi";
    $imagesrc .= "/$dsid/IMAGES/RAW" if $needfullpath;
    $imagesrc .= "/$cid/";
    if ($cid eq "999")
    {
	$imagesrc .= "WL_";
    }
    else
    {
	$imagesrc .= "SC_";
    }

    print "$cid $nimages $imagesrc\n";
}
