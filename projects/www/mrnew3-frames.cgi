#!/usr/bin/perl

use strict;
use DBI;

my $Qrevision = escapeHTML($q->param('revision'));
my $Qmrfunction = escapeHTML($q->param('mrfunction'));
my $Qnodelist = escapeHTML($q->param('nodelist'));
my $Qdsid = escapeHTML($q->param('dsid'));
print qq{
<html>
<head>
<title>mapreduce jobs / new</title>
</head>
<body>
<h2><a href="mrindex.cgi">mapreduce jobs</a> / new (3)</h2>

<form method=get action="mrnew4-frames.cgi">
<input type=hidden name=revision value="$Qrevision">
Revision: $Qrevision<br>
<input type=hidden name=mrfunction value="$Qmrfunction">
Map/reduce function: $Qmrfunction<br>
<input type=hidden name=nodelist value="$Qnodelist">
Nodes: $Qnodelist<br>
<input type=hidden name=dsid value="$Qdsid">
Dataset: $Qdsid<br>
Cycles:<br>
};

my $dbh = DBI->connect($main::analysis_dsn,
		       $main::analysis_mysql_username,
		       $main::analysis_mysql_password) or die DBI->errstr;

my $sth = $dbh->prepare("
    select cid, nfiles, exposure
    from dataset left join cycle on dataset.dsid=cycle.dsid
    where dataset.dsid=? and nfiles>nframes*3
    order by cid");
$sth->execute($q->param('dsid')) or die $dbh->errstr;

print q{<select multiple name=cycles size=16>};

while (my @row = $sth->fetchrow)
{
  print "<option value=\"".escapeHTML($row[0])."\">";
  print escapeHTML("$row[0] ($row[1] files) $row[2]");
  print "</option>\n";
}
print q{
</select>
<br>
};

$sth = $dbh->prepare("select nframes from dataset where dsid=?");
$sth->execute($q->param('dsid')) or die $dbh->errstr;
my @row = $sth->fetchrow;

print qq{
Frames:<br>
<input type=text name=frames value="1-$row[0]"> (1-$row[0])
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
