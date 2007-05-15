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
warn "Read $num_raw\n";

if ($num_raw < 1 ) {
  die "not enough data for brightfield and mask.\n";
}
if (($num_raw-1) % 4 != 0) {
  die "florescence images should be provided in multiples of four.\n";
}
my $num_flor = $num_raw-1;

my @object_pixels;

my $count = 0;
for (my $pos = 0; $pos < $PIXELS; $pos++) {
    my $flip = vec($raw[0], $pos, 16);
    if ($flip) {
      my $object = (($flip&0xFF)<<8)|($flip>>8);
      $object_pixels[$object] .= pack "N", $pos;
      $count++;
    }
}
warn "There are $count ($#object_pixels) pixels (objects) in the mask\n";

my @object_intensities;
for (my $object = 1; $object <= $#object_pixels ; $object++) {
    my @pixels = unpack "N*", $object_pixels[$object];

    $object_intensities[$object] = pack "N", $#pixels+1;

    for (my $i = 1; $i < $num_raw; $i+=4) {

	my $intensityA = 0;
	my $intensityC = 0;
	my $intensityG = 0;
	my $intensityT = 0;

	foreach my $pixel (@pixels) {
	    my $flip = vec($raw[$i], $pixel, 16);
	    $intensityC += (($flip&0xFF)<<8)|($flip>>8);
	    $flip = vec($raw[$i+1], $pixel, 16);
	    $intensityA += (($flip&0xFF)<<8)|($flip>>8);
	    $flip = vec($raw[$i+2], $pixel, 16);
	    $intensityT += (($flip&0xFF)<<8)|($flip>>8);
	    $flip = vec($raw[$i+3], $pixel, 16);
	    $intensityG += (($flip&0xFF)<<8)|($flip>>8);
	    $count++;
	}
    $object_intensities[$object] .= pack "NNNN",
	$intensityA, $intensityC, $intensityG, $intensityT;
    }
}

for (my $object = 1; $object <= $#object_pixels ; $object++) {
    my @intensities = unpack "N*", $object_intensities[$object];
    my $call ="";
    for (my $bp = 1; $bp <$num_flor; $bp+=4) {
	my $A = $intensities[$bp];
	my $C = $intensities[$bp+1];
	my $G = $intensities[$bp+2];
	my $T = $intensities[$bp+3];

	my $max ="N";

	if ($A > $C && $A > $G && $A > $T) {
	    $max = "A";
	}
	elsif ($C > $A && $C > $G && $C > $T) {
	    $max = "C";
	}
	elsif ($G > $A && $G > $C && $G > $T) {
	    $max = "G";
	}
	elsif ($T > $A && $T > $C && $T > $G) {
	    $max = "T";
	}
	$call .= $max;
    }
    print "$call $object @intensities\n";
}

# arch-tag: Tom Clegg Fri Mar 16 20:45:09 PDT 2007 (align-read/raw_to_reads.pl)
