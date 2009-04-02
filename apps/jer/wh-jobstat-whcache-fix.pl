#!/usr/bin/perl
use strict;
use warnings;

# this fixer does these things:
# any jobs within the database that report 0 nodes are tested against the warehouse

use DBI;
use Warehouse;

sub release_time;

my $debuggery = 1;

# create the objects
my $dbh = DBI->connect("DBI:mysql:whcache:localhost:3306","www1","a37hf92ktg")
	or die "Can't connect to cache db: $DBI::errstr\n"; 
my $whc = new Warehouse;

# find all jobs with no nodes
my $sth = $dbh->prepare("select id from whjobstat where nodes=0;");
$sth->execute;

# compare with values in the warehouse
my $uh = $dbh->prepare( q{ update whjobstat set nodes=? where id=?; });
printf ("Checking zero-node jobs:\n");
while (my ($id) = $sth->fetchrow_array()) {
	my $job_list = $whc->job_list (id_min => $id, id_max => $id);
	my $nodes = $whc->_nodelist_to_nnodes ($job_list->[0]->{nodes});
	if ($nodes > 0) {	
		$uh->execute($nodes,$id);
	}
	print ("id=$id nodes=$nodes debug=\"".$job_list->[0]->{nodes}."\"\n");
}
$sth->finish;
$uh->finish;

# next step...?

$dbh->disconnect;
