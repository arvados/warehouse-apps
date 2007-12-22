#!/usr/bin/perl
# -*- mode: perl; perl-indent-level: 2; -*-

use strict;
use DBI;
use CGI ':standard';

do './config.pl' or die;
do './functions.pl' or die;

my $q = new CGI;
print $q->header;

my $job = $main::dbh->selectrow_hashref
    ("select * from job where id=? and warehousename=?",
     undef,
     $q->param ('id'),
     $q->param ('warehousename'));

my %job = %$job;

$job{knobs} = unescape ($job{knobs});
map { $job{$_} = escapeHTML ($job{$_}) } keys %job;

print qq{
<html>
<head>
<title>regol: edit</title>
</head>
<body>
<h2>job $job{id} on $job{warehousename}</h2>
<form action="edit2.cgi" method="post">
<input type=hidden name=id value="$job{id}">
<input type=hidden name=warehousename value="$job{warehousename}">
<table>
<tr>
 <td valign=top align=right>function</td>
 <td valign=top><b>$job{mrfunction}</b></td>
</tr>
<tr>
 <td valign=top align=right>input key</td>
 <td valign=top><b>$job{inputkey}</b></td>
</tr>
<tr>
 <td valign=top align=right>knobs</td>
 <td valign=top><b>$job{knobs}</b></td>
</tr>
<tr>
 <td valign=top align=right>number of nodes to allocate</td>
 <td valign=top><input type=text name=nnodes value="$job{wantredo_nnodes}" /></b></td>
</tr>
<tr>
 <td valign=top align=right>number of photons to bid</td>
 <td valign=top><input type=text name=photons value="$job{wantredo_photons}" /></b></td>
</tr>
<tr>
 <td></td>
 <td><input type=submit name=submit value=Save> &nbsp; <input type=submit name=submit value=Delete></td>
</tr>
</table>
</form>
</body>
</html>
};
