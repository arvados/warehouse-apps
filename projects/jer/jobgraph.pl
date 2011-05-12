#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;

use lib "/usr/local/polony-tools/current/apps/jer/modules";
use WarehouseJobGraph;
#use WarehouseCache;

$|=1;

#my $whc = new WarehouseCache;
#my $job_list = $whc->job_list();

#my $g = new WarehouseJobGraph;
#$g->{debug} = 1;

JobGraphFile("file=temp.png 1024x768 time=1182994803-1185318781");



