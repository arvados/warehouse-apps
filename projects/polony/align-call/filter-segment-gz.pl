#!/usr/bin/perl -w

use strict; 
use Image::Magick;

my $PIXELS = 1000 * 1000; 
my $RECORDSIZE = 2 * $PIXELS; 

open GZIP, "| gzip | wc -c >&2";

#skip brightfield image 
read(STDIN, my $raw, $RECORDSIZE) == $RECORDSIZE
  or die "brightfield must be $RECORDSIZE bytes\n";
print $raw;
print GZIP $raw;

my $num_image = 1;

until ( eof(STDIN) ) {

    read(STDIN, $raw, $RECORDSIZE) == $RECORDSIZE
        or die "image must be $RECORDSIZE bytes\n";

    my $mask = Image::Magick->new( 
        magick => 'gray', size => '1000x1000', endian => 'lsb');
              
    $mask->BlobToImage($raw); 
    my $image = $mask->Clone();

    $mask->Normalize();       
    $mask->Segment();    
    $mask->Normalize();

    $image->Composite(image=>$mask, compose=>'Multiply');

    my $segment = $image->ImageToBlob(); 
    
    print $segment;
    print GZIP $segment;
    
    $num_image++; 
}
warn "Read $num_image raw images.\n";
close GZIP;

# arch-tag: Tom Clegg Tue Mar 20 19:41:03 PDT 2007 (align-call/segment.pl)
