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
<h2><a href="mrindex.cgi">mapreduce jobs</a> / job $jobid</h2>

};

my $dbh = DBI->connect($main::mapreduce_dsn,
		       $main::mapreduce_mysql_username,
		       $main::mapreduce_mysql_password) or die DBI->errstr;

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
      mrjob.success
    from mrjob
    left join mrjobstep on mrjob.id=mrjobstep.jobid
    where mrjob.id=?
    group by mrjob.id");
$sth->execute ($jobid) or die $dbh->errstr;

print q{
<table>
<tr>
};
print map ("<td>$_</td>\n", qw(JobID MgrID Rev Function Procs Nodes Knobs Start Finish Elapsed Steps Success Output));
print q{
</tr>
};
while (my @row = $sth->fetchrow)
{
  my ($jobid) = @row;
  for (@row) { $_ = escapeHTML($_); }
  for ($row[6]) { s/\n/<br>/g; s/,/, /g; }
  if ($row[-1])
  {
    push @row, "<a href=\"get.php?format=text&domain=images&dkey=mrjob/$jobid\">view</a>";
  }
  print "<tr>\n";
  print map ("<td valign=top>$_</td>\n", @row);
  print "</tr>\n";
}
print q{
</table>
};

$sth = $dbh->prepare ("select input0 from mrjob where id=?");
$sth->execute ($jobid) or die $sth->errstr;
my $input0 = $sth->fetchrow;

print "<p>Input:<blockquote><pre><small>".escapeHTML($input0)."</small></pre></blockquote></p>";

print q{
<table>
};

my $sth = $dbh->prepare("select
 id,level,input,submittime,starttime,finishtime,exitcode,length(stderr)
 from mrjobstep
 where jobid=?
 order by id");
$sth->execute ($jobid) or die $sth->errstr;
print map ("<td>$_</td>\n", qw(StepID Level Input Submit Start Finish ExitCode stderr));
print q{
</tr>
};
while (my @row = $sth->fetchrow)
{
  for (@row) { $_ = escapeHTML($_); }
  for ($row[2]) { s/\n/<br>/g; }
  if ($row[-1])
  {
    $row[-1] = "<a href=\"mrjobstep.cgi?id=$row[0]\">$row[-1]&nbsp;bytes</a>";
  }
  print "<tr>\n";
  print map ("<td valign=top>$_</td>\n", @row);
  print "</tr>\n";
}

print q{
</table>
</body>
</html>
};
