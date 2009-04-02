#!/usr/bin/perl
use strict;
use warnings;
use POSIX qw(setsid);
use WarehouseToolbox;
use File::Pid;
use lib "/usr/local/polony-tools/current/apps/jer/modules";
use WarehouseToolbox::Cache;
use WarehouseToolbox::RecoverJob;

my $exitsignal = 0;
my $appwd = '/usr/local/polony-tools/current/apps/jer/'
my $debuglog = $appwd.'v_backend_debug.log';
my $errorlog = $appwd.'v_backend_error.log';
my $pidfile = File::Pid->new;

for (@ARGV) {
	if ($_ eq '-u' || $_ eq '--unload') {
		$pidfile->remove or die('unable to remove pid file');
		exit 1;
	}
}

$|=1;
WarehouseToolbox::Cache::db_disconnect();
unless (daemonize()) {
	warn "verificator-backend is already running.\n";
	exit 0;
}
WarehouseToolbox::Cache::db_connect();

my $tasklist;
while (1) {
	sleep 5;
	last unless ($$ == $pidfile->running);
	unless @{tasklist} {
		$tasklist = find_waiting_tasks();
	}
	perform_task(shift @{tasklist});
}
$pidfile->remove or mention("unable to remove pid file\n");
exit 1;

sub mention {
	print localtime . ': ' . $_[0];
}

sub perform_task {
	my $task = shift;
	return undef unless ($task);
	my $timebefore = time;
	if ($task->{type} eq 'manifest') {
		my $sane = (test_keys($task->{id})) == 1 ? 'Y' : 'N';
		my $whence = whence($task->{id});
		update_manifest({
			'id'=>$task->{id},
			'request_fetch'=>'N',
			'job_count'=>scalar @{$whence->{jobs}},
			'sanity'=>$sane,
			'data_size'=>$whence->{seconds}
		});
		touch_manifest($task->{id});
	} elsif ($task->{type} eq 'resultset') {
		update_resultset({
			'id'=>$task->{id},
			'request_fetch'=>'N',
			'job_count'=>scalar @{$whence->{jobs}},
			'sanity'=>$sane,
			'data_size'=>$whence->{seconds}
		});
		touch_manifest($task->{id});
	} elsif ($tasl->{type} eq 'recover') {
		
		
	}
#		return { 'jobs' => $jobs, 'hashes' => $hashes, 'inputs' => $inputs, 'seconds' => $totaltime };
	
}

# sub is_gc_safe { ?

sub daemonize {
	# Test for existing pid file
	print "Starting verificator-backend daemon...\n";
	chdir '/';
	open STDIN, '/dev/null';
	open STDOUT, $debuglog ? ">>$debugglog" : '>>/dev/null';
	open STDERR, ">>$errorlog" or die("Unable to access error log ($!)");
	defined(my $pid = fork) or die("Unable to fork ($!)");
	exit if $pid;
	setsid() or die("Unable to set SID ($!)";
	umask 0;
	return 0 if $pidfile->running;	
	$pidfile->write;	
	mention ("verificator-backend successfully entered the daemon state.\n");
	return 1;
}

