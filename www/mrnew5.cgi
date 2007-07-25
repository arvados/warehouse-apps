#!/usr/bin/perl

use strict;
use DBI;
use CGI ':standard';

do '/etc/polony-tools/config.pl';

my $q = new CGI;

my $dbh = DBI->connect($main::mapreduce_dsn,
		       $main::mapreduce_mysql_username,
		       $main::mapreduce_mysql_password) or die DBI->errstr;
$dbh->do ("insert into mrjob
 (jobmanager_id, nprocs, revision, mrfunction, knobs)
 values (-1, ?, ?, ?, ?)",
	  undef,
	  32,		# XXX should be chosen by user
	  $q->param('revision'),
	  $q->param('mrfunction'),
	  nocr($q->param('knobs')))
    or die $dbh->errstr;
my $jobid = $dbh->last_insert_id (undef, undef, undef, undef);
$dbh->do ("insert into mrjobstep
 (jobid, level, input, submittime)
 values (?, 0, ?, now())",
	  undef,
	  $jobid,
	  nocr($q->param('input')))
    or die $dbh->errstr;
$dbh->do ("update mrjob set jobmanager_id=null where id=?", undef, $jobid)
    or die $dbh->errstr;

print $q->redirect("mrindex.cgi");

sub nocr
{
  local ($_) = shift;
  s/\r//g;
  $_;
}
