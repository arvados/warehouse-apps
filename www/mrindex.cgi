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
      unix_timestamp(mrjob.finishtime)-unix_timestamp(mrjob.starttime),
      steps_todo,
      steps_done,
      steps_running,
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
print map ("<td>$_</td>\n", qw(JobID MgrID Rev Function Procs Nodes Knobs Start Finish Elapsed ToDo Done Run Success Output Meta OldLog));
print q{
</tr>
};
while (my @row = $sth->fetchrow)
{
  my ($jobid) = @row;
  for (@row) { $_ = escapeHTML($_); }
  for ($row[5]) { s/,/, /g; }
  for ($row[6]) { s/\n/<br>/g; s/,/, /g; s/=/ =/g; $_ = "<code><small>$_</small></code>"; }
  for ($row[8]) { s/.* /.../; }
  for ($row[9]) { $_ = "<b>$_</b>"; }
  $row[0] = "<a href=\"mrjob.cgi?id=$jobid\">$row[0]</a>";
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
  if ($input0 =~ /^[0-9a-f]{32}[,0-9a-f]*$/) {
    my $atag = "<a href=\"whget.cgi/$input0/\">";
    $row[3] .= "($atag<code>".substr($input0,0,8)."</code></a>)";
  }

  push @row, "<a href=\"mrlog.cgi?id=$jobid\">log</a>";
  print "<tr>\n";
  print map ("<td valign=top>$_</td>\n", @row);
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
