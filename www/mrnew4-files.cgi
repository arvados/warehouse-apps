#!/usr/bin/perl

use strict;
use CGI ':standard';

do '/etc/polony-tools/config.pl';

my $q = new CGI;
print $q->header;

my $Qrevision = escapeHTML($q->param('revision'));
my $Qmrfunction = escapeHTML($q->param('mrfunction'));
my $Qdsid = escapeHTML($q->param('dsid'));
my $Qknobs = escapeHTML($q->param('knobs'));
my $Qnodelist = escapeHTML($q->param('nodelist'));

print qq{
<html>
<head>
<title>mapreduce jobs / new</title>
</head>
<body>
<h2><a href="mrindex.cgi">mapreduce jobs</a> / new (4)</h2>

<form method=post action="mrnew5.cgi">
Revision: $Qrevision<br>
Function: $Qmrfunction<br>
Dataset: $Qdsid<br>
Knobs: $Qknobs<br>
Nodes: $Qnodelist<br>

<input type=hidden name=knobs value="$Qknobs">
<input type=hidden name=input value="/$Qdsid/">
<input type=hidden name=mrfunction value="$Qmrfunction">
<input type=hidden name=revision value="$Qrevision">
<input type=hidden name=nodelist value="$Qnodelist">

<input type=submit value="Submit job">
</form>
</table>
</body>
</html>
};
