#!/usr/bin/perl

use strict;
use DBI;
use CGI ':standard';

do '/etc/polony-tools/config.pl';

my $q = new CGI;
print $q->header ('text/plain');

my $jobstepid = $q->param('id');

my $dbh = DBI->connect($main::mapreduce_dsn,
		       $main::mrwebgui_mysql_username,
		       $main::mrwebgui_mysql_password) or die DBI->errstr;

my $sth = $dbh->prepare("select stderr from mrjobstep where id=?");
$sth->execute ($jobstepid) or die $dbh->errstr;
print $sth->fetchrow;
