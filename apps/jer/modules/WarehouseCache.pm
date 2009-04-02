package WarehouseCache;
use strict;

use Warehouse;
use DBI;
use Date::Parse;
require 'whcache-db-auth.pl' 
	or die ("Configuration file not found.  Please edit the whcache-db-auth.pl file before using WarehouseJobGraph.");

our $dbh = DBI->connect(main::dsn_vars())
	or die "Can't connect to cache db: $DBI::errstr\n";

our $whc; #= new Warehouse;

# my $whc = new WarehouseCache;
sub new {
	my $class = shift;
	my $self = {};
	$self->{silent}=1;
	$self->{debug}=0;
	$self->{job_expires}=604800; # age in seconds of a job before we no longer ask the warehouse for updated information
	$self->{start_times}={}; # an array full of starttime_s values
	$self->{job_list_statistics} = {};
  bless ($self, $class);
  return $self;
}

# examples:
# ref-to-hash $whc->job_list(finishtime_min=>1182994803, starttime_max=1185318781)
# ref-to-hash $whc->job_list(id_min=>1000, id_max=1100)
# ref-to-hash $whc->job_list(id=1500)
sub job_list { 
	my $self = shift;
	my %what = @_;
	my @conditions;
	if ($what{id}) { push @conditions, 'id = ' . int($what{id}); } 
		else {
			if ($what{id_min}) { push @conditions, 'id >= ' . int($what{id_min}); }
			if ($what{id_max}) { push @conditions, 'id <= ' . int($what{id_max}); }
			if ($what{starttime_min}) { push @conditions, 'starttime >= ' . int($what{starttime_min}); }
			if ($what{starttime_max}) { push @conditions, 'starttime <= ' . int($what{starttime_max}); }
			if ($what{finishtime_min}) { push @conditions, 'finishtime >= ' . int($what{finishtime_min}); }
			if ($what{finishtime_max}) { push @conditions, 'finishtime <= ' . int($what{finishtime_max}); }
			if ($what{bottom}) { push @conditions, 'bottom is not null'; }
		}
	my $sql = 'select * from whjobstat ';
	if (scalar @conditions > 0) {	$sql .= 'where '. join(' and ',@conditions); }
	my $sth = $dbh->prepare( $sql .';' );
	$sth->execute;	
	$self->{job_list_statistics} = {};
	$self->{job_list} = {};	
	$self->{job_index} = [];
	while (my $job = $sth->fetchrow_hashref()) {
		$self->{job_list}->{$job->{id}} = $job;
		push @{$self->{job_index}}, $job->{id};
	} 	
	$sth->finish;
	return $self->{job_list};
}

# $whc->update();
# Performs Warehouse retrival and update of 'brick' solutions
sub update {
	my $self = shift;
	$whc = new Warehouse;
	$self->_update_warehouse();
	$self->_update_solve();
}

# job 'bricking' for grahical display with WarehouseJobGraph package
sub _update_solve {
	my $self = shift;
	$self->{job_index} = [];
	$self->{job_list} = {};
	# find some jobs to solve
	my $sth = $dbh->prepare( q{ 
		select id, starttime, finishtime, nodes, bottom, mrfunction from whjobstat
		where starttime is not null
		and finishtime is not null
		order by starttime;
	} );
	$sth->execute;
	# load the works into an array
	if ($self->{debug} || !$self->{silent}) { print ("Loading jobs from database...\n"); }
	while (my $job = $sth->fetchrow_hashref()) {
		$self->{job_list}->{$job->{id}} = $job;
		push @{$self->{job_index}}, $job->{id};
	}	
	$sth->finish;
	my @jobs = @{$self->{job_index}};
	$self->{job_count} = scalar @{$self->{job_index}} - 1;
	if ($self->{debug} || !$self->{silent}) { print ("Finished loading ".$self->{job_count}." jobs from database.\n"); }
	my $then = time();
	for my $j (0 .. $self->{job_count}) {
		my $pct = int((($j * 100) / $self->{job_count}) + .5);
		if (!$self->{silent} || $self->{debug}) { print "\rStacking jobs, $pct\% complete... "; }			
		if ($self->{debug}) { print "\n"; }
		$j = $jobs[$j];
		unless (defined($self->{job_list}->{$j}->{bottom})) {
			$self->{job_list}->{$j}->{bottom} = $self->top_brick($self->{job_list}->{$j}->{id}) + 1;
			$self->{job_list}->{$j}->{solved} = 1;
			if ($self->{debug}) { print "[".$j."]"; }
			#what can i fit on the right side?
			for (my $i=0;$i<=$self->{job_count};$i++) {
				if (!defined($self->{job_list}->{$jobs[$i]}->{bottom}) && $self->{job_list}->{$jobs[$i]}->{starttime} > $self->{job_list}->{$j}->{finishtime}) {
					$j = $jobs[$i];
					$self->{job_list}->{$j}->{bottom} = $self->top_brick($self->{job_list}->{$j}->{id}) + 1;
					$self->{job_list}->{$j}->{solved} = 1;					
					if ($self->{debug}) { print "[id=".$j." height=".$self->{job_list}->{$j}->{bottom}."]\n"; }
				}
			}
		}
		if (time() - $then > 300) { # five minutes elapsed, autosave database
			$then = time();
			$self->_update_solve_save();
		}
	}
	$self->_update_solve_save();
	return 1;
}

