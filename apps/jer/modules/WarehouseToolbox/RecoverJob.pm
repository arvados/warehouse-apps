package RecoverJob;
use strict;
use warnings;
use lib "/usr/local/polony-tools/current/apps/jer/modules";
use WarehouseToolbox;

sub all_inputkeys_for { WarehouseToolbox::all_inputkeys_for(@_); }
sub outputkeys_for { WarehouseToolbox::outputkeys_for(@_); }
sub jobs_that_input { WarehouseToolbox::jobs_that_input(@_); }
sub jobs_that_knob { WarehouseToolbox::jobs_that_knob(@_); }
sub jobs_that_really_output { WarehouseToolbox::jobs_that_really_output(@_); }
sub test_keys { WarehouseToolbox::test_keys(@_); }

my $debug = 0;
my $verbose = 0;
my $match_first = 0;
my %output_modes;
my $ordered_output = 0; # arranges things into "steps" to take

my $uid = 0;
my @E;

# recoverjob($goalhash, $goaljobid, ...)
sub main::recoverjob {
	@E = ();
	my $returnstring = "";
	my $e = _spawn_e();
	for my $v (@_) {
		my @k = ();
		if (ref $v eq 'HASH') {
			$debug = 1 if $v->{'debug'};
			$verbose = 1 if $v->{'verbose'};
			$output_modes{batch} = 1 if $v->{'batch'};
			$output_modes{human} = 1 if $v->{'human'};
			$output_modes{portable} = 1 if $v->{'portable'};
			$match_first = 1 if $v->{'match-first'};
		} elsif ($v =~ /([0-9a-f]{32})/) {
			unless (test_keys($1) == 1) {
				$e->{hashes}->{$1} = 0;
			}
		} else {
			$e->{jobs}->{$v} = 0;
			@k = grep { test_keys($_) != 1 } all_inputkeys_for($v);
			map { $e->{hashes}->{$_} = 0 } @k;
		}
	}
	unless (keys %{$e->{hashes}}) {
		print "All specified jobs/hashes appear intact.\n" if ($output_modes{human} || $debug || $verbose);
		print "-\n" if $output_modes{batch};
		return ";\n" if $output_modes{portable};
		return 0;
	}
	print "searching for hashes: " . join(' ', keys %{$e->{hashes}}) . "\n" if ($verbose || $debug);
	$output_modes{batch} = 1 unless ($output_modes{human}||$output_modes{portable});
	push @E, $e;
	$e = _recover();
	_perl_obj_output($e) if $debug;
	_console_output($e) if $output_modes{human};
	_batch_output($e) if $output_modes{batch};
	return _portable_output($e) if $output_modes{portable};
	return 1;
}

sub _recover {
	my (@solutions);
	print 'called _recover():'."\n" if ($debug);
	while (@E) {
		my $e = shift @E;
		my $progress = 1;
		if ($debug || $verbose) {	print "checking entity: "; _explain_e($e); }
		while ($progress) {
			$progress = 0;
			my @hashes_i_need = grep { $e->{hashes}->{$_} == 0 } keys %{$e->{hashes}};
			for (@hashes_i_need) { $progress += _try_to_complete_hash($e, $_); }
			my @jobs_i_need = grep { defined $_ && $e->{jobs}->{$_} == 0 } keys %{$e->{jobs}};
			for (@jobs_i_need) { $progress += _try_to_complete_job($e, $_); }
		}
		unless (defined($e->{dispose})) {
			#should i push this to a "possible solutions" thing?			
			if ($debug || $verbose) {	print "accepted entity: "; _explain_e($e); }
			push @solutions, $e;
			return $e if ($match_first && !defined($e->{orphans}));
		}
	}
	# evaluate the best solution
	my @rank = sort {
		if (defined($a->{orphans}) == defined($b->{orphans})) {
				$a->{complexity} <=> $b->{complexity};
		} elsif(defined($a->{orphans})) { return 1; } else { return -1; }
	} @solutions;

	return undef unless @rank;
	return $rank[0];
}

