#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;

use DBI;
use Warehouse;
use Date::Parse;

require "whcache-db-auth.pl";

sub release_time;
sub guess_release_time;

# seconds before jobs expire, i.e. are no longer updated by this software.  7776000 = 90 days, 607800 = 7 days
my $job_expires=604800;

my $debuggery = 1;
my $gstarttimes = {}; # an array full of starttime_s values

# create the objects
my $dbh = DBI->connect(dsn_vars())
	or die "Can't connect to cache db: $DBI::errstr\n"; 
my $whc = new Warehouse;

# *** Part 1 - Adding new jobs to the cache database ***

# get the highest known job_id in cache, and the most recent finished job time
my ($high_id, $high_time) = $dbh->selectrow_array("select max(id), max(finishtime) from whjobstat;");
$high_time -= $job_expires;

# fill our warehouse with new jobs
my $joblist = $whc->job_list (id_min => ($high_id ? $high_id+1: 0));


# toss new jobs into the database
my $uh = $dbh->prepare( q{ insert into whjobstat values(?, ?, ?, ?, ?, ?); });
foreach my $job (@$joblist) {
	my $jobref = get_job_new ($job);
	$uh->execute( $jobref->{id}, $jobref->{starttime}, $jobref->{finishtime}, $jobref->{nodes}, undef, $jobref->{mrfunction} );	
	printf ("Added new job: id=%d nodes=%d starttime=%d finishtime=%d mrfunction=%s\n", $jobref->{id}, $jobref->{nodes}, $jobref->{starttime} || 0, $jobref->{finishtime}, $jobref->{mrfunction});
}
$uh->finish;

# *** Part 2 - Updating existing database entries that may have missing info ***

# update any jobs that may have missing information
my $sth = $dbh->prepare("select id from whjobstat where ((starttime > $high_time or finishtime > $high_time) or (starttime is null and finishtime is null)) and (nodes=0 or nodes is null or starttime is null or finishtime is null) order by id;");
$uh = $dbh->prepare( q{ update whjobstat set nodes=?, starttime=?, finishtime=?, mrfunction=? where id=?; });
$sth->execute;
while (my ($id) = $sth->fetchrow_array()) {
	my $jobref = get_job_update($id);
	$uh->execute($jobref->{nodes}, $jobref->{starttime}, $jobref->{finishtime}, $jobref->{mrfunction}, $jobref->{id});
	printf ("Updated job: id=%d nodes=%d starttime=%d finishtime=%d mrfunction=%s\n", $jobref->{id}, $jobref->{nodes}||0, $jobref->{starttime}||0, $jobref->{finishtime}||0, $jobref->{mrfunction});
}
$sth->finish;
$uh->finish;

$dbh->disconnect;

# *** Program Ends ***

# *** Global Functions ***

# does a wh lookup, then returns a hash of formatted values
# hash get_job_update( scalar job-id )
sub get_job_update {
	my $id = shift;
	my $whjob = $whc->job_list (id_min => $id, id_max => $id)
	 or return undef;
	my $dbjob = {};
	$dbjob->{id} = $id;
	# die ("id=$id nodes=".$whjob->[0]->{nodes});
	$dbjob->{nodes} = $whc->_nodelist_to_nnodes ($whjob->[0]->{nodes});
	$dbjob->{finishtime} = $whjob->[0]->{'finishtime_s'} ? (release_time($whjob->[0]->{id}) || (guess_release_time($whjob->[0]->{id} || undef))) : undef;  # some early jobs have no metadata, hence -1
	$dbjob->{starttime} = $whjob->[0]->{'starttime_s'}; 
	$dbjob->{mrfunction} = $whjob->[0]->{mrfunction};
	return $dbjob;
}

# same as above, except you pass the warehouse data, instead of looking it up.
# hash get_job_new( hash job )
sub get_job_new {
	my $whjob = shift;
	my $dbjob = {};
	$dbjob->{id} = $whjob->{id};
	$dbjob->{nodes} = $whc->_nodelist_to_nnodes ($whjob->{nodes});
	$dbjob->{finishtime} = $whjob->{'finishtime_s'} ? (release_time($whjob->{id}) || (guess_release_time($whjob->{id} || undef))) : undef;  # some early jobs have no metadata, hence -1
	$dbjob->{starttime} = $whjob->{'starttime_s'};
	$dbjob->{mrfunction} = $whjob->{mrfunction};
	return $dbjob;
}

# aquire the node-release time of a job (based on the metakey data) or undef if the job has never finished
# finishtime_s release_time( job-id )
sub release_time {
	my $job;
	eval {
		$job = $whc->job_stats(shift)
			or return undef;
	};
	return undef if ($?  # bug in /usr/share/perl5/Warehouse.pm line 640, 404 error if a metakey exists, but the meta data does not
		or !defined($job->{metakey}));
	my $releasetime;
	my $s = new Warehouse::Stream (whc => $whc, hash => [split (",", $job->{metakey})]);
	$s->rewind();
	while (my $dataref = $s->read_until (undef, "\n")) {
		if ($$dataref =~ /^(\S+) \d+ \d+  release job allocation\n/) {
			$releasetime = $1;
			$releasetime =~ s/_/ /;
			$releasetime = str2time ($releasetime);
			last;
		}
#		print $$dataref;
	}
	return $releasetime;
}

# returns the closest starttime_s of a nearby job (within 5 min), if available
# finishtime_s guess_release_time( job-id )
sub guess_release_time {
	my $id = (shift)+0;
	my $job = $whc->job_list (id_min => $id, id_max => $id);
	my $old_finishtime = $job->[0]->{'finishtime_s'};
	my $new_finishtime = $old_finishtime - 301;
	unless (scalar keys %$gstarttimes > 0) {
		my $sth = $dbh->prepare( q{ select id, starttime from whjobstat order by starttime; } );
		$sth->execute; 
		while (my @row = $sth->fetchrow_array()) {
			if (defined($row[1])) { $gstarttimes->{$row[0]}=$row[1]; }
		}
		$sth->finish;
	}	
	for (values %$gstarttimes) {
		if ($_<=$old_finishtime && $_>$new_finishtime) {
			$new_finishtime=$_;
		}
	}
	if ($new_finishtime != $old_finishtime - 301) {
		if ($debuggery) { print "id=$id finishtime_s=$old_finishtime finishtime_guess=$new_finishtime\n"; }
		return $new_finishtime;
	} else {
		return $old_finishtime;
	}
}
