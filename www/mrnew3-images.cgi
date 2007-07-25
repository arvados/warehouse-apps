#!/usr/bin/perl

use strict;
use MogileFS::Client;
use DBI;
use CGI ':standard';

my $Qrevision = escapeHTML($q->param('revision'));
my $Qmrfunction = escapeHTML($q->param('mrfunction'));
my $Qdsid = escapeHTML($q->param('dsid'));
print qq{
<html>
<head>
<title>mapreduce jobs / new</title>
</head>
<body>
<h2><a href="mrindex.cgi">mapreduce jobs</a> / new (3)</h2>

<form method=post action="mrnew4-images.cgi">
<input type=hidden name=revision value="$Qrevision">
Revision: $Qrevision<br>
<input type=hidden name=mrfunction value="$Qmrfunction">
Map/reduce function: $Qmrfunction<br>
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
    where dataset.dsid=? and nfiles>0
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
<input type=submit value="Next">
</form>
</table>
</body>
</html>
};
