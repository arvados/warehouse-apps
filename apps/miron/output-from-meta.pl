#!/usr/bin/perl

use Warehouse;
use Warehouse::Stream;
use Data::Dumper;

my $jobid = shift;

my $whc = new Warehouse;

my $job = $whc->job_list(id_min => $jobid, id_max => $jobid)->[0];
my $metakey = $job->{metakey} or die "Job $oldid has no metakey";
warn "meta is $metakey\n";

my @metablocks = split (/,/, $metakey);
my $stream = new Warehouse::Stream (whc => $whc,
  hash => \@metablocks);
$stream->rewind;

while (my $dataref = $stream->read_until (undef, "\n"))
{
  my ($timestamp, $job_id, $jobmanager_pid, $jobstep_id, $message)
  = $$dataref =~ /^(\S+) (\d+) (\d+) (\d*) (.*)\n/;

  if ($message =~ /^output (\S*)\+(\S*)/)
  {
    if (length($1) == 32) {
      my $stream1 = new Warehouse::Stream(whc => $whc, hash => [$1]);
      while (my $manifest_line = $stream1->read_until(undef, "\n")) {
	print $$manifest_line;
      }
    }
  }
}
