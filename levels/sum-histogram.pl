#!/usr/bin/perl
# sum-histogram.pl

@pix;

while (<STDIN>) {
  @a = split "\t";
  $pix[$a[0]] += $a[1];
} 

$i = 0;
foreach (@pix) {
    print "$i\t$_\n";
    $i++;
}

