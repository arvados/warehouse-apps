#!/usr/bin/perl -w

use strict; 
use Image::Magick;

my $PIXELS = 1000 * 1000; 
my $RECORDSIZE = 2 * $PIXELS; 

open GZIP, "| gzip | wc -c >&2";

#skip background image 
read(STDIN, my $raw, $RECORDSIZE) == $RECORDSIZE
  or die "background must be $RECORDSIZE bytes\n";
print $raw; 
print GZIP $raw;

my $num_image = 1;
until ( eof(STDIN) ) {
    read(STDIN, $raw, $RECORDSIZE) == $RECORDSIZE
        or die "image must be $RECORDSIZE bytes\n";
    print $raw;
    print GZIP $raw;
    $num_image++; 
}
warn "Read $num_image raw images.\n";
close GZIP;

# arch-tag: Tom Clegg Thu Apr  5 15:40:44 PDT 2007 (align-call/nosegment.pl)
