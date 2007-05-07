#!/usr/bin/perl

use strict; 
use Image::Magick;

open STDIN, "tprint |" or die "tprint: $!";

my (@frameinfo) = grep (!/^\#/, <>);
chomp (@frameinfo);

my ($xmin, $xmax, $ymin, $ymax, $zmax);
my (@xall);
foreach (@frameinfo)
{
    my ($frameno, $x, $y, $z) = split;
    push (@xall, $x);
    if (!defined($xmin))
    {
	$xmin = $xmax = $x;
	$ymin = $ymax = $y;
	$zmax = $z;
    }
    else
    {
	$xmin = $x if $xmin > $x;
	$ymin = $y if $ymin > $y;
	$xmax = $x if $xmax < $x;
	$ymax = $y if $ymax < $y;
	$zmax = $z if $zmax < $z;
    }
}

my $framesize = 10000;
foreach (@xall)
{
    if (10 < ($_ - $xmin) && ($_ - $xmin) < $framesize)
    {
	$framesize = $_ - $xmin;
    }
}
$framesize = int($framesize*9/10);

$xmax += $framesize;
$ymax += $framesize;

for ($xmin, $ymin) { $_ -= $framesize/2 }
for ($xmax, $ymax) { $_ += $framesize/2 }

my $w = 1024;
my $h = int($w * ($ymax - $ymin) / ($xmax - $xmin));
my $scale = $w / ($xmax - $xmin);

my $image = Image::Magick->new;
$image->Set (size=>"${w}x${h}");
$image->ReadImage('xc:white');

foreach (@frameinfo)
{
    my ($frameno, $x, $y, $z) = split;
    my ($x2, $y2) = ($framesize+$x, $framesize+$y);
    foreach ($x, $x2) { $_ -= $xmin }
    foreach ($y, $y2) { $_ -= $ymin }
    foreach ($x, $y, $x2, $y2) { $_ = int($_ * $scale) }
    $image->Draw(stroke=>'#aaa',
		 primitive=>'rectangle',
		 points=>"$x,$y $x2,$y2");

    my ($cx, $cy, $cy2);

    ($cx, $cy) = map (int, ($x+$x2)/2, ($y+$y2)/2);

    ($cy2) = $cy + int($framesize/2 * $scale * sqrt($z / $zmax));
    $image->Draw(stroke=>'blue',
		 fill=>'lightblue',
		 primitive=>'circle',
		 points=>"$cx,$cy $cx,$cy2");
}

my $e = $image->Write ('png:-');
warn "$e" if "$e";

# arch-tag: Tom Clegg Thu Apr  5 16:19:39 PDT 2007 (align-call/framestatsimage.pl)
