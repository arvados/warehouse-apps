#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

# chr16   MAQ     placed-read     45000009        45000044        41      +       .       R 071224_SLXA-EAS1_0099:3:137:838:834+ ; Q illumina "IAIIII:III95IF7III3+I/<=D6+I15@4+I=*" ; S "AATTAAaACAaaTAaTGGaaTaCAAcaTacTcaTTg"

use BFA;

my $file = shift;

$file = "" if !defined $file || $file eq '-';

my $bfa = new BFA($ENV{REFERENCE_FILE} || "/home/miron/homo_sapiens.bfa");

my $did_init = 0;
my $QUALITY_THRESHOLD = 0;

open(IN, "zcat $file |") or die;
while (<IN>) {
  chomp;
  my ($chr, $source, $type, $start, $end, $score, $strand, $frame, $attrs) = split(/\t/) ;

  # do not handle edge case
  next if $start < 2;

  my @attrs = split(/\s+;\s+/, $attrs);
  my %attrs = map { split(/\s*/, $_, 2); } @attrs;

  my $qual_str = $attrs{'Q'};
  my ($qtype, $quals) = split(/ /, $qual_str);
  $quals =~ s/^"|"$//g;

  if (!$did_init) {
    $bfa->find($chr) or die;
    $did_init = 1;
  }
  my $seq = lc $attrs{S};
  $seq =~ s/^"|"$//g;
  my $ref = lc $bfa->walk($start-3);
  $seq = substr($ref, 0, 2) . $seq;

  if (0) {
    print "\@$start - $ref\n";
    print "\@$start - $seq\n";
    print "\@$start - $quals\n";
  }

  my @diffs = find_diffs($seq, $ref);

  if (scalar(@diffs) > 20) {
    print join("\t", $chr, $source, 'over-mismatch', $start, $end, $score, $strand, $frame, "R $attrs{R} ;"), "\n";
    next;
  }

  foreach my $diff_pos (@diffs) {
    die $qual_str if length($quals) < $diff_pos - 1;
    my $qual = ord(substr($quals, $diff_pos - 2, 1)) - 33;
    $qual = 0 if ($qual < 0);
    next if ($qual < $QUALITY_THRESHOLD);
    print join("\t", $chr, $source, 'mismatch', $start + $diff_pos - 2, $start + $diff_pos - 2, $qual, $strand, $frame, "R $attrs{R} ; D " . substr($ref, $diff_pos - 2, 5) . " " . substr($seq, $diff_pos - 2, 5)), "\n";
  }
}

close(IN) or die;

sub find_diffs {
  my ($seq, $ref) = @_;
  $ref = substr($ref, 0, length($seq));

  return () if ($ref eq $seq);

  my @diffs;
  my $cur_pos = 0;
  while ($ref ne "") {
    my $comp = $ref ^ $seq;
    $comp =~ /^(\0*)/;
    my $pos = length($1);
    last if $pos == length($ref);
    push @diffs, $cur_pos + $pos;
    $seq = substr($seq, $pos+1);
    $ref = substr($ref, $pos+1);
    $cur_pos = $cur_pos + $pos + 1;
  }
  return @diffs;
}
