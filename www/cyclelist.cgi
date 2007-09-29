#!/usr/bin/perl

use strict;
use DBI;
use CGI ':standard';

my $q = new CGI;

print $q->header ('text/plain');

do '/etc/polony-tools/config.pl';

my $dbh = DBI->connect($main::analysis_dsn,
		       $main::mrwebgui_mysql_username,
		       $main::mrwebgui_mysql_password)
    or die DBI->errstr;


my $dsid = $q->param ('dsid');

my $sth = $dbh->prepare ("select cid from cycle where dsid=? and nfiles>0 order by cid");
$sth->execute ($dsid) or die DBI->errstr;
while (my @row = $sth->fetchrow)
{
    my ($cid) = @row;
    my $nimages = $cid =~ /\D/ ? 4 : 1;
    print "$cid $nimages\n";
}
