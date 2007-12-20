!#/usr/bin/perl
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
</body>
</html>
}
