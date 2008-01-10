#!/usr/bin/perl -w

use strict;

while (<>) {

  chomp;

  my @bp = split;

  $bp[3] =~ s/A/00/g;
  $bp[3] =~ s/C/10/g;
  $bp[3] =~ s/G/01/g;
  $bp[3] =~ s/T/11/g;

  my $enc = pack "w*", $bp [0], $bp[1], $bp[2];
  my $len = length ($enc);

  if (2 < $len && $len < 256 ) {
    print pack "Ca*b*", $len, $enc, $bp[3];
  }
  else {
    die "couldn't parse STDIN\n";
  }
}
