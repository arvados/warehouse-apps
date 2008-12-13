#!/usr/bin/perl

use DBI;
do '/etc/warehouse/warehouse-server.conf';

my $dbh = DBI->connect(@$Warehouse::Server::DatabaseDSN);
die $DBI::errstr if !$dbh;

$dbh->do ("
  create table manifests
  (
   name char(128) not null primary key,
   mkey text not null,
   verified timestamp
  )
  ");
