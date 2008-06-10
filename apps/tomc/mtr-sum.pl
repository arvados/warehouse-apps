#!/usr/bin/perl
# -*- mode: perl; perl-indent-level: 2; -*-

use strict;
use Warehouse;
use Warehouse::Stream;
use Warehouse::Manifest;
use IO::File;

my %opt = ("EXAMPLES" => 1000);
while ($ARGV[0] =~ /^(.*?)=(.*)$/)
{
  $opt{$1} = $2;
  shift @ARGV;
}

my $manifestkey = shift @ARGV;
my $examplesbase = shift @ARGV;

my $whc = new Warehouse;
my $m = new Warehouse::Manifest (whc => $whc,
				 key => $manifestkey);

my %sum;
my %summaryfields;
while (my $s = $m->subdir_next)
{
  $s->rewind;
  while (my ($pos, $size, $filename) = $s->file_next)
  {
    last if !defined $pos;
    $s->seek ($pos);    
    while (my $dataref = $s->read_until (undef, "\n"))
    {
      if ($$dataref =~ /^m=(\d+) n=(\d+) (..)=(\d+)$/)
      {
	$sum{"$1,$2,$3"} += $4;
      }
      elsif ($$dataref =~ /^\#summary: m=(\d+) n=(\d+) (.*)/)
      {
	my $m = $1;
	my $n = $2;
	my $s = $3;
	while ($s =~ /\b(\S+)=(\d+)\b/g)
	{
	  $sum{"$m,$n,$1"} += $2;
	  $summaryfields{$1} = 1;
	}
      }
    }
  }
}

my @summaryfields = sort keys %summaryfields;

my @xy = qw(ac ag at ca cg ct ga gc gt ta tc tg);
my %m;
my %n;

print (join ("\t", qw(m n), @xy, @summaryfields), "\n");

foreach (sort keys %sum)
{
  my ($m, $n, $xy) = split (/,/);
  $m{$m} = 1;
  $n{$n} = 1;
}

my %wantexamples;
my %examplefiles;
for my $m (sort { $a <=> $b } keys %m)
{
  for my $n (sort { $a <=> $b } keys %n)
  {
    my @N = map { $sum{"$m,$n,$_"} + 0 } (@xy, @summaryfields);
    print (join ("\t", $m, $n, @N), "\n");

    # add # satisfying reads across all xy

    $sum{"$m,$n"} = 0;
    map { $sum{"$m,$n"} += $sum{"$m,$n,$_"} } @xy;
    $sum{"$m,$n"} = 1 if $sum{"$m,$n"} == 0;

    # how many examples should we save? max { 1000, total # satisfying reads }

    my $wantexamples_total = $sum{"$m,$n"} > $opt{"EXAMPLES"} ? $opt{"EXAMPLES"} : $sum{"$m,$n"};
    map { $wantexamples{"$m,$n,$_"} = int ($wantexamples_total * $sum{"$m,$n,$_"} / $sum{"$m,$n"}) } @xy;

    # open a file to store the examples for this {m,n}

    $examplefiles{"$m,$n"} = new IO::File;
    open $examplefiles{"$m,$n"}, ">", "$examplesbase-m$m-n$n.txt"
	or die "create $examplesbase-m$m-n$n.txt: $!";
  }
}

$m->rewind;
while (my $s = $m->subdir_next)
{
  $s->rewind;
  while (my ($pos, $size, $filename) = $s->file_next)
  {
    last if !defined $pos;
    $s->seek ($pos);    
    while (my $dataref = $s->read_until (undef, "\n"))
    {
      if ($$dataref =~ /^\#example: m=(\d+) n=(\d+) ([acgt][acgt]) (.*)/s)
      {
	my $m = $1;
	my $n = $2;
	my $xy = $3;
	my $s = $4;
	if ($wantexamples{"$m,$n,$xy"} > 0)
	{
	  --$wantexamples{"$m,$n,$xy"};
	  print { $examplefiles{"$m,$n"} } "$xy $s";
	}
      }
    }
  }
}

map { close $examplefiles{$_} or die "close examples{$_}: $!" } keys %examplefiles;
