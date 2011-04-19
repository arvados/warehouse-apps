#!/usr/bin/perl
# -*- mode: perl; perl-indent-level: 2; -*-

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
<style type="text/css">
tr.success { background: #ddffdd; }
tr.running { background: #ffffff; }
tr.running td.col10 { background: #ddffdd; }
tr.running td.col12 { background: #dddddd; }
tr.fail { background: #ffdddd; }
tr.queued { background: #dddddd; }
th { text-align: left; }
td.col5, td.col9, td.col10, td.col11, td.col12, td.col13 { text-align: right; }
</style>
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

my $show = 0 + $q->param('show');
$show = 30 if !$show;
my $limit = ($q->param('showall') ? "" : "limit $show");

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
      unix_timestamp(if(mrjob.finishtime is null,now(),mrjob.finishtime))-unix_timestamp(mrjob.starttime),
      steps_done,
      steps_running,
      steps_todo,
      mrjob.success,
      mrjob.output,
      mrjob.metakey,
      mrjob.input0
    from mrjob
    order by mrjob.id desc
    $limit");
$sth->execute () or die $dbh->errstr;

print q{
<table>
<tr>
};
print map ("<th>$_</th>\n", qw(JobID MgrID Rev Function Procs Nodes Knobs Start Finish Elapsed Done Run ToDo Success Output Meta));
print q{
</tr>
};
while (my @row = $sth->fetchrow)
{
  my ($jobid) = @row;
  for (@row) { $_ = escapeHTML($_); }
  for ($row[5]) { s/,/, /g; }
  for ($row[6]) { s/\n/<br>/g; s/,/, /g; s/=/ =/g; $_ = "<code><small>$_</small></code>"; }
  for ($row[7]) { s/^\d\d\d\d-//; }
  for ($row[8]) { s/.* /.../; }
  for ($row[9]) { $_ = "<b>$_</b>" if $row[13] || !length $row[13]; }
  # $row[0] = "<a href=\"mrjob.cgi?id=$jobid\">$row[0]</a>";
  for (14, 15)
  {
    my $raw = $_ eq 15 ? "/=" : "";
    for ($row[$_])
    {
      $_ = "<a href=\"whget.cgi\/$_$raw\"><code>".substr($_,0,8)."</code><\/a>"
	  if defined;
    }
  }
  my $input0 = pop @row;
  $input0 =~ s/(^|,)([0-9a-f]{32})\+[^,]+/$1$2/g;
  if ($input0 =~ /^[0-9a-f]{32}[,0-9a-f]*$/) {
    my $atag = "<a href=\"whget.cgi/$input0/\">";
    $row[3] .= "($atag<code>".substr($input0,0,8)."</code></a>)";
  }

  my $class = 'queued';
  $class = 'running' if length $row[7] && !length $row[13];
  $class = 'success' if $row[13];
  $class = 'fail' if length $row[13] && !$row[13];
  $class = 'fail' if !length $row[7] && length $row[8];
  print "<tr class=\"$class\">\n";
  my $x = -1;
  print map { ++$x; "<td valign=top class=\"col$x\">$_</td>\n" } @row;
  print "</tr>\n";
}
print q{
</table>
};

if ($limit)
{
  my $showmore = $show*2;
  print "<p>";
  print "<a href=\"mrindex.cgi?show=$showmore\">show $showmore</a> | ";
  print "<a href=\"mrindex.cgi?showall=1\">show all</a></p>";
}

print q{
</body>
</html>
};
