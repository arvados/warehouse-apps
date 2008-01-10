#!/usr/bin/perl -w

use strict;

use constant MAXBP => scalar 4000000;

my $bp = "";
my $length = length($bp);
my $pos = 0;

my $state = 0;

my $desc = 0;

while (<>) {

  chomp;

  if (/^>.*$/) {

     if ($state == 1) {
         my $i = $length%MAXBP;
         print "$desc $pos $i ".substr($bp,0,$i)."\n";
         while ($i < $length) {
             print "$desc ".($pos+$i)." 4000000 ".substr($bp, $i, 4000000)."\n";
             $i+=4000000;
         }
     }
     $desc++;
     print STDERR "$desc $_\n";
     $pos += $length;

     $bp = "";
     $length = length ($bp);
     $state = 0;
  }
  else {

    my @bp = split (/([NnMR]+)/, $_);

    foreach my $tok (@bp) {

      $tok = uc ($tok);

      if ( $tok =~ m/^[NnMR]+$/ ) {

        if ( $state == 0 ) {
          $bp = $tok;
          $length = length ($tok);
          $state = 2;
        }
        elsif ($state == 1 ) {
          my $i = $length%MAXBP;
          print "$desc $pos $i ".substr($bp,0,$i)."\n";
          while ($i < $length) {
             print "$desc ".($pos+$i)." 4000000 ".substr($bp, $i, 4000000)."\n";
             $i+=4000000;
          }
          $pos += $length;

          $bp = $tok;
          $length = length ($tok);
          $state = 2;
        }
        else {
          $bp .= $tok;
          $length += length ($tok);
        }
      }
      elsif ( $tok =~ m/^[ACGT]+$/ ) {

        if ( $state == 0 ) {
          $bp = $tok;
          $length = length ($tok);
          $state = 1;
        }
        elsif ($state == 2 ) {
          $pos += $length;

          $bp = $tok;
          $length = length ($tok);
          $state = 1;
        }
        else {
          $bp .= $tok;
          $length += length ($tok);
        }
      }
    }
  }
}

if ($state == 1) {
   my $i = $length%MAXBP;
   print "$desc $pos $i ".substr($bp,0,$i)."\n";
   while ($i < $length) {
      print "$desc ".($pos+$i)." 4000000 ".substr($bp, $i, 4000000)."\n";
      $i+=4000000;
   }
}
