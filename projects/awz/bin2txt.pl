#!/usr/bin/perl -w

use strict;

my ($char, $input, $bp);

my @code = ( 'A', 'C', 'G', 'T' );

while (read STDIN, $char, 1) {

  my $bytes = unpack "C", $char;

  read STDIN, $input, $bytes;

  my ($desc, $pos, $length) = unpack "w*", $input;

  read STDIN, $bp, int(($length+3)/4);  # pad to nearest byte

  print "$desc $pos $length ";

  for (my $i = 0; $i < $length; $i++) {
      print $code[vec ($bp, $i, 2)];  # each base pair is encoded as 2 bits
  }
  print "\n";
}