# update the database with entries
sub _update_solve_save {
	my $self = shift;
	my $uh = $dbh->prepare( q{ update whjobstat set bottom=? where id=?; });
	if ($self->{debug} || !$self->{silent}) { print "\nUpdating database...\n"; }
	for (keys %{$self->{job_list}}) {
		if (defined($self->{job_list}->{$_}->{solved})) {
			$uh->execute($self->{job_list}->{$_}->{bottom}, $self->{job_list}->{$_}->{id})
				or die "Insert failed: $DBI::errstr";
			delete $self->{job_list}->{$_}->{solved};
		}
	}
	$uh->finish;
	return 1;
}

# returns highest bricked job under another job
# nodes top_brick (id)
sub top_brick {
	my $self = shift;
	my $job = $self->{job_list}->{$_[0]};
	my $highpoint = 0;
	for (0 .. $self->{job_count}) {
		my $j = $self->{job_list}->{$self->{job_index}->[$_]};
		if ($j->{bottom} && $j->{bottom} + $j->{nodes} > $highpoint) {
			if ($job->{finishtime} > $j->{starttime} && $job->{starttime} < $j->{finishtime}) { $highpoint = $j->{bottom} + $j->{nodes}; }
		}
	}
	return $highpoint;
}

# fetches new information from the Warehouse and adds it to the cache
sub _update_warehouse {
	my $self = shift;
	my $job_expires=$self->{job_expires};	
# *** Part 1 - Adding new jobs to the cache database ***
	my ($high_id, $high_time) = $dbh->selectrow_array("select max(id), max(finishtime) from whjobstat;");
	$high_time -= $job_expires;
	if ($self->{debug} || !$self->{silent}) { print "Loading new data from Warehouse...\n";	}	
	$self->{job_list} = $whc->job_list (id_min => ($high_id ? $high_id+1: 0));	# call the warehouse	
	my $uh = $dbh->prepare( q{ insert into whjobstat values(?, ?, ?, ?, ?, ?); });
	for (0 .. $#{$self->{job_list}}) {
		my $jobref = $self->_preen_job ($self->{job_list}->[$_]);				
		if ($self->{debug}) {
			printf ("Adding new job: id=%d nodes=%d starttime=%d finishtime=%d mrfunction=%s\n", $jobref->{id}, $jobref->{nodes}, $jobref->{starttime} || 0, $jobref->{finishtime}, $jobref->{mrfunction} || '');
		}
		$uh->execute( $jobref->{id}, $jobref->{starttime}, $jobref->{finishtime}, $jobref->{nodes}, undef, $jobref->{mrfunction} );	
	}
	$uh->finish;
# *** Part 2 - Updating existing database entries that may have missing info ***
	my $sth = $dbh->prepare("select id from whjobstat where ((starttime > $high_time or finishtime > $high_time) or (starttime is null and finishtime is null)) and (nodes=0 or nodes is null or starttime is null or finishtime is null) order by id;");
	$uh = $dbh->prepare( q{ update whjobstat set nodes=?, starttime=?, finishtime=?, mrfunction=? where id=?; });
	$sth->execute;
	while (my ($id) = $sth->fetchrow_array()) {
		my $jobref = $self->_preen_job($id);		
		if ($self->{debug}) {
			printf ("Updated job: id=%d nodes=%d starttime=%d finishtime=%d mrfunction=%s\n", $jobref->{id}, $jobref->{nodes}||0, $jobref->{starttime}||0, $jobref->{finishtime}||0, $jobref->{mrfunction});
		}
		$uh->execute($jobref->{nodes}, $jobref->{starttime}, $jobref->{finishtime}, $jobref->{mrfunction}, $jobref->{id});
	}
	$sth->finish;
	$uh->finish;
}

