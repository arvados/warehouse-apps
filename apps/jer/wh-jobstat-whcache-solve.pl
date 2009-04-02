#!/usr/bin/perl
use strict;
use warnings;
use DBI;
require 'whcache-db-auth.pl';

# converts entries in cache db whjobstat to whjobstat_solved for displaying time-slices of process usage

#function declaration
sub brick_job;
sub top_brick;

my $debuggery = 1;

# create the objects & globals
my $dbh = DBI->connect(dsn_vars())
	or die "Can't connect to cache db: $DBI::errstr\n"; 

my $job_list = {}; # an array (huge) containing the job database
my $job_count; # = keys($job_list)
my @job_list_startorder; # a list of job id's in chronological order of starttime

my $brick_itt = 0; #itteration counter for the brick() function
my $brick_deep = 0; #itterative depth of brick()

# find some jobs to solve
my $sth = $dbh->prepare( q{ 
	select id, starttime, finishtime, nodes, bottom, mrfunction from whjobstat
	where starttime is not null
	and finishtime is not null
	order by starttime;
} );
$sth->execute;

# load the works into an array
if ($debuggery) { printf ("Loading jobs from database\n"); }
while (my $job = $sth->fetchrow_hashref()) {
	$job_list->{$job->{id}} = $job;
	push (@job_list_startorder, $job->{id});
} 
$sth->finish;
$job_count = keys(%{$job_list})-1;

brick_job();

my $uh = $dbh->prepare( q{ update whjobstat set bottom=? where id=?; });
my $pct = 0;
for (values %$job_list) {
	if (!defined($_->{solved})) {
		$uh->execute($_->{bottom}, $_->{id})
			or die "Insert failed: $DBI::errstr\n";
	}
	if ($debuggery) { 
		$pct++;
		print "\rUpdating database... ". int(($pct*100)/$job_count)."%  ";
	}
}

$uh->finish;
$dbh->disconnect;

exit;
# *** Program Ends ***

sub brick_job {
	my $id = shift;
	$brick_itt++;
	$brick_deep++;
	if ($debuggery) {
		if ($brick_itt>$job_count+10) { 		# stop me if i drone on
			die ("ABORT: too many brick itterations, max=".$job_count." itt=$brick_itt deep=$brick_deep\n");
		}
	}
	if (!defined($id)) { # if run without args it will go through the whole
		for (1 .. $job_count) {
			my $j = $job_list->{$job_list_startorder[$_]};
			if ($debuggery) { print "\rPlotting layout... ".int(($_ * 100) / $job_count).'% '; }
			if (!defined($j->{bottom})) { brick_job($j->{id}); }
		}
		if ($debuggery) { print "brick finished, $brick_itt steps completed.\n"; }
		return $id;
	}
	# drop a brick here
	$job_list->{$id}->{bottom} = top_brick($id) + 1;
	$job_list->{$id}->{solved} = 1;
	# find a spot on the right to drop another (i was thinking that i might be able to modifiy this line to include the 'cheat' functionality...)
	for (1 .. $job_count) {
		my $j = $job_list->{$job_list_startorder[$_]};
		if (!defined($j->{bottom}) && $j->{starttime} > $job_list->{$id}->{finishtime}) {
			brick_job($j->{id});
			last;
		}
	}
	$brick_deep--;
	return $id;
}

# returns highest bricked job under another job
# nodes top_brick (id)
sub top_brick {
	my $job = $job_list->{$_[0]};
	my $highpoint = 0;
	for (1 .. $job_count) {
		my $j = $job_list->{$job_list_startorder[$_]};
		if ($j->{bottom} && $j->{bottom} + $j->{nodes} > $highpoint) {
			if ($job->{finishtime} > $j->{starttime} && $job->{starttime} < $j->{finishtime}) { $highpoint = $j->{bottom} + $j->{nodes}; }
		}
	}
	return $highpoint;
}