sub _try_to_complete_hash {
	my $e = shift;
	my $h = shift;
	my $success = 0;
	print 'called _try_to_complete_hash('.$e->{uid}.", $h):\n" if ($debug);
	my @any_parents = grep { defined $_ } jobs_that_really_output($h);
	my @alive_parents = grep { defined $_ && $e->{jobs}->{$_} } @any_parents;
	my @included_parents = grep { defined $_ && defined($e->{jobs}->{$_}) } @any_parents;
	my $key_ok = (@alive_parents || test_keys($h) == 1) ? 1 : 0;
	unless ($key_ok) {
		if (@any_parents) {
			unless (@included_parents) {
				print "\tkey $h is incomplete.  parents: ". (map {"$_ "} @any_parents) . "\n" if ($debug);
				for ( grep { !defined($e->{jobs}->{$_}) } @any_parents ) {					
					push @E, _spawn_e($e, $_);
					$e->{dispose} = 1;
				}
			}
		} else {
			print "\tkey $h is an orphan.\n" if ($verbose || $debug);
			$e->{orphans} ||= {};
			$e->{orphans}->{$h} = 1;
			$e->{hashes}->{$h} = 1;
			$success = 1;
		}
	} else {
		$success = 1;
		$e->{hashes}->{$h} = 1;
		print "\tkey $h is complete.\n" if ($verbose || $debug);
	}
	return $success;
}

sub _try_to_complete_job {
	my $e = shift;
	my $j = shift;
	my $success = 0;
	print 'called _try_to_complete_job('.$e->{uid}.", $j):\n" if ($debug);
	my @hashes_i_need = grep { test_keys($_) != 1 && !$e->{hashes}->{$_} } all_inputkeys_for($j);
	unless (@hashes_i_need) {
		print "\tjob $j is complete.\n" if ($debug);
		$e->{jobs}->{$j} = 1;
		$success = 1;
	} else {
		print "\tjob $j needs " .@hashes_i_need . " hash(es) to finish.\n" if ($debug);
	}
	return $success;
}

# $e = _spawn_e($parent, $jobid);
sub _spawn_e {
	my $e = shift;
	my $j = shift;
	my $spawn;
	print 'called _spawn_e('.$e->{uid}.', '.(defined $j ? $j : 'undef')."):\n" if ($debug);
	if ($e) {
		$spawn = {
			'complexity'=>$e->{complexity}+1,
			'uid'=>$uid++,
			'hashes'=>{%{$e->{hashes}}},
			'jobs'=>{%{$e->{jobs}}}
		};
		if ($e->{orphans}) { $spawn->{orphans} = {%{$e->{orphans}}}; }
	} else {
		$e = { 'complexity'=>0,'hashes'=>{},'jobs'=>{} };
	}
	if ($j) {
		$spawn->{jobs}->{$j} = 0;
		map { $spawn->{hashes}->{$_} ||= 0 } grep { test_keys($_) != 1 } all_inputkeys_for($j);
	}
	$spawn->{complexity}++;
	$spawn->{uid} = $uid++;
	_explain_e($spawn) if $debug;
	return $spawn;
}

# print details of the supplied element
sub _explain_e {
	my $e = shift;
	print 'called _explain_e('.$e->{uid}."):\n" if ($debug);
	print map { $_.'='.$e->{$_}.' ' } qw(uid complexity);
	print 'keys=' . (scalar grep { $e->{hashes}->{$_} } keys %{$e->{hashes}}) . '/' . (scalar keys %{$e->{hashes}})
		. ' jobs=' . (scalar grep { $e->{jobs}->{$_} } keys %{$e->{jobs}}) . '/' . (scalar keys %{$e->{jobs}}) . "\n";
	if ($debug) {
		print "Hash dump:\n";
		print map { "\t$_ = ".$e->{hashes}->{$_} . ' (test: ' . test_keys($_) . ")\n" } keys %{$e->{hashes}};
		print "Job dump:\n";
		print map { "\t".($_||"undef").' = '.($e->{jobs}->{$_}||0) . "\n" } keys %{$e->{jobs}};
	}
	print "\n" if $debug;
}

