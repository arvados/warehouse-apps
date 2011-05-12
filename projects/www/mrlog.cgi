#!/usr/bin/perl

use strict;
use DBI;
use CGI ':standard';

do '/etc/polony-tools/config.pl';

my $q = new CGI;
print $q->header;

my $jobid = $q->param('id');

print qq{
<html>
<head>
<title>mapreduce jobs</title>
</head>
<body>
<h2><a href="mrindex.cgi">mapreduce jobs</a> / <a href="mrjob.cgi?id=$jobid">job $jobid</a> / log</h2>

};

my $dbh = DBI->connect($main::mapreduce_dsn,
		       $main::mrwebgui_mysql_username,
		       $main::mrwebgui_mysql_password) or die DBI->errstr;

my $sth = $dbh->prepare("
    select id, time, jobid, jobstepid, message
    from mrlog
    where jobid=?
    order by id desc");
$sth->execute ($jobid) or die $dbh->errstr;

print q{
<table>
<tr>
};
print map ("<td>$_</td>\n", qw(LogID Time JobID JobStepID Message));
print q{
</tr>
};
while (my @row = $sth->fetchrow)
{
  my ($jobid) = @row;
  for (@row) { $_ = escapeHTML($_); }
  $row[1] =~ s/ /&nbsp;/g;
  $row[-1] =~ s/\n/<br>/g;
  print "<tr>\n";
  print map ("<td valign=top>$_</td>\n", @row);
  print "</tr>\n";
}

print q{
</table>
</body>
</html>
};
