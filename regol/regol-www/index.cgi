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
<p>None of my jobs are running now.</p>
<h2>done</h2>
<p>None of my jobs have finished.</p>
<h2>available</h2>
<pre>};

my $sth = $main::dbh->prepare ("select controller, id, starttime, finishtime from job order by starttime desc limit 20");
$sth->execute ()
    or die DBI->errstr;
while (my $job = $sth->fetchrow_hashref)
{
  printf ("%-20s %4d %-20s %-20s\n",
	  escapeHTML ($job->{controller}),
	  $job->{id},
	  $job->{starttime},
	  $job->{finishtime});
}

print q{</pre>
</body>
</html>
}