# returns a hash of formatted values, based either on information supplied, or from the warehouse
# hashref _preen_job( scalar job-id )
# hashref _preen_job( hash job )
sub _preen_job {
	my $self = shift;
	my $target = shift;
	my $dbjob = {};
	my $whjob = (ref($target) ? $target : $self->wh_job($target));
	$dbjob->{id} = $whjob->{id};
	$dbjob->{nodes} = $whc->_nodelist_to_nnodes ($whjob->{nodes});
	$dbjob->{finishtime} = $whjob->{'finishtime_s'} ? ($self->node_release_time($whjob->{id}) || $self->guess_node_release_time($whjob->{id})) : undef;
	$dbjob->{starttime} = $whjob->{'starttime_s'};
	$dbjob->{mrfunction} = $whjob->{mrfunction};
	return $dbjob;
}

# aquire the node-release time of a job (based on the metakey data) or undef if the job has never finished
# finishtime_s release_time( job-id )
sub node_release_time {
	my $self = shift;
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
# extreme debuggin' only:
#		print $$dataref;
	}
	return $releasetime;
}

# returns the closest starttime_s of a nearby job (within 5 min), if available
# finishtime_s guess_release_time( job-id )
sub guess_node_release_time {
	my $self = shift;
	my $job = $self->wh_job(shift);
	my $old_finishtime = $job->{'finishtime_s'};
	my $new_finishtime = $old_finishtime - 301;
	unless (scalar keys %{$self->{start_times}} > 0) {
		my $sth = $dbh->prepare( q{ select id, starttime from whjobstat order by starttime; } );
		$sth->execute; 
		while (my @row = $sth->fetchrow_array()) {
			if (defined($row[1])) { $self->{start_times}->{$row[0]}=$row[1]; }
		}
		$sth->finish;
	}	
	for (values %{$self->{start_times}}) {
		if ($_<=$old_finishtime && $_>$new_finishtime) {
			$new_finishtime=$_;
		}
	}
	if ($new_finishtime != $old_finishtime - 301) {
		if ($self->{debug}) { print "id=".$job->{id}." finishtime_s=$old_finishtime finishtime_guess=$new_finishtime\n"; }
		return $new_finishtime;
	} else {
		return $old_finishtime;
	}
}

sub wh_job {
	my $self = shift;
	my $id = int(shift) 
		or return undef;
	my $job = $whc->job_list (id_min => $id, id_max => $id);
	return $job->[0];
}

sub job_statistic {
	my $self = shift;
	my $shape = shift;
	my $column = shift;	
	return undef unless (defined($self->{job_list}) && $shape =~ /^(min|max|count)$/);
	if (defined($self->{job_list_statistics}->{$shape}->{$column})) {
		return $self->{job_list_statistics}->{$shape}->{$column};
	}
	#add the requested statistic
	$self->{job_list_statistics}->{count}->{$column} = 0;
	$self->{job_list_statistics}->{max}->{top} ||= 0;
	for my $job (values %{$self->{job_list}}) {
		if (defined($job->{$column})) {
			$self->{job_list_statistics}->{min}->{$column} ||= $job->{$column};
			$self->{job_list_statistics}->{max}->{$column} ||= $job->{$column};
			if ($self->{job_list_statistics}->{min}->{$column} > $job->{$column}) {
				$self->{job_list_statistics}->{min}->{$column} = $job->{$column};
			} elsif ($self->{job_list_statistics}->{max}->{$column} < $job->{$column}) {
				$self->{job_list_statistics}->{max}->{$column} = $job->{$column};
			}
			$self->{job_list_statistics}->{count}->{$column}++;
		} elsif ($column eq 'top' && $self->{job_list_statistics}->{max}->{top} < ($job->{bottom}||0)+($job->{nodes}||0)) {
			$self->{job_list_statistics}->{max}->{top} = $job->{bottom}+$job->{nodes};
		}
	}
	return $self->{job_list_statistics}->{$shape}->{$column};
}

END {
	$dbh->disconnect;
}
1;

