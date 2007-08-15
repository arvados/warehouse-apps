#!/usr/bin/perl

use strict;
use DBI;

my $Qrevision = escapeHTML($q->param('revision'));
my $Qmrfunction = escapeHTML($q->param('mrfunction'));
my $Qnodelist = escapeHTML($q->param('nodelist'));
print qq{
<html>
<head>
<title>mapreduce jobs / new</title>
</head>
<body>
<h2><a href="mrindex.cgi">mapreduce jobs</a> / new (3)</h2>

<form method=get action="mrnew4-jobs.cgi">
<input type=hidden name=revision value="$Qrevision">
Revision: $Qrevision<br>
<input type=hidden name=mrfunction value="$Qmrfunction">
Map/reduce function: $Qmrfunction<br>
<input type=hidden name=nodelist value="$Qnodelist">
Nodes: $Qnodelist<br>
Jobs:<br>
};

my $dbh = DBI->connect($main::mapreduce_dsn,
		       $main::mrwebgui_mysql_username,
		       $main::mrwebgui_mysql_password) or die DBI->errstr;

my $sth = $dbh->prepare("
    select id, mrfunction, submittime, finishtime, success
    from mrjob
    order by id desc");
$sth->execute() or die $dbh->errstr;

print q{<select multiple name=jobs size=16>};

while (my @row = $sth->fetchrow)
{
  print "<option value=\"".escapeHTML($row[0])."\">";
  my $result = "unfinished";
  if ($row[3]) { $result = "finished $row[4]"; }
  if (!$row[4]) { $result .= " (failed)"; }
  print escapeHTML("$row[0] $row[1] $row[2] $finished");
  print "</option>\n";
}
print q{
</select>
<br>
<input type=submit value="Next">
</form>
</table>
</body>
</html>
};
