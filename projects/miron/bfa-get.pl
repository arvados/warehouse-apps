#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

use BFA;

my $bfa = new BFA "/home/miron/homo_sapiens.bfa";

my $chr = shift;
my $pos = shift;

$bfa->find($chr) or die;
print lc $bfa->get($pos-1), "\n";
