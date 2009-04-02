package WarehouseToolbox;
use strict;
use warnings;
use Warehouse;

my $whc = new Warehouse;

#my $job_list = { map{$_->{id}=>$_} @{$whc->job_list(id_min=>10000,id_max=>11000)} };
my $job_list; # = { map{$_->{id}=>$_} @{$whc->job_list()} };
my %output_to_id;
my %input_to_id;
my %knob_to_id;
my %testedkeys;
my %subkeys;
my %subkeysize;
my $cachedref = { name=>0, ptr=>undef };

sub job_list_load { $job_list = { map{$_->{id}=>$_} @{$whc->job_list()} }; }

# my $job_list = WarehouseToolbox::job_list;
# I've only ever had to use this for debugging.  It's a bad thing to do.
sub job_list {
	job_list_load() unless $job_list;
	return $job_list;
}

# my @jobs = jobs_that_output($hashkey);
sub jobs_that_output {
	my $key = shift;
	unless (%output_to_id) {
		job_list_load() unless $job_list;
		map { push @{$output_to_id{ $_->{outputkey} }}, $_->{id} } values %{$job_list};
	}
	return () unless ($output_to_id{$key});
	return @{$output_to_id{$key}};
}

# my @jobs = jobs_that_really_output($hashkey);
# same as above, except it makes sure jobs don't input or knob the output
sub jobs_that_really_output {
	my $key = shift;
	unless (%output_to_id) {
		job_list_load() unless $job_list;
		map { push @{$output_to_id{ $_->{outputkey} }}, $_->{id} } values %{$job_list};
	}
	return () unless ($output_to_id{$key});
	my %jobs_that_input = map { $_ => 1 } (jobs_that_input($_), jobs_that_knob($_));
	return grep { !$jobs_that_input{$_} } @{$output_to_id{$key}};
}

# my @jobs = jobs_that_input($hashkey);
sub jobs_that_input {
	my $key = shift;
	unless (%input_to_id) {
		job_list_load() unless $job_list;
		map { push @{$input_to_id{ $_->{inputkey} }}, $_->{id} } values %{$job_list};		
	}
	return () unless ($input_to_id{$key});
	return @{$input_to_id{$key}};
}

# my @jobs = jobs_that_input_or_knob($hashkey);
sub jobs_that_knob {
	my $key = shift;
	unless (%knob_to_id) {
		job_list_load() unless $job_list;
		for my $j (values %{$job_list}) {
			map { push @{$knob_to_id{$_}}, $j->{id} } ($j->{knobs} =~ /([0-9a-f]{32})/g);
		}
	}
	return () unless ($input_to_id{$key});
	return @{$input_to_id{$key}};
}

# my @jobs = parents_of_job($jobid);
sub parents_of_job {
	my $id = shift;
	my %parentkeys = all_inputkeys_for($id);
	my %parents;
	for my $key (keys %parentkeys) {
		my $key_ok = test_keys($key);
		for (jobs_that_output($key)) {
			unless ($parents{$_}==0) {	$parents{$_} = $key_ok;	}
		}
	}
	return wantarray ? keys %parents : {%parents};
}

# my @jobs = children_of_job($jobid);
sub children_of_job {
	my $id = shift;
	my %childkeys = main::outputkeys_for($id);
	my %kids;
	for my $key (keys %childkeys) {
		my $key_ok = test_keys($key);
		for (jobs_that_input($key)) {
			unless ($kids{$_}==0) { $kids{$_} = $key_ok;	}
		}
	}
	return wantarray ? keys %kids : {%kids};
}

# my @input_keys_and_knob_keys = all_inputkeys_for($jobid);
sub all_inputkeys_for {
	my $id = shift;
	job_list_load() unless $job_list;
	my @keys = (($job_list->{$id}->{'knobs'}.' '.$job_list->{$id}->{'inputkey'}) =~ /([0-9a-f]{32})/g);
	return wantarray ? @keys : { map { $_ => test_keys($_) } @keys  };
}

# my @input_keys = inputkeys_for($jobid);
sub inputkeys_for {
	my $id = shift;
	job_list_load() unless $job_list;
	my @keys = ($job_list->{$id}->{'inputkey'} =~ /([0-9a-f]{32})/g);
	return wantarray ? @keys : { map { $_ => test_keys($_) } @keys };
}
# my @knob_keys = knobkeys_for($jobid);
sub knobkeys_for {
	my $id = shift;
	job_list_load() unless $job_list;
	my @keys = ($job_list->{$id}->{'knobs'} =~ /([0-9a-f]{32})/g);
	return wantarray ? @keys : { map { $_ => test_keys($_) } @keys };
}

