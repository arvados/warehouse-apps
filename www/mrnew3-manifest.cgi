#!/usr/bin/perl

use strict;
use DBI;

my $Qrevision = escapeHTML($q->param('revision'));
my $Qmrfunction = escapeHTML($q->param('mrfunction'));
my $Qnodelist = escapeHTML($q->param('nodelist'));
my ($Qkey, $Qname) = map { escapeHTML ($_) } split (/=/, $q->param('key'), 2);
print qq{
<html>
<head>
<title>mapreduce jobs / new</title>
</head>
<body>
<h2><a href="mrindex.cgi">mapreduce jobs</a> / new (3)</h2>

<form method=get action="mrnew4-manifest.cgi">
<input type=hidden name=revision value="$Qrevision">
Revision: $Qrevision<br>
<input type=hidden name=mrfunction value="$Qmrfunction">
Map/reduce function: $Qmrfunction<br>
<input type=hidden name=nodelist value="$Qnodelist">
Nodes: $Qnodelist<br>
<input type=hidden name=key value="$Qkey">
<input type=hidden name=name value="$Qname">
Manifest: $Qkey = $Qname<br>
<br>
Knobs:<br>
<textarea name=knobs rows=6 cols=40>$defaultknobs</textarea>
<br>
<input type=submit value="Next">
</form>
</table>
</body>
</html>
};
