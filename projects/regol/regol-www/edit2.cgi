#!/usr/bin/perl
# -*- mode: perl; perl-indent-level: 2; -*-

use strict;
use DBI;
use CGI ':standard';

do './config.pl' or die;

my $q = new CGI;

if ($q->param('submit') eq 'Delete')
{
  $main::dbh->do ("update job set wantredo_nnodes=null, wantredo_photons=null
		   where id=? and warehousename=?",
		  undef,
		  $q->param ('id'),
		  $q->param ('warehousename'));
}
else
{
  $main::dbh->do ("update job set wantredo_nnodes=?, wantredo_photons=?
		   where id=? and warehousename=?",
		  undef,
		  $q->param ('nnodes'),
		  $q->param ('photons'),
		  $q->param ('id'),
		  $q->param ('warehousename'));
}

print $q->redirect ("./");
