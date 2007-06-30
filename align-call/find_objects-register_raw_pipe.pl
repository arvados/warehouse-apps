#!/usr/bin/perl -w

#adding a comment here -- AWZ

use strict;

my $PIXELS = 1000 * 1000;
my $RECORDSIZE = 2 * $PIXELS;

my $num_raw_expected = 1;	# bright field
if (exists($ENV{DIRORDER})	# flor images
    &&
    $ENV{DIRORDER} =~ /\S/)
{
    $num_raw_expected += (1 + ($ENV{DIRORDER} =~ tr/ / /)) * 4;
    $num_raw_expected ++;
}
if (exists($ENV{HYBRIDDIRORDER})# hybrid images
    &&
    $ENV{HYBRIDDIRORDER} =~ /\S/)
{
    $num_raw_expected += $ENV{HYBRIDDIRORDER} =~ tr/ / /;
    $num_raw_expected ++;
}

my @raw;
my $num_raw = 0; 

until ( eof(STDIN) ) {
    read(STDIN, $raw[$num_raw], $RECORDSIZE) == $RECORDSIZE
        or die "input must be multiple of $RECORDSIZE bytes\n";
    $num_raw++;
}
warn "Read $num_raw raw images\n";

if ($num_raw != $num_raw_expected) {
    die "Expected $num_raw_expected images, read $num_raw";
}
open SPOOLER, "| find-objects 1000 1000 $ENV{OBJECTTHRESHOLD} 1";
print SPOOLER $raw[0];
close SPOOLER;

for (my $i = 1; $i < $num_raw; $i++) {
  open SPOOLER, "| register-raw-translate 1000 1000 $ENV{FOCUSPIXELS} $ENV{OBJECTTHRESHOLD} 1 $ENV{ALIGNWINDOW}";
  print SPOOLER $raw[0].$raw[$i];
  close SPOOLER;
}

# arch-tag: Tom Clegg Fri Mar 16 20:44:33 PDT 2007 (align-read/find_objects-register_raw_pipe.pl)
