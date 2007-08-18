#!/usr/bin/perl

use strict;
use DBI;

my $Qrevision = escapeHTML($q->param('revision'));
my $Qmrfunction = escapeHTML($q->param('mrfunction'));
my $Qjobs = escapeHTML(join(",", sort { $a <=> $b } $q->param ('jobs')));
my $Qnodelist = escapeHTML($q->param('nodelist'));

my @prefixlist;
foreach (sort { $a <=> $b } $q->param ('jobs'))
{
  push @prefixlist, "mrjobstep/$_/*";
}
my $Qprefixlist = escapeHTML (join("\n", @prefixlist));


my $defaultknobs = "";
my $dbh = DBI->connect($main::mapreduce_dsn,
		       $main::mrwebgui_mysql_username,
		       $main::mrwebgui_mysql_password) or die DBI->errstr;

my $sth = $dbh->prepare("select knobs from mrjob where id in ($Qjobs)");
$sth->execute($q->param('dsid')) or die $dbh->errstr;
while (my @row = $sth->fetchrow)
{
  $defaultknobs .= escapeHTML ("$row[0]\n");
}
$defaultknobs .= escapeHTML ($mrparam{'MR_KNOBS'});

print qq{
<html>
<head>
<title>mapreduce jobs / new</title>
</head>
<body>
<h2><a href="mrindex.cgi">mapreduce jobs</a> / new (4)</h2>

<form method=post action="mrnew4-jobs.cgi">
Revision: $Qrevision<br>
Function: $Qmrfunction<br>
Jobs: $Qjobs<br>
Nodes: $Qnodelist<br>

Knobs:<br>
<textarea name=knobs rows=6 cols=40>$defaultknobs</textarea>
<br>

<input type=hidden name=input value="$Qprefixlist">
<input type=hidden name=mrfunction value="$Qmrfunction">
<input type=hidden name=revision value="$Qrevision">
<input type=hidden name=nodelist value="$Qnodelist">

<input type=submit value="Next">
</form>
</table>
</body>
</html>
};
