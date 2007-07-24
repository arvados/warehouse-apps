#!/usr/bin/perl

use strict;
use MogileFS::Client;
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
    left join mrjobstep on mrjob.id=mrjobstep.jobid and mrjobstep.finishtime is null
    group by mrjob.id
    order by mrjob.id desc");
$sth->execute or die $dbh->errstr;

print q{
<table>
<tr>
};
print map ("<td>$_</td>\n", qw(JobID MgrID Rev Function Procs Nodes Knobs Start Finish Elapsed Steps2Go Success));
print q{
</tr>
};
while (my @row = $sth->fetchrow)
{
  print "<tr>\n";
  print map ("<td>".escapeHTML($_)."</td>\n", @row);
  print "</tr>\n";
}
print q{
</table>
</body>
</html>
};
