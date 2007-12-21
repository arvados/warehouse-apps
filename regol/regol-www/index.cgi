#!/usr/bin/perl
# -*- mode: perl; perl-indent-level: 2; -*-

use strict;
use DBI;
use CGI ':standard';

do './config.pl' or die;

my $q = new CGI;
print $q->header;

print q{
<html>
<head>
<title>regol</title>
</head>
<body>
<h2>todo</h2>
<p>I have no jobs in my to-redo list.</p>
<h2>running</h2>
<p>None of my queued jobs are running now.</p>
<h2>done</h2>
<p>None of my queued jobs have finished.</p>
<h2>available</h2>
<pre>};

printf ("%-15s %4s %20s %10s\n", qw(warehouse job starttime elapsed));

my $sth = $main::dbh->prepare ("select
 warehousename,
 id,
 success,
 starttime,
 unix_timestamp(finishtime)-unix_timestamp(starttime) elapsed
 from job order by starttime desc limit 40");
$sth->execute ()
    or die DBI->errstr;
while (my $job = $sth->fetchrow_hashref)
{
  printf ("%-15s %4d %20s %10s\n",
	  escapeHTML ($job->{warehousename}),
	  $job->{id},
	  $job->{starttime},
	  $job->{success} ? $job->{elapsed} : "");
}

print q{</pre>
<h2>warehouses</h2>
<pre>};

printf ("%-15s %12s %s\n", qw(name lastupdate servers));

my $sth = $main::dbh->prepare ("select name, servers, unix_timestamp(now())-unix_timestamp(lastupdate) lastupdate_sec from warehouse order by name");
$sth->execute ()
    or die DBI->errstr;
while (my $w = $sth->fetchrow_hashref)
{
  printf ("%-15s %12d %s\n",
	  escapeHTML ($w->{name}),
	  escapeHTML ($w->{lastupdate_sec}),
	  escapeHTML ($w->{servers}));
}

print q{</pre>
</body>
</html>
}