sub _console_output {
	my $e = shift;
	print 'called _console_output('.$e->{uid}."):\n" if ($debug);
	my $stepcount = 1;
	my $out = _prepare_steps($e);
	if ($out->[0]->{orphans}) {
		print "\nYour result set relies on legacy data no longer available in the database.  The following data must be reintroduced to the system before your data set can be reconstructed.\n";
		print "Irreproducible missing data:\n";
		print map { "\t$_\n" } @{ (shift @{$out})->{orphans} };
	}
	print "Re-run these jobs:\t\tTo produce these outputs:\n";
	for my $step (@{$out}) {
		print "Step ".($stepcount++)."\n";
		my $i = 0;
		while ($step->{jobs}->[$i] || $step->{hashes}->[$i]) {
			print "   ".($step->{jobs}->[$i]||'')."\t  ".($step->{hashes}->[$i++]||'')."\n";
		}
	}
	return 1;
}


sub _perl_obj_output {
	my $e = shift;
	print 'called _perl_obj_output('.$e->{uid}."):\n" if ($debug);
	print '$e = {'."\n";
	for my $k (keys %{$e}) {
		print "  '$k' => ";
		if (ref $e->{$k} eq 'HASH') {
			print "{\n";
			print map { "    '$_'=>".$e->{$k}->{$_}."\n" } keys %{$e->{$k}};
			print "  }\n";
		} else {
			print $e->{$k}."\n";
		}
	}
	print "}\n";
}

# $orphan;$orphan;$job;$hash;$job
sub _portable_output {
	my $e = shift;
	print 'called _portable_output('.$e->{uid}."):\n" if ($debug);
	my $steps = _prepare_steps($e);
	my @portable;
	push @portable, @{ (shift @{$steps})->{orphans} } if $steps->[0]->{orphans};
	map { push @portable, @{$_->{jobs}}, @{$_->{hashes}} } @{$steps};
	return join (';', @portable) . "\n";
}

sub _prepare_steps {
	my $e = shift;
	my $stages = [];
	print 'called _prepare_steps('.$e->{uid}."):\n" if ($debug);
	my $activity = 1;
	if ($e->{orphans}) {
		map { $e->{hashes}->{$_} = ($e->{orphans}->{$_} ? 1 : 0) } keys %{$e->{hashes}};
		push @{$stages}, {'orphans'=>[ keys %{$e->{orphans}} ]};
	} else {
		map { $e->{hashes}->{$_} = 0 } keys %{$e->{hashes}};
	}	
	map { $e->{jobs}->{$_} = 0 } keys %{$e->{jobs}};
	while ($activity) {
		$activity = 0;
		my $stage = {'jobs'=>[],'hashes'=>[]};
		for (grep { !$e->{jobs}->{$_} } keys %{$e->{jobs}}) {
			if ( _try_to_complete_job($e, $_) ) {
				push @{$stage->{jobs}}, $_;
				$activity++;
			}			
		}
		for (grep { $e->{jobs}->{$_} } keys %{$e->{jobs}}) {
			for (grep { defined($e->{hashes}->{$_}) } outputkeys_for($_)) {
				unless ($e->{hashes}->{$_}) {
					$e->{hashes}->{$_} = 1;
					push @{$stage->{hashes}}, $_;
				}
			}
		}
		push @{$stages}, $stage if @{$stage->{jobs}};
		print "stages: ".@{$stages}." activity: $activity\n" if ($debug);
	}
	return $stages;
}

sub _batch_output {
	my $e = shift;
	print 'called _batch_output('.$e->{uid}."):\n" if ($debug);
	my @lines;
	map { push @lines, [$_, '-'] } keys %{$e->{orphans}} if ($e->{orphans});
	for my $j (keys %{$e->{jobs}}) {
		my @outkeys = grep { $_ && $e->{hashes}->{$_} } outputkeys_for($j);
		my @inkeys = grep { $_ && $e->{hashes}->{$_} } all_inputkeys_for($j);
		push @lines, [join(',',@outkeys),$j,join(',',@inkeys)] if @outkeys;
	}
	print map { "$_\n" } map { join(' ',@{$_}) } @lines;
	return 1;
}

1;
