#!/usr/bin/perl -w

use strict; 

my $PIXELS = 1000 * 1000; 
my $RECORDSIZE = 2 * $PIXELS; 

my @raw; 
my $num_raw = 0;  

until ( eof(STDIN) ) {
    read(STDIN, $raw[$num_raw], $RECORDSIZE) == $RECORDSIZE
        or die "input must be multiple of $RECORDSIZE bytes\n";
    $num_raw++; 
}
warn "Read $num_raw raw images\n"; 

if ($num_raw < 1 ) {
  die "not enough data for brightfield\n";
}
if (($num_raw-1) % 4 != 0) {
  die "florescence images should be provided in multiples of four.\n";  
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
