#!/usr/bin/perl
# -*- mode: perl; perl-indent-level: 2; -*-

use strict;
use DBI;
use CGI ':standard';

do './config.pl' or die;

my $q = new CGI;
print $q->header;

print q{
<html>
<head>
<title>regol</title>
</head>
<body>
<h2>wanttodo</h2>
<pre>};

my $fmt = "%-15s %4s %-12.12s %4s %-33.33s %5s %7s %s\n";
printf ($fmt, qw(warehouse job function rev input nodes photons ...));

my $sth = $main::dbh->prepare ("select * from job
				where wantredo_nnodes is not null");
$sth->execute ()
    or die DBI->errstr;
while (my $job = $sth->fetchrow_hashref)
{
  my $editlink = "<a href=\""
      . escapeHTML("edit.cgi?warehousename="
		   . $job->{warehousename}
		   . "&id="
		   . $job->{id})
      . "\">edit</a>";
  printf ($fmt,
	  $job->{warehousename}, $job->{id},
	  $job->{mrfunction}, $job->{revision}, $job->{inputkey},
	  $job->{wantredo_nnodes}, $job->{wantredo_photons},
	  $editlink);
}

print q{</pre>
<h2>todo</h2>
<pre>};

my $fmt = "%-15s %6s %6s %-20s\n";
printf ($fmt, qw(warehouse origid newid submittime));

my $sth = $main::dbh->prepare ("select * from todo
				order by warehousename, id_orig");
$sth->execute ()
    or die DBI->errstr;
while (my $job = $sth->fetchrow_hashref)
{
  printf ($fmt,
	  $job->{warehousename}, $job->{id_orig}, $job->{id_new},
	  $job->{submittime});
}

print q{</pre>
<h2>available</h2>
<pre>};

$fmt = "%-15s ; %4s ; %-30.30s ; %-12.12s ; %4s ; %5s ; %-33.33s ; %-33.33s ; %-20s ; %10s ; %s\n";
printf ($fmt, qw(warehouse job function knobs rev nodes input output starttime elapsed ...));

my $sth = $main::dbh->prepare ("select *,
 unix_timestamp(finishtime)-unix_timestamp(starttime) elapsed
 from job order by starttime desc, id desc");
$sth->execute ()
    or die DBI->errstr;
while (my $job = $sth->fetchrow_hashref)
{
  my $addme = "";
  if ($job->{success} && !defined $job->{wantredo_nnodes})
  {
    $addme = "    <a href=\""
	. escapeHTML("edit2.cgi?warehousename="
		     . $job->{warehousename}
		     . "&id="
		     . $job->{id}
		     . "&nnodes=0&photons=1")
	. "\">add</a>";
  }
  elsif (defined $job->{wantredo_nnodes})
  {
    $addme = "todo";
  }
  if ($job->{nodes} !~ /^\d+$/)
  {
    my $n = 0;
    local $_ = $job->{nodes};
    while (s/^[^\[,]+(?:\[([-,\d]+)\])?[ ,]*//)
    {
      foreach (split (/,/, $1))
      {
	if (/-/)
	{
	  $n += $' - $` + 1;
	}
	else
	{
	  $n ++;
	}
      }
    }
    $job->{nodes} = $n;
  }
  $job->{knobs} =~ s/\n/ /g;
  printf ($fmt,
	  escapeHTML ($job->{warehousename}),
	  $job->{id},
	  $job->{mrfunction},
	  $job->{knobs},
	  $job->{revision},
	  $job->{nodes},
	  $job->{inputkey},
	  $job->{outputkey},
	  $job->{starttime},
	  $job->{success} ? $job->{elapsed} : "",
	  $addme);
}

print q{</pre>
<h2>warehouses</h2>
<pre>};

printf ("%-15s %12s %s\n", qw(name lastupdate servers));

my $sth = $main::dbh->prepare ("select name, servers, unix_timestamp(now())-unix_timestamp(lastupdate) lastupdate_sec from warehouse order by name");
$sth->execute ()
    or die DBI->errstr;
while (my $w = $sth->fetchrow_hashref)
{
  printf ("%-15s %12d %s\n",
	  escapeHTML ($w->{name}),
	  escapeHTML ($w->{lastupdate_sec}),
	  escapeHTML ($w->{servers}));
}

print q{</pre>
</body>
</html>
}
