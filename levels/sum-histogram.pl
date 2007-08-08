#!/usr/bin/perl
# sum-histogram.pl

use strict;
use Image::Magick;

my @pix = (0,0);
while (<STDIN>) {
  my @a = split "\t";
  next if @a != 2;
  next if $a[0] =~ /\D/;
  $pix[$a[0]] += $a[1];
}

my $max = -1;
foreach (@pix)
{
  if ($max < $_)
  {
    $max = $_;
  }
}

my ($w, $h) = qw(400 400);

my $image = Image::Magick->new (size => $w."x".$h);
$image->ReadImage('xc:white');

my $margin = 20;
my $x0 = $margin;
my $y0 = $margin;
my $gw = $w - $margin*2;
my $gh = $h - $margin*2;
my $xscale = log($#pix) > 0 ? $gw / log($#pix) : 1;
my $yscale = ($max > 0 && log($max) > 0) ? $gh / log($max) : 1;

for (my $i = 0; $i <= $#pix; $i ++)
{
  my $x = $i>0 ? log($i) : 0;
  my $y = $pix[$i]>0 ? log($pix[$i]) : 0;
  $x = int($x0 + $xscale * $x);
  $y = int($h - $margin - $yscale * $y);
#  print STDERR "$i $pix[$i] $x $y\n";
  $image->Set("pixel[$x,$y]"=>"black");
}

# print STDERR "@pix\n";

my ($x1, $y1) = ($x0+$gw, $y0+$gh);
$image->Draw(stroke=>"black", primitive=>"rectangle", points=>"$x0,$y0 $x1,$y1");
$image->Write('png:-');