# my @output_keys = all_outputkeys_for($jobid);
sub outputkeys_for {
	my $id = shift;
	job_list_load() unless $job_list;
	my @keys = ($job_list->{$id}->{'outputkey'} =~ /([0-9a-f]{32})/g);
	return wantarray ? @keys : { map { $_ => test_keys($_) } @keys };
}

sub subkeys_of {
	my $key = shift;
	unless ($subkeys{$key}) {
		my $bref = fetch_block($key);
		return () unless ($bref);
		$subkeys{$key} = { $$bref =~ /([0-9a-f]{32})\+(\d+)/g };  # hash => size
	}
	return wantarray ? (keys %{$subkeys{$key}}) : $subkeys{$key};
}

# TODO delete or rewrite with cacheing like test_keys
sub test_subkeys_of {
	my @keys = subkeys_of($_[0]);	
	return {map { $_ => test_key($_) } @keys };
}

# $ok = test_key($hashkey);
# performs a fetch_block on a hash key to see if it's fetchable
sub test_key {
	my $key = shift;
	return $testedkeys{$key} if (defined($testedkeys{$key}));
	my $bref = fetch_block($key);
	$testedkeys{$key} = ($bref ? 1 : 0);
	return $testedkeys{$key};
}

# $ok = test_keys($hashkey);
# same as test_key, except that it tests nested subkeys, too
sub test_keys {
	my $key = shift;
	return $testedkeys{$key} if ($testedkeys{$key});
	$testedkeys{$key} = 1;
	unless ($subkeys{$key}) {
		my $bref = fetch_block($key);
		if (!$bref) {
			$testedkeys{$key} = 0;
			return 0;
		}
		$subkeys{$key} = [$$bref =~ /([0-9a-f]{32})/g];
	}	
	for my $subkey (@{$subkeys{$key}}) {
		if (!test_key($_)) {
			$testedkeys{$key} = 2;
			$testedkeys{$_} = 0;
		} else {
			$testedkeys{$_} = 1;
		}
	}
	return $testedkeys{$key};
}

sub fetch_block {
	my $key = shift;
	unless ($cachedref->{name} eq $key) {
		$cachedref->{ptr} = $whc->fetch_block_ref($key, {nowarn=>1});
		$cachedref->{name} = $key;
	}
	return $cachedref->{ptr};
}

# my $whence = whence($job_id || $hash_key);
# $whence { 'jobs' => $jobs, 'hashes' => $hashes, 'inputs' => $inputs, 'seconds' => $totaltime };
sub whence {
	local $_ = shift;
	my $query = /([0-9a-f]{32})/ ? $1 : int($_);
	return undef unless ($query);	
	my $whout = qx(whence $query);
	my $jobs = [$whout =~ /^\#(\d+)\@/gm];
	my $hashes = [$whout =~ /([0-9a-f]{32})/g];
	my $inputs = [$whout =~ /^([0-9a-f]{32})/gm];
	my $totaltime = 0;
	while ($whout =~ /--node-seconds = (\d+)/gm) { $totaltime+=$1; }
	return { 'jobs' => $jobs, 'hashes' => $hashes, 'inputs' => $inputs, 'seconds' => $totaltime };
}

# exported functions
sub main::fetch_job { return $job_list->{$_[0]}; }
sub main::fetch_block { return fetch_block($_[0]); }
sub main::job_exists { return ($job_list->{$_[0]} ? 1 : 0); }
sub main::jobs_that_output { jobs_that_output(@_) }
sub main::jobs_that_really_output { jobs_that_really_output(@_) }
sub main::jobs_that_input { jobs_that_input(@_) }
sub main::parents_of_job { parents_of_job(@_) }
sub main::children_of_job { children_of_job(@_) }
sub main::all_inputkeys_for { all_inputkeys_for(@_) }
sub main::inputkeys_for { inputkeys_for(@_) }
sub main::knobkeys_for { knobkeys_for(@_) }
sub main::outputkeys_for { outputkeys_for(@_) }
sub main::subkeys_of { subkeys_of(@_) }
sub main::test_subkeys_of { test_subkeys_of(@_) }
sub main::test_key { test_key(@_); }
sub main::test_keys { test_keys(@_); }

1;
