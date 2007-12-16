#!/usr/bin/perl

use strict;
use DBI;
use CGI ':standard';

do '/etc/polony-tools/config.pl';

my $q = new CGI;
print $q->header;
print q{
<html>
<head>
<title>mapreduce jobs</title>
</head>
<body>
<h2>mapreduce jobs</h2>
<p><A href="mrnew.cgi">New job</a></p>
};

my $dbh = DBI->connect($main::mapreduce_dsn,
		       $main::mrwebgui_mysql_username,
		       $main::mrwebgui_mysql_password) or die DBI->errstr;

my $sth = $dbh->prepare("select dmid from mogilefs.domain where namespace=?");
$sth->execute ($main::mogilefs_default_domain) or die $dbh->errstr;
my ($dmid) = $sth->fetchrow ();

my $limit = ($q->param('showall') ? "" : "limit 10");

my $sth = $dbh->prepare("
    select mrjob.id,
      jobmanager_id,
      revision,
      mrfunction,
      nprocs,
      nodes,
      knobs,
      mrjob.starttime,
      mrjob.finishtime,
      unix_timestamp(mrjob.finishtime)-unix_timestamp(mrjob.starttime),
      count(mrjobstep.id),
      mrjob.success,
      mrjob.output,
      mrjob.input0
    from mrjob
    left join mrjobstep on mrjob.id=mrjobstep.jobid and ((mrjobstep.finishtime is null) = (mrjob.finishtime is null))
    group by mrjob.id
    order by mrjob.id desc
    $limit");
$sth->execute () or die $dbh->errstr;

print q{
<table>
<tr>
};
print map ("<td>$_</td>\n", qw(JobID MgrID Rev Function Procs Nodes Knobs Start Finish Elapsed Done/-ToDo Success Output Log));
print q{
</tr>
};
while (my @row = $sth->fetchrow)
{
  my ($jobid) = @row;
  for (@row) { $_ = escapeHTML($_); }
  for ($row[5]) { s/,/, /g; }
  for ($row[6]) { s/\n/<br>/g; s/,/, /g; }
  $row[10] = 0-$row[10] if !defined $row[8];
  $row[0] = "<a href=\"mrjob.cgi?id=$jobid\">$row[0]</a>";
  for ($row[12])
  {
    s/.*/<a href=\"whget.cgi\/$&\">$&<\/a>/
	if defined;
  }
  my $input0 = pop @row;
  if ($input0 =~ /^[0-9a-f]{32}/) {
    $row[3] .= "(".substr($input0,0,12)."...)";
  }

  push @row, "<a href=\"mrlog.cgi?id=$jobid\">log</a>";
  print "<tr>\n";
  print map ("<td valign=top>$_</td>\n", @row);
  print "</tr>\n";
}
print q{
</table>
};

if ($limit) { print "<p><a href=\"mrindex.cgi?showall=1\">show all</a></p>"; }

print q{
</body>
</html>
};
