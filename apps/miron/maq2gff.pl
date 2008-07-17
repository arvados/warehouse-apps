#!/usr/bin/perl

use warnings;
use strict;

use Math::BigInt;
use IO::File;

# Usage:
#   maq mapview -N <infile>.map | maq2gff
#
# Output files are opened in append mode!

# MAQ
#  For reads aligned before the Smith-Waterman alignment, each line consists of read name, chromosome, position, strand, insert size from the outer coorniates of a pair, paired flag, mapping quality, single-end mapping quality, alternative mapping quality, number of mismatches of the best hit, sum of qualities of mismatched bases of the best hit, number of 0-mismatch hits of the first 24bp, number of 1-mismatch hits of the first 24bp on the reference, length of the read, read sequence and its quality

# GFF
# Chromosome
# Source program name  - MAQ
# Feature type - "placed-read"
# start,end
# score - the mapping quality
# strand
# frame - '.' since unknown
# attributes - R "<readname>" ; Q <quality type> "<quality string>" ; S "<sequence>" 
# alt attributes - R "<readname>" ; Q <quality type> "<quality string>" ; M "<mismatch read bases>" "<mismatch positions comma separated>"

my %output;

while (<>) {
  chomp;
  my ($name, $chr, $pos, $strand, $insert, $pflag, $mapqual, $se_mapqual, $alt_mapqual, $mismatches, $mismatch_qual, $mm_0, $mm_1, $length, $seq, $qual, $mm_bitmap_hex) = split(/\t/);
  if ($pflag != 18) {
    next;
  }

  my $e_qual = $qual;
  $e_qual =~ s/"/\\"/g;
  my $attrs = qq{R $name$strand ; Q illumina "$e_qual"};
  if ($mm_bitmap_hex) {
    my $mm_bitmap_temp = new Math::BigInt "0x$mm_bitmap_hex";
    my @mms;
    my @mms_pos;
    for (my $ind = $length-1 ; $ind >= 0 ; $ind--) {
      if ($mm_bitmap_temp->is_odd) {
	my $mm_pos = $ind;
	push @mms, substr($seq, $ind, 1);
	push @mms_pos, $ind;
      }
      $mm_bitmap_temp->brsft(1);
      $attrs .= qq{ ; M } . join('', @mms) . " " . join(",", @mms_pos);
    }
  }
  else {
    $attrs .= qq{ ; S "$seq"};
  }
  my $end_pos = $pos + $length - 1;
  my $outindex = "$chr-" . sprintf ("%04d", int($pos / 1_000_000));
  push @{$output{$outindex}}, "$chr\tMAQ\tplaced-read\t$pos\t$end_pos\t$mapqual\t$strand\t.\t$attrs";
}

foreach my $key (sort keys %output) {
  foreach my $value (@{$output{$key}}) {
    print $value, "\n";
  }
}
