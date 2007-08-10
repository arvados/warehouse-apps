#!/usr/bin/perl

use strict;
use DBI;
use CGI ':standard';

do '/etc/polony-tools/config.pl';

my $q = new CGI;
print $q->header;

my $jobid = $q->param('id');
my $sort = $q->param('sort') || '';
$sort =~ s/[^a-z0-9]//gi;

print qq{
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
   "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<title>mapreduce jobs</title>
</head>
<body>
<h2><a href="mrindex.cgi">mapreduce jobs</a> / job $jobid</h2>

<ul>
<li>View <a href="mrlog.cgi?id=$jobid">jobmanager's log</a>
</ul>

};

my $dbh = DBI->connect($main::mapreduce_dsn,
		       $main::mrwebgui_mysql_username,
		       $main::mrwebgui_mysql_password) or die DBI->errstr;

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
  for ($row[5]) { s/,/, /g; }
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

print "<p>Input:<blockquote><pre><small>".escapeHTML($input0)."</small></pre></blockquote><br>";

print q{
<table>
};

my $order_str = 'id';
if ($sort eq 'elapsed') {
	$order_str = "unix_timestamp(finishtime)-unix_timestamp(starttime)";
} elsif ($sort ne '') {
	$order_str = $sort;
}

my %fields;
$fields{StepID} = 'id';
$fields{Level} = 'level';
$fields{Input} = 'input';
$fields{Submit} = 'submittime';
$fields{Start} = 'starttime';
$fields{Finish} = 'finishtime';
$fields{Elapsed} = 'elapsed';
$fields{Attempts} = 'attempts';
$fields{Node} = 'node';
$fields{ExitCode} = 'exitcode';
$fields{stderr} = 'stderr';

my $sth = $dbh->prepare("select
 id,level,input,submittime,starttime,finishtime,
 unix_timestamp(finishtime)-unix_timestamp(starttime) elapsed,
 attempts,node,exitcode,length(stderr)
 from mrjobstep
 where jobid=?
 order by $order_str");
$sth->execute ($jobid) or die $sth->errstr;
print "<tr>";
print map ("<td><a href=\"?id=$jobid&amp;sort=" . $fields{$_} . "\">$_</a></td>\n", qw(StepID Level Input Submit Start Finish Elapsed Attempts Node ExitCode stderr));
print q{
<td>stdout</td></tr>
};
while (my @row = $sth->fetchrow)
{
  for (@row) { $_ = escapeHTML($_); }
  for ($row[2]) { s/\n/<br>/g; }
  if ($row[-1])
  {
    $row[-1] = "<a href=\"mrjobstep.cgi?id=$row[0]\">$row[-1]&nbsp;bytes</a>";
  }
  for ($row[9]) { if ($_) { $_ = sprintf "0x%x", $_; } }
  print "<tr>\n";
  print map ("<td valign=top>$_</td>\n", @row);
  print "<td valign=top><a href=\"get.php?format=text&amp;domain=images&amp;dkey=mrjobstep/$jobid/$row[0]\">download</a></td>";
  print "</tr>\n";
}

print q{
</table>
</body>
</html>
};
