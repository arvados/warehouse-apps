#!/usr/bin/perl

use warnings;
use strict;

use IO::File;

my $size = shift;
my $infile = shift;
my $outpat = shift;

my $infp = new IO::File "/bin/gunzip < $infile |";

my $filecount = 0;

my $outfp;

my $count = 0;
my $buf;
while ($infp->read($buf, 4)) {
  $count = 0 if ($count > $size);
  if ($count == 0)  {
    $outfp->close if $outfp;
    my $file = sprintf "$outpat", $filecount;
    $filecount++;
    $outfp = new IO::File "| /bin/gzip > $file";
  }
  
  my $name_len = unpack "i", $buf;
  die $name_len if $name_len > 100;
  my $name;
  $infp->read($name, $name_len);

  $infp->read($buf, 4);
  my $data_len = unpack "i", $buf;
  die $data_len if $data_len > 1000;
  my $data;
  $infp->read($data, $data_len);

  $count++;

  print $outfp pack('i', $name_len), $name, pack('i', $data_len), $data;
}

$outfp->close;
$infp->close;

print "$filecount\n";
