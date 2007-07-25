#!/usr/bin/perl

use strict;
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
<h2><a href="mrindex.cgi">mapreduce jobs</a> / new</h2>

<form method=post action="mrnew2.cgi">
Revision:<br>
<select size=8 name=revision>
};

my $log = `svn log '$main::svn_repos'`;
my $selected = "selected";
foreach my $logentry (split("------------------------------------------------------------------------\n", $log))
{
  if ($logentry =~ /^r([0-9]+)/)
  {
    my $revision = $1;
    my ($line1, $msg) = split ("\n\n", $logentry, 2);
    my ($x, $committer, $date, $x) = split (/ \| /, $line1);
    $date =~ s/ \(.*//;
    print "\n<option value=\"$revision\" $selected>".escapeHTML("r$revision $date ($committer) $msg")."</option>";
    $selected = "";
  }
}

print q{
</select>
<br>
<br>
Map/reduce function:
<br>
<select size=8 name=mrfunction>
};

opendir D, "../mapreduce" or die "Can't open mapreduce dir";
foreach (sort `svn ls '$main::svn_repos/mapreduce/'`)
{
  if (/^mr-([-_\w\.]+)$/)
  {
    print "<option value=\"".escapeHTML($1)."\">".escapeHTML($1)."</option>\n";
  }
}
closedir D;

print q{
</select>
<br>
<input type=submit value="Next">
</form>
</body>
</html>
};
